{ compiler ? "ghc865" }:

let
  overlayShared = pkgsNew: pkgsOld: {
    haskell = pkgsOld.haskell // {
      packages = pkgsOld.haskell.packages // {
        "${compiler}" = pkgsOld.haskell.packages."${compiler}".override (old: {
            overrides =
              let
                failOnAllWarnings = pkgsOld.haskell.lib.failOnAllWarnings;

                extension =
                  haskellPackagesNew: haskellPackagesOld: {
                    hs-kafka-minimal-example =
                      failOnAllWarnings
                        (haskellPackagesNew.callCabal2nix
                          "hs-kafka-minimal-example"
                          ../.
                          { }
                        );
                  };

              in
                pkgsNew.lib.fold
                  pkgsNew.lib.composeExtensions
                  (old.overrides or (_: _: {}))
                  [ (pkgsNew.haskell.lib.packagesFromDirectory { directory = ./.; })

                    extension
                  ];
          }
        );
      };
    };
  };

  bootstrap = import <nixpkgs> { };

  nixpkgs = builtins.fromJSON (builtins.readFile ./nixpkgs.json);

  src = bootstrap.fetchFromGitHub {
    owner = "NixOS";
    repo  = "nixpkgs";
    inherit (nixpkgs) rev sha256;
  };

  pkgs = import src {
    config = {};
    overlays = [ overlayShared ];
  };

in
  rec {
    inherit (pkgs.haskell.packages."${compiler}")
      hs-kafka-minimal-example
    ;

    shell-hs-kafka-minimal-example = (pkgs.haskell.lib.doBenchmark pkgs.haskell.packages."${compiler}".hs-kafka-minimal-example).env;
  }
