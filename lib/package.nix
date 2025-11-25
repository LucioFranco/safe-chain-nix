# Build safe-chain package from npm registry
{ pkgs, version, hash, npmDepsHash, packageLockPath }:

let
  # Fetch the npm tarball
  npmTarball = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@aikidosec/safe-chain/-/safe-chain-${version}.tgz";
    inherit hash;
  };

  # Create source with tarball extracted and package-lock.json added
  src = pkgs.runCommand "safe-chain-${version}-src" { } ''
    mkdir -p $out
    tar -xzf ${npmTarball} -C $out --strip-components=1
    cp ${packageLockPath} $out/package-lock.json
  '';

  # Pre-fetch npm dependencies
  npmDeps = pkgs.fetchNpmDeps {
    src = builtins.dirOf packageLockPath;
    hash = npmDepsHash;
  };

in
pkgs.buildNpmPackage {
  pname = "safe-chain";
  inherit version src npmDeps;

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
}
