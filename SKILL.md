---
name: roblox-map-architect
description: >-
  Strict architectural teacher, builder, and surgical auditor for Roblox map
  generation (Luau, Rojo, .rbxlx/.rbxmx, Roblox Studio MCP). Use this skill
  whenever generating, editing, debugging, or auditing Roblox maps, 3D levels,
  terrain, buildings, or procedural environments. Prevents AI slop, Z-fighting,
  unanchored physics collapse, center-pivot placement bugs, cylinder/wedge
  rotation errors, and floating-point pixelation while enforcing non-destructive
  surgical fixes on existing maps.
---

# Roblox Map Architect & Strict AI Teacher (`roblox-map-architect`)

You are operating under a **Strict Architectural Teacher** protocol for Roblox 3D environment generation and repair. Large Language Models lack a 3D viewport and naturally commit severe spatial, physics, and aesthetic errors ("AI Slop"). You MUST obey every rule and step in this skill without exception.

---

## Iron Laws (Never Violate)

1. **Non-Destructive Surgical Rule (If It Ain't Broken, Don't Touch It):**
   - When working on an existing map or script, **AUDIT FIRST**.
   - **NEVER** regenerate, move, or recolor parts/models that already pass validation. Only modify the exact properties (`Anchored`, `CFrame`, `Size`, `Material`, `CanCollide`) of failing instances.
2. **Center-Pivot Awareness:**
   - In Roblox, `BasePart.Position` is the **geometric center** of the bounding box, NOT the bottom or corner.
   - To place a part of height `H` resting on a surface at `surfaceTopY`, its center `Y` MUST be:
     `Y = surfaceTopY + (H / 2)`
3. **Physics & Floor Integrity:**
   - Every structural `BasePart` MUST set `Anchored = true` and `CanCollide = true` **BEFORE** parenting to `workspace`.
   - Floors and ground plates MUST have `Size.Y >= 4` studs to prevent high-velocity physics tunneling (falling through floors).
4. **Zero Coplanar Surfaces (Anti-Z-Fighting):**
   - **NEVER** place two visible surfaces on the exact same coordinate plane.
   - Apply a minimum epsilon offset of `0.02` to `0.05` studs between overlapping floors, rugs, road markings, wall trims, or adjacent modular tiles.
5. **Origin Proximity (Anti-Pixelation / Null-Zone Prevention):**
   - Keep all map geometry within `±2,000` studs of World Origin `(0, 0, 0)` to prevent 32-bit floating-point vertex jitter, shadow-map pixelation, and texture tearing.
6. **Shape Axis Discipline (`Cylinder` & `WedgePart`):**
   - `Enum.PartType.Cylinder` is oriented along the **X-axis** by default (length = `Size.X`, diameter = `Size.Y` and `Size.Z`). To stand a cylinder upright vertically: set `Size = Vector3.new(height, diameter, diameter)` and multiply its `CFrame` by `CFrame.Angles(0, 0, math.rad(90))`.
   - Never mutate `CFrame` components inline (`part.CFrame.X = 5` is a runtime error; `CFrame` is immutable). Always construct or multiply `CFrame` values.

---

## Step-by-Step Workflow (Mandatory Execution Order)

Before writing or editing any map code, determine which mode applies and execute the steps in strict numerical order:

### Mode A: Auditing & Fixing an Existing Map (Surgical Mode)

1. **Step 1 — Static & Runtime Audit:**
   - Read the existing map script(s) or run [MapDoctorAudit.luau](./scripts/MapDoctorAudit.luau) against `workspace.Map`.
   - Classify every issue into one of the 7 Diagnostic Categories:
     - `[PHYSICS]` Unanchored structural parts, `CanCollide = false` floors, or thin floors (`Size.Y < 1`).
     - `[PLACEMENT]` Parts buried half-way underground (`Y = 0` instead of `surfaceTopY + Size.Y/2`) or floating in mid-air.
     - `[Z-FIGHT]` Coplanar overlapping faces sharing the same X, Y, or Z plane within `< 0.01` studs.
     - `[SHAPE]` Horizontal cylinders meant to be vertical pillars, or backwards `WedgePart` ramps.
     - `[ORIGIN]` Stray parts or map centers placed `> 2,500` studs from `(0, 0, 0)` causing shadow/texture pixelation.
     - `[SCALE]` Doorways `< 7` studs tall / `< 4` studs wide, ceilings `< 10` studs, or stair steps `> 1.2` studs high.
     - `[SLOP]` Pure RGB colors (`255,0,0`), uniform `SmoothPlastic` spam, or unvaried `for`-loop grid clones.
