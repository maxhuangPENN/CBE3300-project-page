import processing.serial.*;
import java.util.ArrayList;
import java.io.PrintWriter;

// Serial connection
Serial myPort;

// Data storage
ArrayList<Float> pvData = new ArrayList<Float>(); // Dynamic list for PV values
ArrayList<Float> svData = new ArrayList<Float>(); // Dynamic list for SV values
ArrayList<Float> pvStoredValues = new ArrayList<Float>(); // Store all PV values for CSV
ArrayList<Float> svStoredValues = new ArrayList<Float>(); // Store all SV values for CSV
ArrayList<Float> timeData = new ArrayList<Float>(); // Store all time values for CSV

// Time variables
int interval = 5; // Interval for data collection (seconds)
int counter = 0; // Counter for tracking the time

// Fixed y-axis range
float minValue = -10;
float maxValue = 50;

void setup() {
  size(600, 400);

  // Setup serial communication
  println(Serial.list()); // List all available ports
  String portName = Serial.list()[0]; // Choose the correct port from the list (adjust index as needed)
  myPort = new Serial(this, portName, 9600);
  myPort.clear(); // Clear the serial buffer at startup
  myPort.bufferUntil('\n'); // Read until newline
  
  // Initialize plot background
  background(255);
  println("Serial port connected: " + portName);
}

void draw() {
  // Only call drawPlot() after requesting and processing new data
  if (frameCount % (60 * interval) == 0) {
    requestDataFromController();
    drawPlot();
    delay(1000); // 3-second delay after plotting
  }
}

// Function to request and process data from the temperature controller
void requestDataFromController() {
  // Send the command to request Process Value (PV) and Set Value (SV)
  myPort.write(":010347000002B3\r\n"); // Same command as in the Python script
  delay(500); // Wait 1 second after sending the command

  // Wait for the response (read from the serial port)
  String response = myPort.readStringUntil('\n');
  delay(1000); // Wait an additional 1 second after receiving the response

  // Check if response is valid and process it
  if (response != null) {
    response = trim(response);
    println("Received data: " + response); // Print the raw data to verify it's being received

    try {
      // Parse the response and extract PV and SV
      //String pvHex = response.substring(0,3);
      String pvHex = response;
      
      //println(pvHex); // List all available ports
      //String svHex = response.substring(11, 15);
      // Convert from decimal to float values
      float pvValue = Float.parseFloat(pvHex);  // Parse as a decimal float
      // Convert from hexadecimal to integer and then to Centigrade
      //float pvValue = hexToCentigrade(pvHex);
      //float svValue = hexToCentigrade(svHex);
      float svValue = 4;

      // Add the process value (PV) and set value (SV) to their respective buffers
      addData(pvValue, svValue);
      
      // Save the current time
      timeData.add((float) (counter * interval)); // Time in seconds
      counter++;

      // Store values for saving later
      pvStoredValues.add(pvValue);
      svStoredValues.add(svValue);
    } catch (Exception e) {
      println("Error parsing data: " + e); // Print error for debugging
    }
  }
}

// Convert hexadecimal string to Centigrade (temperature)
float hexToCentigrade(String hexString) {
  int value = int(unhex(hexString));
  return value / 10.0;
}

// Add new data points for Process Value (PV) and Set Value (SV)
void addData(float pv, float sv) {
  pvData.add(pv);
  svData.add(sv);
  
  // Maintain a rolling window of the last 100 points for smoother plotting
  if (pvData.size() > 100) {
    pvData.remove(0); // Remove the oldest data point
    svData.remove(0); // Keep both arrays synchronized
  }

  //println("Added to plot - PV: " + pv + ", SV: " + sv); // Debugging print
}

// Draw the plot with a fixed y-axis and dynamic x-axis
void drawPlot() {
  // Clear background right before drawing the new set of data
  background(255);

  // Plot PV
  stroke(0);
  noFill();
  beginShape();
  for (int i = 0; i < pvData.size(); i++) {
    float x = map(i, 0, pvData.size() - 1, 0, width); // Dynamic x-axis based on data size
    float yPv = map(pvData.get(i), minValue, maxValue, height, 0); // Map PV to y-axis
    vertex(x, yPv);
  }
  endShape();

  // Plot SV in red
  stroke(255, 0, 0);
  beginShape();
  for (int i = 0; i < svData.size(); i++) {
    float x = map(i, 0, svData.size() - 1, 0, width);
    float ySv = map(svData.get(i), minValue, maxValue, height, 0);
    vertex(x, ySv);
  }
  endShape();

  // Add legend
  fill(0); // Set color to match PV trace
  text("PV (Process Value)", 20, 20); // Position of PV legend
  fill(255, 0, 0); // Set color to match SV trace
  text("SV (Set Value)", 20, 40); // Position of SV legend

  //println("Plotting range: minValue = " + minValue + ", maxValue = " + maxValue);
}


// Save data to a CSV file when the program is closed
void exit() {
  saveData();
  super.exit(); // Call the parent class exit method to close the sketch
}

// Save the collected data (time, PV, SV) to a CSV file
void saveData() {
  String timestamp = year() + nf(month(), 2) + nf(day(), 2) + "-" + nf(hour(), 2) + nf(minute(), 2) + nf(second(), 2);
  String fileName = sketchPath("data-" + timestamp + ".csv");

  PrintWriter output = createWriter(fileName);
  
  // Write CSV headers
  output.println("Time (s), Process Variable (PV), Set Variable (SV)");

  // Write data
  for (int i = 0; i < pvStoredValues.size(); i++) {
    output.println(timeData.get(i) + "," + pvStoredValues.get(i) + "," + svStoredValues.get(i));
  }

  output.flush();
  output.close();

  println("Data saved to " + fileName);
}
