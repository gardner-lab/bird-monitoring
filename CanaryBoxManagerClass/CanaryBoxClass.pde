// Class that represents each bird box.  Has information on each box, as well as the methods to draw the display for each box
class birdBox {
  // Manager
  birdBoxManager manager;

  // Experimental parameters
  String birdName = "";
  int status = 0; // Bit-field that represents any warning statuses on this box (all 0's means everything is in order)
  boolean doorClosed = true;
  boolean badData = false; // Is this current set of data good, or errored?
  boolean birdInBox = false; // Is there a bird in this box?
  boolean tempWarning = false; // Is the temperature out of range?
  boolean humidityWarning = false; // Is the humidity out of range?

  // Parameters needed for the emailing function
  String emailAddressesFileName; // Name of the file that has all of the email addresses
  Emailer emailer; // The oject responsible for emailing users if anything goes wrong
  String curWarningMessage = ""; // The current message that the Emailer has
  int lastStatus = status; // The status as it was the last time the Emailer was contacted (used to see if the message should be changed)
  float minutesToWaitBeforeEmailing = 10; // The number of minutes to wait before sending an email warning

  // Parameters for keeping track of door-related warnings
  // Social time will be tracked by using two Lists.  The first is a List of Booleans, which store the raw data of when the door is open.  Every checkDoorPeriod minutes, this list will be summed and stored into the second List (of Integers), to keep a low-resolution memory of when the door was open
  float doorTimePeriodHrs = 24; // Hours
  float socialTimeRequiredHrs = 1; // Hours
  float doorOpenUpperLimitHrs = 12; // Hours
  float checkDoorPeriodMin = 10; // Minutes - Period between checking the amount of social time
  long doorTimePeriod; // Same as above, but will be converted into milliseconds
  long socialTimeRequired; // Same as above, but will be converted into milliseconds
  long doorOpenUpperLimit; // Same as above, but will be converted into milliseconds
  long checkDoorPeriod; // Same as above, but will be converted into milliseconds
  long lastDoorClosed; // Time at which the door was last closed (used to check that the door hasn't been open for too long)
  long lastDoorCheck; // Time at which the program last checked for door-related errors/warnings 
  long lastDoorAddData; // Time at which data was last added to the allDoorData queue (door may be checked, but it's possible that no data was added)
  long timeAllDoorDataStarted; // The timestamp marking the beginning of the period that allDoorData represents 
  Queue<Long> allDoorData; // This List will keep track of the number of seconds of social time within the current checkDoorPeriod
  Queue<Long> allDoorDataTimePeriods; // This List keeps track of how much time each element of allDoorData represents
  Queue<Boolean> currentDoorData; // This List will keep track of each new data sample, tracking when the door is open
  int numDoorData; // Number of entries that SHOULD be in the allDoorData Queue, to completely fill the doorTimePeriod

  // Set colors for different parameters
  color tempColor = BLUE;
  color humidityColor = GREEN;

  // Object for writing a file
  csvWriter fileWriter; // Writer to send data to file
  String writerDirectory; // Directory (sub-directory of mainDirectory) in which the data will be written
  String[] headers; // Headers for the file
  boolean writerInitialized = false; // Has a writer been created yet? (Cannot create at construction, because birdName has not been initialized)

  // Experimental data
  // There are three sets of data being kept for each parameter, one each for minutes, hours, and days time scale
  LinkedList<Float> tempDataMin; // Data for temperature, minute scale
  LinkedList<Float> humidityDataMin; // Data for humidity, minute scale
  LinkedList<Float> tempDataHour; // Data for temperature, hour scale
  LinkedList<Float> humidityDataHour; // Data for humidity, hour scale
  LinkedList<Float> tempDataDay; // Data for temperature, day scale
  LinkedList<Float> humidityDataDay; // Data for humidity, day scale
  LinkedList<Float> timeDataMin; // List which holds all of the time points, minute scale
  LinkedList<Float> timeDataHour; // List which holds all of the time points, hour scale
  LinkedList<Float> timeDataDay; // List which holds all of the time points, day scale
  LinkedList<Float> tempSmoothingFilter; // List which holds the last sizeSmoothingFilter number of temperature data points to smooth the input
  LinkedList<Float> humiditySmoothingFilter; // List which holds the last sizeSmoothingFilter number of humidity data points to smooth the input

  // Information on each data set
  int maxNumData; // Maximum number of data points
  int numDataMin = 0; // Number of data points
  int numDataHour = 0; // Number of data points
  int numDataDay = 0; // Number of data points
  int numDataFilter = 0; // Number of data points in filter
  int sizeSmoothingFilter = 5; // Number of data points to average over to smooth out the data
  float tempErrorMin = 0; // The minimum temperature that can reasonably be expected (anything less will be considered an Arduino error)
  float tempErrorMax = 120; // The maximum temperature that can reasonably be expected (anything more will be considered an Arduino error)
  float humidityErrorMin = 0; // The minimum humidity that can reasonably be expected (anything less will be considered an Arduino error)
  float humidityErrorMax = 100; // The maximum humidity that can reasonably be expected (anything more will be considered an Arduino error)
  float secPeriod; // Period between data points in seconds (used to calculate minPeriod, hourPeriod, and dayPeriod)
  float minPeriod; // Period between data points in minutes (used for data increment on plot, so it must be in the units of the x-axis)
  float hourPeriod; // Period between data points in hours (used for data increment on plot, so it must be in the units of the x-axis)
  float dayPeriod; // Period between data points in days (used for data increment on plot, so it must be in the units of the x-axis)
  float hourPeriodInMillis; // Period between data points for the hours plot, in milliseconds
  float dayPeriodInMillis; // Period between data points for the day plot, in milliseconds
  long lastHourUpdate; // The time at which the last hour data update occurred
  long lastDayUpdate; // The time at which the last day data update occurred
  float lastTime; // The time value associate with the first data point in the current time scale
  float firstTimeMin = 0; // The time value associated with the first data point in the min data
  float firstTimeHour = 0; // The time value associated with the first data point in the hour data
  float firstTimeDay = 0; // The time value associated with the first data point in the day data
  Calendar minHourRelativeDate = getLastMidnight(); // The date that the minute/hour trace is relative to
  long lastTimeInTimeDataMin = 0; // The timeDataMin.peek() result from the last time sendDataToTrace was called (used to shift minHourRelativeDate)
  Calendar dayRelativeDate = getFirstOfMonthMidnight(); // The date that the day trace is relative to
  long lastTimeInTimeDataDay = 0; // The timeDataDay.peek() result from the last time sendDataToTrace was called (used to shift dayRelativeDate)
  int plotTimeScale = MINUTES; // The current scale that the plot is using
  float tempMin; // Minimum allowable temperature
  float tempMax; // Maximum allowable temperature
  float humidityMin; // Minimum allowable humidity
  float humidityMax; // Maximum allowable humidity
  float humidityToTempRatio; // Value needed to convert humidity values to temperature values on the same scale (used to plot humidity and temperature on the same axis)

