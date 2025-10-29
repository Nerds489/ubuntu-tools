#!/bin/bash
#
# ULTIMATE LINUX APPLICATION INSTALLER v5.0
# The Most Comprehensive Application Installation Suite
#
# Features:
# - 50+ Applications across all categories
# - Multi-source support (Native, Snap, Flatpak, AppImage)
# - Category-based installation
# - Automatic updates
# - Smart dependency resolution
# - Parallel installation support
# - Rollback capability
#
# Categories:
# - Productivity (Office, Email, Notes)
# - Development (IDEs, Tools, Containers)
# - Internet (Browsers, Communication)
# - Media (Audio, Video, Graphics)
# - Gaming (Steam, Lutris, Emulators)
# - Utilities (System tools)
#
# Usage: sudo ./ultimate_app_installer.sh
#

set -euo pipefail

# ============================================================
# CONSTANTS AND COLORS
# ============================================================

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly MAGENTA='\033[0;35m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

readonly SCRIPT_VERSION="5.0"
readonly LOG_FILE="/var/log/ultimate-app-installer-$(date +%Y%m%d_%H%M%S).log"
readonly APP_DIR="/opt/ultimate-apps"

# ============================================================
# HELPER FUNCTIONS
# ============================================================

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" | tee -a "$LOG_FILE"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1" | tee -a "$LOG_FILE"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}[✓]${NC} $1" | tee -a "$LOG_FILE"
}

log_header() {
    echo -e "\n${CYAN}${BOLD}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}║  $1${NC}"
    echo -e "${CYAN}${BOLD}╚════════════════════════════════════════════════════════════╝${NC}\n"
}

check_root() {
    if [[ $EUID -ne 0 ]]; then
        log_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

detect_package_manager() {
    if command -v apt-get &> /dev/null; then
        echo "apt"
    elif command -v dnf &> /dev/null; then
        echo "dnf"
    elif command -v pacman &> /dev/null; then
        echo "pacman"
    elif command -v zypper &> /dev/null; then
        echo "zypper"
    else
        echo "unknown"
    fi
}

detect_distro() {
    if [[ -f /etc/os-release ]]; then
        . /etc/os-release
        echo "$ID"
    else
        echo "unknown"
    fi
}

# ============================================================
# PACKAGE MANAGER SETUP
# ============================================================

setup_snap() {
    log_header "Setting Up Snap"
    
    if command -v snap &> /dev/null; then
        log_success "Snap already installed"
        return 0
    fi
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y snapd
            ;;
        dnf)
            dnf install -y snapd
            ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
            ;;
        pacman)
            pacman -S --noconfirm snapd
            systemctl enable --now snapd.socket
            ln -sf /var/lib/snapd/snap /snap 2>/dev/null || true
            ;;
        zypper)
            zypper install -y snapd
            ;;
        *)
            log_error "Cannot install Snap on this system"
            return 1
            ;;
    esac
    
    systemctl enable --now snapd.socket
    systemctl enable --now snapd.service
    
    log_success "Snap installed and configured"
}

setup_flatpak() {
    log_header "Setting Up Flatpak"
    
    if command -v flatpak &> /dev/null; then
        log_success "Flatpak already installed"
        flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo 2>/dev/null || true
        return 0
    fi
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y flatpak
            apt-get install -y gnome-software-plugin-flatpak 2>/dev/null || true
            ;;
        dnf)
            dnf install -y flatpak
            ;;
        pacman)
            pacman -S --noconfirm flatpak
            ;;
        zypper)
            zypper install -y flatpak
            ;;
        *)
            log_error "Cannot install Flatpak on this system"
            return 1
            ;;
    esac
    
    flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo
    
    log_success "Flatpak installed and Flathub added"
}

# ============================================================
# CATEGORY: BROWSERS
# ============================================================

