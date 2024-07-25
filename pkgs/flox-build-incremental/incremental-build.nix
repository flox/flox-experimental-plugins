{
  pkgs ? import <nixpkgs> {},
  name,
  env,
  script,
  source,
}:
let
  orig_env = env;
  new_source = pkgs.lib.fileset.toSource {
    root = source;
    fileset = pkgs.lib.fileset.gitTracked source;
  };
  mkArtifact = pkgs.callPackage mkArtifact_recipe {};
  mkArtifact_recipe = args @ { # {{{
  lib,
  runCommandNoCC,
  cacert,
  buildEnv,
  pkgs,
}: name: env: script: let
  hash = "${name}-cache-${builtins.substring 0 12 (builtins.hashString "sha256" orig_env)}";
  drv = (lib.makeOverridable
    ({
      runCommandNoCC,
      cacert,
      buildEnv,
      ...
    }:
      runCommandNoCC name ({
          __impure = builtins.traceVerbose "warning, this is an impure build because __impure is set to true" true; # CA derivations, marked specially, and the final outPath is randomized
          nativeBuildInputs = [cacert];
          passthru.cleanCache = derivation {
            name = "clean-cache";
            system = pkgs.system;
            builder = "/bin/sh";
            __impureHostDeps = ["/nix/var/cache"];
            __impure = true;
            args = [
              "-c"
              ''
                # https://github.com/golang/go/issues/27161
                # Go marks cache entries as non-writable

                ${pkgs.coreutils}/bin/chmod -R u+w "/nix/var/cache/${hash}"
                ${pkgs.coreutils}/bin/rm -rf "/nix/var/cache/${hash}"
                ${pkgs.coreutils}/bin/touch $out
              ''
            ];
          };
        }
        // env) ''
        cached-build(){
          if [ ! -d /nix/var/cache ]; then
            return
          fi
          umask 002
          export SSL_CERT_FILE=${cacert}/etc/ssl/certs/ca-bundle.crt
          export NIX_CACHE=/nix/var/cache

          export HOME="$NIX_CACHE/${hash}"
          export TMPDIR="$HOME/tmp"
          export TEMPDIR="$HOME/tmp"
          export TMP="$HOME/tmp"
          export TEMP="$HOME/tmp"
          export NIX_BUILD_TOP="$HOME/tmp"
          export OLDPWD="$HOME/tmp"
          export CACHE="$HOME"
          mkdir -p "$TMPDIR"

        }
        cached-build

        # User experience starts here, Makefile, Docker, good parts

        ${script}

        # Avoid "suspcious ownership"
        # https://github.com/NixOS/nix/blob/532c70f531a0b61eb0ad506497209e302b8250f3/src/libstore/build/local-derivation-goal.cc#L2261-L2263
        chmod go-w -R $out

      '')
    args)
  .overrideDerivation (_: {
    __impureHostDeps = [(builtins.traceVerbose hash "/nix/var/cache")];
  });
in
  drv; # }}}

in
mkArtifact name {
  buildInputs = [
    (builtins.storePath env)
  ];
  source = new_source;
  meta.fromEnv = true;
} ''

  cp -r --no-preserve=mode $source ./source
  cd source
  eval "$(${builtins.storePath env}/activate)"

  . ${script}
''
