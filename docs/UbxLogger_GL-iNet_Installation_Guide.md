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

## Prerequisites

You will need an activated SIM card and `ext4` formatted MicroSD/TF card.
If you have a MicroSD/TF card with a file system other than `ext4`, 
we recommend to first reformat the card on a different linux system. For instance, on 
a Rapberry Pi the command for this is

> sudo mkfs.ext4 /dev/sda1

The alternative is to reformat the card using the router, but this
requires some extra steps that are discussed later.

## Setting up

To get started

1. Insert the MicroSIM card and MicroSD/TF card and attach the two 4G antenna's. 
   *Hot plug for MicroSD/TF and MicroSIM card is not supported! Always power-off the router before swapping cards.*
2. Power on the router. 
3. Connect to the 2GHz WiFi called GL-X750-xxx (or connect via LAN). The default password is `goodlife`. This will be changed later.
4. Visit `http://192.168.8.1` in your browser to set up your router.

The setup process is very straightforward and self explanatory. For security reasons select a strong root password
`*secret-2*`. The next steps are to 

- configure the 4G,
- change the default WiFi key *goodlife* to `*secret-1*`, do this for 2.4G and 5G, and reconnect with the new WiFi key,
- check that the timezone is set to  `UTC`, because `crontab` works with local time, 
and we want to have this synchronized to `UTC`. Ignore the warning that the
timezone is different from the browser.

After these steps you should have a working router with Internet connectivity.

At this time it might also be good to update the firmware of your router to the latest version,
especially when the router is still on version 3. 

For more information on the GL-iNet Spitz see https://www.gl-inet.com/products/gl-x750/ or check out https://openwrt.org/start for working with OpenWrt.

## GL-iNet configuration 

### Interfaces

The GL-iNet router has three main user interfaces

