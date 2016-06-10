// Array that holds all of the bird boxes
class birdBoxManager {
  // Box managing variables
  birdBox[] boxArray; // Array containing each box
  int numBoxes; // Number of bird boxes that are being managed
  int numParams = numTrackedParameters; // Number of parameters per box that are being tracked
  fileManager fManager; // The file manager used by this program.  It will be used by the birdBoxes to keep track of writing files

  // Arduino variables
  Serial port; // Port to connect to the arduino over
  String portName; // Name of port to connect to Arduino with
  int baudRate; // Baudrate for connection with Arduino
  int fetchTime = 2000; // Number of milliseconds to wait before getting new data 
  long lastFetch = -2*fetchTime; // The time at which the last data was fetched (Initialized to have first fetch occur immediately)
  int serialStatus = DISCONNECTED; // Status of the connection with the Arduino
  boolean receivedGoodData = false; // Has Processing received any good data yet? (Used to treat bug where Arduino sends only 0's for values at first)

  // Parameters needed for the emailing function (for arduino related problems
  String emailAddressesFileName; // Name of the file that has all of the email addresses
  Emailer emailer; // The oject responsible for emailing users if anything goes wrong
  String curWarningMessage = ""; // The current message that the Emailer has
  int lastSerialStatus = clearFlag(); // The status as it was the last time the Emailer was contacted (used to see if the message should be changed)

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

  // ControlP5 object to control any interactivity with the GUI
  ControlP5 cp5;
  ControlFont cFont; // Font to be used on most text in window
  Textlabel warningLabel; // The label to give updates on the state of the serial connection

  birdBoxManager(String portNameIn, int baudRateIn, int fetchTimeIn, PApplet sketchPAppletIn) {
    // Note: managerX and managerY define center of entire array

    // Save all input variables
    portName = portNameIn;
    baudRate = baudRateIn;
    fetchTime = fetchTimeIn;
    sketchPApplet = sketchPAppletIn;

    // Define the dimensions of the manager's display (use the full window)
    int managerX = int(.5*width);
    int managerY = int(.5*height);
    int managerWidth = width;
    int managerHeight = height;

    // Start communication with Arduino
    // Start by opening a port
    openNewPort();

    // Create a file manager for data recording
    fManager = new fileManager();

    // Then, get the number of boxes, and start building the GUI
    arduinoConnect();

    // Create box array
    boxArray = new birdBox[numBoxes];

    // Assign a position, height, and width to each box
    boxBufferedHeight = (managerHeight - heightEdgeBuffer*2 - warningBoxHeight)/numBoxes; // Height of each box including buffer
    boxHeight = boxBufferedHeight - 2*heightBuffer; // Height of each box without buffer
    boxWidth = managerWidth - 2*widthBuffer; // Width of each box
    boxX = managerX; // Each box's X position

    // Calculate the space on the GUI allocated to each box, and create it
    for (int i = 0; i<numBoxes; i++) {
      int top = managerY  - managerHeight/2 + heightEdgeBuffer;
      int boxY = top + (boxBufferedHeight/2)*(2*i + 1); // Each box's Y position
      boxArray[i] = new birdBox(boxX, boxY, boxWidth, boxHeight, this);
    }

    // Calculate space on GUI for warning box
    int right = managerX + managerWidth/2 - widthBuffer;
    warningBoxX = right - warningBoxWidth/2;
    int bottom = managerY + managerHeight/2 - heightEdgeBuffer;
    warningBoxY = bottom - warningBoxHeight/2;
    // Set up text in warning box
    cp5 = new ControlP5(sketchPApplet);
    int fontSize = 18;
    cFont = new ControlFont(createFont("Helvetica", fontSize));
    warningLabel = cp5.addTextlabel("Warning")
      .setValue("")
      .setPosition(right - warningBoxWidth, bottom - warningBoxHeight)
      .setSize(warningBoxWidth, warningBoxHeight)
      .setFont(cFont);

    // Set up the Emailer
    emailAddressesFileName = mainDirectory + "birdBoxEmailAddresses.csv"; 
    float minutesToWaitBeforeEmailing = 0; // The number of minutes to wait before sending an email warning
    emailer = new Emailer(emailAddressesFileName, "", minutesToWaitBeforeEmailing, "Arduino connection"); // The second field is blank so that the Emailer extracts ALL email addresses from the file

    // Get first measurement from arduino
    getNewData();
  }

