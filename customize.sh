#!/sbin/sh
#Require DI v4.8+

#For the DI this "customize.sh" serves only as a method to call the update-binary that loads the real installation
#It is only useful if the module is designed to also work in KernelSU or external Managers other than Magisk

# You can define SPECIAL VARIABLES here:
# (To avoid compatibility issues with future implementations)
#-----------SPECIAL VARS-----------#
SKIPUNZIP=0
#----------------------------------#

#You can define which additional variables should be shared with the DI
SHARED_VARS="

MODPATH
SKIPUNZIP
SKIPMOUNT
PROPFILE
POSTFSDATA
LATESTARTSERVICE
KSU
KSU_VER
KSU_VER_CODE
KSU_KERNEL_VER_CODE
ARCH

"
#YOU DON'T NEED TO TOUCH ANYTHING FROM HERE!

#Exporting the SPECIAL VARIABLES ensures that they are also shared with the DI
export SHARED_VARS $SHARED_VARS
#Get update-binary
binary="META-INF/com/google/android/update-binary"
binaryout="$TMPDIR/$binary"
unzip -qo "$ZIPFILE" "$binary" -d "$TMPDIR"
if [ -f "$binaryout" ]; then
   . "$binaryout"
else
    abort "SETUP: Can't get update-binary"
fi
