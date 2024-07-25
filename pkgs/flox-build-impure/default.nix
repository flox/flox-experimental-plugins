{writeShellApplication, fd, yq, jq, coreutils}:
writeShellApplication {
  name = "flox-build-impure";
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

set -x
while [[ "$#" -gt 0 ]]; do
     case "$1" in
       --)                 break; ;;
       *) break; ;;
     esac
     shift;
done

pushd "$FLOX_ENV_PROJECT"

# Create new env layering results of build script with original env.
# Note: read name from manifest.toml (includes version)
nix build --file ${./impure-build.nix} \
  --argstr name "$package" \
  --argstr env "$(readlink -f "$FLOX_ENV")" \
  --argstr script "$package_builds/$package" \
  --argstr source "$FLOX_ENV_PROJECT" \
  -L "$@"

popd

# Don't remove to allow development for builds that want to
# find things in $PREFIX.
# rm -rf "$PREFIX"
'';
}
