extends Control
@onready var sussy_slots = 1
@onready var num_col = 10
@onready var num_row = 8
@onready var inv_slot = preload("res://Scenes/temp_slot.tscn")
@onready var slot_height 
@onready var slot_width
@onready var current_slot
@onready var held_item = null
@onready var hovered_item = null
@onready var slots = {}
@onready var placed_objects := { Vector2(1, 2): 0, Vector2(1, 3): 1, Vector2(4, 2): 3, Vector2(6, 3): 1, Vector2(4, 6): 0 }
@onready var inventoryGrid = $inventoryPanel/inventoryGrid
@onready var groundItems = $infoPanel/infoVbox/groundItemsScroll/groundItemsGrid
@onready var scroll = $infoPanel/infoVbox/groundItemsScroll
@onready var map = $infoPanel/infoVbox/mapPanel
@onready var description = $infoPanel/infoVbox/descriptionPanel
@onready var objects = $inventoryPanel/Objects
@onready var infoPanel = $infoPanel
@onready var uiAnim = $uiAnim
@onready var inv_scale
@export var infoOpen := false
var inventory_bounding_rect
var inventory_bounding_rect2
# Called when the node enters the scene tree for the first time.
func _ready():
	inv_scale = 80./50.
	inventoryGrid.columns = num_col
	createInventory()
	loadInventory()
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if held_item == null:
		if hovered_item and Input.is_action_just_pressed("ui_right_input"):
			openItemDescription()
		if Input.is_action_just_pressed("ui_input"):
			if hovered_item:
				held_item = hovered_item
				if held_item.item_location != null:
					placed_objects.erase(held_item.item_location)
					print("item found in inventory at", hovered_item.item_location)
					for coord in held_item.item_coords:
						var slot_to_update = held_item.item_location + coord
						print(slot_to_update)
						slots["%s:%s"%[slot_to_update.x, slot_to_update.y]].removeItem()
				else:
					print("item found on ground")
				held_item.pickUp()
				#print(held_item.item_location)
		for child in groundItems.get_children():
			child.mouse_filter = 1
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_VISIBLE)
	else:
		var slot_to_check = getContainerLoc(get_global_mouse_position())
		if inventory_bounding_rect.has_point(slot_to_check):
			slotEntered(slots["%s:%s"%[slot_to_check.x,slot_to_check.y]])
			
			if Input.is_action_just_pressed("ui_input"):
				if checkSlotsAvailable(current_slot):
					putItemDown(current_slot)
					
		else:
			current_slot = null
			clearItemSlots()
			if Input.is_action_just_pressed("ui_input"):
				held_item.putDown()
				held_item = null
				
			#current_slot = 
		for child in groundItems.get_children():
			child.mouse_filter = 2
		DisplayServer.mouse_set_mode(DisplayServer.MOUSE_MODE_HIDDEN)
	#print(placed_objects)
	
func getContainerLoc(mouse_pos):
	var container_pos = mouse_pos - inventoryGrid.global_position - Vector2(slot_width, slot_height)/2*held_item.item_size
	return Vector2(int(container_pos.x/slot_width), int(container_pos.y/slot_height))

func slotEntered(the_slot):
	clearItemSlots()
	current_slot = the_slot
	if held_item:
		if checkSlotsAvailable(current_slot): #item fits
			updateItemSlots(current_slot, 1)
		else:
			updateItemSlots(current_slot, 2)
	pass
	
func slotExited(the_slot):
	current_slot=null
	pass

func itemEntered(the_item):
	if held_item:
		return
	hovered_item = the_item
	pass
func itemExited(the_item):
	if held_item:
		return
	hovered_item = null
	pass
func _on_button_pressed():
	var id = randi_range(0,3)
	addItemToGround(id)

func checkSlotsAvailable(the_slot):
	var main_slot_location = the_slot.location
	for coord in held_item.item_coords:
		var slot_to_check = main_slot_location + coord
		if inventory_bounding_rect.has_point(slot_to_check):
			if slots["%s:%s"%[slot_to_check.x, slot_to_check.y]].has_item or slots["%s:%s"%[slot_to_check.x, slot_to_check.y]].slot_type < 0:
				return false
		else:
			return false
	return true

func updateItemSlots(the_slot, state):
	var main_slot_location = the_slot.location
	for coord in held_item.item_coords:
		var slot_to_check = main_slot_location + coord
		if inventory_bounding_rect.has_point(slot_to_check):
			slots["%s:%s"%[slot_to_check.x, slot_to_check.y]].setState(state)

