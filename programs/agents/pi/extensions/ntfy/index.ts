import { readFile } from "node:fs/promises";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { getKeybindings } from "@earendil-works/pi-tui";
import { installAutoNaming } from "./auto-name.mjs";
import { generateTitle } from "./title-request.mjs";
import { installNotifications } from "./notify.mjs";

export default function (pi: ExtensionAPI) {
  type PiConfig = {
    autoNameEnabled?: boolean;
    notificationsEnabled?: boolean;
    thresholdSeconds?: number;
    secretsFile?: string;
  };

  let configPromise: Promise<PiConfig> | undefined;
  const loadConfig = () => configPromise ??= readFile(
    new URL("./config.json", import.meta.url),
    "utf8",
  ).then((value) => JSON.parse(value) as PiConfig);

  let finishNaming = async () => {};
  finishNaming = installAutoNaming(
    pi,
    async () => (await loadConfig()).autoNameEnabled === true,
    { generateTitle },
  );
  installNotifications(
    pi,
    loadConfig,
    {
      beforeNotify: (ctx, outcome) => finishNaming(ctx, outcome),
      isInterrupt: (data: string) => getKeybindings().matches(data, "app.interrupt"),
    },
  );
}
