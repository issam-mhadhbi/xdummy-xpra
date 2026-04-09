from ubuntu:22.04
env HOME /root
env DEBIAN_FRONTEND=noninteractive
env force_color_prompt=yes
env color_prompt=yes
env PS1='\[\e]0;\u@\h: \w\a\]${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
ENV PATH="/root/.local/bin/:${PATH}"
##################################################
#             Configure tzdata                   #
##################################################
# Set keyboard configuration to AZERTY (French)
run <<EOF
echo -n '
# KEYBOARD CONFIGURATION FILE
# Consult the keyboard(5) manual page.
XKBMODEL="pc105"
XKBLAYOUT="fr"
XKBVARIANT="azerty"
XKBOPTIONS=""
BACKSPACE="guess"
' > /etc/default/keyboard
EOF
# Set locale and language to English (US)
RUN apt-get update && apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen
RUN locale-gen
RUN update-locale LANG=en_US.UTF-8
# Set geographic zone to Europe/Paris
RUN apt-get install -y tzdata
RUN echo 'Europe/Paris' > /etc/timezone
RUN dpkg-reconfigure -f noninteractive tzdata
RUN apt-get update
RUN apt-get install -y --no-install-recommends software-properties-common kbd
run echo "export PS1=\"$PS1\"" >> /root/.bashrc 

##################################################
#              Setup Python                      #
##################################################
run apt install -y python-is-python3 python3-pip 
run /usr/bin/pip install virtualenv
run python -m virtualenv /opt/base
ENV PATH="/opt/base/bin:${PATH}"

##################################################
#                install linux                   #
##################################################
run apt install -y xdg-user-dirs xdg-utils locales dbus-x11 tree lsof sudo nano unzip  swig gpg apt-transport-https software-properties-common wget 
env XDG_CONFIG_HOME=/root/.config 
env XDG_CACHE_HOME=/root/.cache 
env XDG_DATA_HOME=/root/.local/share 
env XDG_STATE_HOME=/root/.local/state 
env XDG_RUNTIME_DIR=/run/root
env XDG_SESSION_TYPE=x11
run mkdir -p $XDG_CONFIG_HOME $XDG_CACHE_HOME $XDG_DATA_HOME $XDG_STATE_HOME $XDG_RUNTIME_DIR && chmod 700 $XDG_RUNTIME_DIR && xdg-user-dirs-update

##################################################
#                create display                  #
##################################################
run apt install -y xorg xserver-xorg-video-dummy 
env DISPLAY=:0
run <<EOF
mkdir -p /etc/X11/
echo -n 'Section "Device"
    Identifier  "DummyDevice"
    Driver      "dummy"
    VideoRam    256000
EndSection

Section "Monitor"
    Identifier "DummyMonitor"
    HorizSync 31.5-48.5
    VertRefresh 50-70
EndSection

Section "Screen"
    Identifier "DummyScreen"
    Device     "DummyDevice"
    Monitor    "DummyMonitor"
    DefaultDepth 24
    SubSection "Display"
        Depth 24
        Modes "1024x576"
    EndSubSection
EndSection

Section "ServerLayout"
    Identifier "DummyLayout"
    Screen "DummyScreen"
EndSection' > /etc/X11/xorg.conf.d/10-dummy.conf
EOF

##################################################
#                create xpra server              #
##################################################
run apt install -y xpra libavcodec58 libavutil56 ffmpeg  libsecret-1-dev gir1.2-secret-1
expose 14500

##################################################
#           install code-server                  #
##################################################
expose 8000
run apt install -y curl 
env VSCODE_SETTINGS '{"workbench.colorTheme": "Monokai Pro", "workbench.iconTheme": "Monokai Pro Icons", "window.customTitleBarVisibility": "auto", "workbench.sideBar.location": "left", "files.autoSave": "afterDelay", "window.commandCenter": false, "workbench.layoutControl.enabled": false, "workbench.activityBar.location": "top", "workbench.panel.alignment": "justify", "python.defaultInterpreterPath": "/opt/base/bin/python", "jupyter.jupyterServerType": "local", "python.terminal.activateEnvInCurrentTerminal": true}'
run curl -fsSL https://code-server.dev/install.sh | sh
run code-server --install-extension monokai.theme-monokai-pro-vscode
run code-server --install-extension ms-python.python 
run code-server --install-extension ms-python.debugpy
run code-server --install-extension nimsaem.nimvscode
run mkdir -p /root/.config/code-server
run mkdir -p /root/.local/share/code-server/User
run mkdir -p $HOME/workspace



run <<EOF
echo -n '#!/bin/bash
set -euo pipefail
tilix --working-directory=/root/Desktop --maximize & 
code-server --bind-addr 0.0.0.0:8000  --auth none /root/Desktop 
' > /root/xstartup.sh && chmod +x /root/xstartup.sh
EOF

##################################################
#                entrypoint script               #
##################################################


run <<EOF
echo -n '#!/bin/bash
set -euo pipefail
Xorg -noreset +extension GLX +extension RANDR +extension RENDER -logfile /tmp/xdummy.log :0 &
xpra start --use-display :0 \
    --bind-tcp=0.0.0.0:14500 \
    --start-child="/root/xstartup.sh" \
    --encoding=rgb \
    --min-quality=20 \
    --min-speed=20 \
    --compressors=zlib,brotli \
    --bandwidth-limit=1000000 \
    --video-scaling=50 \
    --auto-refresh-delay=1.0 \
    --dpi=96 \
    --exit-with-children=yes \
    --no-daemon 


' > /root/.xinitrc && chmod +x /root/.xinitrc
EOF
entrypoint ["/root/.xinitrc"]
