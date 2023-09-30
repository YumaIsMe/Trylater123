if getgenv().Aiming then return getgenv().Aiming end


local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")


local Heartbeat = RunService.Heartbeat
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()


local Drawingnew = Drawing.new
local Color3fromRGB = Color3.fromRGB
local Vector2new = Vector2.new
local GetGuiInset = GuiService.GetGuiInset
local Randomnew = Random.new
local mathfloor = math.floor
local CharacterAdded = LocalPlayer.CharacterAdded
local CharacterAddedWait = CharacterAdded.Wait
local WorldToViewportPoint = CurrentCamera.WorldToViewportPoint
local RaycastParamsnew = RaycastParams.new
local EnumRaycastFilterTypeBlacklist = Enum.RaycastFilterType.Blacklist
local Raycast = Workspace.Raycast
local GetPlayers = Players.GetPlayers
local Instancenew = Instance.new
local IsDescendantOf = Instancenew("Part").IsDescendantOf
local FindFirstChildWhichIsA = Instancenew("Part").FindFirstChildWhichIsA
local FindFirstChild = Instancenew("Part").FindFirstChild
local tableremove = table.remove
local tableinsert = table.insert


getgenv().Aiming = {
	Enabled = true,

	ShowFOV = true,
	FOV = 60,
	FOVSides = 60,
	FOVColour = Color3fromRGB(0, 200, 200),

	VisibleCheck = true,

	HitChance = 100,

	Selected = nil,
	SelectedPart = nil,

	TargetPart = {"Head", "HumanoidRootPart"},

	Ignored = {
		Teams = {
			{
				Team = LocalPlayer.Team,
				TeamColor = LocalPlayer.TeamColor,
			},
		},
		Players = {
			LocalPlayer,
			91318356
		}
	}
}
local Aiming = getgenv().Aiming


local circle = Drawingnew("Circle")
circle.Transparency = 0.5
circle.Thickness = 0.5
circle.Color = Aiming.FOVColour
circle.Filled = false
Aiming.FOVCircle = circle


function Aiming.UpdateFOV()
	if not (circle) then
		return
	end
	circle.Visible = Aiming.ShowFOV
	circle.Radius = (Aiming.FOV * 3)
	circle.Position = Vector2new(Mouse.X, Mouse.Y + GetGuiInset(GuiService).Y)
	circle.NumSides = Aiming.FOVSides
	circle.Color = Aiming.FOVColour
	return circle
end


local CalcChance = function(percentage)
	percentage = mathfloor(percentage)
	local chance = mathfloor(Randomnew().NextNumber(Randomnew(), 0, 1) * 100) / 100
	return chance <= percentage / 100
end


function Aiming.IsPartVisible(Part, PartDescendant)
    local Character = LocalPlayer.Character or CharacterAddedWait(CharacterAdded)
    local Origin = CurrentCamera.CFrame.Position
    local PartPos, OnScreen = CurrentCamera:WorldToViewportPoint(Part.Position)

    if OnScreen then
        local GuiInset = GuiService:GetGuiInset(GuiService)
        local ScreenSize = Workspace.CurrentCamera.ViewportSize
        local ScreenCenter = Vector2.new(ScreenSize.X / 2, ScreenSize.Y / 2)
        local ScreenVec = Vector2.new(PartPos.X, PartPos.Y - GuiInset.Y)

        local DistanceFromCenter = (ScreenVec - ScreenCenter).Magnitude
        if DistanceFromCenter < 200 then
            return true
        end
    end

    return false
end


function Aiming.IgnorePlayer(Player)
	local Ignored = Aiming.Ignored
	local IgnoredPlayers = Ignored.Players
	for _, IgnoredPlayer in ipairs(IgnoredPlayers) do
		if (IgnoredPlayer == Player) then
			return false
		end
	end
	tableinsert(IgnoredPlayers, Player)
	return true
end

function Aiming.UnIgnorePlayer(Player)
	local Ignored = Aiming.Ignored
	local IgnoredPlayers = Ignored.Players

	for i, IgnoredPlayer in ipairs(IgnoredPlayers) do
		if (IgnoredPlayer == Player) then
			tableremove(IgnoredPlayers, i)
			return true
		end
	end
	return false
end

function Aiming.IgnoreTeam(Team, TeamColor)
	local Ignored = Aiming.Ignored
	local IgnoredTeams = Ignored.Teams
	for _, IgnoredTeam in ipairs(IgnoredTeams) do
		if (IgnoredTeam.Team == Team and IgnoredTeam.TeamColor == TeamColor) then
			return false
		end
	end
	tableinsert(IgnoredTeams, {Team, TeamColor})
	return true
end

function Aiming.UnIgnoreTeam(Team, TeamColor)
	local Ignored = Aiming.Ignored
	local IgnoredTeams = Ignored.Teams
	for i, IgnoredTeam in ipairs(IgnoredTeams) do
		-- // Make sure team matches
		if (IgnoredTeam.Team == Team and IgnoredTeam.TeamColor == TeamColor) then
			-- // Remove
			tableremove(IgnoredTeams, i)
			return true
		end
	end
	return false
end

function Aiming.TeamCheck(Toggle)
	if (Toggle) then
		return Aiming.IgnoreTeam(LocalPlayer.Team, LocalPlayer.TeamColor)
	end

	return Aiming.UnIgnoreTeam(LocalPlayer.Team, LocalPlayer.TeamColor)
end

