{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = _: {
    packages =
      builtins.mapAttrs (system: pkgs: let p = pkgs.lib.makeScope pkgs.newScope (s: {
        default = s.callPackage ./pkgs/flox-proxy {};
        flox-proxy = s.callPackage ./pkgs/flox-proxy {};

        all = s.buildEnv {
          name = "builders";
          paths = [
            s.flox-build-manifest
            s.flox-build-impure
            s.flox-build-incremental
            s.flox-build-staged
            s.flox-build-carry
            s.flox-containerize-docker
          ];
        };
        flox-build-manifest = s.callPackage ./pkgs/flox-build-manifest {};
        flox-build-pure = s.callPackage ./pkgs/flox-build-pure {};
        flox-build-impure = s.callPackage ./pkgs/flox-build-impure {};
        flox-build-incremental = s.callPackage ./pkgs/flox-build-incremental {};
        flox-build-staged = s.callPackage ./pkgs/flox-build-staged {};
        flox-build-carry = s.callPackage ./pkgs/flox-build-carry {};
        flox-containerize-docker = s.callPackage ./pkgs/flox-containerize-docker {};
        lib = s.lib // {
            mkArtifact = s.callPackage ./lib/mkArtifact {};
        };
      }); in p.packages p)
      _.nixpkgs.legacyPackages;
  };
}