  // Drawing parameters
  // Whole space
  int allHeight;
  int allWidth;
  int leftX;
  int rightX;
  int topY;
  int bottomY;

  // Box Diagram
  int boxDiagramX;
  int boxDiagramY;
  int boxDiagramHeight;
  int boxDiagramWidth;
  int textWidth;
  int textHeight;

  // Plot Diagram
  int plotX;
  int plotY;
  int plotHeight;
  int plotWidth;
  int plotScale; // Which scale will be plotted (minutes, hours, days)
  dataTrace tempTrace; // Trace responsible for plotting temperature data
  dataTrace humidityTrace; // Trace responsible for plotting humidity data
  warningTrace warnTrace; // Trace for visually representing the warning values
  float xAxisMin; // The minimum value of the x-axis data
  float xAxisMax; // The maximum value of the x-axis data
  int numYTicks; // The number of ticks on the y-axis
  int numXTicks; // The number of ticks on the x-axis
  String xLabelStr; // The label for the x-axis
  Graph2D graph; // Temperature graph
  Graph2D gSecondY; // Dummy graph object for second Y axis

  // Mini-plot diagram
  int miniPlotWidth;
  int miniPlotX;
  Graph2D miniGraph; // Quick-view graph to the right of the main graph
  quickViewTrace tempQuickTrace;
  quickViewTrace humidityQuickTrace;

  // Value labels
  int valLabelX; // X-location of the value labels
  int valLabelWidth; // Width of the value labels
  int valLabelTempY;
  int valLabelHumidityY;
  int valLabelHeight;
  Textlabel tempLabel;
  Textlabel humidityLabel;

  // Plot buttons (These define from the top left corner, regardless of rectMode())
  List<Button> allButtons; // A list of all buttons for this box
  int numButtons = 3;
  int buttonX;
  int buttonFirstY;
  int buttonWidth;
  int buttonHeight;
  int buttonPitch; // The distance between the centers of the buttons
  int normalBackgroundColor; // The normal color for the buttons' background

  // ControlP5 object to control any interactivity with the GUI
  ControlP5 cp5;
  ControlFont cFontBig; // Font to be used on most text in window
  ControlFont cFontSmall; // Font to be used on small text in window 

