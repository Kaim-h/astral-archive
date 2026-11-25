# Environment and runtime assumptions

This file records the **intended** environment and integration assumptions from project documentation and the November 17 handoff. It is not a claim that the target machine has been inspected or that these dependencies are installed. Confirm actual versions and capabilities on the machine before native development.

## Intended desktop foundation

| Layer | Intended role | Evidence / caution |
|---|---|---|
| Fedora Linux | Target distribution in the handoff | The exact installed release is not recorded in this snapshot. |
| KDE Plasma | Retained fallback / repair session | Do not compromise this recovery path during shell experiments. |
| Hyprland | Wayland compositor, window placement, tiling and workspaces | Do not build a replacement window manager. Verify version and config format. |
| Quickshell | Shell process and panel/window composition | Source initially targeted v0.3.1 APIs. Verify actual `qs --version`. |
| Qt Quick / QML | UI, component and state layer | Verify imports with the installed Qt / Quickshell build. |
| JavaScript | Pure policy/model logic and offline checks | Node tests do not exercise the QML engine. |
| Qt Shader Tools (`qsb`) | Compile GLSL fragment sources into `.qsb` | Shader compilation must be performed in the target environment. Generated `.qsb` files are not normally committed. |

## External integrations referenced by source

- Hyprland APIs: toplevels, active window, workspaces, dispatch and global shortcuts.
- Quickshell desktop-entry APIs for application discovery and launching.
- PipeWire for audio volume / mute.
- UPower for battery availability / percentage.
- NetworkManager for Wi-Fi radio state.
- BlueZ for Bluetooth adapter state.
- `brightnessctl` for backlight where supported by hardware.
- `awww` / `awww-daemon` for wallpaper changes.
- MPRIS-compatible media players for Gallery music controls.
- KDE `systemsettings` as an ordinary settings fallback.

Availability is build- and machine-dependent. A missing optional Quickshell module may fail QML import before a visual fallback can run; validate modules in a small native test before enabling autostart.

## Native bring-up safety

- Keep Plasma and a working TTY / terminal recovery route available.
- Launch the shell manually from a terminal first: `qs -p quickshell/shell.qml` (after confirming the command and flags for the installed version).
- Check free Hyprland bindings before adding the global shortcut binds declared in `quickshell/shell.qml`.
- Compile required shaders with the repository scripts and `qsb`; record compile output.
- Capture exact QML errors and the first relevant runtime error, not only screenshots.
- Validate focus, popup anchoring, monitor scale, multi-monitor behavior, service availability, battery reporting, wallpaper backend, MPRIS, shader fallbacks and performance separately.
- Do not enable autostart until manual launch and a recovery route are reliable.

## Machine-specific information to record later

The following are intentionally not invented in this document. Fill them in from the actual target machine:

- Fedora release / kernel:
- GPU and driver:
- Hyprland version / config format:
- Quickshell version / build features:
- Qt version and QML import availability:
- Screen resolution / scaling / monitor layout:
- PipeWire / WirePlumber status:
- UPower battery values and scale:
- NetworkManager / BlueZ status:
- `brightnessctl` devices:
- `awww` version / daemon status:
- `qsb` version:
- MPRIS test player:
- Native bring-up date and validation result:

## Native validation status

Native validation in the intended Fedora Linux, Hyprland and Quickshell environment remains outstanding.

Development and preliminary verification can proceed through static analysis, JavaScript logic tests, browser-based studies and offscreen Qt Quick testing. These checks provide useful implementation evidence but do not establish compatibility with the target desktop environment.

Before production integration, validate compositor behavior, QML imports, shader rendering, input and focus handling, display scaling, system service integrations, performance and recovery procedures in an appropriate native environment.

Retain KDE Plasma and a working terminal recovery path throughout native bring-up. Production integration and autostart remain subject to successful native validation.
