// Declare enum-like variables
final static int CSV = 0;
//int NEWFILETYPE = 1; // ADD: New file-type here

// The dataWriter class is the front-end for writing csv files.
// It simply accepts the directory and base-name for the file that will be opened and written to,
// and then interfaces with the fileManager to ensure that the file is formatted correctly
// T is the same T below for the file class, which is the format of data that the file will receive when writing data
abstract class dataWriter<T> {
  final protected int fileType; // The filetype of the new dataWriter (ADD: new dataWriters must pass this value through super())
  String directory; // The directory into which the file will be created
  String fileBaseName; // The base name used to identify this file from others
  String header; // The header for the file
  file currentFile; // The file that this dataWriter will use
  fileManager fManager; // The file manager that this csvWriter will interact with
  boolean haveFile = false; // Does the dataWriter currently have a file?

  dataWriter(String directoryIn, String fileBaseNameIn, String headerIn, fileManager fManagerIn, int fileTypeIn) {
    // Record all inputs
    fileType = fileTypeIn;
    directory = directoryIn;
    header = headerIn;
    fManager = fManagerIn;
    fileBaseName = fileBaseNameIn;

    // Write a header to the file (will automatically open, write header, and close file)
    new writeLineObject();
  }

  // Public methods for writing and closing files
  public void writeLine(T inputData) {
    new writeLineObject(inputData);
  }

  public void writeLine(T inputData, String timeString) {
    new writeLineObject(inputData, timeString);
  }
  public void closeFile() {
    //ioDebug("Closing File...");
    if (haveFile) {
      fManager.closeFile(currentFile); // Have the file manager close the file
    } else {
      errorReporting("Attempting to close a closed file.  Ignoring.");
    }
    haveFile = false;
  }

  // Private methods for file managment
  protected abstract void doWriteLine(T inputData); // Method for writing a line to the file (called by doWriteData(), after opening the file)
  protected abstract void doWriteLine(T inputData, String timeString); // Method for writing a line to the file (called by doWriteData(), after opening the file)
  // Do all processes involved with simply opening a file for writing
  private void openFile() {
    //ioDebug("Open File...");
    // Create the file name with the given base-name, putting it into the given directory, and adding the fileBaseName
    String fileDateString = str(year()) + "_" + str(month()) + "_" + str(day());
    String fileName = directory + File.separator + fileBaseName + "_" + fileDateString + ".csv";

    // Check to see if this file exists already
    boolean fileExists = (new File(fileName).isFile());

    // Use the file manager to open a new file
    currentFile = fManager.openFile(fileName, fileType);
    haveFile = true;

    // Give user feedback
    if (!fileExists) {
      ioDebug("Creating new file");
      currentFile.writeHeader(header); // Write the header for the new file
    } else {
      ioDebug("Appending to file");
    }
  }

  // Everything required to create a new file or ensure that one exists (used by writeFileObject)
  private void doOpenFile() {
    // Open the file
    openFile();

    // Close the file
    closeFile();
  }

  // Everything required to write new data to a file (used by writeFileObject)
  private void doWriteData(T inputData) {
    // Open the file
    openFile();

    // Write data to the file, according to the extending class (ex. csvWriter)
    doWriteLine(inputData);

    // Close the file
    closeFile();
  }

  private void doWriteData(T inputData, String timeString) {
    // Open the file
    openFile();

    // Write data to the file, according to the extending class (ex. csvWriter)
    doWriteLine(inputData, timeString);

    // Close the file
    closeFile();
  }

  private class writeLineObject implements Runnable {
    Thread thread;
    T writingData;
    String timeString;
    boolean writeTime = false;
    boolean writeDataToFile = true; // Boolean used to keep track of whether or not data will be written to the file, or a header

    writeLineObject() {
      writeDataToFile = false; // This writer will be writing header information to the file
      createThread();
    }

    writeLineObject(T writingDataIn) {
      // This fileWriter will be writing new data to the file
      writingData = writingDataIn;
      createThread();
    }

    writeLineObject(T writingDataIn, String timeStringIn) {
      // This fileWriter will be writing new data to the file
      writingData = writingDataIn;
      writeTime = true;
      timeString = timeStringIn;
      createThread();
    }

    void createThread() {
      thread = new Thread(this);
      thread.start();
    }

    void run() {
      if (writeDataToFile) {
        // If writing data, do so
        if (writeTime) {
          doWriteData(writingData, timeString);
        } else {
          doWriteData(writingData);
        }
      } else {
        // If writing the header, do so
        doOpenFile();
      }
    }
  }
}

// It will create only one file per day
class csvWriter extends dataWriter<List<Float>> {
  //int currentFileDate;  // The date of the file that was last written to

  csvWriter(String directoryIn, String fileBaseNameIn, String[] headers, fileManager fManagerIn) {
    // Construct with dataWriter()
    super(directoryIn, fileBaseNameIn, String.join(",", headers), fManagerIn, CSV); // Combine all headers into a csv list
  }

  // Public interface for writing a line to csv
  void doWriteLine(List<Float> inputData) {
    currentFile.writeData(inputData);
  }

  void doWriteLine(List<Float> inputData, String timeString) {
    currentFile.writeData(inputData, timeString);
  }
}

// The file manager will be responsible for managing every file in the program, making sure that each file is only being written to by one dataWriter at a time.
// It will open files for the user, ensuring that no two "file" objects point to the same actual file in the computer
// It will also close files for the user, keeping track of which files are curently open
// The fileManager only needs to be used during file openning and closing.  Otherwise, the returned file object may be interacted with directly
class fileManager {
  List<file> fileList; // List of files that are currently being used by some part of the program

