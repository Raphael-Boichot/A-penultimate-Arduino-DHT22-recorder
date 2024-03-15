#include <Wire.h>
#include <RTClib.h>  //https://github.com/adafruit/RTClib

RTC_DS3231 rtc;
int RED_LED = 5;
int GREEN_LED = 4;

void setup() {
  Serial.begin(115200);
  pinMode(RED_LED, OUTPUT);
  pinMode(GREEN_LED, OUTPUT);
  if (!rtc.begin()) {
    digitalWrite(RED_LED, 1);
    Serial.println("Module RTC non retrouvé !");
    while (1)
      ;
  }
  rtc.adjust(DateTime(__DATE__, __TIME__));
  digitalWrite(GREEN_LED, 1);
}

void loop() {
  DateTime date = rtc.now();
  Serial.print(date.day());
  Serial.print("/");
  Serial.print(date.month());
  Serial.print("/");
  Serial.print(date.year());
  Serial.print(" ");
  Serial.print(date.hour());
  Serial.print(":");
  Serial.print(date.minute());
  Serial.print(":");
  Serial.println(date.second());
  delay(1000);
}