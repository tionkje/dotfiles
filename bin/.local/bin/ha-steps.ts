#!/usr/bin/env node
import { readFile } from "node:fs/promises";
import { $ } from "./zx-polyfill.ts";

const SSID = "telenet-1837894";
const HA_URL = "https://ha.bastiaandeknudt.be";
const STEPS_ENTITY = "sensor.daily_steps";
const RAW_ENTITY = "sensor.steps";
const TOKEN_FILE = `${process.env.HOME}/.secrets/ha_token`;
const STALE_THRESHOLD_S = 60;

interface Color {
  r: number;
  g: number;
  b: number;
}

interface HAEntityState {
  state: string;
  last_updated: string;
}

const RED: Color = { r: 224, g: 27, b: 36 };
const BLUE: Color = { r: 53, g: 132, b: 228 };
const GREEN: Color = { r: 87, g: 227, b: 137 };

function lerp(a: number, b: number, t: number): number {
  return Math.round(a + (b - a) * t);
}

function lerpColor(from: Color, to: Color, t: number): string {
  const r = lerp(from.r, to.r, t);
  const g = lerp(from.g, to.g, t);
  const b = lerp(from.b, to.b, t);
  return `#${r.toString(16).padStart(2, "0")}${g.toString(16).padStart(2, "0")}${b.toString(16).padStart(2, "0")}`;
}

function stepsToColor(steps: number): string {
  if (steps <= 2000) return lerpColor(RED, RED, 0);
  if (steps <= 8000) return lerpColor(RED, BLUE, (steps - 2000) / 6000);
  if (steps <= 10000) return lerpColor(BLUE, GREEN, (steps - 8000) / 2000);
  return lerpColor(GREEN, GREEN, 0);
}

function fetchEntity(token: string, entityId: string): Promise<Response> {
  return fetch(`${HA_URL}/api/states/${entityId}`, {
    headers: { Authorization: `Bearer ${token}` },
  });
}

// Check WiFi — exit silently if not on home network
const { stdout: ssid } = await $({ nothrow: true })`iwgetid -r`;
if (ssid.trim() !== SSID) process.exit(0);

const token = (await readFile(TOKEN_FILE, "utf-8")).trim();

const [stepsRes, rawRes] = await Promise.all([
  fetchEntity(token, STEPS_ENTITY),
  fetchEntity(token, RAW_ENTITY),
]);

if (!stepsRes.ok || !rawRes.ok) {
  console.error(
    `HA API error: steps=${stepsRes.status} raw=${rawRes.status}`
  );
  process.exit(1);
}

const [stepsData, rawData] = (await Promise.all([
  stepsRes.json(),
  rawRes.json(),
])) as [HAEntityState, HAEntityState];

if (
  !stepsData.state ||
  stepsData.state === "unavailable" ||
  stepsData.state === "unknown"
)
  process.exit(0);

const steps = Number(stepsData.state);
if (Number.isNaN(steps)) {
  console.error(`Unexpected state value: ${stepsData.state}`);
  process.exit(1);
}

const lastUpdated = new Date(rawData.last_updated).getTime();
const staleMs = Date.now() - lastUpdated;
const disconnected = staleMs > STALE_THRESHOLD_S * 1000;

const color = stepsToColor(steps);
const icon = disconnected ? "⚡ " : "";

console.log(
  JSON.stringify({
    text: `${icon}<span color='${color}'>${steps}</span>`,
    tooltip: `Treadmill: ${steps} steps today${disconnected ? " (disconnected)" : ""}`,
  })
);
