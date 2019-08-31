#!/bin/bash
# Geekworm UPS Hat plugin for Nagios/Icinga
# Written by Udo Seidel
#
# Description:
#
# This plugin will check the status of a Geekworm UPS Hat connected to the RPi
#
# Location of the sudo and i2cget command (if not in path)
SUDO="/usr/bin/sudo"
I2CGET="/usr/sbin/i2cget"
BC="/usr/bin/bc"
MYTEST=""
CUSTOMWARNCRIT=0 # no external defined warning and critical levels

# sudo is needed if i2cget cannot be executed by the nagios 
# user context w/o sudo granted priviledges


# Nagios return codes
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4

EXITSTATUS=$STATE_UNKNOWN #default


PROGNAME=`basename $0`

print_usage() {
	echo 
	echo " This plugin will check the battery and voltage status of an locally attached Geekworm UPS Hat."
	echo 
	echo 
        echo " Usage: $PROGNAME -<b|v|h> -w <warning level> -c <critical level>"
        echo
        echo "   -b: Battery capacity"
        echo "   -v: Voltage"
        echo "   -w: WARNING level for battery/voltage"
        echo "   -c: CRITICAL level for battery/voltage" 
	echo 
}

if [ "$#" -lt 1 ]; then
	print_usage
        EXITSTATUS=$STATE_UNKNOWN
        exit $EXITSTATUS
fi

check_i2cget() {
if [ ! -x "$I2CGET" ]
then
        echo "UNKNOWN: $I2CGET not found or is not executable by the nagios user"
        EXITSTATUS=$STATE_UNKNOWN
        exit $EXITSTATUS
fi
}


check_battery() {
I2CGET_ARG="-y 1 0x36 4 w"
# Run basic i2cget and find our status
I2CGET_OUTPUT=`$SUDO $I2CGET $I2CGET_ARG 2>&1`

if [ $? -ne 0 ]
then
EXITSTATUS=$STATE_CRITICAL
else
EXITSTATUS=$STATE_OK
fi

CLEANED_I2CGET_OUTPUT=`sudo $I2CGET $I2CGET_ARG |sed -e 's/0x//g'|tr '[:lower:]' '[:upper:]'|awk '{print $1}' 2>&1`

CLEANED_I2CGET_OUTPUT_DEC=`bcdbyte2dec $CLEANED_I2CGET_OUTPUT`
CLEANED_I2CGET_OUTPUT=`calcbattery $CLEANED_I2CGET_OUTPUT_DEC`

if [ $CUSTOMWARNCRIT -ne 0 ]; then
	# convert them  board specific values
	WARNLEVEL=`echo "$WARNLEVEL * 256"|bc`
	CRITLEVEL=`echo "$CRITLEVEL * 256"|bc`
	# check if the levels are integers
	echo $WARNLEVEL | awk '{ exit ! /^[0-9]+$/ }'
	if [ $? -ne 0 ]; then
		echo " warning level ($WARNLEVEL) is not an integer"
		exit $STATE_UNKNOWN
	fi
	echo $CRITLEVEL | awk '{ exit ! /^[0-9]+$/ }'
	if [ $? -ne 0 ]; then
		echo " critical level ($CRITLEVEL) is not an integer"
		exit $STATE_UNKNOWN
	fi
	if [ $WARNLEVEL -lt $CRITLEVEL ]; then
		echo
		echo " The value for critical level has to be equal or lower than the one for warning level"
		echo " Your values are: critcal ($CRITLEVEL) and warning ($WARNLEVEL)"
		echo
		exit $STATE_UNKNOWN
	fi
	if [ $CLEANED_I2CGET_OUTPUT_DEC -gt $WARNLEVEL ]; then
		EXITSTATUS=$STATE_OK
		echo "Battery OK - $CLEANED_I2CGET_OUTPUT % | $CLEANED_I2CGET_OUTPUT"
	else
		EXITSTATUS=$STATE_WARNING
		if [ $CLEANED_I2CGET_OUTPUT_DEC -gt $CRITLEVEL ]; then
			echo "Battery WARNING - $CLEANED_I2CGET_OUTPUT % | $CLEANED_I2CGET_OUTPUT"
		else
			EXITSTATUS=$STATE_CRITICAL
				echo "Battery CRITICAL - $CLEANED_I2CGET_OUTPUT % | $CLEANED_I2CGET_OUTPUT"
		fi
	fi


else
	echo "Battery OK - $CLEANED_I2CGET_OUTPUT % | $CLEANED_I2CGET_OUTPUT"
fi
}


