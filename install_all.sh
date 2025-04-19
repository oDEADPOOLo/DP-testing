#!/bin/bash
set -euxo pipefail # Improve error handling

# Move to home directory
cd "$HOME" || exit

# Update and upgrade packages
sudo apt update && sudo apt upgrade -y

# Install essential packages
sudo apt install -y curl gnupg2 software-properties-common apt-transport-https

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker "$USER" # Add user to docker group
newgrp docker # Apply group membership without logout
# Check Docker Compose version
docker compose version

# Install Plex
curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plex-archive-keyring.gpg >/dev/null
echo "deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main" | sudo tee /etc/apt/sources.list.d/plex.list
sudo apt update
sudo apt install -y plexmediaserver

# Verify Plex status and boot configuration
echo -e "\nVerify Plex Status and Boot Configuration:"
systemctl status plexmediaserver.service | head -n 3 | awk '/active \(running\)|enabled/{gsub(/active \(running\)|enabled/,"\033[0;32m&\033[0m")} /inactive \(dead\)|disabled/{gsub(/inactive \(dead\)|disabled/,"\033[0;31m&\033[0m")} {print}'

# Display Plex status and boot configuration messages
echo -e "\nPlex Status and Boot Configuration:"
echo "If the output shows 'enabled, enabled, (active running),' Plex is running & set to run on boot."
echo "If you see any error message about 'Critical: libusb_init failed,' you can ignore it as advised by the Plex team."

# Create Docker Directory and functions to install services
mkdir -p /docker

install_overseerr() {
    mkdir -p /docker/overseerr
    cd /docker/overseerr/
    curl -fsSL https://raw.githubusercontent.com/Ombi-app/Ombi/master/docker-compose.yml -o docker-compose.yml # Use official ombi repo
    docker compose up -d
}

install_jackett_flaresolverr() {
    mkdir -p /docker/jackett
    cd /docker/jackett/
    curl -fsSL https://raw.githubusercontent.com/Jackett/Jackett/master/docker-compose.yml -o docker-compose.yml # Use official jackett repo
    docker compose up -d

    # Additional setup for Flaresolverr
    mkdir -p /docker/flaresolverr
    cd /docker/flaresolverr
    curl -fsSL https://raw.githubusercontent.com/FlareSolverr/FlareSolverr/master/docker-compose.yml -o docker-compose.yml
    docker compose up -d
}

# Prompt for Overseerr installation
read -p "Do you want to install Overseerr? (y/n): " overseerr_choice
if [ "$overseerr_choice" = "y" ]; then
    install_overseerr
fi

# Prompt for Jackett and Flaresolverr installation
read -p "Do you want to install Jackett and Flaresolverr? (y/n): " jackett_flaresolverr_choice
if [ "$jackett_flaresolverr_choice" = "y" ]; then
    install_jackett_flaresolverr
fi

# Always install pd_zurg
sudo mkdir -p /docker/pd_zurg/{config,log,cache,RD,mnt}
sudo chown -R "$USER:$USER" /docker/pd_zurg # Set correct ownership
cd /docker/pd_zurg/
curl -fsSL https://raw.githubusercontent.com/I-am-PUID-0/pd_zurg/master/docker-compose.yml -o docker-compose.yml

# Modify pd_zurg Docker Compose file
# No need for the sed command, handle in the instructions

curl -fsSL https://raw.githubusercontent.com/I-am-PUID-0/pd_zurg/master/update_docker_compose.sh -o update_docker_compose.sh
sudo chmod +x update_docker_compose.sh

# Display completion message
echo "Installation complete. Plex, Docker, and chosen containers have been installed."
echo "Important: Edit /docker/pd_zurg/docker-compose.yml to add your Real-Debrid API key (RD_API_KEY), PUID, and PGID."
echo "You might also need to run /docker/pd_zurg/update_docker_compose.sh."
