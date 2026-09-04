extends RefCounted

# This script represents your game data. This abstracts your data layer.
# Your game will likely be more complex than that, including file storage and load.
# To keep things simple, this example only persist the data in memory.
#
# I reckon there are 3 different types of data you will have to handle:
#
# 1 - Internal dialogue data: This is the data your dialogue engine uses to keep track
# of visited options, internal variables and variations. For Clyde, this is data is 
# opaque, unique for a specific dialogue, and should never be manually edited.
#
# 2 - Game global data (i.e flags): This is the data that is used across your game,
# usually representing progression and being persisted on disk.
# For example, you might have a flag set when the player performs a specific action,
# let's say, the player broke a door. This flag can be used both in-game to setup your
# scene (e.g.next time the scene is loaded the door is shown as broken), and in dialogue,
# to include or exclude options / dialogue lines (e.g. a NPC acknowledges the broken
# door in the dialogue)
# 
# 3 - Game dynamic data: This is your game working data. It's not necessarily persisted
# in disk, but still relevant for the game / dialogue.
# E.g. time of the day, character HP, real world time.
#

var _persistence = {
	"dialogues": {},
	"global_variables": {},
}


func get_variable(var_name: String):
	# this is an example of a dynamic value which is not part of the game persistence
	# this is abstracted from the dialogue system
	if var_name == "hour_of_day":
		return Time.get_time_dict_from_system().hour

	return _persistence.global_variables.get(var_name)


func set_variable(var_name: String, value) -> void:
	_persistence.global_variables[var_name] = value


func get_dialogue_data(dialogue_name: String):
	return _persistence.dialogues.get(dialogue_name)


func store_dialogue_data(dialogue_name: String, data: Dictionary) -> void:
	_persistence.dialogues[dialogue_name] = data
