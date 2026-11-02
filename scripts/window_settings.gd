extends RefCounted
const RESOLUTIONS: Array[Vector2i]=[Vector2i(1280,720),Vector2i(1600,900),Vector2i(1920,1080)]
var applied_mode: int=-1
var applied_resolution: int=-1
var requests: int=0
func embedded(window: Window, arguments: PackedStringArray=OS.get_cmdline_args()) -> bool:
	# Godot consumes native embedding flags; use its explicit 4.7 API first.
	if Engine.is_embedded_in_editor() or window.is_embedded(): return true
	for argument in arguments:
		if argument=="--wid" or argument.begins_with("--wid="): return true
	return false
func apply(window: Window, settings: Dictionary, key: String="") -> void:
	if key!="" and key not in ["fullscreen","resolution"]: return
	if DisplayServer.get_name()=="headless" or embedded(window): return
	var mode: int=Window.MODE_FULLSCREEN if settings.fullscreen else Window.MODE_WINDOWED
	var resolution: int=clampi(int(settings.resolution),0,RESOLUTIONS.size()-1)
	if applied_mode!=mode:
		window.mode=mode
		applied_mode=mode
		requests+=1
	if mode==Window.MODE_WINDOWED and (applied_resolution!=resolution or key=="fullscreen"):
		window.size=RESOLUTIONS[resolution]
		applied_resolution=resolution
		requests+=1
