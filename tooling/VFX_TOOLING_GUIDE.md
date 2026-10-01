# Game Visual Effects (VFX) Tooling & Generation Guide

This guide provides tested workflows, open-source software, and AI pipelines to create animated visual effects (SVG, APNG, GIF, MP4, and SpriteSheets) for Colosynth.

---

## 1. Runtime Architecture in Colosynth

Colosynth uses a **hybrid VFX architecture**:
1. **Cinematic Cut-Ins (Persona 5 Eye Banner)**:
   - Rendered via Flutter UI Overlays (`P5CutInOverlay`) with `AnimationController`, `CustomClipper`, and dynamic image zooming.
   - 60fps native scaling, zero video decode latency, procedural speed lines.
2. **In-Game Combat Effects (Target / Self VFX)**:
   - Rendered via Flame's `SpriteAnimationComponent` using $4\times 4$ (16-frame) or $8\times 8$ (64-frame) PNG sprite sheets with transparency.
   - Combined with Flame's `ParticleSystemComponent` for explosive comic sparks and camera screen shake.

---

## 2. Dedicated VFX Creation Tools

### A. Effekseer (Recommended for Magic & Combat Particles)
- **Website**: [https://effekseer.github.io/](https://effekseer.github.io/)
- **Cost**: Free & Open-Source.
- **Best For**: 2D/3D slashes, lightning, magic circles, explosions, laser beams.
- **Export Formats**:
  - Direct **SpriteSheet PNG** (specify row $\times$ col, e.g. $4\times 4$ or $8\times 8$, with alpha channel).
  - **APNG / GIF / AVI**.
- **Workflow**:
  1. Open Effekseer and choose or build a particle/ribbon effect from hundreds of bundled templates.
  2. Set the camera to Orthographic (2D front view).
  3. Go to **File -> Export -> Export as SpriteSheet**.
  4. Set image size to $512\times 512$ or $1024\times 1024$ and frame count to 16.
  5. Save directly into `assets/images/vfx/vfx_<name>.png`.

### B. Glaxnimate (Vector & SVG Animations)
- **Website**: [https://glaxnimate.mattbas.org/](https://glaxnimate.mattbas.org/)
- **Cost**: Free & Open-Source.
- **Best For**: Comic ink slashes, pop-art starbursts, animated SVG icons, Lottie JSON.
- **Export Formats**:
  - **Animated SVG** (`.svg`)
  - **APNG** (`.png`)
  - **Lottie JSON** (`.json`)
  - **Sprite Sheet PNG**
- **Workflow**:
  1. Draw clean vector bezier paths with stroke gradients and speedlines.
  2. Animate stroke trim and scale keyframes.
  3. Export to APNG or Sprite Sheet with transparent background.

### C. Aseprite / Pixelorama (Pixel & Hand-Drawn Frame Animation)
- **Websites**: [Aseprite](https://www.aseprite.org/) / [Pixelorama](https://orama-interactive.itch.io/pixelorama)
- **Best For**: Hand-crafted comic flame arcs, stylized impact frames.
- **Export**: **File -> Export Sprite Sheet** -> Output grid PNG + JSON metadata.

---

## 3. Video / GIF / APNG Conversion Pipelines

When sourcing animated effects as MP4 or GIF clips (e.g. from itch.io, Kenney, or AI video generators), convert them to Flame-ready sprite sheets using `ffmpeg` or `ImageMagick`:

### Converting MP4 / GIF to a 16-Frame SpriteSheet ($4\times 4$ Grid) with `ffmpeg`
```bash
# 1. Extract 16 frames uniformly across the video duration:
ffmpeg -i input_effect.mp4 -vf "fps=16/1.0,scale=128:128" -frames:v 16 frame_%02d.png

# 2. Tile the 16 frames into a single 512x512 sprite sheet:
ffmpeg -i frame_%02d.png -filter_complex tile=4x4 vfx_custom.png
```

### Converting APNG / GIF to SpriteSheet using ImageMagick
```bash
# Montage GIF/APNG frames into a 4x4 transparent sprite sheet:
magick montage -background transparent -tile 4x4 -geometry 128x128+0+0 "input_effect.gif[0-15]" vfx_custom.png
```

---

## 4. Curated Free & CC0 VFX Asset Libraries

1. **Kenney Game Assets**:
   - [Kenney Particle Pack](https://kenney.nl/assets/particle-pack) (over 80 high-contrast elemental textures).
2. **OpenGameArt.org**:
   - Search tags: `2D FX`, `Spell Animations`, `Slash Sprite Sheet`.
3. **Itch.io Game Assets**:
   - Search tags: `VFX`, `Sprite Sheet`, `Visual Effects`, `Anime Slash`.

---

## 5. Adding a New Skill VFX to Colosynth

1. Place the generated $4\times 4$ sprite sheet PNG in `assets/images/vfx/vfx_<archetype>.png`.
2. Register the archetype in [`SpriteRepository`](file:///c:/Users/Lenovo/Desktop/Colosynth/lib/services/sprite_repository.dart):
   ```dart
   static String skillVfx(String archetype) => 'vfx/vfx_$archetype.png';
   ```
3. Map the character's active skill to the archetype in `SkillVfxComponent.archetypeForCharacter(characterId)`.
4. Flame will automatically load and animate the 16-frame sequence with 60fps timing and particle sparks!
