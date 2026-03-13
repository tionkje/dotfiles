interface GraphSvgOptions {
  values: number[];
  color: string;
  label: string;
  displayValue: string;
  maxValue?: number;
  width?: number;
  height?: number;
  maxPoints?: number;
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
  } = opts;
  const n = values.length;
  const maxVal = opts.maxValue ?? Math.max(...values, 1);

  if (n < 2) {
    return `<svg xmlns="http://www.w3.org/2000/svg" width="${width}" height="${height}" viewBox="0 0 ${width} ${height}">
  <text x="${width / 2}" y="${height - 16}" fill="${color}" font-family="monospace" font-size="10" font-weight="bold" text-anchor="middle" dominant-baseline="central">${label} ${displayValue}</text>
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
  <polygon points="${polyPoints}" fill="${color}" opacity="0.3" />
  <polyline points="${linePoints}" fill="none" stroke="${color}" stroke-width="1.5" stroke-linejoin="round" stroke-linecap="round" />
  <text x="${width / 2}" y="${height - 16}" fill="${color}" font-family="monospace" font-size="10" font-weight="bold" text-anchor="middle" dominant-baseline="central">${label} ${displayValue}</text>
</svg>`;
}

export { generateGraphSvg };
export type { GraphSvgOptions };
