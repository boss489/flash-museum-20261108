extends SceneTree

const M = preload("res://Model.gd")
var failures := 0
func check(ok: bool, label: String) -> void:
 if not ok:
  failures += 1
  printerr("FAIL: ", label)
 else:
  print("PASS: ", label)
func _initialize() -> void:
 var m = M.new()
 m.start()
 check(m.room == 0 and m.hearts == 2 and m.relics == 0, "initial run")
 m.flash()
 check(m.flash_time == 0.6 and m.cooldown == 2.0, "flash duration and recharge")
 m.flash()
 check(m.cooldown == 2.0, "cooldown blocks repeat")
 m.step(0.6, 0)
 check(m.flash_time <= 0.001 and m.cooldown > 1.3, "flash expires deterministically")
 m.step(1.4, 0)
 check(m.cooldown <= 0.001, "flash recharges")
 m.player_x = m.relic_positions[0]
 m.step(0.01, 0)
 check(m.relics == 1, "relic pickup")
 m.player_x = 915
 m.step(0.01, 0)
 check(m.room == 1 and m.relics == 1, "room progression retains relic")
 m.hearts = 1
 m.invincible = 0
 m.player_x = m.guards[0]["x"]
 m.step(0.01, 0)
 check(m.mode == "lost", "second hit loses")
 m.start()
 check(m.mode == "playing" and m.hearts == 2 and m.room == 0, "restart resets")
 for i in range(3):
  m.room = i
  m.relics = i
  m.player_x = m.relic_positions[i]
  m.step(0.01, 0)
  check(m.relics == i+1, "room %d relic" % (i+1))
  m.player_x = 915
  m.step(0.01, 0)
 check(m.mode == "won" and m.relics == 3, "exit wins only after three relics")
 print("RESULT failures=", failures)
 quit(1 if failures else 0)
