#!/usr/bin/env just --justfile

pacman:
  sudo pacman -S --needed \
    ffmpeg \
    jq \
    python-pip \
    ripgrep \
    rtorrent \
    transmission-cli \
    wget \
    vifm \
    yt-dlp

docker:
  #!/usr/bin/env bash
  set -e
  sudo pacman -S --needed docker
  sudo systemctl enable docker
  sudo systemctl start docker

ftp-setup:
  #!/usr/bin/env bash
  set -e
  sudo pacman -S --needed vsftpd
  [[ ! -d /etc/vsftpd ]] && sudo mkdir /etc/vsftpd
  sudo cp configuration/vsftpd.conf /etc
  sudo cp configuration/user_list /etc/vsftpd
  echo "Setting file permissions on /mnt/sept11-archive..."
  sudo chown --recursive chris:ftp /mnt/sept11-archive
  sudo chmod --recursive 0775 /mnt/sept11-archive
  echo "Setting file permissions on /mnt/music..."
  sudo chown --recursive chris:ftp /mnt/music
  sudo chmod --recursive 0775 /mnt/music
  sudo useradd -d /mnt/music music
  sudo useradd -d /mnt/sept11-archive sept11
  sudo usermod -aG ftp music
  sudo usermod -aG ftp sept11
  sudo systemctl enable vsftpd
  sudo systemctl start vsftpd

jenkins:
  #!/usr/bin/env bash
  set -e
  sudo pacman -S --needed jenkins
  sudo systemctl enable jenkins
  sudo systemctl start jenkins
  sudo usermod -aG ftp jenkins
  sudo chsh -s /bin/bash jenkins

nginx:
  #!/usr/bin/env bash
  set -e
  sudo cp nginx/nginx.service /etc/systemd/system/nginx.service
  sudo mkdir /etc/nginx-conf
  sudo cp nginx/jenkins.conf /etc/nginx-conf
  sudo systemctl daemon-reload
  sudo systemctl enable nginx
  sudo systemctl start nginx
