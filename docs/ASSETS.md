# Asset Production List

## Standards
- Tile size: 32x32 px.
- Sprite scale: 1x (target), allow 2x exports for retina.
- View: top-down 3/4 (Stardew-like), 4-direction movement.
- Palette: cool cyan/teal highlights on dark metal; avoid heavy bloom.
- File format: PNG with transparency.

## Naming Conventions
- Use lowercase snake_case.
- Prefix by category.
- Examples:
  - `tiles_floor_metal_01.png`
  - `tiles_wall_panel_02.png`
  - `prop_rack_full_01.png`
  - `obj_service_compute_aws_01.png`
  - `char_player_idle_down_01.png`
  - `fx_door_glow_01.png`

## Tilesets (32x32)
### Floor
- `tiles_floor_metal_01` to `_04`
- `tiles_floor_grid_01` to `_03`
- `tiles_floor_cable_channel_01` to `_02`

### Walls
- `tiles_wall_panel_01` to `_04`
- `tiles_wall_vent_01` to `_02`
- `tiles_wall_hatch_01`

### Edges & Corners
- `tiles_edge_inner_01` to `_04`
- `tiles_edge_outer_01` to `_04`
- `tiles_trim_base_01` to `_02`

### Doors
- `tiles_door_frame_01`
- `tiles_door_open_01`
- `tiles_door_closed_01`
- `tiles_door_transition_01`

## Props (Recommended Size)
### Server Room
- Server rack (1x2 tiles): `prop_rack_empty_01`, `prop_rack_half_01`, `prop_rack_full_01`
- Server blade (1x1): `prop_server_small_01`
- UPS/battery (1x1): `prop_ups_01`
- Cooling unit (1x2): `prop_cooling_01`
- Cable tray (2x1): `prop_cable_tray_01`
- Switch/router (1x1): `prop_switch_01`
- Patch panel (1x1): `prop_patch_01`
- Workbench (2x1): `prop_workbench_01`
- Crate (1x1): `prop_crate_01`
- Warning sign (1x1): `prop_sign_warn_01`

### Door Props
- Doorway highlight (1x1 overlay): `fx_door_glow_01`
- Door marker (1x1): `prop_door_marker_01`

## Objects (Service Placeholders)
### Provider-neutral
- Compute terminal (1x1): `obj_service_compute_01`
- Storage terminal (1x1): `obj_service_storage_01`
- Network terminal (1x1): `obj_service_network_01`

### Provider-branded
- AWS: `obj_service_compute_aws_01`, `obj_service_storage_aws_01`
- GCP: `obj_service_compute_gcp_01`, `obj_service_storage_gcp_01`
- Cloudflare: `obj_service_network_cf_01`
- Vultr: `obj_service_compute_vultr_01`

## Characters
### Player
- Idle (4 dirs): `char_player_idle_up_01`, `_down_01`, `_left_01`, `_right_01`
- Walk (4 dirs, 4 frames each): `char_player_walk_up_01` to `_04` (repeat for each dir)
- Interact (2 frames, optional): `char_player_interact_down_01` to `_02`

### NPC (Optional)
- Idle (2 frames): `char_robot_idle_down_01` to `_02`

## UI (Room View)
- Panel background: `ui_panel_room_summary_01`
- Button base: `ui_button_primary_01`
- Icon set (16x16): `ui_icon_add`, `ui_icon_edit`, `ui_icon_room`, `ui_icon_object`

## VFX
- Server light blink (overlay 16x16): `fx_server_blink_01`
- Placement highlight (32x32): `fx_place_highlight_01`
