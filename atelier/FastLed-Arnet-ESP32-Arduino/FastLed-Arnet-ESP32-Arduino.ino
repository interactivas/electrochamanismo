////////////////
//
// Basado en:
// https://learn.sparkfun.com/tutorials/using-artnet-dmx-and-the-esp32-to-drive-pixels/creating-an-artnet-node-on-the-esp32
//
///////////////


#include <ArtnetWifi.h>
#include <FastLED.h>


//Wifi settings
#include "arduino_secrets.h"

// You need to create the file arduino_secrets.h with the wifi credentials
//
//#define ssid      "WiFi"
//#define password  "Password"



// LED Strip
const int numLeds = 300; // Change if your setup has more or less LED's
const int numberOfChannels = numLeds * 3; // Total number of DMX channels you want to receive (1 led = 3 channels)
#define DATA_PIN 6 //The data pin that the WS2812 strips are connected to.
CRGB leds[numLeds];

// Artnet settings
ArtnetWifi artnet;
const int startUniverse = 0;

bool sendFrame = 1;
int previousDataLength = 0;

// connect to wifi – returns true if successful or false if not
boolean ConnectWifi(void)
{
  boolean state = true;
  int i = 0;

  WiFi.begin(ssid, password);
  Serial.println("");
  Serial.println("Connecting to WiFi");

  // Wait for connection
  Serial.print("Connecting");
  while (WiFi.status() != WL_CONNECTED) {
    delay(500);
    Serial.print(".");
    if (i > 20) {
      state = false;
      break;
    }
    i++;
  }
  if (state) {
    Serial.println("");
    Serial.print("Connected to ");
    Serial.println(ssid);
    Serial.print("IP address: ");
    Serial.println(WiFi.localIP());
    showConnection(state);
    initTest();
  } else {
    Serial.println("");
    Serial.println("Connection failed.");
    showConnection(state);
  }

  return state;
}

void onDmxFrame(uint16_t universe, uint16_t length, uint8_t sequence, uint8_t* data)
{
  sendFrame = 1;
  // set brightness of the whole strip
  if (universe == 15)
  {
    FastLED.setBrightness(data[0]);
  }
  // read universe and put into the right part of the display buffer
  for (int i = 0; i < length / 3; i++)
  {
    int led = i + (universe - startUniverse) * (length / 3);
    if (led < numLeds)
    {
      leds[led] = CRGB(data[i * 3], data[i * 3 + 1], data[i * 3 + 2]);
    }
  }
  previousDataLength = length;
  FastLED.show();
}

void initTest()
{
  int stopLed = 10;
  for (int i = 0 ; i < stopLed ; i+=5)
    leds[i] = CRGB(0, 0, 10);
  FastLED.show();
  delay(2000);
  for (int i = 0 ; i < stopLed ; i+=5)
    leds[i] = CRGB(0, 10, 0);
  FastLED.show();
  delay(2000);
  for (int i = 0 ; i < stopLed ; i+=5)
    leds[i] = CRGB(10, 0, 0);
  FastLED.show();
  delay(2000);
  for (int i = 0 ; i < stopLed ; i+=5)
    leds[i] = CRGB(0, 0, 0);
  FastLED.show();
}

void showConnection(boolean connection) {  
  for (int i = 0 ; i < 5 ; i++)
    leds[i] = connection ? CRGB::Blue : CRGB:: Red;
  FastLED.show();

  delay(5000);
  FastLED.clear();
}

void setup()
{
  Serial.begin(115200);

  FastLED.addLeds<WS2812, DATA_PIN, GRB>(leds, numLeds);

  ConnectWifi();
  artnet.begin();


  // onDmxFrame will execute every time a packet is received by the ESP32
  artnet.setArtDmxCallback(onDmxFrame);
}

void loop()
{
  // we call the read function inside the loop
  artnet.read();
}