function Aiming.IsIgnoredTeam(Player)
	local Ignored = Aiming.Ignored
	local IgnoredTeams = Ignored.Teams
	for _, IgnoredTeam in ipairs(IgnoredTeams) do
		if (Player.Team == IgnoredTeam.Team and Player.TeamColor == IgnoredTeam.TeamColor) then
			return true
		end
	end
	return false
end

function Aiming.IsIgnored(Player)
	local Ignored = Aiming.Ignored
	local IgnoredPlayers = Ignored.Players
	for _, IgnoredPlayer in ipairs(IgnoredPlayers) do
		if (typeof(IgnoredPlayer) == "number" and Player.UserId == IgnoredPlayer) then
			return true
		end
		if (IgnoredPlayer == Player) then
			return true
		end
	end
	return Aiming.IsIgnoredTeam(Player)
end

function Aiming.Raycast(Origin, Destination, UnitMultiplier)
    if typeof(Origin) == "Vector3" and typeof(Destination) == "Vector3" then
        if not UnitMultiplier then
            UnitMultiplier = 1
        end

        local Direction = (Destination - Origin).Unit * UnitMultiplier

        local Distance = (Destination - Origin).Magnitude

        local Threshold = 10 

        if Distance < Threshold then
            return Direction, Vector3.new(0, 1, 0), Enum.Material.Plastic 
        end
    end

    return nil
end

function Aiming.Character(Player)
	return Player.Character
end


function Aiming.CheckHealth(Player)

	local Character = Aiming.Character(Player)
	local Humanoid = FindFirstChildWhichIsA(Character, "Humanoid")

	local Health = (Humanoid and Humanoid.Health or 0)

	return Health > 0
end


function Aiming.Check()
	return (Aiming.Enabled == true and Aiming.Selected ~= LocalPlayer and Aiming.SelectedPart ~= nil)
end
Aiming.checkSilentAim = Aiming.Check


function Aiming.GetClosestTargetPartToCursor(Character)
	local TargetParts = Aiming.TargetPart

	local ClosestPart = nil
	local ClosestPartPosition = nil
	local ClosestPartOnScreen = false
	local ClosestPartMagnitudeFromMouse = nil
	local ShortestDistance = 1/0

	local function CheckTargetPart(TargetPart)
		if (typeof(TargetPart) == "string") then
			TargetPart = FindFirstChild(Character, TargetPart)
		end

		if not (TargetPart) then
			return
		end

		local PartPos, onScreen = WorldToViewportPoint(CurrentCamera, TargetPart.Position)
		local GuiInset = GetGuiInset(GuiService)
		local Magnitude = (Vector2new(PartPos.X, PartPos.Y - GuiInset.Y) - Vector2new(Mouse.X, Mouse.Y)).Magnitude

		if (Magnitude < ShortestDistance) then
			ClosestPart = TargetPart
			ClosestPartPosition = PartPos
			ClosestPartOnScreen = onScreen
			ClosestPartMagnitudeFromMouse = Magnitude
			ShortestDistance = Magnitude
		end
	end

	-- // String check
	if (typeof(TargetParts) == "string") then
		-- // Check if it all
		if (TargetParts == "All") then
			-- // Loop through character children
			for _, v in ipairs(Character:GetChildren()) do
				-- // See if it a part
				if not (v:IsA("BasePart")) then
					continue
				end

				-- // Check it
				CheckTargetPart(v)
			end
		else
			-- // Individual
			CheckTargetPart(TargetParts)
		end
	end

	-- //
	if (typeof(TargetParts) == "table") then
		-- // Loop through all target parts and check them
		for _, TargetPartName in ipairs(TargetParts) do
			CheckTargetPart(TargetPartName)
		end
	end

	-- //
	return ClosestPart, ClosestPartPosition, ClosestPartOnScreen, ClosestPartMagnitudeFromMouse
end

-- // Silent Aim Function
function Aiming.GetClosestPlayerToCursor()
	-- // Vars
	local TargetPart = nil
	local ClosestPlayer = nil
	local Chance = CalcChance(Aiming.HitChance)
	local ShortestDistance = 1/0

	-- // Chance
	if (not Chance) then
		Aiming.Selected = LocalPlayer
		Aiming.SelectedPart = nil

		return LocalPlayer
	end

	-- // Loop through all players
	for _, Player in ipairs(GetPlayers(Players)) do
		-- // Get Character
		local Character = Aiming.Character(Player)

		-- // Make sure isn't ignored and Character exists
		if (Aiming.IsIgnored(Player) == false and Character) then
			-- // Vars
			local TargetPartTemp, _, _, Magnitude = Aiming.GetClosestTargetPartToCursor(Character)

			-- // Check if part exists and health
			if (TargetPartTemp and Aiming.CheckHealth(Player)) then
				-- // Check if is in FOV
				if (circle.Radius > Magnitude and Magnitude < ShortestDistance) then
					-- // Check if Visible
					if (Aiming.VisibleCheck and not Aiming.IsPartVisible(TargetPartTemp, Character)) then continue end

					-- // Set vars
					ClosestPlayer = Player
					ShortestDistance = Magnitude
					TargetPart = TargetPartTemp
				end
			end
		end
	end

	-- // End
	Aiming.Selected = ClosestPlayer
	Aiming.SelectedPart = TargetPart
end

-- // Heartbeat Function
Heartbeat:Connect(function()
	Aiming.UpdateFOV()
	Aiming.GetClosestPlayerToCursor()
end)

-- //
return Aiming
