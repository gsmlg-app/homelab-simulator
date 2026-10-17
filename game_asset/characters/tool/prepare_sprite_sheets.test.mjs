import assert from 'node:assert/strict';
import { copyFile, mkdir, mkdtemp, readFile, realpath, rm, writeFile } from 'node:fs/promises';
import { spawnSync } from 'node:child_process';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { deflateSync, inflateSync } from 'node:zlib';
import { createHash } from 'node:crypto';
import { test } from 'node:test';
import { decodePng, encodePng, removeExteriorChecker } from './prepare_sprite_sheets.mjs';

const root = new URL('../', import.meta.url);
const hashes = {
  boy: 'db13e023e529488071e8aa666c3cfb61c0246fb046ea91798eb7096f876fa9f6',
  girl: 'cb35191ab2c1f171b5b9aeb3182e62a200fb67edad6d9ee851e7d675fd18301d',
};

for (const [index, name] of ['boy', 'girl'].entries()) {
  test(name + ' original artwork remains unchanged', async () => {
    const bytes = await readFile(new URL('assets/' + name + '.png', root));
    assert.equal(createHash('sha256').update(bytes).digest('hex'), hashes[name]);
  });

  test(name + ' configured atlas contains complete transparent aligned frames', async () => {
    const metadata = await readFile(new URL('lib/src/game_characters.dart', root), 'utf8');
    const path = [...metadata.matchAll(/path: 'packages\/game_asset_characters\/([^']+)'/g)][index][1];
    const image = decodePng(await readFile(new URL(path, root)));
    assert.equal(image.width, 1536);
    assert.equal(image.height, 1024);
    for (let row = 0; row < 4; row++) for (let column = 0; column < 8; column++) {
      let left = 192, right = 0, top = 256, bottom = 0;
      let transparent = 0, partiallyTransparent = 0;
      for (let y = 0; y < 256; y++) for (let x = 0; x < 192; x++) {
        const alpha = image.pixels[((row * 256 + y) * image.width + column * 192 + x) * 4 + 3];
        if (!alpha) transparent++;
        if (alpha > 0 && alpha < 255) partiallyTransparent++;
        if (alpha < 32) continue;
        left = Math.min(left, x); right = Math.max(right, x + 1);
        top = Math.min(top, y); bottom = Math.max(bottom, y + 1);
      }
      const cell = name + ' row ' + row + ' direction ' + column;
      assert.ok(transparent > 192 * 256 / 2, cell + ': transparent exterior');
      assert.ok(partiallyTransparent > 10, cell + ': antialiased alpha edges');
      assert.ok(left >= 8 && right <= 184, cell + ': complete horizontal crop');
      assert.ok(top >= 15 && top <= 19, cell + ': consistent head height');
      assert.ok(bottom >= 237 && bottom <= 240, cell + ': feet on baseline');
      assert.ok(Math.abs((left + right) / 2 - 96) <= 2, cell + ': centered pose');
    }
    // The standing midpoint must be exactly the same art as idle.
    for (let y = 0; y < 256; y++) assert.deepEqual(
      image.pixels.subarray(y * image.width * 4, (y + 1) * image.width * 4),
      image.pixels.subarray((512 + y) * image.width * 4, (513 + y) * image.width * 4),
    );
  });
}

test('checker removal preserves enclosed whites and non-neutral exterior colors', () => {
  const image = { width: 7, height: 7, pixels: Buffer.alloc(7 * 7 * 4, 255) };
  // A closed dark outline encloses a white highlight at (3,3).
  for (let y = 2; y <= 4; y++) for (let x = 2; x <= 4; x++) {
    if (x === 3 && y === 3) continue;
    const offset = (y * 7 + x) * 4;
    image.pixels[offset] = image.pixels[offset + 1] = image.pixels[offset + 2] = 20;
  }
  image.pixels[0] = 230; image.pixels[1] = 200; image.pixels[2] = 160;
  removeExteriorChecker(image);
  assert.equal(image.pixels[(3 * 7 + 3) * 4 + 3], 255);
  assert.equal(image.pixels[3], 255);
  assert.equal(image.pixels[7], 0);
});


