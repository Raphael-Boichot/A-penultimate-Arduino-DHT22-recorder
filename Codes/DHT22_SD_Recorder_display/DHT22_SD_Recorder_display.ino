/*
  Code adapted initially from here by Raphaël BOICHOT, january 2023, use at your own risk
  https://microcontrollerslab.com/dht22-data-logger-arduino-micro-sd-card/
  to be used with the following libraries:
  https://github.com/adafruit/DHT-sensor-library
  https://github.com/adafruit/RTClib
	https://github.com/olikraus/u8g2
  128x64 pixels OLED daisy chained to the RTC module
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
#include <RTClib.h>
#include <U8x8lib.h> // Added for OLED

// OLED Initialization
U8X8_SSD1306_128X64_NONAME_HW_I2C u8x8(/* reset=*/ U8X8_PIN_NONE);

RTC_DS3231 rtc;
#define DHTPIN 2
#define DHTTYPE DHT22
DHT dht(DHTPIN, DHTTYPE);
File myFile;

int RED_LED = 5;
int GREEN_LED = 4;
int CHIP_SELECT = 10;
unsigned long delay_s = 60;
unsigned long preceding_time, preceding_timeLED, preceding_timeDisplay;
int def_LED;
String Temperature, Humidity, Data;
bool sd_ok = false;
bool rtc_ok = false;

void setup() {
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  Serial.begin(115200);
  while (!Serial);

  // ORIGINAL SERIAL MESSAGES
  Serial.println(F("// By Raphaël BOICHOT, March 2024"));
  Serial.println(F("// This program comes with ABSOLUTELY NO WARRANTY;"));
  Serial.println(F("// This is free software, and you are welcome to redistribute it"));
  
  // OLED Setup
  u8x8.begin();
  u8x8.setPowerSave(0);
  u8x8.setFont(u8x8_font_7x14B_1x2_f); // Set to Big Bold Font
  
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
  sd_ok = SD.begin(CHIP_SELECT);
  if (!sd_ok) {
    Serial.println(F("// SD initialization failed !"));
    def_LED = RED_LED;
  } else {
    Serial.println(F("// SD initialization OK !"));
    Data = F("The device has restarted following a power cut");
    myFile = SD.open("data.txt", FILE_WRITE);
    Serial.println(F("// Writing power down marker to data.txt..."));
    myFile.println(Data);
    myFile.close();
  }

  Serial.println(F("// Initializing RTC module..."));
  rtc_ok = rtc.begin();
  if (!rtc_ok) {
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
  preceding_timeDisplay = millis();
}

void loop() {
  // INDICATE DEVICE IS RUNNING & UPDATE OLED
  if ((millis() - preceding_timeLED) >= (1000)) {
    preceding_timeLED = millis();
    digitalWrite(def_LED, 1);
    delay(10);
    digitalWrite(def_LED, 0);
    updateOLED(); // Refresh the screen every second
  }

  if ((millis() - preceding_time) >= (delay_s * 1000)) {
    preceding_time = millis();
    if (isnan(dht.readTemperature()) || isnan(dht.readHumidity())) {
      Serial.println(F("// DHT22 Sensor not working !"));
      def_LED = RED_LED;
    } else {
      data_logging();
    }
  }
}

void updateOLED() {
  DateTime now = rtc.now();
  u8x8.setFont(u8x8_font_7x14B_1x2_f);

  // Line 1: Date (DD/MM/YYYY)
  u8x8.setCursor(0, 0);
  if(now.day() < 10) u8x8.print('0'); u8x8.print(now.day()); u8x8.print('/');
  if(now.month() < 10) u8x8.print('0'); u8x8.print(now.month()); u8x8.print('/');
  u8x8.print(now.year());

  // Line 2: Time
  u8x8.setCursor(0, 2);
  if(now.hour() < 10) u8x8.print('0'); u8x8.print(now.hour()); u8x8.print(':');
  if(now.minute() < 10) u8x8.print('0'); u8x8.print(now.minute()); u8x8.print(':');
  if(now.second() < 10) u8x8.print('0'); u8x8.print(now.second());

  // Line 3: RTC & SD Status (BIG FONT)
  u8x8.setCursor(0, 4);
  u8x8.print(sd_ok ? F("SD:OK ") : F("SD:!! "));
  u8x8.print(rtc_ok ? F("RTC:OK") : F("RTC:!!"));

  // Line 4: Live Sensors
  u8x8.setCursor(0, 6);
  u8x8.print(dht.readTemperature(), 1); u8x8.print(F("C "));
  u8x8.print(dht.readHumidity(), 0); u8x8.print(F("%"));
}

void data_logging() {
  // ORIGINAL STRING LOGIC UNCHANGED
  String Temperature = String(dht.readTemperature(), 2);
  String Humidity = String(dht.readHumidity(), 2);
  
  rtc_ok = rtc.begin();
  if (!rtc_ok) {
    Serial.println(F("// RTC module not responding !"));
    def_LED = RED_LED;
  }
  
  DateTime date = rtc.now();
  char formattedDate[20];
  sprintf(formattedDate, "%04d-%02d-%02d %02d:%02d:%02d", date.year(), date.month(), date.day(), date.hour(), date.minute(), date.second());
  
  Data = "Temperature: " + Temperature + " Humidity: " + Humidity + " Date/Time: ";
  Data = Data + formattedDate;

  Serial.println(Data);
  
  sd_ok = SD.begin(CHIP_SELECT);
  if (!sd_ok) {
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