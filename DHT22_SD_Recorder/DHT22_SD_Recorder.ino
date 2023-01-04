/*
  Code adapted from here by Raphaël BOICHOT, january 2023
  https://microcontrollerslab.com/dht22-data-logger-arduino-micro-sd-card/
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
DHT dht (DHTPIN, DHTTYPE);
File myFile;

int RED_LED = 5;
int GREEN_LED = 4;
int CHIP_SELECT = 10;//may be different if you use a SD shield (generally 6 if not 10)
int delay_seconds = 10;//enter delay between measurements in seconds here. The time constant of the sensor itself is about 5 minutes
int def_LED, SD_ready;
String Temperature, Humidity, Data;

void setup() {
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  Serial.begin(115200);
  dht.begin() ;
  Serial.println("Initializing SD card...");
  if (!SD.begin(CHIP_SELECT)) {
  Serial.println("SD initialization failed !");
  SD_ready = 0;
  }
  else {
  Serial.println("SD initialization OK !");
  SD_ready = 1;
  }
  
  if (SD_ready == 1) {
    def_LED = GREEN_LED;
  }
    else {
    def_LED = RED_LED;
  }

  for (int j = 0; j < 10; j++) {
    digitalWrite(def_LED, 1);
    delay(20);
    digitalWrite(def_LED, 0);
    delay(100);
  }

}

void loop() {
  if ( isnan (dht.readTemperature ( ) ) || isnan (dht.readHumidity ( ) ) )
  {
    Serial.println ("DHT22 Sensor not working !") ;
  }
  else
  {
    data_logging();
  }
  delay(delay_seconds*1000);
}

void data_logging()
{
  String Temperature = String(dht.readTemperature ( ), 2);
  String Humidity = String(dht.readHumidity ( ), 2);
  Data = Temperature + " " + Humidity;
  Serial.print("Temperature:");
  Serial.println(Temperature);
  Serial.print("Humidity:");
  Serial.println(Humidity);

  if (!SD.begin(CHIP_SELECT)) {
    Serial.println("Writing failed, card not connected!");
    digitalWrite(RED_LED, 1);
    delay(25);
    digitalWrite(RED_LED, 0);
  }
  else {
    myFile = SD.open("data.txt", FILE_WRITE);
    digitalWrite(GREEN_LED, 1);
    delay(25);
    digitalWrite(GREEN_LED, 0);
    Serial.print("Writing to data.txt... ");
    myFile.println(Data);
    myFile.close();
    Serial.println("done.");

  }
  Serial.println("-------------------------------");
}
