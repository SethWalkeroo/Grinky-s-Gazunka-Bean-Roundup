extends RichTextLabel


func _ready():
	# Display the total beans from the permanent save file
	text = "[color=cyan]Bean Jar:[/color] [wave amp=20 freq=5 connect=1][color=gold][b]%s[/b][/color][/wave]" % str(GlobalStats.total_beans_collected)
