{writeShellApplication, fd, fq, gawk, coreutils}:
writeShellApplication {
  name = "flox-build-staged";
  runtimeInputs = [ fq fd coreutils ];
  text = ''
set -eaux -o pipefail

if [ -z "''${FLOX_ENV+x}" ]; then
  echo "FLOX_ENV not set, exiting."
  exit 1
fi

package_builds="$FLOX_ENV/package-builds.d"
readarray packages < <(fd '.' "$package_builds/" -x echo "{/}" )

package="''${1?"build target required, one of: ''${packages[*]-no packages found}"}";
shift;

pushd "$FLOX_ENV_PROJECT"

export NIX_CONFIG="extra-experimental-features = nix-command"


# This will first build a PKGNAME_fetch build then feed that to
# the build for PKGNAME, performing TOFU for the fetch in order
# to turn it into a FOD.

hash="$(fq -r '.vars.fetch_hash' .flox/env/manifest.toml)"
if [[ "$hash" = "null" ]]; then
  read -r hash < <(
  nix build --file ${./staging.nix} \
    --argstr name "$package" \
    --argstr env "$(readlink -f "$FLOX_ENV")" \
    --arg script "$package_builds/$package" \
    --arg fetch_script "$package_builds/''${package}_fetch" \
    --arg source "$FLOX_ENV_PROJECT" \
    -L fetch "$@" \
        |& ${gawk}/bin/awk '/got:    sha256/{print $2}1{print $0 > "/dev/stderr"}' )

  # Ew.... use the better Rust manager to preserve structure/comments
  TMP_FILE="$(mktemp)"
  flox list -c > "$TMP_FILE"
  sed -i "$TMP_FILE" -e "s|^\[vars\]$|\[vars\]\nfetch_hash=\"$hash\"|"
  cat "$TMP_FILE"
  flox edit -f "$TMP_FILE"
  rm "$TMP_FILE"
fi

nix build --file ${./staging.nix} \
  --argstr name "$package" \
  --argstr env "$(readlink -f "$FLOX_ENV")" \
  --arg script "$package_builds/$package" \
  --arg fetch_script "$package_builds/''${package}_fetch" \
  --argstr fetch_hash "$hash" \
  --arg source "$FLOX_ENV_PROJECT" \
  -L "$@" \

popd
'';
}



/*
{ lib, pkgs, inputs }: with pkgs; import ./staging.nix { inherit lib pkgs inputs; }

{
  nativeBuildInputs = [ go ];
  buildInputs = [ libjpeg ];

  # there are no references at all! Pure data from internet
  # Because, it will become a FOD, FOD's can't have references
  stage1Script = ''
      export HOME=$TMP
      go mod vendor
      mv vendor $out
  '';

  # no allowed refereces to stage1
  # Because we don't want to have runtime dependency on stage1
  stage2Script = ''
      export HOME=$TMP
      cp --recursive --reflink=auto --no-preserve=mode $stage1 vendor

      go build
      install -Dm 755 -t $out/bin flox-web
      $out/bin/flox-web -routes > $out/routes.md
      '';
}
*/
