extends Node

@export var note = "A"
var tone_x = 330

var tones = {
	"C": {freq=523.25,stave_pos_y=125},
	"D": {freq=587.33,stave_pos_y=110},
	"E": {freq=659.25,stave_pos_y=95},
	"F": {freq=698.46,stave_pos_y=80},
	"G": {freq=783.99,stave_pos_y=65},
	"A": {freq=880.00,stave_pos_y=50},
	"B": {freq=987.77,stave_pos_y=35}
}



var postions = [35,50,65,80,95,110,125]

# Called when the node enters the scene tree for the first time.
func _ready():
	print (tones[note].stave_pos_y)
	self.global_position=Vector2(tone_x,tones[note].stave_pos_y)
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
	#$Note.set_position(Vector2(300,200))
	
