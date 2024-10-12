#!/bin/sh
#
# ubxlogd   start, stop, restart and display status of ubxlog deamon
#
# (c) 2024 Hans van der Marel, TUD.

#
# (c) 2024 Hans van der Marel, TUD.

#-------------------------------------------------------------------------
# All user defined and OS related settings are in ubxlogger.config

ubxscriptdir=$(dirname "$(readlink -f "$0")")
. ${ubxscriptdir}/ubxlogger.config

#-------------------------------------------------------------------------

# process file arguments

if [ $# -eq 0 ]; then
   action=help
else
   action=$1
fi
if [ $# -eq 2 ]; then
   identifier=$2
elif [ "$action" = "status" ] || [ "$action" = "help" ] ; then
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
   if [ "$devpath" = "" ]; then
      echo "Error: Unknown receiver identifier $identifier, quiting..."
      exit 3
   fi
   if [ "${dev}" = "" ]; then
      echo "Receiver $identifier is not connected, quiting..."
      exit 0
   fi
fi

logfile=${logdir}/${identifier}.log

# Functions

get_pid() {
    pid=$(${ps} | grep str2str | grep -v grep | grep ${dev} | xargs | cut -d ' ' -f1)
}

kill_zombies() {
   ps | grep str2str | grep -v grep | grep -i "$identifier" | while read -r line; do
      pidinstance=$(echo $line | xargs | cut -d ' ' -f1)
      devinstance=$(echo $line | xargs | cut -d ' ' -f7)
      devinstance=$(echo $line | sed -e "s/.*serial:\/\/\(tty[a-zA-Z0-9]*\):.*/\\1/g")
      if [ ! -c /dev/$devinstance ]; then
         echo "Device /dev/$devinstance associated with pid=$pidinstance does not exist, kill this process"
         echo $(date -u +"%F %R") ++ubxlogd Going to kill zombie proces for ${instance} with pid=${pidinstance} on ${devinstance}  >> $logfile
         kill -9 $pidinstance
      else
         echo "Device /dev/$devinstance associated with pid=$pidinstance exits, ok"
      fi
   done
}

check_runfile() {
   currentfile=${identifier}_R_$(date -u +"%Y%j%H??")_01H_01S_MO.ubx

   echo  $( find ${rundir}/$identifier*.ubx -mmin -1 | wc -l ) files written to for $identifier
   if [ $( find ${rundir}/$currentfile -mmin -1 | wc -l ) -gt 0 ]; then
      echo Currentfile $currentfile has recently been written to, logging ok
   elif [ -e ${rundir}/$currentfile ]; then
      echo Currentfile $currentfile exist, but has not recently been written to, logging not active
   else
      echo Currentfile $currentifle does not exist, logging not active
   fi
}

start_deamon() {
   get_pid
   if [ "$pid" != "" ] ; then
      echo "ubxlogd $identifier on ${dev} is already running with pid=$pid, nothing to do"
      echo $(date -u +"%F %R") ++ubxlogd $identifier on ${dev} is already running with pid=$pid, nothing to do >> $logfile
   else
      $str2str -in serial://${dev}:57600#ubx -out file://${rundir}/${identifier}_R_%Y%n%h%M_01H_01S_MO.ubx::S=1  > /dev/null 2>&1 &
      sleep 3
      get_pid
      if [ "$pid" != "" ] ; then
         echo "ubxlogd $identifier on ${dev} is succesfully started with pid=$pid"
         echo $(date -u +"%F %R") ++ubxlogd $identifier on ${dev} is succesfully started with pid=$pid >> $logfile
      else
         echo "Error: ubxlogd $identifier failed to start"
         echo $(date -u +"%F %R") **Error: ubxlogd $identifier on ${dev} failed to start >> $logfile
      fi
   fi
}

stop_deamon() {
   get_pid
   if [ "$pid" = "" ] ; then
      echo "ubxlogd $identifier on ${dev} is not running, no need to stop"
      echo $(date -u +"%F %R") ++ubxlogd $identifier on ${dev} is not running, no need to stop >> $logfile
   else
      kill -9 $pid
      oldpid=$pid
      get_pid $pid
      if [ "$pid" = "" ] ; then
         echo "ubxlogd $identifier on ${dev} with pid=$oldpid was succesfully stopped"
         echo $(date -u +"%F %R") ++ubxlogd $identifier on ${dev} with pid=$oldpid was succesfully stopped >> $logfile
      else
         echo "Error: failed to kill ubxlogd $identifier on ${dev} with pid=$oldpid"
         echo $(date -u +"%F %R") **Error: failed to kill ubxlogd $identifier on ${dev} with pid=$oldpid  >> $logfile
      fi
   fi
}

status_deamon() {
   if [ "$identifier" != "" ]; then
      get_pid
      if [ "$pid" != "" ] ; then
         echo "ubxlogd $identifier on ${dev} (${devpath}) is running with pid=$pid"
         ${ps} | grep str2str | grep -v grep | grep ${dev}
      else
         echo "ubxlogd $identifier on ${dev} (${devpath}) is not running"
      fi
      check_runfile
   else
      echo "Currenlty running instances (or none) of ubxlogd:"
      ${ps} | grep str2str | grep -v grep
   fi
}


# Main

case "${action}" in
    start)
      echo $(date -u +"%F %R") ++Trying to start ubxlogd $identifier  >> $logfile
      start_deamon
      ;;
    stop)
      echo $(date -u +"%F %R") ++Trying to stop ubxlogd $identifier  >> $logfile
      stop_deamon
      ;;
    restart)
      echo $(date -u +"%F %R") ++Trying to restart ubxlogd $identifier  >> $logfile
      stop_deamon
      kill_zombies
      start_deamon
      ;;
    check)
      get_pid
      if [ "$pid" = "" ] ; then
         echo "Warning: ubxlogd $identifier on ${dev} is not running, will try to restart deamon"
         echo $(date -u +"%F %R") **Warning: ubxlogd $identifier on ${dev} is not running, will try to restart deamon  >> $logfile
         kill_zombies
         start_deamon
      fi
      ;;
    kill_zombies)
      kill_zombies
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
