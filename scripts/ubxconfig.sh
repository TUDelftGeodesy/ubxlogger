#!/bin/sh
#
# show ubxlogger configuration
# ----------------------------
#
# Usage:
#    ./ubxconfig.sh [identifier]
#
# (c) 2024 Hans van der Marel, TUD.


# Source the configuration file, requires $ubxscriptdir

ubxscriptdir=$(dirname "$(readlink -f "$0")")
. ${ubxscriptdir}/ubxlogger.config

# Echo

echo "Directory locations:"
echo "  ubxlogger home        $ubxdir"
echo "  scripts and config    $ubxscriptdir"
echo "  str2str output        $rundir"
echo "  log files             $logdir"
echo "  spool queue           $spooldir"
echo "  data archive          $archivedir"
echo ""
echo "Ubx upload server:      $remoteubx"
echo "Rinex upload server:    $remoternx"
echo ""

# Get device name

if [ "$1" != "" ]; then
   identifier=$1
   get_dev
   if [ $? -eq 0 ]; then
      echo "Receiver ${identifier} on USB port ${devpath} is assigned to ${dev}"
   fi
fi
