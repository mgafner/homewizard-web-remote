# This file is part of homewizard-web-remote (hwwr)                                                    
# https://github.com/mgafner/homewizard-web-remote                                            
#                                                                                
# hwwr is free software: you can redistribute it and/or modify                 
# it under the terms of the GNU General Public License as published by            
# the Free Software Foundation, either version 3 of the License, or               
# (at your option) any later version.                                             
#                                                                                
# hwwr is distributed in the hope that it will be useful,                      
# but WITHOUT ANY WARRANTY; without even the implied warranty of                  
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the                   
# GNU General Public License for more details.                                    
#                                                                                
# You should have received a copy of the GNU General Public License               
# along with hwwr.  If not, see <http://www.gnu.org/licenses/>.

# Constants --------------------------------------------------------------------
#
# you may overwrite all this constants in 
#   ~/.homewizard/homewizardrc 

#HOMEWIZARD_IP="192.168.1.99"
#HOMEWIZARD_PW="yourpass"
PROFILEDIR="$HOME/.homewizard"
PROFILE="$PROFILEDIR/homewizardrc"
CACHETIME=10                            # how long to cache the values in [s]
SIGINT=2
DEBUG=0

# get all informations from homewizard:
# GET /yourpass/enlist
# GET /yourpass/get-sensors
# GET /yourpass/suntimes
# GET /yourpass/get-status

# Functions --------------------------------------------------------------------

# ------------------------------------------------------------------------------
control_c()
# ------------------------------------------------------------------------------
#
# Description:  run if user hits control-c
#
# Parameter  :  none
#
# Output     :  logging
#
{
if [ $DEBUG -ge 3 ]; then set -x
fi

echo ""
}

# ------------------------------------------------------------------------------
gethumidity()
# ------------------------------------------------------------------------------
#
# Description:  return the humidity of a device
#
# Parameter  :  none
#
# Output     :  logging
#
{
  update_cache
  echo `cat $PROFILEDIR/homewizard-sensors.json | jq '.thermometers | .[] | select(.name=='\"$1\"') | .hu'`
}


# ------------------------------------------------------------------------------
presetname()
# ------------------------------------------------------------------------------
#
# Description:  return the name of the active preset (0-3)
#
# Parameter  :  none
#
# Output     :  logging
#
{
  case $1 in
  0)
    echo "home"
    ;;
  1)
    echo "away"
    ;;
  2)
    echo "sleep"
    ;;
  3)
    #echo "holiday"
    echo "guest"            # the author is using 'holiday'-mode as 'guest'-mode
    ;;
  esac
}

# ------------------------------------------------------------------------------
getpreset()
# ------------------------------------------------------------------------------
#
# Description:  return the active preset (0-3)
#
# Parameter  :  none
#
# Output     :  logging
#
{
  update_cache
  preset=`cat $PROFILEDIR/homewizard-status.json | jq '.preset'`
  echo `presetname $preset`
}

# ------------------------------------------------------------------------------
setpreset()
# ------------------------------------------------------------------------------
#
# Description:  set a preset
#
# Parameter  :  preset, one of [0,1,2,3]
#               0 = home
#               1 = away
#               2 = sleep
#               3 = holiday (or in my personal case: guest)
#
# Output     :  logging
#
{
  case $1 in
  home)
    newpreset=0
    ;;
  away)
    newpreset=1
    ;;
  sleep)
    newpreset=2
    ;;
  holiday|guest)           # the author is using 'holiday'-mode as 'guest'-mode
    newpreset=3
    ;;
  esac
  wget -O /dev/null -q http://$HOMEWIZARD_IP/$HOMEWIZARD_PW/preset/$1
  echo `presetname $1`
  update_cache
}

# ------------------------------------------------------------------------------
getsensors()
# ------------------------------------------------------------------------------
#
# Description:  return the state of a device
#
# Parameter  :  none
#
# Output     :  logging
#
{
  update_cache
  echo `cat $PROFILEDIR/homewizard-sensors.json | jq '.switches | .[] | select(.name=='\"$1\"') | .status' | sed 's/\"//g'`
}

# ------------------------------------------------------------------------------
gettemperature()
# ------------------------------------------------------------------------------
#
# Description:  return the temperature of a device
#
# Parameter  :  none
#
# Output     :  logging
#
{
  update_cache
  echo `cat $PROFILEDIR/homewizard-sensors.json | jq '.thermometers | .[] | select(.name=='\"$1\"') | .te'`
}

# ------------------------------------------------------------------------------
switch2id()
# ------------------------------------------------------------------------------
#
# Description:  converts switch to id
# 
# Parameter  :  <switchname> 
#
# Return     :  <id>
#
{
  ID=`cat $PROFILEDIR/homewizard-sensors.json | jq '.switches | .[] | select(.name=='\"$1\"') | .id'`
  if [ -z "$ID" ] ; then
    echo -e "ID of Switch '$1' not found. Exiting..."
    exit 1
  else
    echo $ID
  fi
}


# ------------------------------------------------------------------------------
switch() 
# ------------------------------------------------------------------------------
#
# Description:  switch a switch on or off
# 
# Parameter  :  <switch> <on/off>
#
# Output     :  none
#
{
  SWITCH=`switch2id $1`
  wget -O /dev/null -q http://$HOMEWIZARD_IP/$HOMEWIZARD_PW/sw/$SWITCH/$2
  update_cache
}

