extends RefCounted
# Pure immutable definitions, shared by Registry and gameplay.
const DEFINITIONS: Array[Dictionary]=[
	{"id":"arc_freeze","name":"Arc Freeze","elements":["frost","storm"],"bonus":.35,"secondary":.30,"radius":120.0,"targets":1},
	{"id":"blightburst","name":"Blightburst","elements":["fire","toxin"],"bonus":.45,"secondary":.45,"radius":60.0,"targets":8},
	{"id":"void_shatter","name":"Void Shatter","elements":["frost","void"],"bonus":.50,"secondary":0.0,"radius":0.0,"targets":0},
	{"id":"rift_conduction","name":"Rift Conduction","elements":["storm","void"],"bonus":0.0,"secondary":.25,"radius":140.0,"targets":2}]
