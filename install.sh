#!/bin/bash
VER="v1.6"
# Constant
UPDATE_AT=11
CRON_CMD="/bin/bash /usr/local/bin/auto_updater"                     # Updates at 11 AM, change if needed
TEMP_DIR="/tmp/auto_updater"                                         # Temp directory to clone the repo
REPO_URL="https://github.com/darshan-vayavya/linux-auto-updater.git" # Repository URL
NOTIFY_TITLE="Update Available fo Auto Updater ⚙️!"
NOTIFY_MESSAGE="A new version of the auto updater script is available:"

DISPLAY_SETUP_FOR_DIALOG="
USER=\$(logname)
USER_ID=\$(id -u \$USER)
DISPLAY=\${DISPLAY:-:1}
xhost local:\$USER > /dev/null
"

CHECK_FOR_UPDATES_LOGIC="
if [ ! -d \"$TEMP_DIR/.git\" ]; then
    echo \"Cloning repository...\"
    git clone \"$REPO_URL\" \"$TEMP_DIR\"
    git config --global --get-all safe.directory | grep -q \"^$TEMP_DIR\\\$\" || \\
    git config --global --add safe.directory \"$TEMP_DIR\"
else
    cd \"$TEMP_DIR\" && git fetch --tags
fi

LATEST_TAG=\$(cd \"$TEMP_DIR\" && git tag --list | sort -V | tail -n 1)

# Compare the latest tag with the current version
if [[ \"\$LATEST_TAG\" != \"\" && \"\$LATEST_TAG\" != \"$VER\" ]]; then
    if [[ \$(printf \"%s\\n\" \"$VER\" \"\$LATEST_TAG\" | sort -V | tail -n 1) == \"\$LATEST_TAG\" ]]; then
      echo -e \"\e[0;92m$NOTIFY_TITLE\e[0;m\"
      # Display a desktop popup with a clickable URL to the repo
      sudo -u \$USER DISPLAY=\$DISPLAY zenity --info \\
      --text=\"$NOTIFY_TITLE\\n$NOTIFY_MESSAGE \$LATEST_TAG\\nClick OK to visit the repository.\" --icon-name=info
      # Check if user clicked OK (exit status 0)
      if [ \$? -eq 0 ]; then
          # Open the repository URL in the default browser
	  echo \"Opening Repository\" >> /var/log/auto_updater
          sudo -u \$USER DISPLAY=\$DISPLAY firefox \"$REPO_URL\" & disown
      fi
    fi
fi"

# Functions
function setup_packages {
  echo "Installing required packages"
  if [ "$1" == "apt" ]; then
    sudo apt update >/dev/null 2>&1
    sudo apt install -y git cron zenity snapd
    sudo snap install firefox
  elif [ "$1" == "pacman" ]; then
    sudo pacman -Syu --noconfirm git cronie zenity firefox
  elif [ "$1" == "dnf" ]; then
    sudo dnf install -y git cronie zenity firefox
  else
    echo "Unable to install required packages: unsupported package manager."
    exit 1
  fi

  # Start and enable cron service
  echo "Setting-up cron service..."
  if systemctl is-active --quiet cron; then
    echo "Cron is already running. Restarting..."
    sudo systemctl restart cron
  else
    echo "Cron is not running. Starting and enabling..."
    sudo systemctl start cron
    sudo systemctl enable cron
  fi
}

# Create update script
function create_update_script {

  echo -e "\e[4;32mRunning script installation\e[0m"

  # Choose package manager based on the argument passed
  local package_manager=$1
  setup_packages "$package_manager"

  # Define the update script content based on the package manager
  if [ "$package_manager" == "apt" ]; then
    update_script_content="#!/bin/bash
VERSION=\"$VER\"
# This part lets our script display the popup
$DISPLAY_SETUP_FOR_DIALOG
echo -e \"\\n\\e[0;32mRunning system updates at \$(date)\\e[0m\" >> /var/log/auto_updater
# This part of the code checks for the auto-updater script's updates :)
$CHECK_FOR_UPDATES_LOGIC
sudo apt update > /dev/null 2>&1
sudo apt upgrade -y >> /var/log/auto_updater 2>&1
echo -e \"\\n\\e[0;32mCompleted Running System Updates: \$(date)\\e[0m\" >> /var/log/auto_updater
"
  elif [ "$package_manager" == "pacman" ]; then
    update_script_content="#!/bin/bash
VERSION=\"$VER\"
# This part lets our script display the popup
$DISPLAY_SETUP_FOR_DIALOG
echo -e \"\\n\\e[0;32mRunning system updates at \$(date)\\e[0m\" >> /var/log/auto_updater
# This part of the code checks for the auto-updater script's updates :)
$CHECK_FOR_UPDATES_LOGIC
sudo pacman -Syu --noconfirm >> /var/log/auto_updater 2>&1
echo -e \"\\n\\e[0;32mCompleted Running System Updates: \$(date)\\e[0m\" >> /var/log/auto_updater
"
  elif [ "$package_manager" == "dnf" ]; then
    update_script_content="#!/bin/bash
VERSION=\"$VER\"
# This part lets our script display the popup
$DISPLAY_SETUP_FOR_DIALOG
echo -e \"\\n\\e[0;32mRunning system updates at \$(date)\\e[0m\" >> /var/log/auto_updater
# This part of the code checks for the auto-updater script's updates :)
$CHECK_FOR_UPDATES_LOGIC
sudo dnf update -y >> /var/log/auto_updater 2>&1
echo -e \"\\n\\e[0;32mCompleted Running System Updates: \$(date)\\e[0m\" >> /var/log/auto_updater
"
  else
    update_script_content="#!/bin/bash
VERSION=\"$VER\"
# This part lets our script display the popup
$DISPLAY_SETUP_FOR_DIALOG
echo -e '\\n\\e[1;31mUnknown package manager, cannot update system.\\e[0m' >> /var/log/auto_updater
# This part of the code checks for the auto-updater script's updates :)
$CHECK_FOR_UPDATES_LOGIC
"
  fi

  echo "$update_script_content" >/usr/local/bin/auto_updater

  # Make the script executable
  chmod +x /usr/local/bin/auto_updater

  # Set up a cron job to run the script at 11 AM every day
  # Check if the cron job already exists
  if crontab -l | grep -q "$CRON_CMD"; then
    # Remove the old cron job
    crontab -l | grep -v "$CRON_CMD" | crontab -
    echo "Old cron job removed."
  fi

  # Add the new cron job with the updated UPDATE_AT value
  (
    crontab -l 2>/dev/null
    echo "0 $UPDATE_AT * * * $CRON_CMD"
  ) | crontab -

  echo "Auto Updates set to happen at $UPDATE_AT:00 Daily"
  echo ""
  echo "You can find the update log by running cat /var/log/auto_updater"
}

# Detect Distro
function debian_based {
  echo -e "\033[1;31mDebian Based System Detected. 🟥\033[0m"
  create_update_script "apt"
}

function arch_based {
  echo -e "\033[1;34mArch Based System Detected. 🟦 \033[0m"
  create_update_script "pacman"
}

function fedora_based {
  echo -e "\033[1;36mFedora Based System Detected. 🟦\033[0m"
  create_update_script "dnf"
}

function other_distro {
  echo -e "\e[1;101m     This script was not designed to run on your system ⚠️    \e[0m"
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

echo "We will start by detecting which OS the system is on 🔎"
sleep 3 # Small delay for user to see the message
detect_distro
