#!/bin/bash

set -e

# === CONFIG ===
DOCKER_DIR="/docker"
USER_HOME="$HOME"

# === FUNCTIONS ===
install_docker() {
    sudo apt update && sudo apt upgrade -y
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    sudo apt install -y docker-compose-plugin
    docker compose version
}

install_plex() {
    curl https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor | sudo tee /usr/share/keyrings/plex-archive-keyring.gpg >/dev/null
    echo deb [signed-by=/usr/share/keyrings/plex-archive-keyring.gpg] https://downloads.plex.tv/repo/deb public main | sudo tee /etc/apt/sources.list.d/plex.list
    sudo apt update
    sudo apt install -y libusb-dev plexmediaserver

    echo -e "\nPlex Status:"
    systemctl status plexmediaserver.service | head -n 3
}

install_overseerr() {
    mkdir -p "$DOCKER_DIR/overseerr"
    cd "$DOCKER_DIR/overseerr"
    curl -fsSL https://pastebin.com/raw/AMJ9n8AS -o docker-compose.yml
    docker compose up -d
}

install_jackett_flaresolverr() {
    mkdir -p "$DOCKER_DIR/jackett"
    cd "$DOCKER_DIR/jackett"
    curl -fsSL https://pastebin.com/raw/sZ3XbiFE -o docker-compose.yml
    docker compose up -d

    mkdir -p "$DOCKER_DIR/flaresolverr"
    cd "$DOCKER_DIR/flaresolverr"
    sudo curl -fsSL https://raw.githubusercontent.com/FlareSolverr/FlareSolverr/master/docker-compose.yml -o docker-compose.yml
    sudo docker compose up -d
}

install_pd_zurg() {
    sudo mkdir -p "$DOCKER_DIR/pd_zurg"/{config,log,cache,RD,mnt}
    cd "$DOCKER_DIR/pd_zurg"
    sudo curl -fsSL https://raw.githubusercontent.com/I-am-PUID-0/pd_zurg/master/docker-compose.yml -o docker-compose.yml
    sudo sed -i 's|/pd_zurg/|'"$DOCKER_DIR/pd_zurg/"'|g' docker-compose.yml
    sudo curl -fsSL https://raw.githubusercontent.com/I-am-PUID-0/pd_zurg/master/update_docker_compose.sh -o update_docker_compose.sh
    sudo chmod +x update_docker_compose.sh
    sudo docker compose up -d
}

# === EXECUTION ===

cd "$USER_HOME"

install_docker
install_plex

read -p "Install Overseerr? (y/n): " overseerr_choice
[[ "$overseerr_choice" == "y" ]] && install_overseerr

read -p "Install Jackett and Flaresolverr? (y/n): " jackett_choice
[[ "$jackett_choice" == "y" ]] && install_jackett_flaresolverr

install_pd_zurg

echo -e "\n✅ Installation complete. Plex, Docker, and selected services are set up."
