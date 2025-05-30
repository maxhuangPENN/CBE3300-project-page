
import processing.serial.*;
import java.io.PrintWriter;

Serial myPort;
ArrayList<Float> voltageData = new ArrayList<Float>();
ArrayList<String> timeData = new ArrayList<String>();

PrintWriter output;
boolean isRunning = true;
int maxPoints = 300;
float minV = 0;
float maxV = 6;

float batteryCapacity_mAh = 20000;
float batteryVoltage = 3.7; // typical Li-ion voltage
float efficiency = 0.3f; // estimated system efficiency

Button toggleButton;
TextField inputField;
Button sendButton;

void setup() {
  size(900, 600);
  println(Serial.list());
  String portName = Serial.list()[0];
  myPort = new Serial(this, portName, 9600);
  myPort.bufferUntil('\n');

  String timestamp = year() + nf(month(), 2) + nf(day(), 2) + "_" + nf(hour(), 2) + nf(minute(), 2);
  output = createWriter("voltage_log_" + timestamp + ".csv");
  output.println("Time (s),Voltage (V)");

  toggleButton = new Button("Pause", width - 120, 20, 80, 30);
  sendButton = new Button("Set Time (days)", 400, 550, 140, 30);
  inputField = new TextField(250, 550, 130, 30);
}

void draw() {
  background(255);
  drawAxes();
  drawPlot();
  drawLabels();
  toggleButton.display();
  sendButton.display();
  inputField.display();
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

      output.println(timeData.get(timeData.size() - 1) + "," + voltage);
    } catch (Exception e) {
      println("Parse error: " + input);
    }
  }
}

void drawAxes() {
  stroke(0);
  line(60, 40, 60, height - 80);
  line(60, height - 80, width - 40, height - 80);
}

void drawPlot() {
  noFill();
  stroke(50, 100, 255);
  beginShape();
  for (int i = 0; i < voltageData.size(); i++) {
    float x = map(i, 0, maxPoints, 60, width - 40);
    float y = map(voltageData.get(i), minV, maxV, height - 80, 40);
    vertex(x, y);
  }
  endShape();
}

void drawLabels() {
  fill(0);
  textSize(14);
  text("Live Voltage (V)", 20, 20);
  textAlign(CENTER);
  text("Time (rolling)", width / 2, height - 40);

  for (float v = minV; v <= maxV; v += 1) {
    float y = map(v, minV, maxV, height - 80, 40);
    textAlign(RIGHT);
    text(nf(v, 1, 1), 55, y + 5);
    stroke(230);
    line(60, y, width - 40, y);
  }
}

void mousePressed() {
  if (toggleButton.isClicked(mouseX, mouseY)) {
    isRunning = !isRunning;
    toggleButton.label = isRunning ? "Pause" : "Start";
  }

  if (sendButton.isClicked(mouseX, mouseY)) {
    try {
      float days = float(inputField.text);
      //float energyNeeded_Wh = batteryCapacity_mAh * batteryVoltage / 1000.0;
      //float powerNeeded_W = energyNeeded_Wh / (days * 24.0);
      //float adjustedPower_W = powerNeeded_W / efficiency;

      // Example linear calibration relationship:
      //float flowrate_mLps = adjustedPower_W / 22.0; // assume 22 W/L/s
      //float voltageToPump = (flowrate_mLps + 0.7036) / 0.2758; // inverted linear fit from image
      float Rthev = 72.5;
      float capacity = 10;
      float time = days * 24;
      float K = 4.5 / 8.62;
      float voltageToPump = (5.4 + Rthev * capacity / time) / K;
      float dutyCycle = constrain(voltageToPump / 18.0, 0.0, 1.0);

      myPort.write("SET:" + dutyCycle + "\n");
      println("Charge Time (days): " + days);
     // println("Target Power: " + powerNeeded_W + " W");
      //println("Flowrate: " + flowrate_mLps + " mL/s");
      println("Voltage to Pump: " + voltageToPump + " V");
      println("Duty Cycle Sent: " + dutyCycle);

    } catch (Exception e) {
      println("Invalid input.");
    }
  }
}

void exit() {
  output.flush();
  output.close();
  super.exit();
}

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

class TextField {
  int x, y, w, h;
  String text = "";

  TextField(int x, int y, int w, int h) {
    this.x = x;
    this.y = y;
    this.w = w;
    this.h = h;
  }

  void display() {
    fill(255);
    stroke(0);
    rect(x, y, w, h);
    fill(0);
    textAlign(LEFT, CENTER);
    text(text, x + 5, y + h / 2);
  }

  void keyPressed() {
    if (key == BACKSPACE && text.length() > 0) {
      text = text.substring(0, text.length() - 1);
    } else if (key >= 32 && key <= 126) {
      text += key;
    }
  }
}

void keyPressed() {
  inputField.keyPressed();
}
