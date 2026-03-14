#!/usr/bin/env zx

const SVG_PATH = "/tmp/eww-cpu-graph.svg";
const WIDTH = 40;
const HEIGHT = 800;
const MAX_POINTS = 80;
const POLL_MS = 100;
const LEGEND_HEIGHT = 20;
const GRAPH_HEIGHT = HEIGHT - LEGEND_HEIGHT;
const STROKE_COLOR = "#33ccff";
const FILL_COLOR = "rgba(51,204,255,1)";

interface CpuTimes {
  idle: number;
  total: number;
}

function readCpuTimes(): CpuTimes {
  const stat = fs.readFileSync("/proc/stat", "utf-8");
  const cpuLine = stat.split("\n").find((l) => l.startsWith("cpu "));
  if (!cpuLine) throw new Error("no cpu line in /proc/stat");
  const fields = cpuLine.split(/\s+/).slice(1).map(Number);
  // user, nice, system, idle, iowait, irq, softirq, steal
  const idle = fields[3] + fields[4];
  const total = fields.reduce((a, b) => a + b, 0);
  return { idle, total };
}

function getCpuPercent(prev: CpuTimes, curr: CpuTimes): number {
  const totalDelta = curr.total - prev.total;
  const idleDelta = curr.idle - prev.idle;
  if (totalDelta === 0) return 0;
  return Math.round(((totalDelta - idleDelta) / totalDelta) * 100);
}

function generateSvg(values: number[]): void {
  const n = values.length;
  if (n < 2) return;

  const step = WIDTH / (MAX_POINTS - 1);

  let polyPoints = "";
  let linePoints = "";
  for (let i = 0; i < n; i++) {
    const x = (i * step).toFixed(1);
    const y = (GRAPH_HEIGHT - (GRAPH_HEIGHT * values[i]) / 100).toFixed(1);
    polyPoints += `${x},${y} `;
    linePoints += `${x},${y} `;
  }

  const lastX = ((n - 1) * step).toFixed(1);
  polyPoints = `0,${GRAPH_HEIGHT} ${polyPoints}${lastX},${GRAPH_HEIGHT}`;

  const svg = `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}" >
  <line x1="0" y1="0" x2="${WIDTH}" y2="0" stroke="#ffffff" stroke-width="1" opacity="0.15" />
  <polygon points="${polyPoints}" fill="${FILL_COLOR}" />
  <polyline points="${linePoints}" fill="none" stroke="${STROKE_COLOR}" stroke-width="2" stroke-linejoin="round" stroke-linecap="round" />
</svg>`;

  fs.writeFileSync(SVG_PATH, svg);
  console.log(SVG_PATH);
}

$.verbose = false;
const values: number[] = [];
let prev = readCpuTimes();

setInterval(() => {
  const curr = readCpuTimes();
  const pct = getCpuPercent(prev, curr);
  prev = curr;

  values.push(pct);
  if (values.length > MAX_POINTS) values.shift();

  generateSvg(values);
}, POLL_MS);