  boolean birdInAnyBox() {
    // This function queries all of the boxes being managed to determine if there is a bird in any of the boxes
    boolean birdInBoxes = false;
    for (int i = 0; i < numBoxes; i++) {
      if (boxArray[i].birdInBox) {
        birdInBoxes = true;
        break;
      }
    }
    return birdInBoxes;
  }

  void setupEmailIfNeeded() {
    boolean warning = !flagIsClear(serialStatus) && birdInAnyBox(); // If there is a problem, and there is a bird in the box
    if (warning) {
      // If there are some warnings, and there is at least one bird in the boxes, build up a message to send to the Emailer
      if (lastSerialStatus != serialStatus) {
        // If a new warning has occurred, rebuild the message
        // Otherwise, just send the same message as last time (don't change curMessage)

        curWarningMessage = "";
        String nL = "\r\n"; // New line character
        if (testFlag(serialStatus, DISCONNECTED)) {
          curWarningMessage += "Arduino is disconnected" + nL;
        }
        if (testFlag(serialStatus, NUMBOXMISMATCH)) {
          curWarningMessage += "Arduino connection problem (number of boxes mismatch)" + nL;
        }
        if (testFlag(serialStatus, NUMPARAMSMISMATCH)) {
          curWarningMessage += "Arduino connection problem (number of parameters mismatch)" + nL;
        }
      }
      emailDebug("Warning exists, notifying Emailer about: " + curWarningMessage);

      // Keep track of how the status flag changes
      lastSerialStatus = serialStatus;
    }

    // Send the message to the Emailer
    emailer.checkIfEmailIsNeeded(warning, curWarningMessage);
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
      serialDebug("Cannot find " + portName);
      port = new  Serial(sketchPApplet, Serial.list()[0], baudRate);
    }

    serialDebug("Serial information:");
    serialDebug(sketchPApplet.toString());
    serialDebug(portName);
    serialDebug(Integer.toString(baudRate));

    // Wait for Arduino to be ready
    delay(1000);
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

  int readNumberOfBoxes() {
    // Read the number of boxes from the port
    int numBoxesIn = port.read();
    dataDebug("Number of boxes: " + numBoxesIn);
    if (numBoxesIn != numBoxes) {
      serialStatus = setStatus(serialStatus, NUMBOXMISMATCH);
      errorReporting("Number of boxes mismatch");
    } else {
      serialStatus = clearStatus(serialStatus, NUMBOXMISMATCH);
    }
    return numBoxesIn;
  }

  int readNumberOfParameters() {
    // Read the number of boxes from the port
    int numParamsIn = port.read();
    dataDebug("Number of parameters: " + numParamsIn);
    if (numParamsIn != numParams) {
      serialStatus = setStatus(serialStatus, NUMPARAMSMISMATCH);
      errorReporting("Number of parameters mismatch");
    } else {
      serialStatus = clearStatus(serialStatus, NUMBOXMISMATCH);
    }
    return numParamsIn;
  }

  void drawWarningBox() {
    rectMode(CENTER);
    fill(getSerialStatusColor());
    noStroke();
    rect(warningBoxX, warningBoxY, warningBoxWidth, warningBoxHeight);
    warningLabel.setValue(getWarningBoxString());
  }

  String getWarningBoxString() {
    String s;
    if (flagIsClear(serialStatus)) {
      s = "Connected";
    } else if (testFlag(serialStatus, DISCONNECTED)) {
      s = "Disconnected";
    } else {
      s = "Communication error";
    } 
    return s;
  }

  color getSerialStatusColor() {
    color c;
    if (flagIsClear(serialStatus)) {
      c = GREEN;
    } else if (testFlag(serialStatus, DISCONNECTED)) {
      c = RED;
    } else {
      c = YELLOW;
    } 
    return c;
  }

