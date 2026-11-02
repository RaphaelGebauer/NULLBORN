extends Node
var sounds: Dictionary={}
var players: Array=[]
var music: AudioStreamPlayer
var cooldown: float=0
func _ready() -> void:
	process_mode=Node.PROCESS_MODE_ALWAYS
	for bus in ["Music","Effects"]:
		if AudioServer.get_bus_index(bus)<0:
			AudioServer.add_bus()
			AudioServer.set_bus_name(AudioServer.bus_count-1,bus)
	for pair in [["pickup",740.0],["hurt",110.0],["choose",520.0]]: sounds[pair[0]]=tone(pair[1],.12)
	music=AudioStreamPlayer.new()
	music.bus="Music"
	add_child(music)
	music.stream=score()
	if DisplayServer.get_name()!="headless": music.play()
func tone(frequency: float,length: float) -> AudioStreamWAV:
	var bytes:=PackedByteArray()
	bytes.resize(int(22050*length)*2)
	for i in range(bytes.size()/2):
		var t: float=float(i)/22050
		var envelope: float=sin(PI*t/length)*exp(-t*18)
		bytes.encode_s16(i*2,int(sin(TAU*frequency*t)*envelope*9000))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	stream.data=bytes
	return stream
func score() -> AudioStreamWAV:
	# Original eight-second ambient loop: A/E/F/C progression with a sparse pentatonic voice.
	var bytes:=PackedByteArray()
	bytes.resize(22050*8*2)
	var roots: Array=[110.0,164.8138,130.8128,146.8324]
	var notes: Array=[440.0,523.251,659.255,587.33,440.0,783.991,659.255,523.251]
	for i in range(22050*8):
		var t: float=float(i)/22050
		var root_note: float=roots[int(t/2)%4]
		var edge: float=minf(1,minf(t*4,(8-t)*4))
		var pluck: float=fmod(t,1.0)
		var sample: float=(sin(TAU*root_note*t)*.18+sin(TAU*root_note*1.5*t)*.09+sin(TAU*notes[int(t)%8]*t)*exp(-pluck*5)*.18)*edge
		bytes.encode_s16(i*2,int(sample*15000))
	var stream:=AudioStreamWAV.new()
	stream.format=AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate=22050
	stream.data=bytes
	stream.loop_mode=AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin=0
	stream.loop_end=22050*8
	return stream
func _process(delta: float) -> void:
	cooldown=maxf(0,cooldown-delta)
func play(kind: String) -> void:
	if DisplayServer.get_name()=="headless" or cooldown>0 or players.size()>=6: return
	cooldown=.045
	var player:=AudioStreamPlayer.new()
	player.bus="Effects"
	player.stream=sounds.get(kind,sounds.choose)
	add_child(player)
	players.append(player)
	player.finished.connect(func(): players.erase(player); player.queue_free())
	player.play()
func configure(settings: Dictionary) -> void:
	for pair in [["Master","master"],["Music","music"],["Effects","sfx"]]:
		AudioServer.set_bus_volume_db(AudioServer.get_bus_index(pair[0]),linear_to_db(maxf(.0001,settings[pair[1]])))
func _exit_tree() -> void:
	if is_instance_valid(music):
		music.stop()
		music.stream=null
	for player in players:
		if is_instance_valid(player):
			player.stop()
			player.stream=null
	players.clear()
