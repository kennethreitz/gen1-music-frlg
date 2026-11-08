# Gen 1 Music for FireRed

Original Red/Blue Game Boy music in gen1recomp's FireRed and LeafGreen modes.
**Code only: no ROM, sound bank, rendered audio, or other game-derived data is distributed.**

## Requirements

- gen1recomp 0.4.1, compatible range `>=0.4.1 <0.5.0`.
- Own Pokemon Red and import your own supported Red ROM through gen1recomp's launcher. A complete **Red** import is required, even when playing LeafGreen. Blue alone does not currently satisfy this requirement.
- Your own imported FireRed or LeafGreen to play.
- Approve this mod's declared `engine_internals` permission. It uses the native Game Boy synth; no filesystem or network permission is requested.

## Install and enable

1. Download `gen1_music_frlg-v0.1.0.zip` from [Releases](https://github.com/kennethreitz/gen1-music-frlg/releases).
2. Use the launcher's mod installer, or extract its files into your save directory's `mods/gen1_music_frlg/` folder. `manifest.json` must be directly inside that folder.
3. Import Red in the launcher if you have not already done so.
4. Open **Launcher > FireRed (or LeafGreen) > Mods > Gen 1 Music for FireRed** and enable it. It is experimental and **off by default**.
5. Start your game. Disabling the mod restores the native soundtrack. It does not alter saves or global options.

## How it works

On each enabled boot, the mod opens the player's validated Red dataset using `mod.datasets:open("red")`. It reads public audio metadata and resolves the imported sound-program asset with the dataset's asset API. With the declared engine-internals permission, the native `ChipSynth.newEngine` loads that local asset. The mod derives self-contained channel programs, waveforms and drum definitions **in memory**, then registers 48 FRLG music cues using the public music registry.

The existing `ModAudio -> Music -> ChipAudio -> ChipSynth` path synthesizes and streams the Game Boy audio live. There are no OGGs, audio downloads, generated files, persistent caches, hardcoded music bytes, or engine patches. Original bytecode loops are preserved, including Lavender and Cinnabar Mansion's differing channel periods.

See [TRACKS.md](TRACKS.md) for all **48 cue mappings to 42 Red/Blue tracks**.

## Known gaps

- Sevii-specific and other unmapped FRLG-only cues keep their original music.
- Heal/item/badge/level-up/evolution-complete fanfares, Jigglypuff, flute and short scripted jingles remain native. Gen 3's music override dispatcher forces loops, so replacing one-shot fanfares could break waits.
- Evolution uses Red's Safari Zone theme. Mewtwo/legend encounters use Red's wild battle theme. Rival exit and slow Pallet use the normal Red versions, not tempo-edited arrangements.
- Uses engine internals available in 0.4.1; future engine updates may need an adaptation. The mod honors the native platform/performance sample rate (including Android's 22050 Hz). If you change the performance tier while playing, restart the game session so derived drum timing is rebuilt for the new rate.
- Headless integration tests pass; an audible desktop/handheld play-test has not yet been completed.

## Tests and development

From a gen1recomp checkout, with LuaJIT installed:

```sh
luajit /path/to/gen1-music-frlg/tools/test_runtime.lua /path/to/gen1-music-frlg /path/to/your/red-cache
```

The last directory contains your locally imported `data/generated/audio.lua` and `assets/generated/audio/programs.bin`. Do not commit either file. The test uses the engine's real dataset views, sandbox, loader, schema, numeric song dispatcher and synth, with mocked audio Sources and a fixture filesystem. It checks default-off behavior, missing-Red rollback, all 48 mappings on both games at 22050 and 44100 Hz, native fallbacks, and compares one second of every derived track sample-for-sample against the original native synth. No derived test inputs or outputs are distributed.

## Credits and license

- Built for [gen1recomp](https://github.com/bryanthaboi/gen1recomp), by bryanthaboi and contributors. Its native ChipSynth and public mod APIs perform the synthesis; this repository does not vendor its engine.
- Inspired by [DarioMelo's Music1_FRLG](https://github.com/DarioMelo/Gen1Recomp-Music1-FRLG), which replaces music in the opposite direction. No code or audio from that mod is redistributed here.
- MIT license, copyright 2026 Kenneth Reitz. See [LICENSE](LICENSE). The license covers this project's original code and documentation only, not Nintendo's games or music. This is an unofficial fan-made mod, not affiliated with Nintendo, Game Freak or The Pokemon Company.

Do not upload your ROMs, extracted sound data or generated audio. The ignore rules deliberately exclude these files.
