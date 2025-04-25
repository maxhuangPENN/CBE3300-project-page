int pwmPin = 3; // Digital output pin connected to BJT base (via resistor)
int analogPin = A0; // Analog input pin

int timer = 0;


// Set your desired PWM parameters
float dutyCycle = 1;      
float targetFlowrate = 100;  // Set your target flowrate in cc/min
int pwmPeriodMs = 10;        // Total PWM period in milliseconds (e.g., 10ms = 100Hz)

// Define a boolean called 'feedback' and a target voltage
boolean feedback = false;  // Set to true to enable the feedback block

//set charge time
float chargeTimeDays = 40;
float m_ampsDelivered = 2000 / (chargeTimeDays*24) //assuming 2 amp hours needed finds the current output necessary
float targetCellVoltageOpen = 3.7 +  m_ampsDelivered / 13.8 ;  //Converts that current into voltage based on callibration data



void setup() {
  
  
  Serial.begin(9600);
  // Calculate duty cycle
  dutyCycle = targetFlowrate / 254.8;
  if (dutyCycle > 1.0) dutyCycle = 1.0; // Limit to 100%
  pinMode(pwmPin, OUTPUT);
  pinMode(analogPin, INPUT);
}

void loop() {
  int onTime = pwmPeriodMs * dutyCycle;
  int offTime = pwmPeriodMs - onTime;


  // Read the voltage on A0
  int sensorValue = analogRead(analogPin);
  // Convert to voltage (assuming a 5V reference) Resistor divider cuts cell output in four
  float voltage = 4 * sensorValue * (5.0 / 1023.0);

  Serial.println(voltage);


  digitalWrite(pwmPin, HIGH); // Turn BJT ON
  delay(onTime);

  digitalWrite(pwmPin, LOW);  // Turn BJT OFF
  delay(offTime);

  if (feedback) {
    if (timer % 1000 == 0) {
      // Conditional logic to adjust dutyCycle based on voltage reading
      if (voltage > targetCellVoltage + 0.1) {
        // If the voltage is greater than target by 0.1, decrease dutyCycle by 0.01
        dutyCycle -= 0.01;
      } else if (voltage < targetCellVoltage - 0.1) {
        // If the voltage is less than target by 0.1, increase dutyCycle by 0.01
        dutyCycle += 0.01;
      }
    }   
  }
  
  timer += pwmPeriodMs;

}
