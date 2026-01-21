# Audio Guide

## Standards
- Format: 48kHz WAV for source, export OGG for runtime.
- Length: 20-90s for music loops; 0.2-1.5s for SFX.
- Looping: seamless loop points, no hard cut.
- Loudness: target -16 LUFS integrated for music, -10 LUFS for UI/SFX.

## Music by Room Type
### server_room (default)
- Mood: ambient sci-fi hum, low synth bed, subtle mechanical rhythm.
- Instruments: soft pads, low drones, faint beeps.
- Place in: `game_audio/music/room_server_room.ogg`

### aws room
- Mood: airy, high-tech, light arpeggios, neutral corporate sci-fi.
- Instruments: bell-like synths, gentle pulses.
- Place in: `game_audio/music/room_aws.ogg`

### gcp room
- Mood: bright, clean, optimistic tech ambience.
- Instruments: soft keys, light percussive ticks.
- Place in: `game_audio/music/room_gcp.ogg`

### cloudflare room
- Mood: energetic, network flow, slightly percussive.
- Instruments: rhythmic clicks, soft digital noise.
- Place in: `game_audio/music/room_cloudflare.ogg`

### vultr room
- Mood: industrial tech, darker texture.
- Instruments: low pulses, subtle metallic hits.
- Place in: `game_audio/music/room_vultr.ogg`

## Region Rooms
- Reuse provider room track, or create variants with minor tonal shifts.
- Place in: `game_audio/music/room_<provider>_<region>.ogg`

## SFX
### Navigation
- Door open/close: short mechanical slide.
- Place in: `game_audio/sfx/door_open.ogg`, `game_audio/sfx/door_close.ogg`

### UI
- Button confirm/cancel: soft click.
- Place in: `game_audio/sfx/ui_confirm.ogg`, `game_audio/sfx/ui_cancel.ogg`

### Placement
- Object place/remove: subtle snap or data chime.
- Place in: `game_audio/sfx/object_place.ogg`, `game_audio/sfx/object_remove.ogg`
