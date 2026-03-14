#!/usr/bin/env zx

import { generateGraphSvg } from "./graph_svg.ts";

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

  const memCurrent = memValues[memValues.length - 1];
  const diskCurrent = diskValues[diskValues.length - 1];
  fs.writeFileSync(
    memPath,
    generateGraphSvg({
      values: memValues,
      color: COLORS.mem,
      label: "󰍛",
      displayValue: `${memCurrent}%`,
      maxValue: 100,
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
