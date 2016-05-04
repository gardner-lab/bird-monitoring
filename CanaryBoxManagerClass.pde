// Array that holds all of the bird boxes
class birdBoxManager {
  // Box managing variables
  birdBox[] boxArray; // Array containing each box
  int numBoxes; // Number of bird boxes that are being managed

  // Arduino variables
  Serial port; // Port to connect to the arduino over
  String portName; // Name of port to connect to Arduino with
  int baudRate; // Baudrate for connection with Arduino
  int fetchTime = 2000; // Number of milliseconds to wait before getting new data 
  int lastFetch = -2*fetchTime; // The time at which the last data was fetched (Initialized to have first fetch occur immediately)
  int serialStatus = DISCONNECTED; // If the program is currently in communication with the Arduino
  boolean receivedGoodData = false; // Has Processing received any good data yet? (Used to treat bug where Arduino sends only 0's for values at first)

  // Drawing variables
  int warningBoxHeight = 20; // Height of warning box along bottom for serial connection
  int warningBoxWidth = 200; // Width of warning box along bottom for serial connection
  int warningBoxX; // X position of the warning box
  int warningBoxY; // Y position of the warning box
  int heightEdgeBuffer = 5;// Buffer along top and bottom edge
  int heightBuffer = 5; // Buffer between box displays
  int widthBuffer = 10; // Buffer between sides
  int boxBufferedHeight; // Height of each box including buffer
  int boxHeight; // Height of each box without buffer
  int boxWidth; // Width of each box
  int boxX; // Each box's X position
  PApplet sketchPApplet; // This sketch's PApplet

  birdBoxManager(String portNameIn, int baudRateIn, int arrayXIn, int arrayYIn, int arrayWidthIn, int arrayHeightIn, PApplet sketchPAppletIn) {
    // Note: ArrayXIn and arrayYIn define center of entire array
    // Record the sketch PApplet
    sketchPApplet = sketchPAppletIn;

    // Start communication with Arduino
    portName = portNameIn;
    baudRate = baudRateIn;

    // Start by openning a port
    openNewPort();
    arduinoConnect();

    // Create box array
    boxArray = new birdBox[numBoxes];

    // Assign a position, height, and width to each box
    boxBufferedHeight = (arrayHeightIn - heightEdgeBuffer*2 - warningBoxHeight)/numBoxes; // Height of each box including buffer
    boxHeight = boxBufferedHeight - 2*heightBuffer; // Height of each box without buffer
    boxWidth = arrayWidthIn - 2*widthBuffer; // Width of each box
    boxX = arrayXIn; // Each box's X position

    // Calculate the space on the GUI allocated to each box, and create it
    for (int i = 0; i<numBoxes; i++) {
      int top = arrayYIn  - arrayHeightIn/2 + heightEdgeBuffer;
      int boxY = top + (boxBufferedHeight/2)*(2*i + 1); // Each box's Y position
      boxArray[i] = new birdBox(boxX, boxY, boxWidth, boxHeight, this);
    }

    // Calculate space on GUI for warning box
    int right = arrayXIn + arrayWidthIn/2 - widthBuffer;
    warningBoxX = right - warningBoxWidth/2;
    int bottom = arrayYIn + arrayHeightIn/2 - heightEdgeBuffer;
    warningBoxY = bottom - warningBoxHeight/2;

    // Get first measurement from arduino
    getNewData();
  }

  void draw() {
    for (int i = 0; i < boxArray.length; i++) {
      boxArray[i].draw();
    }

    // Draw the warning box
    drawWarningBox();
  }

  void openNewPort() {
    // Create and open a serial port
    try {
      port = new Serial(sketchPApplet, portName, baudRate);
    } 
    catch (Exception e) {
      port = new  Serial(sketchPApplet, Serial.list()[0], baudRate);
    }
  }

  void reopenPort() {
    // Attempt to reopen a port

    // Stop communication with this port
    port.stop();

    // Reopen a new port
    openNewPort();

    // Test the port (expect a handshake reply that contains the number of boxes)
    if (arduinoSendSignal("H")) {
      // Test the input number of boxes
      readNumberOfBoxes();
    }
  }

  void readNumberOfBoxes() {
    // Read the number of boxes from the port
    int numBoxesIn = port.read();
    if (numBoxesIn != numBoxes) {
      serialStatus = NUMBOXMISMATCH;
    }
  }

  void drawWarningBox() {
    rectMode(CENTER);
    fill(getSerialStatusColor());
    noStroke();
    rect(warningBoxX, warningBoxY, warningBoxWidth, warningBoxHeight);
    // ADD TEXT TO THE BOX TO MAKE THE SERIAL STATUS CLEAR IT CLEAR
  }

  color getSerialStatusColor() {
    color c;
    if (serialStatus == CONNECTED) {
      c = GREEN;
    } else if (serialStatus == NUMBOXMISMATCH) {
      c = YELLOW;
    } else {
      c = RED;
    } 
    return c;
  }

  void arduinoConnect() {
    // Connect to the arduino for the first time, get number of boxes
    // Write H (handshake) to the serial port
    boolean connected  = arduinoSendSignal("H");
    println(connected);
    if (connected) {
      numBoxes = port.read();
      println("Number of boxes from Arduino = " + numBoxes);
    } else {
      numBoxes = 3;
    }
  }

