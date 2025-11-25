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

        # Import library with package-lock.json path
        lib = import ./lib {
          inherit pkgs;
          packageLockPath = ./package-lock.json;
        };

        inherit (lib) safeChain mkSafeChain;

        # Import tests
        checks = import ./tests {
          inherit pkgs safeChain;
        };

      in
      {
        # Library exports
        lib = {
          inherit safeChain mkSafeChain;
        };

        # Package exports
        packages = {
          default = safeChain.package;
          safe-chain = safeChain.package;
        };

        # Development shells
        devShells = {
          # Default shell without wrappers (for development)
          default = pkgs.mkShell {
            buildInputs = [ pkgs.nodejs pkgs.python3 ];
            shellHook = ''
              echo "safe-chain-nix development shell"
              echo "Run 'nix flake check' to test"
            '';
          };

          # Test shell WITH safe-chain wrappers enabled
          test = pkgs.mkShell {
            buildInputs = [
              (safeChain.wrapNode pkgs.nodejs)
              (safeChain.wrapPython pkgs.python3)
            ];
            shellHook = ''
              echo "=== Safe-chain TEST shell ==="
              echo "This shell has safe-chain wrappers enabled for npm/pnpm/yarn/pip"
              echo ""
              echo "Wrapper version:"
              npm --safe-chain-version 2>&1 || echo "  ERROR: --safe-chain-version failed"
              echo ""
              echo "Try these commands to test:"
              echo "  npm --version"
              echo "  npm help"
              echo "  npm"
              echo ""
            '';
          };
        };

        # Automated checks
        inherit checks;
      }
    );
}
