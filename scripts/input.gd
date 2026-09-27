extends GridContainer

var four_letter_code = ""
var user_name = ""

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	for character in Global.CHAR_INPUT:
		var button = Button.new()
		button.text = character
		button.pressed.connect(_on_button_pressed.bind(character))
		add_child(button)


func _on_button_pressed(character):
	if four_letter_code.length() < 4:
		four_letter_code += character
	update_entry_label()
		
func _delete_last_character():
	if four_letter_code.length() > 0:
		four_letter_code = four_letter_code.substr(0, four_letter_code.length() - 1)
	update_entry_label()

func submit_code():
	if four_letter_code.length() == 4:
		get_parent().get_parent().get_parent().send_code(four_letter_code)
		
	else:
		four_letter_code = ""
		get_parent().get_node("Entry").text = "[center]Invalid Length"

func update_entry_label():
	get_parent().get_node("Entry").text = "[center]Entered: " + four_letter_code
