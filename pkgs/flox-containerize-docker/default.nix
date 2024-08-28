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

if ! command -v docker &> /dev/null
then
    echo "docker could not be found"
    echo "TODO: support podman"
    exit 1
fi

name=$(echo "$FLOX_ENV_PROJECT" | base64 -w 0 | cut -c 1-12)
name="flox-builder-$name"

if  [ "''${1:-x}" == "prune" ]; then
	docker stop "$name"
	docker rm "$name"
	exit 0
fi

echo "run: 'flox containerize prune' to prune persistent images from docker" >&2

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

flox_builder_info=$(docker ps -q -a -f name="$name")
if [ "''${flox_builder_info:-}" = "" ]; then
  docker run -v "$FLOX_ENV_PROJECT":/work:ro -w /work -d --platform="$platform" --name "$name" -i ghcr.io/flox/flox:latest
fi

docker start "$name"

# TODO: expose any "$@"?
docker exec -i -w /work -e FLOX_DISABLE_METRICS=true "$name" flox containerize -o - | docker load

# TODO: Do in background?
docker stop -t 1 "$name"

popd
'';
}
