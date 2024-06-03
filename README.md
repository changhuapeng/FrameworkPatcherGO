# Framework Patcher GO
A Magisk/KernelSU/APatch module to modify framework.jar directly on the phone, to build a valid system-level certificate chain.

## How to use
1. If you're using your own keybox or fingerprint, you'll have to build `classes.dex` from [FrameworkPatch](https://github.com/chiteroman/FrameworkPatch/tree/69e08eff494b68ccd3ec71ffb04e0a798d7c686e) yourself. Open the project in Android Studio, add your keybox or fingerprint, and build a release build. Then extract the `classes.dex` file from the release .apk file.

   If you're not using your own keybox or fingerprint, A pre-compiled `classes.dex` is available [here](https://github.com/changhuapeng/FrameworkPatch/releases). This `classes.dex` is compiled from FrameworkPatch source and contains whatever keybox and fingerprint included there.

2. Copy the `classes.dex` file from previous step and paste it into `META-INF/com/google/android/magisk/dex` directory of this module.
3. Install the module and watch it happens on your device.

## Extra Info
XDA thread with FAQs @ https://xdaforums.com/t/module-framework-patcher-go.4674536/

> [!IMPORTANT]
> - Please ensure you do not have a modified /system/framework/framework.jar before installing the module.
> - This module is built specifically on this FrameworkPatch [commit](https://github.com/chiteroman/FrameworkPatch/tree/69e08eff494b68ccd3ec71ffb04e0a798d7c686e). Any updates to FrameworkPatch after this commit may break the module.
> - This module may cause bootloop or instability in devices. You are advised to familiarise yourself with the procedure for removing modules during bootloop.
>   - Magisk: https://topjohnwu.github.io/Magisk/faq.html
>   - KernelSU/APatch: https://kernelsu.org/guide/rescue-from-bootloop.html#brick-by-modules

## Credits
* [chiteroman/FrameworkPatch](https://github.com/chiteroman/FrameworkPatch)
* [Dynamic Installer](https://xdaforums.com/t/zip-dual-installer-dynamic-installer-stable-4-8-b-android-10-or-earlier.4279541/)
