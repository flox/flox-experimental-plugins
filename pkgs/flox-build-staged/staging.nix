{
  pkgs ? import <nixpkgs> {},
  name,
  env,
  fetch_script ? null,
  fetch_hash ? "",
  script,
  source,
}:
let
  new_source = pkgs.lib.fileset.toSource {
    root = source;
    fileset = pkgs.lib.fileset.gitTracked source;
  };

  # Fetcher.... no references allowed at all in output
  fetch = pkgs.runCommand "${name}-fetch-${builtins.substring 0 16 (builtins.hashString "sha256" new_source.outPath)}" {
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = fetch_hash;
    nativeBuildInputs = [(builtins.storePath env)];
    source = new_source;
  } ''
      cp -r $source ./source
      chmod -R +w ./source
      cd source
      echo running ${fetch_script}
      . ${fetch_script}
  '';

  stage2 = pkgs.runCommand name {
    nativeBuildInputs = [(builtins.storePath env)];
    source = new_source;
    fetch = fetch;
  } ''
      cp -r $source ./source
      chmod -R +w ./source
      cd source
      echo running ${script}
      . ${script}
  '';
in
  stage2
