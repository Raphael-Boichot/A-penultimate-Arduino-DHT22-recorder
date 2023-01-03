# A penultimate Arduino DHT22 recorder on SD card

Nothing fancy but it does the job of recording temperature and humidity every minute. The txt file format on SD card is voluntarily Spartan in order to read it easily with Matlab. Another Matlab code allows reading and plotting live data. If the SD card is not available, the code does not start but once started, SD card can be removed during recording to plot data on a computer for example. In this case, the Arduino just sends a red flash to indicate that it runs without the SD connected. The writing continues on the same file as soon as the SD card is connected again.

This device is intended to be lost somewhere for long time recording. I've tried it for recording during two consecutive weeks without reboot, it worked.

![](https://github.com/Raphael-Boichot/A-penultimate-Arduino-DHT22-recorder/blob/main/IMG_20230103_142314.jpg)
