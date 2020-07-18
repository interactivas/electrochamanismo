//import java.util.Map;
import java.util.List;

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////


interface SoundVisualiser {
  void update(float time);
  void render(float time);
}

interface LinearWave {
  // Calculates the color values for time and 1-D space coordinates)
  color plot(float time, float x);
}

////////////////////////////////////////////////////////////////////////////////
//
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
//
////////////////////////////////////////////////////////////////////////////////

LinearSoundVisualiser visualiser;
SquareWave wave;



////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////

void setup() {
  
  println("setup");
  //noLoop();
  
  size(1024, 10);
  background(0);
  blendMode(LIGHTEST);
  colorMode(HSB, 360.0, 100.0, 100.0, 100.0);
  noStroke();
  
  visualiser = new LinearSoundVisualiser(width);
  
 
  println();
  
}

void draw() {
  
  background(0);
  visualiser.render(millis()/1000.0);
  
  
}
