{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = _: {
    packages =
      builtins.mapAttrs (system: pkgs: {
        default = pkgs.callPackage ./pkgs/flox-build-proxy {};

        flox-build-manifest = pkgs.callPackage ./pkgs/flox-build-manifest {};
        flox-build-impure = pkgs.callPackage ./pkgs/flox-build-impure {};
        flox-build-incremental = pkgs.callPackage ./pkgs/flox-build-incremental {};
        flox-build-staged = pkgs.callPackage ./pkgs/flox-build-staged {};
        flox-build-carry = pkgs.callPackage ./pkgs/flox-build-carry {};
        lib = pkgs.lib // {
            mkArtifact = pkgs.callPackage ./pkgs/lib/mkArtifact {};
        };
      })
      _.nixpkgs.legacyPackages;
  };
}
