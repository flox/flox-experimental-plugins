{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = _: {
    packages = builtins.mapAttrs (system: pkgs: {
      default = pkgs.callPackage ./pkgs/flox-build-manifest {};
    }) _.nixpkgs.legacyPackages;
  };
}
