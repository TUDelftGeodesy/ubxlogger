#!/bin/sh
echo "Download and install UbxLogger software - part 1"
echo "------------------------------------------------"
echo
echo "This script will download and install UbxLogger on a local drive or "
echo "MicroSD/TF card."
echo ""
echo "On OpenWrt routers you will need an activated SIM card and 'ext4' "
echo "formatted MicroSD/TF card. If you have a MicroSD/TF card with a file"
echo "system other than 'ext4', we recommend to reformat the card on another" 
echo "linux system, with:"
echo ""
echo "   sudo mkfs.ext4 /dev/sda1"
echo ""
echo "The default mount point for the MicroSD/TF card is '/mnt/sda1', but this"
echo "can be changed."
echo ""

# set defaults

sdcard="/mnt/sda1"
release="v1.0-alpha"
gittag="main"

# ask user for input and confirmation

read -p "Local folder or microSD/TF card mount point [${sdcard}]: " tmpinput
sdcard=${tmpinput:-$sdcard}
read -p "Software version [${release}]: " tmpinput
release=${tmpinput:-$release}
read -p "Git branch/tag [${gittag}]: " tmpinput
gittag=${tmpinput:-$gittag}

echo ""
echo "Your inputs:"
echo "  Local folder or microSD/TF card mount point:  ${sdcard}"
echo "  Software version:  ${release}"
echo "  Git branch/tag:   ${gittag}"
echo ""
while true; do
    read -p "Continue with the download and install [yN]? " tmpinput
    case $tmpinput in
        [Yy]* ) break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo ""
echo "Downloading 'UbxLogger' software form 'github'..."

echo cd ${sdcard}
if [ "${gittag}" = "main" ]; then
   curl -L https://github.com/hvandermarel/ubxlogger/archive/main.tar.gz -o ubxlogger-main.tar.gz 
else
   curl -L https://github.com/hvandermarel/ubxlogger/archive/refs/tags/${release}.tar.gz -o ubxlogger-${release}.tar.gz 
fi
echo ""
echo "Installing 'UbxLogger' ..."
tar -xzf ubxlogger-${gittag}.tar.gz 

ubxdir="ubxlogger-${gittag}"

echo ""
echo "The software is installed in ${ubxdir}, if you want, you can rename"
echo "the installation directory to 'ubxlogger' now."
echo ""

while true; do
    read -p "Move ${ubxdir} to ubxlogger [yN]? " tmpinput
    case $tmpinput in
        [Yy]* ) mv -i $ubxdir ubxlogger; ubxdir="ubxlogger"; break;;
        [Nn]* ) break;;
        * ) echo "Please answer yes or no.";;
    esac
done

echo "Download the precompiled executable files from 'github' and unpack to 'bin/' folder"

cd ${ubxdir}
curl -L https://github.com/hvandermarel/ubxlogger/releases/download/${release}/openwrt-mips-bin.tar.gz -o ./openwrt-mips.tar.gz
tar -xzf openwrt-mips.tar.gz

echo ""
echo "The software is now installed with the default directory structure in ${ubxdir}."
echo ""
echo "To create symbolic links, install packages and enable services use the commands"
echo ""
echo "    cd ${ubxdir}"
echo "    ./sys/openwrt-mips/scripts/ubxlogger_install_part2.sh"
echo ""
echo "For other platforms replace 'openwrt-mips' with one of the architectures provided"
echo  "in the '${ubxdir}/sys' folder."
echo ""
echo "    Good to know: On OpenWrt this step must be repeated each time after a firmware "
echo "    upgrade as this will install a clean system (the ubxlogger software, which is on"
echo "    the microSD card, will not be erased by a firmware update)."
echo ""
echo "Finally, prepare the configuration files and start the crontab."
echo " "
echo "- Edit the UbxLogger configuration file './scripts/ubxlogger.config'"
echo "- Edit the rinex configuration file(s) './spool/NAME00CCC.cfg' (NAME00CC"
echo "  must match the name of the identifier in ubxlogger.config"
echo "- Create a 'crontab' file using one of the examples in ./scripts "
echo "  as template and start the crontab."

exit
