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
  # We use `minimal` to keep the build light; switch to `.default` for the
  # batteries-included variant, or `.messaging` if you want the chat gateways
  # baked in (lazy-install can't write to /nix/store).
  hermes = inputs.hermes-agent.packages.${system}.minimal;
in
{
  home.packages = [ hermes ];
}
