#!/bin/sh
#
# ubx2dailyrnx   Create one daily rinex3 file from multiple ubx files
#
# (c) 2024 Hans van der Marel, TUD.

# paths to programs

#convbin="/c/Programs/rtklib_demo5_b34g/convbin.exe"
#rnx2crx="/c/bin/rnx2crx.exe" 
convbin=./convbin
rnx2crx=./rnx2crx

# process options and file arguments

intv=10
hatanaka=no
convopt="-ht NON_GEODETIC -hr \" /UBLOX ZED-F9P/ \" -ha \" /ANN-MB-00\""

while getopts ":hzc:i:" options; do
  case "${options}" in
    c)
      configfile=${OPTARG}
      if [ -f ${configfile} ] ; then
         convopt=$(cat ${configfile})
      else
         echo "Config file $configfile does not exist, quiting..."
         exit 1
      fi
      ;;
    i)
      intv=${OPTARG}
      ;;
    :)                                         # If expected argument omitted:
      echo "Error: -${OPTARG} requires an argument."
      exit
      ;;
    z)
      hatanaka=yes
      ;;
    h|\?)
      echo "Create one daily rinex3 file from multiple ubx files."
      echo "Syntax:"
      echo "   ubx2dailyrnx -h"
      echo "   ubx2dailyrnx [-z] [-c file.cfg] [-i <interval>] ubxfiles"
      echo " "
      echo "Files with ubx data must adhere to the rinex3 standard, with"
      echo "marker_?_yeardoyhhmm_##D_##S_MO.ubx[.gz]."
      echo " "
      echo "Daily rinex3 files are created in the current directory. The default"
      echo "interval is 10 sec, this can be changed with the -i option. With the"
      echo "option -z the output files will be Hatanaka and gzip compressed. Any"
      echo "files in the current directory will be overwritten."
      exit
      ;;
    *)
      echo "Error: unknown option ${option}, quiting."
      exit 1
      ;;
  esac
done
shift $((OPTIND-1))

if [ $# -lt 1 ]; then
   echo "$(basename $0) expects at least one input ubx file, quiting..."
   exit 1
fi
ubxfiles=$*

# Check that the input files are consitent with each other

marker=""
year=""
doy=""
compressed=""
for ubxfile in ${ubxfiles}; do
   # Get the basename from the ubx files (The basename must consistent with RINEX3 file naming)
   filename=$(basename ${ubxfile})
   # Parse rinex version 3 for marker name and date info
   curmarker=${filename%%_*}
   rem=${filename#*_?_}
   yeardoyhhmm=${rem%%_*}
   rem=${rem#*_}
   curyear=${yeardoyhhmm:0:4}
   curdoy=${yeardoyhhmm:4:3}
   if [ "${filename: -3}" == ".gz" ]; then
      curcompressed="yes"
   else
      curcompressed="no"
   fi
  # Check that all files are for the same marker and days and have same compression state
   if [ "${marker}" == "" ]; then
      marker=${curmarker}
      year=${curyear}
      doy=${curdoy}
      compressed=${curcompressed}
   fi
   if [ "${curmarker}" !=  "${marker}" ] || [ "${curyear}" !=  "${year}" ] ||
          [ "${curdoy}" !=  "${doy}" ] || [ "${curcompression}" !=  "${compression}" ] ; then
      echo "Input files are not for the same station, year or doy, or have not the same compression state, quiting..."
      exit 2
   fi
done

# Set output file basename
 
filename=${marker}_R_${year}${doy}0000_01D_${intv}S_MO.ubx
 
# Concatenate all input ubx files

if [ ${compressed} == "yes" ]; then
   zcat ${ubxfiles} > ${filename}
else
   cat ${ubxfiles} > ${filename} 
fi
if [ $? -ne 0 ]; then
    echo "Some input files are missing or corrupt, check your input arguments and try again." 
    if [ -f ${filename} ] ; then
        rm ${filename} || echo "Error deleting concattenated ubx file."
    fi
    exit 2 
fi
# Get the start and end time (ubx files have some data before and after)

ymd=`date -d "${year}/01/01 + $(($doy-1)) days" +%Y/%m/%d 2> /dev/null`
if [ $? -eq 0 ]; then
    # date is probably gnu date
    ts="${ymd} 00:00:00"
    te=`date -d "$ts + day" +"%Y/%m/%d %H:%M:%S"`
else
    # date is not gnu date, probably Busybox, +hour and +days not supported
    ts=`date -d "${year}-01-${doy} 00:00:00" +"%Y/%m/%d %H:%M:%S"`
    #ddoy=${doy:0:1}
    #ddoy=${ddoy/0/}${doy:1}
    #dddoy=${ddoy:0:1}
    #ddoy=${dddoy/0/}${ddoy:1}
    ddoy=$(echo ${doy} | sed 's/^0*//')
    te=`date -d "${year}-01-$((${ddoy}+1)) 00:00:00" +"%Y/%m/%d %H:%M%S"`
fi

#echo $year $doy $ymd 
#echo $ts
#echo $te

# Convert to RINEX 3.03 (trimming the files to day boundaries)

echo ${convbin} -os -od -f 5 -v 3.03 -tt 0.1 -ts $ts -te $te -ti ${intv} -hm "$marker" -hn "$marker" ${convopt} ${filename}
eval ${convbin} -os -od -f 5 -v 3.03 -tt 0.1 -ts $ts -te $te -ti ${intv} -hm "$marker" -hn "$marker" ${convopt} ${filename}
if [ $? -eq 0 ]; then
   # rename observation and navigation files to meet rinex filenaming convention
   mv ${filename/MO.ubx/MO.obs} ${filename/MO.ubx/MO.rnx}
   if [ -f ${filename/MO.ubx/MO.nav} ]; then
      mv ${filename/MO.ubx/MO.nav} ${filename/${intv}S_MO.ubx/MN.rnx}
   fi
   # compress the files (optional)
   if [ "${hatanaka}" == "yes" ]; then
      echo Compress output rinex files
      ${rnx2crx} -f ${filename/MO.ubx/MO.rnx}
      if [ $? -eq 0 ]; then
         rm ${filename/MO.ubx/MO.rnx} || echo "Error removing temporary rinex file ${filename/MO.ubx/MO.rnx}"
      else
         echo "Error Hatanaka compression ${filename/MO.ubx/MO.rnx}, quiting..."
         exit 5
      fi
      gzip -f ${filename/MO.ubx/MO.crx} || { echo "Error gzip compression ${filename/MO.ubx/MO.crx}"; exit 6 ; }
      if [ -f ${filename/${intv}S_MO.ubx/MN.rnx} ]; then
         gzip -f ${filename/${intv}S_MO.ubx/MN.rnx} || { echo "Error gzip compression ${filename/${intv}S_MO.ubx/MN.rnx}"; exit 6 ; }
      fi
   fi
   # delete uncompressed ubxfile
   echo Remove temporary decompressed daily ubxfile
   rm ${filename} || echo "Error removing ${filename}"
else
   echo Error in RTKLIB convbin conversion of ubx to rinex, quiting...
   exit 4
fi

exit 0