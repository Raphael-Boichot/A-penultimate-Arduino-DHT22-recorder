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
    Serial.println("// RTC Module not working !");
    while (1)
      ;
  }
  Serial.println("// Injecting Time/Date from PC to the working module");
  rtc.adjust(DateTime(__DATE__, __TIME__));
  digitalWrite(GREEN_LED, 1);
}

void loop() {
  DateTime date = rtc.now();
  // this part was made with ChatGPT
  char formattedDate[20];  // Table to store the formatted date
  // Date format YYYY-MM-DD HH:MM:SS
  sprintf(formattedDate, "Date/Time: %04d-%02d-%02d %02d:%02d:%02d", date.year(), date.month(), date.day(), date.hour(), date.minute(), date.second());
  // end of part made with ChatGPT
  Serial.println(formattedDate);
  delay(1000);
}