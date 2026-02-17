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
    Serial.println(F("// RTC Module not working !"));
    while (1)
      ;
  }

  // 1. Capture the "New Time" (Compilation time)
  DateTime pcTime = DateTime(__DATE__, __TIME__);

  // 2. Capture the "Current RTC Time" (Before sync)
  DateTime rtcTime = rtc.now();

  // 3. Calculate Drift
  // unixtime() gives total seconds since Jan 1st 1970
  long driftSeconds = pcTime.unixtime() - rtcTime.unixtime();

  Serial.println(F("--- RTC SYNC REPORT ---"));
  Serial.print(F("RTC Time: "));
  Serial.println(rtcTime.timestamp());
  Serial.print(F("PC Time:  "));
  Serial.println(pcTime.timestamp());

  Serial.print(F("Drift detected: "));
  Serial.print(driftSeconds);
  Serial.println(F(" seconds"));

  if (abs(driftSeconds) > 2) {
    Serial.println(F("// Drift > 2s: Injecting PC time..."));
    rtc.adjust(pcTime);
    digitalWrite(GREEN_LED, 1);
    delay(1000);
    digitalWrite(GREEN_LED, 0);
  } else {
    Serial.println(F("// Time is already accurate. No sync needed."));
  }
  Serial.println(F("-----------------------"));
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