{writeShellApplication, fd, yq, jq, coreutils}:
writeShellApplication {
  name = "flox-build-carry";
  runtimeInputs = [ fd coreutils ];
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

carry_args=""
if [ -e ./result-1-carry ]; then
  carry_args="--argstr carry $(readlink -f ./result-1-carry)"
fi
# Create new env layering results of build script with original env.
# Note: read name from manifest.toml (includes version)
# shellcheck disable=SC2086
nix build --file ${./build.nix} \
  --argstr name "$package" \
  --argstr env "$(readlink -f "$FLOX_ENV")" \
  --arg script "$package_builds/$package" \
  --arg source "$FLOX_ENV_PROJECT" \
  --trace-verbose --print-out-paths \
  -L $carry_args out carry "$@"

popd

# Don't remove to allow development for builds that want to
# find things in $PREFIX.
# rm -rf "$PREFIX"
'';
}