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
Creates an encrypted connection between two systems and enables their
operators to talk to each other.

Usage: 
   $PROGNAME [options]

Options:
   -h  --help        Show this output

Summary:
   A system may perform either of two roles:
   * Call a voice service provider
   * Provide a voice service for a caller
   
   Calling a service does not require any changes to be made to the
   firewall/router of the local network.
   
   Providing a service across a local network does not require any 
   changes to be made to the firewall/router of the local network.
 
   Providing a service across the internet requires port number 64730 
   in the firewall/router of the local network to be forwarded to the
   provider system.

   Providing a service across either a local network or the internet
   requires the above port to be open in the provider system.  If the
   provider system is running an active local firewall it must be
   configured to allow connections on the above port.
   
   SSL is used to automatically establish an encrypted connection
   between the caller and provider systems.  A voice sharing session
   is then automatically started with all traffic passing within the
   encrypted tunnel.
   
Configuration:
   In call mode the configuration file is:
   /home/USERNAME/.config/Mumble/Mumble.conf
   
   In provide mode the configuration files are:
   /home/USERNAME/.config/1-to-1_voice/murmur.ini
   
Environment:
   The script works in a GUI (X) environment. 
   
Requires:
   1-to-1_voice_call.sh, 1-to-1_voice_provide.sh
   mumble, mumble-server
   bash, cat, flock, grep, ps, sleep, tail, yad

References:
   http://wiki.mumble.info/wiki/Main_Page

end-of-messageblock
   exit 0
fi



# ---------------
# Static settings
# ---------------

# Location of the lock file used to ensure only a single instance of the script is run
LOCK_FILE=/tmp/1-to-1_voice.lock

# Title in the titlebar of YAD windows
WINDOW_TITLE="1-to-1 Voice"

# Location of icons
ICONS=/usr/share/pixmaps

# Location of configuration directory for murmur server ini file
CONFIG_DIR=$HOME/.config/1-to-1_voice

# Default port number used by Mumble and Murmur
PORT=64730



# --------------------
# Single instance lock
# --------------------

# Create the lock file and remove it when the script finishes
exec 9> $LOCK_FILE
trap "rm -f $LOCK_FILE" 0

# When a subsequent instance of the script is started
if ! flock -n 9 ; then

   # ----- Inform user script already running -----

   # Message to display in error window
   ERROR_MSG_1="\n $WINDOW_TITLE is already running. \
                \n Only one instance at a time is allowed. \
                \n \
                \n Exiting..."

   # Display error message
   yad                             \
   --button="OK:1"                 \
   --title="$WINDOW_TITLE"         \
   --image="$ICONS/cross_red.png"  \
   --text="$ERROR_MSG_1"
 
   # Exit the script
   clear
   exit 1     
fi



# -----------------------------------------------------------------------------
# Ensure provide mode configuration files exist in the user home file structure
# -----------------------------------------------------------------------------

# When the configurtion directory is not present
if [[ ! -d "$CONFIG_DIR" ]]; then

   
   # Ensure the destination directory is present
   mkdir --parents  "$CONFIG_DIR"
   
   # Put a copy of the profile in place
   cp /etc/skel/.config/1-to-1_voice/*  "$CONFIG_DIR"
fi



# Note
# Call mode configuration file is automatically created the first time
# Mumble is started and the audio wizard is completed. This is the default
# global configuration used by all instances of Mumble not just 1-to-1_voice
# The location of the file is ~/.config/Mumble/Mumble.conf



# -------------
# Configuration
# -------------

# When required configuration file for murmur is unavailable
if [[ ! -f "$CONFIG_DIR/murmur.ini" ]]; then

   # Message to display in error window
   ERROR_MSG="\n Essential configuration file not found for \
              \n \
              \n $CONFIG_DIR/murmur.ini  \
              \n \
              \n Exiting..."

	# Display error message
	      yad                      \
	      --button="OK:1"          \
	      --title="$WINDOW_TITLE"  \
	      --image="cross_red"      \
	      --text="$ERROR_MSG"

   # Exit the script
   clear
   exit 1     
fi


# When required configuration file for mumble is unavailable
if [[ ! -f "$CONFIG_DIR/mumble.conf" ]]; then

   # Message to display in error window
   ERROR_MSG="\n Essential configuration file not found for \
              \n \
              \n $CONFIG_DIR/mumble.conf  \
              \n \
              \n Will continue using default values only. \
              \n "

	# Display error message
	      yad                           \
	      --button="OK:1"               \
	      --title="$WINDOW_TITLE"       \
          --timeout-indicator="bottom"  \
          --timeout="10"                \
          --buttons-layout=center       \
	      --image="cross_red"           \
	      --text="$ERROR_MSG"
fi


# Obtain the optional setings for mumble
. "$CONFIG_DIR/mumble.conf"

# Set up default value for superuser in case of misconfiguration
[[ "$ENABLE_SUPERUSER" = "y" ]] || ENABLE_SUPERUSER=



# -----------------------------
# Selection of operational mode
# -----------------------------

# Question and guidance to display
MESSAGE_1="\n Which one? \
           \n \
           \n 1. Call a voice service provider \
           \n \
           \n 2. Provide a voice service for a caller \
           \n \
           \n \
           \n"


# Obtain desired mode of operation
   # Display the mode options
   yad                                      \
   --center                                 \
   --width=0                                \
   --height=0                               \
   --timeout-indicator="bottom"             \
   --timeout="10"                           \
   --buttons-layout=center                  \
   --button="Call":0                        \
   --button="Provide":3                     \
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


# Launch selected operational mode 
case $ACTION in
   0)  # Call was selected
       # Start the required script
       . 1-to-1_voice_call.sh
       ;;
   3)  # Provide was selected
       # Start the required script
       . 1-to-1_voice_provide.sh
       ;;
   70) # Call was selected via timeout 
       # Start the required script
       . 1-to-1_voice_call.sh
       ;;
   *)  # Otherwise
       exit 1        
       ;;
esac

exit



