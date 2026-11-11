# Chess rules specification

The production rules engine must validate every move before changing the board.

## Required rules
- Standard 8x8 board and initial setup.
- Pawn: one square forward, two from its starting rank if unobstructed, diagonal capture, en passant.
- Knight: L-shaped movement and jumping.
- Bishop: diagonal movement with no pieces blocking the path.
- Rook: horizontal and vertical movement with no pieces blocking the path.
- Queen: rook and bishop movement combined.
- King: one square in any direction, never into check.
- Castling: king and rook unmoved, path clear, king not in check and does not cross an attacked square.
- Promotion: pawn reaching the final rank becomes queen, rook, bishop, or knight.
- Check, checkmate, stalemate, and draw conditions.

## Validation architecture
1. Generate pseudo-legal moves for the selected piece.
2. Simulate each candidate move.
3. Reject moves that leave the moving side's king in check.
4. Apply the selected legal move and update turn, castling rights, en-passant target, half-move counter, and position history.
5. Detect check, checkmate, stalemate, repetition, fifty-move draw, and insufficient material.

The 3D scene must never be the source of truth for chess legality. Board state belongs in a separate rules/model layer.