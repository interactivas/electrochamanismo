import ch.bildspur.artnet.*;

ArtNetClient artnet;
byte[] dmxData = new byte[512];



void clearLeds(int numLeds, String arduinoIP) {
  
   // fill dmx array
  for (int i = 0; i < numLeds; i++) {
    dmxData[i*3 + 0] = (byte) 0;
    dmxData[i*3 + 1] = (byte) 0;
    dmxData[i*3 + 2] = (byte) 0;
  }
  // send dmx to localhost
  artnet.unicastDmx(arduinoIP, 0, 0, dmxData);
  
}


void setupDMX(int numLeds, String arduinoIP)
{

  artnet = new ArtNetClient(null);
  artnet.start(); 
  clearLeds(numLeds, arduinoIP);
  
}

void sendDMX(int numLeds, String arduinoIP)
{
  loadPixels();
  int positionY = height/2;
  int pixelSeparation = width / numLeds;
  
  for (int i = 0; i < numLeds; i++) {
    int pixelPosition = width*height/2 + i*pixelSeparation;
    dmxData[i*3 + 0] = (byte) red(pixels[pixelPosition]);
    dmxData[i*3 + 1] = (byte) green(pixels[pixelPosition]);
    dmxData[i*3 + 2] = (byte) blue(pixels[pixelPosition]);
  }

  artnet.unicastDmx(arduinoIP, 0, 0, dmxData);

}

void exit(){
  
  clearLeds(numLeds, arduinoIP);
  super.exit();
}
