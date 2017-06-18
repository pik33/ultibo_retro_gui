#!/bin/sh
DoExitAsm ()
{ echo "An error occurred while assembling $1"; exit 1; }
DoExitLink ()
{ echo "An error occurred while linking $1"; exit 1; }
echo Assembling retrokeyboard
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/retrokeyboard.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/retrokeyboard.s
if [ $? != 0 ]; then DoExitAsm retrokeyboard; fi
echo Assembling retromouse
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/retromouse.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/retromouse.s
if [ $? != 0 ]; then DoExitAsm retromouse; fi
echo Assembling retro
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/retro.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/retro.s
if [ $? != 0 ]; then DoExitAsm retro; fi
echo Assembling mp3
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/mp3.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/mp3.s
if [ $? != 0 ]; then DoExitAsm mp3; fi
echo Assembling retromalina
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/retromalina.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/retromalina.s
if [ $? != 0 ]; then DoExitAsm retromalina; fi
echo Assembling simpleaudio
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/simpleaudio.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/simpleaudio.s
if [ $? != 0 ]; then DoExitAsm simpleaudio; fi
echo Assembling unit6502
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/unit6502.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/unit6502.s
if [ $? != 0 ]; then DoExitAsm unit6502; fi
echo Assembling playerunit
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/playerunit.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/playerunit.s
if [ $? != 0 ]; then DoExitAsm playerunit; fi
echo Assembling screen
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/screen.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/screen.s
if [ $? != 0 ]; then DoExitAsm screen; fi
echo Assembling project1
/usr/bin/arm-none-eabi-as -mfloat-abi=hard -meabi=5 -march=armv7-a -mfpu=neon -o /home/pi/ultibo-retro-gui/lib/arm-ultibo/Project1.o  /home/pi/ultibo-retro-gui/lib/arm-ultibo/Project1.s
if [ $? != 0 ]; then DoExitAsm project1; fi
echo Linking Project1
OFS=$IFS
IFS="
"
/usr/bin/arm-none-eabi-ld -g     --gc-sections  -L. -o Project1.elf -T link.res
if [ $? != 0 ]; then DoExitLink Project1; fi
IFS=$OFS
echo Linking Project1
OFS=$IFS
IFS="
"
/usr/bin/arm-none-eabi-objcopy -O binary Project1.elf kernel7.img
if [ $? != 0 ]; then DoExitLink Project1; fi
IFS=$OFS