  birdBox(int boxXIn, int boxYIn, int widthIn, int heightIn, birdBoxManager managerIn) {
    // Environmental parameters
    tempMin = 61; // Minimum allowable temperature
    tempMax = 81; // Maximum allowable temperature
    humidityMin = 30; // Minimum allowable humidity
    humidityMax = 70; // Maximum allowable humidity

    // These parameters can be adjusted to change the shape of the display
    float plotWidthFrac = .25; // Center of plot as a fraction of the screen (will fill to the left side)
    float boxDiagramWidthFrac = .86; // Center of box diagram as a fraction of the screen (will fill to right side)
    float numHours = 12; // Number of hours to see on hour plot
    float numDays = 7; // Number of days to see on day plot
    numYTicks = 5; // Number of ticks to appear on the plots
    numXTicks = 10; // Number of ticks to appear on the plots
    float percentExtraYAxis = 20; // Percentage outside of allowable range to view the y-axis
    float tempRange = tempMax - tempMin;
    float humidityRange = humidityMax - humidityMin;
    float yAxisTempMin = tempMin - tempRange*(percentExtraYAxis/100); // Minimum value for y axis
    float yAxisTempMax = tempMax + tempRange*(percentExtraYAxis/100);
    float yAxisHumidityMin = humidityMin - humidityRange*(percentExtraYAxis/100); // Minimum value for y axis
    float yAxisHumidityMax = humidityMax + humidityRange*(percentExtraYAxis/100);

    allHeight = heightIn;
    allWidth = widthIn;
    leftX = (boxXIn - allWidth/2); // Position of left side
    rightX = (boxXIn + allWidth/2);  // Position of right side
    topY = boxYIn - allHeight/2; // Position of top
    bottomY = boxYIn + allHeight/2; // Position of bottom

    // Initialize parameters needed for the emailing function
    emailAddressesFileName = mainDirectory + "birdBoxEmailAddresses.csv";
    //minutesToWaitBeforeEmailing = 10; // The number of minutes to wait before sending an email warning

    // Intialize the parameters for tracking social time
    allDoorData = new LinkedList<Long>();
    currentDoorData = new LinkedList<Boolean>();
    allDoorDataTimePeriods = new LinkedList<Long>();
    doorTimePeriod = (long)(doorTimePeriodHrs*(float)millisPerHour);
    socialTimeRequired = (long)(socialTimeRequiredHrs*(float)millisPerHour);
    doorOpenUpperLimit = (long)(doorOpenUpperLimitHrs*(float)millisPerHour);
    checkDoorPeriod = (long)(checkDoorPeriodMin*(float)millisPerMin);
    numDoorData = round((float)doorTimePeriod/checkDoorPeriod); // Calculate the number of entries in the allDoorData Queue
    long curTimeMillis = Calendar.getInstance().getTimeInMillis();
    lastDoorCheck = curTimeMillis; // Initialize the lastDoorCheck variable
    lastDoorAddData = curTimeMillis; // Initialize the lastDoorAddData variable
    timeAllDoorDataStarted = curTimeMillis; // Initialize the timeAllDoorDataStarted variable (used to check how much time has passed, to see if the amount of social time should be checked)
    lastDoorClosed = curTimeMillis;

    // Calculate drawing parameters
    // Box diagram
    boxDiagramX = (int) (leftX + boxDiagramWidthFrac*allWidth);
    boxDiagramY = boxYIn;
    boxDiagramHeight = allHeight;
    boxDiagramWidth = (int)((1 - boxDiagramWidthFrac)*2*allWidth); // (1 - boxDiagramWidthFrac)*allWidth gives "radius" of rectangle

    // Text for box diagram
    textWidth = 150;
    textHeight = 40;
    int fontSizeBig = 30;
    int fontSizeSmall = 16;

    // Plot
    int plotVertTicksRoom = 30;
    int plotHorzTicksRoom = 60;
    plotHeight = allHeight - plotVertTicksRoom;
    plotWidth = (int)(plotWidthFrac*2*allWidth - 2*plotHorzTicksRoom); // plotWidthFrac*allWidth gives "radius" of rectangle, and make room for both y-axes
    plotX = leftX + 2*plotHorzTicksRoom;
    plotY = boxYIn - plotHeight/2;
    plotScale = MINUTES;
    manager = managerIn; // Record the pointer to the manager

    // Mini Plot
    int miniPlotWidthBuffer = 3;
    miniPlotWidth = 50;
    miniPlotX = plotX + plotWidth + miniPlotWidthBuffer;

    // Buttons to control the plot
    int buttonWidthBuffer = 3;
    int buttonHeightBuffer = 30;
    buttonX = plotX + plotWidth + miniPlotWidth + miniPlotWidthBuffer + buttonWidthBuffer;
    buttonFirstY = boxYIn - allHeight/2 + buttonHeightBuffer;
    buttonWidth = 50;
    buttonHeight = 30;
    int totalButtonYSpace = allHeight - 2*buttonHeightBuffer;
    buttonPitch = (totalButtonYSpace - buttonHeight)/(numButtons - 1); // The distance between the centers of the buttons

    // Create the controller, and add the buttons
    cp5 = new ControlP5(manager.sketchPApplet);
    allButtons = new ArrayList<Button>();
    allButtons.add(cp5.addButton("Minutes")
      .setValue(MINUTES)
      .setPosition(buttonX, buttonFirstY)
      .setSize(buttonWidth, buttonHeight)
      .addCallback(new buttonListener()));
    allButtons.add(cp5.addButton("Hours")
      .setValue(HOURS)
      .setPosition(buttonX, buttonFirstY + buttonPitch)
      .setSize(buttonWidth, buttonHeight)
      .addCallback(new buttonListener()));
    allButtons.add(cp5.addButton("Days")
      .setValue(DAYS)
      .setPosition(buttonX, buttonFirstY + 2*buttonPitch)
      .setSize(buttonWidth, buttonHeight)
      .addCallback(new buttonListener()));

    normalBackgroundColor = allButtons.get(0).getColor().getBackground(); 
    allButtons.get(0).setColorBackground(GREEN);

    // Add the textbox for the box, and the textfield
    // First, create the font
    cFontBig = new ControlFont(createFont("Helvetica", fontSizeBig));
    cFontSmall = new ControlFont(createFont("Helvetica", fontSizeSmall));
    cp5.addTextfield("")
      .setText("")
      .setPosition(boxDiagramX - textWidth/2, boxDiagramY - textHeight/2)
      .setSize(textWidth, textHeight)
      .setAutoClear(false)
      .setColorBackground(g.backgroundColor)
      .setColor(0)
      .setFont(cFontBig)
      .addListener(new textListener());
    ControlFont.sharp();

    // Value labels
    int valLabelBufferWidth = 5;
    int valLabelBufferHeight = 10;
    int numLabels = 2;
    int buttonsRight = buttonX + buttonWidth;
    int boxDiagramLeft = boxDiagramX - boxDiagramWidth/2;
    int textHeight = 15;
    valLabelX = buttonsRight + valLabelBufferWidth;
    valLabelWidth = boxDiagramLeft - buttonsRight - 2*valLabelBufferWidth;
    valLabelHeight = (plotHeight - ((numLabels + 1)*valLabelBufferHeight))/numLabels;
    valLabelTempY = plotY + valLabelHeight/2 + valLabelBufferHeight;
    valLabelHumidityY = valLabelTempY + valLabelHeight +valLabelBufferHeight;
    // Add the labels to the cp5 controller
    tempLabel = cp5.addTextlabel("Temperature")
      .setValue("")
      .setPosition(valLabelX, valLabelTempY)
      .setSize(valLabelWidth, valLabelHeight)
      .setFont(cFontBig);
    humidityLabel = cp5.addTextlabel("Humidity")
      .setValue("")
      .setPosition(valLabelX, valLabelHumidityY)
      .setSize(valLabelWidth, valLabelHeight)
      .setFont(cFontBig);
    // Add text labels (to show what the numbers represent
    cp5.addTextlabel("TemperatureText")
      .setValue("Temperature:")
      .setPosition(valLabelX, valLabelTempY - textHeight)
      .setSize(valLabelWidth, valLabelHeight)
      .setFont(cFontSmall)
      .setColor(tempColor);
    cp5.addTextlabel("HumidityText")
      .setValue("Humidity:")
      .setPosition(valLabelX, valLabelHumidityY - textHeight)
      .setSize(valLabelWidth, valLabelHeight)
      .setFont(cFontSmall)
      .setColor(humidityColor);

    // Initialize data traces
    tempTrace = new dataTrace(tempColor); // This is the primary trace.
    humidityTrace = new dataTrace(humidityColor); // This is the secondary trace.  The values must be transformed into values for the temp trace to be properly plotted with the graph (the graph object can only have 1 y-axis)
    // Pass the low and high warning values to each trace
    warnTrace = new warningTrace(tempMin, tempMax); // The temperature warning values are sent, because they are the native unit for the graph object
    // Initialize the quick-view traces
    tempQuickTrace = new quickViewTrace(tempColor); // Primary trace (humidity will be transformed to temperature to be viewed on the same plot)
    humidityQuickTrace = new quickViewTrace(humidityColor);

    // Initialize graphs
    graph = new Graph2D(manager.sketchPApplet, plotWidth, plotHeight, false);
    miniGraph = new Graph2D(manager.sketchPApplet, miniPlotWidth, plotHeight, false);
    // Set graph position
    graph.position.x = plotX;
    graph.position.y = plotY;
    miniGraph.position.x = miniPlotX;
    miniGraph.position.y = plotY;
    //Set up axes sizes
    xAxisMin = 0;
    xAxisMax = pixelsToMinutes(plotWidth);
    graph.setXAxisMin(xAxisMin);
    graph.setXAxisMax(xAxisMax);
    graph.setYAxisMin(yAxisTempMin);
    graph.setYAxisMax(yAxisTempMax);
    graph.setXAxisTickSpacing((xAxisMax - xAxisMin)/numXTicks);
    graph.setYAxisTickSpacing((yAxisTempMax - yAxisTempMin)/numYTicks);
    miniGraph.setXAxisMin(0);
    miniGraph.setXAxisMax(0);
    miniGraph.setXAxisTickSpacing(10);
    miniGraph.setYAxisMin(yAxisTempMin); 
    miniGraph.setYAxisMax(yAxisTempMax);
    miniGraph.setYAxisTickSpacing((yAxisTempMax - yAxisTempMin)/numYTicks);
    // Set up axis labels and colors
    graph.setYAxisLabel("Temperature (˚F)");
    miniGraph.setYAxisLabel("");
    miniGraph.setXAxisLabel("");
    createSecondYAxis(yAxisHumidityMin, yAxisHumidityMax, "Humidity (%RH)", humidityColor);
    setXLabel(); // Set the graph's x-axis label according to the current time scale chosen
    graph.setAxisColour(new GWColour(tempColor));
    // Set up background
    graph.setBackground(new SolidColourBackground(new GWColour(150)));
    miniGraph.setBackground(new SolidColourBackground(new GWColour(150)));
    // Add traces to graph
    graph.addTrace(tempTrace); // Add the temperature trace to the graph
    graph.addTrace(humidityTrace); // Add the humidity trace to the graph
    graph.addTrace(warnTrace); // Add the warning trace to the graph
    miniGraph.addTrace(tempQuickTrace); // Add the temperature quick-view trace
    miniGraph.addTrace(humidityQuickTrace); // Add the humidity quick-view trace

    // Intialize Data Lists (Queues)
    tempDataMin = new LinkedList<Float>(); // Data for temperature, minute scale
    humidityDataMin = new LinkedList<Float>(); // Data for humidity, minute scale
    tempDataHour = new LinkedList<Float>(); // Data for temperature, hour scale
    humidityDataHour = new LinkedList<Float>(); // Data for humidity, hour scale
    tempDataDay = new LinkedList<Float>(); // Data for temperature, day scale
    humidityDataDay = new LinkedList<Float>(); // Data for humidity, day scale
    timeDataMin = new LinkedList<Float>(); // Time points
    timeDataHour = new LinkedList<Float>(); // Time points
    timeDataDay = new LinkedList<Float>(); // Time points
    tempSmoothingFilter = new LinkedList<Float>(); // Temperature smoothing
    humiditySmoothingFilter = new LinkedList<Float>(); // Temperature smoothing
    maxNumData = plotWidth; // Set the number of data points to be equal to the number of pixels in the plot
    humidityToTempRatio = tempRange/humidityRange;

    // Calculate the period between data points for hours and days (minutes' is defined as Processing's sampling rate for getting data from the Arduino)
    secPeriod = (float)manager.fetchTime/1000; // Period between each data point in seconds
    minPeriod = secPeriod/secPerMin; // Period between each data point in minutes
    float numMinutes = (plotWidth*minPeriod); // Number of minutes that appears on minute plot
    hourPeriod = (minPeriod*(numHours/(numMinutes/60)))/minPerHour;  // Calculate the period between data points in the days data set, in hours (the number of seconds between each data point in the hours data set, divided by the number of seconds per hour)
    dayPeriod = hourPeriod*(numDays/(numHours/24))/hourPerDay;  // Calculate the period between data points in the days data set, in days (the number of seconds between each data point in the days data set, divided by the number of seconds per day)
    hourPeriodInMillis = hourPeriod*(millisPerSec*secPerMin*minPerHour); // The period in hours, converted to the period in milliseconds
    dayPeriodInMillis = dayPeriod*(millisPerSec*secPerMin*minPerHour*hourPerDay); // The period in days, converted to the period in milliseconds
    lastHourUpdate = 0; // Initialize so that an update occurs
    lastDayUpdate = 0; // Initialize so that an update occurs

    // Intialize the headers for the file writer
    String[] allHeaders = {"Time (hour:minute:second)", "Temperature (F)", "Humidity (%RH)", "Door Closed"};
    headers = allHeaders; // Because array constaints can't be used outside of initializers ("Hi, I'm Java, and I'm an annoying jerk who won't let you do things easily! :P")
    writerDirectory = mainDirectory + "data" + sep;
  }