  fileManager() {
    fileList = new ArrayList<file>();
  }

  public file openFile(String fileName, int T) {
    file fileToReturn;
    synchronized(fileList) {
      // Determine if the fileManager has this file in the array
      int fileInd = findFileInArray(fileName);
      if (fileInd != -1) {
        // The file exists in the array, so return it
        fileToReturn = fileList.get(fileInd);
      } else {
        // The file does not exist in the array, so open it and add it
        fileToReturn = openFileType(fileName, T);

        // Add this to the fileList
        fileList.add(fileToReturn);
      }
    }

    // Return this file to the calling function
    return fileToReturn;
  }

  public boolean closeFile(file fileToClose) {
    boolean success;
    synchronized(fileList) {
      fileToClose.closeFile(); // Close the file
      success = fileList.remove(fileToClose); // Remove the specified file from the FileManager's list
    }
    return success;
  }

  private file openFileType(String fileName, int T) {
    file fileToOpen;
    // Actually open a file of type T
    switch (T) {
      case (CSV):
      fileToOpen = new csvFile(fileName);
      break;
      //case newType: // ADD: New file type to open
      //  fileToOpen = new newFileTypeFile();
      //  break;
    default:
      fileToOpen = new csvFile(fileName); // Create a csv file, if T is not a recognized file type
    }
    return fileToOpen;
  }

  private int findFileInArray(String fileName) {
    int fileInd = -1;
    synchronized(fileList) {
      for (int i = 0; i < fileList.size(); i++) {
        // If this file's name matches the filename that was input
        if (fileList.get(i).getFileName().equals(fileName)) {
          fileInd = i;
          break;
        }
      }
    }
    return fileInd;
  }
}

// The abstract file class will represent a given file in some directory, with the functionality of mutually exclusive writing.
public abstract class file<T> {
  protected fileManager fManager; // The file manager that controls this files (should report closings to it)
  protected FileWriter fileWriter; // The low-level java object that will be responsible for adding lines onto the file
  protected String fileName; // The file's name
  protected final String newLineCharacter = System.lineSeparator(); // String that contains the new line character for this system 

  file(String fileNameIn) {
    fileName = fileNameIn;
    fileWriter = openFile();
  }

  // Public interface for getting the file's name
  public String getFileName() {
    return fileName;
  }

  // Public interfaces for writing data to the file.  Simply instantiate a fileWriter object, initialized with the required data (or nothing, if writing a header)
  public abstract void writeData(T writingData);
  public abstract void writeData(T writingData, String timeString); // Write data plus a string (representing the time) to the file
  public void writeHeader(String header) {
    //new writeLineObject(header); // Warning can be ignored, as all file writing will occur in the thread created by the constructor of this fileWriter class
    writeLineString(header);
  }

  // Private method for opening a new file
  protected FileWriter openFile() {
    // Open a FileWriter object using the filename provided
    FileWriter fileWriterOut = null;
    synchronized(file.this) {
      ioDebug("Opening File: " + fileName);
      try {
        fileWriterOut = new FileWriter(fileName, true); // Open the file "filename", with appending
      } 
      catch (IOException e) {
        errorReporting("Error on opening file:");
        errorReporting(e.toString());
        errorReporting("");
      }
    }

    return fileWriterOut;
  }

  // Public method for closing this file
  public boolean closeFile() {
    boolean successfulClosing = false;
    synchronized(file.this) {
      ioDebug("Closing file: " + fileName);

      // Close the fileWriter
      try {
        fileWriter.close();
      } 
      catch (IOException e) {
        errorReporting("Error on closing file:");
        errorReporting(e.toString());
        errorReporting("");
      }
    }
    return successfulClosing;
  }

  // Private methods for writing lines to file
  protected void writeLineString(String inputLine) {
    String fullLine = inputLine + newLineCharacter;
    synchronized (fileWriter) {
      // Any time that data will be written to the file, it must come through this method.  Therefore, synchronize on the fileWriter object
      ioDebug("Writing line: " + inputLine);
      try {
        fileWriter.write(fullLine, 0, fullLine.length());
      } 
      catch (IOException e) {
        errorReporting("Error on writing line");
        errorReporting(e.toString());
        errorReporting("");
      }
    }
  }
};

// A Class that extends the file class, specifically using it to write csv files with data from a trackedParametersFloat object
class csvFile extends file<List<Float>> {
  csvFile(String fileName) {
    super(fileName);
  }

  void writeData(List<Float> writingData, String timeString) {
    // Load the data into a StringBuilder
    StringBuilder sb = new StringBuilder();

    // First, add time string
    sb.append(timeString + ",");

    // Next, add data
    for (int i = 0; i<writingData.size(); i++) {
      sb.append(String.format("%.1f", writingData.get(i)));
      if (i < (writingData.size() - 1)) {
        sb.append(","); // If it is not the last line, add a comma
      }
    }

    // Write a line to the file
    writeLineString(sb.toString());
  }

  void writeData(List<Float> writingData) {
    // Load the data into a StringBuilder
    StringBuilder sb = new StringBuilder();
    for (int i = 0; i<writingData.size(); i++) {
      sb.append(writingData.get(i).toString());
      if (i < (writingData.size() - 1)) {
        sb.append(","); // If it is not the last line, add a comma
      }
    }

    // Write a line to the file
    writeLineString(sb.toString());
  }
}