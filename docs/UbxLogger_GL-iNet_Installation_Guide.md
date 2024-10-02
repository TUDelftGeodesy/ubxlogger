# UbxLogger installation for GL-iNet 4G routers

**Hans van der Marel, TU Delft, September, 2024.**

This guides covers the installation and set-up of `UbxLogger` on a **GL-iNet** 4G router.
The guide is specifically written for the `GL-X750V2 / Spitz` with `OpenWrt 22.03.4`, but will 
be similar on other GL-iNet 4G models with OpenWrt.

GL-X750 Spitz is a 3G/4G dual-band wireless router running OpenWRT OS. It has built-in mini PCIe 3G/4G 
module, built-in *128GB MicroSD capacity* and *USB-A* port. Of course, it also has 2GHz/5GHz Wi-Fi, LAN and WAN
ports seen on most other routers. 
Running on OpenWrt you can compile your own firmware an software to fit for different application 
scenarios. 

This makes it an ideal controller for GNSS receiver boards, such as the `U-blox ZED-F9P`, which can be
directly connected to and powered by the USB-A port on the router. The `UbxLogger` scripts running on
OpenWrt saves the raw receiver data to the router's MicroSD card, optionally converts it into RINEX and
optionally send it to an upstream server using the 4G connection. 

Regular usage instructions are given in the [UbxLogger Hardware Manual][1] and [UbxLogger Software Manual][2]. 
This guide deals with installation and setup process.

## Setting up

To get started

1. Insert the MicroSIM card and ext4 formatted MicroSD/TF card and attach the two 4G antenna's. 
   *Hot plug for MicroSD/TF and MicroSIM card is not supported! Always power-off the router before swapping cards.*
2. Power on the router. 
3. Connect to the 2GHz WiFi called GL-X750-xxx (or connect via LAN). The default password is `goodlife`. This will be changed later.
4. Visit `http://192.168.8.1` in your browser to set up your router.

The setup process is very straightforward and self explanatory. For security reasons select a strong root password
`*secret-2*` and also change the default WiFi password *goodlife* to `*secret-1*`.

Also select `UTC` as time-zone for the local time; `crontab` works with local time, and we want to have this synchronized to `UTC`.

After these steps you should have a working router with Internet connectivity.

For more information on the GL-iNet Spitz see https://www.gl-inet.com/products/gl-x750/ or check out https://openwrt.org/start for working with OpenWrt.

## GL-iNet configuration 

### Interfaces

The GL-iNet router has three main user interfaces