  void createFileWriter() {
    if (!writerInitialized) {
      ioDebug("Creating File Writer");
      ioDebug("Current directory: " + writerDirectory);

      // Check if the writerDirectory exists (if not, use the standard user pathway)
      File writerDirectoryFile = new File(writerDirectory);
      if (!(writerDirectoryFile.exists())) {
        // Set the main path to be the user's main directory
        errorReporting("Could not find directory \"" + writerDirectory + "\".  Creating it.");
        writerDirectoryFile.mkdir();
      }

      fileWriter = new csvWriter(writerDirectory, birdName, headers, manager.fManager);
      ioDebug("File Writer created");
      writerInitialized = true;
    }
  }

  void closeFileWriter() {
    ioDebug("Closing File Writer");
    if (writerInitialized) {
      writerInitialized = false;
    }
  }

  void createSecondYAxis(float axisMin, float axisMax, String axisLabel, color axisColor) {
    gSecondY = new Graph2D(manager.sketchPApplet, 0, plotHeight, false);
    gSecondY.position.x = leftX + 50;
    gSecondY.position.y = plotY;

    gSecondY.setXAxisLabel("");
    gSecondY.setXAxisMin(0);
    gSecondY.setXAxisMax(0);
    gSecondY.setXAxisTickSpacing(10);

    gSecondY.setYAxisLabel(axisLabel);
    gSecondY.setYAxisMin(axisMin); 
    gSecondY.setYAxisMax(axisMax);
    gSecondY.setYAxisTickSpacing((axisMax - axisMin)/numYTicks);

    gSecondY.setAxisColour(new GWColour(axisColor));
  }

  void adjustXAxis(float xAxisMin, float xAxisMax) {
    // Change the label for the graph
    setXLabel();

    // Change the scale
    graph.setXAxisMin(xAxisMin);
    graph.setXAxisMax(xAxisMax);
    graph.setXAxisTickSpacing((xAxisMax - xAxisMin)/numXTicks);
  }

  void setXLabel() {
    switch (plotTimeScale) {
    case MINUTES:
      xLabelStr = "minutes since midnight " + date.format(minHourRelativeDate.getTime());
      break;
    case HOURS:
      xLabelStr = "hours since midnight " + date.format(minHourRelativeDate.getTime());
      break;
    case DAYS:
      xLabelStr = "days since midnight " + date.format(dayRelativeDate.getTime());
      break;
    default:
      xLabelStr = "minutes since midnight " + date.format(minHourRelativeDate.getTime());
      break;
    }
    graph.setXAxisLabel("Time (" + xLabelStr + ")");
  }

  float humidityToTemp(float humidityIn) {
    float tempOut = (humidityIn - humidityMin)*humidityToTempRatio + tempMin;
    return tempOut;
  }

  List<Float> humidityToTemp(LinkedList<Float> humidityIn) {
    List tempOut = new LinkedList<Float>(); 
    for (int i = 0; i<humidityIn.size(); i++) {
      tempOut.add(humidityToTemp(humidityIn.get(i)));
    }
    return tempOut;
  }

  void errorData(int numParams, Calendar curTime) {
    List<Float> errorData = new LinkedList<Float>();
    badData = true;
    for (int i = 0; i < numParams; i++) {
      errorData.add(-1f);
    }
    setNewData(errorData, curTime);
    badData = false;
  }

  void setNewData(List<Float> data, Calendar curTime) {
    // Add graphable data to all data lists
    List<Float> newData = addDataFilter(data);
    addDataMin(newData);
    addDataHour(curTime.getTimeInMillis());
    addDataDay(curTime.getTimeInMillis());

    // Set the state of the door
    switch (newData.get(2).intValue()) {
    case 1:
      doorClosed = true;
      break;
    case 0:
      doorClosed = false;
      break;
    }
    currentDoorData.add(doorClosed); // Store the current state of the door (to be summed later)

    // Send the newest data to the dataTrace object, so that it will be plotted on the next draw() cycle
    sendDataToTrace();

    // Write data to file
    // If the data is real
    if (!badData) {
      // Check the data to ensure that it is within acceptable experimental boundaries
      setNewStatus(newData);

      // Set the value labels
      setValueLabels(newData);

      // Send to files
      if (writerInitialized && birdInBox) {
        // If the writer has been created
        List<Float> dataToWrite = newData;
        String timeString = sdf.format(curTime.getTime());
        fileWriter.writeLine(dataToWrite, timeString);
      }
    }
  };

