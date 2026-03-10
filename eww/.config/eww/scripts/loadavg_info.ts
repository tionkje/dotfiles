#!/usr/bin/env zx

const SVG_PATH = "/tmp/eww-loadavg-graph.svg";
const WIDTH = 40;
const HEIGHT = 800;
const MAX_POINTS = 80;
const POLL_MS = 2000;

const COLORS = {
  load1: "#ff6b6b",
  load5: "#ffd93d",
  load15: "#6bcb77",
  cpuLine: "#33ccff",
};

const CPU_COUNT = os.cpus().length;

interface LoadSample {
  load1: number;
  load5: number;
  load15: number;
}

const LEGEND_HEIGHT = 80;
const GRAPH_HEIGHT = HEIGHT - LEGEND_HEIGHT;
const GRAPH_TOP = 0;

function readLoadAvg(): LoadSample {
  const data = fs.readFileSync("/proc/loadavg", "utf-8");
  const [l1, l5, l15] = data.split(/\s+/).map(Number);
  return { load1: l1, load5: l5, load15: l15 };
}

function valueToY(value: number, maxVal: number): number {
  const clamped = Math.min(value, maxVal);
  return GRAPH_TOP + GRAPH_HEIGHT - (GRAPH_HEIGHT * clamped) / maxVal;
}

function buildPolyline(
  values: LoadSample[],
  key: keyof LoadSample,
  maxVal: number,
  step: number,
): string {
  return values
    .map((s, i) => `${(i * step).toFixed(1)},${valueToY(s[key], maxVal).toFixed(1)}`)
    .join(" ");
}

function generateSvg(values: LoadSample[]): void {
  const n = values.length;
  if (n < 2) return;

  const step = WIDTH / (MAX_POINTS - 1);
  // Max Y scale: at least CPU_COUNT, or highest observed value + 20%
  const peak = Math.max(...values.flatMap((s) => [s.load1, s.load5, s.load15]));
  const maxVal = Math.max(CPU_COUNT * 1.2, peak * 1.2);

  const cpuLineY = valueToY(CPU_COUNT, maxVal).toFixed(1);

  const line1 = buildPolyline(values, "load1", maxVal, step);
  const line5 = buildPolyline(values, "load5", maxVal, step);
  const line15 = buildPolyline(values, "load15", maxVal, step);

  const legendBase = GRAPH_HEIGHT + 16;
  const legendSpacing = 22;

  const zeroY = valueToY(0, maxVal).toFixed(1);

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
  <style>text { font-family: monospace; font-size: 11px; }</style>

  <!-- Legend -->
  <text x="4" y="${legendBase + 4}" fill="${COLORS.load1}">1m</text>
  <text x="4" y="${legendBase + legendSpacing + 4}" fill="${COLORS.load5}">5m</text>
  <text x="4" y="${legendBase + legendSpacing * 2 + 4}" fill="${COLORS.load15}">15</text>

  <!-- Zero line -->
  <line x1="0" y1="${zeroY}" x2="${WIDTH}" y2="${zeroY}" stroke="#ffffff" stroke-width="1" opacity="0.3" />

  <!-- CPU count reference line -->
  <line x1="0" y1="${cpuLineY}" x2="${WIDTH}" y2="${cpuLineY}" stroke="${COLORS.cpuLine}" stroke-width="1" stroke-dasharray="3,2" opacity="0.6" />
  <text x="22" y="${Number(cpuLineY) - 3}" fill="${COLORS.cpuLine}" opacity="0.6">${CPU_COUNT}</text>

  <!-- Load lines -->
  <polyline points="${line15}" fill="none" stroke="${COLORS.load15}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />
  <polyline points="${line5}" fill="none" stroke="${COLORS.load5}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />
  <polyline points="${line1}" fill="none" stroke="${COLORS.load1}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />
</svg>`;

  fs.writeFileSync(SVG_PATH, svg);
  console.log(SVG_PATH);
}

$.verbose = false;
const values: LoadSample[] = [];

// Seed with current values so it's not empty
values.push(readLoadAvg());

setInterval(() => {
  values.push(readLoadAvg());
  if (values.length > MAX_POINTS) values.shift();
  generateSvg(values);
}, POLL_MS);