1. GL-iNet Web Admin Panel (http://192.168.8.1)
2. OpenWrt LuCI web user interface (http://192.168.8.1/cgi-bin/luci)
3. SSH to the router BusyBox ash shell (`ssh root@192.168.8.1`)

The first is a Grafical User Interface (GUI) for standard settings
and firmware upgrades. The second is a GUI to do more advanced settings with `OpenWrt LuCI`. Many
tasks can be done in both GUI, but not everything. The third is a Command Line Interface (CLI)
which will be used for setting up regular Linux stuff and `UbxLogger`.

### Installing plug-ins

Plug-ins can be installed from the `GL-iNet Web Admin Panel -> Applications -> Plug-ins`,
or from `OpenWrt LuCI -> System -> Software`, or from the CLI using  the `oplg` package manager.
At this time it is a good idea to update the package list and install `usbutils` (for the `lsusb` 
command)

> opkg update\
> opkg install usbutils

A few plugins need to be installed to be able to use MicroSD card storage and to install some
prerequisites for `UbxLogger`.These are described in the next section

### Mount the MicroSD card

To use the Micro SD card the `ext4` filesystem driver need to be installed.
If the Micro SD card that was inserted is already formatted as `ext4`, 
there is a good chance that the drivers are already installed. In that 
case the Micro SD card is mounted on `/mnt/sda1` and you can proceed with the next section.

If the Micro SD card is not mounted, or not formatted as `ext4`, install the `ext4` 
drivers

> opkg install kmod-fs-ext4

If you need to create and fix `ext4` partitions, also install 

> opkg install e2fsprogs

To see what filesystems are currently supported, enter `cat /proc/filesystems`.
If you need to create an `ext4` partition the command is `mkfs.ext4 /dev/sda1`.

Next, in `OpenWrt LuCI -> System -> Mount points`, in the section on `Moint Points`, 
select the device, click on the `Edit` button, and enter as mount point `/mnt/sda1`,
and click on `Save`. Then click on `Save and Apply` to complete the process.

Now you should be able to see the mounted SD card under `Mounted file systems` and the
SD card is ready to be used. 

## Download and install `UbxLogger` software

To install the `UbxLogger` software download the installation script, run and follow the instructions

> curl -L https://github.com/hvandermarel/ubxlogger/raw/refs/heads/main/sys/ubxlogger_install_part1.sh -o install.sh \
> ./install.sh

The script will guide you step by step through the installation process providing sensible defaults. When the script
finishes the software and executable are installed on the micro SD card, and the user is provided with some
guidance on how to proceed with the second part of the installation.

The second part of the installation is done by a separate script that is installed along with
the software. To run the second part of the install

>   cd /mnt/sda1/ubxlogger \
>   ./sys/openwrt-mips/scripts/ubxlogger_install_part2.sh

For other platforms replace *openwrt-mips* with one of the architectures provided in the `ubxdir/sys` folder.

This script will create symbolic links to the executable and scripts installed during the first step, install 
necessary packages, enable crontab and add a service (`cronatreboot`) to resume logging after a reboot. 

The script will provide you with the option to install RTKLIB's `str2str` using an OpenWrt package or 
to a more recent `str2str` that comes with this download. We recommend to use the OpenWrt package.    

**Important note**: The second part of the install must be repeated after a firmware upgrade! A firmware
upgrade will install a clean system and all additions to the system directories are lost. The ubxlogger 
software itself, which is installed on the microSD card, will not be erased by a firmware update.

More details on the installation process are provided in Appendix I.

## Set up `UbxLogger`

To configure `UbxLogger`

1. Choose an appropriate 9-character `identifier` for each of your systems. You need this `identifier` to
   make settings in the configuration files. The `identifier` will also be the first part
   of the ubx and RINEX file names. 

   At this phase, if you don't plan on logging navigation files, it is also relevant to obtain the approximate coordinates of the receiver(s).

2. Edit the script configuration file with `vi`, enter the command  `vi scripts/ubxlogger.config`, and then

   -  Set the USB port number (device path) for one or more receivers, e.g. for a single device, without hub, it will be something like 
   
      > devpath_NAME00CCC=1.3

      with two devices, and a hub, it could be something like 

      > devpath_NAME00CCC=1.3.1\
      > devpath_SCND00CCC=1.3.2

      Replace "NAME00CCC" and/or "SCND00NLD" with the appropriate `identifier` that you plan on using. The actual device numbers depend on the number of hubs and port on the hub your are using.
   
   - Adjust the remote upload url's and authorizations for curl:

     > #remoteubx=ftp://sub.subdomain.domain/ubx/\\${year}/\\${doy}/ \
     > remoteubx=\
     > remoternx=ftp://sub.subdomain.domain/rinex/\\${year}/\\${doy}/ \
     > authubx="-u username:password"\
     > authrnx="-u username"password"

   Leave a remote upload url empty in case you don't want to upload a particular type of file. 

   See the [software manual][2] for detailed description of the options and instructions on how to 
   determine the USB port numbers. If you use a hub, do not forget to **label the port numbers on the hub**. 

3. In case you plan to do a conversion to RINEX, as is the case in the example of the previous step, create a configuration file for each receiver in the `spool/` directory. This goes as follows

   > cp spool/NAME00CCC.cfg spool/'identifier'.cfg \
   > vi spool/'identifier'.cfg

   Replace `identifier` with the value(s) that you selected. If you don't plan on logging navigation data - something that we recommend not to do - then you need to enter also the 
   approximate coordinates of the station in the configuration file.   

In this phase of the installation process the software is fully functional and can be started and stopped manually, as is described in the [software manual][2]. 

## Starting and stopping the software

The software can be started manually using `ubxlogd`.

To automatically start tasks on OpenWrt we use the `cron` service, which is already enabled by the installation script.
To use the `cron` service the user has to provide a `crontab` file.

Copy one of he example crontab files in `./scripts` to `./scripts/crontab`, edit this file and start using it

> cd /mnt/sda1/ubxlogger/\
> vi scripts/crontab\
> crontab scripts/crontab

Instructions are provided in the example crontab files.

The crontab can be inspected with the `crontab -l` command or in the GUI `OpenWrt LuCI -> System -> Scheduled tasks`.
You can also edit the crontab directly with `crontab -e`.

Crontab on OpenWrt does not support the `@reboot` directive. This directive must be commented out in the `crontab`.
The `cronatreboot` service that is installed during the second part of the install will use the commented out
directive to start logging after a (re)boot.

Note that `crontab` works with local time. To have this synchronized with `UTC` set local time to `UTC` or account for the time difference in the crontab (which can be tricky with daylight saving time).

## Remote connections

So far we accessed the router using it's webinterfaces and ssh from the local network through WiFi or a LAN cable.

To access the router remotely through the 4G LTE interface some additional setup is needed (unless the router has a public ip, but then you definitely want to setup the firewall).

### GL-iNet GoodCloud

The easiest way to achieve remote connectivity over the 4G or WAN network is via GL-iNet's [GoodCloud](https://www.goodcloud.xyz/#/login) 
Cloud Management Software. *GoodCloud* uses something similar to reverse `ssh` to set up a long lasting connection. The connection is initiated by the 
router, so as long as the router can connect to the Internet your are okay. No hassle with firewalls, dynamic DNS, etc.

First, enable GoodLife in the admin Web interface on the router. Then, create an account on *GoodCloud*, and bind the device
using information that can be found on the back of the router. If all is well, the device will appear in the GoodCloud dashboard.
You can use remote GUI and remote ssh from the GoodCloud website to connect to the router.

GoodCloud is free software with unlimited number of devices. There is a paid enterprise edition with more functions, but this is not needed. 


### Dynamic DNS (DDNS)

Dynamics DNS (DDNS) is not needed with GoodCloud. The ip number can be retrieved from the GoodCloud interface. However, if you want, setup dynamic DNS as backup, so that you can use a webbrowser and ssh to access the
router remotely over the 4G network (except when CG-NAT is used by the telecom provider). If you do this, you must set an ip-range with appropriate Firewall rules and enable access from the WAN to ports 80 and 22 . 

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


[1]: <UbxLogger_Hardware_Manual.md> "H. van der Marel (2024), UbxLogger Hardware Manual, TU Delft, September 2024."
[2]: <UbxLogger_Software_Manual.md> "H. van der Marel (2024), UbxLogger Software Manual, TU Delft, September 2024."

## Appendices

## Appendix I: Installation scripts

The UbxLogger installation consists of two parts

### ubxlogger_install_part1.sh

This script will download the `UbxLogger` software and install it on the micro SD card. The typical workflow is
to download the script from Github and then run it

> curl -L https://github.com/hvandermarel/ubxlogger/raw/refs/heads/main/sys/ubxlogger_install_part1.sh -o install.sh \
> ./install.sh

The script does the following

1. Change directory to the sd card root with `cd /mnt/sda1/`
2. Download the `UbxLogger` software form `github` and unpack

   >  curl -L https://github.com/hvandermarel/ubxlogger/archive/main.tar.gz -o ubxlogger.tar.gz \
   >  tar -xzf ubxlogger.tar.gz \
   >  mv ubxlogger-main ubxlogger

   or

   >  curl -L https://github.com/hvandermarel/ubxlogger/archive/refs/tags/v1.0-alpha.tar.gz -o ubxlogger.tar.gz \
   >  tar -xzf ubxlogger.tar.gz \
   >  mv ubxlogger-1.0-alpha ubxlogger

   This will create the basic directory structure, with scripts and example configuration files.

3. Change directory to the `ubxlogger` with `cd ubxlogger`

4. Download the precompiled executable files from `github` and unpack

   >  curl -L https://github.com/hvandermarel/ubxlogger/releases/download/v1.0-alpha/openwrt-mips-bin.tar.gz -o ./openwrt-mips.tar.gz \
   >  tar -xzf openwrt-mips.tar.gz

   This will install the executables in the `ubxlogger/bin` directory. `openwrt-mips` is the architecture used by the `GL-iNet X750`.  For other systems and OS change the download accordingly. Currently available executables are `openwrt-mips` and `raspberry-pi`. 

This part of the installation process is the same for any computer architecture.

### ubxlogger_install_part2.sh

For the second part of the installation process a separate script is provided that is installed along with the rest of the software.
This part is different for the various computer architectures and can be found in `ubxlogger/sys/*architecture*/scripts`.

On OpenWrt a couple of tasks are performed that are described below.

#### str2str plug-in

There are plug-ins for RTLKIB's `str2str` and `convbin`. The `str2str` plug-in is working
quite well.  However, though the `convbin` plug-in installs and does not crash, it 
fails to convert ZED-F9P raw data files to RINEX. The reason for this is that `ublox.c`, which deals with decoding raw U-blox data, and is used by `convbin` and other RTKLIB applications, does not work on big endian systems out of the box.  

To install - after updating the package list - the `str2str` plug-in 

> opkg update\
> opkg install str2str

The plugin needs to be reinstalled after a firmware update.

If you want also to convert raw data file into RINEX then you need cross compiled versions of 
RTKLIB's `convbin`, using modified source code for `ublox.c`, and Hatanaka's `rnx2crx`. 
See the section on cross-compiling on how to achieve this. Compiled versions for the GL-iNet are 
available as downloads. 

There is also a cross compiled version of `str2str` that you can use instead of the OpenWrt package (we recommend using the OpenWrt package).

#### Cron service

By default OpenWrt does not enable the cron service. To start it and enable automatic startup during subsequent reboots, you need to execute the following commands once:

> /etc/init.d/cron start\
> /etc/init.d/cron enable

The first command starts the cron service once, but does not change the startup configuration, so it will not be started automatically after a reboot. 
The second command changes the startup configuration (creates a symlink in `/etc/rc.d`) so that the cron service will be started during boot, 
but does not start it immediately.

Next thing, is to edit the `crontab` file in `ubxlogger/scripts`, and inform `crontab` to use this file

> cd /mnt/sda1/ubxlogger/\
> vi scripts/crontab\
> crontab scripts/crontab

The crontab can be inspected with the `crontab -l` command or in the GUI `OpenWrt LuCI -> System -> Scheduled tasks`.

`crontab` works with local time. To have this synchronized with `UTC` make sure that you're local time is set to `UTC`.

#### Start on (re)boot

Crontab on OpenWrt does not support the `@reboot` directive. This means that, after a (re)boot, the ubx logging is only started at the regular `ubxlogd check 'identifier'` intervals, typically every 57 minutes after the hour. Worst case scenario is that it takes one hour to start after a reboot.

To enable start on (re)boot do the following

1. In the crontab comment out the reboot directive with a single "#" and no spaces
2. Add startup script to /etc/init.d to process the commented out "#@reboot" directive

   > cp sys/open-wrt/scripts/cronatreboot to /etc/init.d/ \
   > /etc/init.d/crontatreboot enable

This needs to be do only once (as part of the installation procedure). After a firmware update the 
2nd step must be done again.

#### Create symbolic links

This script will install symbolic links to the executables and scripts in `/usr/bin` and to `ubxlogger` in the root home directory.


## Appendix II: Cross compiling OpenWrt programs

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


## Appendix III: Differences with other models (and brands)

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
