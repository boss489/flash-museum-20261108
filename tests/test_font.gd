extends SceneTree
const FONT = preload("res://assets/NotoSansKR.ttf")
func _initialize() -> void:
 var text := "플래시 박물관 초상화 회랑 화석 전시실 천문 보관실 황동 메달 고대의 이빨 별의 지도 유물 확보 출구 경비에게 발각 다음 전시실 진입 생명 이동 셔터 소리 섬광 축소 카메라 한 번으로 밤의 경비를 멈춰라 방마다 하나씩 세 개를 모아 기록 최고 시작 터치 클릭 탈출 성공 두 번 발각되었습니다 다시 도전 전시 종료 좌우 재시작◆◇◀▶Ⅱ—0123456789/.:!· "
 var missing := ""
 for i in range(text.length()):
  if not FONT.has_char(text.unicode_at(i)):
   missing += text.substr(i,1)
 if missing != "":
  push_error("MISSING GLYPHS: " + missing)
  quit(1)
 else:
  print("FONT PASS: all ", text.length(), " representative UI glyphs")
  quit(0)
