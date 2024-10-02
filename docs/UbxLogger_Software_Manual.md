# UbxLogger Software Manual

**Hans van der Marel, TU Delft, September, 2024.**


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

You have have the choice to create compressed RINEX files on OpenWrt or SBC and push the RINEX to
the remote server, and/or push ubx rawdata files to the remote server and convert to RINEX on
the remote server. To transfer the compressed RINEX files, especially at a lower sample rate, requires 
only a fraction of the bandwith compared to ubx. A single receiver can produce up to 4 GB/Month of
compressed raw ubx data if only raw measurements are stored (UBX-RXM-RAWX records). If also navigation 
data is stored (UBX-RXM-RAWX + UBX-RXM-SFRBX records) the number increases to 6 GB/Month. The RINEX data,
at 10 sec sample rate, only takes less than 200 MB/month.  

## UbxLogger scripts

`UbxLogger` is written entirely as shell scripts. No `Python`, `Perl`, or other tools are 
required. This is to reduce memory usage so that it will run on `OpenWrt` routers 
with limited flash, ROM and RAM memory, while simultaneously be able to run it on more powerfull 
single board computers (SBC) like the Raspberry Pi. 

The scripts have been written with `BusyBox` in mind. 
**BusyBox** is a software suite that provides several Unix utilities in a single executable file. It runs in a variety 
of POSIX environments such as Linux, Android,and FreeBSD, compatible to the`ash` shell. 
It was specifically created for embedded operating systems with very limited resources and is used
also `OpenWrt`. 
The scripts also run on the more powerful `bash` shell used by for instance
the Raspberry Pi and many other Linuxes.

In the background `str2str` from `RTKLIB` is used to capture data from the receiver. This can
be imported as extension package in `OpenWrt`. If not available for your system, it can 
be cross-compiled on a Linux desktop using the `OpenWrt` developer suite and `RTKLIB` source
code. On the Raspberry Pi you can natively compile `str2str` with `gcc` from the `RTKLIB` source
code.

For the optional conversion to RINEX the `convbin` console app from `RTKLIB` and `rnx2crx` from Yuki Hatanaka
are needed. These can be compiled natively on the Raspberry Pi, or cross-compiled using the 
`OpenWrt` developer package. It is also possible to convert the data to RINEX on an upstream
server, desktop or laptop using the same tools.

### Main scripts

#### ubxlogd.sh

Start, stop, check, restart and status of the ubxlogd (str2str) deamon. The syntax is:

>    ./ubxlogd.sh [start|stop|check|restart|status] 'identifier'\
>    ./ubxlogd.sh status\
>    ./ubxlogd -h

This can be used from the command line and/or crontab to `start` or `stop` the logging, to
`restart` logging (stop followed by start) or `check` if the deamon is logging and if 
necessary start the deamon again to resume logging. All these commands, except check, 
provide output to the console and a log file called `'identifier'.log` in the `log/` directory.
`check` only enters an entry in the log file when a restart was necessary.

The command `./ubxlogd.sh status 'identifier'` only writes to the console. It does not put
anything in the log file. It is intended to be used from the command line to inspect the
status of the deamon. It can be used with and without optional `'identifier'`.

The `'identifier'` is the name of the stream. It typically consists of a four letter sitename, 
followed by 'xx', and then a three letter instrument code. Two examples are *ZEGVxxTS1* and
*ZEGVxxDF1*, for a site in Zegveld, one instrument on the top soil (*TS1*) and the other
deeply founded (*DF1*). The number is used when there are more instrument locations on the
same site. See also the sections on naming conventions.

The raw ubx data is written to hourly files in the `run/` directory following the RINEX3 naming 
convention, with `ubx` as file extension (instead of `rnx`) and `'identifier'` as station
name. The starttime in the file name is usually the round hour, except after a start or
restart of the deamon (the starttime then reflects the actual startime).

#### ubxpush.sh

Push compressed hourly ubx files to the data archive and upload to an upstream server.
The syntax is:

>    ./ubxpush.sh 'identifier'\
>    ./ubxpush.sh -h

This command looks in the `run/` directory for any files starting with `'identifier'` 
that are not actively written to (e.g. from the previous hours and days), then uses
`gzip` to compress the data, optionally upload it to an upstream server, and 
on success move the files to the archive directory `data/` where the data is
stored in daily subdirectories `data/YYYY/DDD/` with 'YYYY' the year and 'DDD' the
day of the year. 

