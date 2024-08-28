args @ {
  lib,
  runCommandNoCC,
  cacert,
  buildEnv,
  pkgs,
}: name: env: script: let
  hash = env.cacheKey or name;
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

          # Read-only source-files
          cp -Rs $source src
          chmod -R +w ./source
          cd src
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
  drv
