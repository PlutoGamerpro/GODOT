extends Node2D
# En dag i pixelby - Godot 4 prototype.
# Alt tegnes i koden (ingen assets). Styring: piletaster/WASD + E eller mellemrum.

const TR := [
	{"n": "Cykel", "c": 0, "k": "bike"},
	{"n": "Bus", "c": 24, "k": "bus"},
	{"n": "Taxa", "c": 150, "k": "taxi"},
]
const FOOD := [
	["Pizza", 45, "#ee8855"],
	["Burger", 35, "#aa6622"],
	["Sushi", 70, "#ff99aa"],
	["Æble", 10, "#dd3333"],
	["Kage", 30, "#ffccdd"],
]
const PAY := 400

var font: Font
var money := 500
var scene_name := "home"
var p := Vector2(160, 100)
var cut := {}
var basket: Array[String] = []
var worked := false
var working := false
var prog := 0.0
var msg := "Vælg hvordan du vil til arbejde!"
var mt := 4.0
var veh := "bike"
var day := 1
var near = null


func _ready() -> void:
	font = ThemeDB.fallback_font


# ---------- hjælpere ----------
func R(c, x, y, w, h) -> void:
	draw_rect(Rect2(x, y, w, h), Color(c))

func T(s: String, x: float, y: float, c = "#ffffff", al := "left") -> void:
	var col := Color(c)
	if al == "center":
		draw_string(font, Vector2(x - 150, y), s, HORIZONTAL_ALIGNMENT_CENTER, 300, 8, col)
	elif al == "right":
		draw_string(font, Vector2(x - 300, y), s, HORIZONTAL_ALIGNMENT_RIGHT, 300, 8, col)
	else:
		draw_string(font, Vector2(x, y), s, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, col)

func say(m: String) -> void:
	msg = m
	mt = 3.5


# ---------- spil-logik ----------
func travel(to: String, t: Dictionary) -> void:
	if t.c > money:
		say("Ikke penge nok til " + str(t.get("n", "det")) + "!")
		return
	money -= t.c
	veh = t.k
	var texts := {"work": "Kører på arbejde...", "shop": "På vej til supermarkedet...", "home": "På vej hjem..."}
	cut = {"to": to, "t": 0.0, "done": false, "text": texts[to]}
	if t.c > 0:
		say("-" + str(t.c) + " kr")

func start_work() -> void:
	if not worked:
		working = true
		prog = 0.0
		say("Tryk hurtigt på mellemrum!")

func buy(f: Array) -> void:
	if money < f[1]:
		say("Ikke penge nok!")
	else:
		money -= f[1]
		basket.append(str(f[0]))
		say("Du købte " + str(f[0]) + "! Mums.")

func objs() -> Array:
	var o: Array = []
	if scene_name == "home":
		for i in TR.size():
			var t: Dictionary = TR[i]
			var price := (str(t.c) + " kr") if t.c > 0 else "gratis"
			o.append({"r": Rect2(50 + i * 90, 112, 40, 30), "l": t.n + " (" + price + ")", "a": travel.bind("work", t)})
	elif scene_name == "work":
		o.append({"r": Rect2(130, 50, 60, 28), "l": "Færdig for i dag" if worked else "Start arbejde", "a": start_work})
		if worked:
			o.append({"r": Rect2(30, 135, 50, 30), "l": "Supermarked", "a": travel.bind("shop", {"c": 0, "k": veh})})
			o.append({"r": Rect2(240, 135, 50, 30), "l": "Tag hjem", "a": travel.bind("home", {"c": 0, "k": veh})})
	elif scene_name == "shop":
		for i in FOOD.size():
			var f: Array = FOOD[i]
			o.append({"r": Rect2(20 + i * 58, 30, 40, 26), "l": f[0] + " " + str(f[1]) + " kr", "a": buy.bind(f)})
		o.append({"r": Rect2(135, 140, 50, 30), "l": "Tag hjem", "a": travel.bind("home", {"c": 0, "k": veh})})
	return o

func find_near(os: Array):
	for o in os:
		var r: Rect2 = o.r
		if p.x > r.position.x - 6 and p.x < r.end.x + 6 and p.y > r.position.y - 6 and p.y < r.end.y + 14:
			return o
	return null


func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		if not cut.is_empty():
			return
		if working and (e.keycode == KEY_SPACE or e.keycode == KEY_E):
			prog += 7
		elif (e.keycode == KEY_E or e.keycode == KEY_SPACE or e.keycode == KEY_ENTER) and near != null:
			near.a.call()


func _process(dt: float) -> void:
	mt -= dt
	if not cut.is_empty():
		cut["t"] += dt
		if cut["t"] > 1.5 and not cut["done"]:
			cut["done"] = true
			scene_name = cut["to"]
			p = Vector2(160, 100 if scene_name == "home" else 120)
			if scene_name == "work":
				worked = false
				working = false
			if scene_name == "home":
				var eaten := ", ".join(basket) if basket.size() > 0 else "ingenting"
				say("Dag slut! Du spiste: " + eaten + ". Ny dag!")
				basket.clear()
				day += 1
		if cut["t"] > 3.0:
			cut = {}
		queue_redraw()
		return

	if working:
		prog = max(0.0, prog - 15.0 * dt)
		if prog >= 100.0:
			working = false
			worked = true
			money += PAY
			say("Arbejde færdig! +" + str(PAY) + " kr")
			p.y = 120
	else:
		var d := Vector2.ZERO
		if Input.is_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_A): d.x -= 1
		if Input.is_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_D): d.x += 1
		if Input.is_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_W): d.y -= 1
		if Input.is_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_S): d.y += 1
		p += d.normalized() * 70.0 * dt
		p.x = clampf(p.x, 6, 314)
		p.y = clampf(p.y, 24, 176)
	near = find_near(objs())
	queue_redraw()


