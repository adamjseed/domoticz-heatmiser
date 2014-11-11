#!/bin/bash
#set -f              # turn off globbing
IFS=''

BASE_PATH=/usr/share/domoticz/scripts/heatmiser
HEATMISER_LOG=$BASE_PATH/heatmiser.log
DOMO_LOG=$BASE_PATH/domo.log
DOMO_IP=http://<IP OF DOMO SERVER>
DOMO_PORT=8080
HEATMISER_IP=<IP OF HEATMISER NEO HUB>
HEATMISER_PORT=4242
NOW=$(date +"%d-%m-%Y %T")


#get data from neo hub
A_TEMP=`$BASE_PATH/getdata.sh $HEATMISER_IP $HEATMISER_PORT $HEATMISER_LOG` 

#get devices from domo
curl -s $DOMO_IP:$DOMO_PORT/json.htm?type=devices > $DOMO_LOG

if [ -f $HEATMISER_LOG ];
then
	#Remove unwanted lines from heatmiser log
	sed -i '6!d' $HEATMISER_LOG
	#runs JQ to query the Heatmiser json file
	HEATMISER_JQ_OUTPUT=`$BASE_PATH/jq ".devices | .[] | .device , .CURRENT_TEMPERATURE" $HEATMISER_LOG`
	#run JQ to query DOMO json file
        DOMO_JQ_OUTPUT=`$BASE_PATH/jq ".result | .[] | .Name, .idx" $DOMO_LOG`

	#firslty puts the device name and current temp on the same line (per device) then removes quotes and repater devices
        HEATMISER_LIST=$(echo $HEATMISER_JQ_OUTPUT | sed -n '${s/$/:/p};N;s/\n/: /p' | tr -d '"' | grep -v repeater)
        #do the same for DOMO get names and IDX values
        DOMO_LIST=$(echo $DOMO_JQ_OUTPUT | sed -n '${s/$/:/p};N;s/\n/: /p' | tr -d '"' | grep HM: | sed -r 's/^.{4}//')
	DOMO_HEATING_SWITCH_IDX=$(echo $DOMO_LIST | grep Heating | cut -d ':' -f 2 | tr -d ' ')
IFS='
'
	#Loop through each Heatmiser device and get the IDX
	for HEATMISER_DEVICE in $HEATMISER_LIST
	do
		HEATMISER_DEVICE_NAME=`echo $HEATMISER_DEVICE | cut -d ':' -f 1 | tr '[:upper:]' '[:lower:]'`
		#loop for matching DOMO device NOTE: Not case senitive
		for DOMO_DEVICE in $DOMO_LIST
		do
			DOMO_DEVICE_NAME=`echo $DOMO_DEVICE | cut -d ':' -f 1 | tr '[:upper:]' '[:lower:]'`
			if [ $HEATMISER_DEVICE_NAME = $DOMO_DEVICE_NAME ]; then
				DEVICE_IDX=`echo $DOMO_DEVICE | cut -d ':' -f 2 | tr -d ' '`
				DEVICE_TEMP=`echo $HEATMISER_DEVICE | cut -d ':' -f 2 | tr -d ' '`
				echo "$NOW $DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DEVICE_IDX&nvalue=0&svalue=$DEVICE_TEMP   $DOMO_DEVICE_NAME"  				
				curl -s "$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=udevice&idx=$DEVICE_IDX&nvalue=0&svalue=$DEVICE_TEMP" > /dev/null 2>&1
			fi 
		done
	done

	#Works out if any devices is on and sets the HM: Heating Switch
	if [[ $A_TEMP == *\"HEATING\":true* ]];
	then
		echo "$NOW $DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DOMO_HEATING_SWITCH_IDX&switchcmd=On&level=0"
		curl -s    "$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DOMO_HEATING_SWITCH_IDX&switchcmd=On&level=0" > /dev/null 2>&1
	else
		echo "$NOW $DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DOMO_HEATING_SWITCH_IDX&switchcmd=Off&level=0"
		curl -s    "$DOMO_IP:$DOMO_PORT/json.htm?type=command&param=switchlight&idx=$DOMO_HEATING_SWITCH_IDX&switchcmd=Off&level=0" > /dev/null 2>&1
	fi


else
	echo "New log file not generated"
fi


#remove log file
rm -rf $HEATMISER_LOG
rm -rf $DOMO_LOG
