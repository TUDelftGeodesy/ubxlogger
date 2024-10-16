#!/bin/sh

# Get path to the ubxlogger directory
scriptdir=$(dirname "$(readlink -f "$0")")
ubxdir=$(readlink -f $scriptdir/../../..)

# Create symbolic links in ${HOME}/bin to the executables
if [ ! -h ${HOME}/bin/convbin ]; then
   echo Create symbolic links in ${HOME}/bin to executables in ${ubxdir}/bin
   ln -s ${ubxdir}/bin/str2str ${HOME}/bin/str2str
   ln -s ${ubxdir}/bin/convbin ${HOME}/bin/convbin
   ln -s ${ubxdir}/bin/rnx2crx ${HOME}/bin/rnx2crx
   ln -s ${ubxdir}/bin/crx2rnx ${HOME}/bin/crx2rnx
fi

# Create symbolic links in ${HOME}/bin to some of the scripts
# for which it make sense to run from the command line on
# occasion
if [ ! -h ${HOME}bin/ubxlogd ]; then
   echo Create symbolic links in ${HOME}/bin to frequently used scripts in ${ubxdir}/scripts
   ln -s ${ubxdir}/scripts/ubxlogd.sh ${HOME}/bin/ubxlogd
   ln -s ${ubxdir}/scripts/ubxconfig.sh ${HOME}/bin/ubxconfig
   ln -s ${ubxdir}/scripts/ubx2hourlyrnx.sh ${HOME}/bin/ubx2hourlyrnx
   ln -s ${ubxdir}/scripts/ubx2dailyrnx.sh ${HOME}/bin/ubx2dailyrnx
fi
