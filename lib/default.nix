# Main entry point for safe-chain-nix library
{ pkgs, packageLockPath }:

let
  # Default safe-chain version
  defaultVersion = "1.1.9";
  defaultNpmHash = "sha256-vRWbNBwy2yOyr8nfXwz7ng2rhl8q+QDoCEH45wUdpK4=";
  defaultNpmDepsHash = "sha256-CuuhqaYKcZHobfu1pOkxeDVcqKXODMjYbMPp9jR6mi4=";

  # Create safeChain library with override support
  mkSafeChain = { version ? defaultVersion, hash ? defaultNpmHash, npmDepsHash ? defaultNpmDepsHash }:
    let
      safeChainPackage = import ./package.nix {
        inherit pkgs version hash npmDepsHash packageLockPath;
      };

      wrappers = import ./wrappers.nix {
        inherit pkgs safeChainPackage;
      };

      shellHook = import ./shell-hook.nix {
        inherit safeChainPackage;
      };

    in
    {
      inherit (safeChainPackage) version;
      inherit (wrappers) wrapNode wrapPython;
      inherit shellHook;

      # Override mechanism
      override = newArgs: mkSafeChain (
        { inherit version hash npmDepsHash; } // newArgs
      );

      # Expose the underlying package
      package = safeChainPackage;
    };

in
{
  safeChain = mkSafeChain { };
  inherit mkSafeChain;
}
