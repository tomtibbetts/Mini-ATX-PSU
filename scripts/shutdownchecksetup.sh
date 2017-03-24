echo '#!/bin/bash

#This script was borrowed from the folk at LowPowerLabs and is used to support the PiRyte Mini ATX PSU.
#This script is modified to use GPIO pins that do not
#have other conflicts.  The original script used GPIO pins that were also used for SPI and so would have
#conflicted with SPI applications.
#This is GPIO 24 (pin 18 on the pinout diagram).
#This is an input from Mini ATX PSU to the Pi.
#When button is held for ~3 seconds, this pin will become HIGH signalling to this script to poweroff the Pi.
SHUTDOWN=24
REBOOTPULSEMINIMUM=200      #reboot pulse signal should be at least this long
REBOOTPULSEMAXIMUM=600      #reboot pulse signal should be at most this long
echo "$SHUTDOWN" > /sys/class/gpio/export
echo "in" > /sys/class/gpio/gpio$SHUTDOWN/direction

#Hold Mini ATX PSU button for at least 500ms but no more than 2000ms and a reboot HIGH pulse of 500ms length will be issued

#This is GPIO 23 (pin 16 on the pinout diagram).
#This is an output from Pi to Mini ATX PSU and signals that the Pi has booted.
#This pin is asserted HIGH as soon as this script runs (by writing "1" to /sys/class/gpio/gpio8/value)
BOOT=23
echo "$BOOT" > /sys/class/gpio/export
echo "out" > /sys/class/gpio/gpio$BOOT/direction
echo "1" > /sys/class/gpio/gpio$BOOT/value

echo "Mini ATX PSU shutdown script started: asserted pins ($SHUTDOWN=input,LOW; $BOOT=output,HIGH). Waiting for GPIO$SHUTDOWN to become HIGH..."

#This loop continuously checks if the shutdown button was pressed on Mini ATX PSU (GPIO7 to become HIGH), and issues a shutdown when that happens.
#It sleeps as long as that has not happened.
while [ 1 ]; do
  shutdownSignal=$(cat /sys/class/gpio/gpio$SHUTDOWN/value)
  if [ $shutdownSignal = 0 ]; then
    /bin/sleep 0.2
  else  
    pulseStart=$(date +%s%N | cut -b1-13) # mark the time when Shutoff signal went HIGH (milliseconds since epoch)
    while [ $shutdownSignal = 1 ]; do
      /bin/sleep 0.02
      if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $REBOOTPULSEMAXIMUM ]; then
        echo "Mini ATX PSU triggered a shutdown signal, halting Rpi ... "
        sudo poweroff
        exit
      fi
      shutdownSignal=$(cat /sys/class/gpio/gpio$SHUTDOWN/value)
    done
    #pulse went LOW, check if it was long enough, and trigger reboot
    if [ $(($(date +%s%N | cut -b1-13)-$pulseStart)) -gt $REBOOTPULSEMINIMUM ]; then 
      echo "Mini ATX PSU triggered a reboot signal, recycling Rpi ... "
      sudo reboot
      exit
    fi
  fi
done' > /etc/shutdowncheck.sh
sudo chmod 755 /etc/shutdowncheck.sh
sudo sed -i '$ i /etc/shutdowncheck.sh &' /etc/rc.local