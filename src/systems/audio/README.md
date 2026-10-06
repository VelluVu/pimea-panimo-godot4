# Audio system

Sound effects, music and UI clicks. Sound effects share a small pool so overlapping ones do not
cut each other off. Music is either one looping track (a menu theme) or a shuffled playlist.
Both keep playing while the tree is paused, since menus usually pause it. Every button that
enters the tree clicks when pressed, so a new button can never be left silent.

## Interface (`AudioPlayback`)

| Call | What it does |
|---|---|
| `play_sfx(stream, volume_db)` | One-shot sound. A click asked for in the same frame gives way to it |
| `play_sfx_at(stream, world_position, volume_db, pitch_scale)` | One-shot sound at a place in the 2D world, panned and faded by its distance to the current `AudioListener2D` |
| `play_click()` | The UI click, at most once per frame; call it for keyboard shortcuts too |
| `play_music_loop(stream)` | Loops one track; keeps going if it already is the loop |
| `play_playlist(tracks)` | Shuffled playlist, repeating |
| `is_playlist_playing()` | For deciding whether to start the playlist again |

Settings: `sfx_bus`, `music_bus`, `sfx_pool_size`, `click_stream`, `click_all_buttons`, and for
world sounds `world_pool_size`, `world_max_distance`, `world_attenuation`, `world_panning_strength`.

## Use it in a new project

1. Copy this folder (keep the `.uid` files).
2. Edit **`audio_wiring.gd`**: your buses, the click sound, which music plays in which scene,
   and which of your signals play which sound. In this game it reads an `AudioBank` resource,
   listens to `BrewerySignals`, `GUISignals` and two managers, and runs the LVV risk drone.
3. Register an autoload whose script is `audio_wiring.gd`, or a two-line script that extends
   `AudioWiring` (this game's `src/autoload/audio_manager.gd`).

## Files

`audio_playback.gd` the interface, `audio_wiring.gd` the project's sounds.
