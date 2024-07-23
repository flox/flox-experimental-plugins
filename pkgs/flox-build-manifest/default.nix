{writeShellApplication, runCommand,dasel}:
writeShellApplication {
  name = "flox";
  text = ''
set -eau
if [ -z "$FLOX_ENV" ]; then
  echo "FLOX_ENV not set, exiting."
  exit 1
fi
case "$1" in
  "build") FLOX_BUILD_COMMAND="build" ;;
  "make") FLOX_BUILD_COMMAND="make" ;;
  *) exec "$FLOX_BIN" "$@" ;;
esac
shift

pushd "$FLOX_ENV_PROJECT"

# calculate temp path of same strlen as eventual "install-prefix" pkg storePath
# TODO: make this stable, hashed on cwd + $FLOX_ENV for reuse

# Read name from manifest.toml
name="$(${dasel}/bin/dasel -w xml -f "$FLOX_ENV_CACHE"/../env/manifest.toml vars.name)"

# totally random to prevent collisions
PREFIX="/tmp/store_$(readlink -f "$FLOX_ENV" | sha256sum | head -c32)-$name"
export PREFIX

# Perform build script with activated environment
# TODO: eventually render the build-script to the rendered env.
# $FLOX_ENV/activate $FLOX_ENV/activate.d/build-script.bash


# TODO: find a better place to put this, and/or clean up afterwards
${dasel}/bin/dasel -w xml -f "$FLOX_ENV_CACHE"/../env/manifest.toml vars."$FLOX_BUILD_COMMAND"_command > "$FLOX_ENV_CACHE"/../build_script.sh
chmod +x "$FLOX_ENV_CACHE"/../build_script.sh
"$FLOX_ENV"/activate "$FLOX_ENV_CACHE"/../build_script.sh

# Create new env layering results of build script with original env.
# Note: read name from manifest.toml (includes version)
nix build --file ${./build-manifest.nix} \
  --argstr name "$name" \
  --argstr flox-env "$FLOX_ENV" \
  --argstr install-prefix "$PREFIX" \
  -L "$@"

popd

# Don't remove to allow development for builds that want to
# find things in $PREFIX.
# rm -rf "$PREFIX"
'';
}
