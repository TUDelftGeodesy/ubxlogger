#!/bin/sh

# Get path to the ubxlogger directory
scriptdir=$(dirname "$(readlink -f "$0")")
ubxdir=$(readlink -f $scriptdir/../../..)

# Create a symbolic link in the /root directory
if [ ! -h /root/ubxlogger ]; then
   echo Create symbolic link in /root to $ubxdir
   ln -s ${ubxdir}/ /root/ubxlogger
fi

# Enable cron and install cronatroot in /etc/init.d
#echo Enable cron and install cronatroot in /etc/init.d
#cp ${scriptdir}/cronatreboot /etc/init.d/
#echo Create symbolic links to $ubxdir
#/etc/init.d/cron enable
#/etc/init.d/cronatreboot enable

# Install str2str package
#echo Install str2str package
#opkg update
#opkg install str2str

# Create symbolic links in /usr/bin to the executables (comment
# out when installed as package)
#if [ ! -e /usr/bin/str2str ]; then
#   echo Str2str not installed as package, create a symobilic link to executable in ${ubxdir}/bin
#   ln -s ${ubxdir}/bin/str2str /usr/bin/str2str
#fi
if [ ! -h /usr/bin/convbin ]; then
   echo Create symbolic links in /usr/bin to executables in ${ubxdir}/bin
   ln -s ${ubxdir}/bin/convbin /usr/bin/convbin
   ln -s ${ubxdir}/bin/rnx2crx /usr/bin/rnx2crx
   ln -s ${ubxdir}/bin/crx2rnx /usr/bin/crx2rnx
fi

# Create symbolic links in /usr/bin to some of the scripts
# for which it make sense to run from the command line on
# occasion
if [ ! -h /usr/bin/ubxlogd ]; then
   echo Create symbolic links in /usr/bin to frequently used scripts in ${ubxdir}/scripts
   ln -s ${ubxdir}/scripts/ubxlogd.sh /usr/bin/ubxlogd
   ln -s ${ubxdir}/scripts/ubxconfig.sh /usr/bin/ubxconfig
   ln -s ${ubxdir}/scripts/ubx2hourlyrnx.sh /usr/bin/ubx2hourlyrnx
   ln -s ${ubxdir}/scripts/ubx2dailyrnx.sh /usr/bin/ubx2dailyrnx
fi
