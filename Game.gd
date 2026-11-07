extends Node2D

const M = preload("res://Model.gd")
const FONT = preload("res://assets/NotoSansKR.ttf")
const INK := Color("0d1423")
const SLATE := Color("172537")
const STONE := Color("283846")
const PAPER := Color("f0e5c8")
const GOLD := Color("ddbb79")
const TEAL := Color("72d9cc")
const RED := Color("ed786d")
var model = M.new()
var portrait := false
var view_scale := 1.0
var offset := Vector2.ZERO
var clock := 0.0
var move_left := false
var move_right := false
var touch_left := false
var touch_right := false
var touch_owner := -1
var muted := false
var reduced_flash := false
var best := 0.0
var highest_room := 0
var sfx: AudioStreamPlayer
var notice := ""
var notice_time := 0.0

func _ready() -> void:
 sfx = AudioStreamPlayer.new()
 add_child(sfx)
 var save := ConfigFile.new()
 if save.load("user://flash_museum.cfg") == OK:
  best = float(save.get_value("scores", "best", 0.0))
  highest_room = int(save.get_value("scores", "room", 0))
 queue_redraw()

func _save() -> void:
 var save := ConfigFile.new()
 save.set_value("scores", "best", best)
 save.set_value("scores", "room", highest_room)
 save.save("user://flash_museum.cfg")

func _process(delta: float) -> void:
 clock += delta
 notice_time = maxf(0.0, notice_time - delta)
 if model.mode == "playing":
  var direction := float(int(move_right or touch_right) - int(move_left or touch_left))
  model.step(minf(delta, 0.05), direction)
  if model.event != "":
   _handle_event(model.event)
 queue_redraw()

func _handle_event(e: String) -> void:
 match e:
  "flash": _sound("shutter")
  "relic":
   notice = "유물 확보 · " + M.RELIC_NAMES[model.room]
   notice_time = 1.8
   _sound("relic")
  "hurt":
   notice = "경비에게 발각!"
   notice_time = 1.2
   _sound("hurt")
  "room":
   highest_room = maxi(highest_room, model.room + 1)
   _save()
   notice = "다음 전시실 진입"
   notice_time = 1.4
   _sound("room")
  "won":
   if best <= 0.0 or model.elapsed < best:
    best = model.elapsed
   highest_room = 3
   _save()
   _sound("won")

func _flash() -> void:
 if model.flash():
  _handle_event("flash")

func _unhandled_input(event: InputEvent) -> void:
 if event is InputEventKey:
  if event.keycode in [KEY_A, KEY_LEFT]: move_left = event.pressed
  if event.keycode in [KEY_D, KEY_RIGHT]: move_right = event.pressed
  if event.pressed and not event.echo:
   if event.keycode in [KEY_SPACE, KEY_ENTER]:
    if model.mode == "playing": _flash()
    else: model.start()
   elif event.keycode == KEY_R: model.start()
   elif event.keycode == KEY_M: muted = not muted
   elif event.keycode == KEY_F: reduced_flash = not reduced_flash
 if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
  _pointer(event.position, event.pressed, 0)
 if event is InputEventScreenTouch:
  _pointer(event.position, event.pressed, event.index + 1)
 if event is InputEventScreenDrag:
  _pointer(event.position, true, event.index + 1)

func _pointer(pos: Vector2, down: bool, pointer_id: int) -> void:
 var p := (pos - offset) / view_scale
 if not down:
  if touch_owner == pointer_id or pointer_id == 0:
   touch_left = false
   touch_right = false
   touch_owner = -1
  return
 if model.mode != "playing":
  model.start()
  return
 var control_y := 575.0 if portrait else 430.0
 if p.y >= control_y:
  if p.x < (170.0 if portrait else 235.0):
   touch_left = p.x < (92.0 if portrait else 115.0)
   touch_right = not touch_left
   touch_owner = pointer_id
  elif p.x > (280.0 if portrait else 740.0):
   _flash()
   touch_owner = -1
 elif portrait and p.y >= 177.0 and p.y < 458.0:
  if p.x > 195.0: touch_right = true
  else: touch_left = true
  touch_owner = pointer_id
 elif not portrait and p.y > 130.0 and p.y < 430.0:
  if p.x > 480.0: touch_right = true
  else: touch_left = true
  touch_owner = pointer_id

