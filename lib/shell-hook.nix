# Shell hook generator for function-based wrapping
{ safeChainPackage }:

''
  # Safe-chain shell function wrappers
  # These use 'command' to find the real binary, avoiding recursion

  npm() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    # Create temp dir with real npm so aikido can find it
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p npm)" "$TEMP_BIN/npm" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-npm "$@"
  }

  npx() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p npx)" "$TEMP_BIN/npx" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-npx "$@"
  }

  yarn() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p yarn)" "$TEMP_BIN/yarn" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-yarn "$@"
  }

  pnpm() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p pnpm)" "$TEMP_BIN/pnpm" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-pnpm "$@"
  }

  pnpx() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p pnpx)" "$TEMP_BIN/pnpx" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-pnpx "$@"
  }

  bun() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p bun)" "$TEMP_BIN/bun" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-bun "$@"
  }

  bunx() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p bunx)" "$TEMP_BIN/bunx" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-bunx "$@"
  }

  pip() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p pip)" "$TEMP_BIN/pip" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-pip "$@"
  }

  pip3() {
    if [ "$1" = "--safe-chain-version" ]; then
      echo "safe-chain v${safeChainPackage.version} (active via Nix wrapper)"
      return 0
    fi
    local TEMP_BIN=$(mktemp -d)/bin
    mkdir -p "$TEMP_BIN"
    ln -s "$(command -v -p pip3)" "$TEMP_BIN/pip3" 2>/dev/null || true
    PATH="$TEMP_BIN:$PATH" ${safeChainPackage}/bin/aikido-pip3 "$@"
  }

  export SAFE_CHAIN_NIX_WRAPPED=1
  export -f npm npx yarn pnpm pnpx bun bunx pip pip3
''
