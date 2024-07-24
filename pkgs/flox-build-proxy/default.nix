{writeShellApplication}:
writeShellApplication {
  name = "flox";
  text = ''
    set -eau
    if [ -z "''${FLOX_ENV+x}" ]; then
      echo "FLOX_ENV not set, exiting."
      exit 1
    fi

    if [[ -n ''${1-} && $(command -v "flox-''${1}") ]]; then
      command="flox-''${1}"
      shift
      echo "Running $command" "$@"
      exec "$command" "$@"
    fi

    exec "$FLOX_BIN" "$@"
  '';
}
