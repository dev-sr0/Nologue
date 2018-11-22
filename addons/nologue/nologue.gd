tool
extends Control

# SOLOGUE - a small dialog system, by some nerd called ArcOfDream.
# Version 0.5
# Make sure the font is saved as a resource file when you set it up for loading.
#
# This code is distributed under the MIT license, because it's cool.
# 
# Dialogue format:
# The dialogue is passed as an array on start, then the element can be passed either
# as an array - [name_tag, font_size, dialogue_stuff] - or as a string.
# You can skip out on the font size, btw.
#
# Modifier flags:
# /dxxx - Set delay. For example if the flag is set as /d200, the delay will be 2 seconds. Must be exactly that length!
# /s - Applies a shake effect.
# /w - Now do a wave.
# /b - Text so excited it bounces.
# /t - Nervous text that twitches around.
# /r - Resets modifiers.
# Note: Setting a new modifier on a different position will override the old flags,
# So make sure that there's a combo of them on the new position.
#
# A bucket list of things to do:
# TODO: Apply portrait.
# TODO: Complete string cutting for splitting the dialogue if it's too long.
# FIXME: Proper spacing for differing font sizes
# FIXME: Make the name tag not get affected by the font size.

export(Array) var dialogue = []
export(Font) var font = get_font("") # The font to be used for drawing text
export(Color) var color = Color(1,1,1) # Color for the text.
export(bool) var skippable = true # Allows you to disable text skipping

const DEFAULT_FONT_SIZE = 16
const DEFAULT_DELAY     = 0.05
const TEXT_DELAY        = 1
const TEXT_SHAKE        = 2
const TEXT_WAVE         = 4
const TEXT_BOUNCE       = 8
const TEXT_TWITCH       = 16
const TEXT_RESET        = 0

var font_size      = DEFAULT_FONT_SIZE
var portrait       # Texture for the portrait.
var current_string = "" # This should hold the string to iterate over.
var tag            = "" # This string is intended for the name tag.
var mods           = [] # Array for triggering text effects. Should be set roughly the same size as the length of the string.
var active_mods    = 0 # used for bitwise operations.
var progress       = -1 # value to denote progress of the dialog array.
var char_pos       = 0 # The amount of characters to process for the _draw function. Gives a typewriter effect.
var text_offset    = Vector2(0,12) # Spacing for the text draw.
var char_amt       = 24 # Amount of characters allowed in a line.
var line_amt       = 0 # Amount of lines allowed in the box.
var cutoff         = 48 # Maximum amount of allowed characters before breaking the text.
var delay          = DEFAULT_DELAY # Amount of time before adding to char_pos.
var time           = 0.0 # General time counter.
var counter        = 0.0 # Delay counter.
var showing        = true # Flag for toggling text visibility.
var continuous     = true # Updates continuously. Consider turning this on for the effects.
var running        = true # Flag for toggling the text processing. Think of it as a pause toggle.
var cut            = false # The flag to tell if to cut the line.
var line_done      = true # The final status of the string iteration.
var finished       = true # A flag set when the dialog is finished in general.
var has_tag        = false # For adding space for the tag above

signal dialog_start 
signal dialog_continue
signal dialog_end


func _ready():
	# TODO: Figure out a better way to manage character spacing.
	char_amt = int(floor((get_rect().size.x - text_offset.x) / 8))
	line_amt = int(floor((get_rect().size.y - text_offset.y) / 9))
	
	print(char_amt, " ", line_amt)
	print(dialogue)
	set_physics_process(true)
	
	# Temporary junk
#	set_process_unhandled_key_input(true) # temporary
#	run_dialog(temp_diag)


func sliceAndSave(src, destArr, nChars):
	# Helper function for word wrapping
	# Written by NavyFish
	var sliceLength = nChars
	destArr.append(src.substr(0, sliceLength))
	return src.substr(sliceLength, src.length() - sliceLength)


