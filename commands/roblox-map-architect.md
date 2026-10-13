---
description: Strict AI Teacher & Surgical Auditor for Roblox Map Generation. Fixes Z-fighting, unanchored parts, center-pivot placement bugs, and AI slop without touching healthy map parts.
argument-hint: "[audit | build | fix] <target script or map description>"
---

Activate and strictly follow the **`roblox-map-architect`** skill (`SKILL.md`, `references/roblox-pro-standards.md`, `scripts/MapBuilderCore.luau`, `scripts/MapDoctorAudit.luau`).

User Task / Arguments: $ARGUMENTS

### Mandatory Execution Rules:
1. **Non-Destructive Surgical Rule (If Editing/Fixing Existing Map):**
   - Audit first against the 7 Diagnostic Checks (`[PHYSICS]`, `[PLACEMENT]`, `[Z-FIGHT]`, `[SHAPE]`, `[ORIGIN]`, `[SCALE]`, `[SLOP]`).
   - **Leave all healthy parts/models 100% untouched.** Only patch the broken properties (`Anchored`, `CFrame`, `Size`, `CanCollide`, epsilon offsets).
2. **Center-Pivot & Shape Math:**
   - `Part.Position` is the **center**, never the bottom corner. Bottom-aligned placement MUST use: `Y = surfaceTopY + (part.Size.Y / 2)`.
   - `Enum.PartType.Cylinder` has its length along the **X-axis**. For vertical pillars of height `H` and diameter `D`, use `Size = Vector3.new(H, D, D)` and multiply `CFrame` by `CFrame.Angles(0, 0, math.rad(90))`.
3. **Zero Z-Fighting & Origin Safety:**
   - Never place two surfaces on the exact same coordinate plane; offset overlapping rugs, roads, and trims by `+0.03` studs.
   - Keep all coordinates within `±2,000` studs of `(0, 0, 0)` to prevent floating-point shadow/texture pixelation.
4. **5-Gate Architecture (If Building New Map):**
   - Execute sequentially: Gate 1 (`01_TerrainAndGround` .. `04_GameplayAndSpawns` hierarchy) $\rightarrow$ Gate 2 (Greybox + R15 Scale: Doors `5.5×8.5`, Ceilings `14+`, Steps `<= 1.2`) $\rightarrow$ Gate 3 (3-Layer Walls & Trim) $\rightarrow$ Gate 4 (Downward `Raycast` + `GetPartBoundsInBox` prop placement) $\rightarrow$ Gate 5 (Desaturated PBR Palette + `Future`/`ShadowMap` Lighting + `MapDoctorAudit`).
