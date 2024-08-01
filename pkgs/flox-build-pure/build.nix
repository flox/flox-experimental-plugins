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
  meta.fromEnv = true;
} ''
  # Copy sources into sandbox
  # TODO: can we prevent copying **everything**?
  ls -alh ${new_source}
  cp -r  ${new_source} ./source
  chmod -R +w ./source
  cd source
  eval "$(${builtins.storePath env}/activate)"

  . ${script}
''
