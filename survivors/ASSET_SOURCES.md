# Asset Sources and Processing

License status was checked on the official source page and against the license text bundled with each Kenney download. Assets with unclear licensing were not used.

## Sources Used

| Source | Download | License verified | Used for |
|---|---|---|---|
| [Kenney Music Jingles](https://kenney.nl/assets/music-jingles) | [ZIP](https://kenney.nl/media/pages/assets/music-jingles/f37e530b9e-1677590399/kenney_music-jingles.zip) | CC0 1.0 | Victory and defeat stings |
| [Kenney RPG Audio](https://kenney.nl/assets/rpg-audio) | [ZIP](https://kenney.nl/media/pages/assets/rpg-audio/8e99002d76-1677590336/kenney_rpg-audio.zip) | CC0 1.0 | Projectile, melee and XP sounds |
| [Kenney Impact Sounds](https://kenney.nl/assets/impact-sounds) | [ZIP](https://kenney.nl/media/pages/assets/impact-sounds/87b4ddecda-1677589768/kenney_impact-sounds.zip) | CC0 1.0 | Hurt and death impacts |
| [Kenney Interface Sounds](https://kenney.nl/assets/interface-sounds) | [ZIP](https://kenney.nl/media/pages/assets/interface-sounds/fa43c1dd4d-1677589452/kenney_interface-sounds.zip) | CC0 1.0 | UI, pause, level and wave cues |
| [Kenney Roguelike/RPG Pack](https://kenney.nl/assets/roguelike-rpg-pack) | [ZIP](https://kenney.nl/media/pages/assets/roguelike-rpg-pack/12c03cd78b-1677697420/kenney_roguelike-rpg-pack.zip) | CC0 1.0 | Pixel-art UI and upgrade icons |
| [Animated Orcs](https://opengameart.org/content/animated-orcs) | [PNG](https://opengameart.org/sites/default/files/orc%20spritesheet%20calciumtrice.png) | CC BY 3.0 | Fast and elite enemy animations |

## Conversion Notes

### Audio

- Processed with ffmpeg 8.1.2.
- All SFX were converted to PCM WAV, mono, 44.1 kHz.
- Both music stings were converted to OGG Vorbis, stereo, 44.1 kHz.
- Audio was normalized with `loudnorm=I=-16:TP=-1.5:LRA=11`.
- The source clips are short one-shot cues, so looping was not enabled.

### UI Images

- Source tiles are transparent 16×16 PNG pixel art.
- UI icons were scaled to 64×64 with nearest-neighbor resampling.
- Upgrade icons were scaled to 128×128 with nearest-neighbor resampling.
- Transparency was preserved.
- `timer.png` and `pause.png` were drawn on a 16×16 transparent grid and enlarged with nearest-neighbor resampling.

### Enemy Spritesheets

- The source sheet contains two characters in 32×32 frames, ten frames per animation.
- Each source frame was centered on a transparent 100×100 canvas.
- The fast enemy was enlarged 2× with nearest-neighbor resampling.
- The elite enemy was enlarged 3× with nearest-neighbor resampling.
- Output sheets contain ten 100×100 frames in a horizontal strip.
- Source row mapping: `idle` → idle, `gesture` → hurt, `walk` → walk, `attack` → attack, `death` → death.
- Both enemies face right, matching the existing orc's visual orientation.

## Download Checksums

SHA-256 values recorded for the downloaded Kenney archives:

- `kenney_music-jingles.zip`: `b729ba57959bd58793d2c5cafa348aaf2655d354f3da35ec4729e03ec77197b8`
- `kenney_rpg-audio.zip`: `6dbeaf8544da958d8f2adcb4a4a4b76c1ade34a05f8ab9edccd327da7375f38b`
- `kenney_impact-sounds.zip`: `029d734af1582474edf3a694d1b0cebc97c1c152f2f39fa34d4c2bafc5de77f8`
- `kenney_interface-sounds.zip`: `f2193d072726d6758a5f7871b2dcc54dcce0d5c35c6f0a62f92549b327c81232`
- `kenney_roguelike-rpg-pack.zip`: `8e7d2378f8f794245645f6d7dc7aeeb246791410a7e512293c594b46a5a9524b`
- `orc spritesheet calciumtrice.png`: `2d6759c13927a1ad5591ad8088bc9326d26a1e23fe2fcc29e5346f70870e5464`
