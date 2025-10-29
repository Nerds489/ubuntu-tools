# Quick Start Guide

## 📋 Before You Begin

This repository contains powerful system optimization scripts for Linux. Please read this guide before running.

## ⚡ Quick Installation

```bash
# Clone the repository
git clone https://github.com/YOUR_USERNAME/ultimate-linux-suite.git
cd ultimate-linux-suite

# Make scripts executable
chmod +x *.sh

# Run the system optimizer
sudo ./ultimate_system_optimizer.sh

# (Optional) Run the app installer
sudo ./ultimate_app_installer.sh
```

## ⚠️ Important Notes

- **Always run on a test system first** or create a backup
- Scripts require root/sudo privileges
- Reboot required after system optimization
- Backup files are stored in `/var/backups/ultimate-optimizer/`
- Logs are stored in `/var/log/ultimate-optimizer-*.log`

## 🔍 What Gets Changed

### System Optimizer
- Memory management (swap, ZRAM, swappiness)
- Kernel parameters optimization
- I/O scheduler configuration
- CPU governor settings
- Network stack tuning
- Desktop environment optimizations
- Security hardening (optional)

### App Installer
- 50+ popular applications
- Multiple package sources (apt, snap, flatpak)
- Category-based installation
- Automatic dependency resolution

## 🆘 Rollback Instructions

If you need to undo changes:

```bash
# Restore original config files
sudo cp /var/backups/ultimate-optimizer/sysctl.conf.BACKUP /etc/sysctl.conf
sudo cp /var/backups/ultimate-optimizer/fstab.BACKUP /etc/fstab

# Reload settings
sudo sysctl -p

# Reboot
sudo reboot
```

## 📚 Full Documentation

See [README.md](README.md) for complete documentation.

## 🤝 Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for contribution guidelines.

## 📄 License

MIT License - See [LICENSE](LICENSE) file.
