extends CanvasLayer

signal restart_requested
signal resign_requested

const GOLD := Color(0.93, 0.68, 0.28)
const PALE_GOLD := Color(1.0, 0.84, 0.55)
const WHITE := Color(0.94, 0.94, 0.92)
const MUTED := Color(0.66, 0.69, 0.75)
const PANEL := Color(0.018, 0.022, 0.032, 0.94)

var turn_label: Label
var status_label: Label
var popup_overlay: ColorRect
var popup_title: Label
var popup_body: Label
var history_text := "Ainda não existem jogadas registadas nesta partida."

func _ready() -> void:
	layer = 20
	_build_interface()

func _build_interface() -> void:
	var root := Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(root)

	_add_player_card(root, false, "Jogador 1", "ELO 1420", "15:00", "♔")
	_add_player_card(root, true, "IA - Mestre", "ELO 1600", "15:00", "♞")
	_add_turn_banner(root)

	_add_action_button(root, false, 0, "☰\nMenu", Callable(self, "_open_menu"))
	_add_action_button(root, false, 1, "⟳\nReiniciar", Callable(self, "_request_restart"))
	_add_action_button(root, false, 2, "⚑\nDesistir", Callable(self, "_request_resign"))
	_add_action_button(root, true, 0, "♧\nDicas", Callable(self, "_open_tips"))
	_add_action_button(root, true, 1, "▤\nHistórico", Callable(self, "_open_history"))
	_add_action_button(root, true, 2, "⚙\nDefinições", Callable(self, "_open_settings"))

	status_label = Label.new()
	status_label.text = "CHESSVERSE 3D  •  XADREZ CLÁSSICO"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.add_theme_color_override("font_color", Color(0.86, 0.72, 0.48, 0.9))
	status_label.add_theme_font_size_override("font_size", 13)
	status_label.anchor_left = 0.5
	status_label.anchor_right = 0.5
	status_label.anchor_top = 1.0
	status_label.anchor_bottom = 1.0
	status_label.offset_left = -220
	status_label.offset_right = 220
	status_label.offset_top = -34
	status_label.offset_bottom = -10
	root.add_child(status_label)

	_build_popup(root)

func _add_player_card(root: Control, right_side: bool, player_name: String, rating: String, timer: String, emblem: String) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.custom_minimum_size = Vector2(300, 88)
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.anchor_left = 1.0 if right_side else 0.0
	panel.anchor_right = 1.0 if right_side else 0.0
	panel.offset_top = 18
	if right_side:
		panel.offset_left = -338
		panel.offset_right = -18
	else:
		panel.offset_left = 18
		panel.offset_right = 338
	panel.offset_bottom = 106
	root.add_child(panel)

	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)

	var avatar_frame := PanelContainer.new()
	avatar_frame.custom_minimum_size = Vector2(66, 66)
	var avatar_style := StyleBoxFlat.new()
	avatar_style.bg_color = Color(0.025, 0.03, 0.045, 1.0)
	avatar_style.border_color = Color(0.72, 0.48, 0.19) if not right_side else Color(0.36, 0.58, 0.82)
	avatar_style.set_border_width_all(2)
	avatar_style.set_corner_radius_all(40)
	avatar_frame.add_theme_stylebox_override("panel", avatar_style)
	row.add_child(avatar_frame)

	var avatar := Label.new()
	avatar.text = emblem
	avatar.custom_minimum_size = Vector2(62, 62)
	avatar.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	avatar.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	avatar.add_theme_color_override("font_color", GOLD if not right_side else Color(0.65, 0.79, 0.96))
	avatar.add_theme_font_size_override("font_size", 46)
	avatar_frame.add_child(avatar)

	var info := VBoxContainer.new()
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.add_theme_constant_override("separation", 3)
	row.add_child(info)

	var name_label := Label.new()
	name_label.text = player_name
	name_label.add_theme_color_override("font_color", WHITE)
	name_label.add_theme_font_size_override("font_size", 20)
	info.add_child(name_label)

	var rating_label := Label.new()
	rating_label.text = rating
	rating_label.add_theme_color_override("font_color", PALE_GOLD)
	rating_label.add_theme_font_size_override("font_size", 15)
	info.add_child(rating_label)

	var time_label := Label.new()
	time_label.text = "◷  " + timer
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	time_label.custom_minimum_size = Vector2(78, 40)
	time_label.add_theme_color_override("font_color", WHITE)
	time_label.add_theme_font_size_override("font_size", 18)
	row.add_child(time_label)

func _add_turn_banner(root: Control) -> void:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _banner_style())
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.0
	panel.anchor_bottom = 0.0
	panel.offset_left = -188
	panel.offset_right = 188
	panel.offset_top = 22
	panel.offset_bottom = 92
	root.add_child(panel)

	turn_label = Label.new()
	turn_label.text = "♙   Vez das Brancas"
	turn_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	turn_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	turn_label.add_theme_color_override("font_color", PALE_GOLD)
	turn_label.add_theme_font_size_override("font_size", 24)
	panel.add_child(turn_label)

