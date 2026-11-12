extends SceneTree

const Rules = preload("res://scripts/chess_rules.gd")
var failures := 0

func _initialize() -> void:
	var rules = Rules.new()
	rules.reset()

	_check(rules.all_legal_moves(true).size() == 20, "Initial position must have 20 legal white moves")
	assert(not rules.play_move(Vector2i(4,6),Vector2i(4,3)), "A pawn cannot move three squares")
	assert(rules.play_move(Vector2i(4,6),Vector2i(4,4)), "e2-e4 should be legal")
	assert(not rules.white_to_move, "Turn must pass to Black")
	assert(rules.en_passant == Vector2i(4,5), "Double pawn move must set en passant target")

	var ai_move: Dictionary = rules.play_ai_move(2)
	assert(not ai_move.is_empty(), "Computer must find a legal reply")
	assert(rules.white_to_move, "Turn must return to White after computer move")
	assert(rules.move_history.size() == 2, "Both moves must be stored")

	var knight_moves := rules.legal_moves_from(Vector2i(6,7))
	assert(knight_moves.size() == 2, "White knight should have two legal opening moves")


	# Fool's Mate: confirms that checkmate is detected from legal moves.
	var mate = Rules.new()
	mate.reset()
	assert(mate.play_move(Vector2i(5,6),Vector2i(5,5)))
	assert(mate.play_move(Vector2i(4,1),Vector2i(4,3)))
	assert(mate.play_move(Vector2i(6,6),Vector2i(6,4)))
	assert(mate.play_move(Vector2i(3,0),Vector2i(7,4)))
	assert(mate.game_state() == "checkmate", "Fool's Mate must be detected")

	# Threefold repetition using both knights.
	var repetition = Rules.new()
	repetition.reset()
	for cycle in range(2):
		assert(repetition.play_move(Vector2i(6,7),Vector2i(5,5)))
		assert(repetition.play_move(Vector2i(6,0),Vector2i(5,2)))
		assert(repetition.play_move(Vector2i(5,5),Vector2i(6,7)))
		assert(repetition.play_move(Vector2i(5,2),Vector2i(6,0)))
	assert(repetition.game_state() == "draw", "Threefold repetition must be a draw")

	var fifty_move = Rules.new()
	fifty_move.reset()
	fifty_move.halfmove_clock = 100
	assert(fifty_move.game_state() == "draw", "Fifty-move rule must be a draw")

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
