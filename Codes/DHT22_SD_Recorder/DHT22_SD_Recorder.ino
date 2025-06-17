/*
  Code adapted initially from here by Raphaël BOICHOT, january 2023, use at your own risk
  https://microcontrollerslab.com/dht22-data-logger-arduino-micro-sd-card/
  to be used with the following libraries:
  https://github.com/adafruit/DHT-sensor-library
  https://github.com/adafruit/RTClib
------------------------------------------------------------------------------------------------------
  pinout Arduino to SD   |  Arduino to DHT22   |    Arduino to LEDS        |   Arduino to RTC (DS3231)
  GND<->GND              |  GND<->GND          |    GND<->led cathodes     |   A4 or SDA<->SCL
  +5V<->+5V              |  +5V<->VCC          |    D4<->green led anode   |   A5 or SCL<->SDA
  D10<->CS               |  D2<->DAT           |    D5<->red led anode     |   GND<->GND
  D11<->MOSI             |                     |                           |   +5V<->VCC
  D12<->MISO             |                     |                           |   SQW not connected
  D13<->SCK              |                     |                           |   32K not connected
-------------------------------------------------------------------------------------------------------
 */
#include "SD.h"
#include <SPI.h>
#include "DHT.h"
#include <Wire.h>
#include <RTClib.h>  //https://github.com/adafruit/RTClib

RTC_DS3231 rtc;  //SDA and SCL pins, or D4 and D5 (same)
#define DHTPIN 2
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);
File myFile;

int RED_LED = 5;
int GREEN_LED = 4;
int CHIP_SELECT = 10;        //may be different if you use a SD shield (generally 4 or 6 if not 10)
unsigned long delay_s = 60;  //enter delay between measurements in seconds here.
unsigned long preceding_time, preceding_timeLED;
//The time constant of the sensor itself is about 2-3 minutes
int def_LED;
String Temperature, Humidity, Data;

void setup() {
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  Serial.begin(115200);
  while (!Serial)
    ;
  Serial.println(F("// By Raphaël BOICHOT, March 2024"));
  Serial.println(F("// This program comes with ABSOLUTELY NO WARRANTY;"));
  Serial.println(F("// This is free software, and you are welcome to redistribute it"));
  digitalWrite(RED_LED, 1);
  digitalWrite(GREEN_LED, 1);
  delay(2500);
  digitalWrite(RED_LED, 0);
  digitalWrite(GREEN_LED, 0);

  def_LED = GREEN_LED;
  Serial.println(F("// Initializing DHT22 sensor..."));
  dht.begin();
  if (isnan(dht.readTemperature()) || isnan(dht.readHumidity())) {
    Serial.println(F("// DHT22 Sensor not working !"));
    def_LED = RED_LED;
  }

  Serial.println(F("// Initializing SD card..."));
  if (!SD.begin(CHIP_SELECT)) {
    Serial.println(F("// SD initialization failed !"));
    def_LED = RED_LED;
  } else {
    Serial.println(F("// SD initialization OK !"));
    Data = F("The device has restarted following a power cut");  //this is just to detect reboot or loss of power during acquisition
    myFile = SD.open("data.txt", FILE_WRITE);
    Serial.println(F("// Writing power down marker to data.txt..."));
    myFile.println(Data);
    myFile.close();
  }

  Serial.println(F("// Initializing RTC module..."));
  if (!rtc.begin()) {
    Serial.println(F("// RTC module not responding !"));
    def_LED = RED_LED;
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
      delay(10);
      digitalWrite(def_LED, 0);
    }

    if ((millis() - preceding_time) >= (delay_s * 1000)) {  //measure temperature once evey delay_s seconds
      preceding_time = millis();
      if (isnan(dht.readTemperature()) || isnan(dht.readHumidity())) {
        Serial.println(F("// DHT22 Sensor not working !"));
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
  if (!rtc.begin()) {
    Serial.println(F("// RTC module not responding !"));
    def_LED = RED_LED;
  }
  DateTime date = rtc.now();
  // this part was made with ChatGPT
  char formattedDate[20];  // Table to store the formatted date
  // Date format YYYY-MM-DD HH:MM:SS
  sprintf(formattedDate, "%04d-%02d-%02d %02d:%02d:%02d", date.year(), date.month(), date.day(), date.hour(), date.minute(), date.second());
  // end of part made with ChatGPT
  Data = "Temperature: " + Temperature + " Humidity: " + Humidity + " Date/Time: ";
  Data = Data + formattedDate;

  Serial.println(Data);
  if (!SD.begin(CHIP_SELECT)) {
    Serial.println(F("// Writing failed, card not connected !"));
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
    myFile.println(Data);
    myFile.close();
  }
}
