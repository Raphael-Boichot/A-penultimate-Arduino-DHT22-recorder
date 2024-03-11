/*
  Code adapted from here by Raphaël BOICHOT, january 2023
  https://microcontrollerslab.com/dht22-data-logger-arduino-micro-sd-card/
  to be used with:
  https://github.com/adafruit/DHT-sensor-library
  pinout Arduino to SD
  GND<->GND
  +5V<->+5V
  D10<->CS
  D11<->MOSI
  D12<->MISO
  D13<->SCK

  Arduino to DHT22
  GND<->GND
  +5V<->+5V
  D2<->DAT

  Arduino to LEDS
  GND<->led cathodes
  D4<->green led anode
  D5<->red led anode
*/

#include "SD.h"
#include <SPI.h>
#include "DHT.h"

#define DHTPIN 2
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);
File myFile;

int RED_LED = 5;
int GREEN_LED = 4;
int CHIP_SELECT = 10;        //may be different if you use a SD shield (generally 6 if not 10)
unsigned long delay_s = 60;  //enter delay between measurements in seconds here.
unsigned long preceding_time, preceding_timeLED;
//The time constant of the sensor itself is about 2-3 minutes
int def_LED;
String Temperature, Humidity, Data;

void setup() {
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  Serial.begin(115200);
  def_LED = GREEN_LED;
  Serial.println("Initializing DHT22 sensor...");
  dht.begin();
  if (isnan(dht.readTemperature()) || isnan(dht.readHumidity())) {
    Serial.println("DHT22 Sensor not working !");
    def_LED = RED_LED;
  }

  Serial.println("Initializing SD card...");
  if (!SD.begin(CHIP_SELECT)) {
    Serial.println("SD initialization failed !");
    def_LED = RED_LED;
  } else {
    Serial.println("SD initialization OK !");
    Data = "00.00 00.00";  //this is just to detect reboot or loss of power during acquisition
    myFile = SD.open("data.txt", FILE_WRITE);
    Serial.print("Writing marker to data.txt... ");
    myFile.println(Data);
    myFile.close();
    Serial.println("done.");
  }

  for (int j = 0; j < 10; j++) {
    digitalWrite(def_LED, 1);
    delay(20);
    digitalWrite(def_LED, 0);
    delay(100);
  }
  preceding_time = millis();
  preceding_timeLED = millis();
}

void loop() {
  while (1) {

    if ((millis() - preceding_timeLED) >= (1000)) {  //just to indicate that the device is running
      preceding_timeLED = millis();
      digitalWrite(def_LED, 1);
      delayMicroseconds(250);
      digitalWrite(def_LED, 0);
    }

    if ((millis() - preceding_time) >= (delay_s * 1000)) {  //measure temperature once evey delay_s seconds
      preceding_time = millis();
      if (isnan(dht.readTemperature()) || isnan(dht.readHumidity())) {
        Serial.println("DHT22 Sensor not working !");
        def_LED = RED_LED;
      } else {
        data_logging();
      }
      break;
    }
  }
}

void data_logging() {
  String Temperature = String(dht.readTemperature(), 2);
  String Humidity = String(dht.readHumidity(), 2);
  Data = Temperature + " " + Humidity;
  Serial.print("Temperature:");
  Serial.println(Temperature);
  Serial.print("Humidity:");
  Serial.println(Humidity);

  if (!SD.begin(CHIP_SELECT)) {
    Serial.println("Writing failed, card not connected!");
    def_LED = RED_LED;
    digitalWrite(def_LED, 1);
    delay(200);
    digitalWrite(def_LED, 0);
  } else {
    myFile = SD.open("data.txt", FILE_WRITE);
    def_LED = GREEN_LED;
    digitalWrite(def_LED, 1);
    delay(200);
    digitalWrite(def_LED, 0);
    Serial.print("Writing to data.txt... ");
    myFile.println(Data);
    myFile.close();
    Serial.println("done.");
  }
  Serial.println("-------------------------------");
}
