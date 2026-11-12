extends RefCounted
class_name ChessRules

const FILES := 8
const VALUES := {"pawn":100,"knight":320,"bishop":335,"rook":500,"queen":900,"king":20000}
var board: Dictionary = {}
var white_to_move := true
var castling := {"K":true,"Q":true,"k":true,"q":true}
var en_passant := Vector2i(-1,-1)
var halfmove_clock := 0
var fullmove_number := 1
var move_history: Array[Dictionary] = []

func reset() -> void:
	board.clear()
	castling = {"K":true,"Q":true,"k":true,"q":true}
	en_passant = Vector2i(-1,-1)
	halfmove_clock = 0
	fullmove_number = 1
	move_history.clear()
	white_to_move = true
	var back := ["rook","knight","bishop","queen","king","bishop","knight","rook"]
	for x in range(8):
		board[Vector2i(x,0)] = {"kind":back[x],"white":false}
		board[Vector2i(x,1)] = {"kind":"pawn","white":false}
		board[Vector2i(x,6)] = {"kind":"pawn","white":true}
		board[Vector2i(x,7)] = {"kind":back[x],"white":true}

func piece_at(square: Vector2i) -> Dictionary:
	return board.get(square, {})

func legal_moves_from(square: Vector2i) -> Array[Dictionary]:
	var piece: Dictionary = board.get(square,{})
	if piece.is_empty() or bool(piece.white) != white_to_move:
		return []
	return _legal_moves_for(board, square, piece, castling, en_passant)

func all_legal_moves(for_white: bool = white_to_move) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for square in board.keys():
		var piece: Dictionary = board[square]
		if bool(piece.white) == for_white:
			result.append_array(_legal_moves_for(board, square, piece, castling, en_passant))
	return result

func play_move(from_square: Vector2i, to_square: Vector2i, promotion: String = "queen") -> bool:
	var found: Dictionary = {}
	for move in legal_moves_from(from_square):
		if move.to == to_square:
			found = move
			break
	if found.is_empty():
		return false
	if found.has("promotion"):
		found.promotion = promotion
	move_history.append(found.duplicate(true))
	en_passant = _apply_move(board, found, castling, en_passant)
	white_to_move = not white_to_move
	if white_to_move:
		fullmove_number += 1
	return true

func is_in_check(for_white: bool) -> bool:
	return _is_in_check(board, for_white)

func game_state() -> String:
	var moves := all_legal_moves(white_to_move)
	if moves.is_empty():
		return "checkmate" if is_in_check(white_to_move) else "stalemate"
	return "check" if is_in_check(white_to_move) else "playing"

func choose_ai_move(depth: int = 2) -> Dictionary:
	var moves := all_legal_moves(false)
	if moves.is_empty():
		return {}
	var best_move: Dictionary = moves[0]
	var best_score := -INF
	for move in moves:
		var next_board := board.duplicate(true)
		var next_castling := castling.duplicate()
		var next_ep: Vector2i = _apply_move(next_board, move, next_castling, en_passant)
		var score := _minimax(next_board, next_castling, next_ep, true, depth - 1, -INF, INF)
		if score > best_score:
			best_score = score
			best_move = move
	return best_move

func play_ai_move(depth: int = 2) -> Dictionary:
	var move := choose_ai_move(depth)
	if move.is_empty():
		return {}
	if move.has("promotion"):
		move.promotion = "queen"
	move_history.append(move.duplicate(true))
	en_passant = _apply_move(board, move, castling, en_passant)
	white_to_move = true
	fullmove_number += 1
	return move

func _legal_moves_for(position: Dictionary, from: Vector2i, piece: Dictionary, rights: Dictionary, ep: Vector2i) -> Array[Dictionary]:
	var candidates := _pseudo_moves(position, from, piece, rights, ep)
	var legal: Array[Dictionary] = []
	for move in candidates:
		var test_board := position.duplicate(true)
		var test_rights := rights.duplicate()
		var ignored_ep: Vector2i = _apply_move(test_board, move, test_rights, ep)
		if not _is_in_check(test_board, bool(piece.white)):
			legal.append(move)
	return legal

