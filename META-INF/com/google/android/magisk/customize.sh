if [ "$BOOTMODE" ] && [ "$KSU" ]; then
    ui_print "- Installing from KernelSU app"
elif [ "$BOOTMODE" ] && [ "$APATCH" ]; then
    ui_print "- Installing from APatch app"
elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
    ui_print "- Installing from Magisk app"
else
    ui_print "*********************************************************"
    ui_print "! Installing from recovery is not supported"
    ui_print "! Please install from KernelSU, APatch or Magisk app"
    abort    "*********************************************************"
fi
. $MODPATH/func.sh

stock_framework="/system/framework/framework.jar"
mod_framework="$MODPATH$stock_framework"
classes_dex="$MODPATH/dex/classes.dex"

ui_print " "
ui_print "******************************"
ui_print "> Pre-installation check ..."
ui_print "******************************"
real_modpath="$(echo "$MODPATH" | cut -d'_' -f1)/$(echo "$MODPATH" | cut -d'_' -f2 | cut -d'/' -f2)"
if [ -e "$real_modpath$stock_framework" ] && [ ! -e "$real_modpath/disable" ]; then
    ui_print "Existing Framework Patcher GO module is running!"
    abort "Please uninstall or disable the module before continuing."
else
    ui_print "[ OK ] Checking for existing Framework Patcher GO module."
fi

if (! unzip -l "$stock_framework" | grep -q "classes.dex"); then
    abort "/system/framework/framework.jar is not deodexed"
else
    ui_print "[ OK ] Checking for deodexed /system/framework/framework.jar."
fi

if [ ! -e "$classes_dex" ]; then
    ui_print "Required classes.dex file is not found in META-INF/com/google/android/magisk/dex directory"
    ui_print " "
    ui_print "Do you want to download a pre-compiled classes.dex file from the FrameworkPatch source?"
    ui_print "- YES  [Press volume UP]"
    ui_print "- NO   [Press volume DOWN]"
    ui_print " "
    if $yes; then
        ui_print "Downloading classes.dex ..."
        wget --no-check-certificate -O "$classes_dex" "$(get_framework_patch_url)" 2>&1 || abort "Downloading failed";
    else
        abort "Please add your own classes.dex file."
    fi
else
    ui_print "[ OK ] Checking for required classes.dex file."
fi

ui_print " "
ui_print "******************************"
ui_print "> Decompiling framework.jar ..."
ui_print "******************************"
apktool d "$stock_framework" -api "$API" --output "$TMP/framework"
to_recompile=false

ui_print " "
ui_print "******************************"
ui_print "> Patching AndroidKeyStoreSpi.smali file..."
ui_print "******************************"
android_key_store_spi_file="$(find "$TMP/framework" -type f -name "AndroidKeyStoreSpi.smali")"
android_key_store_spi_dex="$(classes_path_to_dex "$android_key_store_spi_file")"
akss_method="engineGetCertificateChain"
ui_print "File found: $android_key_store_spi_file"

if (! grep -wlq "$android_key_store_spi_file" -e "$akss_method"); then
    abort "engineGetCertificateChain method not found in AndroidKeyStoreSpi.smali"
fi

ui_print " "
ui_print "This patch is for spoofing a locked bootloader for local attestation."
ui_print "Do you want to apply this patch?"
ui_print "- YES  [Press volume UP]"
ui_print "- NO   [Press volume DOWN]"
ui_print " "

