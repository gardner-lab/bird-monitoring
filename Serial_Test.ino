// Parameters
int numBoxes = 1;
static int bytesPerFloat = 4;
static int LF = 10; // Line-feed in ASCII

void setup() {

  // Serial
  Serial.begin(57600);

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
      //sendHandshake();
      break;
    case 78:
      // Received N (new data)
      //sendNewData();
      break;
  }
  sendHandshake();
}

void sendHandshake() {
  Serial.write(numBoxes);
}

void sendNewData() {
  int variance = 20; // Amount of variance to have in signals
  // Declare variables to transmit
  byteFloat temp;
  byteFloat humidity;
  byteFloat door;

  // Acquire data from the analog sensors
  float inputTempVoltage = 64;
  float inputHumidityVoltage = 24;
  float inputDoorVoltage = 1;

  // Convert the input from voltage
  temp.floatVal = tempConvert(inputTempVoltage);
  humidity.floatVal = humidityConvert(inputHumidityVoltage);
  door.floatVal = doorConvert(inputDoorVoltage);

  temp.floatVal = (inputTempVoltage);
  humidity.floatVal = (inputHumidityVoltage);
  door.floatVal = (inputDoorVoltage);

  // Send acquired data to Processing
  // First, send the number of boxes, so Processing knows what to expect
  Serial.write(numBoxes);

  // Then, for each box, send the necesary information
  for (int i = 0; i < numBoxes; i++) {
    temp.floatVal += random(0, variance * 10) / 10;
    humidity.floatVal += random(0, variance * 10) / 10;
    Serial.write(temp.byteVal, bytesPerFloat);
    Serial.write(humidity.byteVal, bytesPerFloat);
    Serial.write(door.byteVal, bytesPerFloat);
  }

  // Finally, send a line-feed, to signal the end of the transmission
  Serial.write(LF);
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