func _pseudo_moves(position: Dictionary, from: Vector2i, piece: Dictionary, rights: Dictionary, ep: Vector2i) -> Array[Dictionary]:
	var moves: Array[Dictionary] = []
	var white := bool(piece.white)
	var kind: String = piece.kind
	var directions: Array[Vector2i] = []
	if kind == "pawn":
		var dir := -1 if white else 1
		var one := from + Vector2i(0,dir)
		if _inside(one) and not position.has(one):
			_add_pawn_move(moves,from,one,white)
			var start_rank := 6 if white else 1
			var two := from + Vector2i(0,dir*2)
			if from.y == start_rank and not position.has(two):
				moves.append({"from":from,"to":two})
		for dx in [-1,1]:
			var target := from + Vector2i(dx,dir)
			if not _inside(target):
				continue
			if position.has(target) and bool(position[target].white) != white:
				_add_pawn_move(moves,from,target,white)
			elif target == ep:
				moves.append({"from":from,"to":target,"en_passant":true})
		return moves
	if kind == "knight":
		for delta in [Vector2i(1,2),Vector2i(2,1),Vector2i(-1,2),Vector2i(-2,1),Vector2i(1,-2),Vector2i(2,-1),Vector2i(-1,-2),Vector2i(-2,-1)]:
			_add_if_available(moves,position,from,from+delta,white)
		return moves
	if kind in ["bishop","queen"]:
		directions.append_array([Vector2i(1,1),Vector2i(1,-1),Vector2i(-1,1),Vector2i(-1,-1)])
	if kind in ["rook","queen"]:
		directions.append_array([Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)])
	if kind == "king":
		for dx in range(-1,2):
			for dy in range(-1,2):
				if dx != 0 or dy != 0:
					_add_if_available(moves,position,from,from+Vector2i(dx,dy),white)
		var home_y := 7 if white else 0
		var king_key := "K" if white else "k"
		var queen_key := "Q" if white else "q"
		if from == Vector2i(4,home_y) and not _is_square_attacked(position,from,not white):
			if rights.get(king_key,false) and not position.has(Vector2i(5,home_y)) and not position.has(Vector2i(6,home_y)) and _has_rook(position,Vector2i(7,home_y),white) and not _is_square_attacked(position,Vector2i(5,home_y),not white) and not _is_square_attacked(position,Vector2i(6,home_y),not white):
				moves.append({"from":from,"to":Vector2i(6,home_y),"castle":"king"})
			if rights.get(queen_key,false) and not position.has(Vector2i(1,home_y)) and not position.has(Vector2i(2,home_y)) and not position.has(Vector2i(3,home_y)) and _has_rook(position,Vector2i(0,home_y),white) and not _is_square_attacked(position,Vector2i(3,home_y),not white) and not _is_square_attacked(position,Vector2i(2,home_y),not white):
				moves.append({"from":from,"to":Vector2i(2,home_y),"castle":"queen"})
		return moves
	for direction in directions:
		var target := from + direction
		while _inside(target):
			if not position.has(target):
				moves.append({"from":from,"to":target})
			else:
				if bool(position[target].white) != white:
					moves.append({"from":from,"to":target})
				break
			target += direction
	return moves

func _add_pawn_move(moves: Array[Dictionary], from: Vector2i, to: Vector2i, white: bool) -> void:
	if to.y == (0 if white else 7):
		moves.append({"from":from,"to":to,"promotion":"queen"})
	else:
		moves.append({"from":from,"to":to})

func _add_if_available(moves: Array[Dictionary], position: Dictionary, from: Vector2i, to: Vector2i, white: bool) -> void:
	if _inside(to) and (not position.has(to) or bool(position[to].white) != white):
		moves.append({"from":from,"to":to})

func _apply_move(position: Dictionary, move: Dictionary, rights: Dictionary, old_ep: Vector2i) -> Vector2i:
	var from: Vector2i = move.from
	var to: Vector2i = move.to
	var piece: Dictionary = position[from]
	var white := bool(piece.white)
	var kind: String = piece.kind
	if move.get("en_passant",false):
		position.erase(to + Vector2i(0,1 if white else -1))
	if move.has("castle"):
		var y := from.y
		if move.castle == "king":
			var rook: Dictionary = position[Vector2i(7,y)]
			position.erase(Vector2i(7,y))
			position[Vector2i(5,y)] = rook
		else:
			var rook: Dictionary = position[Vector2i(0,y)]
			position.erase(Vector2i(0,y))
			position[Vector2i(3,y)] = rook
	if kind == "king":
		rights["K" if white else "k"] = false
		rights["Q" if white else "q"] = false
	if kind == "rook":
		_update_rook_right(rights,from)
	if position.has(to) and position[to].kind == "rook":
		_update_rook_right(rights,to)
	position.erase(from)
	if move.has("promotion"):
		piece.kind = move.get("promotion","queen")
	position[to] = piece
	if kind == "pawn" and abs(to.y-from.y) == 2:
		return Vector2i(from.x,(from.y+to.y)/2)
	return Vector2i(-1,-1)

