# createClass.lua

<img src="https://travis-ci.org/jonstoler/class.lua.svg" />

createClass => OOP on steroids

### Features

- simple usage & implementation
- small (one file, just over 150 lines, about 2KB)
- support for static and instance properties
- support for `super`
- support for getters, setters & watchers with ZERO overhead
- support for printing classes & instances

```

	-- Usage:
	--------------------------
	local createClass = require("createClass")
	Animal = createClass()

	function Animal:constructor(species)
	    self.species = species
	end

	local animal = Animal("dog")
	-- static variable
	Animal.domesticated = true



	-- Inheritance :-
	-----------------------
	local Dog = createClass(Animal)

	function Dog:constructor()
	    self.super.constructor(self, "dog")
	end

	local dog = Dog()
	print(dog.species)
	-- print static variable
	print(Dog.domesticated)

	-- both classes & instances can be printed : 
	print(tostring(Dog))
	print(tostring(dog))

```

## Usage

### Creating a class

Classes can be created with the `createClass()` function. Classes are just like any other lua variable. They can be local or global. I recommend using CapitalCamelCase names. This way, you can give classes their own files and it's easy to import them into any other files that need them.

	-- create new class
	Animal = createClass()


### Creating a subclass

Subclasses can be created with the `createClass(superClass)` function. They inherit all properties from their super classes. 

	-- creates a subclass, here Animal is the super class of Dog
	Dog = createClass(Animal)

	
### Printing Class/Instance
Both Classes and instances can be printed with proper indentation:

	print(tostring(Dog))
	print(tostring(dog))

Sample output:
	
	class {
	  set: function: 0x010085a628,
	  super: class {
	    constructor: function: 0x0100864db0,
	    set: function: 0x010085a628,
	    _: table: 0x0100864c10,
	  },
	  constructor: function: 0x0100867298,
	  _: table: 0x0100867040,
	}

	instance {
	  set: function: 0x010085a628,
	  super: table: 0x0100867348,
	  constructor: function: 0x0100867298,
	  _: table: 0x01008674e0,
	}


### Setting properties

Sometimes it's useful to set class properties outside of a constructor (especially for inheritance). You can use the `set()` function for this, with either one key/value pair or a table.

	MyAwesomeClass:set("property", "value")
	MyAwesomeClass:set{
		property1 = "value1",
		property2 = "value2",
	}

### Static properties

Static properties can be added to the class itself.

	MyAwesomeClass.staticProperty = 3

Static properties have the same features as other properties (getters/setters, inheritance, etc.)

### Creating a constructor

The `constructor` function is called when your class is initialized. It takes an arbitrary number of arguments.

	function MyAwesomeClass:constructor(a, b, c)
		self.sum = a + b + c
	end

### Creating an instance of a class

You can create a new instance of your class with the `new()` function, or by simply calling the class name as a function. Pass constructor arguments to this function.

	-- create instance of class
	local awesome = MyAwesomeClass(1, 2, 3)

	print(awesome.sum) --> 6

### Getters/Setters

Getters and setters are declared by setting a property to a table with fields `get` and/or `set`.

#### Constant getters/setters

If you set the value of `get` or `set` to a constant, that will be used instead of the actual property.

The value for this property is stored in the `value` key of this table, if appropriate.

	MyAwesomeClass:set{
		property = {
			get = "getConstant",
		},
		property2 = {
			value = "unset",
			set = "setConstant",
		}
	}

	local c = MyAwesomeClass()
	print(c.property) --> "getConstant"
	print(c.property2) --> "unset"
	c.property2 = "this value will be overridden!"
	print(c.property2) --> "setConstant"

#### Getter/Setter functions

If you set the value of `get` or `set` to a function, that will be called and the result will be used.

The `get` function takes two arguments: `self` and the current value of the property being accessed (`value` key in the table).

The `set` function takes three arguments: `self`, the new value, and the current value of the property being set. The `value` key will be automatically changed to the result of this function.

	MyAwesomeClass:set{
		a = "something",
		property = {
			value = "v",
			get = function(self, value) return self.a .. value end
		},
		property2 = {
			value = 3,
			set = function(self, newVal, oldVal) return newVal * oldVal end
		}
	}

	local c = MyAwesomeClass()
	print(c.property) --> "somethingv"
	c.property2 = 6
	print(c.property2) --> 18

#### Setter callbacks

If the `afterSet` key (must be a function!) is set, it will be called after a value is changed. It takes two arguments: `self` and the current value of the variable (after the setter has already been called).

This is useful for systems that require updating when specific values change (eg text that must reformat itself after a window is resized).

## Privacy

There is no built-in mechanism for private or protected variables. These features would bloat the code and make it very difficult to maintain. Instead, I recommend you treat all variable names that start with an underscore (`_privateProperty`) as private. It's up to you to make sure you don't access these properties when you shouldn't.

## Reserved Values

The following are special properties/functions that you should not use for other purposes in your classes, because the class library itself uses them:

	-- CLASS PROPERTIES/METHODS
	_
	set()
	__index metatable
	__newindex metatable
	"get", "set", "afterSet", or "value" keys in a table property
