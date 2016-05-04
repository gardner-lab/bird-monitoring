// Class that represents each bird box.  Has information on each box, as well as the methods to draw the display for each box
class birdBox {
  // Manager
  birdBoxManager manager;

  // Experimental parameters
  String birdName;
  int status;
  float temperature;
  float humidity;
  boolean doorClosed;

  // Experimental data
  // There are three sets of data being kept for each parameter, one each for minutes, hours, and days time scale
  Queue<Float> tempDataMin; // Data for temperature, minute scale
  Queue<Float> humidityDataMin; // Data for humidity, minute scale
  Queue<Float> tempDataHour; // Data for temperature, hour scale
  Queue<Float> humidityDataHour; // Data for humidity, hour scale
  Queue<Float> tempDataDay; // Data for temperature, day scale
  Queue<Float> humidityDataDay; // Data for humidity, day scale

  // Information on each data set
  int maxNumData; // Maximum number of data points
  int numDataMin = 0; // Number of data points
  int numDataHour = 0; // Number of data points
  int numDataDay = 0; // Number of data points
  float minPeriod; // Period between data points
  float hourPeriod; // Period between data points
  float dayPeriod; // Period between data points
  float lastHourUpdate; // The time at which the last hour data update occurred
  float lastDayUpdate; // The time at which the last day data update occurred 
  float firstTimeMin = 0; // The time value associated with the first data point in the min data
  float firstTimeHour = 0; // The time value associated with the first data point in the hour data
  float firstTimeDay = 0; // The time value associated with the first data point in the day data
  int plotTimeScale = MINUTES; // The current scale that the plot is using
  // Drawing parameters
  // Whole space
  int allHeight;
  int allWidth;
  int leftX;
  int rightX;

  // Box Diagram
  int boxDiagramX;
  int boxDiagramY;
  int boxDiagramHeight;
  int boxDiagramWidth;

  // Plot Diagram
  int plotX;
  int plotY;
  int plotHeight;
  int plotWidth;
  int plotScale; // Which scale will be plotted (minutes, hours, days)
  dataTrace tempTrace; // Trace responsible for plotting temperature data
  dataTrace humidityTrace; // Trace responsible for plotting humidity data
  Graph2D graph; // Graph object

  birdBox(int boxXIn, int boxYIn, int widthIn, int heightIn, birdBoxManager managerIn) {
    // These parameters can be adjusted to change the shape of the display
    float plotWidthFrac = .25; // Center of plot as a fraction of the screen (will fill to the left side)
    float boxDiagramWidthFrac = .85; // Center of box diagram as a fraction of the screen (will fill to right side)
    float numHours = 6; // Number of hours to see on hour plot
    float numDays = 5; // Number of days to see on day plot

    allHeight = heightIn;
    allWidth = widthIn;
    leftX = (boxXIn - allWidth/2); // Position of left side
    rightX = (boxXIn + allWidth/2);  // Position of right side

    // Calculate drawing parameters
    // Box diagram
    boxDiagramX = (int) (leftX + boxDiagramWidthFrac*allWidth);
    boxDiagramY = boxYIn;
    boxDiagramHeight = allHeight;
    boxDiagramWidth = (int)((1 - boxDiagramWidthFrac)*2*allWidth); // (1 - boxDiagramWidthFrac)*allWidth gives "radius" of rectangle

    // Plot
    int plotVertTicksRoom = 30;
    int plotHorzTicksRoom = 40;
    plotHeight = allHeight - plotVertTicksRoom;
    plotWidth = (int)(plotWidthFrac*2*allWidth - plotHorzTicksRoom); // plotWidthFrac*allWidth gives "radius" of rectangle
    plotX = leftX + plotHorzTicksRoom;
    plotY = boxYIn - plotHeight/2;
    plotScale = MINUTES;
    manager = managerIn; // Record the pointer to the manager

    // Set status to closed to start
    doorClosed = true;

    // Initialize data traces
    color tempColor = RED;
    color humidityColor = GREEN;
    tempTrace = new dataTrace(tempColor);
    humidityTrace = new dataTrace(humidityColor);

    // Initialize graph
    graph = new Graph2D(manager.sketchPApplet, plotWidth, plotHeight, true);
    graph.position.x = plotX;
    graph.position.y = plotY;
    float xAxisMax = pixelsToMinutes(plotWidth);
    float yAxisMax = 100;
    graph.setXAxisTickSpacing(xAxisMax/5);
    graph.setYAxisTickSpacing(yAxisMax/5);
    graph.setYAxisLabel("");
    graph.setXAxisLabel("");
    graph.setXAxisMin(0f);
    graph.setYAxisMin(0f);
    graph.setXAxisMax(xAxisMax);
    graph.setYAxisMax(yAxisMax);
    graph.addTrace(tempTrace); // Add the temperature trace to the graph
    graph.addTrace(humidityTrace); // Add the humidity trace to the graph

    // Intialize Data Lists (Queues)
    tempDataMin = new LinkedList<Float>(); // Data for temperature, minute scale
    humidityDataMin = new LinkedList<Float>(); // Data for humidity, minute scale
    tempDataHour = new LinkedList<Float>(); // Data for temperature, hour scale
    humidityDataHour = new LinkedList<Float>(); // Data for humidity, hour scale
    tempDataDay = new LinkedList<Float>(); // Data for temperature, day scale
    humidityDataDay = new LinkedList<Float>(); // Data for humidity, day scale
    maxNumData = plotWidth; // Set the number of data points to be equal to the number of pixels in the plot
    minPeriod = manager.fetchTime/1000; // Period between each data point for minutes
    //println("Plot: " + plotWidth*minPeriod + " seconds, "+ (float)(plotWidth*minPeriod/60) + " minutes");

    // Calculate the period between data points for hours and days (minutes is defined as Processing's sampling rate for getting data from the Arduino)
    float numMinutes = (plotWidth*minPeriod/60); // Number of minutes that appears on minute plot
    hourPeriod = minPeriod*(numHours/(numMinutes/60)); // Modify if number of minutes per hour changes
    dayPeriod = hourPeriod*(numDays/(numHours/24)); // Modify if number of hours per day changes (23.9 hours [exact number of hours per day] ~ 24 hours, so bite me)
    lastHourUpdate = -2*hourPeriod; // Initialize so that an update occurs
    lastDayUpdate = -2*dayPeriod; // Initialize so that an update occurs
  }