  boolean tempDataIsError(float data) {
    boolean dataIsErrored = false;
    if (data == -1 || data < tempErrorMin || data > tempErrorMax) {
      dataIsErrored = true;
    }
    return dataIsErrored;
  }

  boolean humidityDataIsError(float data) {
    boolean dataIsErrored = false;
    if (data == -1 || data < humidityErrorMin || data > humidityErrorMax) {
      dataIsErrored = true;
    }
    return dataIsErrored;
  }

  List<Float> addDataFilter(List<Float> data) {
    // Filter the incoming data, or pass error data through
    List<Float> newData;
    if (!tempDataIsError(data.get(0)) && !humidityDataIsError(data.get(1))) {
      // Add the new data to the smoothing filters
      if (numDataFilter >= sizeSmoothingFilter) {
        tempSmoothingFilter.remove();
        humiditySmoothingFilter.remove();
        numDataFilter--;
      }
      tempSmoothingFilter.add(data.get(0));
      humiditySmoothingFilter.add(data.get(1));
      numDataFilter++;

      // Get the means of the smoothing filters, and construct a new "newData"
      newData = new ArrayList<Float>();
      newData.add(getMeanOfList(tempSmoothingFilter));
      newData.add(getMeanOfList(humiditySmoothingFilter));

      // Add in the remaining data points (starting at 2, because the first 2 have already been added)
      for (int i = 2; i<data.size(); i++) {
        newData.add(data.get(2));
      }
    } else {
      // If there is a data error, pass the error through
      newData = data;
    }

    return newData;
  }

  void setValueLabels(List<Float> newData) {
    tempLabel.setValue(String.format("%.1f", newData.get(0)));
    humidityLabel.setValue(String.format("%.1f", newData.get(1)));
  }

  void setNewStatus(List<Float> newData) {
    // Set the status flag for this new set of data (flags will be checked on draw())
    float newTempVal = newData.get(0);
    float newHumidityVal = newData.get(1);

    if (!badData) {
      // If the new data is real (not error data)

      // List the potential error states
      boolean tempLow = false;
      boolean tempHigh = false;
      boolean humidityLow = false;
      boolean humidityHigh = false;

      // Check the temperature
      if (newTempVal < tempMin) {
        tempLow = true;
      } else if (newTempVal > tempMax) {
        tempHigh = true;
      }

      // Check the humidity
      if (newHumidityVal < humidityMin) {
        humidityLow = true;
      } else if (newHumidityVal > humidityMax) {
        humidityHigh = true;
      }

      // Set the status flag for this box (will cause blinking on the box diagram, and perform any other required actions
      status = updateStatus(status, TEMPHIGH, tempHigh);
      status = updateStatus(status, TEMPLOW, tempLow);
      status = updateStatus(status, HUMIDITYHIGH, humidityHigh);
      status = updateStatus(status, HUMIDITYLOW, humidityLow);

      // Print to debugger any warnings
      if (tempHigh) {
        dataDebug("High temp warning on");
        dataDebug("Temp: " + newTempVal + ", warning at " + tempMax);
        dataDebug("");
      }
      if (humidityHigh) {
        dataDebug("High humidity warning on");
        dataDebug("Humidity: " + newHumidityVal + ", warning at " + humidityMax);
        dataDebug("");
      }

      if (tempLow) {
        dataDebug("Low temp warning on");
        dataDebug("Temp: " + newTempVal + ", warning at " + tempMin);
        dataDebug("");
      }

      if (humidityLow) {
        dataDebug("Low humidity warning on");
        dataDebug("Humidity: " + newHumidityVal + ", warning at " + humidityMin);
        dataDebug("");
      }
    }
  }

  int updateStatus(int bField, int status, boolean warningOn) {
    // This function will set the status flag in the bit-field bField according to whether or not warningOn is true
    // I.e. if warningOn is true, the status flag in bField will be set, otherwise it will be cleared
    // Example usage: status = updateStatus(status, SOMETHINGISWRONG, isSomethingWrong);
    // If isSomethingWrong is true, then the SOMETHINGISWRONG flag will be set in status
    int bFieldOut = bField;
    if (warningOn) {
      bFieldOut = setStatus(bField, status);
    } else {
      bFieldOut = clearStatus(bField, status);
    }
    return bFieldOut;
  }

  void sendDataToTrace() {
    LinkedList<Float> tempDataNew;
    LinkedList<Float> humidityDataNew;
    LinkedList<Float> timeDataNew;
    float xAxisWidth;

    float dataIncrement = minPeriod; // The amount of time between data points IN UNITS OF THE PLOT'S TIME SCALE (ex. minPeriod is time between data points in minutes, hourPeriod is time between data points in hours)
    switch (plotTimeScale) {
    case MINUTES:
      tempDataNew = tempDataMin;
      humidityDataNew = humidityDataMin;
      timeDataNew = timeDataMin;
      dataIncrement = minPeriod;
      xAxisWidth = pixelsToMinutes(plotWidth);
      break;
    case HOURS:
      tempDataNew = tempDataHour;
      humidityDataNew = humidityDataHour;
      timeDataNew = timeDataHour;
      dataIncrement = hourPeriod;
      xAxisWidth = pixelsToHours(plotWidth);
      break;
    case DAYS:
      tempDataNew = tempDataDay;
      humidityDataNew = humidityDataDay;
      timeDataNew = timeDataDay;
      dataIncrement = dayPeriod;
      xAxisWidth = pixelsToDays(plotWidth);
      break;
    default:
      tempDataNew = tempDataMin;
      humidityDataNew = humidityDataMin;
      timeDataNew = timeDataMin;
      dataIncrement = minPeriod;
      xAxisWidth = pixelsToMinutes(plotWidth);
      break;
    }

    // Adjust the x-axis (Will cause jump at midnight)
    xAxisMin = timeDataNew.peek();
    xAxisMax = xAxisWidth + xAxisMin;
    adjustXAxis(xAxisMin, xAxisMax);

    // Update the main trace objects
    //tempTrace.setData(tempDataNew, timeDataNew);
    //humidityTrace.setData(humidityToTemp(humidityDataNew), timeDataNew);
    tempTrace.setData(tempDataNew, xAxisMin, dataIncrement);
    humidityTrace.setData(humidityToTemp(humidityDataNew), xAxisMin, dataIncrement);
    warnTrace.setTime(xAxisMin);

    // Update the mini-graph trace objects
    tempQuickTrace.setData(tempDataMin.get(tempDataMin.size() - 1));
    humidityQuickTrace.setData(humidityToTemp(humidityDataMin.get(humidityDataMin.size() - 1)));

    // Call the generate function, so that the traces are plotted
    tempTrace.generate();
    humidityTrace.generate();
    tempQuickTrace.generate();
    humidityQuickTrace.generate();
  }

