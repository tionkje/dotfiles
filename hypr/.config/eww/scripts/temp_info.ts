#!/usr/bin/env zx

import { generateGraphSvg } from "./graph_svg.ts";

const MAX_POINTS = 40;
const POLL_MS = 2000;

const COLOR = "#ff5370";

function readTempCelsius(): number {
  const raw = fs.readFileSync("/sys/class/thermal/thermal_zone0/temp", "utf-8");
  return Math.round(parseInt(raw.trim(), 10) / 1000);
}

const TEMP_PATHS = ["/tmp/eww-temp-graph-0.svg", "/tmp/eww-temp-graph-1.svg"];

$.verbose = false;
let tick = 0;
const tempValues: number[] = [];

tempValues.push(readTempCelsius());

setInterval(() => {
  tempValues.push(readTempCelsius());
  if (tempValues.length > MAX_POINTS) tempValues.shift();

  const idx = tick % 2;
  const tempPath = TEMP_PATHS[idx];

  const current = tempValues[tempValues.length - 1];
  fs.writeFileSync(
    tempPath,
    generateGraphSvg({
      values: tempValues,
      color: COLOR,
      label: "🌡️",
      displayValue: `${current}°`,
      maxValue: 100,
    }),
  );

  console.log(tempPath);
  tick++;
}, POLL_MS);
