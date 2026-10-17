// Dev-only, dependency-free preparation of the checked-in character artwork.
// Run: node tool/prepare_sprite_sheets.mjs [--check]
import { readFile, writeFile } from 'node:fs/promises';
import { deflateSync, inflateSync } from 'node:zlib';
import { fileURLToPath } from 'node:url';
import { resolve } from 'node:path';

const packageRoot = new URL('../', import.meta.url);
export const frameWidth = 192;
export const frameHeight = 256;
const contentHeight = 224;
const footBaseline = 240;

// Bounds isolate complete poses and omit the male sheet's "Walking" label.
// Coordinates are half-open; small padding retains antialiasing and shadows.
const sources = {
  boy: {
    bands: [[35, 375], [425, 710], [715, 980]],
    ranges: [
      [[123,252],[295,410],[446,565],[598,715],[759,882],[933,1065],[1111,1234],[1285,1425]],
      [[114,230],[280,386],[431,547],[580,698],[739,851],[898,1012],[1057,1171],[1205,1316],[1348,1473]],
      [[117,225],[271,389],[421,555],[581,705],[730,827],[878,988],[1023,1146],[1169,1294],[1322,1452]],
    ],
    // Output order: down, down-left, left, up-left, up, up-right, right,
    // down-right. Original male poses lack pure side views: left reuses the
    // nearest rear-left pose; right reuses the nearest front-right pose.
    // Some front-facing walking poses also lean diagonally. No poses invented.
    directions: [[0,1,1,2,4,5,7,7], [0,1,1,2,4,5,8,8], [0,1,1,2,4,5,8,8]],
  },
  girl: {
    bands: [[35, 400], [405, 732], [738, 1005]],
    ranges: [
      [[127,251],[287,410],[439,566],[594,743],[779,904],[957,1081],[1115,1270],[1287,1416]],
      [[102,254],[273,423],[434,589],[605,739],[776,900],[929,1073],[1093,1250],[1268,1430]],
      [[114,246],[276,413],[436,581],[604,740],[778,901],[930,1070],[1108,1250],[1283,1418]],
    ],
    // Top-row directions are the nearest eight compass views; lower-row
    // down/left poses are diagonal approximations present in the original.
    directions: [[0,1,2,3,4,5,6,7], [0,1,2,3,4,5,6,7], [0,1,2,3,4,5,6,7]],
  },
};

