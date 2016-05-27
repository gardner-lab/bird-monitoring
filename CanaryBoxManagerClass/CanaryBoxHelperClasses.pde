class Emailer {
  // Email warning parameters (will send out an email if a warning has been occurring for minutesBeforeEmail straight minutes)
  private float minutesBeforeEmail; // Number of minutes to wait before sending an email because of some warning
  private long millisBeforeEmail; // Number of milliseconds before sending a warning email
  private boolean haveEmailAddresses = false; // Does the Emailer object have any email addresses to notify?
  private String birdName; // (Identifier) The name of the bird that this Emailer is conscerned with
  private String emailIdentifier; // Identifier by which the subject of the email will be referred to (usually the same as birdName, but custom can be specified, used in emails only)
  public long timeWarningStarted; // The time at which the warning started
  public boolean reactingToWarning = false; // If the program is in a state of waiting to send an email (counting down)
  public boolean emailSent = false; // If an email has been sent for the current set of warnings

  // Parameters needed for the computer to send the emails
  private InternetAddress[] emailAddresses; // Addresses objects for the email addresses to be notified
  private InternetAddress fromAddress; // Source address that the email will appear to come from
  private String username = "birdboxmanager@gmail.com"; // Username for the gmail account
  private String password = "birdboxmanager9"; // Password for the gmail account
  private String host = "smtp.gmail.com"; // Use the gmail smtp server
  private Properties properties; // Hey, this is private properties!
  private Session session;
  
  Emailer(String infoFileName, String birdNameIn, float minutesBeforeEmailIn, String emailIdentifierIn) {
    // infoFileName is the path and name of the file that contains information on who to contact
    // birdNameIn is the identifying word/code that corresponds to the correct emails in the file (i.e. "bird1" may correspond to the emails "someone@gmail.com" and "someone-else@gmail.com")
    // if "birdNameIn" is blank (""), then assume that the user wants to send to every birdname, so extract all emails in the file
    // minutesBeforeEmailIn lets the Emailer know how long it should wait before sending an email about a given problem
    birdName = birdNameIn;
    emailIdentifier = emailIdentifierIn;
    minutesBeforeEmail = minutesBeforeEmailIn;
    String[] newEmailAddresses = new String[100]; // Allocate some amount of memory for the array (If there are more than 100 emails, the program may crash.  I just...don't think that will really be a problem)
    try {
      fromAddress = new InternetAddress("birdboxmanager@gmail.com");
    }
    catch (Exception e) {
      println(e.getMessage());
    }
    int curLocNewAddresses = 0; // Current location along the emailAddresses list
    int identifierCol = 1; // The column number that the identifier is expected to be in
    int emailStartCol = 2; // The column number that the emails are expected to start from

    // Open the file and extract the required information
    emailDebug("Creating Emailer for " + emailIdentifier);
    try {
      // The file is expected to be a csv with the following format (can be modified above):
      // The first record (row) will be a header (for user use, ignored)
      // Following rows will be: column 1: Notes (ignored), column 2: identifier, colums 3-inf: emails associated with this identifier
      BufferedReader reader = new BufferedReader(new FileReader(infoFileName));

      // Read and remove the header from the csv file
      if (reader.readLine() != null) {
        // If there is information in the csv

        // Now, read through each line, and check if the identifier is found
        String str; // String read from the file
        while ((str = reader.readLine()) != null && (str.length() != 0)) {
          // While the end-of-file has not been reached

          // First, spit the input String
          String[] columns = str.split(","); // Split on commas, because it is a csv

          // After the split, make sure that there is content in this row (end of file may not have been reached, but the rest of the table may be blank)
          if (columns.length == 0) {
            break;
          }

          // Check the identifier column, to see if it is equal to the expected identifier
          if (columns[identifierCol].equals(birdName) || birdName.equals("")) {
            // The correct identifier has been found

            int numEmails = columns.length - emailStartCol; // The number of emails found in the file
            if (numEmails > 0) {
              // If there are emails associated with this identifier

              // Copy over the emails from the file
              arrayCopy(columns, emailStartCol, newEmailAddresses, curLocNewAddresses, numEmails);
              curLocNewAddresses += numEmails; // Iterate the location along the emailAddresses array (used for filling array, as well as copying it over to a properly sized array later)
              haveEmailAddresses = true;
            }

            if (!birdName.equals("")) {
              // If the user only wants 1 identifier's worth of emails, break out of the loop, as the file does not need to be read any more
              break;
            }
          }
        }
      }

      // Close the file
      reader.close();
    } 
    catch (IOException e) {
      emailDebug("Error reading file");
      println(e.getMessage());
    }

    // Move the email addresses over to a smaller array
    // Also, if the user wanted all identifiers included in this Emailer, go through emailAddresses and remove doubles
    String[] properlySizedEmailAddresses;
    int numberOfEmailAddresses = 0;
    if (birdName.equals("")) {
      String[] nonDuplicateEmailAddresses = new String[curLocNewAddresses];
      for (int i = 0; i < curLocNewAddresses; i++) {
        // Go through each email in the array extracted from the file
        boolean emailExistsInArray = false; 
        for (int j = 0; j < numberOfEmailAddresses; j++) {
          // Go through each email in the emailAddresses array, to see if the current address (newEmailAddresses[i]) exists in it already 
          if (nonDuplicateEmailAddresses[j].equals(newEmailAddresses[i])) {
            emailExistsInArray = true;
            break;
          }
        }

        if (!emailExistsInArray) {
          nonDuplicateEmailAddresses[numberOfEmailAddresses++] = newEmailAddresses[i];
        }
      }
    } else {
      numberOfEmailAddresses = curLocNewAddresses;
    }

    // Copy over the addresses to an array that fits it perfectly
    properlySizedEmailAddresses = new String[numberOfEmailAddresses];
    arrayCopy(newEmailAddresses, 0, properlySizedEmailAddresses, 0, numberOfEmailAddresses);

    // Now, go through nonDuplicateEmailAddresses, and create Address objects out of each
    emailAddresses = new InternetAddress[numberOfEmailAddresses];
    for (int i = 0; i < numberOfEmailAddresses; i++) {
      try {
        emailAddresses[i] = new InternetAddress(properlySizedEmailAddresses[i]);
      } 
      catch(Exception e) {
        emailDebug("InternetAddress error: " + e.getMessage());
      }
    }
    
    // Catch errors on the number of emails
    if (numberOfEmailAddresses < 1) {
     errorReporting("No email addresses found for " + emailIdentifier);
    } else {
      emailDebug(numberOfEmailAddresses + " addresses found for " + birdName + ":");
      for (int i = 0;i<numberOfEmailAddresses;i++) {
       emailDebug(emailAddresses[i].toString());
      }
      emailDebug("");
    }

    // Finish finalizing parameters needed for the computer to send an email
    properties = System.getProperties(); // Get system properties
    properties.setProperty("mail.smtp.host", host); // Setup mail server
    properties.setProperty("mail.smtp.user", username); // Set the username
    properties.setProperty("mail.smtp.password", password); // Set the password
    properties.setProperty("mail.smtp.auth", "true"); // Use authentication
    properties.put("mail.smtp.port", "587"); 
    properties.put("mail.smtp.starttls.enable", "true"); 
    session = Session.getInstance(properties, new javax.mail.Authenticator() {
      protected PasswordAuthentication getPasswordAuthentication() {
        return new PasswordAuthentication(
          username, password);// Specify the Username and the PassWord
      }
    }); // Get the Session object

    // Intialize the parameters needed for countdown
    millisBeforeEmail = (long)(minutesBeforeEmail*millisPerMin); // Calculate the number of milliseconds to wait before sending out an email
  }
  
  Emailer(String infoFileName, String birdNameIn, float minutesBeforeEmailIn) {
    this(infoFileName, birdNameIn, minutesBeforeEmailIn, birdNameIn);
  }
  

  void checkIfEmailIsNeeded(boolean warningStimulus, String message) {
    // If enough time has passed since any warning has been active, without all warnings going silent, then send out an email detailing the current warnings
    // warningStimulus is a boolean that represents something going wrong.  If it is true, Emailer will start the process of sending an email warning (or wait for the warning stimulus to end, if an email has already been sent)
    // message is a String that contains the key text in an email that will be sent

    // First, check the status flag for any warnings
    if (warningStimulus) {
      long curTimeInMillis = Calendar.getInstance().getTimeInMillis(); // Get the current time

      // If there is a warning, check if it is a new warning
      if (!reactingToWarning) {
        // If this is a new warning, start the email countdown period
        emailDebug("Received new warning.  Starting email countdown.");
        timeWarningStarted = curTimeInMillis; // Record the current time
        reactingToWarning = true; // Change the state to the countdown period
      } else {
        // If this is an old warning, check if an email has already been sent
        if (!emailSent) {
          // If an email has been sent, do nothing.
          // If no email has been sent, then check if the countdown has finished
          emailDebug((float)(timeWarningStarted + millisBeforeEmail - curTimeInMillis)/1000 + " seconds before sending email");
          if (curTimeInMillis > (timeWarningStarted + millisBeforeEmail)) {
            // If the countdown has just expired, then send out an email
            sendEmail(message);
            emailSent = true;
          }
        }
      }
    } else {
      // If there are no warnings, update the user if necessary, and then reset the email warning system
      // Check if an email was sent because of a previous warning
      if (emailSent) {
        emailDebug("Warning turned off.  Sending update email.");
        // If an email was sent, send an update to the user, letting them know that the situation has resolved
        sendEmail();
      }

      // Clear all varaibles related to sending an email warning
      reactingToWarning = false;
      emailSent = false;
    }
  }

  private void sendEmail(String messageText) {
    String curTimeString = sdf.format(Calendar.getInstance().getTime());
    // Format the message text
    String header = "Warning from Bird Box at " + curTimeString;
    String fullMessageText = "There is currently a problem with " + emailIdentifier + ", as of " + curTimeString + " today.  Details below:\r\n\r\n" + messageText + "\r\nIf the error resolves, another email will be sent.  Please do not reply to this address.";
    emailDebug("Sending email to the following addresses:");
    for (int i = 0; i < emailAddresses.length; i++) {
      emailDebug(emailAddresses[i].getAddress());
    }
    sendEmailWithText(header, fullMessageText);
  }

  private void sendEmail() {
    // Used to send an "all clear" signal
    String curTimeString = sdf.format(Calendar.getInstance().getTime());
    // Format the message text
    String header = "Problem resolved at " + curTimeString;
    String fullMessageText = "The problem with " + emailIdentifier + " has resolved, as of " + curTimeString + " today.\r\n\r\nPlease do not reply to this address.";
    emailDebug("Sending email to the following addresses:");
    for (int i = 0; i < emailAddresses.length; i++) {
      emailDebug(emailAddresses[i].getAddress());
    }
    sendEmailWithText(header, fullMessageText);
  }

  private void sendEmailWithText(String header, String messageText) {
    emailDebug("Sending message");
    // Will send message in an email to all those in the emailAddresses list
    if (haveEmailAddresses) {
      try {
        // Create a default MimeMessage object.
        MimeMessage message = new MimeMessage(session);

        // Set From: header field of the header.
        message.setFrom(fromAddress);

        // Set To: header field of the header.
        message.addRecipients(Message.RecipientType.TO, emailAddresses);

        // Set Subject: header field
        message.setSubject(header);

        // Now set the actual message
        message.setText(messageText);

        // Send message
        Transport.send(message);
        emailDebug("Sent message successfully");
      }
      catch (MessagingException mex) {
        mex.printStackTrace();
      }
    } else {
      emailDebug("No email addresses to send warning to");
    }
  }
}

