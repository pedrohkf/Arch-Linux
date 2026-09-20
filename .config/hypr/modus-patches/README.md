# Modus patches

[Modus](https://github.com/S4NKALP/Modus) is installed separately via its own
`install.sh` (see the main setup guide) — it isn't vendored in this repo.
After installing or updating Modus, reapply these small patches by hand.
They fix real bugs found while running Modus on a **desktop** (no laptop
backlight) with **two external monitors** (one portrait) and Brazilian
keyboard layout.

## `config/hypr/modus.lua`

The autostart hook (`hl.on("hyprland.start", ...)`) never fires on
`hyprctl reload`, only on a real compositor boot — see the "Gotchas" section
in the main guide. Its `start.py` launch needs a lock so a theme switch
script can call it safely without spawning duplicates:

```lua
"flock /tmp/modus-guard.lock -c 'pgrep -x modus >/dev/null || (cd " .. modus .. " && uwsm app -- uv run python start.py)'",
```

Brightness keys use `brightnessctl`, which only works on laptop panels.
Point them at a DDC/CI script instead (see `brightness.sh` in this repo):

```lua
MonBrightnessUp = "~/.config/hypr/brightness.sh +5",
MonBrightnessDown = "~/.config/hypr/brightness.sh -5",
```

## `config/config.toml`

Ships with `keyboard_layouts = ["us", "pt-br"]` — `"pt-br"` isn't a valid
XKB layout code and throws `Invalid keyboard layout passed`. Use the real
code (`"br"`), matching `kb_layout` in `hardware.lua`:

```toml
keyboard_layouts = ["us", "br"]
```

Also point `wallpapers_dir` somewhere real instead of Modus's bundled
example wallpapers:

```toml
wallpapers_dir = "~/Pictures/Wallpapers"
```

## `src/window/lock.py` — `LockScreenWrapper.lock()`

Two stacked bugs made `Super+Ctrl+L` do nothing:

1. It shelled out with the **system** `python3`, not the `uv`-managed
   venv with Modus's actual dependencies (`pam`, `fabric`, etc.) →
   `ModuleNotFoundError: No module named 'pam'`.
2. The default profile picture asset (`src/assets/default.png`) doesn't
   exist in the Modus repo.

Fix #1:

```python
def lock(self):
    modus_dir = os.path.dirname(get_relative_path("../../start.py"))
    exec_shell_command_async(
        f"uv run --directory {modus_dir} python start.py lock"
    )
```

Fix #2 needs no code change — just create `~/.face.icon` (the standard
Linux user-avatar convention; `lock.py` already checks for it before
falling back to the missing asset).

## `src/window/dock/main.py`

The dock's `auto_hide` was occlusion-gated (only hides when a window
overlaps it *and* the mouse isn't hovering) instead of purely hover-based —
if nothing on screen overlaps the dock's corner, it never hides no matter
where the mouse is. There's also a typo (`"dock_auto_hide"` instead of
`"dock.auto_hide"`) that silently no-ops a related check.

`on_hover_leave`'s `delayed_hide` — drop the occlusion check, just hide:

```python
def delayed_hide(t):
    if t == self.hide_ticket and not self.is_hovered:
        if config().get("dock.auto_hide", True):
            self.revealer.set_reveal_child(False)
    return False
```

