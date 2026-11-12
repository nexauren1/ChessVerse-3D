extends SceneTree

const Rules = preload("res://scripts/chess_rules.gd")
var failures := 0

func _initialize() -> void:
	var rules = Rules.new()
	rules.reset()
	var opening_knight_moves := rules.legal_moves_from(Vector2i(6,7))
	_check(opening_knight_moves.size() == 2, "White knight must have two legal moves in the initial position")

	_check(rules.all_legal_moves(true).size() == 20, "Initial position must have 20 legal white moves")
	_check(not rules.play_move(Vector2i(4,6),Vector2i(4,3)), "A pawn cannot move three squares")
	_check(rules.play_move(Vector2i(4,6),Vector2i(4,4)), "e2-e4 should be legal")
	_check(not rules.white_to_move, "Turn must pass to Black")
	_check(rules.en_passant == Vector2i(4,5), "Double pawn move must set en passant target")

	var ai_move: Dictionary = rules.play_ai_move(1)
	_check(not ai_move.is_empty(), "Computer must find a legal reply")
	_check(rules.white_to_move, "Turn must return to White after computer move")
	_check(rules.move_history.size() == 2, "Both moves must be stored")



	# Fool's Mate: confirms that checkmate is detected from legal moves.
	var mate = Rules.new()
	mate.reset()
	_check(mate.play_move(Vector2i(5,6),Vector2i(5,5)))
	_check(mate.play_move(Vector2i(4,1),Vector2i(4,3)))
	_check(mate.play_move(Vector2i(6,6),Vector2i(6,4)))
	_check(mate.play_move(Vector2i(3,0),Vector2i(7,4)))
	_check(mate.game_state() == "checkmate", "Fool's Mate must be detected")

	# Threefold repetition using both knights.
	var repetition = Rules.new()
	repetition.reset()
	for cycle in range(2):
		_check(repetition.play_move(Vector2i(6,7),Vector2i(5,5)))
		_check(repetition.play_move(Vector2i(6,0),Vector2i(5,2)))
		_check(repetition.play_move(Vector2i(5,5),Vector2i(6,7)))
		_check(repetition.play_move(Vector2i(5,2),Vector2i(6,0)))
	_check(repetition.game_state() == "draw", "Threefold repetition must be a draw")

	var fifty_move = Rules.new()
	fifty_move.reset()
	fifty_move.halfmove_clock = 100
	_check(fifty_move.game_state() == "draw", "Fifty-move rule must be a draw")


	# En passant capture removes the pawn from the adjacent square.
	var ep_rules = Rules.new()
	ep_rules.reset()
	_check(ep_rules.play_move(Vector2i(4,6),Vector2i(4,4)))
	_check(ep_rules.play_move(Vector2i(0,1),Vector2i(0,2)))
	_check(ep_rules.play_move(Vector2i(4,4),Vector2i(4,3)))
	_check(ep_rules.play_move(Vector2i(3,1),Vector2i(3,3)))
	_check(ep_rules.play_move(Vector2i(4,3),Vector2i(3,2)))
	_check(ep_rules.piece_at(Vector2i(3,3)).is_empty(), "En passant must remove the captured pawn")

	# Castling moves both king and rook.
	var castle_rules = Rules.new()
	castle_rules.reset()
	castle_rules.board.clear()
	castle_rules.board[Vector2i(4,7)] = {"kind":"king","white":true}
	castle_rules.board[Vector2i(7,7)] = {"kind":"rook","white":true}
	castle_rules.board[Vector2i(4,0)] = {"kind":"king","white":false}
	_check(castle_rules.play_move(Vector2i(4,7),Vector2i(6,7)), "White king-side castling should be legal")
	_check(castle_rules.piece_at(Vector2i(6,7)).kind == "king")
	_check(castle_rules.piece_at(Vector2i(5,7)).kind == "rook")

	# Promotion choice is respected by the rules engine.
	var promotion_rules = Rules.new()
	promotion_rules.reset()
	promotion_rules.board.clear()
	promotion_rules.board[Vector2i(4,7)] = {"kind":"king","white":true}
	promotion_rules.board[Vector2i(4,0)] = {"kind":"king","white":false}
	promotion_rules.board[Vector2i(0,1)] = {"kind":"pawn","white":true}
	_check(promotion_rules.play_move(Vector2i(0,1),Vector2i(0,0),"knight"), "Pawn promotion should be legal")
	_check(promotion_rules.piece_at(Vector2i(0,0)).kind == "knight", "Promotion piece must match the selected type")

	if failures == 0:
		print("ChessRules tests passed.")
		quit(0)
	else:
		push_error("ChessRules tests failed: " + str(failures))
		quit(1)

func _check(condition: bool, message: String = "Test failed") -> void:
	if not condition:
		failures += 1
		push_error(message)
