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
  carry_temp=$PWD/carry_temp
  mkdir $carry_temp

  echo "Copying $source to ./source"
  cp -TR $source ./source
  chmod -R +w ./source
  cd ./source
  ${if carry == "" then "" else ''
     echo "Copying $carry_in to ."
     cp -nTR $carry_in .
     chmod -R +w .
  ''}
  eval "$(${builtins.storePath env}/activate)"

  . ${script}

  echo "Copying CWD to $carry"
  cp -TR . $carry
''
