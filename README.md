---
title: "Project: Direct Methanol Fuel Cell (DMFC)"
toc: true
toc-depth: 2
numbersections: true
colorlinks: true
abstract-title: Summary
abstract: |
  This project explores the design and prototyping of a Direct Methanol Fuel Cell (DMFC) system using a 10-cell Flex-Stak from the Fuel Cell Store. 
  The cell operates on 3% methanol (~1M), and is designed to output sufficient voltage and current to charge a 20,000 mAh battery pack within 24 hours.
  
  Builders will gain experience with electrochemistry, fuel cell operation, real-time electronics integration with Arduino, and chemical process control. 
  Further extensions include MEA fabrication and advanced catalyst implementation.

  Approximate time: 20–30 person-hours.
---

# DMFC Project – Methanol Dynamics
University of Pennsylvania – CBE 3300B

---

## Project Description

This project explores the design and prototyping of a Direct Methanol Fuel Cell (DMFC) using a 10-cell Flex-Stak. It integrates passive and active fuel delivery, peristaltic pumping, and Arduino-based control logic to modulate methanol flow and monitor system voltage in real time.

Our goal is to develop a system that can charge a 20,000 mAh power bank in less than 24 hours while remaining safe, modular, and efficient. Future goals include fabricating our own MEA and testing alternate catalyst configurations.

---

## Background

![DMFC stack and tubing setup](img/fuelcell.jpg)

A DMFC converts chemical energy directly into electrical energy via redox reactions. Methanol is oxidized at the anode, producing CO₂, protons, and electrons. The electrons generate current through an external circuit, while protons migrate across a PEM to recombine with oxygen at the cathode, forming water.

**Anode reaction**:  
$$\ce{CH3OH + H2O -> CO2 + 6H+ + 6e-}$$

**Cathode reaction**:  
$$\ce{3/2 O2 + 6H+ + 6e- -> 3H2O}$$

**Overall reaction**:  
$$\ce{CH3OH + 3/2 O2 -> CO2 + 2H2O}$$

The theoretical cell voltage is ~1.20 V per cell, but practical values range between 0.3–0.6 V due to internal losses and crossover.

---

## Project Goals

- Develop a minimum viable DMFC prototype
- Integrate peristaltic pump control via PWM (Arduino)
- Monitor live voltage and adjust flow dynamically
- Run extended tests to estimate methanol consumption and power output
- Optimize stack layout and fuel delivery (horizontal vs vertical, vapor vs liquid)
- Charge a 20,000 mAh power bank in < 24 hours

---

## Equipment & Materials

### Hardware

- 10-cell Flex-Stak DMFC (Fuel Cell Store)
- Arduino Uno
- Diode-protected transistor circuit (2N2222 BJT)
- Peristaltic pump
- 3% methanol solution (~1M)
- Tubing, check valves
- USB data logging via Processing

### Software

- Arduino IDE for control logic and PWM duty modulation
- Processing for real-time plotting and CSV saving of voltage
- Python (optional) for data post-processing

---

## Build Instructions

1. **Assemble fuel cell stack** and torque bolts to 8–10 in-lbs
2. **Hydrate membrane** with distilled water before first use
3. Prepare **3% MeOH in water solution (~1M)** and prime pump lines
4. Upload [Arduino script](#arduino-code) and connect PWM to base of 2N2222 transistor
5. Open [Processing visualization](#processing-code) to log voltage and plot in real time
6. Begin testing and incrementally increase duty cycle or MeOH concentration if needed

---

## Arduino Code

```cpp
int pwmPin = 3; // Digital output pin connected to BJT base
int analogPin = A0; // Reads voltage (resistor divider used)

float dutyCycle = 1;      
float targetFlowrate = 100;
int pwmPeriodMs = 10;

boolean feedback = false;
float targetCellVoltage = 4;
int timer = 0;

void setup() {
  Serial.begin(9600);
  dutyCycle = targetFlowrate / 142.0;
  if (dutyCycle > 1.0) dutyCycle = 1.0;
  pinMode(pwmPin, OUTPUT);
  pinMode(analogPin, INPUT);
}

void loop() {
  int onTime = pwmPeriodMs * dutyCycle;
  int offTime = pwmPeriodMs - onTime;

  int sensorValue = analogRead(analogPin);
  float voltage = 4 * sensorValue * (5.0 / 1023.0);
  Serial.println(voltage);

  digitalWrite(pwmPin, HIGH);
  delay(onTime);
  digitalWrite(pwmPin, LOW);
  delay(offTime);

  if (feedback && timer % 1000 == 0) {
    if (voltage > targetCellVoltage + 0.1) dutyCycle -= 0.01;
    else if (voltage < targetCellVoltage - 0.1) dutyCycle += 0.01;
  }
  timer += pwmPeriodMs;
}
