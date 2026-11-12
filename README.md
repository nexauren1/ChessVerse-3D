# ChessVerse 3D

A premium, landscape-first 3D chess game built with Godot 4 for Android.

## Visual direction
- Black marble and ivory chessboard with a machined brass frame and shader-based marble veining.
- Gold pieces for the near side and polished silver pieces for the far side.
- A cinematic palace hall with dark columns, warm gold inlays, a moonlit futuristic skyline, and reflective metal materials.
- Gold-framed player panels, a turn indicator, and side controls.
- Landscape composition designed for phone screens.

## Current implementation
- Procedural GLB chessboard and six procedural piece models, merged by PBR material to reduce draw calls.
- Runtime palace architecture, instanced city windows, moon, lighting, and a reflection probe.
- Touch/mouse selection, animated moves, alternating turns, captures, legal move filtering, check detection, castling, en passant, and queen promotion.
- Single-player mode against a local alpha-beta chess AI (currently depth 2), local two-player mode, and a recorded coordinate move history.
- Headless Godot CI tests for opening move count, illegal pawn movement, en passant target creation, and an AI reply.
- Runtime HUD with player panels, turn banner, action controls, and popup panels.
- Android Compatibility renderer and an expanded 960×540 logical UI canvas.

## Important development status
This is an early playable prototype, not a finished chess game. The current build remains a prototype. Repetition and fifty-move draw rules, richer chess notation, active clocks, sound, save/load, and Android export validation remain outstanding. AI strength is currently modest and should not be represented as a true 1600 ELO rating. The displayed AI name, ELO and clocks are currently presentation placeholders.

## Open the project
1. Install a compatible Godot 4.x editor.
2. Clone or download this repository.
3. Import the folder containing project.godot.
4. Run the main scene.

## Android
The project is configured for landscape orientation and the Compatibility renderer. An Android export requires matching export templates and Android build prerequisites configured in the editor. No signed APK is included yet.

## Performance
The environment uses low-poly procedural architecture, instanced skyline windows, grouped GLB meshes, and a small number of dynamic lights. Test frame rate, touch accuracy, thermal behaviour, and memory use on the target Android device before release.

## License
To be selected before public distribution.
