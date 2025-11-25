# Shell hook generator for function-based wrapping
{ safeChainPackage }:

''
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
''
