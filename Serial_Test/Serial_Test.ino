// To-Do:
#define aRefVoltage 3.41 // Reference voltage tied to 3.3V, multimeter found exact voltage (may want to check again)
#define TEMPCCAL 2.5 // The calibration temperature in celcius (compared to the DM6802B Digital Thermometer, measured at digitial thermometer = 22˚C)
// Parameters
int numBoxes = 3;
static int bytesPerFloat = 4;
static int analogTrackedParameters = 2; // Number of analog parameters tracked per box
static int digitalTrackedParameters = 1; // Number of digital parameters tracked per box
static int LF = 10; // Line-feed in ASCII

void setup() {

  // Serial
  Serial.begin(57600);

  // Set reference voltage
  analogReference(EXTERNAL);

  // Set digital pins
  int startDigiPin = 2; // The pin number to start on
  for (int i = startDigiPin; i < (2 + numBoxes); i++) {
    pinMode(i, INPUT);
  }

  // Setup the number of tracked parameters
  trackedParameters = analogTrackedParameters + digitalTrackedParameters;  // Number of parameters that are being sent per box
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
    //    if (i != 0) {
    //      // Acquire data from the analog sensors
    //      float inputTempVoltage = 71;
    //      float inputHumidityVoltage = 60;
    //      float inputDoorVoltage = 1;
    //
    //      // Convert the input from voltage
    //      temp.floatVal = tempConvert(inputTempVoltage);
    //      humidity.floatVal = humidityConvert(inputHumidityVoltage);
    //      door.floatVal = doorConvert(inputDoorVoltage);
    //
    //      temp.floatVal = (inputTempVoltage);
    //      humidity.floatVal = (inputHumidityVoltage);
    //      door.floatVal = (inputDoorVoltage);
    //
    //      temp.floatVal += random(0, variance * 10) / 10 - variance / 2;
    //      humidity.floatVal += random(0, variance * 10) / 10 - variance / 2;
    //      Serial.write(temp.byteVal, bytesPerFloat);
    //      Serial.write(humidity.byteVal, bytesPerFloat);
    //      Serial.write(door.byteVal, bytesPerFloat);
    //    } else {
    float tempC = getTempCVal(i);
    temp.floatVal = getTempFVal(tempC);
    humidity.floatVal = getHumidityVal(i, tempC);
    door.floatVal = getDoorVal(i);

    Serial.write(temp.byteVal, bytesPerFloat);
    Serial.write(humidity.byteVal, bytesPerFloat);
    Serial.write(door.byteVal, bytesPerFloat);
    //    }
  }

  // Finally, send a line-feed, to signal the end of the transmission
  Serial.write(LF);
}

float getTempCVal(int boxNum) {
  float raw = analogRead(analogTrackedParameters * boxNum);
  float rawVolts = raw * (aRefVoltage / 1023.0);
  float tempC = (rawVolts - .5) * 100 + TEMPCCAL;
  return tempC;
}

float getTempFVal(int tempC) {
  float tempF = tempC * (9.0 / 5.0) + 32.0;
  return tempF;
}

float getHumidityVal(int boxNum, float tempC) {
  float raw = analogRead(analogTrackedParameters * boxNum + 1);
  float rawVolts = raw * (aRefVoltage / 1023.0);
  float sensorRH = ((rawVolts / aRefVoltage) - .1515) / .00636;
  float trueRH = sensorRH / (1.0546 - .00216 * tempC);
  return trueRH;
}

float getDoorVal(int boxNum) {
  float doorClosed;
  int val = digitalRead(digitalTrackedParameters*boxNum + 2);
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

