#!/bin/sh
#
# ubxlogd   start, stop, restart and display status of ubxlog deamon
#
# ---------------
# BusyBox version
# ---------------
#
# (c) 2024 Hans van der Marel, TUD.

#-------------------------------------------------------------------------
# All user defined and OS related settings are in ubxlogger.config 

ubxscriptdir=$(dirname "$(readlink -f "$0")")
source ${ubxscriptdir}/ubxlogger.config

#-------------------------------------------------------------------------

# process file arguments

if [ $# -eq 0 ]; then
   action=help
else
   action=$1
fi
if [ $# -eq 2 ]; then
   identifier=$2
elif [ "$action" == "status" ] || [ "$action" == "help" ] ; then
   identifier=""
else
   echo "Required identifier parameter missing"
   exit 1
fi

# check $identifier using get_dev() function defined in ubxlogger.config
# and retrieve the tty device name in ${dev} 

if [ "${identifier}" != "" ]; then
   # this function sets $devpath and $dev for $identifier
   get_dev
   if [ "$devpath" == "" ]; then
      echo "Error: Unknown receiver identifier $identifier, quiting..."
      exit 3
   fi
   if [ "${dev}" == "" ]; then
      echo "Receiver $identifier is not connected, quiting..."
      exit 0
   fi
fi

logfile=${logdir}/${identifier}.log

# Functions

function get_pid {
    pid=$(${ps} | grep str2str | grep -v grep | grep ${dev} | xargs | cut -d ' ' -f1)
}

function start_deamon {
   get_pid
   if [ "$pid" != "" ] ; then
      echo "ubxlogd $identifier on ${dev} is already running with pid=$pid, nothing to do"
      echo `date -u +"%F %R"` ++ubxlogd $identifier on ${dev} is already running with pid=$pid, nothing to do >> $logfile
   else
      $str2str -in serial://${dev}:57600#ubx -out file://${rundir}/${identifier}_R_%Y%n%h%M_01H_01S_MO.ubx::S=1  > /dev/null 2>&1 &
      sleep 3
      get_pid
      if [ "$pid" != "" ] ; then
         echo "ubxlogd $identifier on ${dev} is succesfully started with pid=$pid"
         echo `date -u +"%F %R"` ++ubxlogd $identifier on ${dev} is succesfully started with pid=$pid >> $logfile
      else
         echo "Error: ubxlogd $identifier failed to start"
         echo `date -u +"%F %R"` **Error: ubxlogd $identifier on ${dev} failed to start >> $logfile
      fi
   fi
}

function stop_deamon {
   get_pid
   if [ "$pid" == "" ] ; then
      echo "ubxlogd $identifier on ${dev} is not running, no need to stop"
      echo `date -u +"%F %R"` ++ubxlogd $identifier on ${dev} is not running, no need to stop >> $logfile
   else
      kill -9 $pid
      oldpid=$pid
      get_pid $pid
      if [ "$pid" == "" ] ; then
         echo "ubxlogd $identifier on ${dev} with pid=$oldpid was succesfully stopped"
         echo `date -u +"%F %R"` ++ubxlogd $identifier on ${dev} with pid=$oldpid was succesfully stopped >> $logfile
      else
         echo "Error: failed to kill ubxlogd $identifier on ${dev} with pid=$oldpid"
         echo `date -u +"%F %R"` **Error: failed to kill ubxlogd $identifier on ${dev} with pid=$oldpid  >> $logfile
      fi 
   fi
}

function status_deamon {
   if [ "$identifier" != "" ]; then
      get_pid
      if [ "$pid" != "" ] ; then
         echo "ubxlogd $identifier on ${dev} (${devpath}) is running with pid=$pid"
         ${ps} | grep str2str | grep -v grep | grep ${dev}
      else
         echo "ubxlogd $identifier on ${dev} (${devpath}) is not running"
      fi
   else
      echo "Currenlty running instances (or none) of ubxlogd:"
      ${ps} | grep str2str | grep -v grep 
   fi
}


# Main

case "${action}" in
    start)
      echo `date -u +"%F %R"` ++Trying to start ubxlogd $identifier  >> $logfile 
      start_deamon
      ;;
    stop)
      echo `date -u +"%F %R"` ++Trying to stop ubxlogd $identifier  >> $logfile 
      stop_deamon
      ;;
    restart)
      echo `date -u +"%F %R"` ++Trying to restart ubxlogd $identifier  >> $logfile 
      stop_deamon
      start_deamon
      ;;
    check)
      get_pid
      if [ "$pid" == "" ] ; then
         echo "Warning: ubxlogd $identifier on ${dev} is not running, will try to restart deamon"
         echo `date -u +"%F %R"` **Warning: ubxlogd $identifier on ${dev} is not running, will try to restart deamon  >> $logfile 
         start_deamon
      fi
      ;;
    status)
      status_deamon
      ;;
    help)
      echo "Start, stop, check, restart and status of ubxlogd."
      echo "Syntax:"
      echo "   ubxlogd [start|stop|check|restart|status] identifier"
      echo "   ubxlogd status"
      exit 1
      ;;
    *)
      echo "Error: unknown action ${action}, quiting."
      exit 2
      ;;
  esac

exit 0
