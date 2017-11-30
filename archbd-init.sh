
#!/bin/bash

# Archbd Installation Script
# Initialising module: tests the internet connection & downloads the scripts

# Mainly Developed by Elizabeth Mills
# Modified by Neil for archbd-installer-script

print_heading() {
  clear
  T_COLS=$(tput cols)
  tput bold
  tput cup 1 $(((T_COLS/2)-20))
  printf "%-s\n" "$Backtitle"
  tput sgr0
  # printf "%$(tput cols)s\n"|tr ' ' '-'  # Draw a line across width of terminal
}

PrintOne() {   # Aligned text according to screen size
  width=$(tput cols)
  EMPTY=" "
  lov=${#1}
  if [ ${lov} -lt ${width} ]; then
    stpt=$(( ($width - $lov) / 2 ))
    EMPTY="$(printf '%*s' $stpt)"
  fi
  echo "$EMPTY $1"
}

PrintMany() {  # Subsequent item(s) in an aligned list
  echo "$EMPTY $1"
}

TPread() {     # Aligned prompt for user-entry
  T_COLS=$(tput cols)
  lov=${#1}
  if [ ${lov} -lt ${T_COLS} ]; then
    stpt=$(( ($T_COLS - $lov) / 2 ))
  elif [ ${lov} -gt ${T_COLS} ]; then
    stpt=0
  else
    stpt=$(( ($T_COLS - 10) / 2 ))
  fi
  EMPTY="$(printf '%*s' $stpt)"
  read -p "$EMPTY $1" Response
}

CheckInternet() {
  Service="N"
  while [ $Service = "N" ]
  do
    PrintOne "A working internet connection is needed for installation."
    PrintOne "Checking your connection,"
    PrintOne "and making sure that archlinux.org is online"
    CheckConnection
    case $Service in
      "N") PrintOne "Sorry, installation cannot continue without an internet connection."
        exit
      ;;
      *) PrintOne "Downloading the latest scripts from Github.com ..."
        break
    esac
    print_heading
  done
}

CheckConnection() {
  while [ $Service = "N" ]
  do
    ping -q -c3 archlinux.org &>/dev/null
    PingTest=$?
    if [ ${PingTest} -ne 0 ]; then
      PrintOne "Enabling wifi-menu"
      wifi-menu &>/dev/null
      ping -q -c3 archlinux.org &>/dev/null
      PingTest=$?
      if [ ${PingTest} -ne 0 ]; then
        print_heading
        echo
        PrintOne "Unable to establish a connection."
        PrintOne "It may be that you are not connected to the internet,"
        PrintOne "or perhaps archlinux.org is offline"
        PrintOne "Ensure that your computer is able to access the internet."
        TPread "Try again? (Y/n): "
        if [ $Response = "N" ] || [ $Response = "n" ]; then
          exit
        else
          continue
        fi
      else
        Service="Y"
      fi
    else
      Service="Y"
    fi
  done
}

ErrorExit() {
  PrintOne "Unable to download the scripts."
  PrintOne "There may be a problem connecting to github.com"
  TPread "Try again? (Y/n): "
  if [ $Response = "N" ] || [ $Response = "n" ]; then
    exit
  else
    Counter=0
  fi
}

ErrorReport() {
  PrintOne "Unable to start the archbd installation script."
  TPread "Try again? (Y/n): "
  if [ $Response = "N" ] || [ $Response = "n" ]; then
    exit
  else
    sh archbd-init.sh
  fi
}

#
# Execute --------------------------------------------------------------
#

# Declare & initialise variables
Backtitle="Archlinux Install by ArchBD Installation script"
PingTest=""                               # Throwaway variable
Chosen="cli"                              # Set default ui in case of error
Counter=0                                 # Set counter
Service="N"                               # Used during connection and download tests

print_heading
PrintOne "Welcome to ArchBD Installer Script."
CheckInternet                             # Connection tests and reporting

Service="N"                               # Reset the conditions
Counter=0
while [ $Service = "N" ]
do
  Counter=$((Counter+1))
  if [ $Counter -gt 3 ]; then             # Limit to 3 failures
    ErrorExit
  fi

  if [ $(ls | grep master.zip) ]; then    # Check in case file already exists
    rm -f master.zip                      # If it already exists, delete it
  fi

  # Download the complete stable archive from Github
  wget -q https://github.com/Neil-seu/archbd-installer-script/archive/master.zip

  if [ $(ls | grep master.zip) ]; then    # Download successful
    sudo pacman -Sy unzip --noconfirm     # Installing unzip
    unzip -o master.zip                   # Unzip
    cp -r archbd-installer-script-master/* .               # Copy all the files
    FileCheck=$(ls | grep archbd)          # Check that they are here
    if [ -z "$FileCheck" ]; then          # If unzip unsuccessful
      continue                            # Try again
    fi
  else                                    # If download unsuccessful
    continue                              # Try again
  fi
  Service="Y"                             # All tests passed
done

# Clean up
rm -rf archbd-installer-script-master
rm -f *.zip

Service="N"                               # Reset the conditions
Counter=0
while [ $Service = "N" ]
do
  Counter=$((Counter+1))
  if [ $Counter -gt 3 ]; then
    ErrorExit
  fi
  if [ -f archbd.sh ]; then
    $Service="Y"
    sh archbd.sh                            # Start the installer
  fi
  if [ $? -gt 0 ]; then
    ErrorReport
  fi
done
