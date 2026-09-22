# Temizlikci app icon — Icon Composer source layers

Concept approved in Phase 1: three sunburst rings with one outer segment swept loose and catching the light, for the space you get back. `preview.svg` / `preview-1024.png` show the flat composite; Icon Composer adds the Liquid Glass material, the shape, and the dark/clear/tinted appearances.

| Layer (front to back) | File | Notes |
|---|---|---|
| Sparkle | `layers/3-sparkle.svg` | White |
| Lifted segment | `layers/2-lifted-segment.svg` | White, highest layer so it catches the most light |
| Rings | `layers/1-rings.svg` | Palette slots 1–4 (inner) and their tints (outer); center left open |
| Background | `layers/0-background.svg` | Or set the Background fill in Icon Composer to a gradient `#1d2b44` → `#0c1320` |

## Assemble (about 5 minutes)
1. Open **Xcode › Open Developer Tool › Icon Composer**, then File › New.
2. Drag `1-rings.svg`, `2-lifted-segment.svg`, and `3-sparkle.svg` onto the canvas as separate layers (in that order, sparkle on top).
3. Select the document and set **Background** to a linear gradient `#1d2b44` (top) → `#0c1320` (bottom), or drop in `0-background.svg`.
4. Optional: raise the lifted segment's Liquid Glass/specular slightly, and check the Dark, Clear, and Tinted previews.
5. Save as **`AppIcon.icon`** in this folder (`design/app-icon/AppIcon.icon`), then ask Claude to wire it into the project.
