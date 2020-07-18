//
// Receiving OSC
//
// https://discourse.processing.org/t/receive-osc-by-processing-a-little-bit-help-is-needed/6512/3
// http://www.sojamo.de/libraries/oscP5/reference/index.html
// http://www.sojamo.de/libraries/oscP5/
//
import oscP5.*;

import oscP5.*;
import netP5.*;

OscP5 oscP5;

void setup() {
  frameRate(25);
  //oscP5 = new OscP5(this,7777);
  oscP5 = new OscP5(
    new OSCListener(),
    7777
  );
}
    
void draw() {
  background(0);  
}
    
void oscEvent(OscMessage theOscMessage) {
  if(theOscMessage.checkAddrPattern("/mfcc-in") == true) {
    Float OSCvalue = theOscMessage.get(0).floatValue();
    println(" values: "+OSCvalue);
    return;
  }
}

//
// OSC listener
//
class OSCListener {
 
  OSCListener() {
  }
  
  void oscEvent(OscMessage msg) {
    if (msg.checkAddrPattern("/volume-in") == true ) {
      Float value= msg.get(0).floatValue();
      println("--");
      println(value);
      println(msg.arguments());
      println(msg.arguments().length);
    }
  }
  
}
