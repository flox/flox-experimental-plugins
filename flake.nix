{
  inputs.__functor.url = "git+ssh://git@github.com/flox/minicapacitor?ref=functor";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";

  outputs = _: _ {
        recipes.packages = ./pkgs;
  };
}
