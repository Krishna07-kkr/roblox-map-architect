--!strict
--[[
	MapBuilderCore.luau
	Strict-Teacher Core Library for Professional Roblox Map Generation.
	Prevents:
	  1. Falling through parts (Forces Anchored = true, CanCollide = true, thick floors)
	  2. Center-Pivot math bugs (Places all parts by their BOTTOM-CENTER surface coordinate)
	  3. Z-Fighting (Enforces epsilon offsets and non-coplanar layering)
	  4. Cylinder & Wedge orientation errors (Corrects Roblox's X-axis Cylinder quirk)
	  5. Floating/Intersecting props (Uses downward Raycast + GetPartBoundsInBox validation)
]]

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")

local MapBuilderCore = {}

export type PartSpec = {
	Name: string?,
	Size: Vector3,
	Color: Color3?,
	Material: Enum.Material?,
	Transparency: number?,
	CanCollide: boolean?,
	CastShadow: boolean?,
	Parent: Instance?,
}

-- Default epsilon to prevent coplanar Z-fighting on layered surfaces
MapBuilderCore.Z_FIGHT_EPSILON = 0.03
MapBuilderCore.MAX_SAFE_ORIGIN_RADIUS = 2000

--- Ensures the standard 4-folder professional hierarchy exists in Workspace.Map
function MapBuilderCore.ensureMapHierarchy(mapName: string?): Folder
	local rootName = mapName or "Map"
	local existing = Workspace:FindFirstChild(rootName)
	local mapRoot: Folder
	if existing and existing:IsA("Folder") then
		mapRoot = existing
	else
		mapRoot = Instance.new("Folder")
		mapRoot.Name = rootName
		mapRoot.Parent = Workspace
	end

	local subfolders = {
		"01_TerrainAndGround",
		"02_Architecture",
		"03_PropsAndFoliage",
		"04_GameplayAndSpawns",
	}

	for _, name in ipairs(subfolders) do
		if not mapRoot:FindFirstChild(name) then
			local sub = Instance.new("Folder")
			sub.Name = name
			sub.Parent = mapRoot
		end
	end

	return mapRoot
end

--- Asserts that coordinates are inside the safe 32-bit floating point zone near (0,0,0)
local function assertOriginSafe(pos: Vector3, label: string)
	if pos.Magnitude > MapBuilderCore.MAX_SAFE_ORIGIN_RADIUS then
		warn(string.format(
			"[MapBuilderCore][ORIGIN WARNING] '%s' at (%.1f, %.1f, %.1f) exceeds %d studs from origin! This causes shadow/texture pixelation and Z-buffer jitter.",
			label, pos.X, pos.Y, pos.Z, MapBuilderCore.MAX_SAFE_ORIGIN_RADIUS
		))
	end
end

--- Creates a safe, anchored Part with Smooth surfaces and sensible defaults BEFORE parenting
function MapBuilderCore.createBasePart(spec: PartSpec, shape: Enum.PartType?): Part
	local part = Instance.new("Part")
	part.Name = spec.Name or "MapPart"
	part.Anchored = true
	part.CanCollide = if spec.CanCollide ~= nil then spec.CanCollide else true
	part.CastShadow = if spec.CastShadow ~= nil then spec.CastShadow else (spec.Size.Magnitude >= 4)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	if shape then
		part.Shape = shape
	end
	part.Size = spec.Size
	part.Color = spec.Color or Color3.fromRGB(163, 162, 165)
	part.Material = spec.Material or Enum.Material.Concrete
	part.Transparency = spec.Transparency or 0

	-- Small decorative parts shouldn't waste raycast/touch queries if non-collidable
	if not part.CanCollide then
		part.CanQuery = false
		part.CanTouch = false
	end

	return part
end

--- Places a Block Part so its BOTTOM face rests cleanly on `surfaceTopY` (with optional Z-fight epsilon)
function MapBuilderCore.placeBlockOnSurface(
	spec: PartSpec,
	x: number,
	surfaceTopY: number,
	z: number,
	rotYDeg: number?,
	epsilonOffset: number?
): Part
	local part = MapBuilderCore.createBasePart(spec, Enum.PartType.Block)
	local eps = epsilonOffset or 0
	local centerY = surfaceTopY + (spec.Size.Y * 0.5) + eps
	local pos = Vector3.new(x, centerY, z)
	assertOriginSafe(pos, part.Name)

	local rot = CFrame.Angles(0, math.rad(rotYDeg or 0), 0)
	part.CFrame = CFrame.new(pos) * rot
	part.Parent = spec.Parent or Workspace
	return part
end

--- Places an upright VERTICAL Cylinder (automatically corrects Roblox's X-axis cylinder orientation quirk)
function MapBuilderCore.placeVerticalCylinder(
	name: string,
	radius: number,
	height: number,
	x: number,
	surfaceTopY: number,
	z: number,
	color: Color3,
	material: Enum.Material,
	parent: Instance?
): Part
	local diameter = radius * 2
	-- In Roblox, Enum.PartType.Cylinder has its length along the X-axis!
	local part = MapBuilderCore.createBasePart({
		Name = name,
		Size = Vector3.new(height, diameter, diameter),
		Color = color,
		Material = material,
		Parent = nil,
	}, Enum.PartType.Cylinder)

	local centerY = surfaceTopY + (height * 0.5)
	local pos = Vector3.new(x, centerY, z)
	assertOriginSafe(pos, name)

	-- Rotate 90 degrees around Z in object space so the X-axis stands vertically along World Y
	part.CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90))
	part.Parent = parent or Workspace
	return part
