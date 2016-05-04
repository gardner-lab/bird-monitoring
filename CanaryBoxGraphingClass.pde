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
    pr.canvas.background(150);
    pr.canvas.stroke(traceColor);
    float curTime = firstTime;
    println(data.size());
    for (int i = 0; i<data.size() - 1; i++) {
      // Go through each value in data and plot it on the graph!
      if (data.get(i) >= 0) {
        pr.canvas.line(
          pr.valToX(curTime), 
          pr.valToY(data.get(i)), 
          pr.valToX(curTime + dataIncrement), 
          pr.valToY(data.get(i + 1))
          );
      }
      curTime += dataIncrement;
    }
  }
};