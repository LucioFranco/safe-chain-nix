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

        # Development shell
        devShells.default = pkgs.mkShell {
          buildInputs = [ pkgs.nodejs pkgs.python3 ];
          shellHook = ''
            echo "safe-chain-nix development shell"
            echo "Run 'nix flake check' to test"
          '';
        };

        # Automated checks
        inherit checks;
      }
    );
}
