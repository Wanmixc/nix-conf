{ inputs, system, ... }:
let
  # Hermes Agent — "the agent that grows with you" by Nous Research.
  # https://github.com/NousResearch/hermes-agent
  #
  # Installed declaratively from the project's own flake rather than the
  # imperative `curl | sh` installer. The upstream flake builds the Python
  # app with uv2nix and exposes several package variants:
  #
  #   default  — full: bundles ~17 optional integration groups (anthropic,
  #              bedrock, voice, messaging, modal, …). Heaviest build.
  #   minimal  — core agent only; optional integrations lazy-install at runtime
  #              into a writable dir (the /nix/store copy stays read-only).
  #   messaging— minimal + discord/telegram/slack preinstalled.
  #   tui / web / desktop — the respective front-ends.
  #
  # Use the messaging variant so gateway dependencies (including Telegram)
  # are available in the immutable Nix environment. The minimal variant cannot
  # lazy-install them because its Python environment lives in /nix/store.
  hermes = inputs.hermes-agent.packages.${system}.messaging;
in
{
  home.packages = [ hermes ];
}
