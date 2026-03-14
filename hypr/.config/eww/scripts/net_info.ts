#!/usr/bin/env zx

import { generateGraphSvg } from "./graph_svg.ts";

const MAX_POINTS = 40;
const POLL_MS = 2000;

const COLORS = {
  rx: "#82aaff",
  tx: "#c3e88d",
};

function formatRate(kbPerSec: number): string {
  if (kbPerSec < 1000) {
    return `${Math.round(kbPerSec)}K`;
  }
  return `${(kbPerSec / 1024).toFixed(1)}M`;
}

interface InterfaceBytes {
  rx: number;
  tx: number;
}

function readNetBytes(): InterfaceBytes {
  const data = fs.readFileSync("/proc/net/dev", "utf-8");
  const lines = data.split("\n");
  let totalRx = 0;
  let totalTx = 0;
  for (const line of lines) {
    const trimmed = line.trim();
    if (!trimmed.includes(":") || trimmed.startsWith("lo:")) continue;
    // Skip header lines (they contain |)
    if (trimmed.includes("|")) continue;
    const parts = trimmed.split(/\s+/);
    // format: iface: rx_bytes rx_packets ... tx_bytes tx_packets ...
    // rx_bytes is index 1, tx_bytes is index 9
    totalRx += parseInt(parts[1], 10) || 0;
    totalTx += parseInt(parts[9], 10) || 0;
  }
  return { rx: totalRx, tx: totalTx };
}

const RX_PATHS = ["/tmp/eww-netrx-graph-0.svg", "/tmp/eww-netrx-graph-1.svg"];
const TX_PATHS = ["/tmp/eww-nettx-graph-0.svg", "/tmp/eww-nettx-graph-1.svg"];

$.verbose = false;
let tick = 0;
const rxRates: number[] = [];
const txRates: number[] = [];

let prevBytes = readNetBytes();

setInterval(() => {
  const curBytes = readNetBytes();

  // Delta bytes, converted to KB/s
  const rxKBs = (curBytes.rx - prevBytes.rx) / 1024 / (POLL_MS / 1000);
  const txKBs = (curBytes.tx - prevBytes.tx) / 1024 / (POLL_MS / 1000);
  prevBytes = curBytes;

  rxRates.push(rxKBs);
  if (rxRates.length > MAX_POINTS) rxRates.shift();

  txRates.push(txKBs);
  if (txRates.length > MAX_POINTS) txRates.shift();

  const idx = tick % 2;
  const rxPath = RX_PATHS[idx];
  const txPath = TX_PATHS[idx];

  const rxDisplay = formatRate(rxRates[rxRates.length - 1]);
  const txDisplay = formatRate(txRates[txRates.length - 1]);

  fs.writeFileSync(
    rxPath,
    generateGraphSvg({
      values: rxRates,
      color: COLORS.rx,
      label: "📥",
      displayValue: rxDisplay,
    }),
  );
  fs.writeFileSync(
    txPath,
    generateGraphSvg({
      values: txRates,
      color: COLORS.tx,
      label: "📩",
      displayValue: txDisplay,
    }),
  );

  console.log(JSON.stringify({ rx: rxPath, tx: txPath }));
  tick++;
}, POLL_MS);
