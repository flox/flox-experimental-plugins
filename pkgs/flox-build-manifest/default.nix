{writeShellApplication, runCommand,dasel}:
writeShellApplication {
  name = "flox";
  text = ''
set -eauo pipefail
if [ -z "$FLOX_ENV" ]; then
  echo "FLOX_ENV not set, exiting."
  exit 1
fi

case "''${1-unset}" in
  "build") FLOX_BUILD_COMMAND="build" ;;
  "make") FLOX_BUILD_COMMAND="make" ;;
  "phase") FLOX_BUILD_COMMAND="phase" ;;
  *) exec "$FLOX_BIN" "$@" ;;
esac
shift

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

# Read name from manifest.toml
name="$(${dasel}/bin/dasel -w xml -f "$FLOX_ENV_CACHE"/../env/manifest.toml vars.name)"

# totally random to prevent collisions
PREFIX="/tmp/store_$( { readlink -f "$FLOX_ENV" ; echo "$FLOX_ENV_PROJECT" ; } | sha256sum | head -c32)-$name"
export PREFIX
export out="$PREFIX"

# NOTE: build_args are not correctly passed by the activate script
if [[ "''${FLOX_BUILD_COMMAND}" = "phase" ]]; then
  "$FLOX_ENV"/activate -c "''${build_args[*]}"
else
  # TODO: find a better place to put this, and/or clean up afterwards
  ${dasel}/bin/dasel -w xml -f "$FLOX_ENV_CACHE"/../env/manifest.toml vars."$FLOX_BUILD_COMMAND"_command > "$FLOX_ENV_CACHE"/../build_script.sh
  chmod +x "$FLOX_ENV_CACHE"/../build_script.sh

  "$FLOX_ENV"/activate "$FLOX_ENV_CACHE"/../build_script.sh
fi

# Create new env layering results of build script with original env.
# Note: read name from manifest.toml (includes version)
if [[ -e "$PREFIX" ]]; then
  if [[ "''${FLOX_BUILD_COMMAND}" != "phase" ]]; then
    nix build --file ${./build-manifest.nix} \
      --argstr name "$name" \
      --argstr flox-env "$FLOX_ENV" \
      --argstr install-prefix "$PREFIX" \
      -L "''${nix_args[@]}"
  fi
else
  echo "Build script did not produce a result in $PREFIX"
  exit 1
fi

popd

# Don't remove to allow development for builds that want to
# find things in $PREFIX.
# rm -rf "$PREFIX"
'';
}