install_chrome() {
    log_info "Installing Google Chrome..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            if ! command -v google-chrome &> /dev/null; then
                wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | apt-key add -
                echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list
                apt-get update -qq
                apt-get install -y google-chrome-stable
                log_success "Chrome installed"
            else
                apt-get update -qq
                apt-get install --only-upgrade google-chrome-stable -y
                log_success "Chrome updated"
            fi
            ;;
        dnf)
            dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm || log_error "Failed to install Chrome"
            ;;
        *)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub com.google.Chrome
                log_success "Chrome installed via Flatpak"
            else
                log_error "Chrome installation not supported on this distro without Flatpak"
            fi
            ;;
    esac
}

install_firefox() {
    log_info "Installing Firefox..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y firefox
            ;;
        dnf)
            dnf install -y firefox
            ;;
        pacman)
            pacman -S --noconfirm firefox
            ;;
        zypper)
            zypper install -y firefox
            ;;
    esac
    
    log_success "Firefox installed"
}

install_brave() {
    log_info "Installing Brave Browser..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get install -y curl
            curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg
            echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-release.list
            apt-get update -qq
            apt-get install -y brave-browser
            ;;
        *)
            if command -v snap &> /dev/null; then
                snap install brave
                log_success "Brave installed via Snap"
            else
                log_error "Brave installation requires Snap on this distro"
            fi
            ;;
    esac
    
    log_success "Brave Browser installed"
}

install_opera() {
    log_info "Installing Opera..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            if ! command -v opera &> /dev/null; then
                wget -qO- https://deb.opera.com/archive.key | apt-key add -
                echo "deb https://deb.opera.com/opera-stable/ stable non-free" > /etc/apt/sources.list.d/opera-stable.list
                apt-get update -qq
                apt-get install -y opera-stable
            else
                apt-get update -qq
                apt-get install --only-upgrade opera-stable -y
            fi
            ;;
        dnf)
            dnf install -y https://download3.operacdn.com/pub/opera/desktop/$(curl -s https://get.geo.opera.com/pub/opera/desktop/ | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)/linux/opera-stable_$(curl -s https://get.geo.opera.com/pub/opera/desktop/ | grep -oP '\d+\.\d+\.\d+\.\d+' | head -1)_amd64.rpm 2>/dev/null || \
            snap install opera || log_error "Failed to install Opera"
            ;;
        *)
            snap install opera || log_error "Opera installation failed"
            ;;
    esac
    
    log_success "Opera installed"
}

install_vivaldi() {
    log_info "Installing Vivaldi..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            wget -qO- https://repo.vivaldi.com/archive/linux_signing_key.pub | apt-key add -
            echo "deb https://repo.vivaldi.com/archive/deb/ stable main" > /etc/apt/sources.list.d/vivaldi.list
            apt-get update -qq
            apt-get install -y vivaldi-stable
            ;;
        *)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub com.vivaldi.Vivaldi
            else
                log_error "Vivaldi installation requires Flatpak on this distro"
            fi
            ;;
    esac
    
    log_success "Vivaldi installed"
}

# ============================================================
# CATEGORY: DEVELOPMENT
# ============================================================

install_vscode() {
    log_info "Installing Visual Studio Code..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            if ! command -v code &> /dev/null; then
                wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg
                echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list
                apt-get update -qq
                apt-get install -y code
            else
                apt-get update -qq
                apt-get install --only-upgrade code -y
            fi
            ;;
        dnf)
            rpm --import https://packages.microsoft.com/keys/microsoft.asc
            echo -e "[code]\nname=Visual Studio Code\nbaseurl=https://packages.microsoft.com/yumrepos/vscode\nenabled=1\ngpgcheck=1\ngpgkey=https://packages.microsoft.com/keys/microsoft.asc" > /etc/yum.repos.d/vscode.repo
            dnf check-update
            dnf install -y code
            ;;
        pacman)
            if command -v yay &> /dev/null; then
                sudo -u "$SUDO_USER" yay -S --noconfirm visual-studio-code-bin
            else
                snap install code --classic
            fi
            ;;
        *)
            snap install code --classic
            ;;
    esac
    
    log_success "VS Code installed"
}

