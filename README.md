# UbxLogger

**Hans van der Marel, TU Delft, September, 2024.**

U-blox ZED-F9P GNSS logging scripts for OpenWrt and Single Board Computers.

## What is UbxLogger?

`UbxLogger` is a suite of shell scripts and executables for logging data from a U-blox 
ZED-F9P low cost GNSS receiver on OpenWrt routers and Single Board Computers such as the
Raspberry Pi. 

Some of the things you can do with `UbxLogger` are

- Log data from one or more U-blox ZED-F9P receivers to a micro SD card, USB stick and/or 
  disk partition
- Compress the data and save to an archive directory
- Optionally push the compressed data to a remote server over the Internet (requires LAN, WAN or 4-G connectivity)
- Optionally convert the data to RINEX version 3 files, at a selectable sample rate and interval,
  compress using Hatanaka compression and gzip, archive and/or push to a remote server.
- Start on (re)boot, monitoring and restart 

You have have the choice to create compressed RINEX files on OpenWrt (or SBC) and push the RINEX to
the remote server, and/or push ubx rawdata files to the remote server and convert to RINEX on
the remote server. To transfer the compressed RINEX files, especially at a lower sample rate, requires 
only a fraction of the bandwith compared to ubx. 

## How to use UbxLogger

`UbxLogger` is designed to run on power efficient OpenWrt routers and Single Board Computers and
is written entirely in shell script with a few pre-compiled c executables . It is known
to work with

- The GL-iNet X750V2 (Spitz) OpenWrt 4G router
- Raspberry Pi single board computer and Teltonika RUT240 4G router

The total power consumption on the GL-iNet Spitz is below 3W, making this an ideal platform 
for solar powered operation.

Instructions on using the software, hardware recommendations, and installation instructions are
given in the `docs/` folder.

Scripts, executables and modified source code are available as releases on this Github repository. 

## Further reading

[1]. H. van der Marel (2024), UbxLogger Software Manual, TU Delft, September 2024.\
[2]. H. van der Marel (2024), UbxLogger Hardware Manual, TU Delft, September 2024.\
[3]. H. van der Marel (2024), UbxLogger GL-iNet Installation Guide, TU Delft, September 2024.


[1]: <docs/UbxLogger_Software_manual.md> "H. van der Marel (2024), UbxLogger Software Manual, TU Delft, September 2024."
[2]: <docs/UbxLogger_Hardware_Manual.md> "H. van der Marel (2024), UbxLogger Hardware Manual, TU Delft, September 2024."
[3]: <docs/UbxLogger_GL-iNet_Installation_Guide.md> "H. van der Marel (2024), UbxLogger Gl-iNet Installation Guide, TU Delft, September 2024."

