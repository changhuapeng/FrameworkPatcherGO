# Framework Patcher GO
A Magisk/KernelSU/APatch module to modify framework.jar directly on the phone, to build a valid system-level certificate chain.

## How to use
#### If you have your own keybox or fingerprint:
1. Open [FrameworkPatch](https://github.com/chiteroman/FrameworkPatch/tree/69e08eff494b68ccd3ec71ffb04e0a798d7c686e) project in Android Studio.
2. Add your keybox or fingerprint to `Keybox.java` or `Android.java` respectively and do a release build.
3. Extract compiled `classes.dex` from the release .apk file.
4. Copy the `classes.dex` file and paste it into `META-INF/com/google/android/magisk/dex` directory of this module.
5. Install the module in your root manager app.

#### If you do not have your own keybox or fingerprint:
1. Simply install the module. The module script will prompt you to download the required `classes.dex` file during installation.

##### Alternatively, if you prefer to do it manually:

<ol start="1">
   <li>Download a pre-compiled <code>classes.dex</code> <a href="https://github.com/changhuapeng/FrameworkPatch/releases">here</a>. This <code>classes.dex</code> is compiled from FrameworkPatch source and contains whatever keybox and fingerprint included there.</li>
   <li>Copy the <code>classes.dex</code> file and paste it into <code>META-INF/com/google/android/magisk/dex</code> directory of this module.</li>
   <li>Install the module in your root manager app.</li>
</ol>

## Extra Info
XDA thread with FAQs @ https://xdaforums.com/t/module-framework-patcher-go.4674536/

> [!IMPORTANT]
> - Please ensure you do not have a modified /system/framework/framework.jar before installing the module.
> - This module is built specifically on this FrameworkPatch [commit](https://github.com/chiteroman/FrameworkPatch/tree/69e08eff494b68ccd3ec71ffb04e0a798d7c686e). Any updates to FrameworkPatch after this commit may break the module.
> - This module may cause bootloop or instability in devices. You are advised to familiarise yourself with the procedure for removing modules during bootloop.
>   - Magisk: https://topjohnwu.github.io/Magisk/faq.html
>   - KernelSU: https://kernelsu.org/guide/rescue-from-bootloop.html#brick-by-modules
>   - APatch: https://apatch.top/rescue-bootloop.html

## Credits
* [chiteroman/FrameworkPatch](https://github.com/chiteroman/FrameworkPatch)
* [Dynamic Installer](https://xdaforums.com/t/zip-dual-installer-dynamic-installer-stable-4-8-b-android-10-or-earlier.4279541/)
