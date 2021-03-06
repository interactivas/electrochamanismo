
int numLeds = 100;
String arduinoIP = "192.168.1.22";

float[] vector = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0};

void setup () {
  size(600, 600);
  setupDMX(numLeds, arduinoIP);
  oscP5setup();
}

void draw () {
  background(0);
  
  //sendDMX(numLeds, arduinoIP);
  noStroke();
  fill(0,100,0); 
  for (int i = 0; i < vector.length; i++) {
    //println(vector[i]);
    float f = (float) vector[i];
    rect(i*20+20, height/2 + 50, 20, -f*100);
  }
  
  fill(100, 0, 0);
  rect(mouseX, mouseY, 20, 80);
  
  sendDMX(numLeds, arduinoIP);
  
  stroke(255);
  line(0,height/2,width,height/2);
  
}
