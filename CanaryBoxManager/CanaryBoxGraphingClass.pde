class dataTrace extends Blank2DTrace {
  private List<Float> data; // Information to be plotted
  private float firstTime; // Time, in seconds, of the first item of data
  private float dataIncrement; // Time, in seconds, between each item of data
  private color traceColor; // 3 member array that corresponds to RGB color of trace

  public void setData(List dataIn, float firstTimeIn, float dataIncrementIn) {
    data = dataIn;
    firstTime = firstTimeIn;
    dataIncrement = dataIncrementIn;
  }

  dataTrace(color traceColorIn) {
    traceColor = traceColorIn;
    data = new ArrayList<Float>();
  }

  public void TraceDraw(Blank2DTrace.PlotRenderer pr) {
    // Draw the data trace
    pr.canvas.stroke(traceColor);
    float curTime = firstTime;
    for (int i = 0; i<data.size() - 1; i++) {
      // Go through each value in data and plot it on the graph!
      if (data.get(i) >= 0 && data.get(i + 1) >= 0) {
        // If both this data point and the next data point are not errors, then plot the data
        pr.canvas.line(
          pr.valToX(curTime), 
          pr.valToY(data.get(i)), 
          pr.valToX(curTime + dataIncrement), 
          pr.valToY(data.get(i + 1))
          );
        plotDebug("Value, plot location");
        plotDebug("X1: " + curTime + ", " + pr.valToX(curTime));
        plotDebug("X2: " + data.get(i) + ", " + pr.valToY(data.get(i)));
        plotDebug("Y1: " + (curTime + dataIncrement) + ", " + pr.valToX(curTime + dataIncrement));
        plotDebug("Y2: " + data.get(i + 1) + ", " + pr.valToY(data.get(i + 1)));
      }
      curTime += dataIncrement;
    }
    plotDebug("");
  }
};

class quickViewTrace extends Blank2DTrace {
  private color traceColor;
  float data; // Current value for the trace
  int lineThickness = 4; // Thickness of line
  boolean warningOn = false; // Should there be a blinking warning?
  
  quickViewTrace(color traceColorIn) {
    traceColor = traceColorIn;
  }
  
  void setWarning(boolean warningIn) {
    warningOn = warningIn;
  }

  void setData(float newData) {
    data = newData;
  }

  void TraceDraw(Blank2DTrace.PlotRenderer pr) {
    color drawColor = traceColor; // Color that will actually be drawn
    
    if (warningOn) {
      drawColor = blink(traceColor);
    }
    
    pr.canvas.stroke(drawColor);
    pr.canvas.fill(drawColor);

    rectMode(CORNER);
    pr.canvas.rect(
      0, 
      pr.valToY(data), 
      pr.canvas.width, 
      lineThickness
      );
  }
};

class warningTrace extends Blank2DTrace {
  private float warningLowVal; // Low value for parameter
  private float warningHighVal; // High value for parameter
  private color traceColor = color(0); // Normal color for the warning lines
  private boolean warningLowOn = false; // Is there an active low warning?
  private boolean warningHighOn = false; // Is there an active high warning?
  private int pixelPeriod = 5; // Width in pixels of each dash, as well as the distance between each dash
  private int lineThickness = 2; // The thickness of the dotted line
  private float firstTime = 0;

  warningTrace(float warningLowValIn, float warningHighValIn) {
    warningLowVal = warningLowValIn;
    warningHighVal = warningHighValIn;
  }

  void setTime (float firstTimeIn) {
    firstTime = firstTimeIn;
  }

  void setLowWarning(boolean warningLowIn) {
    warningLowOn = warningLowIn;
  }

  void setHighWarning(boolean warningHighIn) {
    warningHighOn = warningHighIn;
  }

  public void TraceDraw(Blank2DTrace.PlotRenderer pr) { 
    float firstTimeX = pr.valToX(firstTime); // First time on graph, translated to pixels
    float curLoc = firstTimeX;
    color warningLineColorHigh = traceColor;
    color warningLineColorLow = traceColor;

    // Select color for each line (may blink if current value is outside of warning lines)
    if (warningHighOn) {
      warningLineColorHigh = blink(traceColor);
    }

    if (warningLowOn) {
      warningLineColorLow = blink(traceColor);
    }

    while ((curLoc + pixelPeriod/2) <= (pr.canvas.width + firstTimeX)) {
      rectMode(CORNER);
      // Top line
      pr.canvas.stroke(warningLineColorHigh);
      pr.canvas.fill(warningLineColorHigh);
      pr.canvas.rect(
        curLoc, 
        pr.valToY(warningHighVal), 
        pixelPeriod, 
        lineThickness
        );

      // Bottom line
      pr.canvas.stroke(warningLineColorLow);
      pr.canvas.fill(warningLineColorLow);
      pr.canvas.rect(
        curLoc, 
        pr.valToY(warningLowVal), 
        pixelPeriod, 
        lineThickness
        );

      // Iterate the current location
      curLoc += 2*pixelPeriod;
    }
  }
}