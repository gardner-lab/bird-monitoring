// Graphing libraries //<>// //<>// //<>//
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

//GUI libraries
import controlP5.*;

// Serial libraries
import processing.serial.*;

// Java libraries
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.text.SimpleDateFormat;
import java.io.*;
import java.util.*;
import javax.mail.*;
import javax.activation.*;
//import com.sun.*;

// Set mutually exclusive enum-like variables
final static int CLOSED = 0;
final static int OPEN = 1;
final static int WARNING = 2;
final static int LF = 10; // Line-feed in ASCII
final static int MINUTES = 0;
final static int HOURS = 1;
final static int DAYS = 2;

// Set non-exclusive enum-like values (flags)
final static int TEMPLOW = (int)pow(2, 0);
final static int TEMPHIGH = (int)pow(2, 1);
final static int HUMIDITYLOW = (int)pow(2, 2);
final static int HUMIDITYHIGH = (int)pow(2, 3);
final static int SOCIALNEEDED = (int)pow(2, 4);
final static int DOOROPENTOOLONG = (int)pow(2, 5); // More than 12 hours
final static int DISCONNECTED = (int)pow(2, 0);
final static int NUMBOXMISMATCH = (int)pow(2, 1);
final static int NUMPARAMSMISMATCH = (int)pow(2, 2);

// Set constants that are used
final static int bytesPerFloat = 4; // Number of bytes per floating point value
final static int bytesPerInt = 2; // Number of bytes per int value
final static int millisPerSec = 1000; // Modify if number of milliseconds per second changes (made into variable so that next lines are more clear) 
final static int secPerMin = 60; // Modify if number of seconds per minute changes
final static int minPerHour = 60; // Modify if number of minutes per hour changes
final static int hourPerDay = 24; // Modify if number of hours per day changes (23.9 hours [exact number of hours per day]~24 hours, so bite me)
final static int millisPerMin = millisPerSec*secPerMin; 
final static int millisPerHour = millisPerMin*minPerHour;
final static int millisPerDay = millisPerHour*hourPerDay;

final color GREEN = color(0, 150, 0);
final color YELLOW = color(250, 250, 0);
final color RED = color(250, 0, 0);
final color BLUE = color(0, 0, 250);

final int WINDOWS = 0;
final int MAC = 1;

// Set global objects
birdBoxManager manager;
int numTrackedParameters = 3; // Number of parameters tracked by the Arduino (currently 3: temp, humidity, and door closing)
SimpleDateFormat sdf = new SimpleDateFormat("kk:mm:ss"); // This is the format for time in the output files
SimpleDateFormat date = new SimpleDateFormat("MM/dd/yy"); // This is the format for dates in the x-axis of the plot

// Set debug booleans
boolean doSerialDebug = false;
boolean doDataDebug = false;
boolean doRawDataDebug = false;
boolean doPlotDebug = false;
boolean doIODebug = false;
boolean doDoorDebug = false;
boolean doEmailDebug = true;
boolean doErrorReporting = true;
boolean fakeArduinoTest = false; // (TO-DO: finish implementing this debug tool!) If no Arduino is connected, have the Processing software immitate having one connected (sending data through)

// Directory in which the program will be based (used for file input/output), and information on the operating system
String mainDirectory; // The main directory of the program
String sep = File.separator; // The character that separates directories
int currentOS; // The current operating system

