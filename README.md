# ARCADE – Arch Remote Containerized Always-on Development Environment

A lightweight, always-on Arch Linux development environment containerized via Docker.
Designed for secure, reproducible development on any VPS, independent of the host OS. Includes SSH access, persistent home directory, tmux auto-start, and optional dotfiles bootstrap.

---

## Features

* Arch Linux rolling release inside Docker
* Password SSH for the dev user (configurable via `.env`)
* Persistent home directory via Docker volume
* Auto-start tmux session on login
* Optional dotfiles bootstrap from your Git repo
* Easily deploy multiple containers with different users/ports

---

## Prerequisites

* VPS running Linux (Debian/Ubuntu recommended)
* Docker and Docker Compose installed on the VPS
* Git (to clone dotfiles, optional)

---

## Project Structure

```
arch-dev-docker/
├─ Dockerfile
├─ docker-compose.yml
├─ .env.example
├─ dotfiles/ (optional)
```

---

## Setup

### 1. Clone this repository

```bash
git clone https://github.com/Lokray06/arch-dev-docker.git
cd arch-dev-docker
```

---

### 2. Configure environment

Create the `.env` file, here's a template:
```.env
# .env
USER_NAME=username
USER_PASSWORD=password
SSH_PORT=1234
DOTFILES_REPO=https://github.com/yourusername/dotfiles.git
```

* `USER_NAME` → name of the dev user inside the container
* `USER_PASSWORD` → password for SSH login inside the container
* `SSH_PORT` → port forwarded to VPS for container SSH
* `DOTFILES_REPO` → optional, Git repo with your dotfiles

---

### 3. Build and deploy container

```bash
docker-compose up -d --build
```

* `--build` ensures the Dockerfile is rebuilt with updated environment variables
* `-d` runs it in detached mode

---

### 4. Connect via SSH

```bash
ssh <USER_NAME>@<VPS_IP>/<VPS_DOMAIN> -p <SSH_PORT>
```

Example:

```bash
ssh yourusername@012.034.056.078/yourdomain.com -p 1234
```

On login:

* tmux session auto-starts (`tmux attach || tmux new -s dev`)
* Your dotfiles are loaded if `DOTFILES_REPO` is set

---

### 5. Optional: Secure container SSH internally

If you don’t want to expose the container to the internet:

```bash
ssh -J <VPS_USER>@<VPS_IP> <CONTAINER_USER>@arch-dev
```

* VPS uses key-based authentication
* Container uses password from `.env`

---

## Multiple containers

To deploy another Arch dev container:

1. Copy `.env` to `.env2` and adjust `USER_NAME` and `SSH_PORT`
2. Copy `docker-compose.yml` to `docker-compose2.yml` and reference the new `.env2`
3. `docker-compose -f docker-compose2.yml up -d --build`

---

## Persistent Data

The home directory is stored in a Docker volume:

```bash
docker volume ls
docker volume inspect arch-home
```

This ensures your files, configs, and installed tools persist across container rebuilds.

---

## Updating Arch & Packages

```bash
docker exec -it arch-dev sudo pacman -Syu --noconfirm
```

Or rebuild the container:

```bash
docker-compose up -d --build
```

---

## Notes

* This setup avoids host pollution (perfect for Debian VPS hosts)
* tmux ensures your sessions are persistent
* SSH inside container can be password-based safely if the VPS is key-only

---

## License

MIT License — free to use, modify, and share.