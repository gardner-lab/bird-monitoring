#Canary Box Manager

#Contents
1. Overview of Features
2. Using the program
  1. Initial setup on a new system
  2. Adding a bird to a box
  3. Monitoring a bird/reading the GUI
  4. Modifying the emails associated with a bird
  5. Removing a bird from a box
  6. Retreiving recorded data
3. Parameters which may be adjusted
4. Setting up the hardware
  1. Nomenclature
  2. Setting up a box board
  3. Modifying the power board
  4. Modifying the Arduino headers
  5. Modifying the software (New box is now 4th, etc)
5. Troubleshooting (all warnings, environment or Arduino)
  1. Red flashing GUI (environment warnings)
    1. Temperature too high
    2. Temperature too low
    3. Humidity too high
    4. Humidity too low
    5. Social time needed
    6. Door open too long
  2. Bottom right box is not green (Arduino connection issues)
    1. Yellow box
    2. Red box (Disconnected)
6. Extending the program (To be added)
  1. Overview of Classes
  2. Creating custom classes
  3. Adding more tracked parameters (sensors)
  4. Changing how data is written (change date format, change csvWriter, or make new one)
7. Reference
  1. Output data format (name, each row, each column)
  2. Wire colors
  3. Terms used in the program (plot, mini plot, diagram, trace, graph)

# Overview of Features
This program is intended as a platform to easily monitor the environment inside of bird-box containers.  It is currently configured to keep track of the temperature and humidity of each box, as well as the state of the door (opened/closed).  It then displays this information to the user in an easy to understand way, such that a quick glance at the GUI will tell the user how the bird's environment is doing or if there are any problems, and closer look at the GUI will inform the user of the box's history (over a scale of minutes, hours, or days).  Each parameter's history will also be written to a .csv, one for each individual birdID.  A new .csv will be created every day.
The user will be notified of any problems that may occur within the box via a number of means.  First, red flashing GUI elements will inform the user that something is wrong, and allow them to quicky identify what the problem is.  Next, if a problem has been occurring for longer than some set number of minutes (default is 10), the program will email the user(s) with information related to what the problem is, and when it occurred (then will email them again once the problem has resolved).  The program's current warning states are:

1. Temperature/humidity too high
2. Temperature/humidity too low
3. Door not opened for required social time
4. Door opened for too long consecutively (more than 12 hours)
5. Arduino disconnected
6. Arduino connection problems (incorrect number of boxes/parameters sent from Arduino)