bcdbyte2dec() {
# convert the hex output to a proper dec number
if [ ! -x "$BC" ]
then
        echo "UNKNOWN: $BC not found or is not executable by the nagios user"
        EXITSTATUS=$STATE_UNKNOWN
        exit $EXITSTATUS
fi

DEC=`echo "ibase=16; $1" |bc -l`
echo $DEC
}

calcbattery() {
BAT=`echo "$1 / 256"|bc -l`
echo $BAT
}

calcvoltage() {
VOL=`echo "$1 * 78.125 / 1000000"|bc -l`
echo $VOL
}

check_voltage() {
I2CGET_ARG="-y 1 0x36 2 w"
# Run basic i2cget and find our status
I2CGET_OUTPUT=`$SUDO $I2CGET $I2CGET_ARG 2>&1`

if [ $? -ne 0 ]
then
EXITSTATUS=$STATE_CRITICAL
else
EXITSTATUS=$STATE_OK
fi

CLEANED_I2CGET_OUTPUT=`sudo $I2CGET $I2CGET_ARG |sed -e 's/0x//g'|tr '[:lower:]' '[:upper:]'|awk '{print $1}' 2>&1`

CLEANED_I2CGET_OUTPUT_DEC=`bcdbyte2dec $CLEANED_I2CGET_OUTPUT`
CLEANED_I2CGET_OUTPUT=`calcvoltage $CLEANED_I2CGET_OUTPUT_DEC`

if [ $CUSTOMWARNCRIT -ne 0 ]; then
	# convert them  board specific values
	WARNLEVEL=`echo "$WARNLEVEL * 1000000 / 78.125"|bc`
	CRITLEVEL=`echo "$CRITLEVEL * 1000000 / 78.125"|bc`
	# check if the levels are integers
	echo $WARNLEVEL | awk '{ exit ! /^[0-9]+$/ }'
	if [ $? -ne 0 ]; then
		echo " warning level ($WARNLEVEL) is not an integer"
		exit $STATE_UNKNOWN
	fi
	echo $CRITLEVEL | awk '{ exit ! /^[0-9]+$/ }'
	if [ $? -ne 0 ]; then
		echo " critical level ($CRITLEVEL) is not an integer"
		exit $STATE_UNKNOWN
	fi
	if [ $WARNLEVEL -lt $CRITLEVEL ]; then
		echo
		echo " The value for critical level has to be equal or lower than the one for warning level"
		echo " Your values are: critcal ($CRITLEVEL) and warning ($WARNLEVEL)"
		echo
		exit $STATE_UNKNOWN
	fi
	if [ $CLEANED_I2CGET_OUTPUT_DEC -gt $WARNLEVEL ]; then
		EXITSTATUS=$STATE_OK
		echo "Voltage OK - $CLEANED_I2CGET_OUTPUT V | $CLEANED_I2CGET_OUTPUT"
	else
		EXITSTATUS=$STATE_WARNING
		if [ $CLEANED_I2CGET_OUTPUT_DEC -gt $CRITLEVEL ]; then
			echo "Voltage WARNING - $CLEANED_I2CGET_OUTPUT V | $CLEANED_I2CGET_OUTPUT"
		else
			EXITSTATUS=$STATE_CRITICAL
				echo "Voltage CRITICAL - $CLEANED_I2CGET_OUTPUT V | $CLEANED_I2CGET_OUTPUT"
		fi
	fi


else
	echo "Voltage OK - $CLEANED_I2CGET_OUTPUT V | $CLEANED_I2CGET_OUTPUT"
fi
}


while getopts "hbvw:c:" OPT
do		
	case "$OPT" in
	h)
		print_usage
		exit $STATE_UNKNOWN
		;;
	b)
		MYCHECK=battery
		;;
	v)
		MYCHECK=voltage
		;;
        w)
                WARNLEVEL=$3
		CUSTOMWARNCRIT=1
                ;;
        c)
                CRITLEVEL=$5
		CUSTOMWARNCRIT=1
                ;;
	*)
		print_usage
		exit $STATE_UNKNOWN
	esac
done

check_i2cget
check_$MYCHECK

exit $EXITSTATUS

