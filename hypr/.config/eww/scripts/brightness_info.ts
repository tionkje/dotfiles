#!/usr/bin/env zx

import { spawn } from "child_process";
import { createInterface } from "readline";
import { readFile } from "fs/promises";

$.verbose = false;

const BACKLIGHT_DIR = "/sys/class/backlight/intel_backlight";
const MAX = parseInt(await readFile(`${BACKLIGHT_DIR}/max_brightness`, "utf-8"));

interface BrightnessState {
  brightness: number;
}

async function getBrightness(): Promise<BrightnessState> {
  const raw = parseInt(
    await readFile(`${BACKLIGHT_DIR}/actual_brightness`, "utf-8")
  );
  const brightness = Math.round((raw / MAX) * 100);
  return { brightness };
}

async function emit(): Promise<void> {
  const state = await getBrightness();
  console.log(JSON.stringify(state));
}

await emit();

const inotify = spawn(
  "inotifywait",
  ["-m", "-e", "modify", `${BACKLIGHT_DIR}/actual_brightness`],
  { stdio: ["ignore", "pipe", "inherit"] }
);

const rl = createInterface({ input: inotify.stdout! });

let debounceTimer: ReturnType<typeof setTimeout> | null = null;
const DEBOUNCE_MS = 50;

rl.on("line", () => {
  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    emit();
  }, DEBOUNCE_MS);
});

inotify.on("exit", (code: number | null) => {
  process.exit(code ?? 1);
});
