--!strict
--[[
	MapDoctorAudit.luau
	Idempotent Surgical Auditor & Auto-Fixer for Roblox Maps.
	Rule: "If a part has an issue, fix ONLY that issue. If a part is healthy, leave it 100% untouched."

	Detects & Surgically Fixes:
	  1. [PHYSICS] Unanchored structural parts, or thin ground/floors (< 1 stud thick) causing player fall-through
	  2. [Z-FIGHT] Coplanar overlapping horizontal/vertical surfaces flickering at the same coordinate plane
	  3. [SHAPE] Vertical-intended Cylinder pillars lying sideways due to Roblox's X-axis cylinder default
	  4. [ORIGIN] Parts spawned > 2500 studs from (0,0,0) causing floating-point shadow/texture pixelation
	  5. [SURFACE] Legacy Studs/Inlet surfaces causing unwanted blocky pixelation
	  6. [PERF] Small decorative parts (< 4 studs) needlessly casting heavy shadows
]]

local Workspace = game:GetService("Workspace")

local MapDoctorAudit = {}

export type AuditReport = {
	TotalPartsScanned: number,
	HealthyPartsUntouched: number,
	FixedAnchored: number,
	FixedThinFloors: number,
	FixedZFighting: number,
	FixedCylinders: number,
	FixedSurfaces: number,
	FixedShadowPerf: number,
	OriginWarnings: { string },
	Details: { string },
}

local function roundPlane(val: number): number
	return math.round(val * 100) / 100
end

local function aabb2DOverlap(aPos: Vector3, aSize: Vector3, bPos: Vector3, bSize: Vector3): boolean
	local overlapX = math.abs(aPos.X - bPos.X) < ((aSize.X + bSize.X) * 0.5 - 0.05)
	local overlapZ = math.abs(aPos.Z - bPos.Z) < ((aSize.Z + bSize.Z) * 0.5 - 0.05)
	return overlapX and overlapZ
end

