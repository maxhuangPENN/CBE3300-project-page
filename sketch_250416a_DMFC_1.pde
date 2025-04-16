import processing.serial.*;
import java.io.PrintWriter;

Serial myPort;

ArrayList<Float> voltageData = new ArrayList<Float>();
ArrayList<String> timeData = new ArrayList<String>();
boolean isRunning = true;

int maxPoints = 300;
float minV = 0;
float maxV = 6;

PrintWriter output;
Button toggleButton;

void setup() {
  size(800, 500);
  println(Serial.list());
  String portName = Serial.list()[13]; // Change this if needed
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n');

  String timestamp = year() + nf(month(), 2) + nf(day(), 2) + "_" + nf(hour(), 2) + nf(minute(), 2);
  output = createWriter("voltage_log_" + timestamp + ".csv");
  output.println("Time (s),Voltage (V)");

  toggleButton = new Button("Pause", width - 120, 20, 80, 30);
}

void draw() {
  background(255);
  drawAxes();
  drawPlot();
  drawLabels();
  toggleButton.display();
}

void serialEvent(Serial p) {
  if (!isRunning) return;

  String input = p.readStringUntil('\n');
  if (input != null) {
    input = trim(input);
    try {
      float voltage = float(input);
      voltageData.add(voltage);
      timeData.add(str(millis() / 1000.0));

      if (voltageData.size() > maxPoints) {
        voltageData.remove(0);
        timeData.remove(0);
      }

      // Save to CSV
      output.println(timeData.get(timeData.size() - 1) + "," + voltage);

    } catch (Exception e) {
      println("Parse error: " + input);
    }
  }
}

void drawAxes() {
  stroke(0);
  line(60, 40, 60, height - 40); // Y-axis
  line(60, height - 40, width - 40, height - 40); // X-axis
}

void drawPlot() {
  noFill();
  stroke(50, 100, 255);
  beginShape();
  for (int i = 0; i < voltageData.size(); i++) {
    float x = map(i, 0, maxPoints, 60, width - 40);
    float y = map(voltageData.get(i), minV, maxV, height - 40, 40);
    vertex(x, y);
  }
  endShape();
}

void drawLabels() {
  fill(0);
  textSize(14);
  text("Live Voltage (V)", 20, 20);
  textAlign(CENTER);
  text("Time (rolling)", width / 2, height - 10);

  // Y-axis ticks
  for (float v = minV; v <= maxV; v += 1) {
    float y = map(v, minV, maxV, height - 40, 40);
    textAlign(RIGHT);
    text(nf(v, 1, 1), 55, y + 5);
    stroke(220);
    line(60, y, width - 40, y);
  }
}

// Save CSV on exit
void exit() {
  output.flush();
  output.close();
  println("CSV saved.");
  super.exit();
}

// Handle mouse for toggling
void mousePressed() {
  if (toggleButton.isClicked(mouseX, mouseY)) {
    isRunning = !isRunning;
    toggleButton.label = isRunning ? "Pause" : "Start";
  }
}

// Simple button class
class Button {
  String label;
  int x, y, w, h;

  Button(String label, int x, int y, int w, int h) {
    this.label = label;
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  void display() {
    fill(240);
    stroke(0);
    rect(x, y, w, h, 5);
    fill(0);
    textAlign(CENTER, CENTER);
    text(label, x + w / 2, y + h / 2);
  }

  boolean isClicked(int mx, int my) {
    return mx > x && mx < x + w && my > y && my < y + h;
  }
}
