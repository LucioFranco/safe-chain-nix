{
  description = "Nix flake for safe-chain - automatic malware protection for package managers";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};

        # Default safe-chain version
        defaultVersion = "1.1.9";
        defaultNpmHash = "sha256-vRWbNBwy2yOyr8nfXwz7ng2rhl8q+QDoCEH45wUdpK4=";
        defaultNpmDepsHash = "sha256-CuuhqaYKcZHobfu1pOkxeDVcqKXODMjYbMPp9jR6mi4=";

        # Build safe-chain package from npm registry
        mkSafeChainFromNpm = { version ? defaultVersion, hash ? defaultNpmHash, npmDepsHash ? defaultNpmDepsHash }:
          let
            # Fetch the npm tarball
            npmTarball = pkgs.fetchurl {
              url = "https://registry.npmjs.org/@aikidosec/safe-chain/-/safe-chain-${version}.tgz";
              inherit hash;
            };

            # Create a source with the tarball extracted and package-lock.json added
            src = pkgs.runCommand "safe-chain-${version}-src" {} ''
              mkdir -p $out
              tar -xzf ${npmTarball} -C $out --strip-components=1
              cp ${./package-lock.json} $out/package-lock.json
            '';

            # Pre-fetch npm dependencies using the local package-lock.json
            npmDeps = pkgs.fetchNpmDeps {
              src = ./.;  # Use local dir for package-lock.json
              hash = npmDepsHash;
            };
          in pkgs.buildNpmPackage {
            pname = "safe-chain";
            inherit version src;

            inherit npmDeps;

            dontNpmBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/bin $out/lib/safe-chain
              cp -r . $out/lib/safe-chain/
              cp -r node_modules $out/lib/safe-chain/

              # Create wrapper scripts for all aikido binaries
              for bin in npm npx yarn pnpm pnpx bun bunx pip pip3 python python3; do
                if [ -f $out/lib/safe-chain/bin/aikido-$bin.js ]; then
                  makeWrapper ${pkgs.nodejs}/bin/node $out/bin/aikido-$bin \
                    --add-flags "$out/lib/safe-chain/bin/aikido-$bin.js"
                fi
              done

              runHook postInstall
            '';

            nativeBuildInputs = [ pkgs.makeWrapper ];

            meta = with pkgs.lib; {
              description = "Prevents malware installation through npm/yarn/pnpm/bun/pip";
              homepage = "https://github.com/AikidoSec/safe-chain";
              license = licenses.agpl3Plus;
              platforms = platforms.unix;
            };
          };

        # Create safeChain library with override support
        mkSafeChain = { version ? defaultVersion, hash ? defaultNpmHash, npmDepsHash ? defaultNpmDepsHash }:
          let
            safeChainPackage = mkSafeChainFromNpm { inherit version hash npmDepsHash; };

            # Create a wrapper script for a specific binary
            mkBinWrapper = binName: pkgs.writeShellScript "safe-chain-${binName}" ''
              if [ "$1" = "--safe-chain-version" ]; then
                echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                exit 0
              fi
              export SAFE_CHAIN_NIX_WRAPPED=1
              exec ${safeChainPackage}/bin/aikido-${binName} "$@"
            '';
          in {
            inherit (safeChainPackage) version;

            # Binary wrapper for Node.js package managers
            wrapNode = nodejs:
              pkgs.symlinkJoin {
                name = "wrapped-${nodejs.name}";
                paths = [ nodejs ];
                postBuild = ''
                  # Replace package manager binaries with safe-chain wrappers
                  for bin in npm npx yarn pnpm pnpx bun bunx; do
                    if [ -e $out/bin/$bin ]; then
                      rm $out/bin/$bin
                    fi
                  done

                  # Link our wrapper scripts
                  ln -sf ${mkBinWrapper "npm"} $out/bin/npm
                  ln -sf ${mkBinWrapper "npx"} $out/bin/npx
                  ln -sf ${mkBinWrapper "yarn"} $out/bin/yarn
                  ln -sf ${mkBinWrapper "pnpm"} $out/bin/pnpm
                  ln -sf ${mkBinWrapper "pnpx"} $out/bin/pnpx
                  ln -sf ${mkBinWrapper "bun"} $out/bin/bun
                  ln -sf ${mkBinWrapper "bunx"} $out/bin/bunx
                '';
              };

            # Binary wrapper for Python package managers
            wrapPython = python:
              pkgs.symlinkJoin {
                name = "wrapped-${python.name}";
                paths = [ python ];
                postBuild = ''
                  # Replace pip binaries with safe-chain wrappers
                  for bin in pip pip3; do
                    if [ -e $out/bin/$bin ]; then
                      rm $out/bin/$bin
                    fi
                  done

                  # Link our wrapper scripts
                  ln -sf ${mkBinWrapper "pip"} $out/bin/pip
                  ln -sf ${mkBinWrapper "pip3"} $out/bin/pip3
                '';
              };

            # Shell hook for function-based wrapping
            shellHook = ''
              # Safe-chain shell function wrappers
              npm() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-npm "$@"
              }

              npx() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-npx "$@"
              }

              yarn() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-yarn "$@"
              }

              pnpm() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-pnpm "$@"
              }

              pnpx() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-pnpx "$@"
              }

              bun() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-bun "$@"
              }

              bunx() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-bunx "$@"
              }

              pip() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-pip "$@"
              }

              pip3() {
                if [ "$1" = "--safe-chain-version" ]; then
                  echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
                  return 0
                fi
                ${safeChainPackage}/bin/aikido-pip3 "$@"
              }

              export SAFE_CHAIN_NIX_WRAPPED=1
              export -f npm npx yarn pnpm pnpx bun bunx pip pip3
            '';

            # Override mechanism
            override = newArgs: mkSafeChain (
              { inherit version hash npmDepsHash; } // newArgs
            );

            # Expose the underlying package
            package = safeChainPackage;
          };

        safeChain = mkSafeChain { };

      in {
        # Library exports
        lib = {
          inherit safeChain mkSafeChain;
        };

        # Package exports
        packages = {
          default = safeChain.package;
          safe-chain = safeChain.package;
        };

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.nodejs pkgs.python3 ];
          shellHook = ''
            echo "safe-chain-nix development shell"
            echo "Run 'nix flake check' to test"
          '';
        };

        # Automated checks
        checks = {
          # Test node binary preserved
          node-preserved = pkgs.runCommand "test-node-preserved" {
            nativeBuildInputs = [ (safeChain.wrapNode pkgs.nodejs) ];
          } ''
            node --version | grep -q "v" && touch $out
          '';

          # Test python binary preserved
          python-preserved = pkgs.runCommand "test-python-preserved" {
            nativeBuildInputs = [ (safeChain.wrapPython pkgs.python3) ];
          } ''
            python3 --version | grep -q "Python" && touch $out
          '';

          # Test shell hook syntax
          shell-hook-syntax = pkgs.runCommand "test-shell-hook" {
            nativeBuildInputs = [ pkgs.bash ];
          } ''
            cat > /tmp/hook.sh << 'EOF'
            ${safeChain.shellHook}
            EOF
            bash -n /tmp/hook.sh && touch $out
          '';
        };
      }
    );
}
