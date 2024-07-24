{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = _: {
    packages =
      builtins.mapAttrs (system: pkgs: {
        default = pkgs.callPackage ./pkgs/flox-build-proxy {};

        flox-build-manifest =
          pkgs.callPackage ./pkgs/flox-build-manifest {};

        flox-build-impure = pkgs.callPackage ./pkgs/flox-build-impure {};
      })
      _.nixpkgs.legacyPackages;
  };
}