If the ubxfile upload does not succeed, the compressed files remain in the `run/` 
directory, and the script will attempt to upload them the next time it is invoked.

If RINEX file conversion is selected in the configuration file, then the uncompressed ubx
files are also copied into the `spool/` directory to be converted to RINEX later using the
`rnxpush.sh` script.

#### rnxpush.sh

Create compressed daily RINEX version 3 files hourly and upload to an upstream server.
The syntax is:

>    ./rnxpush.sh 'identifier'\
>    ./ubxpush.sh -h

This command looks in the `spool/` directory for all ubx files, starting with `'identifier'`, from previous days, converts the hourly ubx files from the same day to a single daily
RINEX version 3 observation file (and navigation file when broadcast message data is
stored in the ubx), compress using Hatanaka compression and gzip, and then upload 
it to an upstream server. On success, the RINEX files are moved to the archive 
directory `data/` where the data is stored in daily subdirectories `data/YYYY/DDD/` 
with 'YYYY' the year and 'DDD' the day of the year. 

If the RINEX file upload does not succeed, the RINEX files remain in the `spool/` 
directory, and the script will attempt to upload them the next time it is invoked.

#### ubxpurge.sh

Purge archived ubx data files whenever the current disk usage exceeds a selectable
percentage and if necessary rotate the log files. The syntax is

>    ./ubxpurge.sh\
>    ./ubxpurge.sh -h

The script does two things. 

First, if the current diks usage exceeds a 
selectable percentate `max_disk_usage=95`, data in the `data/` 
directory is purged by deleting some of the oldest data. The amount 
of data that is deleted depends several parameters. The number of 
days that are deleted deleted is between `min_days_to_delete=3` and
`max_days_to_delete=7`, but always making sure to keep at least
`min_days_to_keep=30` of the most recent data. Also, the scripts
stops deleting data, within the above parameters, as soon as the
disk usage drops below `max_disk_usage=95`.

Secondly, if the size on any log file exceeds `max_logfile_size=512k`,
the file is renamed inserting the current date and then compressed,
while a new log file is started.

The values given in the parameters are hardwired at the beginning of 
the script. They can be changed using an editor. 

#### ubxconfig.sh

Show the values of the configuration file, tty device and port numbers.
The syntax is 

>    ./ubxconfig.sh ['identifier'] 

The script shows the directory locations and remote upload server(s) that have
been set in the configuration file.

The device name (ttyACM0, ttyACM1, ..) is assigned more or less randomly by the OS
to each receiver. When the optional `'identifier'` parameter is given, 
this script - like `ubxlogd` does - resolves the randomly assigned device name 
for the receiver with `'identifier'` from the USB port number. 

The USB port number is set in the configuration file. Make sure
that - in case of multiple receivers - each receiver is connected to the port 
given in the configuration file. 

### Configuration file

All setting are done in the configuration file `ubxlogger.config` that can
be found in the same directory as the scripts. 

The configuration file consists of several parts

1. Program paths and os dependent commands
2. Directory paths
3. USB port number (device path) assigned to each receiver 
4. Remote upload base url and authorization for curl
5. Function to return tty device name (e.g. /dev/ttyACM0) for USB port number

Most things are already preset correctly for the default installation. The bits that
most certainly need tweaking are the USB port number assignment and the 
parameters for the remote upload server. 

The USB port number assignment is covered in a separate section.

The remote upload locations are given in the `$remoteubx` and `$remoternx` variables
for respectively ubx and RINEX files. These variables can contain other variables, like `\$year`
and `\$doy`, to specify a dynamic path. If `$remoteubx=` is empty, no ubx data will 
pushed to a remote server, but will be archived in the archive directory `data/`. 
If `$remoternx=` is empty, no RINEX conversion will be done, and no RINEX data will
be pushed to a remote server. 


### RINEX conversion scripts (local and server side)

#### ubx2hourlyrnx.sh

Create hourly RINEX3 file(s) from ubx file(s). The syntax is

>    ubx2hourlyrnx [-c 'identifier'.cfg] [-z] ubxfile(s)\
>    ubx2hourlyrnx -h

For the script to work the file(s) with ubx data must adhere to the RINEX3 
standard `[path/]site9char_?_yeardoyhhmm_##D_##S_MO.ubx[.gz].`

Hourly RINEX3 file(s) are created in the current directory for each of the
input file(s). With the option `-z` the output files will be Hatanaka and
gzip compressed. Any files in the current directory will be overwritten.

