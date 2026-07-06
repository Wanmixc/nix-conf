{ lib, pkgs, ... }:

let
  ollama-bin = pkgs.stdenv.mkDerivation rec {
    pname = "ollama-bin";
    version = "0.31.1";

    src = pkgs.fetchurl {
      url = "https://github.com/ollama/ollama/releases/download/v${version}/ollama-linux-amd64.tar.zst";
      sha256 = "sha256-0pc4HvwTZFH2+rud1kSmf3D+UcFoFaDEqV/w4yejr7Q=";
    };

    nativeBuildInputs = [ pkgs.zstd pkgs.autoPatchelfHook ];

    buildInputs = [
      pkgs.stdenv.cc.cc.lib # libstdc++.so.6, libgcc_s.so.1
      pkgs.vulkan-loader    # libvulkan.so.1
    ];

    # libcuda.so.1 is provided by the host NVIDIA driver at runtime, not at
    # build time. The CUDA backends are optional; ollama falls back to CPU/Vulkan
    # when the driver is absent, so it is safe to ignore here.
    autoPatchelfIgnoreMissingDeps = [ "libcuda.so.1" ];

    unpackPhase = ''
      mkdir -p source
      tar --zstd -xf $src -C source
    '';

    installPhase = ''
      mkdir -p $out/bin $out/lib
      cp -r source/bin/* $out/bin/ 2>/dev/null || true
      cp -r source/lib/* $out/lib/ 2>/dev/null || true
    '';

    meta = with lib; {
      description = "Get up and running with large language models locally (binary release)";
      homepage = "https://github.com/ollama/ollama";
      license = licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  home.packages = [ ollama-bin ];
}
