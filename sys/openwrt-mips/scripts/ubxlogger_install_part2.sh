#!/bin/sh
echo "Install UbxLogger for OpenWrt - part 2"
echo "--------------------------------------"
echo ""
echo "Create symbolic links, install optional packages and enable system services "
echo "for the UbxLogger software "
echo ""
echo "On OpenWrt this step must be repeated after a firmware upgrade as this will "
echo "install a clean system. The ubxlogger software, which is on the microSD card,"
echo "will not be erased by a firmware update and does not need to be re-installed."
echo ""

# Get path to the ubxlogger directory
scriptdir=$(dirname "$(readlink -f "$0")")
ubxdir=$(readlink -f $scriptdir/../../..)

# Create a symbolic link in the /root directory
if [ ! -h /root/ubxlogger ]; then
    while true; do
        read -p "Create a symbolic link in /root to ubxlogger [yN]? " tmpinput
        case $tmpinput in
            [Yy]* )
               echo Creating symbolic link in /root to $ubxdir
               ln -s ${ubxdir}/ /root/ubxlogger
               break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# Optionally install str2str as package

if [ ! -e /usr/bin/str2str ]; then
    while true; do
        read -p "Install OpenWrt str2str package [yN]? " tmpinput
        case $tmpinput in
            [Yy]* )
               echo "Updating OpenWrt package list and installing str2str package"
               opkg update
               opkg install str2str
               break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# Create symbolic links in /usr/bin to the str2str if not installed as package

if [ ! -e /usr/bin/str2str ]; then
    while true; do
        read -p "Str2str not installed as package, create a symbolic link to UbsLogger executable [yN]? " tmpinput
        case $tmpinput in
            [Yy]* )
               echo Creating symbolic link in /usr/bin to str2str executable in ${ubxdir}/bin
               ln -s ${ubxdir}/bin/str2str /usr/bin/str2str
               break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# Create symbolic links to other executables

if [ ! -h /usr/bin/convbin ]; then
    while true; do
        read -p "Create symbolic links in /usr/bin to other UbxLogger executables [yN]? " tmpinput
        case $tmpinput in
            [Yy]* )
               echo Creating symbolic links in /usr/bin to other executables in ${ubxdir}/bin
               ln -s ${ubxdir}/bin/convbin /usr/bin/convbin
               ln -s ${ubxdir}/bin/rnx2crx /usr/bin/rnx2crx
               ln -s ${ubxdir}/bin/crx2rnx /usr/bin/crx2rnx
               break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# Create symbolic links in /usr/bin to some of the scripts
# for which it make sense to run from the command line on
# occasion
if [ ! -h /usr/bin/ubxlogd ]; then
    while true; do
        read -p "Create symbolic links in /usr/bin to UbxLogger scripts [yN]? " tmpinput
        case $tmpinput in
            [Yy]* )
               echo Creating symbolic links in /usr/bin to frequently used scripts in ${ubxdir}/scripts
               ln -s ${ubxdir}/scripts/ubxlogd.sh /usr/bin/ubxlogd
               ln -s ${ubxdir}/scripts/ubxconfig.sh /usr/bin/ubxconfig
               ln -s ${ubxdir}/scripts/ubx2hourlyrnx.sh /usr/bin/ubx2hourlyrnx
               ln -s ${ubxdir}/scripts/ubx2dailyrnx.sh /usr/bin/ubx2dailyrnx
               break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

# Enable cron and install cronatroot in /etc/init.d

if [ ! -e /etc/init.d/cronatreboot ]; then
    while true; do
        read -p "Enable cron and install cronatroot in /etc/init.d [yN]? " tmpinput
        case $tmpinput in
            [Yy]* )
               echo Enabling cron and installing cronatroot in /etc/init.d
               cp ${scriptdir}/cronatreboot /etc/init.d/
               /etc/init.d/cron enable
               /etc/init.d/cronatreboot enable
               break;;
            [Nn]* ) break;;
            * ) echo "Please answer yes or no.";;
        esac
    done
fi

exit
