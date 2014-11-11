domoticz-heatmiser
==================
The purpose of these scripts is to pull heating temperatures from the Heatmiser NEO Hub and push it into Domoticz. 

The script is fairly straightforward and easy to implement but does have a few dependencies:

1) It assumes JQ (http://stedolan.github.io/jq/: which is a JSON Parser) is available in the same directory as these scripts. Just download the binary and place it (with excuitable rights) in the same directory as the script

2) It assumes there is a switch call 'HM: Heating' in Domoticz. This is the master heating on/off switch - It doesn't actually turn the heating on or off but is updated if any Heatmiser device calls for heat. Really its just a log of when the heating is on/off.

3) It matches (not case sensitive) temperature sensors in Domoticz (which are added via dummy device) with the name of 'HM: <DEVICE_NAME> where <DEVICE_NAME> is the same name its called in Heatmiser. 
eg If you have a device call 'Master Bedroom' in Heatmiser then create a switch call 'HM: Master Bedroom' The script will then update it. 

4) To get the Heatmiser Neo data you need to have 'Expect' install. In debian systems run: 'apt-get install expect'







Install: 

1) Make sure you edit the varibales in the loadHeatingStats.sh file

2) Finally just cron the loadHeatingStats.sh script

  2a) edit crontab: 'crontab -e'

  2b) append to the bottom: '* * * * * /path/to/script/loadHeatingStats.sh  >> /var/log/loadHeatingStats.log 2>&1'

