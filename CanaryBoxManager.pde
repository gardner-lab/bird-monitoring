// Graphing libraries //<>//
import org.gwoptics.*;
import org.gwoptics.gaussbeams.*;
import org.gwoptics.graphics.*;
import org.gwoptics.graphics.camera.*;
import org.gwoptics.graphics.colourmap.*;
import org.gwoptics.graphics.colourmap.presets.*;
import org.gwoptics.graphics.graph2D.*;
import org.gwoptics.graphics.graph2D.backgrounds.*;
import org.gwoptics.graphics.graph2D.effects.*;
import org.gwoptics.graphics.graph2D.traces.*;
import org.gwoptics.graphics.graph3D.*;
import org.gwoptics.graphicsutils.*;
import org.gwoptics.mathutils.*;
import org.gwoptics.testing.*;

//GUI libraries
import controlP5.*;

// Serial libraries
import processing.serial.*;

// Java libraries
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.util.*;

// Set enum-like variables
final static int CLOSED = 0;
final static int OPEN = 1;
final static int WARNING = 2;
final static int LF = 10; // Line-feed in ASCII
final static int MINUTES = 0;
final static int HOURS = 1;
final static int DAYS = 2;
final static int CONNECTED = 0;
final static int DISCONNECTED = 1;
final static int NUMBOXMISMATCH = 2;
final static int bytesPerFloat = 4; // Number of bytes per floating point value
final static int bytesPerInt = 2; // Number of bytes per int value

final color GREEN = color(0, 150, 0);
final color YELLOW = color(250, 250, 0);
final color RED = color(250, 0, 0);
final color BLUE = color(0, 0, 250);

// Set global objects
birdBoxManager manager;
int numTrackedParameters = 3; // Number of parameters tracked by the Arduino (currently 3: temp, humidity, and door closing)

void setup() {
  // Set parameters
  int fetchTime = 2000; // Number of milliseconds to wait before getting new data 
  int baudRate = 57600; // Baudrate for the serial connection

  // Set up GUI
  // Create window
  size(1024, 600, OPENGL);
  String arduinoPortName = "/dev/cu.usbserial-A700flOS";
  
  // Create array of bird boxes
  manager = new birdBoxManager(arduinoPortName, baudRate, int(.5*width), int(.5*height), int(width), height, this);

  // Configure manager
  manager.setFetchTime(fetchTime);

  // Tests
  String[] birdNames = {"hello", "world", "please"};
  manager.setName(0, birdNames[0]);
  manager.setName(1, birdNames[1]);
  manager.setName(2, birdNames[2]);
  //manager.setDoorClosed(0, true);
  //manager.setDoorClosed(1, false);
  //manager.setDoorClosed(2, false);
  //manager.setStatus(2, 1);
};

void draw() {
  // Check the serial line for new input
  manager.getNewData();

  // Draw all GUI elements
  background(200); // Clear the screen
  manager.draw();
};