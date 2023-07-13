extends TextureRect
class_name slot

@onready var has_item = false
@onready var location = null
@onready var is_parent = false
@onready var parent_location = null
@onready var item_id = null
@onready var texture_empty = preload("res://Assets/temp_slot1.png")
@onready var texture_full = preload("res://Assets/temp_slot2.png")
signal slotEntered(the_slot)
# Called when the node enters the scene tree for the first time.
func _ready():
	texture = texture_empty
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass

func _on_mouse_entered():
	#setState(1)
	emit_signal("slotEntered", self)

func _on_mouse_exited():
	#setState(0)
	pass # Replace with function body.

func setState(s):
	#print('settingstate')
	match s:
		0: $slotModulate.color = "#ffffff00"
		1: $slotModulate.color = "00ff0033"
		2: $slotModulate.color = "ff000033"
		
func addItem(id):
	has_item = true
	item_id = id
	texture = texture_full

func removeItem():
	has_item = false
	item_id = null
	texture = texture_empty