func _add_action_button(root: Control, right_side: bool, index: int, title: String, callback: Callable) -> void:
	var button := Button.new()
	button.text = title
	button.custom_minimum_size = Vector2(104, 66)
	button.focus_mode = Control.FOCUS_NONE
	button.add_theme_stylebox_override("normal", _button_style(false))
	button.add_theme_stylebox_override("hover", _button_style(true))
	button.add_theme_stylebox_override("pressed", _button_pressed_style())
	button.add_theme_color_override("font_color", PALE_GOLD)
	button.add_theme_color_override("font_hover_color", WHITE)
	button.add_theme_font_size_override("font_size", 16)
	button.anchor_left = 1.0 if right_side else 0.0
	button.anchor_right = 1.0 if right_side else 0.0
	button.anchor_top = 0.5
	button.anchor_bottom = 0.5
	var top := -110.0 + float(index) * 78.0
	button.offset_top = top
	button.offset_bottom = top + 66.0
	if right_side:
		button.offset_left = -122
		button.offset_right = -18
	else:
		button.offset_left = 18
		button.offset_right = 122
	root.add_child(button)
	button.pressed.connect(callback)

func _build_popup(root: Control) -> void:
	popup_overlay = ColorRect.new()
	popup_overlay.color = Color(0.0, 0.0, 0.0, 0.72)
	popup_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	popup_overlay.visible = false
	popup_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(popup_overlay)

	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _panel_style())
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -230
	panel.offset_right = 230
	panel.offset_top = -148
	panel.offset_bottom = 148
	popup_overlay.add_child(panel)

	var content := VBoxContainer.new()
	content.add_theme_constant_override("separation", 16)
	panel.add_child(content)

	popup_title = Label.new()
	popup_title.text = "ChessVerse 3D"
	popup_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_title.add_theme_color_override("font_color", PALE_GOLD)
	popup_title.add_theme_font_size_override("font_size", 25)
	content.add_child(popup_title)

	popup_body = Label.new()
	popup_body.text = ""
	popup_body.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	popup_body.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	popup_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	popup_body.custom_minimum_size = Vector2(390, 90)
	popup_body.add_theme_color_override("font_color", WHITE)
	popup_body.add_theme_font_size_override("font_size", 17)
	content.add_child(popup_body)

	var close_button := Button.new()
	close_button.text = "Continuar"
	close_button.custom_minimum_size = Vector2(150, 48)
	close_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	close_button.add_theme_stylebox_override("normal", _button_style(false))
	close_button.add_theme_stylebox_override("hover", _button_style(true))
	close_button.add_theme_color_override("font_color", PALE_GOLD)
	close_button.add_theme_font_size_override("font_size", 17)
	close_button.pressed.connect(func(): popup_overlay.visible = false)
	content.add_child(close_button)

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = PANEL
	style.border_color = Color(0.7, 0.45, 0.16, 0.95)
	style.set_border_width_all(2)
	style.set_corner_radius_all(17)
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.65)
	style.shadow_size = 10
	return style

func _banner_style() -> StyleBoxFlat:
	var style := _panel_style()
	style.bg_color = Color(0.008, 0.01, 0.016, 0.96)
	style.border_color = Color(0.86, 0.59, 0.2)
	style.set_corner_radius_all(24)
	style.content_margin_left = 18
	style.content_margin_right = 18
	return style

func _button_style(hovered: bool) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.012, 0.016, 0.026, 0.94) if not hovered else Color(0.11, 0.075, 0.035, 0.98)
	style.border_color = Color(0.72, 0.46, 0.16) if not hovered else Color(1.0, 0.75, 0.34)
	style.set_border_width_all(2)
	style.set_corner_radius_all(15)
	style.content_margin_left = 7
	style.content_margin_right = 7
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	return style

func _button_pressed_style() -> StyleBoxFlat:
	var style := _button_style(true)
	style.bg_color = Color(0.2, 0.12, 0.035, 1.0)
	return style

func _open_popup(title: String, body: String) -> void:
	popup_title.text = title
	popup_body.text = body
	popup_overlay.visible = true

func _open_menu() -> void:
	_open_popup("Menu da partida", "ChessVerse 3D\nModo clássico • Tabuleiro 3D\nEscolhe Continuar para regressar ao jogo.")

func _open_tips() -> void:
	_open_popup("Dicas de xadrez", "Controla o centro do tabuleiro, desenvolve os cavalos e bispos e protege o rei com o roque. As regras completas e as dicas legais serão ligadas ao motor de xadrez na próxima etapa.")

func _open_history() -> void:
	_open_popup("Histórico de jogadas", history_text)

func set_history(moves: Array[Dictionary]) -> void:
	if moves.is_empty():
		history_text = "Ainda não existem jogadas registadas nesta partida."
		return
	var lines: Array[String] = []
	for i in range(0, moves.size(), 2):
		var white_move: Dictionary = moves[i]
		var line := str(int(i / 2) + 1) + ". " + _square_name(white_move.from) + "–" + _square_name(white_move.to)
		if i + 1 < moves.size():
			var black_move: Dictionary = moves[i + 1]
			line += "    " + _square_name(black_move.from) + "–" + _square_name(black_move.to)
		lines.append(line)
	history_text = "\n".join(lines)

func _square_name(square: Vector2i) -> String:
	var files := "abcdefgh"
	return files.substr(square.x, 1) + str(8 - square.y)

func _open_settings() -> void:
	_open_popup("Definições", "Apresentação: Luxo metálico\nIdioma: Português\nModo de ecrã: Horizontal\nAs opções de som, câmara e dificuldade serão adicionadas.")

func _request_restart() -> void:
	restart_requested.emit()

func _request_resign() -> void:
	resign_requested.emit()

func set_turn(white_to_move: bool) -> void:
	if is_instance_valid(turn_label):
		turn_label.text = "♙   Vez das Brancas" if white_to_move else "♟   Vez das Pretas"

func set_status(message: String) -> void:
	if is_instance_valid(status_label):
		status_label.text = message.to_upper()

func show_result(title: String, body: String) -> void:
	_open_popup(title, body)
