extends SceneTree

const Rules = preload("res://scripts/chess_rules.gd")

func _initialize() -> void:
	var rules = Rules.new()
	rules.reset()

	assert(rules.all_legal_moves(true).size() == 20, "Initial position must have 20 legal white moves")
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

	print("ChessRules tests passed.")
	quit()
