# INSTALL.md

## Product URL (Installed Solution)

- Live download page: [https://tehlamo.itch.io/coding-cubed](https://tehlamo.itch.io/coding-cubed)

## Supported Platforms

- Windows 10/11 (x64)
- macOS (Apple Silicon or Intel)

## Minimum Requirements

- 4 GB RAM
- Integrated graphics or better
- Keyboard + mouse

## Option A: Install Prebuilt Binary (Recommended)

### Windows

1. Open [https://tehlamo.itch.io/coding-cubed](https://tehlamo.itch.io/coding-cubed).
2. Download the Windows package (for example `coding-cubed-windows.zip`).
3. Extract the zip file.
4. Open the extracted folder and run `Coding Cubed.exe`.
5. If SmartScreen appears, click **More info** -> **Run anyway**.

### macOS

1. Open [https://tehlamo.itch.io/coding-cubed](https://tehlamo.itch.io/coding-cubed).
2. Download the macOS package (for example `Coding Cubed.zip`).
3. Extract the zip file.
4. Open the app bundle.
5. If Gatekeeper blocks launch:
   - Right-click the app -> **Open** -> **Open**.
   - Or go to **System Settings -> Privacy & Security** and allow launch.

## Option B: Run From Source

Prerequisites:

- Godot Engine `4.6.1` (or `4.6.x`) [https://godotengine.org/]
- Git [https://git-scm.com/install/windows]

Steps:

1. Clone repository:
   - `git clone https://github.com/Mooshem/Software-Fungineers.git`
2. Open Godot.
3. Import project folder:
   - `Software-Fungineers/coding-cubed`
4. Open the project and press **Play**.

## Controls

- Move: `W A S D`
- Jump: `Space`
- Run: `Shift`
- Place block: `Right Mouse Button`
- Break block (hold): `Left Mouse Button`
- Pause/Menu: `Esc`
- Interact with blocks: `I`

## Known Issues

- Known issues are tracked in GitHub Issues:
  - [https://github.com/Mooshem/Software-Fungineers/issues](https://github.com/Mooshem/Software-Fungineers/issues)

## Troubleshooting

- Game does not launch on macOS:
  - Use right-click **Open** for first launch.
- Black screen or severe lag:
  - Update GPU drivers and close other heavy apps.
- No audio:
  - Check in-game settings and system output device/volume.
