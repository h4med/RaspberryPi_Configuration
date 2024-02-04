# Raspberry Pi CM3 Configuration
Step by step guide to set up a Compute Module Raspberry Pi Model 3.

## Table of contents
- [Step1: Burning Image](#step1-burning-image)
  - [Raspberry Pi OS](#raspberry-pi-os)
  - [DietPi OS](#dietpi-os)
- [Step2: Headless set-up](#step2-headless-set-up)
  - [Static IP/DNS Address](#static-ipdns-settings)
  - [OTP and Setting MAC address](#otp-and-setting-mac-address)
  - [NTP Client Set-up](#ntp-client-set-up)
- [Step3: Necessary Software & SSH Settings](#step3-necessary-software--ssh-settings)
  - [Initializing Git](#initializing-git)
  - [Storage Management](#storage-management)
  - [sqlite commands](#sqlite-commands)
- [Step4: Adding RTC](#step4-adding-rtc)
  - [Time-zone correction for IRAN 2023](#time-zone-correction-for-iran-2023-irst)
- [Step5: Serial Ports](#step5-serial-ports)
- [Step6: Working with GPIO](#step6-working-with-gpios)
- [Step7: GSM/4G Module ](#step7-gsm4g-module)
- [Step8: CAN BUS setup using MCP2515](#step8-can-bus-setup-using-mcp2515)
---

## Step1: Burning Image
first you need to burn an Image on your Pi, I usually use one of the following options:

### Raspberry Pi OS
You can get it from [raspberrypi.com/software/operating-systems/](https://www.raspberrypi.com/software/operating-systems/).   
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
Default username and password for DietPi OS are **root/dietpi** and for Raspberry Pi OS is **pi/raspberry** unless you have changed it in settings in Imager before burning the image.
After first login you must change the default password either by login prompt or using ```passwd``` in any Linux.

### Static IP/DNS settings
Edit following file:
```
$ (sudo) nano /etc/network/interfaces
```
and set your desired IP address:
```
# Ethernet
allow-hotplug eth0
iface eth0 inet static
address 192.168.100.137
netmask 255.255.255.0
gateway 192.168.100.1
dns-nameservers 8.8.8.8 8.8.4.4
```
Raspberry Pi OS version 12 (Based on Debian 12 Bookworm) uses NetworkManager instead of dhcpcd. To change DNS settings use following command:
```
$ (sudo) nmcli device mod eth0 ipv4.dns "8.8.8.8 8.8.4.4"
```
Then restart NetwrokManager:
```
$ (sudo) systemctl restart NetworkManager
```
For setting Wifi using nmcli read [this blog](#https://www.jeffgeerling.com/blog/2023/nmcli-wifi-on-raspberry-pi-os-12-bookworm).

### OTP and Setting MAC address
CM3 uses the either board's serial number or MAC address written in OPT to set the MAC address. These are written for each CM3 in OTP (One Time Programmable) Memory. You can see [this PDF](/datasheets/Using-the-One-time-programmable-memory-on-Raspberry-Pi-single-board-computers.pdf) which explains OTP on Raspberry Pi SBCs. Run following command to display content of OTP:
```
$ vcgencmd otp_dump
```
Address 28 is serial number, 36-43 is for customer usage and 64-65 is for MAC address if set. By default MAC address in OTP is not set and by above command you get 0 in its address. To manually set MAC address you can run following commands:
```
mac0="70:b3:d5:04:c8:3c"
ip link set dev eth0 down
ip link set dev eth0 address $mac0
ip link set dev eth0 up
```
To add this procedure to startup in kernel 6.1 we should use **systemd**. Open in editor:
```
$ (sudo) nano /etc/systemd/system/macchanger.service
```
Write this:
```
[Unit]
Description=MAC Address Changer

[Service]
ExecStart=/path/to/your/script.sh

[Install]
WantedBy=multi-user.target
```
You have to give your path to script, for example [mac_add_setter.sh](/codes/mac_add_setter.sh). And finally:
```
$ (sudo) systemctl daemon-reload
$ (sudo) systemctl enable macchanger.service
$ (sudo) systemctl start macchanger.service
$ (sudo) systemctl status macchanger.service
```

### NTP Client Set-up
Step 1: Install NTP Package
```
$ (sudo) apt update
$ (sudo) apt install ntp
```
Step 2: Backup Existing Configuration (Optional)
```
$ (sudo) cp /etc/ntp.conf /etc/ntp.conf.backup
```
Step 3: Edit NTP Configuration File
```
$ (sudo) nano /etc/ntp.conf
```
Look for the lines starting with pool or server and comment them out by placing a # in front of them. Then, add the line below to specify the local NTP server.

```
server 192.168.0.1 iburst
```
Step 4: Restart NTP Service
```
$ (sudo) systemctl restart ntp
```
Step 5: Enable NTP Service to Start on Boot
```
$ (sudo) systemctl enable ntp
```
Step 6: Verify Configuration
After completing these steps, you should verify that the NTP client is properly synchronized with the server. You can do this by running:
```
$ ntpq -p
```

---
## Step3: Necessary Software & SSH Settings
Depending on your application you may need different software. Because I want to build C/C++ applications locally on CM3 and I also need Python I install following apps on DietPi (for Raspberry Pi Lite these are installed by default).
```
$ (sudo) apt update && apt install -y build-essential python3 automake autoconf
$ (sudo) apt install -y python3-smbus i2c-tools
$ (sudo) apt install -y can-utils
$ (sudo) apt install -y lsb-release
$ (sudo) apt install -y python3-pip
$ (sudo) apt install -y git
```
For installing docker:

```
$ curl -sSL https://get.docker.com | sh
```
After installing docker you may need to add your user to docker group.
```
$ (sudo) usermod -aG docker YOUR_USER
```
For removing dropbear and replacing it with openssh-server:
```
$ (sudo) apt install -y openssh-server
$ (sudo) apt purge --auto-remove dropbear
```   
After installing **openssh-server** you can set it up as a sftp-server for file transfer using [How to setup an SFTP server on Ubuntu](https://www.pcwdld.com/setup-sftp-server-on-ubuntu).
After installing openssh-server you should enable root login for dietpi by commenting out the following line in **/etc/ssh/sshd_config**
```
PermitRootLogin yes
```
To use VSCode remotely on your Raspberry Pi you can use **Remote SSH** extension on VSCode.
If you have problems installing it via VSCode, This is a good help for **[offline installation](https://medium.com/@debugger24/installing-vscode-server-on-remote-machine-in-private-network-offline-installation-16e51847e275)**   

If you needed to manually install CMake in case you needed the latest version not the version available in repository, [this is a good tutorial](https://linuxhint.com/3-ways-install-cmake-raspberry-pi/).

It is easier to copy your public key to CM3, first generate it on your PC:
```
ssh-keygen.exe
```
Then send it to target (here CM3):
```
ssh-copy-id user@server
```
or manually copy it to ```~/.ssh/authorized_keys```:
```
cat ~/.ssh/id_rsa.pub | ssh user@server 'mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys'
```
Then you can ssh to server using your private key:
```
ssh user@server -i ~/.ssh/id_rsa
```
After adding your public key to ```authorized_keys``` in CM3, you can use **Remote SSH** extension in **VSCode** to directly browse and develope on CM3.

### Initializing Git
If you want to initialize a git repo on a directory your of CM3 RPi these are the command:
```
$ git config --global user.name "Your Name"
$ git config --global user.email "you@youraddress.com"
$ git config --global push.default matching
$ git config --global alias.co checkout
$ git init
```

### Storage Management
With following command you can you can check the size of each directory:
```
du -hs .[^.]* * | sort -n
```
And the size of disk:
```
df -h
```
If you are using **DeitPi** you can run ```dietpi-cleaner``` utility to clean some cache or log files. With ```dietpi-drive_manager``` you can manage swap size or resize the disk if you need it.

### sqlite Commands
If you have a sqlite db on your embedded system you can use following commands to read tables:
Installation:
```
apt install sqlite3
```
Working with DB:
```
sqlite3 -column -header
.open db.sqlite3
.databases
.tables
SELECT * FROM style_meta;
.exit 
```
If you ever wanted to install MySQL(MariaDB) on your Raspberry P [this](https://linuxhint.com/setup-mysql-raspberry-pi/) is a good starting point.
After installation:
```
mysql -u root -p
CREATE DATABASE db_name;
USE db_name;
source /path/to/file.sql
```
---
## Step4: Adding RTC
In our carrier board we have a DS3231 RTC. [Here](https://learn.adafruit.com/adding-a-real-time-clock-to-raspberry-pi?view=all#set-up-and-test-i2c) is a good set up guide for this RTC.
We first should enable I2C-0 and configure the correct pins overlay according to our specific hardware design in **boot/config.txt** by adding following lines:
```
#-------i2c-------------
dtparam=i2c_arm=on
dtparam=i2c0=on
dtoverlay=i2c0,pins_28_29
dtoverlay=i2c-rtc,ds3231,i2c0
```
Here, the DS3231 is connect to I2C-0 by pins 28 and 29 of CM3. 
Detailed information regarding device tree configuration for Raspberry Pi can be found at **[Rpi Overlays](https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README)**.
After a reboot we can check that hardware set up is ok:
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
If instead of ``UU`` you see the address of chip such as ```0x68``` it means that RTC is detected but there is a problem with overlay settings. But if there is nothing in the output you should check the hardware and wiring.
Run the following commands:

```
apt -y remove fake-hwclock
update-rc.d -f fake-hwclock remove
systemctl disable fake-hwclock
```
And then follow the **systemd** settings based on the [Adafruit tutorial](https://learn.adafruit.com/adding-a-real-time-clock-to-raspberry-pi?view=all#raspberry-pi-oss-with-systemd-2026471).
We then set the time-zone using ```raspi-config``` or ```dietpi-config``` accordingly.
We can test that RTC works properly by this command:
```
# hwclock -r
2023-04-19 13:53:01.186700+03:30
```
You can use the following command to **read temperature** from DS3231 RTC:
```
cat /sys/bus/i2c/devices/1-0068/hwmon/hwmon1/temp1_input
```

### Time-zone correction for IRAN 2023 (IRST)
If your kernel is old and your time-zone for Iran is IRDT (Iran Daylight Time) then after March 20th 2023 your time shift for summer time is 4:30 instead of 3:30. You should change your time-zone to IRST (Iran Standard Time), copy this file: **[IRST/Iran-noDST](https://github.com/h4med/RaspberryPi_Configuration/tree/main/IRST)** to:
```
cp Iran-noDST /usr/share/zoneinfo/Asia/
```
Then change the sym-link to new file:
```
unlink /etc/localtime
ln -s /usr/share/zoneinfo/Asia/Iran-noDST /etc/localtime
```
---
## Step5: Serial Ports
As usual we first add the configuration to **/boot/config.txt** 
```
#---------uart---------------
dtoverlay=uart0,txd0_pin=14,rxd0_pin=15
dtoverlay=uart1,txd1_pin=32,rxd1_pin=33
```
After a reboot we check the serial ports:
```
# ls -l /dev/serial*
lrwxrwxrwx 1 root root 7 Aug  7  2022 /dev/serial0 -> ttyAMA0
lrwxrwxrwx 1 root root 5 Aug  7  2022 /dev/serial1 -> ttyS0
```
With a Usb-to-Serial hardware we can perform an echo test to check the actual hardware.

If you want to use serial console on a specific UART port you should change it in **/boot/cmdline.txt**, then change ```console=serial0,115200``` to what you need for example ```console=ttyAMA1,115200```

To send data to serial port from Linux command line you can simply use ```echo``` as follows:
```
echo "some text" > /dev/serial1
```
To receive data you can simpley use ```cat``` on the serial port:
```
# cat < /dev/serial1
some text
```
To retrieve the serial port settings:
```
# stty -F /dev/serial1
speed 9600 baud; line = 0;
-brkint -imaxbel
```
And to set the baudrate for example:
```
stty -F /dev/serial1 115200
```

---
## Step6: Working with GPIOs
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
In [code/gpio_test.c](https://github.com/h4med/RaspberryPi_Configuration/blob/main/codes/gpio_test.c) you can find a C program which turns on LED on GPIO3 for 1 second and then turns it off. You can build this program with following command:
```
gcc gpio_test.c -o gpio_test -lgpiod
```
Suppose we have a Push button in GPIO38, we can read it's status by following command:
```
gpioget gpiochip0 38
```
Here you can find a good tutorial for working with gpiod [libgpiod-intro-rpi](https://lloydrochester.com/post/hardware/libgpiod-intro-rpi/)

---
## Step7: GSM/4G Module 
We have a Quectel EC200T and we have to make and install the driver for CM3 USB bus.
first we install needed kernel headers:
```
apt install raspberrypi-kernel-headers
```
Then we copy or clone the drivers source from here: [Quectel_EC200T_Linux_USB_Driver](/Quectel_EC200T_Linux_USB_Driver)
 and then:
```
cd Quectel_EC200T_Linux_USB_Driver
make
make install
reboot
```
After reboot you should see 3 USB ports added:
```
# ls /dev/ttyUSB*
/dev/ttyUSB0  /dev/ttyUSB1  /dev/ttyUSB2
```
If you can not see the additional serial ports, you can debug with followint commands:
```
# lsusb -t
/:  Bus 01.Port 1: Dev 1, Class=root_hub, Driver=dwc_otg/1p, 480M
    |__ Port 1: Dev 2, If 0, Class=Hub, Driver=hub/3p, 480M
        |__ Port 1: Dev 3, If 0, Class=Vendor Specific Class, Driver=smsc95xx, 480M
        |__ Port 2: Dev 4, If 3, Class=Vendor Specific Class, Driver=option, 480M
        |__ Port 2: Dev 4, If 1, Class=CDC Data, Driver=cdc_ether, 480M
        |__ Port 2: Dev 4, If 4, Class=Vendor Specific Class, Driver=option, 480M
        |__ Port 2: Dev 4, If 2, Class=Vendor Specific Class, Driver=option, 480M
        |__ Port 2: Dev 4, If 0, Class=Communications, Driver=cdc_ether, 480M
```
And:
```
# cat /sys/kernel/debug/usb/devices
...
T:  Bus=01 Lev=02 Prnt=02 Port=01 Cnt=02 Dev#=  4 Spd=480  MxCh= 0
D:  Ver= 2.00 Cls=ef(misc ) Sub=02 Prot=01 MxPS=64 #Cfgs=  1
P:  Vendor=2c7c ProdID=6005 Rev= 3.18
S:  Manufacturer=Android
S:  Product=Android
S:  SerialNumber=0000
C:* #Ifs= 5 Cfg#= 1 Atr=e0 MxPwr=500mA
A:  FirstIf#= 0 IfCount= 2 Cls=02(comm.) Sub=06 Prot=00
I:* If#= 0 Alt= 0 #EPs= 1 Cls=02(comm.) Sub=06 Prot=00 Driver=cdc_ether
E:  Ad=87(I) Atr=03(Int.) MxPS=  64 Ivl=4096ms
I:  If#= 1 Alt= 0 #EPs= 0 Cls=0a(data ) Sub=00 Prot=00 Driver=cdc_ether
I:* If#= 1 Alt= 1 #EPs= 2 Cls=0a(data ) Sub=00 Prot=00 Driver=cdc_ether
E:  Ad=83(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
E:  Ad=0c(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
I:* If#= 2 Alt= 0 #EPs= 2 Cls=ff(vend.) Sub=00 Prot=00 Driver=option
E:  Ad=82(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
E:  Ad=0b(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
I:* If#= 3 Alt= 0 #EPs= 3 Cls=ff(vend.) Sub=00 Prot=00 Driver=option
E:  Ad=89(I) Atr=03(Int.) MxPS=  64 Ivl=4096ms
E:  Ad=86(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
E:  Ad=0f(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
I:* If#= 4 Alt= 0 #EPs= 3 Cls=ff(vend.) Sub=00 Prot=00 Driver=option
E:  Ad=88(I) Atr=03(Int.) MxPS=  64 Ivl=4096ms
E:  Ad=81(I) Atr=02(Bulk) MxPS= 512 Ivl=0ms
E:  Ad=0a(O) Atr=02(Bulk) MxPS= 512 Ivl=0ms
```
For configuration of the module you should install **minicom** and then run it:
```
apt install minicom
minicom -D /dev/ttyUSB2
```
To add the network connection we should add the following code to **/etc/network/interfaces**
```
# Ethernet EC200T (USB)
allow-hotplug usb0
iface usb0 inet dhcp
metric 1
```

## Step8: CAN BUS setup using MCP2515
To interface MCP2515 CAN controller ICs to SPI bus we should first enable SPI and then configure overlays accordingly in ```config.txt``` as follows:
```
#-------SPI-CAN---------
dtparam=spi=on
dtoverlay=mcp2515-can0,oscillator=24000000,interrupt=12

dtoverlay=spi1-1cs
dtoverlay=mcp2515,spi1-0,oscillator=24000000,interrupt=13
```
Please note that based on your hardware schematic pin configurations may differ. Then we add the configuration network settings in ```/etc/network/interfaces``` (don't forget to install canutils in [step3](#step3-necessary-software--ssh-settings))
```
# CAN settings
auto can0
iface can0 inet manual
    pre-up /sbin/ip link set can0 type can bitrate 1000000
    up /sbin/ifconfig can0 up
    down /sbin/ifconfig can0 down

auto can1
iface can1 inet manual
    pre-up /sbin/ip link set can1 type can bitrate 1000000
    up /sbin/ifconfig can1 up
    down /sbin/ifconfig can1 down
```
Then reboot. You can check ```dmesg``` or follwing directories to make sure everything is OK:
```
~# ls /sys/bus/spi/devices/
spi0.0  spi0.1  spi1.0
~# ls /sys/bus/spi/devices/spi0.0/net/
can1
~# ls /sys/bus/spi/devices/spi1.0/net/
can0
```