  Calendar getLastMidnight() {
    // Returns a calendar object set to last midnight
    Calendar c = Calendar.getInstance();
    c.set(Calendar.HOUR_OF_DAY, 0);
    c.set(Calendar.MINUTE, 0);
    c.set(Calendar.SECOND, 0);
    c.set(Calendar.MILLISECOND, 0);

    return c;
  }

  Calendar getFirstOfMonthMidnight() {
    Calendar c = getLastMidnight();
    c.set(Calendar.DAY_OF_MONTH, 1);
    return c;
  }

  float millisToMins(long numMillis) {
    return (float)numMillis/(float)millisPerMin;
  }

  float millisToHours(long numMillis) {
    return (float)numMillis/(float)millisPerHour;
  }

  float millisToDays(long numMillis) {
    return (float)numMillis/(float)millisPerDay;
  }

  void addDataMin(List<Float> newData) {
    // Ensure that the queue is always the correct size
    if (numDataMin >= maxNumData) {
      tempDataMin.remove();
      humidityDataMin.remove();
      timeDataMin.remove();
      numDataMin--;
      firstTimeMin += minPeriod; // Move the graph over one increment
    }

    // Add graphable data
    tempDataMin.add(new Float(newData.get(0)));
    humidityDataMin.add(new Float(newData.get(1)));
    timeDataMin.add(millisToMins(Calendar.getInstance().getTimeInMillis() - getLastMidnight().getTimeInMillis())); // Add the number of minutes since midnight

    // Update the relative date
    if (timeDataMin.peek() < lastTimeInTimeDataMin) {
      minHourRelativeDate = getLastMidnight();
    }
    lastTimeInTimeDataMin = timeDataMin.peek().longValue();

    // Increment the number of data points
    numDataMin++;
  };

  void addDataHour(long curTime) {
    // Add data if the required time has passed
    if (curTime >= ((lastHourUpdate + (long)hourPeriodInMillis)) || (lastHourUpdate == 0)) {
      // Ensure that the queue is always the correct size
      if (numDataHour >= maxNumData) {
        tempDataHour.remove();
        humidityDataHour.remove();
        timeDataHour.remove();
        numDataHour--;
        firstTimeHour += hourPeriod; // Move the graph over one increment
      }

      // Add graphable data (add an average over the last hourPeriodInMillis milliseconds)
      int minuteDataInd = min(numDataMin, (int)(hourPeriodInMillis/manager.fetchTime));
      tempDataHour.add(getMeanOfList(tempDataMin.subList(0, minuteDataInd)));
      humidityDataHour.add(getMeanOfList(humidityDataMin.subList(0, minuteDataInd)));
      timeDataHour.add(millisToHours(Calendar.getInstance().getTimeInMillis() - getLastMidnight().getTimeInMillis())); // Add the number of hours since midnight

      // Record that update occurred
      lastHourUpdate = curTime;

      // Increment the number of data points
      numDataHour++;
    }
  };

  void addDataDay(long curTime) {
    // Add data if the required time has passed
    if (curTime >= (lastDayUpdate + (long)dayPeriodInMillis) || (lastDayUpdate == 0)) {
      // Ensure that the queue is always the correct size
      if (numDataDay >= maxNumData) {
        tempDataDay.remove();
        humidityDataDay.remove();
        timeDataDay.remove();
        numDataDay--;
        firstTimeDay += dayPeriod; // Move the graph over one increment
      }

      // Add graphable data (add an average over the last dayPeriodInMillis milliseconds)
      int minuteDataInd = min(numDataMin, (int)(dayPeriodInMillis/manager.fetchTime));
      tempDataDay.add(getMeanOfList(tempDataMin.subList(0, minuteDataInd)));
      humidityDataDay.add(getMeanOfList(humidityDataMin.subList(0, minuteDataInd)));
      timeDataDay.add(millisToDays(Calendar.getInstance().getTimeInMillis() - getFirstOfMonthMidnight().getTimeInMillis())); // Add the number of days since midnight of the first of the month

      // Update the relative date
      if (timeDataDay.peek() < lastTimeInTimeDataDay) {
        minHourRelativeDate = getFirstOfMonthMidnight();
      }
      lastTimeInTimeDataDay = timeDataDay.peek().longValue();

      // Record that update occurred
      lastDayUpdate = curTime;

      // Increment the number of data points
      numDataDay++;
    }
  };

  float getMeanOfList(List<Float> list) {
    float sum = 0; // Running sum
    for (Float curVal : list) {
      if (curVal != -1) {
        // This function is expecting lists that use "-1" as an error value, so ignore those
        sum += curVal; // Add the current value from the list to the running sum
      }
    }
    float mean = sum/list.size();
    return mean;
  }

  float pixelsToMinutes(float numPixels) {
    // Convert a width (in pixels) to the number of minutes
    return numPixels*minPeriod;
  }

  float pixelsToHours(float numPixels) {
    // Convert a width (in pixels) from the hours plot to the number of hours
    return numPixels*hourPeriod;
  }

  float pixelsToDays(float numPixels) {
    // Convert a width (in pixels) from the days plot to the number of days
    return numPixels*dayPeriod;
  }

  void setName(String birdNameIn) {
    String lastBirdName = birdName; // Store the current name
    birdName = birdNameIn; // Update the current name
    if (!birdName.equals("")) {
      // If the new bird's name is not blank
      //if (!birdName.equals(lastBirdName)) {
        // If the bird's name is new
        birdInBoxStart();
      //}
    } else {
      birdInBoxEnd();
    }
  }

  void birdInBoxStart() {
    if (writerInitialized) {
      closeFileWriter();
    }
    birdInBox = true;
    createFileWriter();
    emailer = new Emailer(emailAddressesFileName, birdName, minutesToWaitBeforeEmailing); // Create a new emailer for this bird
  }

  void birdInBoxEnd() {
    birdInBox = false;
    closeFileWriter();
  }

  color doorStatusColor() {
    color c;
    if (birdInBox) {
      if (!this.doorClosed) {
        c = YELLOW;
      } else {
        c = GREEN;
      }
    } else {
      c = g.backgroundColor;
    }
    return c;
  }

  color warningStatusColor() {
    color c = doorStatusColor(); // Take on the door's status color, unless something is wrong
    if (!flagIsClear(status)) {
      // If there is something wrong
      c = blink(c); // Blink red
    }

    return c;
  }

  void draw() {
    // Draw the box diagragm on the right side of the screen
    drawBoxDiagram();

    // Draw plots and other information
    drawPlot();

    // Set colors for value labels
    setValueLabelColors();

    // Check door-related errors/warnings
    checkDoorWarnings();
  }

