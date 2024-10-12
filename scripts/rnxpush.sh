#!/bin/sh
#
# rnxpush   convert ubx to daily rinex files, push to archive and upload to upstream server
#
# (c) 2024 Hans van der Marel, TUD.

#-------------------------------------------------------------------------
# All user defined and OS related settings are in ubxlogger.config

ubxscriptdir=$(dirname "$(readlink -f "$0")")
. ${ubxscriptdir}/ubxlogger.config

#-------------------------------------------------------------------------

# process options and file arguments

while getopts ":h" options; do
  case "${options}" in
    h|?)
      echo "Convert hourly ubx to daily rinex files, push to archive and"
      echo "upload to upstream server."
      echo "Syntax:"
      echo "   rnxpush -h"
      echo "   rnxpush identifier"
      exit
      ;;
    *)
      echo "Error: unknown option ${option}, quiting."
      exit
      ;;
  esac
done
shift $((OPTIND-1))

# Check that the stream identifier is present

if [ $# -eq 0 ]; then
   echo "No stream identifier is given, quiting."
   exit
fi
identifier=$1
logfile=${logdir}/${identifier}.log

# Change work directory to spool dir

orgdir=$(pwd)
cd ${spooldir}

# Folders in spooldir that are currently not in use

currentdir=$(date -u +%Y%j)
spoolfolders=$(find ./??????? -type d ! -name $currentdir)

# Process the files in each spool folder

for d in ${spoolfolders}; do
    yeardoy=$(basename $d)
    #year=${yeardoy:0:4}
    #doy=${yeardoy:4:3}
    year=${yeardoy%%???}
    doy=${yeardoy#????}
    rnxfile=${identifier}_R_${yeardoy}0000_01D_10S_MO.crx.gz
    count=$(find ${d}/ -name "${identifier}_R_${yeardoy}????_01H_01S_MO.ubx" | wc -l)
    if [ $count -eq 0 ]; then
       continue
    fi
    echo "ubx2dailyrnx -c ${identifier}.cfg -z ${d}/${identifier}_R_${yeardoy}????_01H_01S_MO.ubx"
    nice -n 19 ${ubxscriptdir}/ubx2dailyrnx.sh -c ${identifier}.cfg -z ${d}/${identifier}_R_${yeardoy}????_01H_01S_MO.ubx
    if [ $? -eq 0 ] && [ -f $rnxfile ]; then
       # success, remove the ubx files from the spool directory
       echo $(date -u +"%F %R") Succesfully created rinex file $rnxfile  >> $logfile
       rm ${d}/${identifier}_R_${yeardoy}????_01H_01S_MO.ubx || echo $(date -u +"%F %R") **Error: failed to remove ${identifier} ubx files from spooldir ${d}  >> $logfile
    else
       echo $(date -u +"%F %R") **Error: failed to create $rnxfile  >> $logfile
       continue
    fi
    # push the rinex file to remote server (optionally) and/or move to archive
    if [ "${remoternx}" != "" ]; then
       eval remote=${remoternx}
       curl -s --ftp-create-dirs --connect-timeout 10 --max-time 180 -T $rnxfile $authrnx  $remote
       if [ $? -eq 0 ]; then
          echo $(date -u +"%F %R") Succesfully pushed $rnxfile to $remote >> $logfile
          mkdir -p ${archivedir}/${year}/${doy} || echo $(date -u +"%F %R") **Error: failed to create directory ${archivedir}/${year}/${doy} >> $logfile
          mv $rnxfile ${archivedir}/${year}/${doy}/ || echo $(date -u +"%F %R") **Error: failed to move $rnxfile to $archive >> $logfile
       else
          echo $(date -u +"%F %R") **Error: failed to upload $rnxfile to $remote  >> $logfile
       fi
       navfile=${rnxfile%10S_MO.crx.gz}MN.rnx.gz
       if [ -f $navfile ]; then
          curl -s --ftp-create-dirs --connect-timeout 10 --max-time 180 -T $navfile $authrnx  $remote
          if [ $? -eq 0 ]; then
             echo $(date -u +"%F %R") Succesfully pushed $navfile to $remote >> $logfile
             mkdir -p ${archivedir}/${year}/${doy} || echo $(date -u +"%F %R") **Error: failed to create directory ${archivedir}/${year}/${doy} >> $logfile
             mv $navfile ${archivedir}/${year}/${doy}/ || echo $(date -u +"%F %R") **Error: failed to move $navfile to $archive >> $logfile
          else
             echo $(date -u +"%F %R") **Error: failed to upload $navfile to $remote  >> $logfile
          fi
       fi
    else
       mkdir -p ${archivedir}/${year}/${doy} || echo $(date -u +"%F %R") **Error: failed to create directory ${archivedir}/${year}/${doy} >> $logfile
       mv $rnxfile ${archivedir}/${year}/${doy}/ || echo $(date -u +"%F %R") **Error: failed to move $rnxfile to $archive >> $logfile
       navfile=${rnxfile/10S_MO.crx.gz/MN.rnx.gz}
       if [ -f $navfile ]; then
          mv $navfile ${archivedir}/${year}/${doy}/ || echo $(date -u +"%F %R") **Error: failed to move $navfile to $archive >> $logfile
       fi
    fi
done

# Remove empty spool folders
for d in ${spoolfolders}; do
    count=$(find ${d}/ -name "*.*" | wc -l)
    if [ $count -eq 0 ]; then
       rmdir ${d} || echo $(date -u +"%F %R") **Error: failed to remove spooldir ${d}  >> $logfile
    fi
done

cd $orgdir

exit 0