# ------------------------------------------------------------------------------
update_cache()
# ------------------------------------------------------------------------------
#
# Description:  writes a json file of all switches of the homewizard
# 
# Parameter  :  none
#
# Output     :  none
#
{
  if [ -f "$PROFILEDIR/homewizard-sensors.json" ]; then
    lastmodified=$(( $(date +%s) - $(stat -c %Y "$PROFILEDIR/homewizard-sensors.json") ))
    if [ "$lastmodified" -lt "$CACHETIME" ]; then
      return
    else
      if [ -f "$PROFILEDIR/update.lock" ]; then
        rm "$PROFILEDIR/update.lock"
      fi
    fi
  fi
  if [ ! -f "$PROFILEDIR/update.lock" ]; then
    touch "$PROFILEDIR/update.lock"
    PID=`date +%N`
    wget -O - -q http://$HOMEWIZARD_IP/$HOMEWIZARD_PW/get-sensors | jq '.response' > /tmp/homewizard-sensors.json-$PID
    if [ -f /tmp/homewizard-sensors.json-$PID ]; then
      mv /tmp/homewizard-sensors.json-$PID $PROFILEDIR/homewizard-sensors.json
    fi
    wget -O - -q http://$HOMEWIZARD_IP/$HOMEWIZARD_PW/get-status | jq '.response' > /tmp/homewizard-status.json-$PID
    if [ -f /tmp/homewizard-status.json-$PID ]; then
      mv /tmp/homewizard-status.json-$PID $PROFILEDIR/homewizard-status.json
    fi
    if [ -f "$PROFILEDIR/update.lock" ]; then
      rm "$PROFILEDIR/update.lock"
    fi
  fi
}

# ------------------------------------------------------------------------------
usage()
# ------------------------------------------------------------------------------
#
# Description:  shows help text
# 
# Parameter  :  none
#
# Output     :  shows help text
#
{
cat << EOF

usage: $(basename $0) -d <switchdevice> -s <on/off>

OPTIONS:
  -d    <device>
  -g    get status of a sensor/device, needs option -d too
  -h    get humidity of a sensor, needs option -d too
  -t    get temperature of a sensor, needs option -d too
  -p    needs options: keyword or number: 0,1,2,3 or ?
        0 or home
        1 or away
        2 or sleep
        3 or holiday/guest
        for options 0-3 it sets the preset to 0-3
        for option ? it returns the current set preset
  -u    update all caches

examples:

  switch a device on or off
  $(basename $0) -d Loudspeaker -s on
  $(basename $0) -d Loudspeaker -s off

EOF
return 0
}

# ------------------------------------------------------------------------------
# Main
# ------------------------------------------------------------------------------

# trap keyboard interrupt (control-c)
trap control_c $SIGINT

if [ ! -d "$PROFILEDIR" ]; then
  mkdir -p "$PROFILEDIR"
fi

# load configuration
if [ -f "$PROFILE" ]; then
  . "$PROFILE"
else
  if [ ! -z "$HOMEWIZARD_IP" ] || [ ! -z "$HOMEWIZARD_PW" ]; then
    echo "Error:" 
    echo "'HOMEWIZARD_IP' and 'HOMEWIZARD_PW' have to be set either in the "
    echo "header of $0 or in $PROFILE"
    exit 1
  fi
fi

# When you need an argument that needs a value, you put the ":" right after 
# the argument in the optstring. If your var is just a flag, withou any 
# additional argument, just leave the var, without the ":" following it.
#
# please keep letters in alphabetic order
#
while getopts ":d:ghp:s:tu" OPTION
do
  case $OPTION in
    d)
      GETOPTS_DEVICE="$OPTARG"
      ;;
    g)
      GETOPTS_GETSENSORS=1
      ;;
    h)
      GETOPTS_HUMIDITY=1
      ;;
    p)
      GETOPTS_PRESET="$OPTARG"
      ;;
    s)
      GETOPTS_SWITCH="$OPTARG"
      ;;
    t) 
      GETOPTS_TEMPERATURE=1
      ;;
    u)
      update_cache
      ;;
    \?)
      usage
      exit 1
      ;;
    :)
      echo -e "Option -$OPTARG requires an argument." >&2
      exit 1
      ;;
  esac
done

if [ ! -z $GETOPTS_SWITCH ] ; then
  if [ -z $GETOPTS_DEVICE ] ; then
    echo -e "Option -s needs Option -d too"
    exit 1
  else
    switch $GETOPTS_DEVICE $GETOPTS_SWITCH
  fi
fi

if [ ! -z $GETOPTS_PRESET ] ; then
  case $GETOPTS_PRESET in
   home|0)
     setpreset 0
     ;;
   away|1)
     setpreset 1
     ;;
   sleep|2)
     setpreset 2
     ;;
   holiday|guest|3)  # the author is using 'holiday'-mode as 'guest'-mode
     setpreset 3
     ;;
   ?)
     getpreset
     ;;
   *)
     echo -e "Arguments for Option -p are: 0,1,2,3,?"
     exit 1
     ;;
  esac
fi

if [ ! -z $GETOPTS_GETSENSORS ] ; then
  if [ -z $GETOPTS_DEVICE ] ; then
    echo -e "Option -g needs Option -d too"
    exit 1
  else
    getsensors $GETOPTS_DEVICE $GETOPTS_SWITCH
  fi
fi

if [ ! -z $GETOPTS_HUMIDITY ] ; then
  if [ -z $GETOPTS_DEVICE ] ; then
    echo -e "Option -h needs Option -d too"
    exit 1
  else
    gethumidity $GETOPTS_DEVICE 
  fi
fi

if [ ! -z $GETOPTS_TEMPERATURE ] ; then
  if [ -z $GETOPTS_DEVICE ] ; then
    echo -e "Option -t needs Option -d too"
    exit 1
  else
    gettemperature $GETOPTS_DEVICE
  fi
fi

