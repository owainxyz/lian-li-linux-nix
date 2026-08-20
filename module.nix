{ config, pkgs, lib, ... }:

let
  unstablePkgs = import (builtins.fetchTarball {
    url = "https://github.com/NixOS/nixpkgs/archive/refs/heads/nixos-unstable.tar.gz";
    sha256 = "1vkilgbwjpyhjjyx1i75wcinqxgk5smy1gmqyvl41v262awl6jlv";
  }) { system = pkgs.stdenv.hostPlatform.system; };

  lianli-linux = unstablePkgs.callPackage ./lian-li-linux {
    evdi = config.boot.kernelPackages.evdi;
  };
in
{
  environment.systemPackages = [ lianli-linux ];

  services.udev.extraRules = lib.replaceStrings
    [ "/bin/sh" "/bin/chmod" ]
    [ "${pkgs.bash}/bin/sh" "${pkgs.coreutils}/bin/chmod" ]
    (builtins.readFile ./lian-li-linux/99-lianli.rules);

  boot.extraModulePackages = [ config.boot.kernelPackages.evdi ];
  boot.kernelModules = [ "evdi" ];

  systemd.user.services.lianli-daemon = {
    description = "Lian Li Device Daemon";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = "${lianli-linux}/bin/lianli-daemon";
      Restart = "on-failure";
      RestartSec = 5;
    };
  };
}
