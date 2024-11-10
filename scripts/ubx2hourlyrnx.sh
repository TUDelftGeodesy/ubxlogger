#!/bin/sh
#
# ubx2hourlyrnx   Create hourly rinex file for each ubx file
#
# (c) 2024 Hans van der Marel, TUD.

# paths to programs

convbin=convbin
rnx2crx=rnx2crx

# process options and file arguments

hatanaka=no
convopt="-ht NON_GEODETIC -hr \" /UBLOX ZED-F9P/ \" -ha \" /ANN-MB-00\""

ALLOPTS=""
while getopts ":hc:z" options; do
  case "${options}" in
    c)
      configfile=${OPTARG}
      if [ -f ${configfile} ] ; then
         #convopt=$(<${configfile})
         convopt=$(cat ${configfile})
      else
         echo "Config file $configfile does not exist, quiting..."
         exit 1
      fi
      ALLOPTS="${ALLOPTS} -c ${OPTARG}"
      ;;
    z)
      hatanaka=yes
      ALLOPTS="${ALLOPTS} -z"
      ;;
    h|\?)
      echo "Create hourly rinex3 file from ubx file(s)."
      echo "Syntax:"
      echo "   ubx2hourlyrnx -h"
      echo "   ubx2hourlyrnx [-c file.cfg] [-z] ubxfile(s)"
      echo " "
      echo "Files with ubx data must adhere to the rinex3 standard, with"
      echo "marker_?_yeardoyhhmm_##D_##S_MO.ubx[.gz]."
      echo " "
      echo "Hourly rinex3 files are created in the current directory for each of the"
      echo "input files. With the option -z the output files will be Hatanaka and"
      echo "gzip compressed. Any files in the current directory will be overwritten."
      exit
      ;;
    *)
      echo "Error: unknown option ${option}, quiting."
      exit 1
      ;;
  esac
done

shift $((OPTIND-1))

# In case of multiple files, call this function recursively

if [ $# -gt 1 ]; then
    # call this function recursively
    for ubxfile in $*; do
       echo $0 $ALLOPTS  ${ubxfile}
       $0 $ALLOPTS  ${ubxfile}
    done
    exit 0
elif [ $# -eq 0 ]; then
   echo "$(basename $0) expects one input ubx file, quiting..."
   exit 1
fi

ubxfile=$1

# Get the basename of the ubx file (The basename must consistent with RINEX3 file naming)

if [ -f ${ubxfile} ]; then
   filename=$(basename ${ubxfile})
else
   echo "Input ubx file not found, quiting..."
   exit 2
fi

# Optionally decompress ubx file

deleteubx="no"
if [ ".${filename##*.}" = ".gz" ]; then
   echo "Decompress input ubxfile ${filename}"
   filename=${filename%.gz}
   gunzip -c ${ubxfile} > ${filename} || { echo "Error gzip decompression ${ubxfile}, quiting..." ; exit 3 ; }
   if [ $? -eq 0 ]; then
      orgfile=${ubxfile}
      ubxfile=${filename}
      deleteubx="yes"
   fi
fi

# Parse rinex version 3 for marker name and date info

marker=${filename%%_*}
rem=${filename#*_?_}
yeardoyhhmm=${rem%%_*}
rem=${rem#*_}

#year=${yeardoyhhmm:0:4}
#doy=${yeardoyhhmm:4:3}
#hour=${yeardoyhhmm:7:2}
year=${yeardoyhhmm%%???????}
doy=${yeardoyhhmm#????};doy=${doy%%????}
hour=${yeardoyhhmm#???????};hour=${hour%%??}

# Get the start and end time (ubx files have some data before and after)

ddoy=$(echo ${doy} | sed 's/^0*//')
ymd=$(date -d "${year}/01/01 + $(($ddoy-1)) days" +%Y/%m/%d 2> /dev/null)
if [ $? -eq 0 ]; then
   # date is probably gnu date
   ts="${ymd} ${hour}:00:00"
   te=$(date -d "$ts + hour" +"%Y/%m/%d %H:%M:%S")
else
   # date is not gnu date, probably Busybox, +hour and +days not supported
   ts=$(date -d "${year}-01-${doy} ${hour}:00:00" +"%Y/%m/%d %H:%M:%S")
   dhour=${hour#0}
   te=$(date -d "${year}-01-${doy} $((${dhour}+1)):00:00" +"%Y/%m/%d %H:%M:%S")
fi

#echo $year $doy $hour $ymd 
#echo $ts
#echo $te

# Convert to RINEX 3.03 (trimming the files to hour boundaries)

#echo "${convopt}"

echo ${convbin} -os -od -f 5 -v 3.03 -tt 0.1 -ts $ts -te $te -hm "$marker" -hn "$marker" ${convopt} ${ubxfile}
eval ${convbin} -os -od -f 5 -v 3.03 -tt 0.1 -ts $ts -te $te -hm "$marker" -hn "$marker" ${convopt} ${ubxfile}
if [ $? -eq 0 ]; then
   # rename observation and navigation files to meet rinex filenaming convention
   mv ${filename%MO.ubx}MO.obs ${filename%MO.ubx}MO.rnx
   if [ -f ${filename%MO.ubx}MO.nav ]; then
      mv ${filename%MO.ubx}MO.nav ${filename%01S_MO.ubx}MN.rnx
   fi
   # compress the files (optional)
   if [ "${hatanaka}" = "yes" ]; then
      echo Compress output rinex files
      ${rnx2crx} -f ${filename%MO.ubx}MO.rnx
      if [ $? -eq 0 ]; then
         rm ${filename%MO.ubx}MO.rnx || echo "Error removing temporary rinex file ${filename%MO.ubx}MO.rnx"
      else
         echo "Error Hatanaka compression ${filename%MO.ubx}MO.rnx, quiting..."
         exit 5
      fi
      gzip -f ${filename%MO.ubx}MO.crx || { echo "Error gzip compression ${filename%MO.ubx}MO.crx" ; exit 6 ; }
      if [ -f ${filename%01S_MO.ubx}MN.rnx ]; then
         gzip -f ${filename%01S_MO.ubx}MN.rnx || { echo "Error gzip compression ${filename%01S_MO.ubx}MN.rnx" ; exit 6 ; }
      fi
   fi
   if [ "${deleteubx}" = "yes" ] && [ "${orgfile}" !=  "${ubxfile}" ]; then
      # delete uncompressed ubxfile
      echo "Remove temporary decompressed input ubxfile"
      rm ${ubxfile} || echo "Error removing ${ubxfile}"
   fi
else
   echo "Error in RTKLIB convbin conversion of ubx to rinex, quiting..."
   exit 4
fi

exit 0
