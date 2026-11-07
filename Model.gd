extends RefCounted

const SPEED := 245.0
const RECHARGE := 2.0
const FLASH_DURATION := 0.6
const STUN_DURATION := 2.5
const ROOM_NAMES := ["초상화 회랑", "화석 전시실", "천문 보관실"]
const RELIC_NAMES := ["황동 메달", "고대의 이빨", "별의 지도"]
var relic_positions := [480.0, 555.0, 430.0]
var room := 0
var player_x := 78.0
var hearts := 2
var relics := 0
var cooldown := 0.0
var flash_time := 0.0
var invincible := 0.0
var elapsed := 0.0
var mode := "title"
var guards: Array[Dictionary] = []
var collected := [false, false, false]
var event := ""

func start() -> void:
 room = 0
 player_x = 78.0
 hearts = 2
 relics = 0
 cooldown = 0.0
 flash_time = 0.0
 invincible = 0.0
 elapsed = 0.0
 collected = [false, false, false]
 mode = "playing"
 event = "start"
 setup_room()

func setup_room() -> void:
 if room == 0:
  guards = [{"x": 770.0, "home": 770.0, "dir": -1.0, "speed": 88.0, "stun": 0.0, "kind": 0}]
 elif room == 1:
  guards = [{"x": 360.0, "home": 360.0, "dir": 1.0, "speed": 83.0, "stun": 0.0, "kind": 1}, {"x": 800.0, "home": 800.0, "dir": -1.0, "speed": 72.0, "stun": 0.0, "kind": 0}]
 else:
  guards = [{"x": 330.0, "home": 330.0, "dir": 1.0, "speed": 112.0, "stun": 0.0, "kind": 0}, {"x": 715.0, "home": 715.0, "dir": -1.0, "speed": 100.0, "stun": 0.0, "kind": 1}]

func flash() -> bool:
 if mode != "playing" or cooldown > 0.0:
  return false
 flash_time = FLASH_DURATION
 cooldown = RECHARGE
 event = "flash"
 for g in guards:
  if absf(g["x"] - player_x) <= 270.0:
   g["stun"] = STUN_DURATION
 return true

func step(delta: float, direction: float) -> void:
 if mode != "playing":
  return
 event = ""
 elapsed += delta
 cooldown = maxf(0.0, cooldown - delta)
 flash_time = maxf(0.0, flash_time - delta)
 invincible = maxf(0.0, invincible - delta)
 player_x = clampf(player_x + direction * SPEED * delta, 42.0, 926.0)
 for g in guards:
  if g["stun"] > 0.0:
   g["stun"] = maxf(0.0, g["stun"] - delta)
   continue
  var distance: float = player_x - g["x"]
  if g["kind"] == 0 and absf(distance) < 300.0:
   g["dir"] = signf(distance)
  elif g["kind"] == 1:
   if g["x"] < g["home"] - 125.0:
    g["dir"] = 1.0
   elif g["x"] > g["home"] + 125.0:
    g["dir"] = -1.0
  g["x"] = clampf(g["x"] + g["dir"] * g["speed"] * delta, 44.0, 916.0)
  if absf(g["x"] - player_x) < 31.0 and invincible <= 0.0:
   hearts -= 1
   invincible = 1.5
   player_x = clampf(player_x - signf(distance) * 72.0, 42.0, 926.0)
   event = "hurt"
   if hearts <= 0:
    mode = "lost"
    return
 if not collected[room] and absf(player_x - relic_positions[room]) < 35.0:
  collected[room] = true
  relics += 1
  event = "relic"
 if player_x > 893.0 and collected[room]:
  if room == 2:
   mode = "won"
   event = "won"
  else:
   room += 1
   player_x = 65.0
   invincible = 0.8
   setup_room()
   event = "room"
