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
}

function generateGraphSvg(opts: GraphSvgOptions): string {
  const {
    values,
    color,
    label,
    displayValue,
    width = 40,
    height = 120,
    maxPoints = 40,
    iconSize = 22,
    iconOpacity = 0.2,
  } = opts;
  const n = values.length;
  const maxVal = opts.maxValue ?? Math.max(...values, 1);

  // Watermark icon: large, centered, subtle
  const iconX = width / 2;
  const iconY = height / 2 - 6;
  const watermark = `<text x="${iconX}" y="${iconY}" fill="${color}" opacity="${iconOpacity}" font-family="monospace" font-size="${iconSize}" text-anchor="middle" dominant-baseline="central" stroke="#000" stroke-width="0.5" stroke-opacity="0.15">${label}</text>`;

  // Value readout: small text at bottom with dark backdrop
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

  let polyPoints = "";
  let linePoints = "";
  for (let i = 0; i < n; i++) {
    const x = (i * step).toFixed(1);
    const y = (height - (height * values[i]) / maxVal).toFixed(1);
    polyPoints += `${x},${y} `;
    linePoints += `${x},${y} `;
  }

  const lastX = ((n - 1) * step).toFixed(1);
  polyPoints = `0,${height} ${polyPoints}${lastX},${height}`;

  return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  ${watermark}
  <polygon points="${polyPoints}" fill="${color}" opacity="0.3" />
  <polyline points="${linePoints}" fill="none" stroke="${color}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />
  ${valBg}
  ${valEl}
</svg>`;
}

export { generateGraphSvg };
export type { GraphSvgOptions };
