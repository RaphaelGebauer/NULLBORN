extends RefCounted
# Synchronous borrowed render view. Never retain it, mutate gameplay, advance RNG/cadence,
# or call simulation/update/hit methods here. Canvas calls run only inside World's _draw.
func render(canvas: Node2D,view: Dictionary) -> void:
	var model: RefCounted=view.model
	var player: Node2D=view.player
	var combat: RefCounted=view.combat
	var rift_node: Dictionary=view.rift_node
	var lanterns: Array=view.lanterns
	var pickups: Array=view.pickups
	var reaction_visuals: Array=view.reaction_visuals
	var enemies: Array=view.enemies
	var shots: Array=view.shots
	var hazards: Array=view.hazards
	var texts: Array=view.texts
	var reduce_flash: bool=view.reduce_flash
	var damage_texts: bool=view.damage_texts
	if not is_instance_valid(player): return
	var stage: Dictionary=model.registry.get_def(model.stage).values
	var origin:=Vector2i(player.position/96)
	for x in range(origin.x-10,origin.x+11):
		for y in range(origin.y-7,origin.y+8):
			var pos:=Vector2(x,y)*96
			canvas.draw_rect(Rect2(pos,Vector2(96,96)),Color(stage.background).lightened(.012 if posmod(x+y,2)==0 else 0))
			var pattern: int=posmod(x*73+y*37,13)
			if pattern<3:
				var c:=Color(stage.accent)
				if model.stage=="ash":
					canvas.draw_arc(pos+Vector2(35,40),20,0,TAU,12,c,2)
				else:
					canvas.draw_line(pos+Vector2(32,55),pos+Vector2(32,30),c.darkened(.3),4)
					canvas.draw_circle(pos+Vector2(32,29),8,c)
			elif pattern==4: canvas.draw_rect(Rect2(pos+Vector2(15,30),Vector2(22,9)),Color(stage.accent).darkened(.3))
	if not rift_node.is_empty():
		var pos: Vector2=rift_node.pos
		canvas.draw_arc(pos,25,0,TAU,6,Color("aab9f6"),3)
		canvas.draw_line(pos+Vector2(-10,-15),pos+Vector2(8,15),Color("d2f4ed"),3)
		canvas.draw_string(ThemeDB.fallback_font,pos+Vector2(-48,-35),"F / Y · Rift",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("d2f4ed"))
	for lantern in lanterns:
		canvas.draw_rect(Rect2(lantern.pos-Vector2(8,13),Vector2(16,26)),Color("bd8650"))
		canvas.draw_circle(lantern.pos,6,Color("ffee96"))
	for p in pickups:
		var c: Color=Color("4de8d2") if p.kind=="xp" else Color("ffd66b") if p.kind in ["gold","chest"] else Color("ff9fa8")
		var r: float=6 if p.kind=="xp" else 11
		if p.kind=="xp" and p.value>10: r=9;c=Color("a89cff")
		if p.kind=="chest": canvas.draw_rect(Rect2(p.pos-Vector2(12,9),Vector2(24,18)),c)
		else: canvas.draw_colored_polygon(PackedVector2Array([p.pos+Vector2(0,-r),p.pos+Vector2(r,0),p.pos+Vector2(0,r),p.pos+Vector2(-r,0)]),c)
	for effect in reaction_visuals:
		canvas.draw_arc(effect.pos,effect.radius,0,TAU,16,Color("a8d2d9",.35 if reduce_flash else .65),1)
		canvas.draw_string(ThemeDB.fallback_font,effect.pos+Vector2(-24,-20),effect.name,HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("bed4db"))
	for e in enemies:
		var c:=Color.from_hsv(model.registry.get_def(e.kind).values.color,.5,.85)
		if e.flash>0 and not reduce_flash: c=c.lerp(Color("c2cdd1"),.35*e.flash/.06)
		if e.statuses.has("slow"): c=Color("87d8ff")
		if e.statuses.has("burn") or e.statuses.has("imprint_glow"): c=c.lerp(Color.ORANGE,.5)
		canvas.draw_circle(e.pos+Vector2(0,7),e.radius+2,Color(0,0,0,.4))
		var points:=PackedVector2Array()
		var sides: int=3+int(model.registry.catalogs.enemy.keys().find(e.kind))%5
		for i in range(sides): points.append(e.pos+Vector2.RIGHT.rotated(TAU*i/sides+e.age*.15)*e.radius)
		canvas.draw_colored_polygon(points,c)
		canvas.draw_circle(e.pos+Vector2(-4,-3),2,Color.WHITE)
		if e.statuses.has("charged"): canvas.draw_arc(e.pos,e.radius+4,0,TAU*.75,12,Color("b8c9ff"),1.5)
		if e.statuses.has("imprint_mark"):
			canvas.draw_line(e.pos+Vector2(-4,-e.radius-6),e.pos+Vector2(4,-e.radius-6),Color("d6c2f7"),2)
		if e.kind=="shield": canvas.draw_arc(e.pos,e.radius+3,e.velocity.angle()-.9,e.velocity.angle()+.9,8,Color("d8e8ed"),4)
		if e.kind=="healer": canvas.draw_arc(e.pos,30,0,TAU,16,Color(0.3,1,.5,.4),2)
		if e.kind in ["charger","astral_guardian"] and e.phase==1: canvas.draw_line(e.pos,e.pos+e.charge*150,Color("ff696b"),3)
		if e.elite:
			canvas.draw_arc(e.pos,e.radius+7,0,TAU,20,Color("e3b475"),2)
			for i in range(e.affixes.size()):
				canvas.draw_string(ThemeDB.fallback_font,e.pos+Vector2(-e.radius+i*14,-e.radius-12),e.affixes[i].left(1).to_upper(),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color("ffd996"))
			if e.elite_state.warning>0:
				canvas.draw_arc(e.elite_state.blink_target,e.radius+6,0,TAU,12,Color("c3b4f5"),2)
		if e.boss:
			if e.transition_left>0: canvas.draw_arc(e.pos,e.radius+12,0,TAU,20,Color("f6c978"),3)
			if e.dash_state==1: canvas.draw_line(e.pos,e.pos+e.dash_direction*220,Color("f6c978"),3)
			canvas.draw_rect(Rect2(e.pos+Vector2(-45,-e.radius-15),Vector2(90,6)),Color("3d273d"))
			canvas.draw_rect(Rect2(e.pos+Vector2(-45,-e.radius-15),Vector2(90*maxf(0,e.hp/e.max_hp),6)),Color("ff777c"))
	for s in shots:
		if s.delay>0: continue
		var c:=Color("ff756d") if s.hostile else Color.from_hsv(s.values.get("color",.5),.5,1)
		if s.bounces>0: canvas.draw_arc(s.pos,9,s.age*9,s.age*9+TAU*.8,10,c,3)
		elif s.values.get("boomerang",false): canvas.draw_arc(s.pos,14,s.age*8,s.age*8+PI,9,c,4)
		else: canvas.draw_line(s.pos-s.velocity.normalized()*14,s.pos,c,4)
	for id in model.weapons:
		var v: Dictionary=model.registry.weapon_values(id,model.weapons[id])
		if v.behavior=="orbit":
			var p: Dictionary=combat.params(combat.modifiers.parameters(id,v,false))
			for i in range(int(p.count)):
				var pos: Vector2=player.position+Vector2.RIGHT.rotated(combat.elapsed*p.rotation+TAU*i/p.count)*p.radius*(1+.12*(p.duration-3)/3)
				canvas.draw_circle(pos,11*model.area,Color("ffdf8d"))
	for e in combat.effects:
		var c:=Color.from_hsv(e.values.get("color",.13),.6,1,.3 if reduce_flash else .7)
		if e.behavior=="impact":
			var progress: float=clampf(e.age/e.life,0,1)
			canvas.draw_arc(e.pos,e.radius*(.4+progress*.6),0,TAU,16,Color(.8,.8,.65,(.15 if reduce_flash else .5)*(1-progress)),1)
		elif e.behavior=="beam":
			canvas.draw_line(player.position,player.position+Vector2.RIGHT.rotated(e.angle)*e.radius,c,e.values.get("hit_width",10.0)*1.2)
		elif e.delay>0:
			canvas.draw_arc(e.pos,e.radius,0,TAU,24,Color(c,.55),2)
			if e.has("launch"):
				var t: float=clampf(e.age/.8,0,1)
				var pos: Vector2=e.launch.lerp(e.pos,t)-Vector2(0,sin(t*PI)*90)
				canvas.draw_circle(pos,8,c)
		else:
			canvas.draw_circle(e.pos,e.radius,Color(c,.03 if reduce_flash else .12))
			canvas.draw_arc(e.pos,e.radius,0,TAU,24,c,3)
	for h in hazards:
		var c:=Color(1,.7,.3,.7) if h.delay>0 else Color(1,.3,.3,.6 if reduce_flash else .9)
		if h.has("gap"):
			canvas.draw_arc(h.pos,h.radius,h.gap_angle+h.gap*.5,h.gap_angle+TAU-h.gap*.5,30,c,2)
		elif h.has("end"): canvas.draw_line(h.pos,h.end,c,3 if h.delay>0 else h.radius*2)
		else: canvas.draw_arc(h.pos,h.radius,0,TAU,24,c,2 if h.delay>0 else 8)
	if damage_texts:
		for t in texts: canvas.draw_string(ThemeDB.fallback_font,t.pos,t.text,HORIZONTAL_ALIGNMENT_LEFT,-1,17 if t.get("critical",false) else 15,Color(1,.76,.35,t.life/.6) if t.get("critical",false) else Color(.85,.92,.9,t.life/.6))

