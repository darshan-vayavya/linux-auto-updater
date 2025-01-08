#!/bin/bash
VERSION="v1.1"
# Constant
UPDATE_AT=11                                                         # Updates at 11 AM, change if needed
TEMP_DIR="/tmp/auto_updater"                                         # Temp directory to clone the repo
REPO_URL="https://github.com/darshan-vayavya/linux-auto-updater.git" # Replace with your repository URL
NOTIFY_TITLE="Update Available"
NOTIFY_MESSAGE="A new version of the auto updater script is available:"

CHECK_FOR_UPDATES_LOGIC="if [ ! -d \"$TEMP_DIR/.git\" ]; then
    echo \"Cloning repository...\"
    git clone \"$REPO_URL\" \"$TEMP_DIR\"
else
    echo \"Repository already cloned. Updating...\"
    cd \"$TEMP_DIR\" && git fetch --tags
fi
LATEST_TAG=\$(cd \"$TEMP_DIR\" && git tag --list | sort -V | tail -n 1)

# Compare the latest tag with the current version
if [[ \"\$LATEST_TAG\" != \"\" && \"\$LATEST_TAG\" != \"$VERSION\" ]]; then
    if [[ $(printf \"%s\n\" \"$VERSION\" \"$LATEST_TAG\" | sort -V | tail -n 1) == \"$LATEST_TAG\" ]]; then
        # Display a desktop notification with a clickable URL to the repo
        notify-send \"$NOTIFY_TITLE\" \"$NOTIFY_MESSAGE $LATEST_TAG\nClick to view the repository.\" \
            -u normal -i info -a \"Update Check\" --hint=int:transient:1 \
            -t 0 -c \"notification.url=$REPO_URL\"
    fi
fi"

# Functions
# Install cron
function setup_cron {
  echo "Checking if cron is installed..."

  if ! command -v cron &>/dev/null; then
    echo "Cron is not installed. Installing cron..."

    if [ "$1" == "apt" ]; then
      sudo apt update
      sudo apt install -y git cron libnotify-bin
    elif [ "$1" == "pacman" ]; then
      sudo pacman -Syu --noconfirm git cronie libnotify
    elif [ "$1" == "dnf" ]; then
      sudo dnf install -y git cronie libnotify
    else
      echo "Unable to install cron: unsupported package manager."
      exit 1
    fi

    # Start and enable cron service
    echo "Starting and enabling cron service..."
    sudo systemctl start cron
    sudo systemctl enable cron
  else
    echo "Cron is already installed."
  fi
}
# Create update script
function create_update_script {

  echo -e "\e[4;32mRunning script installation\e[0m"

  # Choose package manager based on the argument passed
  local package_manager=$1
  setup_cron "$package_manager"

  # Define the update script content based on the package manager
  if [ "$package_manager" == "apt" ]; then
    update_script_content="#!/bin/bash
VERSION=\"$VERSION\"
echo \"Running system updates at \$(date)\" >> /var/log/auto_updater
# This part of the code checks for the auto-updater script's updates :)
$CHECK_FOR_UPDATES_LOGIC
sudo apt update > /dev/null 2>&1
sudo apt upgrade -y >> /var/log/auto_updater 2>&1
"
  elif [ "$package_manager" == "pacman" ]; then
    update_script_content="#!/bin/bash
VERSION=\"$VERSION\"
echo \"Running system updates at \$(date)\" >> /var/log/auto_updater
# This part of the code checks for the auto-updater script's updates :)
$CHECK_FOR_UPDATES_LOGIC
sudo pacman -Syu --noconfirm >> /var/log/auto_updater 2>&1
"
  elif [ "$package_manager" == "dnf" ]; then
    update_script_content="#!/bin/bash
VERSION=\"$VERSION\"
echo \"Running system updates at \$(date)\" >> /var/log/auto_updater
# This part of the code checks for the auto-updater script's updates :)
$CHECK_FOR_UPDATES_LOGIC
sudo dnf update -y >> /var/log/auto_updater 2>&1
"
  else
    update_script_content="#!/bin/bash
VERSION=\"$VERSION\"
echo 'Unknown package manager, cannot update system.' >> /var/log/auto_updater
# This part of the code checks for the auto-updater script's updates :)
$CHECK_FOR_UPDATES_LOGIC
"
  fi

  echo "$update_script_content" >/usr/local/bin/auto_updater

  # Make the script executable
  chmod +x /usr/local/bin/auto_updater

  # Set up a cron job to run the script at 11 AM every day
  crontab -l >cronjobs
  echo "0 $UPDATE_AT * * * /bin/bash /usr/local/bin/auto_updater" >>cronjobs
  crontab cronjobs
  rm cronjobs

  echo "Auto Updates set to happen at $UPDATE_AT:00 Daily"
  echo ""
  echo "You can find the update log by running cat /var/log/auto_updater"
}

# Detect Distro
function debian_based {
  echo "Debian Based System Detected."
  sudo apt update
  #  Install cron
  create_update_script "apt"
}

function arch_based {
  echo "Arch Based System Detected"
  #  Install cron
  create_update_script "pacman"
}

function fedora_based {
  echo "Fedora Based System Detected"
  #  Install cron
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
