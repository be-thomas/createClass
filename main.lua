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

-- both classes & objects can be printed : 
print(tostring(Dog))
print(tostring(dog))
