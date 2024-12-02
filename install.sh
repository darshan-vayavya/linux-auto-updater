#!/bin/bash
# Constant
UPDATE_AT=11 # Updates at 11 AM, change if needed

# Functions
# Create update script
function create_update_script {

  echo -e "\e[4;32mRunning script installation\e[0m"

  # Choose package manager based on the argument passed
  local package_manager=$1

  # Define the update script content based on the package manager
  if [ "$package_manager" == "apt" ]; then
    update_script_content="#!/bin/bash
echo 'Running system updates at $(date)' >> ~/update_log.txt
sudo apt update >> ~/update_log.txt 2>&1
sudo apt upgrade -y >> ~/update_log.txt 2>&1
echo 'Update completed on $(date)' >> ~/update_log.txt
"
  elif [ "$package_manager" == "pacman" ]; then
    update_script_content="#!/bin/bash
echo 'Running system updates at $(date)' >> ~/update_log.txt
sudo pacman -Syu --noconfirm >> ~/update_log.txt 2>&1
echo 'Update completed on $(date)' >> ~/update_log.txt
"
  elif [ "$package_manager" == "dnf" ]; then
    update_script_content="#!/bin/bash
echo 'Running system updates at $(date)' >> ~/update_log.txt
sudo dnf update -y >> ~/update_log.txt 2>&1
echo 'Update completed on $(date)' >> ~/update_log.txt
"
  else
    update_script_content="#!/bin/bash
echo 'Unknown package manager, cannot update system.' >> ~/update_log.txt
"
  fi

  # Create a hidden script in the home directory
  echo "$update_script_content" >~/.update_script.sh

  # Make the script executable
  chmod +x ~/.update_script.sh

  # Set up a cron job to run the script at 11 AM every day
  (
    crontab -l 2>/dev/null
    echo "0 $UPDATE_AT * * * /bin/bash ~/.update_script.sh"
  ) | crontab -

  echo "Auto Updates set to happen at $UPDATE_AT:00 Daily"
}

# Detect Distro
function debian_based {
  echo "Debian Based System Detected."
  sudo apt update
  #  Install cron
  sudo apt install -y cron
  create_update_script "apt"
}

function arch_based {
  echo "Arch Based System Detected"
  #  Install cron
  sudo pacman -Syu --noconfirm cron
  create_update_script "pacman"
}

function fedora_based {
  echo "Fedora Based System Detected"
  #  Install cron
  sudo dnf install -y cronie
  create_update_script "dnf"
}

function other_distro {
  echo -e "\e[1;31mThis script was not designed to run on your system :(\e[0m"
  exit
}

function detect_distro {
  if [ -f /etc/os-release ]; then
    # Source the /etc/os-release file to get distro information
    . /etc/os-release
    # Check for specific distributions
    case "$ID" in
    ubuntu | debian | linuxmint | pop)
      debian_based
      ;;
    arch | manjaro)
      arch_based
      ;;
    fedora)
      fedora_based
      ;;
    *)
      other_distro
      ;;
    esac
  else
    echo "Could not detect distribution. /etc/os-release not found."
    other_distro
  fi
}

# Main code
if [[ ! -z "$1" && "$1" =~ ^[0-9]+$ ]]; then
  # Means time value was passed as additional parameter
  UPDATE_AT=$1
fi
echo -e "\e[1;32mWelcome to Auto-Update Script installer\e[0m"

echo "We will start by detecting which OS the system is on:"
detect_distro
