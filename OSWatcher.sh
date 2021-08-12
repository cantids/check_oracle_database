#!/bin/bash
echo ""
echo "OSWatcher Version：2.0.0"
echo ""
#Create Time：2016-04-08  
#Update Time：2016-09-26
######################################################################
#设置命令的路径，防止命令找不到路径
PATH=$PATH:/usr/sbin/
export PATH
echo "the PATH is:$PATH"
######################################################################
PLATFORM=`/bin/uname`
#
######################################################################
# Create log subdirectories if they don't exist
######################################################################
if [ ! -d archive ]; then
        mkdir archive
fi        

case $PLATFORM in
  Linux)
    DF='df -h'
    MEMINFO='free -m'
    MPSTAT='mpstat 1 3'
    TOP='eval top -b -n 1 | head -50'
    VMSTAT='vmstat 1 3'
    IOSTAT='iostat -d -x -k 1 5'
    PSELF='ps -elf'
    BOOTLOG='tail -500 /var/log/boot.log'
    SYSLOG='dmesg'
    MESSAGE='tail -500 /var/log/messages'
    ;;
esac
hostn=`hostname`
hour=`date +'%m.%d.%y.%H00.dat'`
echo "`date` Collect">archive/${hostn}_$hour
######################################################################
# Test for discovery of os utilities. Notify if not found.
######################################################################
echo ""
echo "Starting Data Collection..."
echo ""

case $PLATFORM in
  Linux)
    $DF > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "DF found on your system."
            echo "--1.DF==========================">>archive/${hostn}_$hour
            $DF>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... DF not found on your system."
      MEMFOUND=0
    fi
    
    $MEMINFO > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "meminfo found on your system."
            echo "--2.MEMINFO==========================">>archive/${hostn}_$hour
            $MEMINFO>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... /proc/meminfo not found on your system."
      MEMFOUND=0
    fi
    
    $MPSTAT > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "MPSTAT found on your system."
            echo "--3.MPSTAT==========================">>archive/${hostn}_$hour
          $MPSTAT>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... MPSTAT not found on your system."
      MEMFOUND=0
    fi
    
    $TOP > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "TOP found on your system."
            echo "--4.TOP==========================">>archive/${hostn}_$hour
          $TOP>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... TOP not found on your system."
      MEMFOUND=0
    fi
    
    $VMSTAT > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "VMSTAT found on your system."
            echo "--5.VMSTAT==========================">>archive/${hostn}_$hour
          $VMSTAT>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... VMSTAT not found on your system."
      MEMFOUND=0
    fi
    
    $IOSTAT > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "IOSTAT found on your system."
            echo "--6.IOSTAT==========================">>archive/${hostn}_$hour
          $IOSTAT>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... IOSTAT not found on your system."
      MEMFOUND=0
    fi
    
    $PSELF > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "PSELF found on your system."
            echo "--7.PSELF==========================">>archive/${hostn}_$hour
          $PSELF>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... PSELF not found on your system."
      MEMFOUND=0
    fi
    
    $BOOTLOG > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "BOOTLOG found on your system."
            echo "--8.BOOTLOG==========================">>archive/${hostn}_$hour
          $BOOTLOG>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... BOOTLOG not found on your system."
      MEMFOUND=0
    fi
    
    $SYSLOG > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "SYSLOG found on your system."
            echo "--9.SYSLOG==========================">>archive/${hostn}_$hour
          $SYSLOG>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... SYSLOG not found on your system."
      MEMFOUND=0
    fi
    
    $MESSAGE > /dev/null 2>&1
    if [ $? = 0 ]; then
      echo "MESSAGE found on your system."
            echo "--10.MESSAGE==========================">>archive/${hostn}_$hour
          $MESSAGE>>archive/${hostn}_$hour
      MEMFOUND=1
    else
      echo "Warning... MESSAGE not found on your system."
      MEMFOUND=0
    fi
    
    ;;
esac 

echo ""
echo "Discovery completed."
echo "Collection completed."
echo "The Collected result saved in ./archive/${hostn}_$hour."
echo ""
