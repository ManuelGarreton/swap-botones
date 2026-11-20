"""
swap-botones: reasigna los botones de un control XInput (Xbox 360) creando un
control virtual con ViGEmBus. El control real se oculta a los juegos con HidHide.

Uso:  python swap_botones.py [ruta/a/config.json]
"""
import ctypes
import json
import os
import sys
import time
from ctypes import wintypes

# ------------------------------------------------------------------ XInput --
class XINPUT_GAMEPAD(ctypes.Structure):
    _fields_ = [
        ("wButtons", wintypes.WORD),
        ("bLeftTrigger", ctypes.c_ubyte),
        ("bRightTrigger", ctypes.c_ubyte),
        ("sThumbLX", ctypes.c_short),
        ("sThumbLY", ctypes.c_short),
        ("sThumbRX", ctypes.c_short),
        ("sThumbRY", ctypes.c_short),
    ]


class XINPUT_STATE(ctypes.Structure):
    _fields_ = [("dwPacketNumber", wintypes.DWORD), ("Gamepad", XINPUT_GAMEPAD)]


class XINPUT_VIBRATION(ctypes.Structure):
    _fields_ = [("wLeftMotorSpeed", wintypes.WORD), ("wRightMotorSpeed", wintypes.WORD)]


_xinput = ctypes.WinDLL("xinput1_4.dll")
try:
    _get_state = _xinput[100]  # XInputGetStateEx (no documentada): incluye boton Guia
except (AttributeError, OSError):
    _get_state = _xinput.XInputGetState
_get_state.argtypes = [wintypes.DWORD, ctypes.POINTER(XINPUT_STATE)]
_get_state.restype = wintypes.DWORD
_set_state = _xinput.XInputSetState
_set_state.argtypes = [wintypes.DWORD, ctypes.POINTER(XINPUT_VIBRATION)]
_set_state.restype = wintypes.DWORD


def read_state(index):
    st = XINPUT_STATE()
    return st if _get_state(index, ctypes.byref(st)) == 0 else None


def set_vibration(index, left, right):
    _set_state(index, ctypes.byref(XINPUT_VIBRATION(left, right)))


# ------------------------------------------------------------------- Mapeo --
BUTTONS = {
    "UP": 0x0001, "DOWN": 0x0002, "LEFT": 0x0004, "RIGHT": 0x0008,
    "START": 0x0010, "BACK": 0x0020, "LS": 0x0040, "RS": 0x0080,
    "LB": 0x0100, "RB": 0x0200, "GUIDE": 0x0400,
    "A": 0x1000, "B": 0x2000, "X": 0x4000, "Y": 0x8000,
}
DEFAULT_CONFIG = {"swaps": [["A", "B"], ["X", "Y"]]}


def load_config(path):
    if not os.path.exists(path):
        return DEFAULT_CONFIG
    with open(path, encoding="utf-8") as f:
        cfg = json.load(f)
    for pair in cfg.get("swaps", []):
        for name in pair:
            if name.upper() not in BUTTONS:
                raise ValueError(f"Boton desconocido en config: {name!r}. Validos: {', '.join(BUTTONS)}")
    return cfg


def build_mapper(cfg):
    pairs = [(BUTTONS[a.upper()], BUTTONS[b.upper()]) for a, b in cfg.get("swaps", [])]

    def remap(buttons):
        out = buttons
        for p, q in pairs:
            bp, bq = buttons & p, buttons & q
            out &= ~(p | q)
            if bp:
                out |= q
            if bq:
                out |= p
        return out

    return remap


# -------------------------------------------------------------------- Main --
def main():
    here = os.path.dirname(os.path.abspath(__file__))
    cfg_path = sys.argv[1] if len(sys.argv) > 1 else os.path.join(here, "config.json")
    cfg = load_config(cfg_path)
    remap = build_mapper(cfg)

    # Buscar el control real ANTES de crear el virtual
    reales = [i for i in range(4) if read_state(i) is not None]
    if not reales:
        print("No veo ningun control XInput.")
        print("Si HidHide ya lo oculta, este python debe estar permitido en HidHide:")
        print("   ", sys.executable)
        return 1
    real = reales[0]

    try:
        import vgamepad as vg
        pad = vg.VX360Gamepad()
    except ImportError:
        print("Falta la libreria vgamepad:  python -m pip install vgamepad")
        return 1
    except Exception as e:
        print("No pude crear el control virtual (¿ViGEmBus instalado?):", e)
        return 1

    def on_rumble(client, target, large_motor, small_motor, led_number, user_data):
        set_vibration(real, large_motor * 257, small_motor * 257)

    try:
        pad.register_notification(callback_function=on_rumble)
    except Exception:
        pass

    swaps = ", ".join(f"{a}<->{b}" for a, b in cfg.get("swaps", []))
    print(f"Control real: puerto XInput {real}. Control virtual creado ({swaps}).")
    print("Deja esta ventana abierta mientras juegas. Ctrl+C para salir.")

    last_packet = None
    lost = False
    try:
        while True:
            st = read_state(real)
            if st is None:
                if not lost:
                    print("Control real desconectado; esperando...")
                    lost = True
                pad.reset()
                pad.update()
                time.sleep(0.5)
                continue
            if lost:
                print("Control real reconectado.")
                lost = False
            if st.dwPacketNumber != last_packet:
                last_packet = st.dwPacketNumber
                g, r = st.Gamepad, pad.report
                r.wButtons = remap(g.wButtons)
                r.bLeftTrigger, r.bRightTrigger = g.bLeftTrigger, g.bRightTrigger
                r.sThumbLX, r.sThumbLY = g.sThumbLX, g.sThumbLY
                r.sThumbRX, r.sThumbRY = g.sThumbRX, g.sThumbRY
                pad.update()
            time.sleep(0.001)
    except KeyboardInterrupt:
        pass
    finally:
        try:
            pad.unregister_notification()
        except Exception:
            pass
        set_vibration(real, 0, 0)
        print("Cerrado.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
