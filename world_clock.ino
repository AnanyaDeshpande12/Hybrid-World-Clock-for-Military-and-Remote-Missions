/*
ESP8266 NTP + DS3231 RTC + Timezone Switch
Push button cycles through 20 time zones
DST supported via POSIX TZ strings
*/

#include <Wire.h>
#include <LiquidCrystal_I2C.h>
#include <RTClib.h>
#include <time.h>
#include <ESP8266WiFi.h>

LiquidCrystal_I2C LCD(0x27, 16, 2);
RTC_DS3231 rtc;

#define NTP_SERVER "pool.ntp.org"

#define WIFI_SSID "A54"
#define WIFI_PASS "ananyad2005"

#define BUTTON_PIN 12

int lastButtonState = HIGH;

const char* places[] = {
  "UTC","LON","PAR","KOL","KTM",
  "TYO","SYD","NYC","CHI","DEN",
  "LAX","SAO","JNB","MSC","DXB",
  "SHA","AKL","SGP","ANC","HNL"
};

const char* tzSpecs[] = {
  "UTC0",
  "GMT0BST",
  "CET-1",
  "IST-5:30",
  "NPT-5:45",
  "JST-9",
  "AEST-10",
  "EST5EDT",
  "CST6CDT",
  "MST7MDT",
  "PST8PDT",
  "BRT3",
  "SAST-2",
  "MSK-3",
  "GST-4",
  "CST-8",
  "NZST-13",
  "SGT-8",
  "AKST9AKDT",
  "HST10"
};

const int NUM_ZONES = 20;
int timezoneIndex = 0;

char timeBuf[16];
char dateBuf[16];

bool rtcPresent = false;

void applyTZ(int idx)
{
    if(idx < 0 || idx >= NUM_ZONES) return;

    setenv("TZ", tzSpecs[idx], 1);
    tzset();
}

void setSystemTimeFromRTC()
{
    if(!rtcPresent) return;

    DateTime dt = rtc.now();
    time_t t = (time_t)dt.unixtime();

    if(t < 100000) return;

    struct timeval tv;
    tv.tv_sec = t;
    tv.tv_usec = 0;

    settimeofday(&tv, nullptr);
}

void writeRTCfromSystemTime()
{
    if(!rtcPresent) return;

    time_t now = time(nullptr);

    if(now < 100000) return;

    rtc.adjust(DateTime((uint32_t)now));
}

bool tryNtpSync(uint32_t timeoutMs = 5000)
{
    configTime(0, 0, NTP_SERVER);

    uint32_t start = millis();

    struct tm ti;

    while(millis() - start < timeoutMs)
    {
        if(getLocalTime(&ti, 2000))
            return true;

        delay(200);
    }

    return false;
}

void printTimeToLCD()
{
    struct tm ti;

    if(!getLocalTime(&ti, 2000))
    {
        LCD.setCursor(0,0);
        LCD.print("Time Err");
        return;
    }

    strftime(timeBuf, sizeof(timeBuf), "%H:%M:%S", &ti);
    strftime(dateBuf, sizeof(dateBuf), "%d/%m/%Y", &ti);

    LCD.setCursor(0,0);
    LCD.print(places[timezoneIndex]);
    LCD.print(" ");
    LCD.print(timeBuf);

    int used1 =
        strlen(places[timezoneIndex]) +
        1 +
        strlen(timeBuf);

    for(int i = used1; i < 16; i++)
        LCD.print(' ');

    LCD.setCursor(0,1);
    LCD.print(dateBuf);

    int used2 = strlen(dateBuf);

    for(int i = used2; i < 16; i++)
        LCD.print(' ');
}

void checkButton()
{
    int reading = digitalRead(BUTTON_PIN);

    if(reading == LOW && lastButtonState == HIGH)
    {
        timezoneIndex++;

        if(timezoneIndex >= NUM_ZONES)
            timezoneIndex = 0;

        applyTZ(timezoneIndex);
    }

    lastButtonState = reading;
}

void setup()
{
    Serial.begin(115200);

    delay(100);

    Wire.begin();

    LCD.init();
    LCD.backlight();

    pinMode(BUTTON_PIN, INPUT_PULLUP);

    LCD.clear();
    LCD.print("Starting...");

    rtcPresent = rtc.begin();

    WiFi.begin(WIFI_SSID, WIFI_PASS);

    uint32_t wifiStart = millis();

    while(WiFi.status() != WL_CONNECTED &&
          millis() - wifiStart < 10000)
    {
        delay(200);
    }

    if(WiFi.status() == WL_CONNECTED)
    {
        if(tryNtpSync(8000))
        {
            if(rtcPresent)
                writeRTCfromSystemTime();
        }
        else
        {
            if(rtcPresent)
                setSystemTimeFromRTC();
        }
    }
    else
    {
        if(rtcPresent)
            setSystemTimeFromRTC();
    }

    applyTZ(timezoneIndex);

    LCD.clear();
}

void loop()
{
    checkButton();

    printTimeToLCD();

    delay(500);
}