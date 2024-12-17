extends Control



# game parameters
enum State {
	START, LOADING, LOADED, NOT_LOADED, GUESSED, NOT_GUESSED, LLM_ERROR
}
var word:String 
const URL := "http://localhost:3000/v1/chat/completions"
const SAVE_PATH := "user://save_progress.json"
const HEX_GREEN :="#11FF11"
const HEX_RED :="#FF2211"
const GENERATE_CONTENT = "Generate a random 5-letter noun. Output the answer only in JSON format as follows: { “result”: the generated word}"
const START_CONTENT = "Start new game"

# model request parameters
var headers = ["Content-Type: application/json", "Cache-Control: no-cache'"]
var request = {
	"messages":[
  ],
 "model": "unsloth/Llama-3.2-1B-Instruct-GGUF",
 "mmax_tokens": 2048,
 "stop": null,
 "stream":false,
 "temperature": 0.8,
 "do_sample":true,
 "top_p": 0.5,
 "frequency_penalty": 1
}

func change_state(state:State, data={}):
	"""change parameters of scene nodes.
	Args:
		state: Enum State
		data: object for additional data (used for recieve llm hiden word)
	Returns:
		None
	"""
	%EnterButton.disabled = true
	match state:
		State.START:
			#get history of messages, or create new if not exists
			if FileAccess.file_exists(SAVE_PATH):
				var file =  FileAccess.open(SAVE_PATH, FileAccess.READ)
				var content = file.get_as_text()
				file.close()
				var result_json = JSON.parse_string(content)
				request["messages"]=result_json
			else:
				request["messages"]= [
					{
				  "role": "user",
				  "content": START_CONTENT
					}
				]
			_on_next_word_pressed()
		State.LOADING:
			%LlmWord.text = "Loading..."
			%LineEdit.text="";
			%ResultLabel.text = ""
		State.LOADED:
			save_messages_to_json(request["messages"], SAVE_PATH)
			%LlmWord.text = data["llmWord"]
			%EnterButton.disabled = true
			%LineEdit.text="";
			%LineEdit.editable=true;
		State.NOT_LOADED:
			save_messages_to_json(request["messages"], SAVE_PATH)
			%LlmWord.text = 'Please press button "Next word"'
		State.GUESSED:
			%LlmWord.text = data["llmWord"]
			%EnterButton.disabled = true
			%ResultLabel.set("theme_override_colors/font_color",HEX_GREEN);
			%ResultLabel.text = "Guessed!"
			%LineEdit.editable=false;
		State.NOT_GUESSED:
			%LlmWord.text = data["llmWord"]
			%EnterButton.disabled = true
			%ResultLabel.set("theme_override_colors/font_color",HEX_RED);
			%ResultLabel.text = "Wrong answer!"
			%LineEdit.editable=false;
		State.LLM_ERROR:
			%LlmWord.text = "Error: LLM not response"
		_:
			print("Default case: No specific match found.")

func save_messages_to_json(data, file_path) -> bool:
	"""Saves the given data to a JSON file.
	Args:
		data: The data to save (a dictionary).
		file_path: The path to the JSON file (relative to the project directory).
	Returns:
		True if the save was successful, False otherwise.
	"""
	# IMPORTANT: Check if the path is valid.
	if !file_path.begins_with("user://"):
		print("Invalid file path (must start with 'user://')")
		return false
	var file =  FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		var json_data =JSON.stringify(data)
		file.store_string(json_data)
		file.close()
		return true
	else:
		print("Could not open file for writing:", file_path)
		return false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	change_state(State.START) 


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_new_game_pressed() -> void:
	request["messages"]= [
		{
			"role": "user",
			"content": START_CONTENT
		}
	]
	save_messages_to_json(request["messages"], SAVE_PATH)
	_on_next_word_pressed()


func _on_next_word_pressed() -> void:
	change_state(State.LOADING)
	request["messages"].append({
	  "role": "user",
	  "content": GENERATE_CONTENT
	})
	$HTTPRequest.request(URL, headers, HTTPClient.METHOD_POST, JSON.stringify(request))



func _on_http_request_request_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	
	if response_code == 200:
		# get message from llm
		var json = JSON.parse_string(body.get_string_from_utf8())
		var message = json["choices"][0]["message"]
		var content = JSON.parse_string(message["content"])
		# check what llm response with result object
		if  (content != null) and ("result" in content):
			word = content["result"].to_lower() 
			if word.length() == 5:
				request["messages"].append(message)
				var masked_word = ""
				for i in range(word.length()):
					if i % 2 != 0:  # Check if index is odd
						masked_word += "*" # Change to desired character
					else:
						masked_word += word[i] # keep original character
				change_state(State.LOADED,{"llmWord":masked_word})
			else:
				change_state(State.NOT_LOADED)
		else:
			change_state(State.NOT_LOADED)
	else:
			change_state(State.LLM_ERROR)


func _on_enter_button_pressed() -> void:
	if word == %LineEdit.text.to_lower():
		change_state(State.GUESSED,{"llmWord":word})
	else:
		change_state(State.NOT_GUESSED,{"llmWord":word})

# Called when user are typing symbol in LineEdit
func _on_line_edit_text_changed(new_text: String) -> void:
	if new_text.length() == 5:
		%EnterButton.disabled = false
	else:
		%EnterButton.disabled = true 

# Called when user press Enter in LineEdit
func _on_line_edit_text_submitted(new_text: String) -> void:
		if new_text.length() == 5:
			_on_enter_button_pressed()
