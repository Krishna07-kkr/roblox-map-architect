# `roblox-map-architect` — Strict AI Teacher Skill for Roblox Map Generation

A portable **Agent Skill** for **Claude Code**, **Google Antigravity**, **Cursor**, **Windsurf**, and any `SKILL.md`-compatible AI coding agent.

Designed to eliminate "AI Slop" and classic Roblox Luau map generation bugs:
- **Zero Falling Through Floors:** Enforces `Anchored = true`, `CanCollide = true` before parenting, and minimum floor thickness (`Size.Y >= 4` studs).
- **Center-Pivot Placement Math:** Enforces bottom-surface coordinate math (`Y = surfaceTopY + Size.Y / 2`) so walls and props never spawn half-buried underground.
- **Zero Z-Fighting & Pixelation:** Prevents coplanar surface flickering (`+0.03` epsilon offsets) and keeps builds inside the `±2,000` stud origin zone to prevent 32-bit floating-point shadow/texture pixelation.
- **Cylinder & Wedge Orientation Safety:** Automatically corrects Roblox's `Enum.PartType.Cylinder` X-axis orientation quirk (`Size = Vector3.new(height, diameter, diameter)` + `90° Z` rotation).
- **Non-Destructive Surgical Mode:** Audits existing maps first—leaves healthy parts 100% untouched and surgically patches only failing instances.

---

## Quick Install (For Any AI Agent or Terminal)

### 1. Claude Code (Global Install)
```bash
git clone https://github.com/Krishna07-kkr/roblox-map-architect.git ~/.claude/skills/roblox-map-architect
```
*(PowerShell on Windows)*:
```powershell
git clone https://github.com/Krishna07-kkr/roblox-map-architect.git "$HOME\.claude\skills\roblox-map-architect"
```

### 2. Google Antigravity / Gemini CLI (Global Install)
```powershell
git clone https://github.com/Krishna07-kkr/roblox-map-architect.git "$HOME\.gemini\config\skills\roblox-map-architect"
```

### 3. Project-Local Install (Works Across Cursor, Windsurf, Antigravity & Claude Code)
Run inside your Roblox / Rojo project root:
```bash
git clone https://github.com/Krishna07-kkr/roblox-map-architect.git .agents/skills/roblox-map-architect
```

---

## Repository Structure

```text
roblox-map-architect/
├── SKILL.md                             # Main Strict-Teacher instruction & 5-Gate workflow
├── README.md                            # Installation & usage guide
├── scripts/
│   ├── MapBuilderCore.luau              # Safe bottom-pivot placement, Cylinder/Wedge & Raycast library
│   └── MapDoctorAudit.luau              # Idempotent Surgical Auditor & Auto-Fixer for existing maps
└── references/
    └── roblox-pro-standards.md          # Humanoid scale table, 3-Layer Wall rules, PBR palettes & perf budget
```

---

## How to Trigger in Your AI Agent

Ask your agent:
> *"Use the `roblox-map-architect` skill in Mode A (Surgical Audit) to inspect and fix my map without touching healthy parts."*

or for a new build:
> *"Use the `roblox-map-architect` skill in Mode B (5-Gate Architect) to build a medieval harbor town map."*