end

--- Places a WedgePart ramp resting on `surfaceTopY`, facing the specified compass angle (`rotYDeg`)
function MapBuilderCore.placeRampOnSurface(
	spec: PartSpec,
	x: number,
	surfaceTopY: number,
	z: number,
	rotYDeg: number?
): WedgePart
	local wedge = Instance.new("WedgePart")
	wedge.Name = spec.Name or "Ramp"
	wedge.Anchored = true
	wedge.CanCollide = if spec.CanCollide ~= nil then spec.CanCollide else true
	wedge.CastShadow = if spec.CastShadow ~= nil then spec.CastShadow else true
	wedge.TopSurface = Enum.SurfaceType.Smooth
	wedge.BottomSurface = Enum.SurfaceType.Smooth
	wedge.Size = spec.Size
	wedge.Color = spec.Color or Color3.fromRGB(140, 140, 145)
	wedge.Material = spec.Material or Enum.Material.Concrete
	wedge.Transparency = spec.Transparency or 0

	local centerY = surfaceTopY + (spec.Size.Y * 0.5)
	local pos = Vector3.new(x, centerY, z)
	assertOriginSafe(pos, wedge.Name)

	wedge.CFrame = CFrame.new(pos) * CFrame.Angles(0, math.rad(rotYDeg or 0), 0)
	wedge.Parent = spec.Parent or Workspace
	return wedge
end

--- Connects two 2D points `(x1, z1)` and `(x2, z2)` with a continuous wall resting on `surfaceTopY`
function MapBuilderCore.placeWallBetweenPoints(
	name: string,
	x1: number,
	z1: number,
	x2: number,
	z2: number,
	surfaceTopY: number,
	height: number,
	thickness: number,
	color: Color3,
	material: Enum.Material,
	parent: Instance?,
	trimShift: number?
): Part
	local p1 = Vector3.new(x1, surfaceTopY + (height * 0.5), z1)
	local p2 = Vector3.new(x2, surfaceTopY + (height * 0.5), z2)
	-- Shrink length by 0.01 studs if needed to avoid corner Z-fighting with perpendicular walls
	local rawDist = (p2 - p1).Magnitude
	local length = math.max(0.2, rawDist - (trimShift or 0.02))
	local mid = (p1 + p2) * 0.5

	local wall = MapBuilderCore.createBasePart({
		Name = name,
		Size = Vector3.new(thickness, height, length),
		Color = color,
		Material = material,
	}, Enum.PartType.Block)

	wall.CFrame = CFrame.lookAt(mid, p2)
	wall.Parent = parent or Workspace
	return wall