func _update_rook_right(rights: Dictionary, square: Vector2i) -> void:
	if square == Vector2i(0,7): rights["Q"] = false
	if square == Vector2i(7,7): rights["K"] = false
	if square == Vector2i(0,0): rights["q"] = false
	if square == Vector2i(7,0): rights["k"] = false

func _has_rook(position: Dictionary, square: Vector2i, white: bool) -> bool:
	return position.has(square) and position[square].kind == "rook" and bool(position[square].white) == white

func _is_in_check(position: Dictionary, white: bool) -> bool:
	var king_square := Vector2i(-1,-1)
	for square in position:
		var piece: Dictionary = position[square]
		if piece.kind == "king" and bool(piece.white) == white:
			king_square = square
			break
	if king_square.x < 0:
		return true
	return _is_square_attacked(position,king_square,not white)

func _is_square_attacked(position: Dictionary, target: Vector2i, by_white: bool) -> bool:
	for square in position:
		var piece: Dictionary = position[square]
		if bool(piece.white) != by_white:
			continue
		var delta := target-square
		match String(piece.kind):
			"pawn":
				var dir := -1 if by_white else 1
				if abs(delta.x)==1 and delta.y==dir: return true
			"knight":
				if (abs(delta.x)==1 and abs(delta.y)==2) or (abs(delta.x)==2 and abs(delta.y)==1): return true
			"king":
				if max(abs(delta.x),abs(delta.y))==1: return true
			"bishop":
				if abs(delta.x)==abs(delta.y) and _ray_clear(position,square,target): return true
			"rook":
				if (delta.x==0 or delta.y==0) and _ray_clear(position,square,target): return true
			"queen":
				if (delta.x==0 or delta.y==0 or abs(delta.x)==abs(delta.y)) and _ray_clear(position,square,target): return true
	return false

func _ray_clear(position: Dictionary, from: Vector2i, to: Vector2i) -> bool:
	var step := Vector2i(int(sign(to.x-from.x)),int(sign(to.y-from.y)))
	var cursor := from+step
	while cursor != to:
		if position.has(cursor): return false
		cursor += step
	return true

func _inside(square: Vector2i) -> bool:
	return square.x>=0 and square.x<8 and square.y>=0 and square.y<8

func _next_ep(move: Dictionary) -> Vector2i:
	var from: Vector2i = move.from
	var to: Vector2i = move.to
	if board.has(from) and board[from].kind=="pawn" and abs(to.y-from.y)==2:
		return Vector2i(from.x,(from.y+to.y)/2)
	return Vector2i(-1,-1)

func _minimax(position: Dictionary, rights: Dictionary, ep: Vector2i, white_turn: bool, depth: int, alpha: float, beta: float) -> float:
	if depth<=0:
		return _evaluate(position)
	var moves: Array[Dictionary] = []
	for square in position:
		var piece: Dictionary = position[square]
		if bool(piece.white)==white_turn:
			moves.append_array(_legal_moves_for(position,square,piece,rights,ep))
	if moves.is_empty():
		if _is_in_check(position,white_turn):
			return -100000.0 if white_turn else 100000.0
		return 0.0
	if white_turn:
		var best := -INF
		for move in moves:
			var next := position.duplicate(true)
			var next_rights := rights.duplicate()
			var next_ep: Vector2i = _apply_move(next,move,next_rights,ep)
			best=max(best,_minimax(next,next_rights,next_ep,false,depth-1,alpha,beta))
			alpha=max(alpha,best)
			if beta<=alpha: break
		return best
	var best := INF
	for move in moves:
		var next := position.duplicate(true)
		var next_rights := rights.duplicate()
		var next_ep: Vector2i = _apply_move(next,move,next_rights,ep)
		best=min(best,_minimax(next,next_rights,next_ep,true,depth-1,alpha,beta))
		beta=min(beta,best)
		if beta<=alpha: break
	return best

func _evaluate(position: Dictionary) -> float:
	var score := 0.0
	for square in position:
		var piece: Dictionary = position[square]
		var value: float = VALUES.get(piece.kind,0)
		var center := 3.5-(abs(float(square.x)-3.5)+abs(float(square.y)-3.5))*0.12
		value += center*4.0 if piece.kind!="king" else 0.0
		score += value if piece.white else -value
	return score
