{ lib, buildGoModule, go_1_25, fetchFromGitHub, makeWrapper, openssh }:

(buildGoModule.override { go = go_1_25; }) rec {
  pname = "neossh";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "WhiteRoseLK";
    repo = "neossh";
    rev = "v${version}";
    hash = "sha256-P3976KydcHz+dyS4zd3TeZaTm5x69EgYTE2ttMzv0lI=";
  };

  vendorHash = "sha256-+dyMJshTQrCmFx1mdLVlUVhuXxtZxk/BD2GJakW0wXY=";
  subPackages = [ "cmd" ];
  ldflags = [ "-s" "-w" "-X main.version=${version}" ];
  nativeBuildInputs = [ makeWrapper ];

  # Upstream command tests initialize a file logger before running.
  preCheck = ''
    export XDG_STATE_HOME="$TMPDIR/neossh-state"
  '';

  postInstall = ''
    mv "$out/bin/cmd" "$out/bin/neossh"
    wrapProgram "$out/bin/neossh" --prefix PATH : ${lib.makeBinPath [ openssh ]}
  '';

  meta = {
    description = "Interactive terminal SSH manager";
    homepage = "https://github.com/WhiteRoseLK/neossh";
    license = lib.licenses.asl20;
    mainProgram = "neossh";
  };
}