If more than one input file is given (wildcards are allowed) then the script
calls itself recursively to complete the task. For every input file, one 
output rinex file is created. The output filename is not changed, except for
the extension `ubx`, which will be changes into `rnx` or `crx`.

The script trims each output RINEX file to start exactly at `xx:00:00` (if possible) and stop
at `xx:59:59` (if possible), ignoring ubx data before and after the hour. This is
done because ubx files created by `str2str` use a 30 second overlap to accommodate for
errors in system time. 

The marker name and number in the RINEX files are the same as the station
name in the filename. The receiver and antenna type, serial numbers, receiver
version, operator and agency name can be set in a configuration file 
with the `-c 'identifier'.cfg` option. The configuration file contains 
command line options which will be passed to `convbin`.  


#### ux2dailyrnx.sh

Create a single daily RINEX3 file from multiple ubx files. The syntax is:

>    ubx2dailyrnx [-c 'identifier'.cfg] [-i <interval>] [-z] ubxfiles\
>    ubx2dailyrnx -h

For the script to work the file(s) with ubx data must adhere to the RINEX3 
standard `[path/]site9char_?_yeardoyhhmm_##D_##S_MO.ubx[.gz].`

The input ubx files must all be for the same station, the same day and
have the same compression state. If these conditions are not met, the 
script will raise an error and stop.

Daily RINEX3 files are created in the current directory. The default interval 
is 10 sec, this can be changed with the `-i` option. If the option `-z` is
given the output files will be Hatanaka and gzip compressed. Any files in the 
current directory will be overwritten.

The script trims each output RINEX file to start exactly at `00:00:00` (if possible) and stop
before or at `23:59:59` (if possible), ignoring ubx data before and after the day. Also,
overlapping data between hours, is removed. This is done because hourly ubx files created by 
`str2str` use a 30 second overlap to accommodate for errors in system time. 

The marker name and number in the RINEX files are the same as the station
name in the filename. The receiver and antenna type, serial numbers, receiver
version, operator and agency name can be set in a configuration file 
with the `-c 'identifier'.cfg` option. The configuration file contains 
command line options which will be passed to `convbin`.  


## Directory structure

The default directory stucture for `UbxLogger` is

>     ubxlogger
>        |- bin
>        +- data
>        |   |- year
>        |   |    |- doy
>        |   |    v
>        |   v
>        |- log
>        |- run
>        |- scripts
>        +- spool
>        |   |- yeardoy
>        |   v
>        +- sys
>            |- openwrt-mips
>            +- raspberry-pi

The scripts and configuration file can be found in `scripts/`. 

The directories `bin/`, `log/`, `run/`, `spool/` and `data/` are initially empty.
The `run/` directory will hold only data files that are actively written to, or
are waiting to be pushed to the data archive `data/` and/or upstream remote
server. The directory `log/` will hold the log files, `data/` is where the
compressed data goes after a succesful upload and `spool/` is the directory
that will hold ubx data that will be converted to RINEX at the end of the day.
The `spool/` directory has subdirectories `yeardoy` that contain the year and day of year
number. These subdirectories are purged after a succesful conversion to RINEX.
The `data/` directory has two levels of subdirectories, one for the year, 
the second for the day number of the year. The data in `data/` is stored indefinitely 
until it is purged by the  `ubxpurge.sh` script. 

The `bin/` directory is only populated upon install with symbolic links to the 
scripts and the proper executables (if needed), copied from `sys/'os'/`.

The directory `sys/` contains all the system related stuff, organized in
subdirectories for the different computer architectures and platforms. 

The default directory structure can be changed in the configuration file.

## File naming convention

All data files follow the RINEX3 file naming convention

>    XXXXMRCCC_R_YYYYDDDHHMM_FFU_DDU_MO.{ubx|rnx|crx}[.gz] \
>    XXXXMRCCC_R_YYYYDDDHHMM_FFU_MN.rnx[.gz] \
>
>    SITExxST#_YYYYDDDHHMM_FFU_DDU_MO.{ubx|rnx|crx}[.gz] 

All elements are fixed length and are separated by an underscore “_” except 
for the file type (`ubx`, `rnx` or `crx`) and optional compression field (`.gz`)
that use a period “.” as a separator. The individual elements are:

