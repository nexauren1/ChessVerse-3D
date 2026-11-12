# ChessVerse 3D

A premium, landscape-first 3D chess game built with Godot 4 for Android.

## Visual direction
- Black marble and ivory chessboard with a machined brass frame.
- Gold pieces for the near side and polished silver pieces for the far side.
- A cinematic palace hall with dark columns, warm gold inlays, a moonlit futuristic skyline, and reflective metal materials.
- Gold-framed player panels, turn indicator, and side controls.
- Landscape interface designed around a wide 16:9 composition.

## Current implementation
- Procedural GLB chessboard and six procedural piece models.
- Runtime palace architecture, skyline, moon, lighting, and reflection probe.
- Touch/mouse selection and animated piece movement prototype.
- Runtime HUD with player panels, turn banner, action controls, and popup panels.
- Android Compatibility renderer to target a broad range of mobile GPUs.

## Important development status
The current interaction layer is still a visual prototype. Full legal chess move validation, check/checkmate, castling, en passant, promotion, the computer opponent, clock logic, move history, sound, save/load, and Android export validation remain to be implemented and tested.

## Open the project
1. Install a compatible Godot 4.x editor.
2. Clone or download this repository.
3. Import the folder containing project.godot.
4. Run the main scene.

## Android
The project is configured for landscape orientation and the Compatibility renderer. An Android export requires matching export templates and Android build prerequisites configured in the editor. No signed APK is included yet.

## Performance
The environment is assembled from low-poly primitive meshes and uses few dynamic lights. Run tests on the target Android device and reduce glow, shadow, or skyline detail if its GPU needs a lighter profile.

## License
To be selected before public distribution.
