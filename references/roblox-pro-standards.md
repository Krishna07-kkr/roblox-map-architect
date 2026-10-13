# Roblox Professional Map Design & Engineering Standards

This reference manual defines the mandatory scale, design, material, and optimization rules enforced by `roblox-map-architect`.

---

## 1. Roblox Humanoid Scale & Architectural Proportions

Standard Roblox R6/R15 avatars are **~5.0–5.5 studs tall** and **3.5–4.0 studs wide** (`1 stud ≈ 0.28 meters ≈ 11 inches`).

| Element | Minimum Studs | Recommended Pro Studs | Notes |
| :--- | :--- | :--- | :--- |
| **Ground / Baseplate Thickness** | `2.0` | `4.0 – 8.0` | Prevents physics tunneling when falling at terminal velocity. |
| **Single Doorway** | `4.0 W × 7.0 H` | `5.5 W × 8.5 H` | Prevents third-person camera clipping at the top frame. |
| **Double / Main Entrance** | `8.0 W × 8.5 H` | `10.0 W × 10.0 H` | Allows multiple players to pass simultaneously. |
| **Interior Room Ceiling** | `10.0 H` | `14.0 – 18.0 H` | Prevents third-person camera zoom clamp inside rooms. |
| **Hallway / Corridor Width** | `6.0 W` | `10.0 – 14.0 W` | Narrower hallways trap R15 characters and break NPC pathfinding. |
| **Stair Step (Rise × Run)** | `0.5 H × 1.5 D` | `0.8 H × 1.8 D` | **Hard Max Rise = `1.2 studs`**. Higher than `1.2` forces players to jump every step. |
| **Road / Street Width** | `14.0 W` | `20.0 – 28.0 W` | Plus `6.0 – 8.0 W` sidewalks raised by `0.5 – 0.75 studs` (curb). |
| **Standard Jump Ledge** | `4.0 H` | `6.0 – 8.0 H` | Default JumpPower (`50`) maxes out around `10.5 – 11.0 studs`. |
| **Guardrail / Fence Height** | `3.0 H` | `3.8 – 4.5 H` | Waist-to-chest height for R15 character safety. |

---

## 2. Anti-"AI Slop" Level Design Rules (Wikipedia & Industry Standards)

AI-generated maps look like "AI Slop" when they rely on 2D array loops, pure RGB colors, and featureless boxes. Follow these 6 structural rules:

1. **The 3-Layer Wall Rule (Never Build Flat Boxes):**
   - Every building facade must have depth across 3 layers:
     - **Layer 1 (Core Wall):** Main structural block (`Thickness = 1.0–1.5 studs`).
     - **Layer 2 (Framing & Pillars):** Corner pillars, roof overhangs (`+1.5 to 3.0 studs` outward), and foundation plinths/baseboards (`+0.15 studs` outward, `1.5–2.5 studs` tall).
     - **Layer 3 (Recessed/Extruded Details):** Window glass recessed `-0.1 studs` inward; window sills and lintels extruded `+0.2 studs` outward.
2. **Sightlines & "Weenies" (Visual Landmarks):**
   - Place at least 1 tall, distinct landmark (clocktower, lighthouse, central monument, giant tree, citadel) visible from spawn to orient players without UI arrows.
3. **Break Grid Monotony (Controlled Asymmetry):**
   - Never place >3 identical buildings or trees in a straight line with identical spacing and `0°` rotation.
   - Apply organic variation to nature props:
     - Rotation: `math.random(0, 359)` degrees on Y-axis, `math.random(-4, 4)` degrees tilt on X/Z.
     - Scale: `0.85x` to `1.25x` size multiplier.
4. **Elevation Hierarchy (Minimum 3 Heights):**
   - Every map must have at least 3 distinct vertical elevation tiers (e.g., `Y = 0` Lower Plaza/Waterfront, `Y = 6` Main Town Terrace connected by wide stairs/ramps, `Y = 16` Upper Overlook/Hill).
5. **Curbs & Border Transitions:**
   - Never let grass touch asphalt or wood touch stone on the exact same plane without a border curb, trim beam, or `0.2–0.6 stud` step change.
6. **Pathfinding & Flow Validation:**
   - Every doorway, stair, and bridge must have a continuous, unobstructed `6-stud-wide` clearance path from `SpawnLocation`.

---

## 3. Professional Color & Material Palettes (No Pure RGB Slop)

**FORBIDDEN COLORS:** `Color3.fromRGB(255, 0, 0)`, `(0, 255, 0)`, `(0, 0, 255)`, `(255, 255, 0)`, `(255, 0, 255)`. Always keep saturation below `65%` and value between `15%` and `90%`.

| Surface Type | Recommended `Enum.Material` | Recommended `Color3.fromRGB(...)` Palette |
| :--- | :--- | :--- |
| **Grass / Meadow** | `Grass` or `LeafyGrass` | `(75, 118, 68)`, `(86, 130, 74)`, `(64, 102, 58)` |
| **Stone / Cliff / Rock** | `Slate` or `Basalt` or `Rock` | `(95, 98, 104)`, `(112, 110, 106)`, `(78, 80, 85)` |
| **Road / Asphalt** | `Asphalt` or `Concrete` | `(52, 54, 58)` with `(215, 205, 175)` markings (`+0.03` Y offset) |
| **Sidewalk / Plaza Stone** | `Cobblestone` or `Pavement` | `(148, 146, 142)`, `(165, 160, 154)` |
| **Warm Plaster / Stucco Wall** | `Concrete` or `Limestone` | `(226, 214, 198)`, `(212, 196, 176)`, `(234, 226, 214)` |
| **Brick / Masonry** | `Brick` or `Sandstone` | `(156, 88, 74)`, `(142, 78, 66)`, `(178, 132, 104)` |
| **Timber / Wood Trim** | `Wood` or `WoodPlanks` | `(104, 74, 52)`, `(128, 92, 64)`, `(78, 54, 38)` |
| **Roof Tiles / Metal Roof** | `Slate` or `CorrugatedMetal` | `(62, 72, 84)`, `(138, 72, 58)`, `(54, 58, 62)` |
| **Foliage / Tree Leaves** | `Grass` or `Fabric` | `(62, 108, 64)`, `(78, 124, 72)`, `(188, 118, 58)` (Autumn) |
| **Water / Glass** | `Glass` (`Transparency = 0.35–0.6`) | `(88, 142, 168)`, `(140, 185, 210)` |

---

## 4. Performance, Streaming & Rendering Budget

1. **Shadow Budget (`CastShadow`):**
   - Set `CastShadow = false` on all small props (`Size.Magnitude < 4`), foliage leaves, road stripes, and indoor ceiling trims.
2. **Collision Budget (`CanCollide`, `CanQuery`, `CanTouch`):**
   - For non-reachable visual details (roof shingles, high beams, small pebbles, grass blades, wall trims `< 0.3 studs`):
     ```lua
     part.CanCollide = false
     part.CanQuery = false
     part.CanTouch = false
     ```
3. **Mesh & Union Discipline:**
   - On `MeshPart` and `UnionOperation` props, set `CollisionFidelity = Enum.CollisionFidelity.Box` (or `Hull` for large rocks/pillars). Never leave `PreciseConvexDecomposition` on decorative assets.
4. **World Origin & Streaming:**
   - Keep map bounds within `[-2000, +2000]` on X and Z, and `[-200, +800]` on Y.
   - For maps larger than `1000 × 1000` studs, enable `Workspace.StreamingEnabled = true` (`StreamingMinRadius = 128`, `StreamingTargetRadius = 512`).
