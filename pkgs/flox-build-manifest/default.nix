{writeShellApplication, fq, coreutils}:
writeShellApplication {
  name = "flox-build-manifest";
  runtimeInputs = [ fq coreutils ];
  text = ''
set -eaux -o pipefail

if [ -z "''${FLOX_ENV+x}" ]; then
  echo "FLOX_ENV not set, exiting."
  exit 1
fi

# package_builds="$FLOX_ENV/package-builds.d" # not yet working?
readarray -t packages < <(fq '.build|keys[]' "$FLOX_ENV_CACHE"/../env/manifest.toml -r)

mkdir -p "$FLOX_ENV_CACHE"/../build_scripts/
for i in "''${packages[@]}"; do
  fq ".build.\"$i\".command" "$FLOX_ENV_CACHE"/../env/manifest.toml -r > "$FLOX_ENV_CACHE"/../build_scripts/"$i"
  chmod +x "$FLOX_ENV_CACHE"/../build_scripts/"$i"
done

package="''${1?"build target required, one of: ''${packages[*]-no packages found}"}";
shift;

pushd "$FLOX_ENV_PROJECT"

out="/tmp/store_$( { readlink -f "$FLOX_ENV" ; echo "$FLOX_ENV_PROJECT" ; }| sha256sum | head -c32)-$package"
export out

# Perform build script with activated environment
"$FLOX_ENV"/activate "$FLOX_ENV_CACHE"/../build_scripts/"$package"

# Create new env layering results of build script with original env.
# Note: read name from manifest.toml (includes version)
nix build --file ${./build-manifest.nix} \
  --extra-experimental-features nix-command \
  --argstr name "$package" \
  --argstr flox-env "$FLOX_ENV" \
  --argstr install-prefix "$out" \
  -L "$@"

popd
'';
}
