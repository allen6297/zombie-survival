uuid - static uuid generator for Godot Engine
===========================================

The *UUID* class is a GDScript 'static' class that provides a unique identifier generation for [Godot Engine](https://godotengine.org).

Usage
-----

Copy the `uuid.gd` file in your project folder, then start using it.

```gdscript
func _init():
  # To generate a new UUID string
  print(UUID.v4())

  # To generate a new UUID object
  var uuid_object = UUID.new()
  var uuid_object_2 = UUID.new()

  print(uuid_object.as_string())
  print(uuid_object.as_dict())

  # Get a duplicated object
  print(uuid_object.as_array())

  # Compare 2 UUID objects
  print(uuid_object.is_equal(uuid_object_2))
```

Licensing
---------

MIT (See license file for more informations)
