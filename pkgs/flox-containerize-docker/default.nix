{writeShellApplication, coreutils, flox-proxy}:
writeShellApplication {
  name = "flox-containerize-docker";
  runtimeInputs = [ coreutils ];
  derivationArgs.postCheck = ''
    ln -s ${flox-proxy}/bin/flox $out/bin/flox
  '';
  text = ''
set -eaux -o pipefail

if [ -z "''${FLOX_ENV:-x}" ]; then
  echo "FLOX_ENV not set, exiting."
  exit 1
fi

engine=
if command -v docker &> /dev/null
then
    echo "docker found"
    engine=docker
fi
if command -v podman &> /dev/null
then
    echo "podman found"
    engine=podman
fi
if [ -z "''$engine" ]; then
    echo "No container engine found, exiting."
    exit 1
fi

name=$(echo "$FLOX_ENV_PROJECT" | base64 -w 0 | cut -c 1-12)
name="flox-builder-$name"

if  [ "''${1:-x}" == "prune" ]; then
	"$engine" stop "$name"
	"$engine" rm "$name"
	exit 0
fi

echo "run: 'flox containerize prune' to prune persistent images from $engine" >&2

pushd "$FLOX_ENV_PROJECT"

case $(uname -m) in
	arm64)
		platform=linux/arm64
		;;
	x86_64)
		platform=linux/amd64
		;;
	*)
		echo "Unsupported platform: $(uname -m)"
		exit 1
		;;
esac

flox_builder_info=$("$engine" ps -q -a -f name="$name")
if [ "''${flox_builder_info:-}" = "" ]; then
  "$engine" run -v "$FLOX_ENV_PROJECT":/work:ro -w /work -d --platform="$platform" --name "$name" -i ghcr.io/flox/flox:latest
fi

"$engine" start "$name"

# TODO: expose any "$@"?
engine_output=$("$engine" exec -i -w /work -e FLOX_DISABLE_METRICS=true "$name" flox containerize -o - | "$engine" load)

# TODO: Do in background?
"$engine" stop -t 1 "$name"

set +x
popd
echo
echo "used '$engine' and container '$name' to containerize $FLOX_ENV_DESCRIPTION"
echo
echo "$engine_output"

'';
}
