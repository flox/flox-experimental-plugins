{writeShellApplication, fd, yq, jq, coreutils}:
writeShellApplication {
  name = "flox-build-manifest";
  runtimeInputs = [ yq jq fd coreutils ];
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

build_args=()
nix_args=()
args=()
target=build_args
while [[ "$#" -gt 0 ]]; do
     case "$1" in
       --)  build_args=("''${args[@]}");  args=(); target="nix_args"; ;;
       *)   args=("''${args[@]}" "$1");  ;;
     esac
     shift;
done
declare -a "$target"="''${args[*]}"

pushd "$FLOX_ENV_PROJECT"

# calculate temp path of same strlen as eventual "install-prefix" pkg storePath
# TODO: make this stable, hashed on cwd + $FLOX_ENV for reuse


# totally random to prevent collisions
PREFIX="/tmp/store_$( { readlink -f "$FLOX_ENV" ; echo "$FLOX_ENV_PROJECT" ; }| sha256sum | head -c32)-$package"
export PREFIX
export out="$PREFIX"

# Perform build script with activated environment
"$FLOX_ENV"/activate "$package_builds/$package"

# Create new env layering results of build script with original env.
# Note: read name from manifest.toml (includes version)
nix build --file ${./build-manifest.nix} \
  --argstr name "$package" \
  --argstr flox-env "$FLOX_ENV" \
  --argstr install-prefix "$PREFIX" \
  --arg activate "$activate" \
  -L "$@"

popd

# Don't remove to allow development for builds that want to
# find things in $PREFIX.
# rm -rf "$PREFIX"
'';
}
