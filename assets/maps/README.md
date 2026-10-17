# Homelab environment art and maps

Original artwork created for Homelab Simulator, 2026-10-17. No downloaded art,
external fonts, generated monitoring data, or character modifications are included.
The palette uses cool graphite, brushed steel, muted cyan and warm laminate to
complement the supplied illustrated characters. Raster artwork is authored at
2 source pixels per logical unit.

- `source/homelab_atlas.svg`: editable vector master (transparent 1024 × 768).
- `homelab_atlas.png`: runtime atlas, rasterized with ImageMagick's local librsvg.
- `catalog.json`: schema-v1 runtime tile/prefab catalog and two complete maps.
- `preview_server-lab.png`, `preview_operations.png`: composed visual references,
  generated from exactly the same SVG frames, footprint anchors and map data.
- `source/preview_*.svg`: inspectable vector versions of the reference views.
- `tool/build_maps.py`: original construction, catalog authoring and build tool.

Run from the repository root using Python 3 and ImageMagick with SVG support:

```sh
python3 assets/maps/tool/build_maps.py
python3 assets/maps/tool/build_maps.py --check
```

The normal build preserves edits to the SVG master. It rebuilds catalog and
previews deterministically from the definitions in the Python authoring tool.
`--check` performs a clean temporary rebuild and compares decoded PNG pixels,
validates atlas frame bounds and rectangular map layers, without writing assets.
`--regenerate-source` explicitly restores the SVG from its original programmatic
construction; this overwrites manual vector edits. Edit `FRAMES` construction
and catalog authoring together when moving atlas regions or changing footprints.
Fonts in source signage use the local DejaVu Sans fallback, so exact raster
reproduction across hosts requires the same font and librsvg installation.
The committed PNG is the portable runtime artifact.

`server-lab` is 20 × 12 cells; `operations` is 16 × 10. Both have named entry and
center spawns and one shop terminal at `[2, 2]`. A right-wall portal at row 8
connects to the operations left-wall portal at row 7. Door artwork is already in
the architecture layer: keep legacy procedural door and terminal visuals off
for these maps. The runtime engine still owns interaction and accepted movement.
Binding slots are stable equipment references; the atlas lights are decorative.

Tile frames are source-pixel `[x, y, width, height]` rectangles. Prop drawing
width/height are logical units, independent of their occupied cell footprint.
Props use bottom-center ground anchors; floors render below actors. The southern
sill is a low foreground band so it cannot obscure a character. Placement grid
and footprint feedback are drawn by the renderer only in placement mode.

Mount with `await environment.attachToWorld(sceneContainer)` under the same
stable scene container as actors. Actor priority is `(groundAnchor.y * 100).round()`.
Call `setActorGroundPosition` with interpolated feet to fade overlapping tall
props, `setPlacementMode`/`setPlacementPreview` for placement, and
`removeFromWorld()` to dispose every owned sibling during a map change. The
renderer uses the game's image cache, configured with `Images(prefix: '')` for
the catalog's repository-root asset path. A removed environment never publishes
a delayed atlas load.
