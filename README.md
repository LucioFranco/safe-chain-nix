# safe-chain-nix

Nix flake integration for [safe-chain](https://github.com/AikidoSec/safe-chain) - automatic malware protection for npm, yarn, pnpm, bun, and pip.

## Quick Start

Add to your `flake.nix`:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    safe-chain-nix.url = "github:AikidoSec/safe-chain-nix";
  };

  outputs = { nixpkgs, safe-chain-nix, ... }:
    let
      system = "x86_64-linux"; # or aarch64-linux, x86_64-darwin, aarch64-darwin
      pkgs = nixpkgs.legacyPackages.${system};
      safeChain = safe-chain-nix.lib.${system}.safeChain;
    in {
      devShells.${system}.default = pkgs.mkShell {
        buildInputs = [
          (safeChain.wrapNode pkgs.nodejs)
          (safeChain.wrapPython pkgs.python3)
        ];
      };
    };
}
```

Now when you enter the devShell, `npm`, `yarn`, `pip`, etc. are automatically protected.

## Wrapper Approaches

safe-chain-nix provides two ways to wrap package managers:

### 1. Binary Wrappers (Recommended)

Replaces package manager binaries with wrapped versions:

```nix
buildInputs = [
  (safeChain.wrapNode pkgs.nodejs)    # Wraps npm, npx, yarn, pnpm, bun
  (safeChain.wrapPython pkgs.python3) # Wraps pip, pip3
];
```

**Wrapped binaries:**
- Node.js: `npm`, `npx`, `yarn`, `pnpm`, `pnpx`, `bun`, `bunx`
- Python: `pip`, `pip3`

### 2. Shell Functions

Defines shell functions that intercept package manager commands:

```nix
buildInputs = [ pkgs.nodejs pkgs.python3 ];
shellHook = safeChain.shellHook;
```

### Comparison

| Aspect | Binary Wrappers | Shell Functions |
|--------|----------------|-----------------|
| Purity | Pure Nix derivation | Shell state |
| Portability | Works with any invocation | Shell-invoked only |
| Composability | Can pass to other derivations | Current shell only |
| Setup | Just add to buildInputs | Requires shellHook |
| Use when | Building packages, scripts | Interactive dev |

Both approaches provide identical security guarantees.

## Override Mechanism

### Default (npm registry)

```nix
safeChain.wrapNode pkgs.nodejs
```

### GitHub releases

```nix
(safeChain.override {
  source = "github";
  version = "1.0.25";
  hash = "sha256-...";
}).wrapNode pkgs.nodejs
```

### Build from source

```nix
(safeChain.override {
  source = "source";
  ref = "main";  # or a specific commit/tag
  hash = "sha256-...";
}).wrapNode pkgs.nodejs
```

## Verification

### Check Protection is Active

```bash
$ npm --safe-chain-version
safe-chain v1.0.25 (active via Nix wrapper)

$ pip3 --safe-chain-version
safe-chain v1.0.25 (active via Nix wrapper)
```

### Inspect Wrapper Path

```bash
$ which npm
/nix/store/xxx-wrapped-nodejs-20.x.x/bin/npm
```

### Test Malware Blocking

```bash
$ npm install safe-chain-test
# Expected: "blocked 1 malicious package" and exit code 1
```

## Platform Support

| Platform | Architecture | Status |
|----------|-------------|--------|
| Linux | x86_64 | Supported |
| Linux | aarch64 | Supported |
| macOS | x86_64 (Intel) | Supported |
| macOS | aarch64 (Apple Silicon) | Supported |

## API Reference

### `safeChain.wrapNode`

```nix
wrapNode :: derivation -> derivation
```

Takes a Node.js derivation and returns a new derivation with package managers wrapped.

### `safeChain.wrapPython`

```nix
wrapPython :: derivation -> derivation
```

Takes a Python derivation and returns a new derivation with pip/pip3 wrapped.

### `safeChain.shellHook`

```nix
shellHook :: string
```

Shell script string defining wrapper functions. Add to your `mkShell.shellHook`.

### `safeChain.override`

```nix
override :: { source?, version?, ref?, hash? } -> safeChain
```

Returns a new safeChain with different package source.

### `safeChain.version`

```nix
version :: string
```

The safe-chain version being used.

### `safeChain.package`

```nix
package :: derivation
```

The underlying safe-chain package derivation.

## Error Handling

safe-chain follows a **fail-closed** security model:

| Scenario | Behavior |
|----------|----------|
| Malware detected | Exit code 1, installation blocked |
| Proxy fails to start | Exit code 1, installation blocked |
| Network timeout | Exit code 1, installation blocked |
| safe-chain binary missing | Wrapper fails with clear error |

**No silent fallbacks** to unwrapped package managers.

## Troubleshooting

### "command not found: aikido-npm"

The safe-chain package isn't built correctly. Check:
- Hash values are correct
- Network access during build

### "proxy failed to start"

Safe-chain's proxy couldn't start:
- Check network permissions
- Verify Node.js is available

### Wrapper not intercepting commands

1. Check which binary is being used:
   ```bash
   which npm
   ```
2. For shell functions, ensure `shellHook` is evaluated
3. Verify with `npm --safe-chain-version`

### Hash mismatch errors

Update the hash in your override:
```nix
(safeChain.override {
  version = "1.0.25";
  hash = "sha256-CORRECT_HASH_HERE";
}).wrapNode pkgs.nodejs
```

## Running Tests

```bash
nix flake check
```

This runs all automated checks including:
- Version introspection tests
- Wrapper functionality tests
- Shell hook syntax validation

## License

AGPL-3.0-or-later (same as safe-chain)