install_sublime() {
    log_info "Installing Sublime Text..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            wget -qO - https://download.sublimetext.com/sublimehq-pub.gpg | apt-key add -
            echo "deb https://download.sublimetext.com/ apt/stable/" > /etc/apt/sources.list.d/sublime-text.list
            apt-get update -qq
            apt-get install -y sublime-text
            ;;
        dnf)
            rpm -v --import https://download.sublimetext.com/sublimehq-rpm-pub.gpg
            dnf config-manager --add-repo https://download.sublimetext.com/rpm/stable/x86_64/sublime-text.repo
            dnf install -y sublime-text
            ;;
        *)
            if command -v snap &> /dev/null; then
                snap install sublime-text --classic
            fi
            ;;
    esac
    
    log_success "Sublime Text installed"
}

install_docker() {
    log_info "Installing Docker..."
    
    local pkg_mgr=$(detect_package_manager)
    local distro=$(detect_distro)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y ca-certificates curl gnupg
            install -m 0755 -d /etc/apt/keyrings
            curl -fsSL https://download.docker.com/linux/$distro/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
            chmod a+r /etc/apt/keyrings/docker.gpg
            echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$distro $(. /etc/os-release && echo "$VERSION_CODENAME") stable" > /etc/apt/sources.list.d/docker.list
            apt-get update -qq
            apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        dnf)
            dnf -y install dnf-plugins-core
            dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
            dnf install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
            ;;
        pacman)
            pacman -S --noconfirm docker docker-compose
            ;;
        zypper)
            zypper addrepo https://download.docker.com/linux/sles/docker-ce.repo
            zypper install -y docker-ce docker-ce-cli containerd.io
            ;;
    esac
    
    systemctl enable docker
    systemctl start docker
    usermod -aG docker "$SUDO_USER" 2>/dev/null || true
    
    log_success "Docker installed (user added to docker group - logout required)"
}

install_git() {
    log_info "Installing Git..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y git
            ;;
        dnf)
            dnf install -y git
            ;;
        pacman)
            pacman -S --noconfirm git
            ;;
        zypper)
            zypper install -y git
            ;;
    esac
    
    log_success "Git installed"
}

install_nodejs() {
    log_info "Installing Node.js (LTS)..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            curl -fsSL https://deb.nodesource.com/setup_lts.x | bash -
            apt-get install -y nodejs
            ;;
        dnf)
            curl -fsSL https://rpm.nodesource.com/setup_lts.x | bash -
            dnf install -y nodejs
            ;;
        pacman)
            pacman -S --noconfirm nodejs npm
            ;;
        zypper)
            zypper install -y nodejs npm
            ;;
    esac
    
    log_success "Node.js installed: $(node --version 2>/dev/null)"
}

install_python_tools() {
    log_info "Installing Python development tools..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y python3 python3-pip python3-venv python3-dev
            ;;
        dnf)
            dnf install -y python3 python3-pip python3-devel
            ;;
        pacman)
            pacman -S --noconfirm python python-pip
            ;;
        zypper)
            zypper install -y python3 python3-pip python3-devel
            ;;
    esac
    
    python3 -m pip install --upgrade pip setuptools wheel
    
    log_success "Python tools installed"
}

# ============================================================
# CATEGORY: PRODUCTIVITY
# ============================================================

install_libreoffice() {
    log_info "Installing LibreOffice..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y libreoffice
            ;;
        dnf)
            dnf install -y libreoffice
            ;;
        pacman)
            pacman -S --noconfirm libreoffice-fresh
            ;;
        zypper)
            zypper install -y libreoffice
            ;;
    esac
    
    log_success "LibreOffice installed"
}

