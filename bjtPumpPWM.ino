int pwmPin = 3; // Digital output pin connected to BJT base (via resistor)


// Set your desired PWM parameters
float dutyCycle = 1;      
float targetFlowrate = 100;  // Set your target flowrate in cc/min
int pwmPeriodMs = 10;        // Total PWM period in milliseconds (e.g., 10ms = 100Hz)

void setup() {
  // Calculate duty cycle
  dutyCycle = targetFlowrate / 142.0;
  if (dutyCycle > 1.0) dutyCycle = 1.0; // Limit to 100%
  pinMode(pwmPin, OUTPUT);
}

void loop() {
  int onTime = pwmPeriodMs * dutyCycle;
  int offTime = pwmPeriodMs - onTime;

  digitalWrite(pwmPin, HIGH); // Turn BJT ON
  delay(onTime);

  digitalWrite(pwmPin, LOW);  // Turn BJT OFF
  delay(offTime);
}
