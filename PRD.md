# Development PRD: Character Creation Enhancements

## Summary
Upgrade the character creation flow to support richer customization, stronger validation, and an improved UX that works with touch, keyboard, and gamepad. The feature should be ready for an early development milestone and designed to evolve as gameplay systems mature.

## Goals
- Enable deeper character customization beyond gender.
- Make name input safe and consistent with validation and feedback.
- Provide a smooth, gamepad-friendly creation flow with live preview.
- Allow editing an existing character from the start menu.
- Keep roles cosmetic (appearance/name only).

## Non-Goals
- Online profiles, cloud sync, or cross-device character sharing.
- Web target support.
- Advanced avatar editor (e.g., freeform sliders, paint tools).

## Target Users
- New players starting the game.
- Returning players selecting/editing existing characters.

## User Stories
- As a new player, I can create a character with a unique name and appearance.
- As a returning player, I can edit my character's name/appearance.
- As a gamepad user, I can complete creation without touching the mouse.

## UX Flow
1) Start Menu -> "Create New Character" or "Edit" on a character card.
2) Step 1: Name input with validation and suggestions.
3) Step 2: Appearance (gender, skin tone, hair, outfit), with live preview.
4) Summary -> Create/Save.

## Functional Requirements
### Character Data
- Store: name, gender, skin tone, hair style/color, outfit variant.
- Preserve existing fields: id, createdAt, lastPlayedAt, level, credits.

### Validation
- Name length: 2-16 characters.
- Trim whitespace; block empty or all-space names.
- Disallow reserved words and profane words.
- Duplicate names are allowed (uniqueness by UUID).

### Creation & Editing
- Multi-step dialog/sheet with next/back actions.
- Live preview of the character sprite as selections change.
- "Randomize" button to auto-pick appearance + name suggestion.
- Allow editing an existing character from the list.

### Input & Accessibility
- Full keyboard and gamepad support for all fields.
- Clear focus order and visual focus outline.
- Error messages are readable and non-blocking.

## Data & Technical Considerations
- Update `CharacterModel` to include new fields.
- No backward-compat requirement; schema changes can reset local data until post-release.
- Asset mapping: define available sprite variants in `game_asset/characters`.

## Milestones
1) Data model + storage migration.
2) New creation UI (multi-step + preview).
3) Edit flow from character list.
4) Validation + randomize.
5) Polish, QA, and tests.

## Acceptance Criteria
- Can create a character with name + appearance, and it persists.
- Can edit an existing character and see updates in the list.
- Validation blocks invalid names and shows clear feedback.
- Gamepad-only flow completes without dead ends.
- Old characters still load without crashes.

## Risks & Open Questions
- Asset coverage: ensure all appearance variants exist in `game_asset`.

---

# Development PRD: Game World & Rooms (Core Feature)

## Summary
Introduce a navigable 2D world where players start in a default `server_room`, move through doors to other rooms, and manage room contents (objects and nested rooms). Rooms persist in storage and show summary counts of contained objects.

## Goals
- Establish a room/door navigation system (tree-like world layout).
- Provide a 2D room view (Stardew Valley-like layout).
- Persist all rooms and objects locally.
- Ship a preset catalog of common cloud services while allowing custom services.
- Show per-room object count summaries.

## Non-Goals
- Multiplayer or shared worlds.
- Real-time cost simulation or monitoring.
- Web target support.

## World Structure
- Rooms form a tree; a room can contain objects and child rooms.
- Doors connect a room to its child rooms.
- Default room on new game: `server_room` with racks + servers.
- Provider rooms (e.g., AWS) can contain region rooms (e.g., `us-east-1`).

## User Stories
- As a player, I can walk through doors to enter other rooms.
- As a player, I can create a new room and choose a type (AWS, GCP, Cloudflare, Vultr, etc.).
- As a player, I can add objects to a room (e.g., EC2, S3).
- As a player, I can create nested rooms (AWS -> region rooms).
- As a player, I can view a room summary showing object counts.

## UX Flow
1) Enter game -> spawn in `server_room`.
2) Walk to doors -> transition to target room.
3) Room summary panel shows object counts.
4) Add room -> choose type -> room appears with a door.
5) Add object -> choose provider + service -> object appears in room.

## Functional Requirements
### Rooms
- Room has: id, name, type, parentId (optional), childRoomIds, objects.
- Room type presets: server_room, aws, gcp, cloudflare, vultr, azure, digital_ocean, custom.
- Regions are rooms under provider rooms (e.g., `aws/us-east-1`).

### Objects
- Object has: id, name, provider, serviceType, roomId, metadata.
- Preset catalog for providers (outline only for now): aws, gcp, vultr, cloudflare, azure, digital_ocean.
- Allow custom service definitions.

### Navigation
- Door per child room; door triggers room transition.
- Player position resets to spawn point in new room.
- Room menu supports adding doors; player selects placement location.
- Doors are wall-only, grid-aligned, two character widths, with at least one tile gap between doors.

### Persistence
- Local persistence for all room/object data.
- No schema versioning until post-release.

### Summary
- Show counts of objects by type/provider in the current room only.
- Updates live as objects are added/removed.

## Data & Technical Considerations
- New world/room storage layer (likely in `app_lib/database`).
- No backward-compat requirement; schema changes can reset local data until post-release.
- Asset coverage for doors, racks, and cloud service placeholders.

## Game Assets Checklist (Homelab Sci‑Fi Default)
### Environment Tiles
- Floor tiles: clean metal, gridded panels, cable channels.
- Wall tiles: sci‑fi panels, vents, access hatches.
- Corner/edge tiles: inner/outer corners, trims, skirting.
- Door frames: closed, open, and transition variants.

### Room Props (Default)
- Server racks (empty, half, full).
- Servers/blades (small, medium, large variants).
- Cooling units, UPS/battery stacks, cable trays.
- Network gear: switches, routers, patch panels.
- Workbench + tools, storage crates, warning signs.

### Objects (Service Placeholders)
- Provider-neutral service terminals (compute, storage, network).
- Basic cloud service icons/labels for AWS/GCP/Cloudflare/Vultr.

### Characters & Interaction
- Player sprite: idle, walk (4 directions), interact.
- NPC/robot helper (optional): idle, idle alt.
- Interaction prompts: door use, object inspect, add/edit.

### UI Elements (Room View)
- Room summary panel with object counts.
- Add room/object buttons and selection list styles.
- Tooltips/labels for room name and door destinations.

### VFX & Feedback
- Door glow/activate effect.
- Object placement highlight.
- Subtle ambient flicker for server lights.

### Audio (Optional for MVP)
- Door open/close SFX.
- Low hum/ambient rack noise.

## Milestones
1) Data model + persistence for rooms/objects.
2) Basic 2D room view + player spawn + door transitions.
3) Room creation + provider presets + region rooms.
4) Object catalog + room placement UI.
5) Summary panel + layout rules (expandable room size).

## Acceptance Criteria
- New game starts in `server_room` with visible racks/servers.
- Player can enter a door to a child room and return.
- Player can add a room and see a new door.
- Player can add objects to a room and see them rendered.
- Room summary shows accurate object counts.
- Room/objects persist across app restarts.

## Risks & Open Questions
- Define room layout rules for door placement in 2D view.
