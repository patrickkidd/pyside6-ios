# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this project.

## Self-Learning Process

**AUTONOMOUS BY DEFAULT**: Commit knowledge to docs automatically. Only ask Patrick when: creating new files, deleting content, or genuinely unsure about categorization.

### Finding & Routing Documentation

1. Search `**/doc/*.md` for keywords
2. Only ask Patrick if genuinely missing

Each domain has ONE authoritative doc. Integrate knowledge there. If no doc exists, create one in `doc/` and add to this file's index.

### Correction Detection (MANDATORY)

Recognize corrections: "No, that's wrong...", "I already told you...", "Stop doing X", frustrated tone about repeated mistakes, "The actual way is...", any explanation of something you got wrong.

**Response protocol:**
1. Acknowledge briefly (no over-apologizing)
2. **BEFORE continuing**, update the relevant doc file
3. State: "Documented in [file] to prevent recurrence"
4. Continue with corrected approach

### Knowledge Capture

**Triggers**: Patrick explains how a subsystem works, behavioral rules/constraints, workflows, or why a decision was made. **Process**: Detect -> find authoritative doc -> integrate -> notify "Documented [X] in [file]"

### Decision Log

Maintain `decisions/log.md`. **Triggers**: "I've decided...", "I'm going to...", commits after weighing options, accepts/rejects opportunity, changes strategy/priorities. Write entry immediately, notify, ask only if missing critical context.

### Documentation Maintenance

- **Sync**: When modifying python, keep existing markdown in sync. Ask before creating new files, not before updating.
- **Workflows must be documented** with: step-by-step instructions, URLs/commands, data model relationships, query examples.
- **Archive** (ask first): Move to `archive/YYYY-MM-description.md`, add header, update refs, create replacement if needed.
- **Context optimization**: Prune redundant info autonomously. Lossless compression only -- ask before deleting substantive detail.
- **Feature doc progression**: brainstorming (`doc/brainstorming/`) -> vision (`doc/{FEATURE}_VISION.md`) -> as-built (`doc/asbuilts/`). Always update as-builts on notable changes. Consult as-builts before new implementations.

## Documentation Index

- `doc/pyside6-ios-solution.md` — Original project context: problem statement, solution architecture, and rationale for the QtRuntime.framework approach
- `doc/build-tool-reference.md` — Build tool config reference, commands, bundle layout, build phases
- `doc/porting-cookbook.md` — Step-by-step guide for porting an existing PySide6 app to iOS (QML or QtWidgets)
- `doc/initial-plan.md` — Milestone progression (M1–M6), key design decisions, risk register

## Cross-Compiled PySide6 Modules

Available in `build/pyside6-ios-static/`:
- QtCore, QtGui, QtWidgets, QtNetwork, QtQml, QtQuick

To add a new module, add a case to `scripts/build_pyside6_module.sh` and run it. iOS-specific patches may be needed (e.g., `setAsDockMenu` stripped from QtWidgets, DTLS stripped from QtNetwork).

## Demo Apps

- `test/test_pyside6/` — QML demo (QtCore + QtGui + QtNetwork + QtQml + QtQuick)
- `test/test_widgets/` — QtWidgets demo (QtCore + QtGui + QtWidgets)

Both exercise: custom C++ (Q_OBJECT + MOC), Obj-C++ (deviceinfo), shiboken6 bindings (AppState), Python virtual overrides, and the build tool. The QtWidgets demo requires a custom `main.mm` because the auto-generated template uses `QGuiApplication` (QML) rather than `QApplication` (widgets).

## Development Rules

- Always ensure that there is test coverage for new code.
- **Never commit or push** unless Patrick explicitly asks.

## Development Commands

- **Virtual environment**: uv workspace. **Prepend `uv run`** to all python/pytest commands.
- **Environment File**: ./.env
- **GitHub CLI**: Use `GH_TOKEN=$(grep GITHUB_TOKEN .env | cut -d= -f2) gh ...` for all `gh` commands (PRs, issues, etc.)
