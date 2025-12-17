# -----------------------------
# arch-dev Dockerfile
# -----------------------------
FROM archlinux:latest

# 1. Update Keyring FIRST to fix "package not found" or "invalid signature" errors
#    Then perform a full system update.
RUN pacman -Sy --noconfirm archlinux-keyring && \
    pacman -Syu --noconfirm

# 2. Install Dependencies (Updated with bat and eza)
ARG INSTALL_NIRI
RUN pacman -S --noconfirm \
    base base-devel sudo openssh git fish ripgrep fd python curl wget unzip vim nvim tmux \
    bat eza

# Conditional Niri/Wayland installation
RUN if [ "$INSTALL_NIRI" = "true" ]; then \
    pacman -S --noconfirm waypipe niri sway wayland-utils xorg-xwayland \
    xdg-desktop-portal mesa alacritty fuzzel; \
    fi

# 3. Create User & Sudoers (Updated shell to fish)
ARG USER_NAME
ARG USER_PASSWORD
RUN useradd -m -s /usr/bin/fish $USER_NAME && \
    echo "$USER_NAME:$USER_PASSWORD" | chpasswd && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME

# 4. Install yay (Must be done as non-root user)
USER $USER_NAME
WORKDIR /home/$USER_NAME

# --- MOVE THE ENV SETUP BELOW 'USER root' ---

# 5. Setup Dotfiles (Bare Repo Method)
ARG DOTFILES_REPO
RUN if [ -n "$DOTFILES_REPO" ]; then \
    # Install OhMyPosh
    curl -s https://ohmyposh.dev/install.sh | bash -s && \
    # Clone as a bare repo into a hidden folder
    git clone --separate-git-dir=$HOME/.dotfiles $DOTFILES_REPO $HOME/dotfiles-temp && \
    # Move the files to HOME and remove the temp folder
    cp -rvT $HOME/dotfiles-temp $HOME && \
    rm -rf $HOME/dotfiles-temp && \
    # Setup the alias for managing them (optional but recommended)
    echo "alias dot='/usr/bin/git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME'" >> $HOME/.bashrc; \
    else \
    echo "No dotfiles repo provided"; \
    fi
# 6. Configure Runtime Environment
USER root
# Only setup XDG_RUNTIME_DIR if Niri is being used
RUN if [ "$INSTALL_NIRI" = "true" ]; then \
    export XDG_RUNTIME_DIR=/tmp/runtime-$USER_NAME && \
    mkdir -p $XDG_RUNTIME_DIR && \
    chown $USER_NAME:$USER_NAME $XDG_RUNTIME_DIR && \
    chmod 700 $XDG_RUNTIME_DIR && \
    echo "export XDG_RUNTIME_DIR=$XDG_RUNTIME_DIR" >> /etc/environment; \
    fi

# Setup SSH keys and directory
RUN mkdir -p /run/sshd && \
    ssh-keygen -A

# Expose SSH port
EXPOSE 22

# 7. CMD: Start SSH Daemon
CMD ["/usr/sbin/sshd", "-D"]