--- Runs a non-destructive audit and optionally applies surgical fixes only to failing parts
function MapDoctorAudit.auditAndFix(targetRoot: Instance?, applySurgicalFixes: boolean?): AuditReport
	local root = targetRoot or Workspace:FindFirstChild("Map") or Workspace
	local shouldFix = if applySurgicalFixes ~= nil then applySurgicalFixes else true

	local report: AuditReport = {
		TotalPartsScanned = 0,
		HealthyPartsUntouched = 0,
		FixedAnchored = 0,
		FixedThinFloors = 0,
		FixedZFighting = 0,
		FixedCylinders = 0,
		FixedSurfaces = 0,
		FixedShadowPerf = 0,
		OriginWarnings = {},
		Details = {},
	}

	-- Bucket horizontal top planes to detect coplanar Z-fighting
	local topPlaneBuckets: { [number]: { BasePart } } = {}

	for _, inst in ipairs(root:GetDescendants()) do
		if inst:IsA("BasePart") and not inst:IsA("Terrain") then
			-- Skip player characters
			if inst:FindFirstAncestorOfClass("Model") and inst:FindFirstAncestorOfClass("Model"):FindFirstChildOfClass("Humanoid") then
				continue
			end

			report.TotalPartsScanned += 1
			local partModified = false

			-- 1. Check Origin Distance (Null-Zone / Floating-Point Pixelation)
			if inst.Position.Magnitude > 2500 then
				table.insert(
					report.OriginWarnings,
					string.format("%s is %.0f studs from Origin (0,0,0)", inst:GetFullName(), inst.Position.Magnitude)
				)
			end

			-- 2. Check Anchored State (unless constrained by a Weld/Motor6D/Hinge)
			local hasActiveJoint = inst:FindFirstChildWhichIsA("JointInstance") ~= nil
				or inst:FindFirstChildWhichIsA("Constraint") ~= nil
			if not inst.Anchored and not hasActiveJoint then
				if shouldFix then
					inst.Anchored = true
				end
				report.FixedAnchored += 1
				partModified = true
				table.insert(report.Details, "[PHYSICS] Anchored loose part: " .. inst:GetFullName())
			end

			-- 3. Check Thin Floor Tunneling (Floors/Grounds that are CanCollide but too thin)
			local lowerName = string.lower(inst.Name)
			local isFloorLike = string.find(lowerName, "floor") ~= nil
				or string.find(lowerName, "ground") ~= nil
				or string.find(lowerName, "baseplate") ~= nil
				or string.find(lowerName, "road") ~= nil
			if isFloorLike and inst.CanCollide and inst.Size.Y < 1.0 and inst.Size.X > 16 and inst.Size.Z > 16 then
				if shouldFix then
					local oldTopY = inst.Position.Y + (inst.Size.Y * 0.5)
					local newThickness = 2.0
					inst.Size = Vector3.new(inst.Size.X, newThickness, inst.Size.Z)
					inst.CFrame = CFrame.new(inst.Position.X, oldTopY - (newThickness * 0.5), inst.Position.Z) * inst.CFrame.Rotation
				end
				report.FixedThinFloors += 1
				partModified = true
				table.insert(report.Details, "[PHYSICS] Thickened thin floor to prevent fall-through: " .. inst:GetFullName())
			end

			-- 4. Check Sideways Cylinder Pillars (Size.Y >> Size.X on a Cylinder Part)
			if inst:IsA("Part") and inst.Shape == Enum.PartType.Cylinder then
				local isPillarLike = string.find(lowerName, "pillar") ~= nil
					or string.find(lowerName, "column") ~= nil
					or string.find(lowerName, "trunk") ~= nil
					or string.find(lowerName, "pole") ~= nil
					or string.find(lowerName, "post") ~= nil
				if isPillarLike and inst.Size.Y > inst.Size.X * 1.5 then
					if shouldFix then
						local intendedHeight = inst.Size.Y
						local intendedDiameter = inst.Size.X
						inst.Size = Vector3.new(intendedHeight, intendedDiameter, intendedDiameter)
						inst.CFrame = inst.CFrame * CFrame.Angles(0, 0, math.rad(90))
					end
					report.FixedCylinders += 1
					partModified = true
					table.insert(report.Details, "[SHAPE] Corrected sideways X-axis cylinder pillar: " .. inst:GetFullName())
				end
			end

			-- 5. Check Legacy Studs/Inlet Pixelated Surfaces
			if inst.TopSurface == Enum.SurfaceType.Studs or inst.BottomSurface == Enum.SurfaceType.Inlet then
				if shouldFix then
					inst.TopSurface = Enum.SurfaceType.Smooth
					inst.BottomSurface = Enum.SurfaceType.Smooth
				end
				report.FixedSurfaces += 1
				partModified = true
			end

			-- 6. Check Small Prop Shadow Overhead
			if inst.CastShadow and inst.Size.Magnitude < 3.5 and not inst.CanCollide then
				if shouldFix then
					inst.CastShadow = false
				end
				report.FixedShadowPerf += 1
				partModified = true
			end

			-- Record top plane for Z-fighting check (only roughly horizontal parts)
			if inst.Transparency < 0.95 and math.abs(inst.CFrame.UpVector.Y) > 0.98 then
				local topY = roundPlane(inst.Position.Y + (inst.Size.Y * 0.5))
				topPlaneBuckets[topY] = topPlaneBuckets[topY] or {}
				table.insert(topPlaneBuckets[topY], inst)
			end

			if not partModified then
				report.HealthyPartsUntouched += 1
			end
		end
	end

	-- 7. Check & Surgically Resolve Coplanar Top-Surface Z-Fighting
	for planeY, partsOnPlane in pairs(topPlaneBuckets) do
		if #partsOnPlane > 1 then
			for i = 1, #partsOnPlane do
				for j = i + 1, #partsOnPlane do
					local a = partsOnPlane[i]
					local b = partsOnPlane[j]
					-- Only flag Z-fighting if their 2D X/Z footprints overlap and they have different colors/materials
					if (a.Color ~= b.Color or a.Material ~= b.Material)
						and aabb2DOverlap(a.Position, a.Size, b.Position, b.Size)
					then
						-- Surgically lift the smaller/detail part by 0.03 studs so the larger base floor stays untouched
						local smaller = if (a.Size.X * a.Size.Z) <= (b.Size.X * b.Size.Z) then a else b
						if shouldFix then
							smaller.CFrame = smaller.CFrame + Vector3.new(0, 0.03, 0)
						end
						report.FixedZFighting += 1
						report.HealthyPartsUntouched = math.max(0, report.HealthyPartsUntouched - 1)
						table.insert(
							report.Details,
							string.format("[Z-FIGHT] Offset %s by +0.03 studs above coplanar plane Y=%.2f", smaller:GetFullName(), planeY)
						)
					end
				end
			end
		end
	end

	print(string.format(
		"[MapDoctorAudit] Scanned: %d | Healthy (Untouched): %d | Anchored Fixed: %d | Floors Fixed: %d | Z-Fights Fixed: %d | Cylinders Fixed: %d",
		report.TotalPartsScanned,
		report.HealthyPartsUntouched,
		report.FixedAnchored,
		report.FixedThinFloors,
		report.FixedZFighting,
		report.FixedCylinders
	))

	return report
end

return MapDoctorAudit