# ---------- tegning ----------
func draw_vehicle(k: String, x: float, y: float) -> void:
	if k == "bike":
		R("#111", x, y + 8, 6, 6); R("#111", x + 16, y + 8, 6, 6)
		R("#d22", x + 4, y + 5, 14, 2); R("#888", x + 10, y, 2, 6)
	elif k == "bus":
		R("#e33", x, y, 40, 16)
		R("#99ccff", x + 3, y + 3, 7, 5); R("#99ccff", x + 13, y + 3, 7, 5); R("#99ccff", x + 23, y + 3, 7, 5)
		R("#111", x + 5, y + 14, 6, 5); R("#111", x + 28, y + 14, 6, 5)
	elif k == "taxi":
		R("#ffdd00", x, y + 6, 30, 9); R("#ffdd00", x + 7, y, 16, 7)
		R("#99ccff", x + 9, y + 1, 12, 5); R("#000", x + 11, y - 3, 8, 3)
		R("#111", x + 4, y + 13, 6, 5); R("#111", x + 20, y + 13, 6, 5)

func draw_player() -> void:
	var x := p.x - 4
	var y := p.y - 10
	R("#222", x + 1, y + 10, 6, 2)
	R("#3388cc", x, y + 4, 8, 6)
	R("#f5c28b", x + 1, y, 6, 5)
	R("#553311", x + 1, y, 6, 2)

func _draw() -> void:
	if not cut.is_empty():
		draw_cutscene()
		return
	var os := objs()
	if scene_name == "home":
		R("#4a8c4a", 0, 0, 320, 180); R("#555555", 0, 100, 320, 60)
		for i in 8: R("#dddddd", i * 44 + 10, 128, 22, 2)
		R("#cc9977", 20, 20, 70, 50); R("#aa3333", 14, 12, 82, 12)
		R("#553311", 48, 44, 14, 26); R("#99ccff", 70, 34, 12, 12)
		T("Hjem", 55, 85, "#ffffff", "center")
		for i in os.size():
			var r: Rect2 = os[i].r
			R("#ffdd00", r.position.x, r.position.y, r.size.x, 2)
			R("#ffdd00", r.position.x, r.end.y - 2, r.size.x, 2)
			var k: String = TR[i].k
			draw_vehicle(k, r.position.x + (0 if k == "bus" else 5), r.position.y + 8)
	elif scene_name == "work":
		R("#888899", 0, 0, 320, 180); R("#555566", 0, 0, 320, 40)
		for i in 6: R("#99ccff", 20 + i * 50, 10, 30, 16)
		R("#885533", 130, 50, 60, 28); R("#222222", 150, 40, 20, 14); R("#66ff66", 152, 42, 16, 10)
		if worked:
			R("#ffdd00", 30, 135, 50, 30); R("#ffdd00", 240, 135, 50, 30)
			T("Supermarked", 55, 152, "#000000", "center"); T("Hjem", 265, 152, "#000000", "center")
	elif scene_name == "shop":
		R("#ddddee", 0, 0, 320, 180); R("#aaaabb", 0, 0, 320, 26)
		for i in FOOD.size():
			R("#776655", 20 + i * 58, 30, 40, 26)
			R(FOOD[i][2], 26 + i * 58, 34, 28, 12)
		R("#ffdd00", 135, 140, 50, 30)
		T("Hjem", 160, 158, "#000000", "center")

	draw_player()
	if near != null and not working:
		var l: String = near.l
		var w := l.length() * 5 + 24
		R("#000000", p.x - w / 2.0, p.y - 26, w, 12)
		T(l + " [E]", p.x, p.y - 17, "#ffff00", "center")
	if working:
		R("#000000", 90, 150, 140, 20); R("#333333", 94, 154, 132, 12)
		R("#44dd44", 94, 154, 132.0 * prog / 100.0, 12)
		T("ARBEJDER", 160, 148, "#ffffff", "center")
	R("#000000", 0, 0, 320, 12)
	T("Dag %d  |  Penge: %d kr" % [day, money], 4, 9, "#ffdd00")
	T("Kurv: %d" % basket.size(), 316, 9, "#ffffff", "right")
	if mt > 0:
		var w2 := msg.length() * 5 + 12
		R("#000000", 160 - w2 / 2.0, 160, w2, 14)
		T(msg, 160, 170, "#ffffff", "center")

func draw_cutscene() -> void:
	var t: float = cut["t"]
	R("#66ccff", 0, 0, 320, 180); R("#88aa88", 0, 80, 320, 30)
	for i in 5:
		var bx := fposmod(i * 90 - t * 30, 400.0) - 40
		R("#777788", bx, 40, 40, 50)
		R("#ccddee", bx + 8, 50, 8, 8); R("#ccddee", bx + 24, 50, 8, 8)
	R("#444444", 0, 110, 320, 50)
	for i in 8: R("#dddddd", fposmod(i * 50 - t * 200, 400.0) - 40, 134, 26, 3)
	draw_vehicle(veh, -50 + t / 3.0 * 420, 100)
	T(cut["text"], 160, 40, "#000000", "center")
	var a := maxf(0.0, 1.0 - t / 0.4) + maxf(0.0, (t - 2.6) / 0.4)
	draw_rect(Rect2(0, 0, 320, 180), Color(0, 0, 0, minf(1.0, a)))
