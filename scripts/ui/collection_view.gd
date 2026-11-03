extends ScrollContainer
# Read-only projection: no App, Model or SaveManager ownership and no state machine.
func populate(registry: RefCounted,is_discovered: Callable) -> void:
	custom_minimum_size=Vector2(900,450)
	var text:=RichTextLabel.new()
	text.custom_minimum_size=Vector2(850,0)
	text.fit_content=true
	var lines: String=""
	for kind in registry.catalogs:
		if kind=="mutation": continue
		lines+="\n"+{"weapon":"WEAPONS","passive":"PASSIVES","enemy":"BESTIARY","character":"HEROES","wave":"WAVES","evolution":"RECIPES","rune":"RUNES","stage":"ARENAS","mutation":"MUTATIONS"}[kind]+"\n"
		for d in registry.catalogs[kind].values():
			var discovered: bool=is_discovered.call(d.id,kind)
			lines+=(d.display_name+" · "+d.description if discovered else "??? · Not yet discovered")+"\n"
	text.text=lines
	add_child(text)
