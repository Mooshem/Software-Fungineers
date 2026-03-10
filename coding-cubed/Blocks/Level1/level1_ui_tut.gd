"""
Developer: Donovan Thach
Tutorial UI for Level 1 — walks the player through controls and variable blocks.
"""

extends CanvasLayer

@onready var ui_coverage = $UICoverage
@onready var panel = $UICoverage/Panel
@onready var title_label = $UICoverage/Panel/Title
@onready var body_label = $UICoverage/Panel/Body
@onready var next_button = $UICoverage/Panel/NextButton
@onready var prev_button = $UICoverage/Panel/PrevButton
@onready var page_label = $UICoverage/Panel/PageLabel
@onready var close_button = $UICoverage/Panel/CloseButton

var current_page = 0
var pages = [
	{
		"title": "Controls",
		"body": "WASD — Move\nMouse — Look Around\nSpace — Jump\nShift — Sprint\n\nScroll / 1,2,3 — Switch Hotbar Slot\nRight Click — Place Block\nLeft Click (Hold) — Break Block\nI — Interact with Block\nEsc — Pause"
	},
	{
		"title": "Variable Blocks",
		"body": "Variable blocks store information.\n\nWhen you interact with one (I), you can set:\n  • var name — the name of the variable\n  • var value — the value it holds\n\nOther blocks like IF blocks can read\nthese values to make decisions."
	},
	{
		"title": "Your Goal",
		"body": "Place a Variable Block and interact with it.\n\nSet its name to:  var1\nSet its value to:  10\n\nThen connect a start block the\ngreen End Block using wires.\nSend a signal through\nby interacting with a start\nblock to complete the level!"
	}
]

func _ready() -> void:
	update_page()
	# Pause the game while tutorial is open.
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = Node.PROCESS_MODE_DISABLED

func update_page() -> void:
	title_label.text = pages[current_page]["title"]
	body_label.text = pages[current_page]["body"]
	page_label.text = "%d / %d" % [current_page + 1, pages.size()]
	prev_button.disabled = current_page == 0
	next_button.disabled = current_page == pages.size() - 1

func _on_next_button_pressed() -> void:
	if current_page < pages.size() - 1:
		current_page += 1
		update_page()

func _on_prev_button_pressed() -> void:
	if current_page > 0:
		current_page -= 1
		update_page()

func _on_close_button_pressed() -> void:
	ui_coverage.visible = false
	panel.visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.process_mode = Node.PROCESS_MODE_ALWAYS
	