A picture of the GUI:
![CanaryBoxManager GUI](https://github.com/samuelgbrown/bird-monitoring/CanaryBoxManagerGUI.png)
![CanaryBoxManager GUI - Annotated](https://github.com/samuelgbrown/bird-monitoring/CanaryBoxManagerGUI Annotated.png)

# Using the program
##1. Initial setup on a new system
1. Install required software
  1. The software [Processing](https://processing.org/download/?processing) **must** be installed on the monitoring computer.  The process of installing this software should create a directory entitled `Processing/` in the user's `Documents/` directory.
  2. The software [Arduino]must be installed on a system which wishes to modify the Arduino software (used when changing the hardware setup, see "Setting up the hardware")
2. Install the required libraries
  1. The zip-file `Libraries.zip` in this repository should be unziped, and the directory within it should be placed in the directory `Processing/libraries/` that was created during the Processing software install.
3. Install the monitoring software on the computer
  1. Move the `CanaryBoxManager/` directory from this repository to `Processing/` directory.
  2. Create a directory named `bird_monitoring/` in the `Documents` folder for the user.
  3. Place the `birdBoxEmailAddresses.csv` provided in this repository in the `bird_monitoring/` directory
4. Install the monitoring software on the Arduino
  1. **This can only be done on machines which have the [Arduino] software installed.**  Move the `Serial_Test/` directory in this repository to the `Arduino/` directory that was created during the Arduino software install.
  2. Connect the Arduino board to the computer, and open this file in Arduino.  Configure the software to communicate with the Arduino (as of writing, the settings should be: board - Arduino Mega 1280, port - `COM4` (Windows), `/dev/cu.usbserial-A700flOS` (Mac))
  3. Upload the software to the Arduino board using the Upload button

##2. Adding a bird to a box
Adding a bird to be monitored by the program occurs in three steps.

1. Install hardware in the box, if it has not been done already (See "[Setting up the hardware](#setting_up_the_hardware)").
2. If email notifications for warnings are desired, then the `birdBoxEmailAddress.csv` file should be updated.
  1. If the bird's name/ID **is not** already in the `birdBoxEmailAddress.csv` file, the bird's name/ID should be typed into the second column, labeled "birdID".  **This case-sensitive name/identification number must be exactly the same as the one that will be entered into the GUI later.** Any email address(es) that you or other users wish to be notified at may be entered in the subsquent columns.  If the bird's ID already exists in the file, simply append the desired email addresses into the columns to the right of the bird's ID.
  2. For further information about the formatting of the 'birdBoxEmailAddresses.csv' file, see "[Parameters which may be adjusted](#parameters_which_may_be_adjusted)".
2. Type the bird's ID into its physical box's corresponding text box on the right of the GUI, **and hit 'Enter' after typing the word**.  **The color of the box in the GUI will change** (corresponding now to the whether or not the door is open) to indicate that the bird's ID has successfully been added.
  1. Each box in the GUI represents a physical bird box, which are stacked in the order that they appear on the rack.  Therefore, if a new bird is being added to the top (first) box, the bird's name should be added to the top (first) box in the GUI.

##3. Monitoring a bird/reading the GUI
  1. The **current** status of the bird's environment can be seen as numbers near the center of the GUI, and graphically as horizontal bars that align with the history plot.  The **bird box's color** indicates the **state of the door**, green being closed, yellow being open.  If there is anything wrong with the environment (see Overview of features), one or more of the GUI elements will continually flash red.
  2. The **history** of the temperature and humidity fluctuations can be seen in the plot on the left side of the GUI.  By default, it shows the last ~10 minutes of data (one pixel for each update from the Ardunio, labeled as "minutes" timescale).
    1. The plot can be adjusted to show a few hours or a few days of past data by pressing the corresponding button to the right of the plot.
    2. The dotted lines in the middle of the plot represent the required range of temperature and humidity in the IACUC protocol.  The program will warn the user (red flashing GUI and potentially an email) if the temperature or humidity goes outside of this range.
    3. The overall y-boundary of the plot represents 20% above and below the allowable range.  The program will not react specifically to the temperature or humidity going outside of the boundary, but the user should consider these to be extreme environment circumstances, and must adjust the bird's environment as soon as possible.
  3. Occasionally, the status of the serial connection to the Arduino should be checked.  This status can be seen in the bottom right of the GUI, in the form of a small, colored rectangle with text in it.  If something is wrong, the box will turn yellow (generally indicating a mismatch between the Arduino's setup and the computer's setup), and if the Arduino has been disconnected, the box will turn red.
  4. **If there are any red flashing warnings, something is wrong with the bird box environment.  If there are statuses in the Arduino status box other than a green "Connected" signal, something is wrong with the connection to the Arduino.  If these problems persist for 10 minutes, the program will send an email to those emails which are registered with the affected bird (environmental warnings), or to all registered emails (Arduino connection warnings). In either case, please refer to the "Troubleshooting" section.**
    1. If all problems become resolved after an email is sent, a second email will be sent to notify all users that the problem no longer needs attending to.

##4. Modifying emails associated with a bird
  1. In `birdBoxEmailAddresses.csv`, locate the row associated with the bird ID whose emails must be modified.  Make any changes to this row which must be done (addition/deletion of emails)
  2. In the Processing GUI, locate the box of the bird whose emails were just updated.  Click its text box so that the cursor is modifying the contents (you may want to try typing/deleting a letter and then deleting/replacing it to make sure that the text box is being modified).
  3. When the cursor is inside the textbox, and the textbox shows the correct bird ID, **press Enter** to make the program load the contents of the newly modified `birdBoxEmailAddresses.csv` file (effectively making the program think you "changed" the bird's ID, so it looks for new emails).

##5. Removing a bird from a box
Removing a bird is a simple process
  1. Once the bird has been removed from the physical box, the user should clear the bird's ID from the textbox on the right of the GUI **and then hit Enter**.  The program will confirm the removal of the bird's ID by changing the box's background color to gray (from green or yellow, previously).
    1. This will stop data being written to .csv file, as well as any email notifications related to that bird.
    2. If a new bird is being placed into the box directly after the previous one, the text box does not need to be cleared, and the user may instead type the new bird's ID into the box **and then hit Enter**.
  2. If this bird will definitely not be stored in the boxes again, the user may want to remove it from the `birdBoxEmailAddresses.csv` file, so that the user will not be accidentally notified in the future.
    1. This can be done by deleting the entire row of the .csv file corresponding to the bird.

##6. Retreiving recorded data
All data created by the software will be written to the `data/` directory under the main path, in the form of .csv files for each day.  If the program was installed on the system properly, the main path will lead to the `bird_monitoring/` path in the user's `Documents/` directory.  If the software was **not** installed correctly, the main path will lead to the user's home directory (different for each system).
More information about the format of the data files can be found the "Reference" section.

#Parameters which may be adjusted
- `birdBoxEmailAddresses.csv`
  - Purpose: The `birdBoxEmailAddresses.csv` file allows the program to keep track of which user(s) should be notified by email if there are any problems with certain birds (identified by their names/ID's).
  - The file is formatted in the following way:
    - The first line (row) is ignored.  This is to allow headers in the file to better explain each column's purpose.
    - The first column is ignored.  This is to allow the user to write in notes for each bird.
    - The second column is the name/ID of the bird whose warnings will send an email.
    - Every column after the third column may contain a single email address.  This email address will be sent a message if there are any problems with the bird or the Arduino connection.
    - The order of the rows (aside from the first "header" row) does not matter, nor does the order of the emails in each row matter.
  - To change the email addresses while a bird is currently being tracked by the program (the bird's ID is in one of the GUI boxes), the `birdBoxEmailAddresses.csv` file must be modified and then the bird's name text box in the GUI must be clicked into followed by pressing Enter (see "Modifying emails associated with a bird").
  - To change the email addresses while a bird is **not** currently being tracked by the program (the bird' ID is **not** in any of the GUI boxes), the `birdBoxEmailAddresses.csv` file may be changed at any time.  The next time that the bird's ID is entered into the GUI, the program will read all associated email addresses from the file.
    - A sample `birdBoxEmailAddresses.csv` is included in this repository, which may be filled out as needed.
- Processing program parameters
  - **Changing any of the following parameters will require modifying the source code of Processing program, as well as restarting the program**
  - Frequency of sampling from the Arduino
    - Variable: `int fetchTime`
    - Location: `CanaryBoxManager.pde`
    - Purpose: This parameter defines frequency of polling from the Arduino.  The rate at which the program updates the GUI/records values is set by the **Processing program**, not the Arduino program.
    - The value corresponds to the number of milliseconds between updates from the Arduino.  Lower values increase the frequency of updates.
  - Number of hours/days to display on the plot
    - Variables: `float numHours` and `float numDays`
    - Location: `CanaryBoxClass`
    - Purpose: These parameters can be adjusted to change how many hours or days appear in the history plot when the corresponding button has been pressed to adjust the scale.
  - Upper and lower boundaries for allowable temperature and humidity
    - Variables: `float tempMin`, `float tempMax`, `float humidityMin`, and `float humidityMax`
    - Location: `CanaryBoxClass`
    - Purpose: These parameters represent the allowable range of temperature and humidity before the program starts sending warnings (red flashing and emails).  These values should be taken from the IACUC protocol.
      - Temperature is measured in ˚F, and humidity is measured in % Relative Humidity (%RH).
  - Range of values (y-axis) shown on plot
    - Variable: `float percentExtraYAxis`
    - Location: `CanaryBoxClass.pde`
    - Purpose: This parameter represents how much "extra" y-axis should be shown outside of the allowable range defined by the maximum and minimum temperature and humidity values.
  - Number of minutes to wait before emailing a warning
    - Variable: `float minutesToWaitBeforeEmailing`
    - Location: `CanaryBoxClass.pde`, `CanaryBoxManagerClass.pde`
    - Purpose: This parameter represents the number of minutes that a problem must persist before an email is sent.
      - The `minutesToWaitBeforeEmailing` parameter in the `CanaryBoxClass.pde` file governs how long to wait before sending a bird environment related email, while the version in `CanaryBoxManagerClass.pde` governs how long to wait before sending an email due to an Arduino connection problem (this is set to 0 by default)
      - Note: The program will send an email after 10 minutes of **any** environmental warning, not necessarily the warning which **started** the countdown.  For example, if the temperature is too low for 5 minutes, and then the humidity drifts too high, even if the temperature problem is corrected, the program will still send an email in `minutesToWaitBeforeEmailing - 5` minutes unless the humidity problem gets corrected.
  - Number of parameters that are being tracked by the Arduino
    - Variable: `int numTrackedParameters`
    - Location: `CanaryBoxClass.pde`
    - Purpose: This variable represents how many parameters (temperature, humidity, door status, etc.) the Arduino is sending to the software **per box**.  This parameter should only be changed if the entire setup is being modified to add more sensors per box.  If this is done, this parameter is one of many that should be changed. See "Extending the program".
      - **Note: This value must match the value of `trackedParameters` (`= analogTrackedParameters + digitalTrackedParameters`) in `Serial_Test.ino`.**
  - Size of the GUI
    - Line: `size(1024, 600, OPENGL);`
    - Location: `CanaryBoxClass.pde`
    - Purpose: This line can be modified to change the size of the GUI window, which may be useful if more boxes are added and the GUI becomes too compact.  The first parameter (`1024` by default) represents the window width, while the second parameter (`600` by default) represents the height.  See the [`size` documentation](https://processing.org/reference/size_.html) for more information.
  - Arduino connection port
    - Variable: `String arduinoPortName`
    - Location: `CanaryBoxManager.pde` (Note that there are two lines of interest, connected by an `if` statement.  The line that must be adjusted depends on which operating system you are using.  See the comments in `CanaryBoxManager.pde`.)
    - Purpose: This is the port name that the Processing program will look for the Arduino on. To test if the port is correct, either use the Device Manager on your system, or attempt to connect to the Arduino using the [Arduino] software over the port in question.
- Arduino program parameters
  - Number of boxes being tracked
    - Variable: `int numBoxes`
    - Location: `Serial_Test.ino`
    - Purpose: This parameter records how many boxes the Arduino is keeping track of.  If more boxes are added to the software, this must be incremented.
  - Number of analog parameters that are being tracked by the Arduino
    - Variable: `analogTrackedParameters`
    - Location: `Serial_Test.ino`
    - Purpose: This variable represents how many analog parameters (temperature, humidity, etc.) the Arduino is sending to the software **per box**.  This parameter should only be changed if the entire setup is being modified to add more sensors per box.  If this is done, this parameter is one of many that should be changed. See "Extending the program".
    - **Note: This value plus the value of `digitalTrackedParameters` must match the value of `numTrackedParameters` in `CanaryBoxClass.pde`.**
  - Number of digital parameters that are being tracked by the Arduino
    - Variable: `digitalTrackedParameters`
    - Location: `Serial_Test.ino`
    - Purpose: This variable represents how many digital parameters (door status, etc.) the Arduino is sending to the software **per box**.  This parameter should only be changed if the entire setup is being modified to add more sensors per box.  If this is done, this parameter is one of many that should be changed. See "Extending the program".
    - **Note: This value plus the value of `analogTrackedParameters` must match the value of `numTrackedParameters` in `CanaryBoxClass.pde`.**

# Setting up the hardware
##1. Nomenclature
- Box: The physical box into which each bird will be placed. Each box will have a number of sensors placed into it to keep track of the environment inside of the box.
- Box Board: A small breadboard that connects all of the physical sensors for each box, as well as any required circuitry to accurately read the sensors (such as pull-down resistors, current limiting resistors, etc.).  This board is placed inside of an enclosure which is then placed inside of the box
- Power Board: A small breadboard which sits between the Arduino and the box boards.  This board has two main purposes.  Its first purpose is to distribute and manage power between all box boards.  To do this, it has two power rails (a 5V and a 3.3V) and a ground rail which all box boards connect to.  It also has a capacitor between each power rail and the ground rail, so that the box boards do not need to do this to prevent fluctuations.  Its second purpose is to combine the large number of cables from all of the box boards into a single cable that goes from the power board to the Arduino.
- [Arduino](https://www.arduino.cc/en/Guide/Introduction): The microcontroller which acts as the high-level interface between the Processing program and the sensors in each box.  The Arduino is responsible for recording the values of each sensor, and transmitting them to the program in an understandable way.
- [D-sub cable](https://en.wikipedia.org/wiki/D-subminiature): This cable (identified by the type of connector it has) connects the Arduino, power board, and box boards.  The main difference between the different cables is the number of pins and wires within each. 9-pin cables are used to connect the box boards to the power board, and a 25-pin cable is used to connect the power board to the Arduino.
  - Note: There are more wires in the 25-pin D-sub cable than there are pins, so adding more box boards may be difficult due to redundancies in the wires (i.e. two sensors accidentally being assigned to the same pin).  To help alleviate issues in the future, a csv file is included in this repository ([`Hardware/D-Sub Pins.csv`]) which lists the corresponding pin number of each wire in the cable currently being used between the power board and the Arduino as of writing.

##2. Setting up a box board
- All of the supplies listed in the [`Required Hardware.csv`] file in this repository will be needed.
- Using the [breadboard], [temperature sensor], [humidity sensor], [door sensor], and resistors, assemble the circuit shown in [`Bread_Board_Circuit.pdf](bird-monitoring/Hardware/Bread_Board_Circuit.pdf).
  - The power will be provided by the Arduino via the power board, so wires extending from the power rails on the box board should be present.  The negative ends of the power supply should connect to the ground of the Arduino (not seen in the circuit), so there should be a third wire extending from the ground rail of the box board.
  - Pay special care to the lengths of the cables attaching each sensor.  Using an [inline splice solder](http://www.instructables.com/id/Soldering-Tutorial-Inline-Splicing/?ALLSTEPS), the door sensor's cables should be extended by about 1.5x, and the [humidity sensor] and [temperature sensor] cables should be extended so that they can reach around the enclosure to be fed into the box.
  - Note: Because of the leakage resistor on the [humidity sensor], and the pull-down and current limiting resistors on the [door sensor], the [temperature sensor] is the only sensor whose Vout wire does not need to be attached to the [breadboard].  This wire may be connected directly to the D-sub cable, while the others should have a wire extending from their Vout node on the [breadboard].
- Prepare a 9-pin D-sub cable for this board.
  - In general, the box board has a long (~4 ft.) cable, while the power board has an opposite gendered short (~6 inch) cable. The cable must have its insolation removed, and 6 of its wires stripped.  Any 6 of the wires may be used, but for ease of use, a convention has been followed with each of the previous box boards.  This convention is shown in the Reference section, "Wire colors".
  - Because the purpose of the connector is easy attachment/detachment from the power board, a matching, opposite-gendered D-sub connector must be found for this cable as well.  Also, because no guarantee is made about which colored wires the pins connect to, a continuity test must be used to determine which wires match.
    - To do this, prepare both gendered cables (by cutting them to appropriate lengths, removing insolation, and stripping the wires), and connect them. On the box board side, start with one wire that will be needed (e.g. the green wire, for ground), and determine which wire connects to it through the D-sub connection by using the continuity tester.  Record the matched wire for later use (while connecting it to the power board), and then do this procedure for each wire on the box board size that will be used.  Unused wires should be zip-tied to the remaining insolation on the cable.
- Install the box board into the box
  - Because the hole in the box for cables and tubes is very small, it is not possible to fit either the D-sub connector nor the box board through it.  Because of this, the board must be connected to the D-sub cable in the box.  The deinsulated end should be fed through the hole, and connected to the corresponding wires on the box board using [twist-on wire connectors](https://en.wikipedia.org/wiki/Twist-on_wire_connector).
  - The box board may now be positioned in the box, and mounted using tape and/or velcro.
    - Ensure that the temperature and humidity sensors are exposed to the center of the enclosure.
    - The [door sensor] should be attached near the top of the box, facing the opening (care must be taken to consider how the door occupies room in the box when it is closed, i.e. the [door sensor] might not be able to be installed flush with the opening).  The magnet (included with the [door sensor]), may be installed on the door, such that when the door closes, the magnet will be within about 1 cm of the [door sensor].

##3. Modifying the power board
- If not already done so, create the power board.
  - This will require a [breadboard] and 2 .1µF capacitors (as seen in the [`Required Hardware.csv`] file).  No circuit has been provided, because it is simply a distribution platform for power and pinouts to the Arduino.
  - Prepare a 25-pin D-sub cable to connect the power board to the Arduino.
    - In general, the power board has a long (~6 ft.) cable, while the Arduino has an opposite gendered short (~6 inch) cable. The cable must have its insolation removed, and a number of wires must be stripped equal to 3 times the number of boxes plus 3 for the power rails (`3*(number_of_boxes + 1)`).  Any of the wires may be used, but the wires that were used originally are listed in the [`Hardware/D-Sub Pins.csv`] file.  The file should also be referred to if using the original cable, as there are 36 wires representing only 25 pins, so there are some redundancies, as well as some wires which are not connected at all.
  - Solder the cable on the [breadboard].  For each of the 3 power-related rails (5V, 3.3V, and ground), it is recommended to use a jumper cable to extend the rails, as each box will need access to each.
  - One capacitor should be placed between each of the power rails and ground.
- Connect the box board D-sub connector to the power board
  - Using the wire-pairs recorded in the "Setting up a box board", solder the deinsulated end of the cable to the power board, such that each wire is matched with the power or signal that it carries.

##4. Modifying the Arduino headers
- Determine which wires in the D-sub cable are responsible for each purpose.
  - Using the technique described above, under "Prepare a 9-pin D-sub cable for this board", determine which wires are matched on the power board and Arduino ends of the 25-pin D-sub cable.  For the original cable used, the wires match by color because both ends were made from the same cable.
- Solder the wires onto the corresponding headers on the Arduino
  - New temperature and humidity signal lines can be added after the existing **analog** pins.
    - New lines are always added temperature line first, then humidity.  Therefore, if a fourth box is desired, the third box's temperature line will be on analog pin 4, and its humidity line will be on analog pin 5, so the fourth box's temperature line should be on analog pin 6, and its humidity line should be on analog pin 7.
  - New door signal lines can be added after the existing **digital** pins.
    - New lines are added sequentially onto the board, with the first box's door line being on digital pin 2 (pins 0 and 1 are reserved on the Arduino board).  Therefore, the third box's door sensor should be on digital pin 4, so the fourth box's door sensor should be on digital pin 5.

##5. Modifying the software
- **Modifying the software is only necessary if using more than 3 boxes**
    - If a new box is being added, the box is designated the next incremental numbered box.
    - Therefore, if there were 3 boxes, a new box is referred to as "box 4".
  - Modify the Arduino software
    - The `int numBoxes` parameter in `Serial_Test.ino` may need to be changed to match the number of boxes that the Arduino is tracking.  The value should be changed, and the software must be re-uploaded to the Arduino board.
    - Restart the Processing software, if it was not done so already.
      - Once the Processing program detects the change in the number of boxes from the Arduino upon restarting, the number of boxes in the GUI should automatically update.
      - If the GUI appears to be too compacted and difficult to read after adding boxes, you may want to consider changing the size of the entire window, to better fit the increased amount of information. See "Size of the GUI" under "Parameters which may be adjusted".

# Troubleshooting
##1. Red flashing GUI (environment warnings)
- Different parts of the GUI will flash when indicating different problems arise.  For **any** environmental warning, the affected bird's box on the GUI will flash red.  This indicates that there is a problem.  To diagnose the problem, one must determine what else is flashing on the GUI.
- The first step to correct all temperature and humidity problems is to determine if the lab air (the air that everyone in the lab is breathing) would satisfy the required parameters.
  - If so, simply open the bird box and allow the temperature and humidity to equalize for some time.  After this, more long-term solutions may be planned.
  - If not, a solution must be devised according to the problem at hand.  You may want to consider taking the bird to the aviary until the environment can be properly managed.
  
####1. Temperature too high
- **Temperature value, blue horizontal bar, and top dashed line on plot flashing red**
- If a humidifier is being used in line with the airpump, consider chilling the water with ice.  If no humidifier is being used, consider adding one with chilled water.  Note that this will most likely increase the humidity.
- The air line may be run through a long section that goes through a pool of ice water (unexposed to the water, only to the water's temperature).  Note that this may lead to condensation, which may decrease the humidity.
- Cooling down the lab's air (adjusting HVAC, etc.) may eventually cool down the box's air, but this may take some time.

####2. Temperature too low
- **Temperature value, blue horizontal bar, and bottom dashed line on plot flashing red**
- If a humidifier is being used in line with the airpump, consider warming the water.  If no humidifier is being used, consider adding one with warm water.  Note that this will most likely increase the humidity.
- The air line may be run through a long section that goes through a pool of warm water (unexposed to the water, only to the water's temperature).
- Warming up the lab's air (adjusting HVAC, etc.) may eventually warm up the box's air, but this may take some time.

####3. Humidity too high
- **Humidity value, green horizontal bar, and top dashed line on plot flashing red**
- If there is a humidifer being used in line with the airpump, consider changing the size of the line that feeds into the water (shorter lines will disturb the water less, which may lead to less moisture/air mixing).  Also consider changing the pressure of the air being put into the humidifier.  Completely removing the humidifer may also be useful.
- If there is no humidifier being used, a dehumidifier may need to be used.  Consider running the airline through a pool of ice water to create a condenser.  Note that this may lead to a decrease in temperature.

####4. Humidity too low
- **Humidity value, green horizontal bar, and bottom dashed line on plot flashing red**
- If there is a humidifer being used in line with the airpump, consider changing the size of the line that feeds into the water (longer lines will disturb the water more, which may lead to more moisture/air mixing).  Also consider changing the pressure of the air being put into the humidifier.
- If there is no humidifier being used, consider adding one.

####5. Social time needed
- **"Social time needed" appears in flashing red underneath the bird's ID**
- This indicates that the bird has not had its IACUC required social time for the day (1 hour of social time per 24 hours, by default).
- Opening the door will make the status disappear.  However, if the door is closed again before the social time requirement is fulfilled, the warning (and email countdown) will start once again.

####6. Door open too long
  - **"Door open too long" appears in flashing red underneath the bird's ID**
  - This indicates that the bird box's door has been left ajar for a long time (12 hours straight, by default).  Simply closing the door will end this status, and reset the "door open too long" timer back to 0.

##2. Bottom right box is not green (Arduino connection issues)
####1. Yellow box
- **The Arduino status box is yellow, and has the text "Communication error"**
- This indicates that the Arduino and the Processing program are mismatched on either the number of boxes being tracked, or the number of parameters being tracked per box.
- If a new box was added and the program has not been restarted yet, simply restart the Processing program.  If the Arduino software was properly updated (see "Modifying the software" under "Setting up the hardware"), and the connection between the devices is good, the Processing GUI should now appear with the correct number of boxes.
- If a new tracked parameter was added (in addition to temperature, humidity, and the door sensor), and the Arduino software was properly updated (see "Modifying the software" under "Setting up the hardware"), but the Processing program was not, then the Processing program should be updated by changing `numTrackedParameters` (see "Number of parameters that are being tracked by the Arduino" under "Parameters which may be adjusted").  In addition to this, the Processing program must be updated to store and interpret the new parameters correctly (see "Adding more tracked parameters" under "Extending the program").
####2. Red box (Disconnected)
- ** The Arduino box is red, and has the text "Disconnected"**
- This indicates that the Processing program cannot find the Arduino.
- Check that the Arduino is connected properly.  The Processing program will attempt to reconnect to the Arduino every 2 seconds.
- If the program cannot reconnect to the Arduino while it is running, try restarting the Processing program (operating system level limitations sometimes do not allow the program to reacquire a connection to the Arduino while running).
- If the Arduino still cannot be found, look under the computer Device Manager, to attempt to find the Arduino.
  - If it cannot be found, try restarting the computer. Further attempts to connect the Arduino to the computer are outside of the scope of this manual (i.e. use your [Google-fu](https://en.wiktionary.org/wiki/Google-fu)).
  - If it can be found, check the name of the port that the Arduino is connected to, and make sure that the Processing program is looking for the Arduino on that same port (see "Arduino connection port" under "Parameters which may be adjusted").  Restarting the computer may also be necessary.

[Arduino]: https://www.arduino.cc/en/Main/Software
[temperature sensor]: http://www.analog.com/media/en/technical-documentation/data-sheets/TMP35_36_37.pdf
[humidity sensor]: http://sensing.honeywell.com/index.php/ci_id/49692/la_id/1/document/1/re_id/0
[door sensor]: https://www.adafruit.com/products/375
[breadboard]: http://www.digikey.com/product-detail/en/sparkfun-electronics/PRT-12702/1568-1083-ND/5230952
[`Required Hardware.csv`]: https://github.com/samuelgbrown/bird-monitoring/Hardware/Required_Hardware.csv
[`Hardware/D-Sub Pins.csv`]: https://github.com/samuelgbrown/bird-monitoring/Hardware/D-Sub_Pins.csv