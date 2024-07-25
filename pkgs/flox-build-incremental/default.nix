{writeShellApplication, fd, yq, jq, coreutils}:
writeShellApplication {
  name = "flox-build-incremental";
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

RED='\033[0;31m'
NC='\033[0m' # No Color
printf "''${RED}INFO: ''${NC}%s\n" "Must have allowed-impure-host-deps set to /nix/var/cache (and more for OSX)"
printf "''${RED}INFO: ''${NC}%s\n" "this is a daemon setting"
printf "''${RED}INFO: ''${NC}%s\n" "Also, this directory must exist and have group write permissions"
printf "''${RED}INFO: ''${NC}%s\n" "the nixbld group or whatever will perform the build"
nix config show | grep allowed-impure-host-deps | grep -F "/nix/var/cache"

# Create new env layering results of build script with original env.
# Note: read name from manifest.toml (includes version)
nix build --file ${./incremental-build.nix} \
  --argstr name "$package" \
  --argstr env "$(readlink -f "$FLOX_ENV")" \
  --arg script "$package_builds/$package" \
  --arg source "$FLOX_ENV_PROJECT" \
  --trace-verbose --print-out-paths \
  -L "$@"

popd

# Don't remove to allow development for builds that want to
# find things in $PREFIX.
# rm -rf "$PREFIX"
'';
}