  void setNewData(float[] newData, int curTime) {
    // Add graphable data to all data lists
    addDataMin(newData);
    addDataHour(newData, curTime);
    addDataDay(newData, curTime);

    // Set the state of the door
    switch ((int)newData[numTrackedParameters - 1]) {
    case 1:
      doorClosed = true;
      break;
    case 0:
      doorClosed = false;
      break;
    }

    // Send the newest data to the dataTrace object, so that it will be plotted on the next draw() cycle
    sendDataToTrace();
  };

  void sendDataToTrace() {
    Queue<Float> tempDataNew;
    Queue<Float> humidityDataNew;
    float firstTime = firstTimeMin;
    float dataIncrement = minPeriod;
    switch (plotTimeScale) {
    case MINUTES:
      tempDataNew = tempDataMin;
      humidityDataNew = humidityDataMin;
      firstTime = firstTimeMin;
      dataIncrement = minPeriod;
      break;
    case HOURS:
      tempDataNew = tempDataHour;
      humidityDataNew = humidityDataHour;
      firstTime = firstTimeHour;
      dataIncrement = hourPeriod;
      break;
    case DAYS:
      tempDataNew = tempDataDay;
      humidityDataNew = humidityDataDay;
      firstTime = firstTimeDay;
      dataIncrement = dayPeriod;
      break;
    default:
      tempDataNew = tempDataMin;
      humidityDataNew = humidityDataMin;
      break;
    }

    tempTrace.setData((List)tempDataNew, firstTime, dataIncrement);
    humidityTrace.setData((List)humidityDataNew, firstTime, dataIncrement);
  }

  void addDataMin(float[] newData) {
    // Ensure that the queue is always the correct size
    if (numDataMin >= maxNumData) {
      tempDataMin.remove();
      humidityDataMin.remove();
      numDataMin--;
      firstTimeMin += minPeriod; // Move the graph over one increment
    }

    // Add graphable data
    tempDataMin.add(new Float(newData[0]));
    humidityDataMin.add(new Float(newData[1]));

    // Increment the number of data points
    numDataMin++;
  };

  void addDataHour(float[] newData, int curTime) {
    // Add data if the required time has passed
    if (curTime >= ( lastHourUpdate + hourPeriod)) {
      // Ensure that the queue is always the correct size
      if (numDataHour >= maxNumData) {
        tempDataHour.remove();
        humidityDataHour.remove();
        numDataHour--;
        firstTimeHour += hourPeriod; // Move the graph over one increment
      }

      // Add graphable data
      tempDataHour.add(new Float(newData[0]));
      humidityDataHour.add(new Float(newData[1]));

      // Record that update occurred
      lastHourUpdate = millis();

      // Increment the number of data points
      numDataHour++;
    }
  };

  void addDataDay(float[] newData, int curTime) {
    // Add data if the required time has passed
    if (curTime >= (lastDayUpdate + dayPeriod)) {
      // Ensure that the queue is always the correct size
      if (numDataDay >= maxNumData) {
        tempDataDay.remove();
        humidityDataDay.remove();
        numDataDay--;
        firstTimeDay += dayPeriod; // Move the graph over one increment
      }

      // Add graphable data
      tempDataDay.add(new Float(newData[0]));
      humidityDataDay.add(new Float(newData[1]));

      // Record that update occurred
      lastDayUpdate = millis();

      // Increment the number of data points
      numDataDay++;
    }
  };

  float pixelsToMinutes(float numPixels) {
    float numSeconds = (numPixels*manager.fetchTime)/1000;
    float numMinutes = numSeconds/60;
    return numMinutes;
  }

  float pixelsToHours(float numPixels) {
    return (pixelsToMinutes(numPixels)/60);
  }

  float pixelsToDays(float numPixels) {
    return (pixelsToHours(numPixels)/24);
  }

  void setStatus(int statusIn) {
    status = statusIn;
  }

  void setDoorClosed(boolean doorClosedIn) {
    doorClosed = doorClosedIn;
  }

  void setName(String birdNameIn) {
    birdName = birdNameIn;
  }

  color doorStatusColor() {
    color c;
    if (!this.doorClosed) {
      c = YELLOW;
    } else {
      c = GREEN;
    }
    return c;
  }

  color warningStatusColor() {
    color c = doorStatusColor(); // Take on the door's status color, unless something is wrong
    int flashRate = 1000; // Flash period (in milliseconds)
    if (status > 0) {
      // If there is something wrong
      if ((millis()%flashRate) < flashRate/4) {
        // Blink according to a rate
        c = RED;
      }
    }

    return c;
  }

  void draw() {
    // Draw the box diagragm on the right side of the screen
    drawBoxDiagram();

    // Draw plots and other information
    drawPlot();
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

    // Draw Text
    // ADD AN EDITABLE TEXT BOX, OR SOME WAY TO CHANGE THE NAME OF THE BIRD
    // fill(0);
    // textAlign(CENTER);
    // text(, boxX, boxY);
  }

  void drawPlot() {
    rectMode(CORNER);
    graph.draw();
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