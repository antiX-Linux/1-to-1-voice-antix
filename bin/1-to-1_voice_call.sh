#!/bin/bash

# Capture the name of the script
PROGNAME=${0##*/}

# Set the version number
PROGVERSION=1.1



# --------------------
# Help and Information
# --------------------

# When requested show information about script
if [[ "$1" = '-h' ]] || [[ "$1" = '--help' ]]; then

# Display the following block
cat << end-of-messageblock

$PROGNAME version $PROGVERSION
Starts Mumble and makes a connection request to a Mumble-Server (Murmur)

Usage: 
   $PROGNAME [options]
   Note: must be sourced from 1-to-1_voice.sh

Options:
   -h, --help     Show this output

Summary:
   Refer to 1-to-1_voice.sh
   
Configuration:
   Refer to 1-to-1_voice.sh
      
Environment:
   Refer to 1-to-1_voice.sh
      
Requires:
   Refer to 1-to-1_voice.sh

end-of-messageblock
   exit 0
fi



# ---------------------
# Inherit configuration
# ---------------------
   
# When this script is not being sourced
if [[ "$0" = "$BASH_SOURCE" ]]; then

   # Title in the titlebar of YAD window
   WINDOW_TITLE="1-to-1 Voice"
   
   # Location of icons
   ICONS=/usr/share/pixmaps
   
   # Message to display in error window
   ERROR_MSG_1="\n This script must be started from \
                \n 1-to-1_voice.sh \
                \n \
                \n Exiting..."

   # Display an error message
   yad                             \
   --button="OK:1"                 \
   --title="$WINDOW_TITLE"         \
   --image="$ICONS/cross_red.png"  \
   --text="$ERROR_MSG_1"

   # Exit the script
   clear
   exit 1
fi



# --------------------------------------
# Obtain the address of listening server
# --------------------------------------

# Request the address of the provider system
while [[ "$PROVIDER_ADDRESS" = "" ]]
do
   # Message to display in the address input window
   LABEL_MSG_1=" IP Address of 1-to-1 Voice Provider "
   
   # Display a window in which to input the address of the viewer system
   PROVIDER_ADDRESS=$(yad                         \
                     --center                     \
                     --entry                      \
                     --entry-label="$LABEL_MSG_1" \
                     --buttons-layout="center"    \
                     --title="$WINDOW_TITLE")
   
   # Capture which button was selected
   EXIT_STATUS=$?

   # Check whether user cancelled or closed the window and if so exit
   [[ "$EXIT_STATUS" = "1" ]] || [[ "$EXIT_STATUS" = "252" ]] && exit 1
done



# --------------------------------
# Determine the port number to use
# --------------------------------

# Detect whether the provider address includes a port number
PORT_CHECK=$(echo $PROVIDER_ADDRESS | grep -c :)

# Handle port number assignment
case $PORT_CHECK in
   0) # No port number provided
      # Assign default
      PROVIDER_ADDRESS=$PROVIDER_ADDRESS:$PORT
      ;;
   1) # Alternative port number provided
      # Retain alternative
      PROVIDER_ADDRESS=$PROVIDER_ADDRESS
      ;;
   *) # Otherwise
      exit 1
      ;;
esac



# ---------------------------
# Connect to listening server
# ---------------------------

# Connect to the address of the server system
mumble mumble://caller@$PROVIDER_ADDRESS
