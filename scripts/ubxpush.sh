#!/bin/sh
#
# ubxpush   push hourly ubx files to archive and upload to upstream server
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
      echo "Push ubx files to archive and upload to upstream server."
      echo "Syntax:"
      echo "   ubx_push -h"
      echo "   ubx_push identifier"
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

# Find files that are currently not in use

currentfile=${identifier}_R_$(date -u +"%Y%j%H00")_01H_01S_MO.ubx
#echo "$currentfile"
#ubxfilelist=$(find ${rundir}/${identifier}*.ubx -mmin +5 ! -name $currentfile)
ubxfilelist=$(find ${rundir}/${identifier}*.ubx -mmin +5)

# Copy file(s) that are currently not in use to spool directory for further processing

if [ "${remoternx}" != "" ] ; then
    for f in ${ubxfilelist}; do
        yeardoy=${f#*_?_}
        #yeardoy=${yeardoy:0:7}
        yeardoy=${yeardoy%%????_*}
        mkdir -p ${spooldir}/${yeardoy} || echo $(date -u +"%F %R") **Error: failed to create directory ${spooldir}/${yeardoy} >> $logfile
        cp $f ${spooldir}/${yeardoy}/ || echo $(date -u +"%F %R") **Error: failed to ingest $f into ${spooldir}/${yeardoy} >> $logfile
    done
fi

# Compress file(s) that are currently not in use

for f in ${ubxfilelist}; do
    gzip $f || echo $(date -u +"%F %R") **Error: failed to gzip $f >> $logfile
done

# Optionally upload compressed file(s) to upstream server and on success move to archive

for f in $(find ${rundir}/ -name "${identifier}*.ubx.gz"); do
    # Parse rinex version 3 name for marker name and date info
    filename=$(basename $f)
    marker=${filename%%_*}
    rem=${filename#*_?_}
    yeardoyhhmm=${rem%%_*}
    #year=${yeardoyhhmm:0:4}
    #doy=${yeardoyhhmm:4:3}
    #hour=${yeardoyhhmm:7:2}
    year=${yeardoyhhmm%%???????}
    doy=${yeardoyhhmm#????};doy=${doy%%????}
    hour=${yeardoyhhmm#???????};hour=${hour%%??}
    # push the ubx file to remote server (optionally) and/or move to archive
    if [ "${remoteubx}" != "" ]; then
       eval remote=${remoteubx}
       curl -s --ftp-create-dirs --connect-timeout 10 --max-time 180 -T $f $authubx  $remote
       if [ $? -eq 0 ]; then
          echo $(date -u +"%F %R") Succesfully pushed $filename to $remote >> $logfile
          mkdir -p ${archivedir}/${year}/${doy} || echo $(date -u +"%F %R") **Error: failed to create directory ${archivedir}/${year}/${doy} >> $logfile
          mv $f ${archivedir}/${year}/${doy} || echo $(date -u +"%F %R") **Error: failed to move $filename to $archive >> $logfile
       else
          echo $(date -u +"%F %R") **Error: failed to upload $filename to $remote  >> $logfile
       fi
    else
       mkdir -p ${archivedir}/${year}/${doy} || echo $(date -u +"%F %R") **Error: failed to create directory ${archivedir}/${year}/${doy} >> $logfile
       mv $f ${archivedir}/${year}/${doy} || echo $(date -u +"%F %R") **Error: failed to move $filename to $archive >> $logfile
    fi
done

exit
