#!/usr/bin/env zx

import { generateGraphSvg } from "./graph_svg.ts";

const MAX_POINTS = 40;
const POLL_MS = 2000;

const COLORS = {
  mem: "#c792ea",
  swap: "#ff9e64",
  disk: "#f78c6c",
};

interface MemSample {
  mem: number;
  swap: number;
}

// Both values expressed as % of physical RAM (MemTotal), so they stack as
// "memory pressure" — swap usage extends the bar past 100 % when RAM is full.
function readMemSample(): MemSample {
  const data = fs.readFileSync("/proc/meminfo", "utf-8");
  const lines = data.split("\n");
  let memTotal = 0;
  let memAvailable = 0;
  let swapTotal = 0;
  let swapFree = 0;
  for (const line of lines) {
    if (line.startsWith("MemTotal:")) {
      memTotal = parseInt(line.split(/\s+/)[1], 10);
    } else if (line.startsWith("MemAvailable:")) {
      memAvailable = parseInt(line.split(/\s+/)[1], 10);
    } else if (line.startsWith("SwapTotal:")) {
      swapTotal = parseInt(line.split(/\s+/)[1], 10);
    } else if (line.startsWith("SwapFree:")) {
      swapFree = parseInt(line.split(/\s+/)[1], 10);
    }
  }
  if (memTotal === 0) return { mem: 0, swap: 0 };
  const memPct = ((memTotal - memAvailable) / memTotal) * 100;
  const swapUsed = swapTotal - swapFree;
  const swapPct = (swapUsed / memTotal) * 100;
  return { mem: Math.round(memPct), swap: Math.round(swapPct) };
}

function readDiskPercent(): number {
  const stat = fs.statfsSync("/");
  const used = stat.blocks - stat.bfree;
  if (stat.blocks === 0) return 0;
  return Math.round((used / stat.blocks) * 100);
}

// Use alternating files so eww sees a path change each tick
const MEM_PATHS = ["/tmp/eww-mem-graph-0.svg", "/tmp/eww-mem-graph-1.svg"];
const DISK_PATHS = ["/tmp/eww-disk-graph-0.svg", "/tmp/eww-disk-graph-1.svg"];

$.verbose = false;
let tick = 0;
const memValues: number[] = [];
const swapValues: number[] = [];
const diskValues: number[] = [];

const initial = readMemSample();
memValues.push(initial.mem);
swapValues.push(initial.swap);
diskValues.push(readDiskPercent());

setInterval(() => {
  const sample = readMemSample();
  memValues.push(sample.mem);
  swapValues.push(sample.swap);
  if (memValues.length > MAX_POINTS) memValues.shift();
  if (swapValues.length > MAX_POINTS) swapValues.shift();

  diskValues.push(readDiskPercent());
  if (diskValues.length > MAX_POINTS) diskValues.shift();

  const idx = tick % 2;
  const memPath = MEM_PATHS[idx];
  const diskPath = DISK_PATHS[idx];

  const memCurrent = memValues[memValues.length - 1];
  const swapCurrent = swapValues[swapValues.length - 1];
  const diskCurrent = diskValues[diskValues.length - 1];
  // Combined pressure as % of RAM fits the 40 px slot and conveys overall load.
  const pressure = memCurrent + swapCurrent;
  // Y floor at 100 so the RAM scale is stable; grows only when swap pushes past.
  let pressurePeak = 100;
  for (let i = 0; i < memValues.length; i++) {
    const combined = memValues[i] + (swapValues[i] ?? 0);
    if (combined > pressurePeak) pressurePeak = combined;
  }
  fs.writeFileSync(
    memPath,
    generateGraphSvg({
      values: memValues,
      color: COLORS.mem,
      label: "󰍛",
      displayValue: `${pressure}%`,
      maxValue: pressurePeak,
      stack: { values: swapValues, color: COLORS.swap },
    }),
  );
  fs.writeFileSync(
    diskPath,
    generateGraphSvg({
      values: diskValues,
      color: COLORS.disk,
      label: "",
      displayValue: `${diskCurrent}%`,
      maxValue: 100,
    }),
  );

  console.log(JSON.stringify({ mem: memPath, disk: diskPath }));
  tick++;
}, POLL_MS);
