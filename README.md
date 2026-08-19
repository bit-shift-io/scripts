# Scripts

A bunch of linux scripts for various things.

Supports Arch (pacman/yay/paru), Debian (apt), Fedora (dnf) and SUSE (zypper). Primarily tested on Manjaro, EndeavourOS, CachyOS and Fedora.

## util.sh

Shared install helper. Detects the distro from `/etc/os-release` and picks the right package manager.

```
./util.sh -d            # print detected distro (arch|debian|fedora|suse)
./util.sh -i <pkgs>     # install packages
./util.sh -r <pkgs>     # remove packages
```

Package names can be either real names or logical names that resolve per distro (e.g. `base-devel`, `vulkan-drivers`, `sshfs`, `zed`). AUR-only packages are installed via paru/yay on Arch, COPR ones via dnf on Fedora, and skipped with a message elsewhere.

To add a distro-specific mapping, edit the `pkg` function in `util.sh`.

## Syncthing as a systemd service

Instructions on setting up syncthing to run as a systemd user service here: https://docs.syncthing.net/v1.0.0/users/autostart#how-to-set-up-a-user-service

In short, copy syncthing.service (I've a copy in the serivces dir) to ~/.config/systemd/user/

systemctl --user enable syncthing.service
systemctl --user start syncthing.service

systemctl --user status syncthing.service
