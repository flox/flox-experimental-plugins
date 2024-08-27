{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = _: {
    packages =
      builtins.mapAttrs (system: pkgs: rec {
        default = pkgs.callPackage ./pkgs/flox-build-proxy {};

        all = pkgs.buildEnv {
          name = "builders";
          paths = [
            flox-build-manifest
            flox-build-impure
            flox-build-incremental
            flox-build-staged
            flox-build-carry
            flox-containerize-docker
          ];
        };
        flox-build-manifest = pkgs.callPackage ./pkgs/flox-build-manifest {};
        flox-build-pure = pkgs.callPackage ./pkgs/flox-build-pure {};
        flox-build-impure = pkgs.callPackage ./pkgs/flox-build-impure {};
        flox-build-incremental = pkgs.callPackage ./pkgs/flox-build-incremental {};
        flox-build-staged = pkgs.callPackage ./pkgs/flox-build-staged {};
        flox-build-carry = pkgs.callPackage ./pkgs/flox-build-carry {};
        flox-containerize-docker = pkgs.callPackage ./pkgs/flox-containerize-docker {};
        lib = pkgs.lib // {
            mkArtifact = pkgs.callPackage ./pkgs/lib/mkArtifact {};
        };
      })
      _.nixpkgs.legacyPackages;
  };
}
