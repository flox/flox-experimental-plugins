{
  pkgs ? import <nixpkgs> {},
  name,
  env,
  script,
  source,
}:
pkgs.runCommand name {
  buildInputs = [env pkgs.cacert];
  meta.fromEnv = true;
} ''
  eval "$(${env}/activate)"
  export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
  export PREFIX="$out"

  # Copy sources into sandbox
  # TODO: can we prevent copying **everything**?
  cp -r --no-preserve=mode ${source}/* ./

  ${script}
''