test('actual female checker between legs clears while enclosed shirt stays white', async () => {
  const image = decodePng(await readFile(new URL('assets/girl.png', root)));
  removeExteriorChecker(image);
  const alpha = (x, y) => image.pixels[(y * image.width + x) * 4 + 3];
  assert.equal(alpha(668, 350), 0, 'checker gap between legs');
  assert.equal(alpha(1180, 350), 0, 'checker gap in side-facing pose');
  assert.equal(alpha(189, 150), 255, 'enclosed white shirt');
});


// Re-encode the exact scanlines with uncompressed deflate blocks. This models
// zlib-version differences without requiring a second Node installation.
function recompressPng(png) {
  const parts = [];
  for (let offset = 8; offset < png.length;) {
    const length = png.readUInt32BE(offset);
    if (png.toString('ascii', offset + 4, offset + 8) === 'IDAT') parts.push(png.subarray(offset + 8, offset + 8 + length));
    offset += length + 12;
  }
  const compressed = deflateSync(inflateSync(Buffer.concat(parts)), { level: 0 });
  const idat = Buffer.alloc(compressed.length + 12);
  idat.writeUInt32BE(compressed.length);
  idat.write('IDAT', 4);
  compressed.copy(idat, 8);
  let crc = 0xffffffff;
  for (const byte of idat.subarray(4, -4)) {
    crc ^= byte;
    for (let bit = 0; bit < 8; bit++) crc = (crc >>> 1) ^ ((crc & 1) ? 0xedb88320 : 0);
  }
  idat.writeUInt32BE((crc ^ 0xffffffff) >>> 0, idat.length - 4);
  return Buffer.concat([png.subarray(0, 33), idat, png.subarray(-12)]);
}

test('--check accepts equivalent PNG compression and rejects changed pixels', async () => {
  const temporary = await realpath(await mkdtemp(join(tmpdir(), 'homelab-atlas-check-')));
  try {
    await mkdir(join(temporary, 'tool'));
    await mkdir(join(temporary, 'assets'));
    const script = join(temporary, 'tool/prepare_sprite_sheets.mjs');
    await copyFile(new URL('tool/prepare_sprite_sheets.mjs', root), script);
    for (const name of ['boy', 'girl']) {
      await copyFile(new URL('assets/' + name + '.png', root), join(temporary, 'assets/' + name + '.png'));
      const approved = await readFile(new URL('assets/' + name + '_sprite_sheet.png', root));
      const alternate = recompressPng(approved);
      assert.ok(!alternate.equals(approved), 'fixture must have different encoded bytes');
      assert.deepEqual(decodePng(alternate), decodePng(approved));
      await writeFile(join(temporary, 'assets/' + name + '_sprite_sheet.png'), alternate);
    }
    const check = () => spawnSync(process.execPath, [script, '--check'], { encoding: 'utf8' });
    const equivalent = check();
    assert.equal(equivalent.status, 0, equivalent.stderr);

    const regeneration = spawnSync(process.execPath, [script], { encoding: 'utf8' });
    assert.equal(regeneration.status, 0, regeneration.stderr);
    const regeneratedCheck = check();
    assert.equal(regeneratedCheck.status, 0, regeneratedCheck.stderr);
    for (const name of ['boy', 'girl']) assert.deepEqual(
      decodePng(await readFile(join(temporary, 'assets/' + name + '_sprite_sheet.png'))),
      decodePng(await readFile(new URL('assets/' + name + '_sprite_sheet.png', root))),
    );

    const output = join(temporary, 'assets/boy_sprite_sheet.png');
    const changed = decodePng(await readFile(output));
    const opaquePixel = changed.pixels.findIndex((value, index) => index % 4 === 3 && value === 255) - 3;
    assert.ok(opaquePixel >= 0);
    changed.pixels[opaquePixel] ^= 1;
    await writeFile(output, encodePng(changed));
    const different = check();
    assert.equal(different.status, 1);
    assert.match(different.stderr, /boy atlas differs/);
  } finally {
    await rm(temporary, { recursive: true, force: true });
  }
});
