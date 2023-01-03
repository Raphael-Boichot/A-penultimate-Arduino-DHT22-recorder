# A penultimate Arduino DHT22 recorder on SD card

Nothing fancy but it does the job of recording temperature and humidity every minute. The txt file format on SD card is voluntarily Spartan in order to read it easily with Matlab. Another Matlab code allows reading and plotting live data. If the SD card is not available, the code does not start but once started, SD card can be removed during recording to plot data on a computer for example. In this case, the Arduino just sends a red flash to indicate that it runs without the SD connected. The writing continues on the same file as soon as the SD card is connected again.

This device is intended to be lost somewhere for long time recording. I've tried it for recording during two consecutive weeks without reboot, it worked.

To what I understand, pinout for SD card must be strict on Arduino as only CS can be changed, so refer to the pinout given in the project.

# The thing as I made it
![](https://github.com/Raphael-Boichot/A-penultimate-Arduino-DHT22-recorder/blob/main/IMG_20230103_142314.jpg)

# The pinout stolen [here](https://microcontrollerslab.com/dht22-data-logger-arduino-micro-sd-card/)
![](https://github.com/Raphael-Boichot/A-penultimate-Arduino-DHT22-recorder/blob/main/Arduino-with-DHT22-and-microSD-card-schematic-diagram.jpg)

The pullup resistance can be removed if you use the sensor mounted on a breakout board as I did. The two leds are not represented here but are on D4 and D5.
