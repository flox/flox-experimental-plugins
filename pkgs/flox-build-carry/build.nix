{
  pkgs ? import <nixpkgs> {},
  name,
  env,
  script,
  source,
  carry ? ""
}:
let
  orig_env = env;
  new_source = pkgs.lib.fileset.toSource {
    root = source;
    fileset = pkgs.lib.fileset.gitTracked source;
  };

in
pkgs.runCommand name ({
  buildInputs = [
    (builtins.storePath env)
  ];
  source = new_source;
  meta.fromEnv = true;
  outputs = [ "out" "carry" ];
} // (if carry == "" then {} else {
  carry_in = builtins.storePath carry;
}))
''
  cp -TRv $source ./source
  chmod -R +w ./source
  cd source
  ${if carry == "" then "" else ''
     cp -nTRv $carry_in .
     chmod -R +w .
  ''}
  eval "$(${builtins.storePath env}/activate)"

  set -x
  . ${script}
  mkdir -p $carry
  cp -rt $carry .
  set +x
''
