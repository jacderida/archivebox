#!/usr/bin/env just --justfile

pacman:
  sudo pacman -S --needed \
    jq \
    ripgrep \
    wget \
    vifm \
    yt-dlp

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
