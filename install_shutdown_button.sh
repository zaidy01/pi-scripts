#!/bin/bash

set -e

echo "Installing gpiozero..."
sudo apt update -y
sudo apt install -y python3-gpiozero

echo "Creating shutdown script..."
cat << 'PYEOF' | sudo tee /home/pi/shutdown_button.py > /dev/null
from gpiozero import Button
from signal import pause
import os

button = Button(17, pull_up=True, bounce_time=0.1)

def shutdown():
    os.system("shutdown -h now")

button.when_held = shutdown
button.hold_time = 1

pause()
PYEOF

echo "Setting permissions..."
sudo chown pi:pi /home/pi/shutdown_button.py
sudo chmod 755 /home/pi/shutdown_button.py

echo "Creating systemd service..."
cat << 'SVCEOF' | sudo tee /etc/systemd/system/shutdown-button.service > /dev/null
[Unit]
Description=Shutdown Button Listener
After=multi-user.target

[Service]
ExecStart=/usr/bin/python3 /home/pi/shutdown_button.py
User=root
Restart=always
Environment=PYTHONUNBUFFERED=1

[Install]
WantedBy=multi-user.target
SVCEOF

echo "Enabling service..."
sudo systemctl daemon-reload
sudo systemctl enable shutdown-button.service
sudo systemctl restart shutdown-button.service

echo "DONE ✅ Shutdown button installed (GPIO17, hold 2 seconds)"