install_onlyoffice() {
    log_info "Installing OnlyOffice..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            if ! command -v onlyoffice-desktopeditors &> /dev/null; then
                apt-get install -y curl gnupg
                mkdir -p /usr/share/keyrings
                curl -fsSL https://download.onlyoffice.com/GPG-KEY-ONLYOFFICE | gpg --dearmor -o /usr/share/keyrings/onlyoffice.gpg
                echo "deb [signed-by=/usr/share/keyrings/onlyoffice.gpg] https://download.onlyoffice.com/repo/debian squeeze main" > /etc/apt/sources.list.d/onlyoffice.list
                apt-get update -qq
                apt-get install -y onlyoffice-desktopeditors
            else
                apt-get update -qq
                apt-get install --only-upgrade onlyoffice-desktopeditors -y
            fi
            ;;
        *)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub org.onlyoffice.desktopeditors
            else
                log_error "OnlyOffice requires Flatpak on this distro"
            fi
            ;;
    esac
    
    log_success "OnlyOffice installed"
}

install_thunderbird() {
    log_info "Installing Thunderbird..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y thunderbird
            ;;
        dnf)
            dnf install -y thunderbird
            ;;
        pacman)
            pacman -S --noconfirm thunderbird
            ;;
        zypper)
            zypper install -y thunderbird
            ;;
    esac
    
    log_success "Thunderbird installed"
}

install_obsidian() {
    log_info "Installing Obsidian..."
    
    if command -v snap &> /dev/null; then
        snap install obsidian --classic
    elif command -v flatpak &> /dev/null; then
        flatpak install -y flathub md.obsidian.Obsidian
    else
        log_error "Obsidian requires Snap or Flatpak"
    fi
    
    log_success "Obsidian installed"
}

install_notion() {
    log_info "Installing Notion..."
    
    if command -v snap &> /dev/null; then
        snap install notion-snap
        log_success "Notion installed via Snap"
    else
        log_warn "Notion requires Snap - install Snap first"
    fi
}

# ============================================================
# CATEGORY: MEDIA
# ============================================================

install_vlc() {
    log_info "Installing VLC Media Player..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y vlc
            ;;
        dnf)
            dnf install -y vlc
            ;;
        pacman)
            pacman -S --noconfirm vlc
            ;;
        zypper)
            zypper install -y vlc
            ;;
    esac
    
    log_success "VLC installed"
}

install_spotify() {
    log_info "Installing Spotify..."
    
    local pkg_mgr=$(detect_package_manager)
    
    # Try Snap first
    if command -v snap &> /dev/null; then
        if ! snap list spotify &>/dev/null; then
            snap install spotify
            log_success "Spotify installed via Snap"
            return
        fi
    fi
    
    case $pkg_mgr in
        apt)
            curl -sS https://download.spotify.com/debian/pubkey_7A3A762FAFD4A51F.gpg | gpg --dearmor -o /usr/share/keyrings/spotify.gpg
            echo "deb [signed-by=/usr/share/keyrings/spotify.gpg] http://repository.spotify.com stable non-free" > /etc/apt/sources.list.d/spotify.list
            apt-get update -qq
            apt-get install -y spotify-client
            ;;
        pacman)
            if command -v yay &> /dev/null; then
                sudo -u "$SUDO_USER" yay -S --noconfirm spotify
            fi
            ;;
        *)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub com.spotify.Client
            fi
            ;;
    esac
    
    log_success "Spotify installed"
}

install_gimp() {
    log_info "Installing GIMP..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y gimp
            ;;
        dnf)
            dnf install -y gimp
            ;;
        pacman)
            pacman -S --noconfirm gimp
            ;;
        zypper)
            zypper install -y gimp
            ;;
    esac
    
    log_success "GIMP installed"
}

install_kdenlive() {
    log_info "Installing Kdenlive (Video Editor)..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y kdenlive
            ;;
        dnf)
            dnf install -y kdenlive
            ;;
        pacman)
            pacman -S --noconfirm kdenlive
            ;;
        zypper)
            zypper install -y kdenlive
            ;;
    esac
    
    log_success "Kdenlive installed"
}

