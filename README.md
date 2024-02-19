## Yet another Arduino DHT22 automatic recorder on SD card

Nothing fancy but it does the job of recording temperature and humidity every minute. The txt file format on SD card is voluntarily simple in order to read it easily with Matlab. Another Matlab code allows reading and plotting live data. If the SD card is not available, the code just continues outputting data to the serial and ignore the SD card. This means that the card can be removed at any time during recording to plot data on a computer for example (In other words, it can be hot plugged). In this case, the Arduino just sends a red flash to indicate that it runs without the SD connected. The writing continues on the same file as soon as the card is connected again. It is not sensitive to power shutdown as it will reboot in exactly the same state everytime.

This device is intended to be lost somewhere for long time recording. I've tried it for recording two consecutive weeks of temperature and humidity without reboot, it worked.

To what I understand, pinout for SD card must be strict on Arduino as only Chip Select pin can be changed, so refer to the pinout given in the project. If you use an SD shield, CS may differ (it's generally 4, 6 or 10 by default).

## Parts and depedencies needed
- An [Arduino Uno](https://fr.aliexpress.com/item/1005006088733150.html), the cheaper the better;
- A [generic SD shield](https://fr.aliexpress.com/item/1005006005013220.html) (regular or micro, does not care);
- A [DHT22 module with everything integrated](https://fr.aliexpress.com/item/1005005996195284.html). The red AM2302 stuff is the one I used;
- Two leds and two 220 Ohms resistors. In fact the Arduino D pins are current limited to 20 mA so no resistor is probably OK too (I used none because I don't care).
- The quite old [Adafruit DHT library](https://github.com/adafruit/DHT-sensor-library) is to be used here among the dozens of other possible libraries.
  
## The pinout
![](Pictures/Schematic_DHT22.png)

## The thing as I made it on a generic Arduino prototyping board
![](Pictures/Image_of_the_device.png)

## Funfact
If this device did not generate energy savings for the moment, it at least proved that the energy saving closure of a certain university during a certain gas war in Europe was only a political display since the heating remained on full blast during the entire closure. 
