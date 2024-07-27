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

package="''${1?"build target required, one of: ''${packages[@]-no packages found}"}";

if [[ ! "''${packages[*]}" =~ $package ]]; then
  echo "build target '$package' invalid, one of: ''${packages[*]-no packages found}"
  # TODO: fix fd's jemalloc problem, or use find
fi

shift;

pushd "$FLOX_ENV_PROJECT"

export NIX_CONFIG="extra-experimental-features = nix-command"


# This will first build a PKGNAME_fetch build then feed that to
# the build for PKGNAME, performing TOFU for the fetch in order
# to turn it into a FOD.

hash="$(fq -r '.vars.fetch_hash' .flox/env/manifest.toml)"
hash_set="$(fq -r '.vars.fetch_set' .flox/env/manifest.toml)"

read -r new_hash < <(
  nix build --file ${./build.nix} \
    --argstr name "$package" \
    --argstr env "$(readlink -f "$FLOX_ENV")" \
    --arg script "$package_builds/$package" \
    --arg fetch_script "$package_builds/''${package}_fetch" \
    --argstr fetch_hash "$hash" \
    --argstr fetch_set "$hash_set" \
    --arg source "$FLOX_ENV_PROJECT" \
    -L fetch "$@" \
        |& ${gawk}/bin/awk '/got:    sha256/{print $2}1{print $0 > "/dev/stderr"}' ) || echo "No change to hash '$hash' detected"

if [ "''${new_hash+x}" != "$hash" ] && [ -n "$new_hash" ]; then
  hash="$new_hash"
  # Ew.... use the better Rust manager to preserve structure/comments
  TMP_FILE="$(mktemp)"
  flox list -c > "$TMP_FILE"
  sed -i "$TMP_FILE" -e "s|^fetch_hash=.*$||"
  sed -i "$TMP_FILE" -e "s|^\[vars\]$|\[vars\]\nfetch_hash=\"$hash\"|"
  flox edit -f "$TMP_FILE"
  rm "$TMP_FILE"

  ## THIS chagnes the environment!!! arg
fi

nix build --file ${./build.nix} \
  --argstr name "$package" \
  --argstr env "$(readlink -f "$FLOX_ENV")" \
  --arg script "$package_builds/$package" \
  --arg fetch_script "$package_builds/''${package}_fetch" \
  --argstr fetch_hash "$hash" \
  --argstr fetch_set "$hash_set" \
  --arg source "$FLOX_ENV_PROJECT" \
  -L "$@" \

popd
'';
}
