// To-Do:
#define aRefVoltage 3.41 // Reference voltage tied to 3.3V, multimeter found exact voltage (may want to check again)

// Parameters
int numBoxes = 3;
static int bytesPerFloat = 4;
static int trackedParameters = 3; // Number of parameters that are being sent per box
static int LF = 10; // Line-feed in ASCII

void setup() {

  // Serial
  Serial.begin(57600);

  // Set reference voltage
  analogReference(EXTERNAL);

  // Set digital pins
  pinMode(2,INPUT);
}

void loop() {
  // Wait for serialEvent() to occur
}

typedef union {
  float floatVal;
  byte byteVal[4];
} byteFloat;

void serialEvent() {
  int newByte = Serial.read();
  //Serial.write(newByte);
  switch (newByte) {
    case 72:
      // Received H (handshake)
      sendHandshake();
      break;
    case 78:
      // Received N (new data)
      sendNewData();
      break;
  }
}

void sendHandshake() {
  Serial.write(numBoxes);
}

void sendNewData() {
  int variance = 15; // Amount of variance to have in signals
  // Declare variables to transmit
  byteFloat temp;
  byteFloat humidity;
  byteFloat door;

  // Send acquired data to Processing
  // First, send the number of boxes, so Processing knows what to expect
  Serial.write(numBoxes);

  // Second, then the number of tracked parameters that will be expected for each box
  Serial.write(trackedParameters);

  // Then, for each box, send the necesary information
  for (int i = 0; i < numBoxes; i++) {
    if (i != 0) {
      // Acquire data from the analog sensors
      float inputTempVoltage = 71;
      float inputHumidityVoltage = 60;
      float inputDoorVoltage = 1;

      // Convert the input from voltage
      temp.floatVal = tempConvert(inputTempVoltage);
      humidity.floatVal = humidityConvert(inputHumidityVoltage);
      door.floatVal = doorConvert(inputDoorVoltage);

      temp.floatVal = (inputTempVoltage);
      humidity.floatVal = (inputHumidityVoltage);
      door.floatVal = (inputDoorVoltage);

      temp.floatVal += random(0, variance * 10) / 10 - variance / 2;
      humidity.floatVal += random(0, variance * 10) / 10 - variance / 2;
      Serial.write(temp.byteVal, bytesPerFloat);
      Serial.write(humidity.byteVal, bytesPerFloat);
      Serial.write(door.byteVal, bytesPerFloat);
    } else {
      temp.floatVal = getTempVal(i);
      humidity.floatVal = getHumidityVal(i, temp.floatVal);
      door.floatVal = getDoorVal(i);

      Serial.write(temp.byteVal, bytesPerFloat);
      Serial.write(humidity.byteVal, bytesPerFloat);
      Serial.write(door.byteVal, bytesPerFloat);
    }
  }

  // Finally, send a line-feed, to signal the end of the transmission
  Serial.write(LF);
}

float getTempVal(int boxNum) {
  float raw = analogRead(trackedParameters * boxNum);
  float rawVolts = raw * (aRefVoltage / 1023.0);
  float tempC = (rawVolts - .5) * 100;
  float tempF = tempC * (9 / 5) + 32;
  return tempF;
}

float getHumidityVal(int boxNum, float temp) {
  float raw = analogRead(trackedParameters * boxNum + 1);
  float rawVolts = raw * (aRefVoltage / 1023.0);
  float sensorRH = ((rawVolts / aRefVoltage) - .1515) / .00636;
  float trueRH = sensorRH / (1.0546 - .00216 * temp);
  return trueRH;
}

float getDoorVal(int boxNum) {
  float doorClosed;
  int val = digitalRead(2);
  if (val == HIGH) {
    doorClosed = 1;
  } else {
    doorClosed = 0;
  }
  return doorClosed;
}

float tempConvert(float inputVoltage) {
  float outputTemp;

  // Perform the conversion from voltage to temperature
  outputTemp = inputVoltage;

  return outputTemp;
}

float humidityConvert(float inputVoltage) {
  float outputHumidity;

  // Perform the conversion from voltage to humidity
  outputHumidity = inputVoltage;

  return outputHumidity;
}

float doorConvert(float inputVoltage) {
  boolean outputDoorBool;
  boolean outputDoor;

  // Perform the conversion from voltage to humidity
  outputDoorBool = true;

  // Convert boolean to float value
  if (outputDoorBool) {
    outputDoor = 1;
  } else {
    outputDoor = 0;
  }

  return outputDoor;
}

