#!/usr/bin/env zx

import { spawn } from "child_process";
import { createInterface } from "readline";

$.verbose = false;

interface VolumeState {
  volume: number;
  muted: boolean;
}

async function getVolumeState(): Promise<VolumeState> {
  const result = await $`wpctl get-volume @DEFAULT_AUDIO_SINK@`;
  const line = result.stdout.trim();
  const parts = line.split(/\s+/);
  const volume = Math.round(parseFloat(parts[1]) * 100);
  const muted = line.includes("[MUTED]");
  return { volume, muted };
}

async function emit(): Promise<void> {
  const state = await getVolumeState();
  console.log(JSON.stringify(state));
}

await emit();

const pactl = spawn("pactl", ["subscribe"], {
  stdio: ["ignore", "pipe", "inherit"],
});

const rl = createInterface({ input: pactl.stdout! });

let debounceTimer: ReturnType<typeof setTimeout> | null = null;
const DEBOUNCE_MS = 50;

rl.on("line", (line: string) => {
  if (!/Event 'change' on (sink|server|card)/.test(line)) return;

  if (debounceTimer) clearTimeout(debounceTimer);
  debounceTimer = setTimeout(() => {
    emit();
  }, DEBOUNCE_MS);
});

pactl.on("exit", (code: number | null) => {
  process.exit(code ?? 1);
});
