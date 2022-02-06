check_gwupshat
==========

Very simple Nagios/Icinga plugin to check the battery and voltage status of Geekworm UPS Hat (an UPS for the Raspberry Pi)

More information can be found here: http://raspberrypiwiki.com/index.php/Raspi_UPS_HAT_Board

```
$ check_gwupshat.sh 

 This plugin will check the battery and voltage status of an locally attached UPS Hat.


 Usage: check_gwupshat.sh -<b|v|h> -w <warning level> -c <critical level>

   -b: Battery capacity
   -v: Voltage
   -w: WARNING level for battery/voltage
   -c: CRITICAL level for battery/voltage

$
```
