# swap-botones

Intercambia los botones de un control **XInput (Xbox 360)** en Windows — por defecto **A↔B** y **X↔Y** — para **todos los juegos**, incluidos los que no son de Steam (Epic, Rockstar, etc.).

Lo hice para poder usar un control de Nintendo como si fuera uno de Xbox: el botón de abajo pasa a funcionar como **A** (aceptar) y el de la derecha como **B** (volver), como esperan los juegos de PC.

> *English:* Swaps face buttons (A↔B, X↔Y by default) of any XInput / Xbox 360 controller system-wide on Windows, using a virtual controller (ViGEmBus) and hiding the physical one (HidHide).

## El problema

Muchos controles genéricos traen las letras con **distribución Nintendo** (B abajo, A a la derecha, Y izquierda, X arriba) pero se identifican ante Windows como un **control oficial de Xbox 360** (`VID_045E&PID_028E`). El botón de abajo envía la señal **B**, así que en los juegos "aceptar" y "volver" quedan al revés.

- Windows no permite reasignar botones de un control Xbox 360.
- Steam Input tiene la opción *"Usar disposición de botones de Nintendo"*, pero solo funciona en juegos lanzados por Steam (y no en juegos con anticheat que bloquean su inyección).
- El orden de los botones está grabado en el firmware del control.

## Cómo funciona

```
Control real ──XInput──▶ swap_botones.py ──(intercambia botones)──▶ Control virtual Xbox 360 ──▶ Juegos
     │                                                              (ViGEmBus)
     └── oculto para los juegos con HidHide (solo python puede verlo)
```

1. **[ViGEmBus](https://github.com/nefarius/ViGEmBus)** crea un control Xbox 360 virtual.
2. **swap_botones.py** lee el control real vía XInput, aplica el mapeo de `config.json` y lo envía al virtual (palancas, gatillos, botón Guía y vibración incluidos).
3. **[HidHide](https://github.com/nefarius/HidHide)** oculta el control real para todo el sistema excepto `python.exe`, así los juegos no reciben doble entrada.

## Requisitos

- Windows 10/11 (x64)
- [Python 3.9+](https://www.python.org) (marcar *"Add python.exe to PATH"*)
- Permisos de administrador para instalar los drivers

## Instalación

1. Descarga o clona este repositorio.
2. Con el control **enchufado**, ejecuta **`instalar.bat`** y acepta los permisos. El script:
   - descarga e instala ViGEmBus y HidHide desde sus releases oficiales de GitHub,
   - instala la librería [`vgamepad`](https://pypi.org/project/vgamepad/),
   - permite a tu `python.exe` en HidHide y oculta el control real.
3. **Reinicia el PC.**

## Uso

1. Ejecuta **`iniciar.bat`** y deja la ventana abierta.
2. Abre tu juego normalmente.

Mientras el control real esté oculto, **solo funciona con `iniciar.bat` abierto**.

| Archivo | Para qué sirve |
|---|---|
| `iniciar.bat` | Inicia el intercambio de botones |
| `config.json` | Define qué botones intercambiar |
| `ocultar_control.bat` | Vuelve a ocultar el control (p. ej. si cambiaste de puerto USB) |
| `mostrar_control.bat` | Desactiva el ocultamiento (el control vuelve a funcionar normal, sin swap) |

### Configurar botones

`config.json`:

```json
{ "swaps": [["A", "B"], ["X", "Y"]] }
```

Botones válidos: `A B X Y LB RB LS RS START BACK GUIDE UP DOWN LEFT RIGHT`.

### Otro control

Si tu control usa otro VID/PID (míralo en *Administrador de dispositivos → Propiedades → Detalles → Id. de hardware*):

```powershell
powershell -ExecutionPolicy Bypass -File scripts\ocultar_control.ps1 -Python "C:\ruta\python.exe" -VidPid "VID_XXXX&PID_YYYY"
```

## Solución de problemas

- **El botón sigue al revés / doble entrada:** el control real no quedó oculto. Ejecuta `ocultar_control.bat`, revisa `diagnostico.txt` y desenchufa/enchufa el control. Deben quedar ocultos el *"Controlador de Xbox 360 para Windows"* (clase `XnaComposite`) y sus hijos HID.
- **"No veo ningún control XInput":** el `python.exe` que ejecutas no está permitido en HidHide. Vuelve a correr `ocultar_control.bat`.
- **Steam invierte los botones otra vez:** desactiva *Parámetros → Mando → (tu control) → Usar disposición de botones de Nintendo*.

## Desinstalar

1. `mostrar_control.bat`
2. Desinstala *HidHide* y *ViGEmBus* desde *Aplicaciones y características*.

## Aviso

Usar controles virtuales (como hacen DS4Windows o reWASD) suele ser compatible con los juegos, pero **no se garantiza** con sistemas anticheat de juegos online. Úsalo bajo tu propia responsabilidad.

ViGEmBus está archivado por su autor; sigue funcionando pero ya no recibe actualizaciones.

## Créditos

- [ViGEmBus](https://github.com/nefarius/ViGEmBus) y [HidHide](https://github.com/nefarius/HidHide) — Nefarius Software Solutions
- [vgamepad](https://github.com/yannbouteiller/vgamepad) — Yann Bouteiller

## Licencia

[MIT](LICENSE)
