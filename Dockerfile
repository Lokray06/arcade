# -----------------------------
# arch-dev Dockerfile (VNC-enabled)
# -----------------------------
FROM archlinux:latest

# 1. Update Keyring & system
RUN pacman -Sy --noconfirm archlinux-keyring && \
    pacman -Syu --noconfirm

# 2. Install dependencies
ARG INSTALL_NIRI
RUN pacman -S --noconfirm \
    base base-devel sudo openssh git fish ripgrep fd python curl wget unzip vim nvim tmux \
    bat eza fastfetch waybar swaylock hyprpicker \
    weston wayvnc cage libinput xorg-xwayland mesa mesa-utils libpipewire libwireplumber dbus vulkan-intel vulkan-radeon vulkan-icd-loader \
    chromium kitty fuzzel rofi xcursor-themes

# Conditional Niri/Wayland packages
RUN if [ "$INSTALL_NIRI" = "true" ]; then \
    pacman -S --noconfirm waypipe niri sway wayland-utils xdg-desktop-portal \
    xwayland-satellite alacritty fuzzel; \
    fi

RUN chmod 755 /usr /usr/bin /usr/lib /usr/share /etc /etc/xdg && \
    find /usr /etc -type d -exec chmod 755 {} +

# 3. Create user
ARG USER_NAME
ENV USER_NAME=$USER_NAME
ENV XDG_RUNTIME_DIR=/tmp/runtime-$USER_NAME
ARG USER_PASSWORD
RUN useradd -m -s /usr/bin/fish $USER_NAME && \
    echo "$USER_NAME:$USER_PASSWORD" | chpasswd && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME

# 4. Copy VNC launcher (Add --chown here)
COPY --chown=$USER_NAME:$USER_NAME launch_vnc.sh /home/${USER_NAME}/launch_vnc.sh
RUN chmod +x /home/${USER_NAME}/launch_vnc.sh

# 5. Switch to user for dotfiles & env
USER $USER_NAME
WORKDIR /home/$USER_NAME

ARG DOTFILES_REPO
RUN if [ -n "$DOTFILES_REPO" ]; then \
    curl -s https://ohmyposh.dev/install.sh | bash -s && \
    git clone --separate-git-dir=$HOME/.dotfiles $DOTFILES_REPO $HOME/dotfiles-temp && \
    cp -rvT $HOME/dotfiles-temp $HOME && rm -rf $HOME/dotfiles-temp && \
    echo "alias dot='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'" >> $HOME/.bashrc; \
    fi

USER root
# 6. Setup XDG_RUNTIME_DIR
RUN mkdir -p /tmp/.X11-unix && chmod 1777 /tmp/.X11-unix && \
    export XDG_RUNTIME_DIR=/tmp/runtime-$USER_NAME && \
    mkdir -p $XDG_RUNTIME_DIR && \
    chown $USER_NAME:$USER_NAME $XDG_RUNTIME_DIR && chmod 700 $XDG_RUNTIME_DIR && \
    echo "export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" >> /etc/environment

# Ensure the user is part of the 'video' and 'render' groups for GPU/Display access
RUN usermod -aG video,render $USER_NAME

# 7. Setup SSH
RUN mkdir -p /run/sshd && ssh-keygen -A
EXPOSE 22
# 8. Expose VNC port
EXPOSE 5900

# 9. Default command: Start SSH as root, VNC as user
CMD ["/bin/bash", "-c", "/usr/sbin/sshd && sudo -u $USER_NAME -E /home/$USER_NAME/launch_vnc.sh"]