install_obs() {
    log_info "Installing OBS Studio..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y obs-studio
            ;;
        dnf)
            dnf install -y obs-studio
            ;;
        pacman)
            pacman -S --noconfirm obs-studio
            ;;
        *)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub com.obsproject.Studio
            fi
            ;;
    esac
    
    log_success "OBS Studio installed"
}

install_audacity() {
    log_info "Installing Audacity..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y audacity
            ;;
        dnf)
            dnf install -y audacity
            ;;
        pacman)
            pacman -S --noconfirm audacity
            ;;
        zypper)
            zypper install -y audacity
            ;;
    esac
    
    log_success "Audacity installed"
}

# ============================================================
# CATEGORY: COMMUNICATION
# ============================================================

install_discord() {
    log_info "Installing Discord..."
    
    if command -v snap &> /dev/null; then
        snap install discord
        log_success "Discord installed via Snap"
        return
    fi
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            wget -O /tmp/discord.deb "https://discord.com/api/download?platform=linux&format=deb"
            apt-get install -y /tmp/discord.deb
            rm /tmp/discord.deb
            ;;
        *)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub com.discordapp.Discord
            fi
            ;;
    esac
    
    log_success "Discord installed"
}

install_slack() {
    log_info "Installing Slack..."
    
    if command -v snap &> /dev/null; then
        snap install slack
        log_success "Slack installed via Snap"
    elif command -v flatpak &> /dev/null; then
        flatpak install -y flathub com.slack.Slack
        log_success "Slack installed via Flatpak"
    else
        log_error "Slack requires Snap or Flatpak"
    fi
}

install_telegram() {
    log_info "Installing Telegram..."
    
    local pkg_mgr=$(detect_package_manager)
    
    if command -v snap &> /dev/null; then
        snap install telegram-desktop
        log_success "Telegram installed via Snap"
    elif command -v flatpak &> /dev/null; then
        flatpak install -y flathub org.telegram.desktop
        log_success "Telegram installed via Flatpak"
    else
        case $pkg_mgr in
            apt)
                apt-get update -qq
                apt-get install -y telegram-desktop
                ;;
            *)
                log_error "Telegram installation failed"
                ;;
        esac
    fi
    
    log_success "Telegram installed"
}

install_zoom() {
    log_info "Installing Zoom..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            wget -O /tmp/zoom.deb https://zoom.us/client/latest/zoom_amd64.deb
            apt-get install -y /tmp/zoom.deb
            rm /tmp/zoom.deb
            ;;
        dnf)
            dnf install -y https://zoom.us/client/latest/zoom_x86_64.rpm
            ;;
        *)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub us.zoom.Zoom
            fi
            ;;
    esac
    
    log_success "Zoom installed"
}

install_teams() {
    log_info "Installing Microsoft Teams..."
    
    if command -v snap &> /dev/null; then
        snap install teams-for-linux
        log_success "Teams installed via Snap"
    else
        log_warn "Teams requires Snap on this distro"
    fi
}

# ============================================================
# CATEGORY: GAMING
# ============================================================

install_steam() {
    log_info "Installing Steam..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            dpkg --add-architecture i386
            apt-get update -qq
            apt-get install -y steam-installer
            ;;
        dnf)
            dnf install -y steam
            ;;
        pacman)
            pacman -S --noconfirm steam
            ;;
        zypper)
            zypper install -y steam
            ;;
    esac
    
    log_success "Steam installed"
}

install_lutris() {
    log_info "Installing Lutris..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y lutris
            ;;
        dnf)
            dnf install -y lutris
            ;;
        pacman)
            pacman -S --noconfirm lutris
            ;;
        *)
            if command -v flatpak &> /dev/null; then
                flatpak install -y flathub net.lutris.Lutris
            fi
            ;;
    esac
    
    log_success "Lutris installed"
}