func _draw() -> void:
 var vp := get_viewport_rect().size
 portrait = vp.x / maxf(vp.y, 1.0) < 0.85
 var base := Vector2(390, 844) if portrait else Vector2(960, 540)
 view_scale = minf(vp.x / base.x, vp.y / base.y)
 offset = (vp - base * view_scale) * 0.5
 draw_rect(Rect2(Vector2.ZERO, vp), INK)
 draw_set_transform(offset, 0.0, Vector2(view_scale, view_scale))
 if portrait:
  draw_rect(Rect2(0, 0, 390, 844), INK)
  # Fill the phone width; the taller art scale gives the corridor more screen space.
  draw_set_transform(offset + Vector2(0, 177) * view_scale, 0.0, Vector2(view_scale * 390.0 / 960.0, view_scale * 0.52))
  _room_art()
  draw_set_transform(offset, 0.0, Vector2(view_scale, view_scale))
  _portrait_ui()
 else:
  _room_art()
  _desktop_ui()
 draw_set_transform(Vector2.ZERO)

func _label(text: String, x: float, y: float, size: int, color: Color = PAPER) -> void:
 if portrait and size >= 17:
  draw_string_outline(FONT, Vector2(x,y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, 1, color)
 draw_string(FONT, Vector2(x,y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, size, color)

func _center(text: String, x: float, y: float, size: int, color: Color = PAPER) -> void:
 var width := FONT.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
 _label(text, x - width * 0.5, y, size, color)

func _room_art() -> void:
 var r: int = model.room
 draw_rect(Rect2(0, 0, 960, 540), INK)
 draw_rect(Rect2(0, 94, 960, 352), SLATE)
 # Layered architectural insets and columns.
 for i in range(7):
  var x := float(i * 160 - 24)
  draw_rect(Rect2(x, 112, 126, 262), STONE)
  draw_rect(Rect2(x+9, 120, 108, 232), Color("1b2c3c"))
  draw_line(Vector2(x, 104), Vector2(x+128, 104), GOLD.darkened(0.55), 2)
  draw_rect(Rect2(x+126, 95, 7, 286), Color("394954"))
  draw_rect(Rect2(x+5, 371, 126, 11), Color("42505a"))
  if r == 0:
   draw_rect(Rect2(x+35, 147, 59, 110), GOLD.darkened(0.25), false, 5)
   draw_rect(Rect2(x+40, 152, 49, 100), Color("101e2b"))
   draw_circle(Vector2(x+64, 187), 17, Color("647781"))
   draw_rect(Rect2(x+50, 207, 28, 37), Color("647781"))
  elif r == 1:
   draw_arc(Vector2(x+64, 215), 39, PI, TAU, 20, GOLD.darkened(0.25), 4)
   for j in range(4):
    draw_line(Vector2(x+38+j*17, 209), Vector2(x+40+j*13, 247), Color("859399"), 4)
   draw_line(Vector2(x+29, 252), Vector2(x+101, 252), GOLD.darkened(0.5), 2)
  else:
   draw_circle(Vector2(x+64, 201), 42, Color("102330"))
   draw_arc(Vector2(x+64, 201), 36, -2.7, 2.6, 25, GOLD.darkened(0.25), 2)
   draw_circle(Vector2(x+64, 201), 7, TEAL.darkened(0.25))
   for j in range(3):
    draw_circle(Vector2(x+35+j*25, 177+j*10), 2, PAPER)
 # Floor, parallax grain and plinth.
 draw_rect(Rect2(0, 386, 960, 154), Color("202d38"))
 for i in range(13):
  draw_line(Vector2(i*85, 389), Vector2(i*85-30, 540), Color("344451"), 1)
 for i in range(3):
  draw_line(Vector2(0, 410+i*37), Vector2(960, 410+i*37), Color("344451"), 1)
 for i in range(12):
  var dx := fposmod(float(i*137)+clock*(2+i%3), 920.0)+18.0
  draw_circle(Vector2(dx, 146+float(i*19%188)), 1.5, Color(0.87,0.80,0.66,0.23))
 var relic_x: float = model.relic_positions[r]
 draw_rect(Rect2(relic_x-43, 346, 86, 18), Color("5c5860"))
 draw_rect(Rect2(relic_x-34, 364, 68, 43), Color("39434b"))
 if not model.collected[r]:
  var bob := sin(clock*2.7)*4.0
  draw_circle(Vector2(relic_x, 322+bob), 31, Color(0.44,0.85,0.80,0.10))
  if r == 0:
   draw_circle(Vector2(relic_x, 320+bob), 17, GOLD)
   draw_circle(Vector2(relic_x, 320+bob), 11, STONE)
   draw_circle(Vector2(relic_x, 320+bob), 6, GOLD)
  elif r == 1:
   draw_colored_polygon(PackedVector2Array([Vector2(relic_x-13,306+bob), Vector2(relic_x+16,308+bob), Vector2(relic_x+8,337+bob), Vector2(relic_x,344+bob)]), PAPER)
  else:
   draw_colored_polygon(PackedVector2Array([Vector2(relic_x,300+bob), Vector2(relic_x+17,328+bob), Vector2(relic_x-18,328+bob)]), TEAL)
   draw_circle(Vector2(relic_x,319+bob), 4, GOLD)
 # Exit.
 draw_rect(Rect2(895, 274, 54, 139), GOLD.darkened(0.4))
 draw_rect(Rect2(902, 281, 40, 132), Color("101e29"))
 draw_line(Vector2(922,284), Vector2(922,410), GOLD.darkened(0.4), 2)
 draw_circle(Vector2(929,357), 3, GOLD)
 _center("출구", 922, 267, 16, GOLD if model.collected[r] else Color("72838a"))
 for g in model.guards:
  var gx: float = g["x"]
  var stunned: bool = g["stun"] > 0.0
  var facing: float = g["dir"]
  if not stunned:
   draw_colored_polygon(PackedVector2Array([Vector2(gx+facing*19,346), Vector2(gx+facing*150,295), Vector2(gx+facing*150,413)]), Color(0.95,0.42,0.36,0.12))
  draw_ellipse(Vector2(gx,410), 28, 6, Color(0,0,0,0.3))
  draw_colored_polygon(PackedVector2Array([Vector2(gx-16,353), Vector2(gx+16,353), Vector2(gx+22,407), Vector2(gx-22,407)]), Color("0c151e"))
  draw_rect(Rect2(gx-12, 332, 24, 24), Color("101b25"))
  draw_rect(Rect2(gx-11, 343, 22, 5), TEAL if stunned else RED)
  draw_rect(Rect2(gx-16, 323, 32, 9), Color("0a131d"))
  if stunned:
   draw_arc(Vector2(gx,366), 34, clock, clock+TAU*0.83, 28, TEAL, 3)
   _center("Ⅱ", gx, 316, 20, TEAL)
 var px: float = model.player_x
 if model.invincible <= 0.0 or int(clock*8)%2 == 0:
  draw_ellipse(Vector2(px,410), 25, 6, Color(0,0,0,0.3))
  draw_colored_polygon(PackedVector2Array([Vector2(px-14,354),Vector2(px+13,354),Vector2(px+20,408),Vector2(px-19,408)]), Color("b1c4c1"))
  draw_rect(Rect2(px-10,328,20,25), PAPER)
  draw_rect(Rect2(px-12,324,24,6), Color("304a55"))
  draw_line(Vector2(px-13,358),Vector2(px+19,373),TEAL,5)
  draw_rect(Rect2(px+9,357,16,13),Color("142b37"))
  draw_circle(Vector2(px+20,362),5,TEAL)
 if model.flash_time > 0.0:
  var k: float = 1.0 - model.flash_time / M.FLASH_DURATION
  var radius: float = 270.0 if reduced_flash else 70.0 + 205.0*k
  draw_arc(Vector2(px,366),radius,0,TAU,72,Color(0.55,0.95,0.88,0.75*(1-k)),5.0)
  draw_circle(Vector2(px,366),34,Color(0.65,0.97,0.91,0.08*(1-k)))
 draw_rect(Rect2(0,92,960,4), GOLD.darkened(0.45))
 draw_rect(Rect2(0,447,960,4), GOLD.darkened(0.45))


func _desktop_ui() -> void:
 draw_rect(Rect2(0,0,960,93), Color("0d1423"))
 _label("FLASH / MUSEUM",26,36,17,GOLD)
 _label("%02d  %s" % [model.room+1,M.ROOM_NAMES[model.room]],26,75,28,PAPER)
 _label("유물  %d / 3" % model.relics,490,49,21,TEAL)
 _label("생명  " + "◆".repeat(model.hearts) + "◇".repeat(2-model.hearts),690,49,21,RED)
 draw_rect(Rect2(0,450,960,90),INK)
 _controls(80,475,180,475,870,479,43)
 _label("← → / A D 이동    SPACE 플래시    R 재시작",258,486,15,Color("a7b9b7"))
 _label("M 소리    F 섬광 축소",258,515,13,GOLD)
 _progress(258,525,410,7)
 if notice_time > 0.0: _center(notice,480,129,20,TEAL)
 if model.mode != "playing": _overlay(480,270,false)

func _portrait_ui() -> void:
 _center("FLASH / MUSEUM",195,34,21,PAPER)
 _center("플래시 박물관",195,79,34,PAPER)
 _center("%02d  %s" % [model.room+1,M.ROOM_NAMES[model.room]],195,122,23,PAPER)
 _label("유물 %d/3" % model.relics,18,162,21,TEAL)
 _label("생명 " + "◆".repeat(model.hearts) + "◇".repeat(2-model.hearts),265,162,20,RED)
 _center("전시실을 가로질러 유물을 찾으세요",195,493,20,PAPER)
 _progress(24,516,342,12)
 _controls(54,620,130,620,324,620,32)
 _center("◀ ▶ 이동     셔터로 경비 정지",195,710,20,PAPER)
 _center("F 섬광 축소  ·  M 소리  ·  R 재시작",195,750,17,PAPER)
 if notice_time > 0.0: _center(notice,195,208,20,TEAL)
 if model.mode != "playing": _overlay(195,317,true)

func _progress(x: float,y: float,w: float,h: float) -> void:
 draw_rect(Rect2(x,y,w,h),Color("344451"))
 draw_rect(Rect2(x,y,w*(1.0-model.cooldown/M.RECHARGE),h),TEAL)

func _controls(lx: float,ly: float,rx: float,ry: float,fx: float,fy: float,r: float) -> void:
 for item in [[lx,ly,"◀",touch_left],[rx,ry,"▶",touch_right]]:
  draw_circle(Vector2(item[0],item[1]),r,Color("344451") if not item[3] else TEAL.darkened(0.45))
  _center(item[2],item[0],item[1]+11,32,PAPER)
 draw_circle(Vector2(fx,fy),r+6,Color("2d6160") if model.cooldown <= 0 else Color("405563"))
 draw_arc(Vector2(fx,fy),r+6,-PI/2,-PI/2+TAU*(1.0-model.cooldown/M.RECHARGE),40,TEAL,4)
 _center("셔터",fx,fy+9,26 if r < 40 else 19,PAPER)

func _overlay(cx: float, cy: float, mobile: bool) -> void:
 var w := 370.0 if mobile else 590.0
 var h := 282.0 if mobile else 272.0
 draw_rect(Rect2(cx-w/2,cy-h/2,w,h),Color("0b1723e8"))
 draw_rect(Rect2(cx-w/2,cy-h/2,w,h),GOLD.darkened(0.35),false,2)
 if model.mode == "title":
  _center("플래시 박물관",cx,cy-91,30 if mobile else 48,GOLD)
  _center("카메라로 밤의 경비를 멈춰라" if mobile else "카메라 한 번으로 밤의 경비를 멈춰라",cx,cy-47,19 if mobile else 17,PAPER)
  _center("셔터 0.6초 · 재충전 2초" if mobile else "좌우 이동  ·  셔터는 0.6초 / 재충전 2초",cx,cy-8,19 if mobile else 16,TEAL)
  _center("유물 세 개를 모아 출구로" if mobile else "방마다 유물 하나씩, 세 개를 모아 출구로",cx,cy+31,19 if mobile else 15,PAPER)
  _center("시작 · 터치 / ENTER",cx,cy+89,21 if mobile else 20,GOLD)
 elif model.mode == "lost":
  _center("전시 종료",cx,cy-44,42,RED)
  _center("두 번 발각되었습니다",cx,cy+1,20,PAPER)
  _center("다시 도전  ·  터치 / 클릭 / ENTER / R",cx,cy+76,18,GOLD)
 else:
  _center("탈출 성공!",cx,cy-55,43,TEAL)
  _center("세 유물을 지켰습니다",cx,cy-10,21,PAPER)
  _center("기록 %.1f초  ·  최고 %.1f초" % [model.elapsed,best],cx,cy+29,19,GOLD)
  _center("다시 도전  ·  터치 / 클릭 / ENTER",cx,cy+84,18,PAPER)
 if highest_room > 0 and model.mode == "title":
  _center("최고 진도 %d/3  ·  최고 기록 %s" % [highest_room, "%.1f초" % best if best > 0 else "—"],cx,cy+120 if mobile else cy+117,16 if mobile else 13,PAPER if mobile else Color("9baba9"))

func _sound(kind: String) -> void:
 if muted: return
 var rate := 22050
 var duration := 0.20 if kind == "shutter" else 0.28
 var samples := int(rate * duration)
 var data := PackedByteArray()
 data.resize(samples*2)
 var base_freq := 680.0 if kind == "relic" or kind == "won" else 190.0
 for i in range(samples):
  var t := float(i)/rate
  var envelope := pow(1.0-t/duration,2.0)
  var wave := sin(TAU*base_freq*t)
  if kind == "shutter":
   wave = sin(TAU*107.0*t)*0.3 + (sin(i*12.9898)*sin(i*78.233))*0.7
   envelope *= 1.0 if t < 0.035 or (t > 0.07 and t < 0.105) else 0.12
  elif kind == "hurt": wave = sin(TAU*(220.0-150.0*t)*t)
  else: wave = sin(TAU*(base_freq+370.0*t)*t)+0.3*sin(TAU*base_freq*2.0*t)
  var value := clampi(int(wave*envelope*8000.0),-32767,32767)
  data[i*2] = value & 255
  data[i*2+1] = (value >> 8) & 255
 var wav := AudioStreamWAV.new()
 wav.format = AudioStreamWAV.FORMAT_16_BITS
 wav.mix_rate = rate
 wav.stereo = false
 wav.data = data
 sfx.stream = wav
 sfx.play()
