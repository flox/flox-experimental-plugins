{
  pkgs ? import <nixpkgs> {},
  name,
  env,
  fetch_script ? null,
  fetch_hash ? "",
  fetch_set ? ''["*"]'',
  script,
  source,
}:
let
  new_source = pkgs.lib.fileset.toSource {
    root = source;
    fileset = pkgs.lib.fileset.gitTracked source;
  };
  just_locs = pkgs.lib.sources.sourceByRegex source (builtins.fromJSON (if fetch_set == "null" then ''[".*"]'' else fetch_set));

  # Fetcher.... no references allowed at all in output
  # TODO: name should only be based on the relevant lock files
  # eg, go.mod,go.sum, pacakges-lock.json, etc
  fetch = pkgs.runCommand "${name}-fetch-${builtins.substring 0 16 (builtins.hashString "sha256" new_source.outPath)}" {
    outputHashMode = "recursive";
    outputHashAlgo = "sha256";
    outputHash = if fetch_hash == null || fetch_hash == "null" then "" else fetch_hash;
    nativeBuildInputs = [ pkgs.cacert (builtins.storePath env)];
    source = just_locs;
    # meta.fromEnv = true; TODO: use env
  } ''
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      cp -r $source ./source
      chmod -R +w ./source
      cd source
      ls -alh
      echo running ${fetch_script}
      . ${fetch_script}
  '';

  stage2 = pkgs.runCommand name {
    nativeBuildInputs = [(builtins.storePath env) pkgs.cacert];
    source = new_source;
    __impure = true;
    fetch = fetch;
  } ''
      export SSL_CERT_FILE=${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt
      cp -r $source ./source
      chmod -R +w ./source
      cd source
      echo running ${script}
      . ${script}
  '';
in
  stage2
