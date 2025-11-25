# Binary wrappers for package managers
{ pkgs, safeChainPackage }:

let
  # Create a wrapper script for a specific binary
  mkBinWrapper = binName: pkgs.writeShellScript "safe-chain-${binName}" ''
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      exit 0
    fi
    export SAFE_CHAIN_NIX_WRAPPED=1
    exec ${safeChainPackage}/bin/aikido-${binName} "$@"
  '';

in
{
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
}