func word_wrap(src, charMax):
	# Makes sure words don't get chopped in half
	# Also written by NavyFish
	print("source string length: %s" % src.length())

	var lines = []
	var done = false
	var limit = charMax

	if src.length() > char_amt:
		while(not done):
			# Don't count effect characters
			var delayCount = src.substr(0, char_amt).split("/d").size() - 1
			var effectCount = (src.substr(0, char_amt).split("/").size() - 1) - delayCount
			limit += 2*effectCount
			limit += 5*delayCount
			
			# Line slicing
			if (src[limit-1] == " ") || (src[limit] == " "):
				src = sliceAndSave(src, lines, limit)
			else:
				var idx = src.rfind(" ", limit - 1)
				if (idx == -1):
					src = sliceAndSave(src, lines, limit)
				else:
					src = sliceAndSave(src, lines, idx+1)
	
			# Check if we can stop
			if (src.length() <= limit):
				done = true
				src = sliceAndSave(src, lines, src.length())
	else:
		lines.append(src)

	return lines


func _draw():
	# This will handle the text drawn on the screen.
	# The idea is that it iterates the current string until it hits the current position, 
	# which updates with the given delay.
	if showing:
		var place = 0
		var line = 0
		var space = 0
		var character
		var origin = 0
		var pos = Vector2(12, 12)
		var height = font.get_string_size("ABC").y

		active_mods = 0 # Let's reset this so the whole string won't go nuts.
		
		if has_tag:
			draw_string(font, text_offset,"[" + tag + "]:", color)

		while place < char_pos:
			# Here we have a loop which will determine position the characters will be drawn
			# up to the last available character, which is char_pos.

			character = current_string.substr(place, 1) # Gets character from current place

			# Make newlines work properly
			if character == "\n":
				line += 1
				space = 0
				place += 1
				continue

			# Skip spaces at the start of lines
			if space == 0 && character == " ":
				place += 1
				continue

			origin = char_amt * floor(place/char_amt) # Calculates starting character point of a line
			pos.x = text_offset.x + space # Apply X position
			pos.y = text_offset.y + (height * (line + int(has_tag))) # Apply Y position
			space += font.get_string_size(character).x # Add more space for the next character

			if typeof(mods[place]) == TYPE_ARRAY:
				active_mods = mods[place][0]
			
			if active_mods == 0 or active_mods == TEXT_DELAY:
				# De facto action for no modifiers. We don't need the checks below, so we can proceed
				# with the next loop.
				draw_string(font, pos, character, color)
				place += 1
				continue
			
			if active_mods & TEXT_SHAKE:
				var num = 1
				pos += Vector2(rand_range(-num, num), rand_range(-num, num))
			if active_mods & TEXT_WAVE:
				pos.y += 2 * sin((time*6) + (pos.x*0.02))
				pos.x += 4 * sin((time*3) + (pos.x*0.01))
			if active_mods & TEXT_BOUNCE:
				pos.y += (abs(4 * sin((time*5) + (place*0.5))) - 4) * -1
			if active_mods & TEXT_TWITCH:
				var num = 0.51
				pos += Vector2(rand_range(-num, num), rand_range(-num, num))

			draw_string(font, pos, character, color)
			place += 1


func _physics_process(delta):
	# The process function here should be handling time before adding to the position var.
	# TODO: Implement difference between text being cut and text being done.
	
	if running and !finished and !line_done:
		if counter >= delay:
			if char_pos < current_string.length():
				# Modifier specific for delay will be put here.
				if typeof(mods[char_pos]) == TYPE_ARRAY or typeof(mods[char_pos]) == TYPE_STRING_ARRAY:
					if mods[char_pos][0] & TEXT_DELAY:
						delay = mods[char_pos][1]
				
				char_pos += 1
			else:
				line_done = true
			# 
			if !continuous:
				update()
			counter = 0
		counter += delta
	
	time += delta
	
	if continuous:
		update()


