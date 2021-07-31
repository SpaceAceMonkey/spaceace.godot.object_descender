# You may use this code however you like, including in commercial products, but this notice must remain intact.
# This code and all associated files are (c) 2021 by me.
# This code's home is https://github.com/SpaceAceMonkey/spaceace.godot.object-descender/
extends Node

# The default value returned by grab() when the desired key is not found
# in the Dictionary. Can be overridden for a single grab() using d().
var _default_default_value = null setget set_default_default_value
# The default path separator used to break a key into pieces. For
# example, in the key "first.second.third.desired_key", the
# path separator is the period found between each pair of words.
var _default_path_separator = '.' setget set_default_path_separator

var _default_value = self._default_default_value
var _path_separator = self._default_path_separator
var _dh = null

# Travels into a Dictionary to find a specific key. The search key is specified as "key.key2.and so.on"
#
# Parameters
# - dict: The Dictionary object to search
# - path: The key you wish to search for in dict. For example, "this.particular.dictionary.key"
# - preserve_key: True = return { last_key_found: value } instead of just value
#                 This only has an effect when the search is successful.
# Returns a Dictionary in the format
#  {
#	"error": Integer from the ERR_* enum
#	, "errors": [an array of error strings]
#	, "value": The value retrieved from the Dictionary
#	, "found_path": [contains each key in the path that was successfully located]
#  }
#
# Example Dictionary:
#  var dict = { "key": "value", "key2": { "sub-key one": "sub-key one value" } }
# Example usages
# grab(dict, "key") -> "value"
# grab(dict, "key2") -> { "sub-key one": "sub-key one value" }
# grab(dict, "key2.sub-key one") -> "sub-key one value"
# grab(dict, "key that doesn't exist") -> Null
#
# d() and s()
# - d() sets the default value to be returned if the complete path can not be found in the dictionary
# - s() sets the path separator string
# Both d() and s() work only for one call to grab().
# d("Value not found").grab(dict, "key that doesn't exist") -> "Value not found"
# s(":").grab(dict, "key2.sub-key one") -> Null
# s(":").grab(dict, "key2:sub-key one") -> "sub-key one value"
# s(":").d("Value not found").grab(dict, "key2.sub-key one") -> "Value not found"
#
# In each case, the value following "->" is what will be found in the "value" key
# of the result object returned by the function.
func grab(dict, path, preserve_key = false):
	var result = { "error": OK, "errors": [], "value": null, "found_path": [] }
	if typeof(dict) != TYPE_DICTIONARY:
		result.errors.push_back("First argument to od_get must be a Dictionary.")
		# ERR_* are not powers of two, so we will overwrite result.error each time
		# we encounter a new error during processing. If the ERR_* enum used
		# powers of two, we could just | them together. We could also store an
		# array of errors, and I may implement that in a future version.
		result.error = ERR_INVALID_PARAMETER
	if typeof(path) != TYPE_STRING || path.empty():
		result.errors.push_back("Second argument to od_get must be a non-empty string.")
		result.error = ERR_INVALID_PARAMETER

	if result.error == OK:
		self.grab_recursive(dict, path.split(self._path_separator), result)

	if result.error != OK:
		result.value = self._default_value
	else:
		result.value = { result.found_path.back(): result.value } if preserve_key else result.value

	self._default_value = self._default_default_value
	self._path_separator = self._default_path_separator

	return result

# Call grab() rather than calling this directly
func grab_recursive(dict, path_keys, result):
	var next_key = path_keys[0]
	path_keys.remove(0)
	if next_key:
		if next_key in dict:
			var value = dict[next_key]
			result.found_path.push_back(next_key)
			if path_keys.size() > 0:
				self.grab_recursive(value, path_keys, result)
			else:
				result.value = value
		else:
			result.error = ERR_DOES_NOT_EXIST
			self.dbg(
				(
					"Failed to find key '{key}' at path '{path}' in GodotObjectDescender -> grab_recursive()"
				).format({"key": next_key, "path": PoolStringArray(result.found_path).join(self._path_separator)})
			)
	else:
		result.error = ERR_DOES_NOT_EXIST
		self.dbg(
			(
				"Encountered an empty or invalid key '{key}' in GodotObjectDescender -> grab_recursive()"
			).format({"key": next_key})
		)


# Shortcut to set_temporary_default_value()
func d(value):
	return set_temporary_default_value(value)


# Shortcut to set_temporary_default_separator()
func s(separator):
	return set_temporary_default_separator(separator)


# Sets the value of the path separator. This value is only set
# for the next call to grab(), after which it will revert to 
# _default_path_separator from this instance of the
# ObjectDescender class.
func set_temporary_default_separator(separator):
	var separator_type = typeof(separator)
	if separator_type != TYPE_STRING:
		self.dbg(
			(
				"Separator must be a string (type %s) in GodotObjectDescender -> set_temporary_default_separator(); " +
				"type %s supplied, instead."
			) % [TYPE_STRING, separator_type]
		)
	else:
		self._path_separator = separator

	return self


# Sets the default value to be returned if the specified key is
# not found in the Dictionary. Default value is only set for
# the next call to grab(), after which it will revert to 
# _default_default_value from this instance of the
# ObjectDescender class.
func set_temporary_default_value(value):
	self._default_value = value

	return self


# This is the value that will be returned in the "value" key of the grab() result
# if it is not overridden by a call to d(). In essence, this is the permanent
# default value to d()'s temporary one.
func set_default_default_value(value):
	_default_default_value = value
	self._default_value = _default_default_value


# This is the path separator that will be used by grab() if it is not overridden
# by a call to s(). In essence, this is the permanent path separator to s()'s
# temporary one.
func set_default_path_separator(separator):
	if typeof(separator) != TYPE_STRING:
		self.dbg((
			"Value provided to set_default_path_separator must be of type string (%s); type %s provided."
			% [typeof(TYPE_STRING), typeof(separator)]
		))
	else:
		_default_path_separator = separator


# It is your responsibility to ensure debug_handler has the
# method d() for handling debug output, and a "level" enum.
# The easiest way is to use my Godot DebugHandler, found at
# https://github.com/SpaceAceMonkey/spaceace.godot.debughandler
func set_debug_handler(debug_handler):
	self._dh = debug_handler

	return self


# Calls the debug handler if one is available
func dbg(message, level = self._dh.level.INFO if self._dh else null):
	if self._dh:
		dh.d(message, level)