  void setFetchTime(int fetchTimeIn) {
    fetchTime = fetchTimeIn;
  }

  void getNewData() {
    // Check how long has passed since the last time data was fetched
    int curTime = millis();
    if ((curTime - lastFetch) > fetchTime) {
      boolean viableData = false; // Boolean to decide whether or not to send this new data to the Arduino

      // Write "N" (new data) to the serial port
      boolean arduinoResponded = arduinoSendSignal("N"); // Did the Arduino respond with data?
      if (arduinoResponded) {
        //// Read new data
        readNumberOfBoxes();
        //println("Number of boxes: " + numBoxesIn);

        // Check that the number of boxes is the same (could be indicative of a problem otherwise)
        if (serialStatus != NUMBOXMISMATCH) {
          // The call to readNumberOfBoxes() above set the serialStatus variable, so read that variable to see if the data is viable
          viableData = true;
        }
      }

      if (viableData) {
        // Read the data from the Serial buffer into a byte stream
        int numTotalBytes = numBoxes*bytesPerFloat*numTrackedParameters + 1; // 4 bytes per tracked parameter per box, plus a line-feed
        byte[] newData = new byte[numTotalBytes];
        port.readBytesUntil(LF, newData);
        //println(newData);

        // Check that there is no strange values on the connection (existing bug: Arduino will send all 0's for values (normal numBoxes, but values will be wrong), but then will correct itself)
        if (!receivedGoodData) {
          for (int i = 0; i < numTotalBytes; i++) {
            if (newData[i] != 0) {
              // Has finally received good data from the Arduino
              // Start actual data logging, and break out of this loop
              receivedGoodData = true;
              break;
            }
          }
        }

        if (!receivedGoodData) {
          // If no good data has been received, then the current data is not viable, and should not be sent
          viableData = false; 
          println("Received all zero's from Arduino: Ignoring");
        }

        // If this data is still viable (passed "Good data" test, above), send it to the boxes
        if (viableData) {
          // Separate input into byte-streams for each box
          // Update each box with new data
          //println("New Data:");
          for (int i = 0; i < numBoxes; i++) {
            // Convert this box's byte data into values
            float[] boxData = new float[numTrackedParameters];
            for (int j = 0; j < numTrackedParameters; j++) {
              byte[] byteData = new byte[bytesPerFloat];
              System.arraycopy(newData, bytesPerFloat*(i*numTrackedParameters + j), byteData, 0, bytesPerFloat);
              // Go through each parameter in this box's byte array, and convert the sets of 4 into a single float
              boxData[j] = ByteBuffer.wrap(byteData).order(ByteOrder.LITTLE_ENDIAN).getFloat();
            }
            boxArray[i].setNewData(boxData, curTime);
            //println(boxData);
            //println();
          }
          //println();
        }

        // Set the last fetch time
        lastFetch = millis();
      }

      // If current data ended up not being viable, send error data to boxes
      if (!viableData) {
        println("Data error at time " + (float)curTime/1000 + " seconds");
        // Set new data to be -1's
        for (int i = 0; i < numBoxes; i++) {
          float[] errorData = {-1, -1, -1}; 
          boxArray[i].setNewData(errorData, curTime);
        }
      }

      if (!arduinoResponded) {
        println("Arduino not found: attempting to reconnect");
        reopenPort();
        if (serialStatus == CONNECTED) {
          // If Arduino has reconnected, then reattempt to get this data
          println("Arduino reconnected, fetching new data");
          getNewData();
        }
      }
    }
  }

  void setName(int boxInd, String birdName) {
    boxArray[boxInd].setName(birdName);
  }

  void setStatus(int boxInd, int status) {
    boxArray[boxInd].setStatus(status);
  }

  void setDoorClosed(int boxInd, boolean doorClosed) {
    boxArray[boxInd].setDoorClosed(doorClosed);
  }

  boolean arduinoSendSignal(String call) {
    // Output is whether or not a response was received
    // Call the arduino (send the "call" string) and wait for a response (will call the arduino multiple times, every waitTime milliseconds
    int waitTime = 200; // Number of milliseconds between each call
    int maxCalls = 2; // Maxiumum number of times to call the arduino before giving up

    // First, clear the serial buffer
    port.clear();

    // Then, call the Arduino
    int numTries = 0; // The number of times the program has tried to call the arduino
    boolean response = false;
    while (!response & numTries < maxCalls) {

      port.write(call); 

      // Continue checking for a response
      boolean timeOut = false; // Has a timeout occurred while waiting for the Arduino?
      int timeStart = millis(); // Time that the waiting period started
      while (port.available() == 0) {
        // Wait for the arduino to send something (the number of boxes, specifically)
        if ((millis() - timeStart) > waitTime) {
          // If the wait time has expired, send another
          timeOut = true;
          numTries = numTries + 1;
          break;
        }
      }
      if (!timeOut) {
        // If the the last loop ended because new data was found (not because of a time-out), read the new data
        response = true;
      }
    }

    // Update the serialStatus variable
    if (response) {
      serialStatus = CONNECTED;
      // Set message on the Serial warning box
    } else {
      serialStatus = DISCONNECTED;
      // Set message on the Serial warning box
    }

    return response;
  }
};