# SETUP.md

This document explains how to set up, build, test, and package Coding Cubed as an administrator or developer.

## Repository and Issue Tracker

- Source repository: [https://github.com/Mooshem/Software-Fungineers](https://github.com/Mooshem/Software-Fungineers)
- Issue tracker: [https://github.com/Mooshem/Software-Fungineers/issues](https://github.com/Mooshem/Software-Fungineers/issues)

## Prerequisites
- Godot `4.6.1` (or compatible `4.6.x`)
- Platform tools:
  - Windows: standard unzip + PowerShell
  - macOS: unzip + terminal

## 1) Clone and Open

1. Clone:
   - `git clone https://github.com/Mooshem/Software-Fungineers.git`
2. Enter project:
   - `cd Software-Fungineers/coding-cubed`
3. Open `coding-cubed` in Godot editor.

## 2) Local Run

- In Godot editor, press **Play**.
- Main scene is defined in `project.godot`.

## 3) Automated CI Build and Test

CI workflows are in `.github/workflows/`:

- Tests: `tests.yml`
- Export: `main.yml`

### Trigger via GitHub Actions UI

1. Open repository in GitHub.
2. Go to **Actions**.
3. Run:
   - `godot tests` (test workflow)
   - `godot-ci export` (export workflow)
4. Download artifacts from workflow run:
   - `windows`
   - `mac`

## 4) Test Instructions

### Full automated test suite (same pattern as CI)

From `coding-cubed/`:

- `godot --headless --import --quit`
- `godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -ginclude_subdirs -gexit`

## 5) Administrator Deployment Notes
- Current distribution is through downloadable artifacts and itch.io upload.
- CI upload target is configured in `.github/workflows/main.yml`.
- Required secret for automated itch upload:
  - `BUTLER_API_KEY`