if $yes; then
    akss_line="$(grep -w "$android_key_store_spi_file" -e "$akss_method")"
    akss_method_code="$(string -f "$android_key_store_spi_file" extract "$akss_line" ".end method")"
    ui_print "Method found: $akss_line"

    last_aput_obj="$(echo "$akss_method_code" | grep "aput-object" | tail -n1)"
    last_aput_obj="$(echo "$last_aput_obj" | sed -e 's/^[[:blank:]]*//')"
    leaf_cert_regex='s/^[[:blank:]]*aput-object[[:blank:]].[[:digit:]]+,[[:blank:]](.[[:digit:]]+),[[:blank:]].[[:digit:]]+$/\1/p'
    leaf_cert="$(echo "$last_aput_obj" | sed -nE "$leaf_cert_regex")"

    if [ -z "$leaf_cert" ]; then
        abort "Leaf certificate register not found in engineGetCertificateChain method"
    fi

    eng_get_cert_chain="
        invoke-static {$leaf_cert}, Lcom/android/internal/util/framework/Android;->engineGetCertificateChain([Ljava/security/cert/Certificate;)[Ljava/security/cert/Certificate;

        move-result-object $leaf_cert
    "
    ui_print " "
    ui_print "--------------------"
    ui_print "Patching engineGetCertificateChain method:"
    ui_print "$eng_get_cert_chain"
    ui_print "added."
    smali_kit -check -method "$akss_method" -file "$android_key_store_spi_file" -after-line "$last_aput_obj" "$eng_get_cert_chain"
    ui_print "--------------------"
    to_recompile=true
else
    ui_print "Skipped patch for AndroidKeyStoreSpi.smali"
fi

ui_print " "
ui_print "******************************"
ui_print "> Patching Instrumentation.smali file ..."
ui_print "******************************"
instrumentation_file="$(find "$TMP/framework" -type f -name "Instrumentation.smali")"
instrumentation_dex="$(classes_path_to_dex "$instrumentation_file")"
i_static_method="public static whitelist.*newApplication"
i_method="public whitelist.*newApplication"
ui_print "File found: $instrumentation_file"

if (! grep -wlq "$instrumentation_file" -e "$i_static_method") && (! grep -wlq "$instrumentation_file" -e "$i_method"); then
    i_static_method="public static newApplication"
    i_method="public newApplication"
    if (! grep -wlq "$instrumentation_file" -e "$i_static_method") && (! grep -wlq "$instrumentation_file" -e "$i_method"); then
        abort "newApplication method not in Instrumentation.smali"
    fi
fi

ui_print " "
ui_print "This patch is for spoofing system properties to pass Play Integrity."
ui_print "Do you want to apply this patch?"
ui_print "- YES  [Press volume UP]"
ui_print "- NO   [Press volume DOWN]"
ui_print " "

if $yes; then
    i_static_line="$(grep -w "$instrumentation_file" -e "$i_static_method")"
    i_static_method_code="$(string -f "$instrumentation_file" extract "$i_static_line" ".end method")"
    ui_print "Method found: $i_static_line"

    i_static_return="$(echo "$i_static_method_code" | tail -n1 | sed -e 's/^[[:blank:]]*//')"
    i_static_context="$(get_context_val "$i_static_method_code")"

    if [ -z "$i_static_context" ]; then
        abort "Context register not found in newApplication static method"
    fi

    static_new_app="
        invoke-static {$i_static_context}, Lcom/android/internal/util/framework/Android;->newApplication(Landroid/content/Context;)V
    "
    ui_print " "
    ui_print "--------------------"
    ui_print "Patching newApplication static method:"
    ui_print "$static_new_app"
    ui_print "added."
    smali_kit -check -method "$i_static_method" -file "$instrumentation_file" -before-line "$i_static_return" "$static_new_app"
    ui_print "--------------------"

    i_line="$(grep -w "$instrumentation_file" -e "$i_method")"
    i_method_code="$(string -f "$instrumentation_file" extract "$i_line" ".end method")"
    ui_print " "
    ui_print "Method found: $i_line"

    i_return="$(echo "$i_method_code" | tail -n1 | sed -e 's/^[[:blank:]]*//')"
    i_context="$(get_context_val "$i_method_code")"

    if [ -z "$i_context" ]; then
        abort "Context register not found in newApplication method"
    fi

    new_app="
        invoke-static {$i_context}, Lcom/android/internal/util/framework/Android;->newApplication(Landroid/content/Context;)V
    "
    ui_print " "
    ui_print "--------------------"
    ui_print "Patching newApplication method:"
    ui_print "$new_app"
    ui_print "added."
    smali_kit -check -method "$i_method" -file "$instrumentation_file" -before-line "$i_return" "$new_app"
    ui_print "--------------------"
    to_recompile=true
else
    ui_print "Skipped patch for Instrumentation.smali"
fi

ui_print " "
ui_print "******************************"
ui_print "> Patching ApplicationPackageManager.smali file ..."
ui_print "******************************"
app_package_manager_file="$(find "$TMP/framework" -type f -name "ApplicationPackageManager.smali")"
app_package_manager_dex="$(classes_path_to_dex "$app_package_manager_file")"
apm_method="public .*hasSystemFeature(Ljava/lang/String;)Z"
ui_print "File found: $app_package_manager_file"

if (! grep -wlq "$app_package_manager_file" -e "$apm_method"); then
    abort "hasSystemFeature method not found in ApplicationPackageManager.smali"
fi

ui_print " "
ui_print "This patch is optional but recommended if your device has StrongBox or app attestation key support."
ui_print "Do you want to apply this patch?"
ui_print "- YES  [Press volume UP]"
ui_print "- NO   [Press volume DOWN]"
ui_print " "

is_apm_patched=false
if $yes; then
    is_apm_patched=true
    apm_line="$(grep -w "$app_package_manager_file" -e "$apm_method")"
    apm_method_code="$(string -f "$app_package_manager_file" extract "$apm_line" ".end method")"
    ui_print "Method found: $apm_line"

    apm_return="$(echo "$apm_method_code" | tail -n1 | sed -e 's/^[[:blank:]]*//')"
    apm_move_result="$(echo "$apm_method_code" | grep -e "move-result *" | sed -e 's/^[[:blank:]]*//')"
    apm_has_sys_feature="$(echo "$apm_method_code" | grep "Ljava/lang/String;I)")"
    apm_name=""
    apm_last_reg=""
    if [ -n "$apm_has_sys_feature" ]; then
        apm_has_sys_feature="$(echo "$apm_has_sys_feature" | cut -d',' -f1-3)"
        apm_regex='s/^.+\{.[[:digit:]]+,[[:blank:]](.[[:digit:]]+),[[:blank:]](.[[:digit:]]+)\}$/\1;\2/p'
        apm_has_sys_feature="$(echo "$apm_has_sys_feature" | sed -nE "$apm_regex")"
        apm_name="$(echo "$apm_has_sys_feature" | cut -d';' -f1)"
        apm_last_reg="$(echo "$apm_has_sys_feature" | cut -d';' -f2)"
    fi

    if [ -z "$apm_name" ]; then
        is_apm_patched=false
        ui_print "Name register not found in hasSystemFeature method"
    fi

    if [ -z "$apm_last_reg" ]; then
        is_apm_patched=false
        ui_print "Last register not found in hasSystemFeature method"
    fi

    move_result_replacement="
    move-result $apm_last_reg
    "

    return_replacement="
    return $apm_last_reg
    "

    has_sys_feature="
    invoke-static {$apm_last_reg, $apm_name}, Lcom/android/internal/util/framework/Android;->hasSystemFeature(ZLjava/lang/String;)Z

    move-result $apm_last_reg
    "
    if [ "$is_apm_patched" = "true" ]; then
        ui_print " "
        ui_print "--------------------"
        ui_print "Patching hasSystemFeature method:"
        ui_print " "
        if ( ! echo "$move_result_replacement" | grep -qw "$apm_move_result" ); then
            ui_print "    $apm_move_result"
            ui_print " "
            ui_print "replaced by:"
            ui_print "$move_result_replacement"
            smali_kit -check -method "$apm_method" -file "$app_package_manager_file" -replace-in-method "$apm_move_result" "$move_result_replacement"
            ui_print "--------------------"
        fi
        ui_print "$has_sys_feature"
        ui_print "added."
        smali_kit -check -method "$apm_method" -file "$app_package_manager_file" -before-line "$apm_return" "$has_sys_feature"
        ui_print "--------------------"
        if ( ! echo "$return_replacement" | grep -qw "$apm_return" ); then
            ui_print " "
            ui_print "    $apm_return"
            ui_print " "
            ui_print "replaced by:"
            ui_print "$return_replacement"
            smali_kit -check -method "$apm_method" -file "$app_package_manager_file" -replace-in-method "$apm_return" "$return_replacement"
            ui_print "--------------------"
        fi
    else
        ui_print "Patching ApplicationPackageManager.smali failed"
    fi
else
    ui_print "Skipped patch for ApplicationPackageManager.smali"
fi

ui_print " "
if [ "$to_recompile" = "true" ]; then
    ui_print "******************************"
    ui_print "> Recompiling framework.jar ..."
    ui_print "******************************"
    ui_print "This may take a while, please wait."
    apktool b "$TMP/framework" -api "$API" --copy-original --output "$TMP/framework-patched.jar"

    ui_print " "
    ui_print "******************************"
    ui_print "> Setting up FrameworkPatch ..."
    ui_print "******************************"
    mkdir -p "$(dirname "$mod_framework")"
    unzip -qo "$stock_framework" -d "$TMP/framework-patched"
    unzip -qo "$TMP/framework-patched.jar" \
              "$android_key_store_spi_dex" \
              "$instrumentation_dex" \
              -d "$TMP/framework-patched"
    if [ "$is_apm_patched" = "true" ]; then
        unzip -qo "$TMP/framework-patched.jar" \
              "$app_package_manager_dex" \
              -d "$TMP/framework-patched"
    fi

    num_of_classes="$(find "$TMP/framework-patched" -maxdepth 1 -type f -name "classes*.dex" | wc -l)"
    mod_dex_name="classes$((num_of_classes+1)).dex"
    ui_print "$num_of_classes dex files found in framework.jar"
    ui_print "FrameworkPatch's compiled classes.dex renamed to $mod_dex_name and patched to framework.jar"
    mv "$classes_dex" "$TMP/framework-patched/$mod_dex_name"
    cd "$TMP/framework-patched" && zip -qr0 "$TMP/framework-patched.zip" .

    if [ ! -e "$TMP/framework-patched.zip" ]; then
        abort "Modifying framework.jar failed"
    fi

    ui_print "Optimising framework.jar with zipalign"
    zipalign -f -p -z 4 "$TMP/framework-patched.zip" "$mod_framework"
    if [ -e "$mod_framework" ]; then
        ui_print "Cleaning boot-framework files ..."
        ui_print " "
        ui_print "This step is not required unless your device crashes after installing this module."
        ui_print "Do you want to apply this step?"
        ui_print "- YES  [Press volume UP]"
        ui_print "- NO   [Press volume DOWN]"
        ui_print " "
        if $yes; then
            if [ "$BOOTMODE" ] && { [ "$KSU" ] || [ "$APATCH" ]; }; then
                find "/system/framework" -type f -name 'boot-framework.*' -print0 |
                    while IFS= read -r -d '' line; do
                        mkdir -p "$(dirname "$MODPATH$line")" && mknod "$MODPATH$line" c 0 0
                    done
            elif [ "$BOOTMODE" ] && [ "$MAGISK_VER_CODE" ]; then
                find "/system/framework" -type f -name 'boot-framework.*' -print0 |
                    while IFS= read -r -d '' line; do
                        mkdir -p "$(dirname "$MODPATH$line")" && touch "$MODPATH$line"
                    done
            fi
        else
            ui_print "Skipped cleaning boot-framework files"
        fi

        ui_print "Some final touches ..."
        rm -rf "$MODPATH/dex" "$MODPATH/func.sh" "$MODPATH/customize.sh"
        ui_print " "
        ui_print "FrameworkPatch set up successfully!"
    else
        ui_print " "
        abort "FrameworkPatch set up failed!"
    fi
else
    abort "No patch is applied at all."
fi
ui_print " "
