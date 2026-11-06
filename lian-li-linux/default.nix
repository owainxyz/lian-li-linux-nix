{
  callPackage,
  fetchFromGitHub,
  applyPatches,
}:

callPackage ./package.nix {
  src = applyPatches {
    name = "lian-li-linux-src";
    src = fetchFromGitHub {
      owner = "sgtaziz";
      repo = "lian-li-linux";
      rev = "2172973cb68de0244032507666e844be55112c6d";
      fetchSubmodules = true;
      hash = "sha256-Ll18+qRGAGaJhsNczTiULbO7DoRqBsoTWi9VjZgU7oM=";
    };
    patches = [ ./jpeg-payload.patch ];
  };
}