func run():
	# The function to call if you want to start up a dialogue on this system.
	if finished:
		finished = false
		time = 0.0
		emit_signal("dialog_start")
		next_line()


func next_line():
	# The function that  calls for the next item in the array, and processes the text accordingly.
	if line_done and !finished:
		progress += 1
		
		if progress < dialogue.size():
			var item = dialogue[progress] # get new variable from array
			char_pos = 0 # reset character position
			mods.clear()
			
			if typeof(item) == TYPE_ARRAY or typeof(item) == TYPE_STRING_ARRAY: 
				has_tag = true
				tag = item[0] # name
				if typeof(item[1]) == TYPE_INT: # optional font size here
					font_size = item[1]
					font.set_size(font_size)
					current_string = _process_text(item[2])
				else: # default size if none
					font_size = DEFAULT_FONT_SIZE
					font.set_size(DEFAULT_FONT_SIZE)
					current_string = _process_text(item[1])
			else:
				# we will assume that the item is a string if it's not an array
				has_tag = false
				font_size = DEFAULT_FONT_SIZE
				delay = DEFAULT_DELAY
				current_string = _process_text(item)
				# Below is a little extra that uses a ternary operator. I think it should work!
#				current_string = process_text(item) if typeof(item) == TYPE_STRING else process_text(str(item))
			
			line_done = false
			emit_signal("dialog_continue")
		
		elif progress == dialogue.size():
			char_pos = 0
			current_string = ""
			tag = ""
			dialogue.clear()
			mods.clear()
			has_tag = false
			finished = true
			progress = -1
			update()
			emit_signal("dialog_end")
			print("Dialogue finished!")
	elif !finished && skippable:
		char_pos = current_string.length()


func _process_text(string):
	# Takes a string and removes modifier flags present. Returns the processed string.
	# Modifiers are placed inside an array which will tell on which place of the string to trigger the modifiers.
	
	var i = 0
	var mod_count = 0
	var new_string = string

	# Use newline characters for word wrapping
	var lines = word_wrap(new_string, char_amt)
	new_string = ""
	for line in lines:
		new_string += line
		new_string += "\n"

	mods.resize(new_string.length()) # Make array the size of the string length. Doesn't matter if it ends up being longer.
	
	while i != -1:
		mod_count = 0
		i = new_string.find("/", i) # Look for the mod flag. Returns -1 if it's not found, thus ending the loop.
		
		if i != -1:
			# First let's check if the mods array has something set for this position. 
			if typeof(mods[i]) != TYPE_ARRAY:
				mods[i] = [0, 0] # And set something for that if it's empty.
			# Now we will check for what kind of modifier is it, and add values if there's a match.
			if new_string.substr(i + 1, 1) == "d":
				mods[i][0] += TEXT_DELAY
				mods[i][1] = float(new_string.substr(i + 2, 3)) / 100
				mod_count += 4
			elif new_string.substr(i + 1, 1) == "s":
				mods[i][0] += TEXT_SHAKE
				mod_count += 1
			elif new_string.substr(i + 1, 1) == "w":
				mods[i][0] += TEXT_WAVE
				mod_count += 1
			elif new_string.substr(i + 1, 1) == "b":
				mods[i][0] += TEXT_BOUNCE
				mod_count += 1
			elif new_string.substr(i + 1, 1) == "t":
				mods[i][0] += TEXT_TWITCH
				mod_count += 1
			elif new_string.substr(i + 1, 1) == "r":
				mods[i][0] = TEXT_RESET # This is specific, in that it removes any mods afterwards.
				mod_count += 1
		new_string.erase(i, 1+mod_count) # Remove the mod part.

	return new_string # Finally, our squeaky clean string is given back to us.


func set_visibility(toggle):
	if typeof(toggle) == TYPE_BOOL:
		showing = toggle
		update()