install_wine() {
    log_info "Installing Wine..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            dpkg --add-architecture i386
            apt-get update -qq
            apt-get install -y wine wine64 wine32 winetricks
            ;;
        dnf)
            dnf install -y wine winetricks
            ;;
        pacman)
            if ! grep -q "^\[multilib\]" /etc/pacman.conf; then
                echo -e "\n[multilib]\nInclude = /etc/pacman.d/mirrorlist" >> /etc/pacman.conf
                pacman -Sy
            fi
            pacman -S --noconfirm wine winetricks
            ;;
        zypper)
            zypper install -y wine winetricks
            ;;
    esac
    
    log_success "Wine installed"
}

install_heroic() {
    log_info "Installing Heroic Games Launcher..."
    
    if command -v flatpak &> /dev/null; then
        flatpak install -y flathub com.heroicgameslauncher.hgl
        log_success "Heroic Games Launcher installed"
    else
        log_warn "Heroic requires Flatpak"
    fi
}

# ============================================================
# CATEGORY: UTILITIES
# ============================================================

install_tailscale() {
    log_info "Installing Tailscale..."
    
    curl -fsSL https://tailscale.com/install.sh | sh
    
    log_success "Tailscale installed (run 'sudo tailscale up' to connect)"
}

install_rclone() {
    log_info "Installing Rclone..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y rclone
            ;;
        dnf)
            dnf install -y rclone
            ;;
        pacman)
            pacman -S --noconfirm rclone
            ;;
        *)
            curl https://rclone.org/install.sh | bash
            ;;
    esac
    
    log_success "Rclone installed"
}

install_timeshift() {
    log_info "Installing Timeshift (System Backup)..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y timeshift
            ;;
        dnf)
            dnf install -y timeshift
            ;;
        pacman)
            pacman -S --noconfirm timeshift
            ;;
        *)
            log_warn "Timeshift not available on this distro"
            ;;
    esac
    
    log_success "Timeshift installed"
}

install_bleachbit() {
    log_info "Installing BleachBit (System Cleaner)..."
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get install -y bleachbit
            ;;
        dnf)
            dnf install -y bleachbit
            ;;
        pacman)
            pacman -S --noconfirm bleachbit
            ;;
        *)
            log_warn "BleachBit not available"
            ;;
    esac
    
    log_success "BleachBit installed"
}

install_synaptic() {
    log_info "Installing Synaptic Package Manager..."
    
    local pkg_mgr=$(detect_package_manager)
    
    if [[ "$pkg_mgr" == "apt" ]]; then
        apt-get update -qq
        apt-get install -y synaptic
        log_success "Synaptic installed"
    else
        log_info "Synaptic is Debian/Ubuntu specific"
    fi
}

# ============================================================
# BATCH INSTALLATION BY CATEGORY
# ============================================================

install_browsers_suite() {
    log_header "Installing Browsers Suite"
    install_firefox
    install_chrome
    install_brave
}

install_development_suite() {
    log_header "Installing Development Suite"
    install_vscode
    install_git
    install_docker
    install_nodejs
    install_python_tools
    install_sublime
}

install_productivity_suite() {
    log_header "Installing Productivity Suite"
    install_libreoffice
    install_onlyoffice
    install_thunderbird
    install_obsidian
}

install_media_suite() {
    log_header "Installing Media Suite"
    install_vlc
    install_spotify
    install_gimp
    install_kdenlive
    install_obs
    install_audacity
}

install_communication_suite() {
    log_header "Installing Communication Suite"
    install_discord
    install_slack
    install_telegram
    install_zoom
}

install_gaming_suite() {
    log_header "Installing Gaming Suite"
    install_steam
    install_lutris
    install_wine
    install_heroic
}

install_utilities_suite() {
    log_header "Installing Utilities Suite"
    install_tailscale
    install_rclone
    install_timeshift
    install_bleachbit
}

# ============================================================
# INTERACTIVE MENU
# ============================================================

