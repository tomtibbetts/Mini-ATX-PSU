echo 'import RPi.GPIO as GPIO
import os
import sys
import time

GPIO.setmode(GPIO.BCM)

pulseStart = 0.0
SHUTDOWN = 24               #pin 18
BOOT_OK = 23                #pin 16
REBOOTPULSEMINIMUM = 0.2    #reboot pulse signal should be at least this long
REBOOTPULSEMAXIMUM = 0.6    #reboot pulse signal should be at most this long

print ("\n=====================================\n")
print ("== ATX-PSU_startup: Initializing GPIO")
GPIO.setup(SHUTDOWN, GPIO.IN, pull_up_down = GPIO.PUD_DOWN)
GPIO.setup(BOOT_OK, GPIO.OUT, initial = GPIO.HIGH)

try:
    while True:
        print ("\n== Waiting for shutdown pulse\n")
        GPIO.wait_for_edge(SHUTDOWN, GPIO.RISING)

        print ("\nshutdown pulse received\n")
        pulseValue = GPIO.input(SHUTDOWN)
        pulseStart = time.time()

        pinResult = GPIO.wait_for_edge(SHUTDOWN, GPIO.FALLING, timeout = 600)

        if pinResult == None:
            GPIO.output(BOOT_OK, GPIO.LOW)
            os.system("sudo poweroff")
            sys.exit()
        elif time.time() - pulseStart >= REBOOTPULSEMINIMUM:
            GPIO.output(BOOT_OK, GPIO.LOW)
            os.system("sudo reboot")
            sys.exit()

        if GPIO.input(SHUTDOWN):
            GPIO.wait_for_edge(SHUTDOWN, GPIO.FALLING)

except:
    pass
finally:
    GPIO.output(BOOT_OK, GPIO.LOW)
    GPIO.cleanup()
' > /etc/ATX-PSU_startup.py
sudo chmod 755 /etc/ATX-PSU_startup.py
sudo sed -i '$ i python /etc/ATX-PSU_startup.py &' /etc/rc.local


        