  void arduinoConnect() {
    // Connect to the arduino for the first time, get number of boxes
    // Write H (handshake) to the serial port
    boolean connected  = arduinoSendSignal("H");
    serialDebug("Connected to Arduino: " + connected);
    if (connected) {
      numBoxes = port.read();
      serialDebug("Initial number of boxes from Arduino = " + numBoxes);
    } else {
      numBoxes = 3;
    }
  }

  void getFakeArduinoData() {
    Calendar curTime = Calendar.getInstance();
    float var = 30; // Variance of the random data
    float tempBase = 61;
    float humidityBase = 40;
    if ((curTime.getTimeInMillis() - lastFetch) > fetchTime) {
      // Populate the boxes with fake data
      for (int i = 0; i < numBoxes; i++) {
        // For each box
        float[] parameters = new float[numParams];
        for (int j = 0; j < numParams; j++) {
          // For each parameter
          switch(j) {
          case 0:
            parameters[j] = tempBase + random(0, var) - var/2;
            break;
          case 1:
            parameters[j] = humidityBase + random(0, var) - var/2;
            break;
          case 2:
            parameters[j] = 1;
            break;
          default:
            parameters[j] = 0;
            break;
          }
        }
        dataDebug("New Data:");
        boxArray[i].setNewData(new trackedParametersFloat(parameters, numParams).parameters, curTime);
      }

      // Set the last fetch time
      lastFetch = curTime.getTimeInMillis();
    }
  }


  void getNewData() {
    // Check how long has passed since the last time data was fetched
    //int curTime = millis();
    Calendar curTime = Calendar.getInstance();
    if ((curTime.getTimeInMillis() - lastFetch) > fetchTime) {
      List<trackedParametersFloat> structureList = new LinkedList<trackedParametersFloat>(); // Data which is extracted and sent to the boxes
      boolean viableData = false; // Boolean to decide whether or not to send this new data to the boxes

      // Write "N" (new data) to the serial port, to gather the data
      boolean arduinoResponded = arduinoSendSignal("N"); // Did the Arduino respond with data?
      if (arduinoResponded) {
        viableData = true;
      }

      // Extract the meta-data
      if (viableData) {
        // Check the number of boxes from the Arduino
        readNumberOfBoxes();

        // Check the number of parameters from the Arduino
        readNumberOfParameters();

        // Check that the number of boxes is the same (could be indicative of a problem otherwise)
        if (flagIsClear(serialStatus)) {
          // Read serialStatus to see if the data is viable
          viableData = true;
        } else {
          viableData = false;
        }
      }

      // If the meta-data is correct, then extract the data into a datastructure (structureList)
      if (viableData) {
        // Read the data from the Serial buffer into a byte stream, then convert into floats
        structureList = readByteData(numBoxes, numParams);

        // Check that there is no strange values on the connection (existing bug: Arduino will send all 0's for values (normal numBoxes, but values will be wrong), but then will correct itself)
        viableData = checkForDataBugs(structureList);
      }

      // If this data is still viable, send it to the boxes
      if (viableData) {
        // Update each box with new data
        dataDebug("New Data:");
        for (int i = 0; i < numBoxes; i++) {
          boxArray[i].setNewData(structureList.get(i).parameters, curTime);
        }

        // Set the last fetch time
        lastFetch = curTime.getTimeInMillis();
      }


      // If current data ended up not being viable, send error data to boxes
      if (!viableData) {
        // Report any errors that occured
        errorReporting("Data error at " + sdf.format(curTime.getTime()) + ":");
        if (!receivedGoodData) {
          errorReporting("Due to all 0's");
        }
        if (!arduinoResponded) {
          errorReporting("Due to no Arduino response");
        }
        if (testFlag(serialStatus, NUMBOXMISMATCH)) {
          errorReporting("Due to mismatched number of boxes");
        }
        if (testFlag(serialStatus, NUMPARAMSMISMATCH)) {
          errorReporting("Due to mismatched number of parameters");
        }
        errorReporting("");

        // Send error data to boxes
        for (int i = 0; i < numBoxes; i++) {
          boxArray[i].errorData(numParams, curTime);
        }

        // If the arduino is not responding, attempt to reconnect to it
        if (!arduinoResponded) {
          serialDebug("Arduino not found: attempting to reconnect");
          reopenPort();
          if (flagIsClear(serialStatus)) {
            // If Arduino has reconnected, then reattempt to get this data
            serialDebug("Arduino reconnected, fetching new data");
            getNewData();
          }
        }
      }

      // Update the emailer
      setupEmailIfNeeded();
    }
  }