// A structure that keeps track of each parameter for a single box, in the form of floats, and is able to extract them from a byte-stream from the Arduino
class trackedParametersFloat {
  int numParameters; // The number of parameters that this object keeps track of
  List<Float> parameters;

  trackedParametersFloat(byte[] allParameterData, int numParametersIn) {
    numParameters = numParametersIn; // Record the number of parameters
    parameters = new ArrayList<Float>(); // Create the list of parameters
    convertParameters(allParameterData); // Convert the byte data into floats
  }

  trackedParametersFloat(float[] allParameterData, int numParametersIn) {
    numParameters = numParametersIn; // Record the number of parameters
    parameters = new ArrayList<Float>(); // Create the list of parameters
    convertParameters(allParameterData); // Convert the byte data into floats
  }

  private void convertParameters(float[] allParameterData) {
    // allParameterData is expected to be an array of size numParameters*bytesPerFloat.  No safety is guaranteed if this is not true
    for (int j = 0; j < numParameters; j++) {
      parameters.add(allParameterData[j]);
    }
  }

  private void convertParameters(byte[] allParameterData) {
    // allParameterData is expected to be an array of size numParameters*bytesPerFloat.  No safety is guaranteed if this is not true
    for (int j = 0; j < numParameters; j++) {
      byte[] parameterData = new byte[bytesPerFloat]; // Contains bytes for one parameter
      arrayCopy(allParameterData, bytesPerFloat*j, parameterData, 0, bytesPerFloat); // Move 1 parameter's data from allParamterData to parameterData 
      // Convert the set of 4 bytes in parameterData into a single float
      parameters.add(ByteBuffer.wrap(parameterData).order(ByteOrder.LITTLE_ENDIAN).getFloat());
    }

    dataDebug(parameters.toString());
  }
}