void setup() {
  // Set parameters
  int fetchTime = 2000; // Number of milliseconds to wait before getting new data
  int baudRate = 57600; // Baudrate for the serial connection
  String arduinoPortName;

  // Determine which operating system is being used
  if (System.getProperty("os.name").startsWith("Windows")) {
    currentOS = WINDOWS;
  } else {
    currentOS = MAC;
  }

  // Set the main directory
  if (currentOS == WINDOWS) {
    mainDirectory = "C:"+sep+"Users"+sep+"Nathan"+sep+"Documents"+sep+"bird_monitoring"+sep;
    arduinoPortName = "COM4";
  } else {
    mainDirectory = sep+"Users"+sep+"sambrown"+sep+"Documents"+sep+"Classes"+sep+"Gardner Rotation"+sep+"bird-monitoring"+sep;
    arduinoPortName = "/dev/cu.usbserial-A700flOS";
  }

  // Check if the main directory exists (if not, use the standard user pathway)
  if (!(new File(mainDirectory).exists())) {
    // Set the main path to be the user's main directory
    errorReporting("Could not find directory \"" + mainDirectory + "\".  Using " + System.getProperty("user.dir") + " instead.");
    mainDirectory = System.getProperty("user.dir");
  }

  // Set up GUI
  // Create window
  size(1024, 600, OPENGL);
  prepareExitHandler(); // Prepare stopping mechanism

  // Create array of bird boxes
  manager = new birdBoxManager(arduinoPortName, baudRate, fetchTime, this);
};

void draw() {
  // Check the serial line for new input
  if (!fakeArduinoTest) {
    manager.getNewData();
  } else {
    manager.getFakeArduinoData(); // Create fake data and pass it down the pipeline
  }

  // Draw all GUI elements
  background(200); // Clear the screen
  manager.draw();
};

void stop() {
  manager.closeFileWriters();
  super.stop();
}

// For handler for effective stopping of the Processing applet
private void prepareExitHandler () {
  // Courtesy of bassnharp and ericosoc of forum.processing.org, originally from romaintaz of StackOverflow
  Runtime.getRuntime().addShutdownHook(new Thread(new Runnable() {
    public void run () {
      try {
        stop();
      } 
      catch (Exception ex) {
        ex.printStackTrace(); // not much else to do at this point
      }
    }
  }
  ));
} 

// Function for making a color blink to another color
color blink(color cNormal) {
  color cWarning = RED;
  int flashRate = 1000; // 1 second
  // cNormal is the standard color, cWarning is the color to which this function will change the output color at a rate of flashRate (in milliseconds)
  color cOut;
  if ((millis()%flashRate) >= flashRate/4) {
    cOut = cNormal;
  } else {
    // Blink according to a rate
    cOut = cWarning;
  }
  return cOut;
}

// Functions used for managing flags
// Functions used for managing flags
boolean testFlag(int bField, int testStatus) {
  // Test the input flag to determine if it contains the status testStatus
  // Only test one flag at a time
  return  (testStatus & bField) == testStatus;
}

boolean flagIsClear(int bField) {
  // Test the input flag to determine if it is clear
  return bField == 0;
}

int setStatus(int bField, int status) {
  // Set status to the bit-field "bField"
  // Multiple flags can be set at once with "flag1 | flag2"
  return bField | status;
}

int clearFlag() {
  return 0;
}

int clearStatus(int bField, int status) {
  // Clear status from the bit-field "bField"
  return bField & ~status;
}

// Debug printing functions
void serialDebug(String str) {
  str = "Serial: " + str;
  if (doSerialDebug) {
    println(str);
  }
}

void dataDebug(String str) {
  str = "Data: " + str;
  if (doDataDebug) {
    println(str);
  }
}

void rawDataDebug(String str) {
  str = "Raw Data: " + str;
  if (doRawDataDebug) {
    println(str);
  }
}

void plotDebug(String str) {
  str = "Plot: " + str;
  if (doPlotDebug) {
    println(str);
  }
}

void ioDebug(String str) {
  str = "IO: " + str;
  if (doIODebug) {
    println(str);
  }
}

void doorDebug(String str) {
  str = "Door: " + str;
  if (doDoorDebug) {
    println(str);
  }
}

void emailDebug(String str) {
  str = "Email: " + str;
  if (doEmailDebug) {
    println(str);
  }
}

void errorReporting(String str) {
  str = "Error: " + str;
  if (doErrorReporting) {
    println(str);
  }
}