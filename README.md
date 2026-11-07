# 플래시 박물관 / Flash Museum

Godot 4.7 GDScript single-screen museum chase. Three authored rooms, one relic in each, stun guards with a 0.6-second local camera pulse, and exit with all three before two hits. Recharge takes 2 seconds. Portrait and desktop layouts, touch and mouse controls, persistent best time and room progress.

## Play

- Open `docs/index.html` through a static web server (`python3 -m http.server 8000` from this directory) or import `project.godot` in Godot 4.7.
- A/D or ←/→ move. Space or the large 셔터 button fires the flash. R restarts. M toggles sound, F reduces flash animation. Touch the left/right buttons or either side of the gallery to move; tap the shutter disc to stun guards.
- Guard cones indicate danger. Teal rings and pause marks indicate stunned guards. Collect a relic and reach the illuminated exit; repeat through all three rooms.

## Build and test

```sh
godot --headless --path . --editor --quit
godot --headless --path . --script res://tests/test_model.gd
godot --headless --path . --script res://tests/test_font.gd
godot --headless --path . --quit-after 10
godot --headless --path . --export-release Web docs/index.html
```

Godot Web exports require serving over HTTP, not opening `file://`. `docs/` is the static artifact, not deployed by this repository. Save data uses Godot's `user://` (browser IndexedDB). No analytics or network requests in the game. The font is Noto Sans KR, bundled under `assets/` with its SIL Open Font License (`assets/OFL.txt`). All art is programmatic and original; all sounds are synthesized in GDScript. Game source and artwork are MIT licensed; see `LICENSE`.

The deterministic suite checks starting state, flash timing/cooldown, collection, transition, failure, restart, and three-relic victory. The font test checks 203 representative Korean/UI characters. Browser QA captures are in `screenshots/desktop-relic.png` and `screenshots/mobile-flash.png`; the latter uses a 390×844 portrait viewport. The browser's headless animation scheduler required timer-driven frames during QA, with no changes to the exported game. Full three-room victory was model-tested but not completed manually in browser; device-specific audio autoplay still merits testing on a physical phone.
