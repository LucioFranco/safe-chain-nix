# Binary wrappers for package managers
{ pkgs, safeChainPackage }:

let
  # Create a wrapper script for a specific binary
  # origBin is the path to the original unwrapped binary
  mkBinWrapper = binName: origBin: pkgs.writeShellScript "safe-chain-${binName}" ''
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      exit 0
    fi
    export SAFE_CHAIN_NIX_WRAPPED=1
    # Create temp directory with symlink to original binary
    # This allows aikido to find the real binary without recursion
    TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "${origBin}" "$TEMP_BIN/${binName}"
    # Prepend temp dir to PATH so aikido finds the real binary
    export PATH="$TEMP_BIN:$PATH"
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
        # Only wrap binaries that actually exist in nodejs
        if [ -e ${nodejs}/bin/npm ]; then
          rm -f $out/bin/npm
          ln -sf ${mkBinWrapper "npm" "${nodejs}/bin/npm"} $out/bin/npm
        fi
        if [ -e ${nodejs}/bin/npx ]; then
          rm -f $out/bin/npx
          ln -sf ${mkBinWrapper "npx" "${nodejs}/bin/npx"} $out/bin/npx
        fi
        if [ -e ${nodejs}/bin/yarn ]; then
          rm -f $out/bin/yarn
          ln -sf ${mkBinWrapper "yarn" "${nodejs}/bin/yarn"} $out/bin/yarn
        fi
        if [ -e ${nodejs}/bin/pnpm ]; then
          rm -f $out/bin/pnpm
          ln -sf ${mkBinWrapper "pnpm" "${nodejs}/bin/pnpm"} $out/bin/pnpm
        fi
        if [ -e ${nodejs}/bin/pnpx ]; then
          rm -f $out/bin/pnpx
          ln -sf ${mkBinWrapper "pnpx" "${nodejs}/bin/pnpx"} $out/bin/pnpx
        fi
        if [ -e ${nodejs}/bin/bun ]; then
          rm -f $out/bin/bun
          ln -sf ${mkBinWrapper "bun" "${nodejs}/bin/bun"} $out/bin/bun
        fi
        if [ -e ${nodejs}/bin/bunx ]; then
          rm -f $out/bin/bunx
          ln -sf ${mkBinWrapper "bunx" "${nodejs}/bin/bunx"} $out/bin/bunx
        fi
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

        # Link our wrapper scripts, passing the original binary paths
        ln -sf ${mkBinWrapper "pip" "${python}/bin/pip"} $out/bin/pip
        ln -sf ${mkBinWrapper "pip3" "${python}/bin/pip3"} $out/bin/pip3
      '';
    };
}
