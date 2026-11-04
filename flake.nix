{
  description = "Lian Li Linux! .. but for Nix?";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      systems = [
        "x86_64-linux"
        "aarch64-linux"
      ];
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system: f nixpkgs.legacyPackages.${system});
    in
    {
      packages = forAllSystems (pkgs: {
        lian-li-linux = pkgs.callPackage ./lian-li-linux { };
        default = self.packages.${pkgs.stdenv.hostPlatform.system}.lian-li-linux;
      });

      overlays.default = final: _: {
        lian-li-linux = final.callPackage ./lian-li-linux { };
      };

      nixosModules.default = {
        imports = [ ./module.nix ];
        nixpkgs.overlays = [ self.overlays.default ];
      };

      formatter = forAllSystems (pkgs: pkgs.nixfmt);
    };
}