1. GL-iNet Web Admin Panel (http://192.168.8.1)
2. OpenWrt LuCI web user interface (http://192.168.8.1/cgi-bin/luci)
3. SSH to the router BusyBox ash shell ()`ssh root@192.168.8.1`)

The first is a Grafical User Interface (GUI) for standard settings
and firmware upgrades. The second is a GUI to do more advanced settings with `OpenWrt LuCI`. Many
tasks can be done in both GUI, but not everything. The third is a Command Line Interface (CLI)
which will be used for setting up regular Linux stuff and `UbxLogger`.

### Installing plug-ins

Plug-ins can be installed from the `GL-iNet Web Admin Panel -> Applications -> Plug-ins`,
or from `OpenWrt LuCI -> System -> Software`, or from the CLI using  the `oplg` package manager.

A few plugins need to be installed to be able to use MicroSD card storage and to install some
prerequisites for `UbxLogger`.These are described in the next section

### Mount the MicroSD card

To use the Micro SD card the `ext4` filesystem driver need to be installed.

> opkg install kmod-fs-ext4

If you need to create and fix ext4 partitions, also install 

> opkg install e2fsprogs

To see what filesystems are currently supported, enter `cat /proc/filesystems`.

Next, in `OpenWrt LuCI -> System -> Mount points`, in the section on `Moint Points`, 
select the device, click on the `Edit` button, and enter as mount point `/mnt/sdcard`,
and click on `Save`. Then click on `Save and Apply` to complete the process.

**Check->** is it necessary to create sdcard folder first? 

Now you should be able to see the mounted SD card under Mounted file systems and the
SD card is ready to be used. 

### str2str plug-in

There are plug-ins for RTLKIB's `str2str` and `convbin`. The `str2str` plug-in is working
quite well.  However, though the `convbin` plug-in installs and does not crash, it 
fails to convert ZED-F9P raw data files to RINEX. The reason for this is that `ublox.c`, which deals with decoding raw U-blox data, and is used by `convbin` and other RTKLIB applications, does not work on big endian systems out of the box.  

To get started quickly install the `str2str` plug-in. 

If you want also to convert raw data file into RINEX then you need cross compiled versions of 
RTKLIB's `convbin`, using modified source code for `ublox.c`, and Hatanaka's `rnx2crx`. 
See the section on cross-compiling on how to achieve this. Compiled versions for the GL-iNet are 
available as downloads.

## Set up `UbxLogger`

## Installing

To install `UbxLogger` :

1. Change directory to the sd card root with `cd /mnt/sdcard/`
2. Download the `UbxLogger` software form `github` and unpack

   >  curl https://github.com/hvandermarel/ubxlogger/releases/ubxlogger.tar.gz -o ./ubxlogger.tar.gz \
   >  tar -xzf ubxlogger.tar.gz

   This will create the basic directory structure, with scripts and example configuration files.

   **check->** creating symbolic links to the correct scripts

3. Download the precompiled executable files from `github` and unpack

   >  curl https://github.com/hvandermarel/ubxlogger/releases/openwrt-mips.tar.gz -o ./openwrt-mips.tar.gz \
   >  tar -xzf openwrt-mips.tar.gz

   This will install the executables in the `ubxlogger/bin` directory. `openwrt-mips` is the architecture used by the `GL-iNet X750`.  For other systems and OS change the download accordingly. Currently available executables are `openwrt-mips` and `raspberry-pi`. 

4. Change directory to the `ubxlogger` directory with `cd ubxlogger`

5. Choose an appropriate 9-character `identifier` for each of your systems. You need this `identifier` to
   make settings in the configuration files. The `identifier` will also be the first part
   of the ubx and RINEX file names. 

   At this phase, if you don't plan on logging navigation files, it is also comes in handy to write down the approximate coordinates of the receiver(s).

6. Edit the script configuration file with `vi`, enter the command  `vi scripts/ubxlogger.config`, and then

   -  Set the USB port number (device path) for one or more receivers, e.g. with two devices, and a hub it will be something like 

      > devpath_NAMExxTS1=1.3.1\
      > devpath_NAMExxDF1=1.3.2

      with a single device, without hub, it will be something like 
   
      > devpath_NAMExxTS1=1.3

      Replace "NAMExxTS1" and/or "NAMExxDF1" with the appropriate `identifier` that you plan on using. The actual device numbers depend on the number of hubs and port on the hub your are using.
   
   - Adjust the remote upload url's and authorizations for curl:

     > #remoteubx=ftp://sub.subdomain.domain/ubx/\\${year}/\\${doy}/ \
     > remoteubx=\
     > remoternx=ftp://sub.subdomain.domain/rinex/\\${year}/\\${doy}/ \
     > authubx="-u username:password"\
     > authrnx="-u username"password"

   Leave a remote upload url empty in case you don't want to upload a particular type of file. 

   See the [software manual][2] for detailed description of the options and instructions on how to 
   determine the USB port numbers. If you use a hub, do not forget to **label the port numbers on the hub**. 

6. In case you plan to do a conversion to RINEX, as is the case in the example of the previous step, create a configuration file for each receiver in the `spool/` directory. This goes as follows

   > cp spool/NAMExxTS1.cfg spool/'identifier'.cfg \
   > vi spool/'identifier'.cfg

   Replace `identifier` with the value(s) that you selected. If you don't plan on logging navigation data - something that we recommend not to do - then you need to enter also the 
   approximate coordinates of the station in the configuration file.   

   **check->** creating symbolic links to executables in `spool/`

In this phase of the installation process the software is fully functional and can be started and stopped manually, as is decribed in the [software manual][2]. 

To automatically start tasks on the server we use the `crontab`.

### Crontab

By default OpenWrt does not enable the cron service. To start it and enable automatic startup during subsequent reboots, you need to execute the following commands once:

> /etc/init.d/cron start\
> /etc/init.d/cron enable

The first command starts the cron service once, but does not change the startup configuration, so it will not be started automatically after a reboot. 
The second command changes the startup configuration (creates a symlink in `/etc/rc.d`) so that the cron service will be started during boot, 
but does not start it immediately.

Next thing, is to edit the `crontab` file in `ubxlogger/scripts`, and inform `crontab` to use this file

> cd /mnt/sdcard/ubxlogger/\
> vi scripts/crontab\
> crontab scripts/crontab

The crontab can be inspected with the `crontab -l` command or in the GUI `OpenWrt LuCI -> System -> Scheduled tasks`.

`crontab` works with local time. To have this synchronized with `UTC` make sure that you're local time is set to `UTC`.


### Start on (re)boot

Crontab on OpenWrt does not support the `@reboot` directive. This means that, after a (re)boot, the ubx logging is only started at the regular `ubxlogd check 'identifier'` intervals, typically every 57 minutes after the hour. Worst case scenario is that it takes one hour to start after a reboot.

To enable start on (re)boot the script `notyetdone` must be copied to /etc/init.d .
**This script is not yet implemented**

## Remote connections

So far we accessed the router using it's webinterfaces and ssh from the local network through WiFi or a LAN cable.

To access the router remotely through the 4G LTE interface some additional setup is needed (unless the router has a public ip, but then you definitely want to setup the firewall).

### GL-iNet GoodCloud

The easiest way to achieve remote connectivity over the 4G or WAN network is via GL-iNet's [GoodCloud](https://www.goodcloud.xyz/#/login) 
Cloud Management Software. *GoodCloud* uses reverse `ssh` to set up a long lasting connection. The connection is initiated by the 
router, so as long as the router can connect to the Internet your are okay. No hassle with firewalls, dynamic DNS, etc.

First, enable GoodLife in the admin Web interface on the router. Then, create an account on *GoodCloud*, and bind the device
using information that can be found on the back of the router. If all is well, the device will appear in the GoodCloud dashboard.
You can use remote GUI and remote ssh from the GoodCloud website to connect to the router.

GoodCloud is free software with unlimited number of devices. There is a paid enterprise edition with more functions, but this is not needed. 


### Dynamic DNS (DDNS)

Dynamics DNS (DDNS) is not needed with GoodCloud. The ip number can be retrieved from the GoodCloud interface. 

However, it is a good idea to setup a dynamic DNS as backup, so that you can use a webbrowser and ssh to access the
router remotely over the 4G network (except when CG-NAT is used by the telecom provider). If you do this, it is
a good idea to limit the ip-range with access by setting the appropriate firewall rules.

You also need to enable access from the WAN to ports 80 and 22 . 

**HM: check if this works**

### Firewall settings

No modifications in the firewall settings are needed when *GoodCLoud* is used. 

In case Dynamic DNS (DDNS) is used, or, if the system has a public ip, and ssh and/or web access are enabled, then it will be definitely necessary to add firewall rules to limit access to certain ip-ranges. 

### Reverse ssh and other cloud platforms

It is possible to initiate reverse ssh to your own server or use alternative cloud platforms. 
This is beyond the material covered by this installation manual.


## Using `UbxLogger`

The `ubxlogger` commands and folder structure are described in [UbxLogger Software Manual][2]. Refer to this document for starting
and stopping the `ubxlogd` deamon and automated conversion and file transfer.


## Further reading

[1]. H. van der Marel (2024), UbxLogger Hardware Manual, TU Delft, September 2024.\
[2]. H. van der Marel (2024), UbxLogger Software Manual, TU Delft, September 2024.


[1]: <UbxLogger_Hardware_manual.md> "H. van der Marel (2024), UbxLogger Hardware Manual, TU Delft, September 2024."
[2]: <UbxLogger_Software_manual.md> "H. van der Marel (2024), UbxLogger Software Manual, TU Delft, September 2024."

## Appendices

## Appendix I: Cross compiling OpenWrt programs

To cross compile a C program for OpenWrt you need a linux system for making the `OpenWrt build environment`. 
Ubuntu is an obvious choice. Windows 10 users can use Windows Subsystem for Linux.

A good guide  for getting started with OpenWrt C Programing is https://electrosome.com/cross-compile-openwrt-c-program/.
The official OpenWrt developer information can be bound at https://openwrt.org/docs/guide-developer/start and specifically
https://openwrt.org/docs/guide-developer/toolchain/install-buildsystem for installing the build system.


### OpenWrt build system information

OpenWrt 22.03.4, r20123-38ccc47687

Qualcomm Atheros QCA9533 ver 2 rev 0
GL.iNet GL-X750
MIPS 24Kc V7.4

### Building RTKLIB's str2str and convbin

RTLKIB's `str2str` and `convbin` can be installed as plug-ins. These are however not the latest
versions. 

With the ready made `str2str` plug-in we have obtained good results and seems to be reliable. 

However, the ready made `convbin` plug-in is unable to convert the ZED-F9P ubx raw data files to RINEX.
**\<\<Produce cross compiled version using RTKLib Explorer `b34k` and test on Gl-iNet.\>\>**

### Building Hatanaka's rnx2crx and crx2rnx compression

There are no plug-ins for `rnx2crx` and `crx2rnx`. **\<\<We have to make these ourself.\>\>**

### Cross-compiling on Linux Mint virtual machine

Install necessary developer tools on the Linux Mint virtual machine 

> sudo apt update
> sudo apt install build-essential clang flex bison g++ gawk gcc-multilib g++-multilib gettext git libncurses-dev libssl-dev 
> sudo apt install python3-setuptools rsync swig unzip zlib1g-dev file wget

Install the OpenWrt development environment with cross-compiles

> git clone https://github.com/openwrt/openwrt.git
> cd ~/openwrt
> ./scripts/feeds update -a
> ./scripts/feeds install -a
> make menuconf
> make -j1 V=s
> cp openwrt-config.sh  ../software/

> cd ~/software
> wget https://terras.gsi.go.jp/ja/crx2rnx/RNXCMP_4.1.0_src.tar.gz
> tar -xzf RNXCMP_4.1.0_src.tar.gz 
> source openwrt-config.sh 
> mips-openwrt-linux-gcc -o rnx2crx RNXCMP_4.1.0_src/source/rnx2crx.c
> mips-openwrt-linux-gcc -o crx2rnx RNXCMP_4.1.0_src/source/crx2rnx.c 

> cd ~/software
> git clone https://github.com/rtklibexplorer/RTKLIB.git
> cd RTKLIB/app/consapp
> cd convbin
> mkdir openwrt
> cd openwrt
> cp ../gcc/makefile ./
> nano makefile
> make
> cp convbin ~/software
> cd ../../str2str
> mkdir openwrt
> cp makefile ../openwrt/
> cd ../openwrt/
> nano makefile
> make
> cp str2str ~/software

> cd ~/software
> mkdir openwrt-mips
> mv convbin openwrt-mips/
> mv str2str openwrt-mips/
> mv rnx2crx openwrt-mips/
> mv crx2rnx openwrt-mips/
> tar -cf openwrt-mips.tar openwrt-mips/*


## Appendix II: Differences with other models (and brands)

Spitz (GL-X750V2) is the advanced version of older model Spitz (GL-X750). It comes with the redesigned PCBA and optimized 
antennas to improve the 4G performance.GL-iNet 4G routers support 

Puli (GL-XE300) is designed to develop DIY IoT project. It comes with a rechargeable battery, 512GB MicroSD capacity
and an extra NAND Flash 128MB compared to Spitz (GL-X750V2). The downside is that the Puli has internal antennas and 
no connectors for external antenna's. 

Teltonika RUT240/RUT241 runs on RUTOS (based on OpenWrt) and has no USB-A port or MicroSD card capability. This is fine
for Septentrio Mosaic-X5 receiver boards with an Ethernet interface and Micro SD card. Other receiver boards, without
Ethernet or SD card, including ZED-F9P, Mosaic-GO and older SimpleRTK3B models (without SD card), require a Raspberry Pi 
(Zero) to interface with the receiver.

Teltonika RUT956 (Available Q3/2024) has build in Micro SD capability and USB-A port. It runs on OpenWrt based RUTOS instead
of OpenWrt itself and has its own development kit. It is more expensive than the GL-iNet Spitz. 