Station/project name `XXXXMRCCC` or `SITExxST#` 
:   This is a 9 character station or project name. The IGS convention is to use 4 characters 
    `XXXX`for the site/station, two digits `MR` to indicate the monument respectively receiver number,
    and the ISO country code `CCC`, but this is not mandatory for other projects. 
    For subsidence monitoring and geodetic extensometer applications the following naming 
    convention for the 9 character station name is proposed,`SITExxST#`, see also the next
    section.
    This element is also used as `UbxLogger` stream/receiver identifier `'identifier'`. 

Data source `R` 
:   This is `R` if the data is collected at the receiver, as is the case in ours. Can also
    be `S` when the data is captured from a stream.

Start time `YYYYDDDHHMM` 
:   The start time is the file start time. This should coincide with the first
    observation in the file. The start time consists of the 4 decimal year `YYYY`, day of
    year number `DDD`, hour `HH` and minute `MM`.

File period `FFU` 
:   Is used to specify the data collection period of the file, with `FF` two decimals 
    and `U` the unit ([S|M|H|D] for resp. second, minute, hour and day). Typical values
    are `01H` for hourly files and `01D` for daily files. 

Data interval/frequency `DDU` 
:   Used for files with observation data to specify the data interval, with `DD` two 
    decimals and `U` the unit (see also above). Typical values are `01S`, `10S` and `30S`
    for respectively 1, 10 and 30 second intervals.

Data type and format `{MO|MN}.{ubx|rnx|crx}[.gz]` 
:   Data type is either `MO` mixed observation or `MN` mixed navigation. The format is
    either raw U-blox data `ubx`, RINEX `rnx`, or Hatanaka compressed RINEX observation
    files `crx`. The optionally `.gz` indicates that the files are compressed using gzip.
    Note that for `ubx` data files the type is always `MO` for observation data, also when
    it contains navigation data besides observation data.

It is standard to archive the files in a layered directory structure `./YYYY/DDD/` with `YYYY`
the year and `DDD` the day number of the year.

## Station naming convention

For subsidence monitoring and geodetic extensometer applications the following naming convention
for the 9 character station name, used for the first element in the file name (see above) and used 
as identifier in `UbxLogger`, is proposed:

>    SITExxST#

with `SITE` the 4-character site name (e.g. 'ZEGV', 'ROVN', ...), `xx` a fixed separator, and 
`ST#` the instrument identifier at the site. Note that we cannot use `_` or `-` as separators or in the names,
as `_` is reserved for separating fields in the RINEX name, nor can we use `-` as this is very
awkward for shell scripting. The `xx` sets it also apart from the IGS naming convention.

The instrument identifier `ST#` can basically be anything as long as it is 3 characters, so that the
total length of the station name does not exceed 9 characters. A sensible
naming scheme could be the following: two characters `ST` (for stratum) identifying the 
foundation depth followed by a number `#` to indicate the location at a site (to cover situations when
there are multiple instrument locations at a site). The stratum `ST` can either be *TS* an instrument
embeded in the top soil, *DF* for a deeply founded instrument, or *SA*, *SB*, *SC*, etc., to
indicate a specific stratum in the soil layers.  


## USB port number assignment

The device name (ttyACM0, ttyACM1, ..), which is needed by `ubxlogd`, is assigned more or 
less randomly for each receiver. This is becomes a problem in case two or more U-blox 
receivers are used, which is the device used for each receiver? We have to find out.

A particular problem for the U-blox receivers is that the 'idVendor' and 'idProduct' for
all ZED-F9P is the same (idVendor=0x1546, idProduct=0x01a9), and that there is no 
serial id that otherwise can be used to distinquish between receivers.

**The only option we have, is to always use the same USB port for a receiver, and distinquish
between receivers using the USB device path.**

The device path must then be specified in the configuration file for each receiver.
An example for setting the device paths in the configuratuin file is given below: 

>    devpath_ZEGVxxTS1=1.3.2 \
>    devpath_ZEGVxxDF1=1.3.4

The identifier (e.g. `ZEGVxxTS1`) must preceeded by `devpath_`, the value is the USB 
device part (think of this a kind of port number) with variable name `${devpath}`.

These settings are used by a function 'get_dev', also defined in the configuration file, 
which uses the instrument identifier `${identifier}` variable (e.g. "ZEGVxxTS1") to 
find the corresponding device path, set `${devpath}` (e.g. "1.3.2"), and then resolve 
the device name (e.g. ttyACM0) and return this in the variable `${dev}`. 

The logic is to look for the USB device path `${devpath}` in the system directory
`/sys/bus/usb/devices/1-${devpath}:1.0/tty)`, which points to the tty device `${dev}` (e.g. ttyACM0)
that is used for the USB serial device.

