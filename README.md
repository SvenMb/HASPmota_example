# Example using AZ-Touch MOD case with HASPmota

**Warning** using LVGL and Haspmota with a ESP32 without PSRam seems to be very unstable.

This small demo shows how to use the AZ-Touch Mode case, which integrates a ESP32-Devkit, a ILI9341 320x240 display with xpt2046 touch and a 5V regulator.

Following the basic install you can use display and touch for HASPmota or LVGL within tasmota. More documentation is here: https://tasmota.github.io/docs/HASPmota/

## Install

Simplest way to install a fitting tasmota on your ESP32-devkit is to use the [web-installer](https://tasmota.github.io/install/)
and install the Tasmota32-LVGL binary.

Configure the gpio-template, insert it in to the webinterface on "Configuration->Configure other"
~~~display.ini
{"NAME":"ESP32 AZ-Touch","GPIO":[0,1,1,1,800,768,0,0,1088,224,7264,448,6720,1184,736,672,1,480,1024,704,1,1,1,0,0,0,0,0,0,1,1,1,1,0,6210,1],"FLAG":0,"BASE":1}
~~~
When you check that gpio-config in "Configuration->Configure Template", you will find that I also added a SDCARD, a DHT11 and a relay, you can remove them there if you don't like them, they are not needed for basic functions.

You should now switch on the last two switches in that tasmota web-interface, they control the display-backlight and the display-controler, since tasmota has no backlight_i.

Then upload the [display.ini](https://raw.githubusercontent.com/SvenMb/HASPmota_example/main/berry/display.ini) via the tasmota webinterface (Consoles->Manage file System) to the root directory of this tasmota.

After a restart you should already see the Tasmota Logo. 

You can now use the normal tasmota display commands like displaymode and displaytext.

If you like to follow the HASPmota and LVGL examples, be aware that the current touch config (line :M in display.ini)
is correct only for displayrotate 2 and the 2.8" display variant.

A more complex configuration variant and some beery classes are found in the reminding files here.

## SDCard

if you like to use the SDCard, you have to connect SDCard_cs to GPIO-16 and SDCard-Miso, -Mosi, -Sck to the already connected DISPLAY-signals Miso/Mosi/Sck.
