#!/bin/bash

# build on raspbian, windows, and windows/appveyor

PROJECT=Project1.pas

function build-message {
    if [[ "$APPVEYOR" == "True" ]]
    then
        appveyor AddMessage $*
    else
        echo $*
    fi
}

if [[ "$HOME" == "/home/pi" ]]
then
    COMPILER=/home/pi/ultibo/core/fpc/bin/fpc
    EXTRA=-XParm-none-eabi-
    CFG=@/home/pi/ultibo/core/fpc/bin/rpi3.cfg
else
    COMPILER=/c/Ultibo/Core/fpc/3.1.1/bin/i386-win32/fpc
    EXTRA=
    CFG=@/c/Ultibo/Core/fpc/3.1.1/bin/i386-win32/RPI3.CFG
fi

build-message "compiling $PROJECT"
$COMPILER \
 -a \
 -al \
 -B \
 -Tultibo \
 -Parm \
 -CpARMV7A \
 -WpRPI3B \
 -Scg \
 -FElib/arm-ultibo \
 $EXTRA \
 $CFG \
 -O2 \
 $PROJECT