The value of `${devpath}` must be set in `devpath_${instrument}=${devpath}`, e.g.
`devpath_ZEGVxxTS1=1.3.2`. The actual value, in our case '1.3.2', depends on the USB port 
that we are using. In this case it is the second port on a USB hub which itself has 
device path '1.3'. The actual numbers are different for each system.

There are several ways to find out the device number used by a USB port.

1. Use the command `lssub -t` and make note of the sequence of port numbers, or,
2. Use the command `dmesg` and look for newly added usb devices. Make note of the 
   string `usb 1-#.#[.#[.#]]:`. The `#.#[.#[.#]]` part is the device path.

Execute these commands before and after connecting each device, seeing the changes
helps to identify the device.


## Typical data storage and transmission volume

### gzip compressed ubx data 

Under normal (full-sky) tracking conditions the typical amount ubx data that is
collected, after compression with gzip, is

|       | RAWX    | RAWX+SFRBX |
| ----- | ------- | ---------- |
| Hour  | 4.2 MB  | 5.7 MB     |
| Day   | 100 MB  | 138 MB     |
| Month | 3.0 GB  | 4.1 GB     |
| Year  | 36 GB   | 49 GB      |

This is the amount of data that needs to be transmitted and stored.

Storing only UBX-RXM-RAWX data for a single receiver will fill up a 128 GB micro SD 
card in about 3 years, and requires a 4-5 GB data subscription with your telecom
provider. 

As the navigation data (broadcast data messages send by the satellites) is the same 
for all stations it does not make sense to store this for every station. It is also 
possible to retrieve this data from the Internet. The only downside of not storing 
navigation data is that upon conversion to RINEX the approximate coordinates of the
station cannot be computed by `convbin`, thus the approximate position must be
set in the configuration file or else the approximate position in the RINEX file
will consist of zeros.

It is not recommended to reduce the data volume by reducing the data rate (currently 1 Hz) 
at the receiver. If the data rate is lowered at the receiver, e.g. to 10 seconds, the 
data is samples every 10 seconds using an arbitray start time. There is no guarantee that
this then includes the whole minute, and when processing data from multiple receivers, there 
is no guarantee anymore that each samples the data at the same time. 


### Hatanaka and gzipped RINEX version 3 files

Hatanaka compressed and gzipped RINEX version3 files tend to be smaller than 
u-blox raw data files. When the sample rate is further reduced to e.g. 10 seconds, the
file sizes are only a fraction of the raw ubx data.

|       | intv   | crx.gz  |
| ----- | ------ | ------- |
| Hour  | 1 sec  |  2 MB   |
| Day   | 10 sec | 4.5 MB  |
| Month | 10 sec | 140 MB  |
| Year  | 10 sec | 1.6 GB  |

Compressed navigation files are typically 300 KB per day.

Storing and transmitting compressed RINEX 3 data at 10 second sample rate takes only 1/20 - 1/30 
of the data volume of raw ubx data.

### RINEX file generation on OpenWrt

Router in general are not designed for heavy computational processing. It is therefore no 
surprise that the conversion of ubx to RINEX on OpenWrt router is not very fast. 
Some timing results, on a GL-iNet X750 OpenWrt router, for creating and transfering
daily 10 sec RINEX file are

|          | RAWX   | RAWX+SFRBX |
| -------- | ------ | ---------- |
| convbin  | 3 min  | 9 min      |
| rnx2crx  | 25 sec | 25 sec     |
| gzip     | 64 sec | 69 sec     |
| transfer |  8 sec | 9 sec      |

The data transfer (for which the router is build) is the fastest. The conversion itself takes 
3 minutes and also gzip is not very fast. If also `SFRBX` data (navigation message data) is
stored the conversion time is tripled. This is another reason not to store navigation data,
which is the same for every receiver, and obtain this data from another source. 


## Further reading

[1]. H. van der Marel (2024), UbxLogger Hardware Manual, TU Delft, September 2024.\
[2]. H. van der Marel (2024), UbxLogger GL-iNet Installation Guide, TU Delft, September 2024.


[1]: <UbxLogger_Hardware_Manual.md> "H. van der Marel (2024), UbxLogger Hardware Manual, TU Delft, September 2024."
[2]: <UbxLogger_GL-iNet_Installation_Guide.md> "H. van der Marel (2024), UbxLogger Gl-iNet Installation Guide, TU Delft, September 2024."

