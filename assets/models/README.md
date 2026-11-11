# 3D model assets

The board and chess pieces are exported as binary glTF 2.0 GLB files by `tools/build_models.py`.

- `board.glb`: black-marble and ivory chessboard with a machined brass frame.
- `pieces/pawn.glb`, `rook.glb`, `knight.glb`, `bishop.glb`, `queen.glb`, `king.glb`: separate metallic chess-piece models.

Materials use PBR metallic and roughness values for polished platinum, champagne gold, black chrome, and obsidian enamel. Godot changes the platinum material to black chrome for the dark side while keeping the gold details.

Regenerate locally with `python -m pip install numpy 'trimesh>=4.4,<5'` followed by `python tools/build_models.py --output assets/models`. GitHub Actions performs the same generation automatically when the model generator changes.
