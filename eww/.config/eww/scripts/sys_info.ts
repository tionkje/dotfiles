#!/usr/bin/env zx

const WIDTH = 40;
const HEIGHT = 120;
const MAX_POINTS = 40;
const POLL_MS = 2000;

const COLORS = {
  mem: "#c792ea",
  disk: "#f78c6c",
};

function readMemPercent(): number {
  const data = fs.readFileSync("/proc/meminfo", "utf-8");
  const lines = data.split("\n");
  let total = 0;
  let available = 0;
  for (const line of lines) {
    if (line.startsWith("MemTotal:")) {
      total = parseInt(line.split(/\s+/)[1], 10);
    } else if (line.startsWith("MemAvailable:")) {
      available = parseInt(line.split(/\s+/)[1], 10);
    }
  }
  if (total === 0) return 0;
  return Math.round(((total - available) / total) * 100);
}

function readDiskPercent(): number {
  const stat = fs.statfsSync("/");
  const used = stat.blocks - stat.bfree;
  if (stat.blocks === 0) return 0;
  return Math.round((used / stat.blocks) * 100);
}

function generateSvg(
  values: number[],
  color: string,
  label: string,
): string {
  const n = values.length;
  const current = n > 0 ? values[n - 1] : 0;

  if (n < 2) {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
  <text x="${WIDTH / 2}" y="${HEIGHT / 2}" fill="${color}" font-family="monospace" font-size="14" font-weight="bold" text-anchor="middle" dominant-baseline="central">${current}%</text>
  <text x="${WIDTH / 2}" y="${HEIGHT / 2 + 16}" fill="${color}" font-family="monospace" font-size="9" text-anchor="middle" opacity="0.7">${label}</text>
</svg>`;
  }

  const step = WIDTH / (MAX_POINTS - 1);

  let polyPoints = "";
  let linePoints = "";
  for (let i = 0; i < n; i++) {
    const x = (i * step).toFixed(1);
    const y = (HEIGHT - (HEIGHT * values[i]) / 100).toFixed(1);
    polyPoints += `${x},${y} `;
    linePoints += `${x},${y} `;
  }

  const lastX = ((n - 1) * step).toFixed(1);
  polyPoints = `0,${HEIGHT} ${polyPoints}${lastX},${HEIGHT}`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${WIDTH}" height="${HEIGHT}" viewBox="0 0 ${WIDTH} ${HEIGHT}">
  <polygon points="${polyPoints}" fill="${color}" opacity="0.3" />
  <polyline points="${linePoints}" fill="none" stroke="${color}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />
  <text x="${WIDTH / 2}" y="${HEIGHT / 2}" fill="${color}" font-family="monospace" font-size="14" font-weight="bold" text-anchor="middle" dominant-baseline="central">${current}%</text>
  <text x="${WIDTH / 2}" y="${HEIGHT / 2 + 16}" fill="${color}" font-family="monospace" font-size="9" text-anchor="middle" opacity="0.7">${label}</text>
</svg>`;
}

// Use alternating files so eww sees a path change each tick
const MEM_PATHS = ["/tmp/eww-mem-graph-0.svg", "/tmp/eww-mem-graph-1.svg"];
const DISK_PATHS = ["/tmp/eww-disk-graph-0.svg", "/tmp/eww-disk-graph-1.svg"];

$.verbose = false;
let tick = 0;
const memValues: number[] = [];
const diskValues: number[] = [];

memValues.push(readMemPercent());
diskValues.push(readDiskPercent());

setInterval(() => {
  memValues.push(readMemPercent());
  if (memValues.length > MAX_POINTS) memValues.shift();

  diskValues.push(readDiskPercent());
  if (diskValues.length > MAX_POINTS) diskValues.shift();

  const idx = tick % 2;
  const memPath = MEM_PATHS[idx];
  const diskPath = DISK_PATHS[idx];

  fs.writeFileSync(memPath, generateSvg(memValues, COLORS.mem, "MEM"));
  fs.writeFileSync(diskPath, generateSvg(diskValues, COLORS.disk, "DSK"));

  console.log(JSON.stringify({ mem: memPath, disk: diskPath }));
  tick++;
}, POLL_MS);
