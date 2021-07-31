# SpaceAce's object descender for Godot

This code was written using [Godot](https://godotengine.org/) 3.3.2.stable, and has not been tested with previous versions of the engine.

&nbsp;

## What it does

This code searches recursively through a Godot Dictionary to find the key you're looking for. No matter how complex your Dictionary is, or what kinds of keys and values it contains, the object descender will find it and retrieve its value for you.

This is similar to my [object descender for NodeJS](https://github.com/SpaceAceMonkey/object-descender).

&nbsp;

## Requirements

- Godot. I wrote this with 3.3.2.stable; it may or may not work with other versions.

## Optional

- [DebugHandler](https://github.com/SpaceAceMonkey/spaceace.godot.debughandler)

&nbsp;

## Features

- Fluent interface
  - Chain methods to easily manipulate the object's behavior
- Simple API
  - The entire library's core functionality is availabe through one method call.

&nbsp;

## Setup

1) Clone this repository or download the file GodotObjectDescender<span/>.gd in the res/ sub-directory. Add GodotObjectDescender<span/>.gd to your Godot project.
2) Add GodotObjectDescender to your project's AutoLoad settings. Give it a simple name and make sure "Singleton" is enabled. The name you give this singleton will be global, so remember not to create any variables in your code which conflict with it.

&nbsp;

## Properties

> _default_default_value

The value to be returned if the `grab()` operation fails. Can be temporarily overriden using [d()](#api). Defaults to `null`.

> _default_path_separator

The string to use when breaking the search key into pieces for processing by `grab()`. Can be temporarily overriden using [s()](#api). Defaults to `.`

&nbsp;

## API

`grab(dict, path, preserve_key)`

*Description*

Searches dict for the given path (a series of keys), and returns a result object.

*Returns*

{ error, errors, value, found_path }

- `error`: A numeric value equal to one of Godot's ERR_* enum values, or `OK` if no errors were encountered.
- `errors`: An array of strings describing errors encounterd.
  - Empty if no errors were encountered.
- `value`: The value found at the given location in the Dictionary.
  - Contains the default value if grab() fails to find the given key. See [_default_default_value](#properties)
- `found_path`: An array of strings representing the chain of keys that was successfully found during the `grab()` operation. If `grab()` was successful, this array will contain all the pieces of the search path. See [examples](#examples) for more details.

*Parameters*

> dict

A Godot Dictionary.

> path

A string representing the path to be searched for inside `dict`. For example, `"a_key.another_key.a_third_key.the_desired_key"`

> preserve_key

If true, `grab()` will wrap the returned value in its parent key. See [examples](#examples) for more details.

&nbsp;

`d(default_value)`

*Description*

Overrides the default value returned in the `{ value }` key of the result object when the `grab()` operation fails to find the desired path inside the Dictionary.

This method only overrides the default value for a single call to `grab()`. After that, the default value reverts to [_default_default_value](#properties)

*Returns*

`self`, allowing for method chaining.

*Parameters*

> default_value

A value of any type which will be returned inside the `{value}` key of the result object if `grab()` fails to find the requested path.

&nbsp;

`s(path_separator)`

*Description*

Overrides the path separator used to break the requested path into keys. This method only overrides the default path separator for a single call to `grab()`. After that, the path separator reverts to [_default_path_separator](#properties)

*Returns*

`self`, allowing for method chaining.

*Parameters*

> path_separator

A string used to break the `path` passed to `grab()` into individual keys.

&nbsp;

`set_debug_handler(debug_handler)`

*Description*

Specifies the object used to handle debug messages.

If no debug handler is set, debug messages will be ignored.

*Returns*

`self`, allowing for method chaining.

*Parameters*

> debug_handler

The `debug_handler` object must provide a `d(message, level)` function, as well as a `level` enum to specify log levels. I suggest using my [Godot DebugHandler](https://github.com/SpaceAceMonkey/spaceace.godot.debughandler)

&nbsp;

## Examples

```
var od = preload("res://GodotObjectDescender.gd").new()
var dict = {
    "key": "value",
    "key2": {
        "key2 inner": "key2_inner value",
        "key2_inner_2": { "dog": "cat" }
    },
    "van": "morrison"
}

var result = {}
# Basics
result = od.grab(dict, "key") # Found
print("%s" % result)
# {error:0, errors:[], found_path:[key], value:value}

result = od.grab(dict, "wrong_key") # Not found
print("%s" % result)
# {error:33, errors:[], found_path:[...], value:Null}

result = od.grab(dict, "van", true) # Found, preserving key
print("%s" % result)
# {error:0, errors:[], found_path:[van], value:{van:morrison}}

result = od.grab(dict, "key.key2") # Found
print("%s" % result)
# {error:33, errors:[], found_path:[key], value:Null}
# found_path contains key, but not key2, because key exists,
# but key.key2 does not.

result = od.grab(dict, "key2.key2 inner", true) # Found, preserving key
print("%s" % result)
# {
#     error:0
#     , errors:[]
#     , found_path:[key2, key2 inner]
#     , value:{key2 inner:key2_inner value}
# }

result = od.grab(dict, "key2.key2_inner_2.dog") # Found
print("%s" % result)
# {
#     error:0
#     , errors:[]
#     , found_path:[key2, key2_inner_2, dog]
#     , value:cat
# }

result = od.grab(dict, "key2.key2_inner_2.dog", true) # Found, preserving key
print("%s" % result)
# {
#     error:0
#     , errors:[]
#     , found_path:[key2, key2_inner_2, dog]
#     , value:{dog:cat}
# }


# Set default value for one call at a time
result = od.d("Not found").grab(dict, "key2") # Found
print("%s" % result)
# {
#     error:0
#     , errors:[]
#     , found_path:[key2]
#     , value:{key2 inner:key2_inner value, key2_inner_2:{dog:cat}}
# }

result = od.d("Not found").grab(dict, "key2.key2b") # Not found
print("%s" % result)
# {error:33, errors:[], found_path:[key2], value:Not found}

result = od.d({}).grab(dict, "key2_key2b") # Not found, note "_"
print("%s" % result)
# {error:33, errors:[], found_path:[...], value:{...}}

result = od.d(
  {"default_key":"default_value"}
).grab(dict, "wrong key") # Not found
print("%s" % result) # value = "Not Found"
# {
#   error:33
#   , errors:[]
#   , found_path:[...]
#   , value:{default_key:default_value}
# }

result = od.grab(dict, "key2_key2b") # Not found
# ^^ Remember, d() is only valid for one call to grab()
print("%s" % result) # value = null
# {error:33, errors:[], found_path:[...], value:Null}

# Change path separator for one call at a time
result = od.s(".").grab(dict, "key2.key2_inner_2") # Found
print("%s" % result)
# {
#   error:0
#   , errors:[]
#   , found_path:[key2, key2_inner_2]
#   , value:{dog:cat}
# }

result = od.s("-").grab(dict, "key2.key2_inner_2") # Not found
print("%s" % result)
# {error:33, errors:[], found_path:[...], value:Null}

result = od.s("_").grab(dict, "key") # Found
print("%s" % result)
# {error:0, errors:[], found_path:[key], value:value}

result = od.s("+").grab(dict, "key2") # Found
print("%s" % result)
# {
#   error:0
#   , errors:[]
#   , found_path:[key2]
#   , value:{
#     key2 inner:key2_inner value
#     , key2_inner_2:{dog:cat}
#   }
# }

result = od.s("_").grab(dict, "key2_key2 inner") # Found
print("%s" % result)
# {
#   error:0
#   , errors:[]
#   , found_path:[key2, key2 inner]
#   , value:key2_inner value
# }

result = od.s("_").grab(dict, "key2_key2_inner_2") # Not found
# ^^ Not found because "key2_key2_inner_2" contains "_" and
# therefore gets broken into individual keys.
print("%s" % result)
# {error:33, errors:[], found_path:[key2], value:Null}
#
# ^^ Note that found_path contains key2. This is because
# "key2_key2_inner_2" breaks down into [key2, key2, inner, 2]
# when the path separator is "_", and "key2" is a valid key
# in the first level of the Dictionary. However,
# { "key2": { "key2": ... } } does not exist, so grab()
# fails on the second key in the array
```

Additional examples can be found in the comments for `grab()`.