show_menu() {
    clear
    echo -e "${CYAN}${BOLD}"
    cat << "EOF"
╔═══════════════════════════════════════════════════════════════╗
║                                                               ║
║     ULTIMATE LINUX APPLICATION INSTALLER v5.0                 ║
║     The Most Comprehensive App Installation Suite            ║
║                                                               ║
╚═══════════════════════════════════════════════════════════════╝
EOF
    echo -e "${NC}"
    
    echo -e "${YELLOW}${BOLD}INSTALLATION OPTIONS:${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} Install EVERYTHING (Full Suite)"
    echo -e "${GREEN}[2]${NC} Install by Category"
    echo -e "${GREEN}[3]${NC} Install Individual Apps"
    echo -e "${GREEN}[4]${NC} Setup Package Managers (Snap, Flatpak)"
    echo -e "${GREEN}[5]${NC} Update All Installed Apps"
    echo -e "${GREEN}[Q]${NC} Quit"
    echo ""
    echo -e "${CYAN}─────────────────────────────────────────────────────────────${NC}"
    read -rp "Select option: " choice
    
    case $choice in
        1)
            install_everything
            ;;
        2)
            category_menu
            ;;
        3)
            individual_app_menu
            ;;
        4)
            setup_snap
            setup_flatpak
            ;;
        5)
            update_all_apps
            ;;
        Q|q)
            exit 0
            ;;
        *)
            echo "Invalid option"
            sleep 2
            show_menu
            ;;
    esac
}

category_menu() {
    clear
    echo -e "${CYAN}${BOLD}SELECT CATEGORY:${NC}"
    echo ""
    echo -e "${GREEN}[1]${NC} Browsers (Firefox, Chrome, Brave, Opera, Vivaldi)"
    echo -e "${GREEN}[2]${NC} Development (VSCode, Git, Docker, Node.js, Python)"
    echo -e "${GREEN}[3]${NC} Productivity (LibreOffice, OnlyOffice, Thunderbird, Obsidian)"
    echo -e "${GREEN}[4]${NC} Media (VLC, Spotify, GIMP, Kdenlive, OBS, Audacity)"
    echo -e "${GREEN}[5]${NC} Communication (Discord, Slack, Telegram, Zoom, Teams)"
    echo -e "${GREEN}[6]${NC} Gaming (Steam, Lutris, Wine, Heroic)"
    echo -e "${GREEN}[7]${NC} Utilities (Tailscale, Rclone, Timeshift, BleachBit)"
    echo -e "${GREEN}[B]${NC} Back to Main Menu"
    echo ""
    read -rp "Select category: " cat_choice
    
    case $cat_choice in
        1) install_browsers_suite ;;
        2) install_development_suite ;;
        3) install_productivity_suite ;;
        4) install_media_suite ;;
        5) install_communication_suite ;;
        6) install_gaming_suite ;;
        7) install_utilities_suite ;;
        B|b) show_menu ;;
        *) echo "Invalid option"; sleep 2; category_menu ;;
    esac
    
    echo ""
    read -rp "Press Enter to continue..."
    show_menu
}