  void checkDoorWarnings() {
    Calendar curTime = Calendar.getInstance();
    long curTimeMillis = curTime.getTimeInMillis(); // Get the current time in milliseconds
    boolean checkDoorPeriodExpired = (curTimeMillis > (lastDoorCheck + checkDoorPeriod)); // If checkDoorPeriod has passed since the last door check
    boolean doorStatusTimeExpired = (testFlag(status, DOOROPENTOOLONG) | testFlag(status, SOCIALNEEDED)) && (curTimeMillis > (lastDoorCheck + manager.fetchTime)); // If there is a door status, and fetchTime has passed since the last check

    if (checkDoorPeriodExpired || doorStatusTimeExpired) {
      // Inform the user that a door-warning check is occurring
      doorDebug("Checking door warnings at " + sdf.format(curTime.getTime()) + " because");
      if (checkDoorPeriodExpired) {
        doorDebug("checkDoorPeriod has passed");
      } else {
        doorDebug("Door-related status");
      }

      // Transfer data from currentDoorData over to allDoorData if a)checkDoorPeriod amount of time has passed, or b) there is a door problem and the fetchTime period has passed (increase resolution when it is expected that the door problem will be resolved soon 
      long periodOpenTime = queueSumFalseDestroy(currentDoorData)*manager.fetchTime; // The amount of time that the door has been open over the last period
      doorDebug("Door open for " + periodOpenTime + "ms over last " + (curTimeMillis - lastDoorCheck) + "ms");

      doorDebug("Now adding data to allDoorData");
      // Add the cumulative sum of false's (door being open) to the allDoorData, multiplied by the fetching period (stores the number of milliseconds that the door was open over the last checkDoorPeriod)
      allDoorData.add(periodOpenTime);
      allDoorDataTimePeriods.add(curTimeMillis - lastDoorAddData); // The amount of time that this most recent data represents
      lastDoorAddData = curTimeMillis;

      // Check if the door has been open for too long consecutively (this method has relatively low granularity, but is meant to be used when doorOpenUpperLimit is much larger than checkDoorPeriod)
      if (!doorClosed) {
        doorDebug("Checking if door was open too long");
        doorDebug("Door open for " + (curTimeMillis - lastDoorClosed) + " ms ("+ (float)((curTimeMillis - lastDoorClosed)/millisPerHour) + " hours) straight");
        // If the door is open, compare how long it's been since the last time the door was closed
        if (curTimeMillis > (lastDoorClosed + doorOpenUpperLimit)) {
          doorDebug("Door open for over " + doorOpenUpperLimit + " ms (" + (float)(doorOpenUpperLimit/millisPerHour) + " hours), door was open too long");
          // If it has been longer than doorOpenUpperLimit since the last time the door was closed, set the status such that the door has been open too long
          setStatus(status, DOOROPENTOOLONG);
        }
      } else {
        lastDoorClosed = curTimeMillis; // If the door is closed, reset the time since the last door closure
        clearStatus(status, DOOROPENTOOLONG);
      }

      // Check how much time allDoorData represents (used only in the beginning, when the allDoorData buffer is still filling)
      long totalTimeInAllDoorData = curTimeMillis - timeAllDoorDataStarted;
      doorDebug("Time represented in allDoorData: " + totalTimeInAllDoorData + " (" + (float)(totalTimeInAllDoorData/millisPerHour) + " hours)");
      if (totalTimeInAllDoorData > doorTimePeriod) {
        // If more than doorTimePeriod has passed (if it's been more than 24 hours)

        // Remove the olded data point from allDoorData
        allDoorData.remove(); // Remove the oldest value
        timeAllDoorDataStarted += allDoorDataTimePeriods.remove(); // Move the timeAllDoorDataStarted forward by the period of time that the allDoorData time that was just removed represented
        doorDebug("allDoorData now represents the past " + (float)((totalTimeInAllDoorData)/millisPerHour) + " hours"); 

        // Get the total amount of time that the door was open
        long totalOpenTime = queueSum(allDoorData); // Sum all of the values in allDoorData, which represents the number of ms that the door was open in each epoch (with each element of the array representing one epoch)
        doorDebug("Door open for " + totalOpenTime + "ms (" + (float)totalOpenTime/millisPerHour + " hours) over last " + doorTimePeriodHrs + " hours");

        // Check for social time (only if a full doorTimePeriod has passed, otherwise the social alarm would go off immediately)
        doorDebug("DoorTimePeriod (" + (float)(doorTimePeriod/millisPerHour) + " hours) has passed since program start, checking social time");
        if (totalOpenTime <  socialTimeRequired) {
          // If the the door has not been open enough
          if (doorClosed) {
            // If the door is currently closed, someone needs to be notified to open it
            setStatus(status, SOCIALNEEDED);
            doorDebug("Total time open is less than required social time (" + (float)socialTimeRequired/millisPerHour + " hours): Social time needed");
          } else {
            // If the door is open, then don't set the social time needed flag, because it may be in the processing of being taken care of
            doorDebug("Total time open is less than required social time (" + (float)socialTimeRequired/millisPerHour + " hours), but door is open.  Waiting.");
          }
        } else {
          clearStatus(status, SOCIALNEEDED);
        }
      }

      lastDoorCheck = curTimeMillis;
      doorDebug("");
    }
  }

  Queue<Long> getSubQueueTail(Queue<Long> queue, int numElements) {
    // Get numElements number of elements from the tail end of the Queue (the elements that were put in most recently)
    int firstIndex = queue.size() - numElements; // Index of the first element to place into the new queue
    Queue<Long> newQueue = new LinkedList<Long>();
    for (int i = 0; i < queue.size(); i++) {
      if (i >= firstIndex) {
        long element = queue.remove();
        queue.add(element); // Place element back into the tail of the old queue
        newQueue.add(element);
      } else {
        // If firstIndex has not been reached yet, just continue cycling through the Queue
        queue.add(queue.remove());
      }
    }
    return newQueue;
  }

  int getNumElementsThatCumSumToVal(Queue<Long> queue, long val) {
    // This function will calculate a running sum through the queue.  Once that running sum has reached up to (and over) val, this function will return the index
    long runSum = 0;
    int index = -1; // Index to return
    boolean valReached = false;
    for (int i = 0; i < queue.size(); i++) {
      long thisLong = queue.remove(); // Get the next value

      if (runSum >= val && !valReached) { // If the running sum JUST went over the val
        index = i; // Record the index at which this happened
        valReached = true; // Then, must continue going through loop because otherwise the queue would be partially rearranged (however, no need to continue the running sum)
      } else {
        runSum += thisLong; // If val has not yet been reached, add the value to the running sum
      }

      queue.add(thisLong); // Add the value back into the queue
    }
    return index;
  }

  int queueSumFalseDestroy(Queue<Boolean> queue) {
    // This method will return a sum of the number of false's in the queue, and then leave the queue empty after
    int queueSize = queue.size();
    int runSumFalse = 0; // Running sum of the falses in the queue
    for (int i = 0; i < queueSize; i++) {
      if (!queue.remove()) {
        // If the removed item is a "false", add to the running sum
        runSumFalse++;
      }
    }
    return runSumFalse;
  }

