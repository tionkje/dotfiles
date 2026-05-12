interface StackSeries {
  values: number[];
  color: string;
}

interface GraphSvgOptions {
  values: number[];
  color: string;
  label: string;
  displayValue: string;
  maxValue?: number;
  width?: number;
  height?: number;
  maxPoints?: number;
  iconSize?: number;
  iconOpacity?: number;
  stack?: StackSeries;
}

function generateGraphSvg(opts: GraphSvgOptions): string {
  const {
    values,
    color,
    label,
    displayValue,
    stack,
    width = 40,
    height = 120,
    maxPoints = 40,
    iconSize = 22,
    iconOpacity = 0.2,
  } = opts;
  const n = values.length;

  // For stacked, max needs to account for combined peak so the chart fits.
  let observedMax = 1;
  for (let i = 0; i < n; i++) {
    const combined = values[i] + (stack ? stack.values[i] ?? 0 : 0);
    if (combined > observedMax) observedMax = combined;
  }
  const maxVal = opts.maxValue ?? observedMax;

  const iconX = width / 2;
  const iconY = height / 2 - 6;
  const watermark = `<text x="${iconX}" y="${iconY}" fill="${color}" opacity="${iconOpacity}" font-family="monospace" font-size="${iconSize}" text-anchor="middle" dominant-baseline="central" stroke="#000" stroke-width="0.5" stroke-opacity="0.15">${label}</text>`;

  const valY = height - 8;
  const valBg = `<rect x="0" y="${valY - 7}" width="${width}" height="14" fill="black" opacity="0.4" rx="2" />`;
  const valEl = `<text x="${width / 2}" y="${valY}" fill="${color}" font-family="monospace" font-size="15" font-weight="bold" text-anchor="middle" dominant-baseline="central" stroke="#000" stroke-width="0.3" stroke-opacity="0.2">${displayValue}</text>`;

  if (n < 2) {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  ${watermark}
  ${valBg}
  ${valEl}
</svg>`;
  }

  const step = width / (maxPoints - 1);
  const toY = (v: number) => height - (height * v) / maxVal;

  // Primary series points (boundary between baseline and primary fill)
  const primaryYs: number[] = [];
  let primaryLine = "";
  for (let i = 0; i < n; i++) {
    const x = (i * step).toFixed(1);
    const y = toY(values[i]);
    primaryYs.push(y);
    primaryLine += `${x},${y.toFixed(1)} `;
  }

  const lastX = ((n - 1) * step).toFixed(1);
  const primaryPoly = `0,${height} ${primaryLine}${lastX},${height}`;

  let stackLayer = "";
  if (stack) {
    // Stack polygon: top edge of primary, then top edge of combined in reverse.
    let stackTopLine = "";
    const stackTopYs: number[] = [];
    for (let i = 0; i < n; i++) {
      const x = (i * step).toFixed(1);
      const y = toY(values[i] + (stack.values[i] ?? 0));
      stackTopYs.push(y);
      stackTopLine += `${x},${y.toFixed(1)} `;
    }
    let stackPoly = "";
    for (let i = 0; i < n; i++) {
      stackPoly += `${(i * step).toFixed(1)},${primaryYs[i].toFixed(1)} `;
    }
    for (let i = n - 1; i >= 0; i--) {
      stackPoly += `${(i * step).toFixed(1)},${stackTopYs[i].toFixed(1)} `;
    }
    stackLayer = `<polygon points="${stackPoly}" fill="${stack.color}" opacity="0.35" />
  <polyline points="${stackTopLine}" fill="none" stroke="${stack.color}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />`;
  }

  // Optional 100% reference when scale exceeds 100 (memory pressure exceeds RAM)
  let refLine = "";
  if (maxVal > 100) {
    const refY = toY(100).toFixed(1);
    refLine = `<line x1="0" y1="${refY}" x2="${width}" y2="${refY}" stroke="#ffffff" stroke-width="1" stroke-dasharray="2,2" opacity="0.25" />`;
  }

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  ${watermark}
  <polygon points="${primaryPoly}" fill="${color}" opacity="0.3" />
  <polyline points="${primaryLine}" fill="none" stroke="${color}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />
  ${stackLayer}
  ${refLine}
  ${valBg}
  ${valEl}
</svg>`;
}

export { generateGraphSvg };
export type { GraphSvgOptions, StackSeries };
