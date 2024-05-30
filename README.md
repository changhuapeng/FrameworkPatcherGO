# Framework Patcher GO
A Magisk/KernelSU/APatch module to modify framework.jar directly on the phone, to build a valid system-level certificate chain.

## How to use
1. Build [FrameworkPatch](https://github.com/chiteroman/FrameworkPatch/tree/69e08eff494b68ccd3ec71ffb04e0a798d7c686e) as release-build using Android Studio and extract `classes.dex` from the release .apk file.
2. Copy the `classes.dex` file from previous step into `META-INF/com/google/android/magisk/dex` directory of this module.
3. Install the module and watch it happens on your device.

## Extra Info
> [!IMPORTANT]
> - This module is built specifically for this FrameworkPatch [commit](https://github.com/chiteroman/FrameworkPatch/tree/69e08eff494b68ccd3ec71ffb04e0a798d7c686e). Updates to FrameworkPatch after this commit may potentially break this module.
> - Please ensure your device do not have a patched or mounted /system/framework/framework.jar.
> - May cause bootloop or instability in devices. You are advised to familiar yourself with procedures in removing module when bootloop happens.
>   - Magisk: https://topjohnwu.github.io/Magisk/faq.html
>   - KernelSU/APatch: https://kernelsu.org/guide/rescue-from-bootloop.html#brick-by-modules

## Credits
* [FrameworkPatch](https://github.com/chiteroman/FrameworkPatch)
* [Dynamic Installer](https://xdaforums.com/t/zip-dual-installer-dynamic-installer-stable-4-8-b-android-10-or-earlier.4279541/)
