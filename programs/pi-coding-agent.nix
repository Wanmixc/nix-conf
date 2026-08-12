{ pkgs, lib, ... }:
let
  version = "0.84.1";

  # sha512 SRI integrity for @earendil-works workspace tarballs.
  # The published npm-shrinkwrap.json omits these, which breaks `npm ci`
  # under Nix. Values come from `npm view @earendil-works/<pkg>@<version>
  # dist.integrity` and must be refreshed together with `version`.
  workspaceIntegrity = {
    pi-ai = "sha512-wMsAdJMxuNri08vLqTyYVI201DQQezGhPSTkzYsHdw5dYX3rCNwEmSvpaAwhi7ELKI/2tE/CEgSWg/6iRxSgdQ==";
    pi-agent-core = "sha512-evyzXYWCLQGmcaBYHlmSku02r8qoN4SGI60GZABo6iV+H+nqX+P9ud8fEZ4GmRq9mUSREvvfX+w9dA9ThF9C6w==";
    pi-client = "sha512-/V5hGHE4Zq+jG0GtwIB9PyBUOGd6gBLZ7lkQYFKchKnxYHeH3rmWC5xw4kpnZKKBuBuFTdLVbU9vEjlAGMMb2A==";
    pi-protocol = "sha512-Ox1pciyeSPGEEUcxvR0/dJcrY7C6hrEGA8y71rOsvSIUlXN1Cbp/be/eoL71OGDBk5O97TeQPfWN6Ju/2Ehjww==";
    pi-telemetry = "sha512-180/xGJtsq7IoR3p9EKWjRd0e9M4DkxInhlo9xyD7prDC7Qrhqq+nhvwrW0lFjPfXcEI2FSHmGCSyvSJE9GsaQ==";
    pi-tui = "sha512-udeXFbgEhJ6JiB0uguwNVNkDy2FENfmtQwPcY+/iJ8GWeq18wkal1tKqa5YyeH0IqtX1vG0cGh8zfSYzyzVuLA==";
  };

  rawSrc = pkgs.fetchurl {
    url = "https://registry.npmjs.org/@earendil-works/pi-coding-agent/-/pi-coding-agent-${version}.tgz";
    hash = "sha256-ppoYWWAX6RlV/Q/Wd75p+rW26gHVsGIHvO407hUivCA=";
  };

  # Unpack the npm tarball, backfill the missing workspace integrities so both
  # dependency fetching and `npm ci` see a valid lockfile, and drop the
  # devDependencies (which the published shrinkwrap omits) since dist/ is
  # already built and we never compile.
  src = pkgs.runCommand "pi-coding-agent-src-${version}" {
    nativeBuildInputs = [ pkgs.jq ];
  } ''
    mkdir -p "$out"
    tar xzf ${rawSrc} --strip-components=1 -C "$out"
    cd "$out"
    jq '
        .packages["node_modules/@earendil-works/pi-ai"].integrity = "${workspaceIntegrity.pi-ai}"
      | .packages["node_modules/@earendil-works/pi-agent-core"].integrity = "${workspaceIntegrity.pi-agent-core}"
      | .packages["node_modules/@earendil-works/pi-client"].integrity = "${workspaceIntegrity.pi-client}"
      | .packages["node_modules/@earendil-works/pi-protocol"].integrity = "${workspaceIntegrity.pi-protocol}"
      | .packages["node_modules/@earendil-works/pi-telemetry"].integrity = "${workspaceIntegrity.pi-telemetry}"
      | .packages["node_modules/@earendil-works/pi-tui"].integrity = "${workspaceIntegrity.pi-tui}"
    ' npm-shrinkwrap.json > npm-shrinkwrap.json.tmp
    mv npm-shrinkwrap.json.tmp npm-shrinkwrap.json
    jq 'del(.devDependencies)' package.json > package.json.tmp
    mv package.json.tmp package.json
  '';

  pi-coding-agent = pkgs.buildNpmPackage {
    pname = "pi-coding-agent";
    inherit version src;

    npmDepsHash = "sha256-FfwODI+m5Jts0PrjA9mFa+Mp9QT17/ejixg84RGXGe4=";

    # The published tarball already ships a built dist/, so there is nothing
    # to compile; only install the pinned dependencies.
    dontNpmBuild = true;
    npmFlags = [ "--ignore-scripts" "--omit=dev" ];

    nativeBuildInputs = [ pkgs.makeBinaryWrapper ];

    # pi shells out to ripgrep and fd at runtime.
    postFixup = ''
      wrapProgram "$out/bin/pi" \
        --prefix PATH : ${lib.makeBinPath [ pkgs.ripgrep pkgs.fd ]}
    '';

    meta = {
      description = "Coding agent CLI with read, bash, edit, write tools and session management";
      homepage = "https://pi.dev/";
      license = lib.licenses.mit;
      mainProgram = "pi";
    };
  };
in
{
  home.packages = [ pi-coding-agent ];
}