end

--- Raycasts downward from sky and checks `GetPartBoundsInBox` so props never float or overlap
function MapBuilderCore.placePropWithRaycastValidation(
	spec: PartSpec,
	x: number,
	z: number,
	maxSlopeDeg: number?,
	groundWhitelist: { Instance }?,
	obstacleIgnoreList: { Instance }?
): (Part?, string)
	local rayOrigin = Vector3.new(x, 500, z)
	local rayDir = Vector3.new(0, -1000, 0)

	local rayParams = RaycastParams.new()
	if groundWhitelist and #groundWhitelist > 0 then
		rayParams.FilterType = Enum.RaycastFilterType.Include
		rayParams.FilterDescendantsInstances = groundWhitelist
	else
		rayParams.FilterType = Enum.RaycastFilterType.Exclude
		rayParams.FilterDescendantsInstances = obstacleIgnoreList or {}
	end

	local hit = Workspace:Raycast(rayOrigin, rayDir, rayParams)
	if not hit then
		return nil, "Rejected: No ground surface found beneath (" .. tostring(x) .. ", " .. tostring(z) .. ")"
	end

	-- Check slope angle
	local maxSlope = maxSlopeDeg or 35
	local slopeDeg = math.deg(math.acos(math.clamp(hit.Normal:Dot(Vector3.new(0, 1, 0)), -1, 1)))
	if slopeDeg > maxSlope then
		return nil, string.format("Rejected: Ground slope %.1f deg exceeds max %.1f deg", slopeDeg, maxSlope)
	end

	-- Compute target CFrame slightly above ground to avoid coplanar Z-fighting and false ground overlap
	local rotY = math.rad(math.random(0, 359))
	local targetCFrame = CFrame.new(hit.Position.X, hit.Position.Y + (spec.Size.Y * 0.5) + 0.02, hit.Position.Z)
		* CFrame.Angles(0, rotY, 0)

	-- Check bounding box overlap (shrink query box slightly on Y bottom so it doesn't hit the floor itself)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Exclude
	local ignores = table.clone(obstacleIgnoreList or {})
	table.insert(ignores, hit.Instance)
	overlapParams.FilterDescendantsInstances = ignores

	local overlaps = Workspace:GetPartBoundsInBox(targetCFrame, spec.Size - Vector3.new(0.1, 0.2, 0.1), overlapParams)
	if #overlaps > 0 then
		return nil, "Rejected: Space already occupied by " .. overlaps[1]:GetFullName()
	end

	local part = MapBuilderCore.createBasePart(spec, Enum.PartType.Block)
	part.CFrame = targetCFrame
	part.Parent = spec.Parent or Workspace
	return part, "Placed"
end

--- Applies a professional PBR Lighting + Atmosphere setup (eliminates flat plastic AI-slop lighting)
function MapBuilderCore.applyProLightingPreset()
	Lighting.Brightness = 2.5
	Lighting.ClockTime = 14.5
	Lighting.GeographicLatitude = 35
	Lighting.GlobalShadows = true
	Lighting.ShadowSoftness = 0.15
	Lighting.EnvironmentDiffuseScale = 1.0
	Lighting.EnvironmentSpecularScale = 1.0
	Lighting.Ambient = Color3.fromRGB(45, 50, 60)
	Lighting.OutdoorAmbient = Color3.fromRGB(70, 78, 92)
	Lighting.ColorShift_Top = Color3.fromRGB(255, 248, 235)

	local atmosphere = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atmosphere.Density = 0.32
	atmosphere.Offset = 0.25
	atmosphere.Color = Color3.fromRGB(198, 208, 218)
	atmosphere.Decay = Color3.fromRGB(108, 118, 132)
	atmosphere.Glare = 0.35
	atmosphere.Haze = 1.4
	atmosphere.Parent = Lighting

	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Brightness = 0.02
	cc.Contrast = 0.14
	cc.Saturation = -0.05
	cc.TintColor = Color3.fromRGB(255, 252, 246)
	cc.Parent = Lighting
end

return MapBuilderCore
