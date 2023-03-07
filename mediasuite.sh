#!/bin/bash

function installDependencies(){
    apt update
    apt install software-properties-common -y
    add-apt-repository contrib
    add-apt-repository non-free
    apt update
    apt install apt-transport-https dirmngr gnupg ca-certificates curl wget gnupg2 git python3-setuptools ufw sabnzbdplus python3-sabyenc par2 snapd install transmission-daemon -y
    snap install overseerr
}

function installArrsuite(){

    # Add Mono repo
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
    echo "deb https://download.mono-project.com/repo/debian stable-buster main" |  tee /etc/apt/sources.list.d/mono-official-stable.list
    apt update

    # Install MediaArea repo
    wget https://mediaarea.net/repo/deb/repo-mediaarea_1.0-20_all.deb
    dpkg -i repo-mediaarea_1.0-20_all.deb 

    # Install Sonarr Repo
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 2009837CBFFD68F45BC180471F4F90DE2A9B4BF8
    echo "deb https://apt.sonarr.tv/debian buster main" |  tee /etc/apt/sources.list.d/sonarr.list
    apt update

    # Install Lidarr, Prowlarr, Radarr, Readarr
    for i in {1..4}
    do
        #echo "$i"
        printf "$i\n\nplex\n1\n\n" | bash ./plex-files/ArrInstall.sh
    done

    # Install Sonarr
    apt-get update
    apt install sonarr -y
}

function installPlex(){
    
    wget -O- https://downloads.plex.tv/plex-keys/PlexSign.key | gpg --dearmor |  tee /usr/share/keyrings/plex.gpg

    echo deb [signed-by=/usr/share/keyrings/plex.gpg] https://downloads.plex.tv/repo/deb public main |  tee /etc/apt/sources.list.d/plexmediaserver.list

    apt update

    apt install plexmediaserver -y

    systemctl start plexmediaserver
    systemctl enable plexmediaserver
}

function installTautulli(){

    # Install from GitHub
    cd /opt
    git clone https://github.com/Tautulli/Tautulli.git
    addgroup tautulli &&  adduser --system --no-create-home tautulli --ingroup tautulli
    chown -R tautulli:tautulli /opt/Tautulli

    # Create systemd service
    cp /opt/Tautulli/init-scripts/init.systemd /lib/systemd/system/tautulli.service
    systemctl daemon-reload &&  systemctl enable tautulli.service
    systemctl start tautulli.service

}

function installUFW(){

    allowedPorts=(22 32400 9696 7878 8989 8686 8787 8181 8081 9091)
    # Deny all traffic
    ufw default deny
    for i in "${allowedPorts[@]}"
    do
        ufw allow $i
    done

    ufw enable
    ufw reload
    ufw status
}

function installSabnzbd(){
    
    cp ./plex-files/sabnzbd.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl start sabnzbd
    systemctl enable sabnzbd

}

installDependencies
installPlex
installArrsuite
installSabnzbd
installUFW
installTautulli