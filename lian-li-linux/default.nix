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
      rev = "896593b3b84f0d9225471222a319c4c95144c635";
      fetchSubmodules = true;
      hash = "sha256-DcxjUs0d9auuaiRzJkDNVeh3XX2XCQ/GV99k5X1y+CQ=";
    };
    patches = [ ./package-lock.patch ];
  };
}
