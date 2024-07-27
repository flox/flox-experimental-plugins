{writeShellApplication, fd, coreutils}:
writeShellApplication {
  name = "flox-build-manifest";
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

out="/tmp/store_$( { readlink -f "$FLOX_ENV" ; echo "$FLOX_ENV_PROJECT" ; }| sha256sum | head -c32)-$package"
export out

# Until they are executable
mkdir -p "$FLOX_ENV_CACHE"/
cp -f "$package_builds"/"$package" "$FLOX_ENV_CACHE"/builder
chmod +x "$FLOX_ENV_CACHE"/builder
"$FLOX_ENV"/activate "$FLOX_ENV_CACHE"/builder

# Create new env layering results of build script with original env.
# Note: read name from manifest.toml (includes version)
nix build --file ${./build.nix} \
  --extra-experimental-features nix-command \
  --argstr name "$package" \
  --argstr flox-env "$FLOX_ENV" \
  --argstr install-prefix "$out" \
  -L "$@"

popd
'';
}
