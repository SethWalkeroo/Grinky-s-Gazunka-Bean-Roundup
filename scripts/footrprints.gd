extends Decal

var fade_time = 12.0
var timer = 0.0

func _process(delta):
	timer += delta
	if timer > fade_time:
		# Fade out the albedo alpha
		albedo_mix = lerp(1.0, 0.0, (timer - fade_time) / 2.0) 
		if albedo_mix <= 0.01:
			queue_free() # Delete the node when fully faded
