# Raspberry Pi Configuration
Step by step guide to set up a Compute Module Raspberry Pi.

## Table of contents
- [Step1: Burning Image](#step1-burning-image)
  - [Raspberry Pi OS](#raspberry-pi-os)
  - [DietPi OS](#dietpi-os)

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
## Step2: Headless set-up
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
apt update && apt install -y  build-essential python3 automake autoconf
```