func clearItemSlots():
	for s in slots:
		slots[s].setState(0)
		
func putItemDown(the_slot):
	var main_slot_location = the_slot.location
	placed_objects[main_slot_location] = held_item.item_id
	held_item.item_location = main_slot_location
	for coord in held_item.item_coords:
		var slot_to_check = main_slot_location + coord
		slots["%s:%s"%[slot_to_check.x, slot_to_check.y]].addItem(held_item.item_id)
	
	var snap_coords = main_slot_location * slot_height
	print(snap_coords)
	held_item.putDown(inventoryGrid.global_position+snap_coords)
	held_item = null

func addItemToGround(id):
	var new_item_button = load("res://Scenes/item_button.tscn").instantiate()
	groundItems.add_child(new_item_button)
	new_item_button.loadItemButton(id)
	new_item_button.item_pressed.connect(groundItemPressed)
	hovered_item = null
	scroll.queue_sort()
	
func groundItemPressed(id):
	var new_item = load('res://Scenes/item.tscn').instantiate()
	print("ADDING A NEW ITTEM TO INV")
	objects.add_child(new_item)
	new_item.loadItem(id, Vector2(inv_scale, inv_scale))
	#new_item.pivot_offset = new_item.getSize()/2
	new_item.cursor_entered_item.connect(itemEntered)
	new_item.cursor_exited_item.connect(itemExited)
	new_item.return_to_ground.connect(addItemToGround)
	held_item = new_item
	new_item.pickUp()
	print(new_item.item_size)

func _on_clear_pressed():
	for obj in objects.get_children():
		obj.queue_free()
	held_item = null
	hovered_item = null
	for sl in slots:
		slots[sl].removeItem()
	pass # Replace with function body.

func _on_tab_bar_tab_selected(tab):
	match tab:
		0: scroll.visible = true; map.visible = false; description.visible = false; if infoOpen: uiAnim.play("close_info") 
		1: scroll.visible = false; map.visible = false; description.visible = true; if not infoOpen: uiAnim.play("open_info")
		2: scroll.visible = false; map.visible = true; description.visible = false; if infoOpen: uiAnim.play("close_info")
	pass # Replace with function body.

func openItemDescription():
	$infoPanel/infoVbox/descriptionPanel/descriptionMargin/descriptionText.clear()
	$infoPanel/infoVbox/descriptionPanel/descriptionMargin/descriptionText.parse_bbcode(ItemLoader.item_data[str(hovered_item.item_id)]['item_description'])
	_on_tab_bar_tab_selected(1)

func loadInventory():
	for object in placed_objects:
		var the_slot = slots["%s:%s" % [object.x, object.y]]
		var new_item = load('res://Scenes/item.tscn').instantiate()
		objects.add_child(new_item)
		new_item.loadItem(placed_objects[object], Vector2(inv_scale, inv_scale))
		#new_item.pivot_offset = new_item.getSize()/2
		new_item.cursor_entered_item.connect(itemEntered)
		new_item.cursor_exited_item.connect(itemExited)
		new_item.return_to_ground.connect(addItemToGround)
		held_item = new_item
		new_item.pickUp()
		putItemDown(the_slot)
		print("ADDING ITEM %s TO SLOT %s WITH LOCATION %s" % [new_item.item_id, the_slot, the_slot.global_position])

func createInventory():
	for row in range(num_row):
		for col in range(num_col):
			var new_slot = inv_slot.instantiate()
			inventoryGrid.add_child(new_slot)
			new_slot.slotEntered.connect(slotEntered)
			new_slot.location = Vector2(col, row)
			slots['%s:%s' %[col, row]] = new_slot
			if row < sussy_slots or col < sussy_slots or num_row-row <= sussy_slots or num_col-col <= sussy_slots:
				new_slot.setType(-1)
			elif (row == 1 and col == 1) or (row == 1 and num_col-col == 2) or (num_row-row == 2 and col == 1) or (num_row-row == 2 and num_col-col == 2):
				new_slot.setType(-1)
			else:
				new_slot.setType(0)
	slot_height = inventoryGrid.size.y/num_row
	slot_width = inventoryGrid.size.x/num_col
	inventory_bounding_rect = Rect2(Vector2(1, 1), Vector2(num_col-2, num_row-2))
