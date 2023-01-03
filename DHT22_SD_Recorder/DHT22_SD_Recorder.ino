/*
Code adapted from here
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
DHT dht (DHTPIN, DHTTYPE) ;
int RED_LED = 5;
int GREEN_LED = 4;

File myFile;
String Temperature, Humidity, Data;

void setup() {
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  Serial.begin(115200);
  dht.begin (  ) ;
  Serial.print("Initializing SD card...");
  if (!SD.begin(10)) {
    Serial.println("initialization failed!");
    while (1) {
      digitalWrite(RED_LED, 1);
      delay(20);
      digitalWrite(RED_LED, 0);
      delay(1000);
    }
  }
  Serial.println("initialization done.");
  for (int j = 0; j < 10; j++) {
    digitalWrite(GREEN_LED, 1);
    delay(20);
    digitalWrite(GREEN_LED, 0);
    delay(100);
  }
}

void loop() {
  if ( isnan (dht.readTemperature ( ) ) || isnan (dht.readHumidity ( ) ) )
  {
    Serial.println ("DHT22 Sensor not working!") ;
  }
  else
  {
    data_logging();
  }
  delay(60000);
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

  if (!SD.begin(10)) {
    Serial.println("Writing failed, card not connected!");
    digitalWrite(RED_LED, 1);
    delay(1000);
    digitalWrite(RED_LED, 0);
  }
    else {
    myFile = SD.open("data.txt", FILE_WRITE);
    digitalWrite(GREEN_LED, 1);
    delay(20);
    digitalWrite(GREEN_LED, 0);
    Serial.print("Writing to data.txt...");
    myFile.println(Data);
    myFile.close();
    Serial.println("done.");

  }
  Serial.println("-------------------------------");
}
