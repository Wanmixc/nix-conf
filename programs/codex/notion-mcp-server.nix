{ buildNpmPackage, lib, makeWrapper, nodejs }:

buildNpmPackage {
  pname = "notion-mcp-server";
  version = "2.5.0";

  src = ./notion-mcp;
  npmDepsHash = "sha256-NSjXu0n8Gw//Jls9MnNuqhidBoQOg6ShdYKVvbffeXA=";

  dontNpmBuild = true;
  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/lib"
    cp -r node_modules "$out/lib/node_modules"
    makeWrapper ${nodejs}/bin/node "$out/bin/notion-mcp-server" \
      --add-flags "$out/lib/node_modules/@notionhq/notion-mcp-server/bin/cli.mjs"

    runHook postInstall
  '';

  meta = {
    description = "Official Notion MCP server";
    homepage = "https://github.com/makenotion/notion-mcp-server";
    license = lib.licenses.mit;
    mainProgram = "notion-mcp-server";
  };
}