  boolean checkForDataBugs(List<trackedParametersFloat> inputData) {
    // Check for the "all-zeros" bug in the data
    boolean viableData = true;
    if (!receivedGoodData) {
      for (int i = 0; i < inputData.size(); i++) {
        // For each trackedParametersFloat object in structureList...
        for (int j = 0; j < inputData.get(i).parameters.size(); j++) {
          // For each parameter in the trackedParametersFloat object...
          if (inputData.get(i).parameters.get(j) != 0) {
            // Has finally received good data from the Arduino
            // Start actual data logging, and break out of this loop
            receivedGoodData = true;
            break;
          }
        }
      }
    }

    if (!receivedGoodData) {
      // If no good data has been received, then the current data is not viable, and should not be sent
      viableData = false; 
      dataDebug("Received all zero's from Arduino: Ignoring");
    }

    return viableData;
  }

  List<trackedParametersFloat> readByteData(int numBoxes, int numParameters) {
    // Read all input data from the Arduino
    int numTotalBytes = numBoxes*bytesPerFloat*numParameters + 1; // 4 bytes per tracked parameter per box, plus a line-feed
    byte[] data = new byte[numTotalBytes];
    port.readBytesUntil(LF, data); // Read the data from the Arduino
    rawDataDebug("Raw data:");
    rawDataDebug(Arrays.toString(data));

    // Partition it into different trackedParametersFloat structures
    List<trackedParametersFloat> structureList = new LinkedList<trackedParametersFloat>(); // Create a list of trackedParametersFloat structures, one for each box 
    int bytesPerBox = numParameters*bytesPerFloat;
    for (int i = 0; i < numBoxes; i++) {
      byte[] thisBoxData = new byte[bytesPerBox];
      System.arraycopy(data, bytesPerBox*i, thisBoxData, 0, bytesPerBox);
      structureList.add(new trackedParametersFloat(thisBoxData, numParameters));
    }

    return structureList;
  }

  void setName(int boxInd, String birdName) {
    boxArray[boxInd].setName(birdName);
  }

  void closeFileWriters() {
    for (int i = 0; i < numBoxes; i++) {
      boxArray[i].closeFileWriter();
    }
  }

  boolean arduinoSendSignal(String call) {
    // Output is whether or not a response was received
    // Call the arduino (send the "call" string) and wait for a response (will call the arduino multiple times, every waitTime milliseconds
    int waitTime = 50; // Number of milliseconds between each call
    int maxCalls = 10; // Maxiumum number of times to call the arduino before giving up

    // First, clear the serial buffer
    port.clear();

    // Then, call the Arduino
    int numTries = 0; // The number of times the program has tried to call the arduino
    boolean response = false;
    while (!response & numTries < maxCalls) {
      serialDebug("Calling...");

      port.write(call); 

      // Continue checking for a response
      boolean timeOut = false; // Has a timeout occurred while waiting for the Arduino?
      int timeStart = millis(); // Time that the waiting period started
      while (port.available() == 0) {
        // Wait for the arduino to send something (the number of boxes, specifically)
        if ((millis() - timeStart) > waitTime) {
          // If the wait time has expired, send another
          serialDebug("No response");
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
      serialDebug("Reponse");
      serialStatus = clearFlag();
      // Set message on the Serial warning box
    } else {
      serialStatus = setStatus(serialStatus, DISCONNECTED);
      // Set message on the Serial warning box
    }
    serialDebug("");

    return response;
  }
};