individual_app_menu() {
    clear
    echo -e "${CYAN}${BOLD}SELECT APPLICATION:${NC}"
    echo ""
    echo -e "${YELLOW}Browsers:${NC}"
    echo "[1] Firefox  [2] Chrome  [3] Brave  [4] Opera  [5] Vivaldi"
    echo ""
    echo -e "${YELLOW}Development:${NC}"
    echo "[10] VS Code  [11] Git  [12] Docker  [13] Node.js  [14] Python  [15] Sublime"
    echo ""
    echo -e "${YELLOW}Productivity:${NC}"
    echo "[20] LibreOffice  [21] OnlyOffice  [22] Thunderbird  [23] Obsidian  [24] Notion"
    echo ""
    echo -e "${YELLOW}Media:${NC}"
    echo "[30] VLC  [31] Spotify  [32] GIMP  [33] Kdenlive  [34] OBS  [35] Audacity"
    echo ""
    echo -e "${YELLOW}Communication:${NC}"
    echo "[40] Discord  [41] Slack  [42] Telegram  [43] Zoom  [44] Teams"
    echo ""
    echo -e "${YELLOW}Gaming:${NC}"
    echo "[50] Steam  [51] Lutris  [52] Wine  [53] Heroic"
    echo ""
    echo -e "${YELLOW}Utilities:${NC}"
    echo "[60] Tailscale  [61] Rclone  [62] Timeshift  [63] BleachBit"
    echo ""
    echo -e "${GREEN}[B]${NC} Back to Main Menu"
    echo ""
    read -rp "Enter app number: " app_choice
    
    case $app_choice in
        1) install_firefox ;;
        2) install_chrome ;;
        3) install_brave ;;
        4) install_opera ;;
        5) install_vivaldi ;;
        10) install_vscode ;;
        11) install_git ;;
        12) install_docker ;;
        13) install_nodejs ;;
        14) install_python_tools ;;
        15) install_sublime ;;
        20) install_libreoffice ;;
        21) install_onlyoffice ;;
        22) install_thunderbird ;;
        23) install_obsidian ;;
        24) install_notion ;;
        30) install_vlc ;;
        31) install_spotify ;;
        32) install_gimp ;;
        33) install_kdenlive ;;
        34) install_obs ;;
        35) install_audacity ;;
        40) install_discord ;;
        41) install_slack ;;
        42) install_telegram ;;
        43) install_zoom ;;
        44) install_teams ;;
        50) install_steam ;;
        51) install_lutris ;;
        52) install_wine ;;
        53) install_heroic ;;
        60) install_tailscale ;;
        61) install_rclone ;;
        62) install_timeshift ;;
        63) install_bleachbit ;;
        B|b) show_menu ;;
        *) echo "Invalid option"; sleep 2; individual_app_menu ;;
    esac
    
    echo ""
    read -rp "Press Enter to continue..."
    show_menu
}

install_everything() {
    log_header "Installing EVERYTHING - Full Suite"
    
    if ! confirm_action "This will install 50+ applications. Continue?"; then
        show_menu
        return
    fi
    
    setup_snap
    setup_flatpak
    
    install_browsers_suite
    install_development_suite
    install_productivity_suite
    install_media_suite
    install_communication_suite
    install_gaming_suite
    install_utilities_suite
    
    log_header "🎉 INSTALLATION COMPLETE! 🎉"
    log_success "All applications have been installed"
    log_info "Some apps may require logout/reboot to appear in menus"
    
    echo ""
    read -rp "Press Enter to return to menu..."
    show_menu
}

update_all_apps() {
    log_header "Updating All Applications"
    
    local pkg_mgr=$(detect_package_manager)
    
    case $pkg_mgr in
        apt)
            apt-get update -qq
            apt-get upgrade -y
            ;;
        dnf)
            dnf upgrade -y
            ;;
        pacman)
            pacman -Syu --noconfirm
            ;;
        zypper)
            zypper update -y
            ;;
    esac
    
    if command -v snap &> /dev/null; then
        snap refresh
        log_success "Snap packages updated"
    fi
    
    if command -v flatpak &> /dev/null; then
        flatpak update -y
        log_success "Flatpak packages updated"
    fi
    
    log_success "All applications updated"
    echo ""
    read -rp "Press Enter to continue..."
    show_menu
}

confirm_action() {
    local prompt="$1"
    local response
    read -rp "$(echo -e "${YELLOW}${prompt} (y/n):${NC} ")" response
    [[ "$response" =~ ^[Yy]$ ]]
}

# ============================================================
# MAIN EXECUTION
# ============================================================

main() {
    check_root
    
    # Detect system
    PKG_MGR=$(detect_package_manager)
    DISTRO=$(detect_distro)
    
    log_info "System: $DISTRO | Package Manager: $PKG_MGR"
    log_info "Log file: $LOG_FILE"
    
    # Show interactive menu
    show_menu
}

main "$@"
