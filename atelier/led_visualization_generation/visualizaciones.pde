void visualizacion(int n) {
  if (n == 0) {
    fill(100, 0, 0);
    rect(mouseX, mouseY, 20, 80);
  }
  if (n == 1) {
    int t = frameCount;
    colorMode(HSB);
    for (int i = 0; i < 9; i++) {
      fill((i*10+t)%255, 255, 255);
      rect((i*200 + t)%width, 0, 10, height);
    }
  }
  if (n == 2) {
    rect(0, 150, 100,100);
  }
}
