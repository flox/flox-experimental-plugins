{
  pkgs ? import <nixpkgs> {},
  name,
  env,
  script,
  source,
}:
let
  new_source = pkgs.lib.fileset.toSource {
    root = source;
    fileset = pkgs.lib.fileset.gitTracked source;
  };
in
pkgs.runCommand name {
  buildInputs = [(builtins.storePath env) pkgs.cacert];
  meta.fromEnv = true;
} ''
  export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
  export PREFIX="$out"

  # Copy sources into sandbox
  # TODO: can we prevent copying **everything**?
  ls -alh ${new_source}
  cp -r --no-preserve=mode ${new_source} ./source
  cd source
  eval "$(${env}/activate)"

  . ${script}
''
