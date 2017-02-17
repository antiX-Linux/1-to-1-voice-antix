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
Starts Mumble-Server (Murmur) and waits for a connection request from
a Mumble client.

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
   ERROR_MSG="\n This script must be started from \
              \n 1-to-1_voice.sh \
              \n \
              \n Exiting..."

   # Display an error message
   yad                             \
   --button="OK:1"                 \
   --title="$WINDOW_TITLE"         \
   --image="$ICONS/cross_red.png"  \
   --text="$ERROR_MSG"

   # Exit the script
   clear
   exit 1
fi



# ------------------
# SuperUser Password
# ------------------

# When enable the superuser account has been requested
if [[ "$ENABLE_SUPERUSER" = "y" ]]; then

   # Question and guidance to display
   MESSAGE_1="\n Which one? \
              \n \
              \n 1. Existing SuperUser password \
              \n     The service may be administrated with a password \
              \n     created in a previous session.  If one does not yet \
              \n     exist you will be prompted to create one. \
              \n \
              \n 2. New SuperUser password \
              \n     Change the administrative password. \
              \n \
              \n"


	# Obtain desired way of handling the superuser password
	   # Display the superuser password options
	   yad                                      \
	   --center                                 \
	   --width=0                                \
	   --height=0                               \
	   --timeout-indicator="bottom"             \
	   --timeout="30"                           \
	   --buttons-layout=center                  \
	   --button="Existing:0"                    \
	   --button="Change":3                      \
	   --button="gtk-cancel":1                  \
	   --title="$WINDOW_TITLE"                  \
	   --image="$ICONS/questionmark_yellow.png" \
	   --text="$MESSAGE_1"      

	   # Capture which button was selected
	   EXIT_STATUS=$?
	
	   # Check whether user cancelled or closed the window and if so exit
	   [[ "$EXIT_STATUS" = "1" ]] || [[ "$EXIT_STATUS" = "252" ]] && exit 1
	     
	   # Capture which action was requested
	   ACTION=$EXIT_STATUS
	
	
	# When a superuser password has not been created or when changing it has been requested
	if [[ "$(cat $CONFIG_DIR/murmur_supw.flag)" != "1" ]] || [[ $ACTION = 3 ]]; then
	   
	   # Display a request to input the desired superuser password
	   while [[ "$SUPERUSER_PASSWORD" = "" ]]
	   do
	      MESSAGE_1=" Password for SuperUser   "
	
	      SUPERUSER_PASSWORD=$(yad                             \
	                         --center                          \
	                         --buttons-layout=center           \
	                         --title="$WINDOW_TITLE"           \
	                         --image="$ICONS/key_yellow.png"   \
	                         --entry                           \
	                         --text="$MESSAGE_1")   
	
	      # Capture which button was selected
	      EXIT_STATUS=$?
	
	      # Check whether user cancelled or closed the window and if so exit
	      [[ "$EXIT_STATUS" = "1" ]] || [[ "$EXIT_STATUS" = "252" ]] && exit 1
	   done
	     
	   # Assign the provided superuser password
	   murmur-user-wrapper -p "$SUPERUSER_PASSWORD" -d "$CONFIG_DIR"
	   
	   # Set the flag to indicate a superuser password has been created
	   echo 1 > "$CONFIG_DIR"/murmur_supw.flag
	fi
fi



# -----------------------
# Start murmur and mumble
# -----------------------

# Start the murmur daemon service using the 1-to-1 voice profile
murmur-user-wrapper -d "$CONFIG_DIR"


# When an alternative port has not been specified
if [[ $ALTERNATIVE_PORT = "" ]]; then

   # Join the service as an unprivileged user via the default port number
   mumble mumble://provider@localhost:$PORT &

# When an alternative port has been specified
else

   # Join the service as an unprivileged user via the alternative port number
   mumble mumble://provider@localhost:$ALTERNATIVE_PORT &
fi

# Capture the process id of mumble
MUMBLE_PID=$!



# ----------------------------------------------------
# Close murmur when mumble has been closed by the user
# ----------------------------------------------------

# Detect when mumble has been closed
until [[ "$MUMBLE_PID" = "" ]]
do
      # Pause to allow an opportunity for the status to change 
      sleep 3
      
      # Capture the current process id number of the mumble process
      MUMBLE_PID=$(ps -p $MUMBLE_PID -o pid= )
done
   

# Stop the murmur daemon that uses the 1-to-1 voice profile
murmur-user-wrapper -k -d "$CONFIG_DIR"