`_run_occlusion_check` — remove the branch that force-reveals the dock
when nothing occludes it (that's what was fighting the hover-based hide);
keep only the "hide when occluded and not hovered" branch. Also fix the
`dock_auto_hide` → `dock.auto_hide` key typo in the same function's early
return.

## `src/services/brightness.py`

The whole service only knew how to read `/sys/class/backlight`, which
doesn't exist on a desktop. Added a DDC/CI fallback: when no backlight
device is found, `_detect_ddc_displays()` probes `ddcutil detect` +
`getvcp 10` per display, and `_read_ddc_brightness()` /
`_set_ddc_brightness()` back the existing `screen_brightness`
property/setter so the on-screen brightness popup shows the real value
instead of always 0%. See the main guide for the `ddcutil` + `i2c-dev`
system setup this depends on.

**Keep ddcutil off the UI thread and off `--display`.** `ddcutil --display N`
rescans every i2c bus: ~5s for `getvcp`, ~10s for `setvcp`. Called
synchronously from the brightness slider (and when the control center is
built, which reads the current value), it froze the whole shell on every
tick. Address the i2c bus directly instead (~0.1s) and apply `setvcp` in a
worker thread where only the latest value wins:

```python
DDCUTIL = ["ddcutil", "--noverify", "--sleep-multiplier", "0.1"]

# _detect_ddc_displays(): keep the i2c bus of each *valid* "Display N" block
# (monitors that fail DDC show up as "Invalid display" with no header).
re.findall(r"^Display \d+\s+I2C bus:\s+/dev/i2c-(\d+)", out, re.MULTILINE)
# ...then probe with [*DDCUTIL, "--bus", n, "getvcp", "10", "--brief"]

def _set_ddc_brightness(self, value: int):
    with self._ddc_lock:
        self._ddc_target = value
        if self._ddc_running:
            return
        self._ddc_running = True
    threading.Thread(target=self._ddc_worker, daemon=True).start()

def _ddc_worker(self):
    while True:
        with self._ddc_lock:
            value, self._ddc_target = self._ddc_target, None
            if value is None:
                self._ddc_running = False
                return
        for n in self._ddc_displays:  # i2c bus numbers
            subprocess.run([*DDCUTIL, "--bus", str(n), "setvcp", "10", str(value)],
                           capture_output=True, timeout=5)
```

`_ddc_lock = threading.Lock()`, `_ddc_target = None` and
`_ddc_running = False` are initialised in `__init__`. Measured: `getvcp`
4.9s → 0.1s, and 20 rapid sets return in 0.2 ms (coalesced into ~3 calls).
The same `--display` slowness applies to `brightness.sh` (brightness keys),
which still runs `ddcutil detect` on every keypress.

## `src/window/controlcenter/main.py` — volume/brightness sliders

The sliders felt stuck at a few positions. PulseAudio (and the brightness
service) emit async `changed` events carrying **stale** values right after
a user set; `volume_changed` / `brightness_changed` applied them to the
slider (yanking it back mid-drag), and that programmatic `set_value`
re-triggered `set_volume` / `set_brightness`, writing the stale value back
— a feedback loop. Ignore async events for 300ms after a user-initiated set
and guard the programmatic `set_value`:

```python
import time
# __init__
self._volume_set_at = 0.0
self._brightness_set_at = 0.0

def set_volume(self, _, volume):
    if not self._signals_connected or self._updating_volume:
        return
    self._volume_set_at = time.monotonic()
    ...  # unchanged

def volume_changed(self, _):
    if (not self._signals_connected or self._updating_volume
            or time.monotonic() - self._volume_set_at < 0.3):
        return

    def sync():
        self._updating_volume = True  # set_value must not re-trigger set_volume
        self.volume_scale.set_value(int(audio_service.speaker.volume))
        self._updating_volume = False

    GLib.idle_add(sync)
```

`set_brightness` / `brightness_changed` get the identical treatment with
`_updating_brightness` and `_brightness_set_at`. Simulated 25→35→25 drag on
a real `FlatScale`: old code left the slider ≠ mouse in 9/11 steps, patched
code in 0/11.

## `src/window/notification/notification.py` — `create_content()`

Summary/body labels used `ellipsization="end"` with no wrapping, so
anything longer than ~40 characters (a Bluetooth pairing code, for
example) got truncated on one line. Added word wrapping with a line cap
instead:

```python
summary_label = Label(..., line_wrap="word-char", ellipsization="end", ...)
summary_label.set_lines(3)

body_label = Label(..., line_wrap="word-char", ellipsization="end", ...)
body_label.set_lines(6)
```

## `src/styles/notification/center_base.css`

`#noti-center-box` had `background-color: transparent` with no border —
combined with Modus having removed its own "no notifications" empty-state
label, the notification history panel was functionally invisible even
though it opened correctly. Give it a real background:

```css
#noti-center-box {
  background-color: @glass-popup;
  border: 1px solid @glass-border;
  border-radius: apply(radius-xl);
  margin-right: 10px;
  padding: 10px;
}
```

---

All of the above are local patches on top of Modus's own files — they're
lost on `git pull` inside `~/.config/Modus`. Diff against this doc after
updating Modus and reapply what's still needed.
