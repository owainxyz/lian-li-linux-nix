{
  description = "Lian Li Linux! .. but for Nix?";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in
    {
      packages.${system} = {
        lian-li-linux = pkgs.callPackage ./lian-li-linux {
          evdi = pkgs.linuxPackages.evdi;
        };
        default = self.packages.${system}.lian-li-linux;
      };

      nixosModules.default = import ./module.nix;
    };
}
