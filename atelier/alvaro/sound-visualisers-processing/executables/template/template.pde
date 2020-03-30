//import java.util.Map;
import java.util.List;

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////


interface SoundVisualiser {
  void update(Float time);
  void render(Float time);
}

interface LinearWave {
  // Calculates the color values for time and 1-D space coordinates)
  color plot(Float time, Float x);
}

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////
class SquareWave implements LinearWave {
  
  //
  // The total length is 1.0 * N
  //
  int resolution;    // Number of items (leds, pixels, along the linear dim)
  Float freq;        // Number of pulses per second
  Float lambda;      // Number of pixels/leds/elements of a wavelength
  Float dutyCycle;   // proportion in high state (0,1)
  
  SquareWave(
    int resolution,
    Float freq,
    Float lambda,
    Float dutyCycle
  ) {
    this.resolution= resolution;
    this.freq = freq;
    this.lambda = lambda;
    this.dutyCycle = dutyCycle;
  }

  color plot(Float time, Float x) {
    color result;
    
    Float xMod = abs( (x - lambda*freq * time) % resolution );
    Float mod = ( xMod % lambda) / lambda;
    // TODO: use blend() instead of alpha
    if (mod > (1-dutyCycle) ) {
      int c = int( 255 / dutyCycle * (-mod + 1) );
      result = color(c, c, c, 255);
    } else {
      result = color(0, 0, 0, 128); 
    }
    return result;
  }
}


class LinearSoundVisualiser implements SoundVisualiser {
  
  Float tempo = 120.0;
  int resolution = 512; 
  
  List<SquareWave> waves = new ArrayList();
  
  LinearSoundVisualiser(
    int resolution
   ) { 
    this.resolution = resolution;
    SquareWave w0 = new SquareWave(resolution, -1.0, resolution / 1.0, 0.4 );
    SquareWave w1 = new SquareWave(resolution, 2.0, resolution / 3.0, 0.4 );
    waves.add(w0);
    waves.add(w1);
  }
  
  void update(Float time) {
  }
  
  void render(Float time) {
    
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
  noStroke();
  
  visualiser = new LinearSoundVisualiser(width);
  
 
  println();
  
}

void draw() {
  
  visualiser.render(millis()/1000.0);
  
  
}