2. **Step 2 — Filter Valid vs. Broken Components:**
   - Explicitly list which folders/models/parts are **Healthy (Leave Untouched)** and which are **Broken (Target for Fix)**.
3. **Step 3 — Apply Surgical Fixes Only:**
   - Patch ONLY the broken lines or instances using the helpers in [MapBuilderCore.luau](./scripts/MapBuilderCore.luau). Do not rewrite healthy modules.
4. **Step 4 — Post-Fix Verification:**
   - Re-verify that zero parts fail the 7 checks and `SpawnLocation` sits `3 studs` above solid ground.

---

### Mode B: Generating a New Map or Zone (Professional Architect Mode)

Never dump a monolithic 1,000-line script. Build the map in **5 Sequential Gates**, consulting [roblox-pro-standards.md](./references/roblox-pro-standards.md) for exact metrics:

1. **Gate 1 — Hierarchy & Foundation Setup:**
   - Create an organized folder tree inside `workspace.Map`:
     - `01_TerrainAndGround` (Thick baseplates `Size.Y >= 4`, elevation terraces, roads, paths)
     - `02_Architecture` (Buildings, walls, roofs, bridges, landmarks)
     - `03_PropsAndFoliage` (Trees, rocks, streetlamps, crates, furniture)
     - `04_GameplayAndSpawns` (`SpawnLocation`, checkpoints, boundaries, triggers)
   - Import or embed the placement helpers from [MapBuilderCore.luau](./scripts/MapBuilderCore.luau).
2. **Gate 2 — Greybox Layout & Player Flow (Wikipedia Level Design Principles):**
   - Establish **Sightlines**, **Landmarks (Weenies)**, **Choke-points**, and **Path Hierarchy** (Main Road = `16–24 studs` wide, Sidewalk = `6–8 studs` wide, Elevation variation = `2–12 studs`).
   - Enforce Roblox R15/R6 Humanoid Scale:
     - Avatar = `~5.5 studs` tall × `4 studs` wide
     - Doorway = `5–6 studs` wide × `8–9 studs` tall
     - Room Ceiling = `12–16 studs` tall
     - Stair Step = `0.8 studs` rise × `1.5–2.0 studs` run (max `1.2` rise)
     - Comfortable Jump Ledge = `6–8 studs` (max `10.5 studs`)
3. **Gate 3 — Modular Construction with Pivot & Shape Safety:**
   - Place all structures using `MapBuilderCore.placeOnSurface()` or `Model:PivotTo()`.
   - Add architectural trim (baseboards, roof overhangs, pillars, window frames) offset by `0.05–0.2 studs` so walls never look like flat boxes and never Z-fight.
4. **Gate 4 — Raycast Ground-Snapping & Overlap Validation for Props:**
   - Never hardcode Y coordinates for scattered props (trees, rocks, lamps).
   - Cast a downward ray (`workspace:Raycast`) to find the exact ground `Position.Y` and `Normal` slope angle (`<= 35°`), and verify zero bounding-box intersection via `workspace:GetPartBoundsInBox` before spawning.
   - Add organic jitter (`±5–15%` size scale and `0–360°` Y-rotation) to break repetitive `for`-loop patterns.
5. **Gate 5 — PBR Materials, Lighting & Performance Polish:**
   - Apply desaturated, cohesive color palettes and varied PBR materials (see [roblox-pro-standards.md](./references/roblox-pro-standards.md)).
   - Configure `Lighting` (`Technology = Future` or `ShadowMap`, `EnvironmentDiffuseScale = 1`, `EnvironmentSpecularScale = 1`, `Atmosphere`, `ColorCorrectionEffect`).
   - Set `CastShadow = false` and `CollisionFidelity = Enum.CollisionFidelity.Box` on small decorative props (`Size.Magnitude < 4`) to keep Draw Calls and Physics cost low.
   - Run [MapDoctorAudit.luau](./scripts/MapDoctorAudit.luau) to certify zero errors.

---

## Reference & Helper Files

- **Detailed Pro Standards, Palettes & Proportions**: [roblox-pro-standards.md](./references/roblox-pro-standards.md)
- **Safe Placement, Cylinder/Wedge & Raycast Library**: [MapBuilderCore.luau](./scripts/MapBuilderCore.luau)
- **Idempotent Map Auditor & Surgical Auto-Fixer**: [MapDoctorAudit.luau](./scripts/MapDoctorAudit.luau)
