function handler () {
  EVENT_DATA=$1
  echo "$EVENT_DATA" 1>&2;
  RESPONSE="Echoing request: '$EVENT_DATA'"

  ls -alh /nix/store
  env
  LD_LIBRARY_PATH= /nix/store/*-hello*/bin/hello
  echo $PWD
}
