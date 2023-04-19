# Raspberry Pi Configuration
Step by step guide to set up a Compute Module Raspberry Pi.

## Table of contents
- [Step1: Burning Image](#step1-burning-image)
  - [Raspberry Pi OS](#raspberry-pi-os)
  - [DietPi OS](#dietpi-os)
- [Step2: Headless set-up](#step2-headless-set-up)
- [Step3: Installing Necessary Software](#step3-installing-necessary-software)
- [Step4: Adding RTC](#step4-adding-rtc)
- [Step5: serial Ports](#step5-serial-ports)
- [Step6: Working with GPIOS](#step6-working-with-gpios)
---

## Step1: Burning Image
first you need to burn an Image on your Pi, I usually use one of the following options:

### Raspberry Pi OS
You can get it from [raspberrypi.com/software/operating-systems/](https://www.raspberrypi.com/sowftware/operating-systems/).   
You can choose 32bit or 64bit OS but my daily experience shows that 64bit version, as of now (Apr 2023), specially regarding Wifi is a bit unstable.   
So we download 32bit Lite version [Direct Link for February 21st 2023 version](https://downloads.raspberrypi.org/raspios_lite_armhf/images/raspios_lite_armhf-2023-02-22/2023-02-21-raspios-bullseye-armhf-lite.img.xz)
To burn the image you can use Raspberry Pi Imager: [raspberrypi.com/software/](https://downloads.raspberrypi.org/imager/imager_latest.exe)


### DietPi OS
Diet Pi is a trimmed version Debian for various embedded boards such as Raspberry Pi and with lots of utilities which help you to bootstrap start using tour board. You can get your Image [from here](https://dietpi.com/#downloadinfo), and This is the [Direct Link](https://dietpi.com/downloads/images/DietPi_RPi-ARMv8-Bullseye.7z)
For burning image I recommend Win32 Disk Imager which you can get from [here](https://sourceforge.net/projects/win32diskimager/) and [Direct Link](https://kumisystems.dl.sourceforge.net/project/win32diskimager/Archive/win32diskimager-1.0.0-install.exe)

---
## Step2: Headless Set-up
If you use DeietPi, SSH by default is enabled.   
For Raspberry Pi OS you should enable SSH either by settings in **Imager** or by just adding an **empty file** named ```ssh``` in the boot directory.
We will use nmap free software to find the Ip of Compute module. You can get it from [nmap.org/download](https://nmap.org/download).
With the following command we scan our desired range:
(Here we suppose the LAN range is ```192.168.137.xxx```)
```
nmap -sn 192.168.137.*
Starting Nmap 7.93 ( https://nmap.org ) at 2023-04-19 10:50 Iran Standard Time
Nmap scan report for 192.168.137.243
Host is up (0.0041s latency).
MAC Address: B8:27:EB:38:73:9C (Raspberry Pi Foundation)
```
Default username and password for DietPi OS are **root/dietpi**   
After first login you must change the default password either by login prompt or using ```passwd``` in any Linux.

---
## Step3: Installing Necessary Software
Depending on your application you may need different software. Because I want to build C/C++ applications locally on CM3 and I also need Python I install following apps on DietPi (for Raspberry Pi Lite these are installed by default).
```
apt update && apt install -y build-essential python3 automake autoconf
apt install -y python3-smbus i2c-tools
```   
**TODO: add later in case needed**   

---
## Step4: Adding RTC
In our carrier board we have a DS3231 RTC. [Here](https://learn.adafruit.com/adding-a-real-time-clock-to-raspberry-pi?view=all#set-up-and-test-i2c) is a good set up guide for this RTC.
We first should enable I2C-0 and configure the pins overlay according to our specific hardware design in **boot/config.txt** by adding following lines:
```
#-------i2c-------------
dtparam=i2c_arm=on
dtparam=i2c0=on
dtoverlay=i2c0,pins_28_29
dtoverlay=i2c-rtc,ds3231,i2c0
```
Here, the DS3231 is connect to I2C-0 by pins 28 and 29 of CM3. 
Detailed information regarding device tree configuration for Raspberry Pi can be found **[Rpi Overlays](https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README)**
After a reboot we check that hardware set up is ok:
```
# i2cdetect -y 0
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:                         -- -- -- -- -- -- -- --
10: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
20: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
30: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
40: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
50: -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- --
60: -- -- -- -- -- -- -- -- UU -- -- -- -- -- -- --
70: -- -- -- -- -- -- -- --

```
If instead of ``UU`` you see a number such as ```0x68``` it means that RTC is detected but there a problem with overlay settings. But if there is nothing in the output you should check the hardware and wiring.

```
apt -y remove fake-hwclock
update-rc.d -f fake-hwclock remove
systemctl disable fake-hwclock
```
And then follow the **systemd** settings based on the [Adafruit guide](https://learn.adafruit.com/adding-a-real-time-clock-to-raspberry-pi?view=all#raspberry-pi-oss-with-systemd-2026471).
We the set time-zone according using ```raspi-config``` or ```dietpi-config``` accordingly.
We can test that RTC working properly by this command:
```
# hwclock -r
2023-04-19 13:53:01.186700+03:30
```

---
## Step5: serial Ports
As usual we first add the configuration to **/boot/config.txt** 
```
#---------uart---------------
dtoverlay=uart0,txd0_pin=14,rxd0_pin=15
dtoverlay=uart1,txd1_pin=32,rxd1_pin=33
```
Then we check the serial ports:
```
# ls -l /dev/serial*
lrwxrwxrwx 1 root root 7 Aug  7  2022 /dev/serial0 -> ttyAMA0
lrwxrwxrwx 1 root root 5 Aug  7  2022 /dev/serial1 -> ttyS0
```
With a Usb-to-Serial hardware we can perform an echo test to check the actual hardware.
+ Todo: serial port test commands

---
## Step6: Working with GPIOS
For working with GPIOs in C/C++ we are using gpiod. We need to install the tools and required libs:
```
apt install -y gpiod libgpiod-dev
```
Then we can manually set GPIOs. Suppose GPIO2 and GPIO3 are connected to LEDs, with following commands we turn them ON and OFF.
```
# gpioset gpiochip0 2=1
# gpioset gpiochip0 2=0
# gpioset gpiochip0 2=1
# gpioset gpiochip0 2=0
# gpioset gpiochip0 3=1
# gpioset gpiochip0 3=0
# gpioset gpiochip0 3=1
# gpioset gpiochip0 3=0
```
For c program [code/gpio_test.c](https://github.com/h4med/RaspberryPi_Configuration/blob/main/codes/gpio_test.c) you can find a C program which turns on LED on GPIO3 for 1 second and then turns it off. We build the program:
```
gcc gpio_test.c -o gpio_test -lgpiod
```
Suppose we have a Push button in GPIO38, we can read it's status:
```
gpioget gpiochip0 38
```
Here you can find a good guid for gpiod [libgpiod-intro-rpi](https://lloydrochester.com/post/hardware/libgpiod-intro-rpi/)

---
## Step7: GSM/4G Module 
todo.