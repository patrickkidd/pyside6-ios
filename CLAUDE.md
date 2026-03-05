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

## Development Rules

- Always ensure that there is test coverage for new code.

## Development Commands

- **Virtual environment**: uv workspace. **Prepend `uv run`** to all python/pytest commands.
- **Environment File**: ./.env
- **GitHub CLI**: Use `GH_TOKEN=$(grep GITHUB_TOKEN .env | cut -d= -f2) gh ...` for all `gh` commands (PRs, issues, etc.)