  long queueSum(Queue<Long> queue) {
    // This method will return a sum of the elements in the queue
    long runSum = 0; // Running sum of the elements in the queue
    for (int i = 0; i < queue.size(); i++) {
      long thisVal = queue.remove(); // Remove the head of the queue, and store it
      runSum += thisVal; // Add the value onto the running sum
      queue.add(thisVal); // Add the element back onto the queue (onto the tail)
    }
    return runSum;
  }

  void drawBoxDiagram() {
    // Outer box
    rectMode(CENTER);
    stroke(0);
    fill(100);
    //rect(boxDiagramX, boxDiagramY, boxDiagramWidth, boxDiagramHeight);
    bezierRect(boxDiagramX, boxDiagramY, boxDiagramWidth, boxDiagramHeight, -2, -2);

    // Warning box
    int warningBufferWidth = 15;
    int warningBufferHeight = 25;
    fill(warningStatusColor());
    rect(boxDiagramX, boxDiagramY, boxDiagramWidth - warningBufferWidth*2, boxDiagramHeight - warningBufferHeight*2);

    // Inner box
    noStroke();
    int doorBufferWidth = 35;
    int doorBufferHeight = 45;
    fill(doorStatusColor());
    rect(boxDiagramX, boxDiagramY, boxDiagramWidth - doorBufferWidth*2, boxDiagramHeight - doorBufferHeight*2);
    stroke(0);
  }

  void drawPlot() {    
    // Take care of any warning states
    actOnWarnings();

    // Generate the traces for any that will react to warnings (so that the blinking will appear)
    warnTrace.generate();
    tempQuickTrace.generate();
    humidityQuickTrace.generate();

    // Draw the plots
    rectMode(CORNER);
    drawMiniPlot();
    graph.draw();
    gSecondY.draw();
  }

  void actOnWarnings() {
    // Act on any flags in the status variable
    // Act on any error states
    // Set the low value warning to be on or off for the graph (must be updated each time)
    warnTrace.setLowWarning(testFlag(status, TEMPLOW) | testFlag(status, HUMIDITYLOW));

    // Set the high value warning to be on or off for the graph (must be updated each time)
    warnTrace.setHighWarning(testFlag(status, TEMPHIGH) | testFlag(status, HUMIDITYHIGH));

    // Set warning states for temperature
    tempQuickTrace.setWarning(testFlag(status, TEMPLOW) | testFlag(status, TEMPHIGH));

    // Set warning states for humidity
    humidityQuickTrace.setWarning(testFlag(status, HUMIDITYLOW) | testFlag(status, HUMIDITYHIGH));

    // Contact anyone who should be notified
    // Start the warning process if the status flag is not clear
    setupEmailIfNeeded();
  }

  void setupEmailIfNeeded() {
    if (!flagIsClear(status) && birdInBox) {
      // If there are some warnings, and a bird is in the box, build up a message to send to the Emailer
      if (lastStatus != status) {
        // If a new warning has occurred, rebuild the message
        // Otherwise, just send the same message as last time (don't change curMessage)

        curWarningMessage = "";
        String nL = "\r\n"; // New line character
        if (testFlag(status, TEMPLOW)) {
          curWarningMessage += "Temperature too low" + nL;
        }
        if (testFlag(status, TEMPHIGH)) {
          curWarningMessage += "Temperature too high" + nL;
        }
        if (testFlag(status, HUMIDITYLOW)) {
          curWarningMessage += "Humidity too low" + nL;
        }
        if (testFlag(status, HUMIDITYHIGH)) {
          curWarningMessage += "Humidity too high" + nL;
        }
        if (testFlag(status, SOCIALNEEDED)) {
          curWarningMessage += "Social time period needed" + nL;
        }
        if (testFlag(status, DOOROPENTOOLONG)) {
          curWarningMessage += "Door has been open for too long" + nL;
        }
      }

      emailDebug("Warning exists, notifying Emailer about: " + curWarningMessage);
    }

    if (birdInBox) {
      // If there is a bird in the box (i.e. there exists an emailer), send the message to the Emailer
      emailer.checkIfEmailIsNeeded(!flagIsClear(status), curWarningMessage);
    }

    // Keep track of how the status flag changes
    lastStatus = status;
  }

  void setValueLabelColors() {
    color tempLabelColor = tempColor;
    if (testFlag(status, TEMPLOW) | testFlag(status, TEMPHIGH)) {
      tempLabelColor = blink(tempColor);
    }

    color humidityLabelColor = humidityColor;
    if (testFlag(status, HUMIDITYLOW) | testFlag(status, HUMIDITYHIGH)) {
      humidityLabelColor = blink(humidityColor);
    }

    tempLabel.setColor(tempLabelColor);
    humidityLabel.setColor(humidityLabelColor);
  }

  void drawMiniPlot() {
    miniGraph.draw();

    // Draw a background-colored rectangle to block the x-axis of the graph
    int labelHeight = 18;
    int labelNegativeX = 10;
    rectMode(CORNER);
    stroke(g.backgroundColor);
    fill(g.backgroundColor);

    rect(miniPlotX - labelNegativeX, plotY + plotHeight, miniPlotWidth + labelNegativeX, labelHeight);
  }

  class buttonListener implements CallbackListener {
    public void controlEvent(CallbackEvent theEvent) {
      if (theEvent.getAction() == ControlP5.ACTION_PRESS) {
        // Clear all background colors
        for (int i = 0; i < allButtons.size(); i++) {
          allButtons.get(i).setColorBackground(normalBackgroundColor);
        }

        theEvent.getController().setColorBackground(GREEN); // Set this buttons' background to be green

        // Set the time-scale
        plotTimeScale = (int)theEvent.getController().getValue();
        sendDataToTrace();
      }
    }
  }

  class textListener implements ControlListener {
    public void controlEvent(ControlEvent theEvent) {
      if (theEvent.isAssignableFrom(Textfield.class)) {
        setName(theEvent.getStringValue());
      }
    }
  }
};

void bezierRect(float x, float y, float w, float h, float xr, float yr) {
  // Courtesy of davbol of processing.org forum
  /**
   @param x  x-coordinate of center
   @param y  y-coordinate of center
   @param w  width of the rectangle
   @param h  height of the rectangle
   @param xr radius to inset x-coordinate corners for bezier controls (may be negative to "outset")
   @param yr radius to inset y-coordinate corners for bezier controls (may be negative to "outset")
   */

  float w2=w/2f, h2=h/2f;
  beginShape();
  vertex(x, y-h2);
  bezierVertex(x+w2-xr, y-h2, x+w2, y-h2+yr, x+w2, y);
  bezierVertex(x+w2, y+h2-yr, x+w2-xr, y+h2, x, y+h2);
  bezierVertex(x-w2+xr, y+h2, x-w2, y+h2-yr, x-w2, y);
  bezierVertex(x-w2, y-h2+yr, x-w2+xr, y-h2, x, y-h2);
  endShape();
}