function crc32(bytes) {
  let crc = 0xffffffff;
  for (const byte of bytes) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

function chunk(type, data) {
  const name = Buffer.from(type);
  const result = Buffer.alloc(data.length + 12);
  result.writeUInt32BE(data.length);
  name.copy(result, 4);
  data.copy(result, 8);
  result.writeUInt32BE(crc32(Buffer.concat([name, data])), data.length + 8);
  return result;
}

function paeth(left, up, corner) {
  const p = left + up - corner;
  const a = Math.abs(p - left), b = Math.abs(p - up), c = Math.abs(p - corner);
  return a <= b && a <= c ? left : b <= c ? up : corner;
}

// These source PNGs use non-interlaced 8-bit RGB/RGBA, filters 0–4.
export function decodePng(bytes) {
  if (!bytes.subarray(0, 8).equals(Buffer.from([137,80,78,71,13,10,26,10]))) throw new Error('Invalid PNG');
  const width = bytes.readUInt32BE(16), height = bytes.readUInt32BE(20);
  const channels = bytes[25] === 6 ? 4 : bytes[25] === 2 ? 3 : 0;
  if (bytes[24] !== 8 || !channels || bytes[28] !== 0) throw new Error('Expected non-interlaced 8-bit RGB/RGBA');
  const parts = [];
  for (let offset = 8; offset < bytes.length;) {
    const length = bytes.readUInt32BE(offset);
    if (bytes.toString('ascii', offset + 4, offset + 8) === 'IDAT') parts.push(bytes.subarray(offset + 8, offset + 8 + length));
    offset += length + 12;
  }
  const raw = inflateSync(Buffer.concat(parts));
  const stride = width * channels;
  const unfiltered = Buffer.alloc(stride * height);
  for (let y = 0; y < height; y++) {
    const row = y * stride, input = y * (stride + 1), filter = raw[input];
    if (filter > 4) throw new Error('Unsupported PNG filter');
    for (let x = 0; x < stride; x++) {
      const left = x >= channels ? unfiltered[row + x - channels] : 0;
      const up = y ? unfiltered[row + x - stride] : 0;
      const corner = y && x >= channels ? unfiltered[row + x - stride - channels] : 0;
      const predictor = [0, left, up, Math.floor((left + up) / 2), paeth(left, up, corner)][filter];
      unfiltered[row + x] = (raw[input + x + 1] + predictor) & 255;
    }
  }
  const pixels = Buffer.alloc(width * height * 4);
  for (let i = 0; i < width * height; i++) {
    unfiltered.copy(pixels, i * 4, i * channels, i * channels + 3);
    pixels[i * 4 + 3] = channels === 4 ? unfiltered[i * 4 + 3] : 255;
  }
  return { width, height, pixels };
}

export function encodePng({ width, height, pixels }) {
  const header = Buffer.alloc(13);
  header.writeUInt32BE(width); header.writeUInt32BE(height, 4);
  header[8] = 8; header[9] = 6;
  const stride = width * 4, raw = Buffer.alloc(height * (stride + 1));
  for (let y = 0; y < height; y++) pixels.copy(raw, y * (stride + 1) + 1, y * stride, (y + 1) * stride);
  return Buffer.concat([Buffer.from([137,80,78,71,13,10,26,10]), chunk('IHDR', header), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]);
}

function crop(image, left, top, right, bottom) {
  const width = right - left, height = bottom - top;
  const pixels = Buffer.alloc(width * height * 4);
  for (let y = 0; y < height; y++) image.pixels.copy(pixels, y * width * 4, ((top + y) * image.width + left) * 4, ((top + y) * image.width + right) * 4);
  return { width, height, pixels };
}

// Flood only exterior, bright, nearly neutral checker pixels and their gray ground shadows. Enclosed shirt,
// eye and highlight whites remain untouched, unlike global white-key removal.
export function removeExteriorChecker(image) {
  const { width, height, pixels } = image;
  const seen = new Uint8Array(width * height), queue = new Int32Array(width * height);
  let head = 0, tail = 0;
  function visit(x, y) {
    if (x < 0 || y < 0 || x >= width || y >= height) return;
    const index = y * width + x, offset = index * 4;
    if (seen[index]) return;
    seen[index] = 1;
    const r = pixels[offset], g = pixels[offset + 1], b = pixels[offset + 2];
    if (Math.min(r, g, b) < 160 || Math.max(r, g, b) - Math.min(r, g, b) > 12) return;
    pixels[offset + 3] = 0;
    queue[tail++] = index;
  }
  for (let x = 0; x < width; x++) { visit(x, 0); visit(x, height - 1); }
  for (let y = 0; y < height; y++) { visit(0, y); visit(width - 1, y); }
  while (head < tail) {
    const index = queue[head++], x = index % width, y = Math.floor(index / width);
    visit(x - 1, y); visit(x + 1, y); visit(x, y - 1); visit(x, y + 1);
  }
}

function bounds(image) {
  let left = image.width, top = image.height, right = 0, bottom = 0;
  for (let y = 0; y < image.height; y++) for (let x = 0; x < image.width; x++) {
    if (image.pixels[(y * image.width + x) * 4 + 3] < 32) continue;
    left = Math.min(left, x); top = Math.min(top, y);
    right = Math.max(right, x + 1); bottom = Math.max(bottom, y + 1);
  }
  return { left, top, right, bottom };
}

// Sample premultiplied colors so transparent source RGB cannot form dark halos.
function placePose(atlas, pose, row, column) {
  const { left, top, right, bottom } = bounds(pose);
  const scale = contentHeight / (bottom - top);
  const width = Math.round((right - left) * scale);
  const startX = column * frameWidth + Math.floor((frameWidth - width) / 2);
  const startY = row * frameHeight + footBaseline - contentHeight;
  for (let y = 0; y < contentHeight; y++) for (let x = 0; x < width; x++) {
    const sx = left + (x + 0.5) / scale - 0.5, sy = top + (y + 0.5) / scale - 0.5;
    const x0 = Math.floor(sx), y0 = Math.floor(sy), fx = sx - x0, fy = sy - y0;
    let alpha = 0; const colors = [0, 0, 0];
    for (let dy = 0; dy < 2; dy++) for (let dx = 0; dx < 2; dx++) {
      const px = Math.max(0, Math.min(pose.width - 1, x0 + dx));
      const py = Math.max(0, Math.min(pose.height - 1, y0 + dy));
      const source = (py * pose.width + px) * 4;
      const weight = (dx ? fx : 1 - fx) * (dy ? fy : 1 - fy);
      const a = pose.pixels[source + 3] * weight;
      alpha += a;
      for (let c = 0; c < 3; c++) colors[c] += pose.pixels[source + c] * a;
    }
    const target = ((startY + y) * atlas.width + startX + x) * 4;
    atlas.pixels[target + 3] = Math.round(alpha);
    if (alpha) for (let c = 0; c < 3; c++) atlas.pixels[target + c] = Math.round(colors[c] / alpha);
  }
}

export function prepareSheet(image, name) {
  const source = sources[name];
  const poses = source.bands.map(([top, bottom], band) => source.ranges[band].map(([left, right]) => {
    const pose = crop(image, left - 4, top, right + 4, bottom);
    if (name === 'girl') removeExteriorChecker(pose);
    return pose;
  }));
  const atlas = { width: frameWidth * 8, height: frameHeight * 4, pixels: Buffer.alloc(frameWidth * 8 * frameHeight * 4 * 4) };
  // Standing row 0; walk phase A, standing midpoint, phase B in rows 1–3.
  for (const [row, band] of [0, 1, 0, 2].entries()) for (let column = 0; column < 8; column++) placePose(atlas, poses[band][source.directions[band][column]], row, column);
  return atlas;
}

async function main() {
  const check = process.argv.includes('--check');
  for (const name of ['boy', 'girl']) {
    const image = decodePng(await readFile(new URL('assets/' + name + '.png', packageRoot)));
    const prepared = prepareSheet(image, name);
    const output = new URL('assets/' + name + '_sprite_sheet.png', packageRoot);
    if (check) {
      // zlib versions can encode identical scanlines differently. Verify the
      // complete decoded RGBA content rather than compressed PNG bytes.
      const actual = decodePng(await readFile(output));
      if (actual.width !== prepared.width || actual.height !== prepared.height ||
          !actual.pixels.equals(prepared.pixels)) throw new Error(name + ' atlas differs; rerun preparation');
    } else await writeFile(output, encodePng(prepared));
    console.log(name + ': 1536x1024 RGBA atlas ' + (check ? 'matches' : 'prepared'));
  }
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) await main();
