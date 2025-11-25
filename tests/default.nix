# Wrapper tests for safe-chain-nix
{ pkgs, safeChain }:

{
  # Test node binary is preserved after wrapping
  node-preserved = pkgs.runCommand "test-node-preserved" {
    nativeBuildInputs = [ (safeChain.wrapNode pkgs.nodejs) ];
  } ''
    echo "Testing node binary preservation..."
    node --version | grep -q "v" || { echo "FAIL: node --version failed"; exit 1; }
    echo "PASS: node binary works"
    touch $out
  '';

  # Test python binary is preserved after wrapping
  python-preserved = pkgs.runCommand "test-python-preserved" {
    nativeBuildInputs = [ (safeChain.wrapPython pkgs.python3) ];
  } ''
    echo "Testing python binary preservation..."
    python3 --version | grep -q "Python" || { echo "FAIL: python3 --version failed"; exit 1; }
    echo "PASS: python3 binary works"
    touch $out
  '';

  # Test shell hook syntax is valid bash
  shell-hook-syntax = pkgs.runCommand "test-shell-hook-syntax" {
    nativeBuildInputs = [ pkgs.bash ];
  } ''
    echo "Testing shell hook syntax..."
    cat > hook.sh << 'EOF'
    ${safeChain.shellHook}
    EOF
    bash -n hook.sh || { echo "FAIL: shell hook has syntax errors"; exit 1; }
    echo "PASS: shell hook syntax valid"
    touch $out
  '';

  # Test --safe-chain-version flag on npm wrapper
  npm-version-flag = pkgs.runCommand "test-npm-version-flag" {
    nativeBuildInputs = [ (safeChain.wrapNode pkgs.nodejs) ];
  } ''
    echo "Testing npm --safe-chain-version flag..."
    output=$(npm --safe-chain-version 2>&1)
    echo "$output" | grep -q "safe-chain v" || { echo "FAIL: version flag not working"; exit 1; }
    echo "$output" | grep -q "Nix wrapper" || { echo "FAIL: missing 'Nix wrapper' text"; exit 1; }
    echo "PASS: npm --safe-chain-version works"
    touch $out
  '';

  # Test --safe-chain-version flag on pip wrapper (when pip exists)
  pip-version-flag =
    let
      pythonWithPip = pkgs.python3.withPackages (ps: [ ps.pip ]);
    in
    pkgs.runCommand "test-pip-version-flag" {
      nativeBuildInputs = [ (safeChain.wrapPython pythonWithPip) ];
    } ''
      echo "Testing pip --safe-chain-version flag..."
      output=$(pip --safe-chain-version 2>&1)
      echo "$output" | grep -q "safe-chain v" || { echo "FAIL: version flag not working"; exit 1; }
      echo "$output" | grep -q "Nix wrapper" || { echo "FAIL: missing 'Nix wrapper' text"; exit 1; }
      echo "PASS: pip --safe-chain-version works"
      touch $out
    '';

  # Test wrapper symlinks exist for Node.js package managers
  node-wrapper-symlinks = pkgs.runCommand "test-node-wrapper-symlinks" {
    nativeBuildInputs = [ (safeChain.wrapNode pkgs.nodejs) ];
  } ''
    echo "Testing Node.js wrapper symlinks..."
    # Only test binaries that nodejs actually provides (npm and npx)
    for bin in npm npx; do
      if ! command -v $bin > /dev/null 2>&1; then
        echo "FAIL: $bin not found in PATH"
        exit 1
      fi
      echo "  $bin: found"
    done
    echo "PASS: Node.js wrapper symlinks exist"
    touch $out
  '';

  # Test wrapper symlinks exist for Python package managers (when pip exists)
  python-wrapper-symlinks =
    let
      pythonWithPip = pkgs.python3.withPackages (ps: [ ps.pip ]);
    in
    pkgs.runCommand "test-python-wrapper-symlinks" {
      nativeBuildInputs = [ (safeChain.wrapPython pythonWithPip) ];
    } ''
      echo "Testing Python wrapper symlinks..."
      for bin in pip pip3; do
        if ! command -v $bin > /dev/null 2>&1; then
          echo "FAIL: $bin not found in PATH"
          exit 1
        fi
        echo "  $bin: found"
      done
      echo "PASS: all Python wrapper symlinks exist"
      touch $out
    '';

  # Test SAFE_CHAIN_NIX_WRAPPED environment variable is set
  env-var-set = pkgs.runCommand "test-env-var-set" {
    nativeBuildInputs = [ pkgs.bash ];
  } ''
    echo "Testing SAFE_CHAIN_NIX_WRAPPED in shell hook..."
    cat > test.sh << 'SCRIPT'
    ${safeChain.shellHook}
    if [ "$SAFE_CHAIN_NIX_WRAPPED" != "1" ]; then
      echo "FAIL: SAFE_CHAIN_NIX_WRAPPED not set"
      exit 1
    fi
    echo "PASS: SAFE_CHAIN_NIX_WRAPPED=1"
    SCRIPT
    bash test.sh || exit 1
    touch $out
  '';
}
