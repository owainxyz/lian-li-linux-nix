# Lian Li Linux! .. but for Nix?

Unofficial NixOS packaging for [sgtaziz/lian-li-linux](https://github.com/sgtaziz/lian-li-linux), the open-source Linux replacement for Lian Li's L-Connect 3. It puts fan control, RGB, and LCD/screen streaming for Lian Li hardware into your NixOS config, instead of installed by hand.

## What's in here

- **`lian-li-linux/default.nix`**: a `buildRustPackage` derivation for `lianli-daemon` and `lianli-gui`. It pulls in a Rust toolchain new enough for Slint, vendors Slint's git dependency, and patches the rpath of libraries the app `dlopen()`s at runtime instead of linking normally (`libxkbcommon-x11`, `libevdi.so.1`, assorted GL/Wayland/X11 libs). Upstream's own build doesn't handle any of that.
- **`module.nix`**: a NixOS module that installs the package, loads the `evdi` kernel module for desktop-mode LCD panels, and runs the daemon as a `systemd --user` service. It also rewrites the upstream udev rules to use Nix store paths instead of `/bin/sh` and `/bin/chmod`, since those paths don't exist on NixOS.

## Setup guide

### Quick install (just the binaries)

```sh
nix profile add github:owainxyz/lian-li-linux-nix
```

Gets you `lianli-daemon` and `lianli-gui` on `PATH`. You still need the udev rules and the `evdi` kernel module for full hardware access, which only the NixOS module sets up.

### Full NixOS integration

1. Clone this repo into your home directory:

   ```sh
   git clone https://github.com/owainxyz/lian-li-linux-nix.git ~/lian-li-linux-nix
   ```

2. Import the module in `configuration.nix` with an absolute path. Nix doesn't care where the file lives:

   ```nix
   { config, pkgs, ... }:
   {
     imports = [
       /home/user/lian-li-linux-nix/module.nix
     ];
   }
   ```

3. Rebuild and switch:

   ```sh
   sudo nixos-rebuild switch
   ```

4. Log out and back in, or run `systemctl --user start lianli-daemon`. The daemon runs as a user service from then on. Launch `lianli-gui` from your app menu or a terminal to control fans, RGB, and LCD panels.

If a device doesn't show up, check that it's covered by `lian-li-linux/99-lianli.rules`, and that you've replugged it (or rebooted) since the udev rules landed. The rules only apply permissions to devices plugged in *after* that.

## Supported hardware

Whatever upstream's udev rules cover. Full VID:PID list in `lian-li-linux/99-lianli.rules`.

### HID

| Device | Fan Control | RGB | LCD | Pump | Tested |
|---|---|---|---|---|---|
| UNI FAN SL / AL / SL Infinity / SL V2 / AL V2 | 4 groups | Yes | - | - | Yes |
| UNI FAN TL Controller | 4 ports | Yes | - | - | Yes |
| UNI FAN TL LCD | 4 ports | Yes | 400x400 | - | Yes |
| Galahad II Trinity AIO | Yes | Yes | - | Yes | Yes |
| HydroShift LCD AIO | Yes | Yes | 480x480 | Yes | Yes |
| Galahad II LCD / Vision AIO | Yes | Yes | 480x480 | Yes | Yes |

Galahad II LCD / Vision uses the same driver as HydroShift LCD AIO.

### Wireless (via TX/RX dongle)

| Device | Fan Control | RGB | LCD | Pump | Tested |
|---|---|---|---|---|---|
| UNI FAN TL V2 (LCD / LED) | Yes | Yes | 400x400 | - | Yes |
| UNI FAN SL V3 (LCD / LED) | Yes | Yes | 400x400 | - | Yes |
| UNI FAN SL-INF | Yes | Yes | - | - | Yes |
| UNI FAN CL / RL120 | Yes | Yes | - | - | - |
| HydroShift II LCD-C (Wireless) | Yes | Yes | - | Yes | Yes |
| HydroShift II LCD-S (Wireless) | Yes | Yes | - | Yes | Yes |
| Strimer Plus Wireless | - | Yes | - | - | Yes |
| Lancool 217 Wireless | - | Yes | - | - | - |
| Lancool V150 Wireless | Yes | Yes | - | - | - |
| Universal Screen 8.8" Wireless | - | Yes | - | - | - |

Both V1 (VID `0x0416`) and V2 (VID `0x1A86`) wireless dongles work. Bind devices through the GUI.

Wireless devices with an LCD still need a USB connection for the screen. The dongle alone can't drive the display.

### USB (standalone LCD)

| Device | LCD | Tested | Notes |
|---|---|---|---|
| HydroShift II LCD Circle | 480x480 | Yes | |
| HydroShift II LCD Square | 480x480 | Yes | |
| Lancool 207 Digital | 1472x720 | Yes | |
| Universal Screen 8.8" | 1920x480 | Yes | |
| Universal Screen 8.8" LED Ring | - | Yes | RGB only, no LCD |

## Notes

- Not affiliated with Lian Li or the upstream `lian-li-linux` project. This is just a Nix packaging of it.
- Pulls a `nixos-unstable` Rust toolchain via a pinned `fetchTarball`, since stable nixpkgs' `rustc` is too old to build Slint 1.16. Everything else (system libraries, glibc) stays on your regular channel.
- LCD/screen streaming shells out to `ffmpeg` for H.264 encoding. The package wraps `lianli-daemon` and `lianli-gui` so `ffmpeg` is always on `PATH` for them, regardless of what's installed system-wide.
- File pickers (uploading an image to an LCD panel) go through the XDG desktop portal. On non-GNOME/KDE window managers, you need a portal backend installed and routed to it, e.g.:

  ```nix
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = [ "gtk" ];
  ```

- MIT licensed, same as upstream.
