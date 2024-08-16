# GdMoL - Godot Mod Loader
#
# Copyright (c) 2024 Luana Neder
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
extends Node

var mods: Array = []
var modded: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():
	var path: String = "user://Mods"
	findmods(path)
	print("Modded: " + str(modded))
	print(mods)
	if modded:
		loadmods()

func findmods(path):
	var dir = DirAccess.open(path)
	if dir:
		dir.set_include_hidden(false)
		var empty: PackedStringArray = []
		var files: PackedStringArray = dir.get_files_at(path)
		var directories: PackedStringArray = dir.get_directories_at(path)
		# print(files)
		if (files != empty) and ("disable" not in files):
			modded = true
			if (".json" not in str(files)) or (not((".zip" in str(files)) or (".pck" in str(files)))):
				print("Invalid mod: " + path)
			else:
				print("Mod found: " + path)
			
			for i in files:
				if ((".json" in i) or (".JSON" in i)):
					var json = JSON.new()
					var json_file = FileAccess.open( path+"/"+i, FileAccess.READ )
					var json_string: String = json_file.get_as_text()
					var error = json.parse(json_string)
					if error == OK:
						var data_received = json.data
						if typeof(data_received) == TYPE_DICTIONARY:
							# Adds the mod path to the dictionary, and then adds the mod to the mods arrray
							var mod: Dictionary = data_received
							mod.path = path
							mods.append(mod)
						else:
							print("Unexpected data")
					else:
						print("JSON Parse Error: ", json.get_error_message(), " in ", json_string, \
						" at line ", json.get_error_line())
		elif ("disable" in files):
			print("Mod disabled: " + path)
			
		for i in directories:
			print("Found directory: " + i)
			findmods(dir.get_current_dir() + "/" + i)
			
		# dir.close()
	else:
		modded = false
		print("Mod folder not detected in " + path)

func loadmods():
	for mod in mods:
		var dir = DirAccess.open(mod.path)
		if not dir:
			print("Error loading mod: " + str(mod))
		else:
			dir.set_include_hidden(false)
			var files: PackedStringArray = dir.get_files_at(mod.path)
			for file in files:
				if ((".pck" in file) or (".PCK" in file) or (".zip" in file) or (".ZIP" in file)):
					var replace: bool = true
					if mod.has("noreplace"):
						if mod.noreplace:
							replace = false
					print(replace)
					var success = ProjectSettings.load_resource_pack(file, replace)
					if success:
						print("Loaded mod: " + str(mod))
					else:
						print("Error loading mod: " + str(mod))
			
			
