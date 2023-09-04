extends CanvasLayer


func fload():
	var file = FileAccess.open("res://game-config.json", FileAccess.READ)
	var content = file.get_as_text()
	file.close()
	var result_json = JSON.parse_string(content)
	return result_json

# Called when the node enters the scene tree for the first time.
func _ready():
	#pass # Replace with function body.
	var settings =	fload()
	var songs = settings.songs
	var item=0;
	for song in songs:
		$StartScreen.find_child('SelectSong').add_item(song.title,item)
		item+=1


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	pass
