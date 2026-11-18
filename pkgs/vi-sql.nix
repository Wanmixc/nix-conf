{ lib, buildGoModule, fetchFromGitHub, writableTmpDirAsHomeHook, versionCheckHook }:

buildGoModule rec {
  pname = "vi-sql";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "kopecmaciej";
    repo = "vi-sql";
    tag = "v${version}";
    hash = "sha256-ajRcNLjOSFz1yexAJ8dyq4J/QEofnUx4M1/kdMPeTxs=";
  };

  vendorHash = "sha256-UpziJIG99qE3sWTm2qKVWFE8Yl0+ZLuRFiaD4+Sdygs=";

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/kopecmaciej/vi-sql/internal/build.Version=${version}"
  ];

  nativeCheckInputs = [ writableTmpDirAsHomeHook ];
  nativeInstallCheckInputs = [ versionCheckHook ];
  doInstallCheck = true;

  meta = {
    description = "Terminal UI for SQL databases";
    homepage = "https://github.com/kopecmaciej/vi-sql";
    changelog = "https://github.com/kopecmaciej/vi-sql/releases/tag/v${version}";
    license = lib.licenses.asl20;
    mainProgram = "vi-sql";
  };
}
