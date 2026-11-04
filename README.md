# Lian Li Linux! .. but for Nix?

Unofficial NixOS packaging for [sgtaziz/lian-li-linux](https://github.com/sgtaziz/lian-li-linux), the open-source Linux replacement for Lian Li's L-Connect 3. Fan control, RGB and LCD streaming for Lian Li hardware, set up from your NixOS config.

Packages upstream **1.2.4** (Tauri GUI). The same packaging is proposed upstream in [sgtaziz/lian-li-linux#274](https://github.com/sgtaziz/lian-li-linux/pull/274); once that's merged you can point at upstream's flake directly.

## What's in here

- **`lian-li-linux/package.nix`**: builds `lianli-daemon`, `lianli-gui`, `lianli-control` and `lianli-session`, including the Vue frontend offline. Hardcoded `/usr/bin` paths (`systemctl`, `systemd-run`, `busctl`, `pkexec`, the project's own binaries) are patched to store paths, `ffmpeg` is put on `PATH`, and `libevdi` plus GL/GBM are added to the runpath.
- **`lian-li-linux/default.nix`**: pins the upstream commit and applies `package-lock.patch`, which fills in npm lockfile entries upstream is missing so the frontend builds in the sandbox.
- **`module.nix`**: NixOS module. Installs upstream's udev rules, user and system units, Polkit rule, tmpfiles locks and the `lianli` system account, and optionally loads `evdi`.

## Setup

### NixOS module (recommended)

```nix
{
  inputs.lian-li-linux-nix.url = "github:owainxyz/lian-li-linux-nix";

  outputs = { nixpkgs, lian-li-linux-nix, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        lian-li-linux-nix.nixosModules.default
        {
          services.lian-li-linux = {
            enable = true;
            evdi.enable = true;
          };
        }
      ];
    };
  };
}
```

| Option | Default | Description |
| --- | --- | --- |
| `enable` | `false` | Package, udev rules, units, Polkit rule, tmpfiles and `lianli` account |
| `systemService.enable` | `false` | Run the system daemon at boot as `lianli`. Leave off to pick user mode in the GUI |
| `evdi.enable` | `false` | Load the `evdi` kernel module for desktop-mode LCD panels |
| `package` | this flake | Override the package |

Rebuild with `sudo nixos-rebuild switch`, then log out and back in so `uaccess` applies to the USB devices. Pick **User (at login)** in the GUI on first launch. NixOS keeps `/etc/systemd` read-only, so system mode can only be set with `systemService.enable`, not from the GUI.

### Just the binaries

```sh
nix profile add github:owainxyz/lian-li-linux-nix
```

No udev rules or lock files this way, so the daemon won't start or reach devices without the module.

### Upgrading from 0.6.x

The module was rewritten for 1.x. The old unconditional import is now `services.lian-li-linux.enable = true`, and the user service comes from upstream's unit instead of one defined here. `lian-li-linux/99-lianli.rules` is gone, the rules come from upstream.

If an LCD stays blank after upgrading with a `generated frame ... exceeds LCD payload limit` warning, lower the image quality or pick the media again in the GUI.

## Supported hardware

Whatever upstream's udev rules cover. Full VID:PID list in upstream's [`packaging/udev/60-lianli.rules`](https://github.com/sgtaziz/lian-li-linux/blob/main/packaging/udev/60-lianli.rules).

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

- Not affiliated with Lian Li. This is just Nix packaging of upstream.
- Builds with the regular `nixos-unstable` Rust toolchain, no pinned tarball needed anymore.
- File pickers go through the XDG desktop portal. On non-GNOME/KDE window managers, install a portal backend, e.g.:

  ```nix
  xdg.portal.enable = true;
  xdg.portal.extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
  xdg.portal.config.common.default = [ "gtk" ];
  ```

- MIT licensed, same as upstream.
