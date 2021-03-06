//import java.util.Map;
import java.util.List;
import oscP5.*;

////////////////////////////////////////////////////////////////////////////////
// INTERFACES
////////////////////////////////////////////////////////////////////////////////

interface SoundVisualiser {
  void update(float time);
  void render(float time);
}

interface LinearWave {
  // Calculates the color values for time and 1-D space coordinates)
  color plot(float time, float x);
}

interface Observer {
  void update(Message msg);
}

////////////////////////////////////////////////////////////////////////////////
// Observer and messages
////////////////////////////////////////////////////////////////////////////////

class Message {
   
  String address;
  Object arguments;
  
  Message(String address, Object arguments) {
    this.address = address;
    this.arguments = arguments;
  }
}

class Observable {
  
  List<Observer> observers = new ArrayList();
  
  Observable() {
  }
  
  void subscribe(Observer observer) {
    observers.add(observer);
    println("New subscriber ", observers);
  }
  void unsubscribe(Observer observer) {
    observers.remove(observer);
    println("Deleted subscriber ", observers);
  }
  
  void emit(Message msg) {
    println("Emitting message to subscribers. ", msg, observers);
    for (Observer o : observers) {
      o.update(msg);
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
// Visualiser
////////////////////////////////////////////////////////////////////////////////
class SquareWave implements LinearWave {
  
  //
  // The total length is 1.0 * N
  //
  int resolution;    // Number of items (leds, pixels, along the linear dim)
  float freq;        // Number of pulses per second
  float lambda;      // Number of pixels/leds/elements of a wavelength
  float dutyCycle;   // proportion in high state (0,1)
  float hue;         // valued between (0.0,360.0)
  float saturation;  // valued between (0.0, 100.0)
  float timeGamma;   // time distortion to get "jumpy" beats 

  
  SquareWave(
    int resolution,
    float freq,
    float lambda,
    float dutyCycle,
    float hue,
    float saturation,
    float timeGamma
  ) {
    this.resolution= resolution;
    this.freq = freq;
    this.lambda = lambda;
    this.dutyCycle = dutyCycle;
    this.hue = hue;
    this.saturation = saturation;
    this.timeGamma = timeGamma;
  }

  color plot(float time, float x) {
    color result;
    
    float partOfOneCycle = pow( (freq * time) % 1, timeGamma);
    float xMod = abs( x - lambda * partOfOneCycle ) % resolution;
    //float xMod = abs( (x - lambda*freq * time) % resolution );
    // TODO: does this make sense?
    float modBeforeGamma = ( xMod % lambda) / lambda;
    float mod = pow(modBeforeGamma, timeGamma);
    if (mod > (1-dutyCycle) ) {
      float b = 100.0 / dutyCycle * (-mod + 1);
      result = color(hue, saturation, b, 100.0);
    } else {
      result = color(0, 0, 0, 100.0); 
    }
    return result;
  }
}


class LinearSoundVisualiser implements SoundVisualiser {
  
  float tempo = 120.0;
  int resolution = 512; 
  
  List<SquareWave> waves = new ArrayList();
  
  LinearSoundVisualiser(
    int resolution
   ) { 
    this.resolution = resolution;
    SquareWave w0 = new SquareWave(resolution + 1, -1.0, resolution / 5.0, 0.4, 0.0, 0.0, 5.0 );
    SquareWave w1 = new SquareWave(resolution, 1.0, resolution / 2, 0.4, 30.0, 100.0, 5.0 );
    SquareWave w2 = new SquareWave(resolution, -1/4.0, resolution * 4, 0.8, 50.0, 80.0, 1.0 );
    waves.add(w0);
    waves.add(w1);
    waves.add(w2);
  }
  
  void update(float time) {
  }
  
  void render(float time) {
    
    for (LinearWave w : waves) {

       for (int i =0; i < resolution; i++) {
           color c = w.plot(time, float(i));
           stroke(c);
           line(i, 0, i, height);       
       } 
    }
  }
}

////////////////////////////////////////////////////////////////////////////////
// OSC listener
////////////////////////////////////////////////////////////////////////////////

class OSCListener extends Observable {

  OSCListener() {
    super();
  }

  void oscEvent(OscMessage msg) {
    
    Message m = new Message(
      msg.addrPattern(),
      msg.arguments()
    );
    
    this.emit(m);
    /*
    if (msg.checkAddrPattern("/volume-in") == true ) {
      Float value= msg.get(0).floatValue();
      println("--");
      println(value);
      println(msg.arguments());
      println(msg.arguments().length);
    }
    */
  }
}

////////////////////////////////////////////////////////////////////////////////
// OSC normaliser
////////////////////////////////////////////////////////////////////////////////

class OSCNormaliser extends Observable implements Observer {

  OSCNormaliser() {
  }
  
  void update(Message m){
    println("Normaliser getting message: ", m.address);
  }
  
}


////////////////////////////////////////////////////////////////////////////////
// References
////////////////////////////////////////////////////////////////////////////////

LinearSoundVisualiser visualiser;
SquareWave wave;
OscP5 oscP5;
OSCListener listener;
OSCNormaliser normaliser;

////////////////////////////////////////////////////////////////////////////////
// CONFIGURATION
////////////////////////////////////////////////////////////////////////////////
int OSC_PORT = 7777;

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

void setup() {
  
  println("setup");
  //noLoop();
  frameRate(25);

  
  size(1024, 10);
  background(0);
  blendMode(LIGHTEST);
  colorMode(HSB, 360.0, 100.0, 100.0, 100.0);
  noStroke();
  
  visualiser = new LinearSoundVisualiser(width);
  listener = new OSCListener();
  // Temporary. This is to be managed by the visualiser?
  normaliser = new OSCNormaliser();
  listener.subscribe(normaliser);
  
  oscP5 = new OscP5(listener , OSC_PORT );
  
 
  println();
  
}

void draw() {
  
  background(0);
  visualiser.render(millis()/1000.0);
  
  
}
