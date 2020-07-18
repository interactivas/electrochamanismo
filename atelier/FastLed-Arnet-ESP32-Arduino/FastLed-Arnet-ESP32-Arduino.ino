////////////////
//
// Basado en:
// https://learn.sparkfun.com/tutorials/using-artnet-dmx-and-the-esp32-to-drive-pixels/creating-an-artnet-node-on-the-esp32
//
///////////////
//
// TODO:
//     - The led strip or the builtin led show when the conection was lost
//     - Reboot the nodemcu when the conection was lost
//     - Improve the init testing, try to show all the leds working dynamically
//
//
//
/////////

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

// Built-in led blink variables 
unsigned long previous_millis = 0;
const long blink_interval = 1000;
const int ledPin = 2;
boolean ledState = false;

// ------------------- Wifi Managmanet ---------------------
// wifi scanNetworks, wifi connection

int wifi_managment() {
  // scan for nearby networks:
  Serial.println("** Scan Networks **");
  byte numSsid = WiFi.scanNetworks();

  // print the list of networks seen:
  Serial.print("SSID List:");
  Serial.println(numSsid);
  // print the network number and name for each network found:
  //for (int thisNet = 0; thisNet < numSsid; thisNet++) {
  //  Serial.print(thisNet);
  //  Serial.print(") Network: ");
  //  Serial.println(WiFi.SSID(thisNet));
  //}

  int network_id = -1;
  for (int i = 0; i < networks_num; i++) {
    for (int thisNet = 0; thisNet < numSsid; thisNet++) {
      if (networks_ssid[i] == WiFi.SSID(thisNet)) {
        Serial.print("Network found ");
        Serial.println(WiFi.SSID(thisNet));
        network_id = i;
        break;
      }
    }
  }

  if (network_id >= 0) {
    ConnectWifi(network_id);
  } else {
    while (1) {
      showConnection(0);
      delay(5000);
    }
  }

}


//------------------------ Connect Wifi --------------
// connect to wifi – returns true if successful or false if not

boolean ConnectWifi(int id)
{
  boolean state = true;
  int i = 0;

  WiFi.begin(networks_ssid[id], networks_pass[id]);
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
    Serial.println(networks_ssid[id]);
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

// ---------------- on DMX Frame ---------------
// send the recibe DMX to the leds

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

// ---------------- init Test ---------------//
// testing the strip leds

void initTest()
{
  int stopLed = 10;
  for (int i = 0 ; i < stopLed ; i += 5)
    leds[i] = CRGB(0, 0, 10);
  FastLED.show();
  delay(2000);
  for (int i = 0 ; i < stopLed ; i += 5)
    leds[i] = CRGB(0, 10, 0);
  FastLED.show();
  delay(2000);
  for (int i = 0 ; i < stopLed ; i += 5)
    leds[i] = CRGB(10, 0, 0);
  FastLED.show();
  delay(2000);
  for (int i = 0 ; i < stopLed ; i += 5)
    leds[i] = CRGB(0, 0, 0);
  FastLED.show();
}

// -----------  Show Connection ---------
// show that we are connected to the net in the strip led, Blue = conected, Red = not conected

void showConnection(boolean connection) {
  for (int i = 0 ; i < 5 ; i++)
    leds[i] = connection ? CRGB::Blue : CRGB:: Red;
  FastLED.show();

  delay(5000);
  FastLED.clear();
}

// ----------- Builtin Led Blink ------------
// control the built led

void builtin_led_blink () {

  unsigned long current_millis = millis();

  if (current_millis - previous_millis >= blink_interval) {
    previous_millis = current_millis;
    
    if (ledState == LOW) {
      ledState = HIGH;
      analogWrite(ledPin, 1012);
    } else {
      ledState = LOW;
      analogWrite(ledPin, 1024);
    }

    //digitalWrite(ledPin, ledState);
    
  }
}



// ----------------   Setup --------------------

void setup()
{
  pinMode(ledPin, OUTPUT);

  Serial.begin(115200);

  Serial.print("LED_BUILTIN = ");
  Serial.println(LED_BUILTIN, DEC);

  FastLED.addLeds<WS2812, DATA_PIN, GRB>(leds, numLeds);

  wifi_managment();
  artnet.begin();


  // onDmxFrame will execute every time a packet is received by the ESP32
  artnet.setArtDmxCallback(onDmxFrame);
}


// ----------------- Loop ----------------

void loop()
{
  // we call the read function inside the loop

  artnet.read();
  builtin_led_blink();

}
