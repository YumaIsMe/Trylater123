if getgenv().Aiming then return getgenv().Aiming end
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local GuiService = game:GetService("GuiService")
local RunService = game:GetService("RunService")


local Heartbeat = RunService.Heartbeat
local LocalPlayer = Players.LocalPlayer
local CurrentCamera = Workspace.CurrentCamera
local Mouse = LocalPlayer:GetMouse()

local config = {
    getgenv().Aiming = {
        Enabled = true,
        ShowFOV = true,
        FOV = 60,
        FOVSides = 60,
        FOVColour = Color3.fromRGB(0, 200, 200),
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
}


local circle = Drawing.new("Circle")
circle.Transparency = 0.5
circle.Thickness = 0.5
circle.Color = config.Aiming.FOVColour
circle.Filled = false
config.Aiming.FOVCircle = circle


function config.Aiming.UpdateFOV()
    if not circle then
        return
    end

    circle.Visible = config.Aiming.ShowFOV
    circle.Radius = (config.Aiming.FOV * 3)
    circle.Position = Vector2.new(Mouse.X, Mouse.Y + GuiService:GetGuiInset(GuiService).Y)
    circle.NumSides = config.Aiming.FOVSides
    circle.Color = config.Aiming.FOVColour

    return circle
end


function config.Aiming.IsPartVisible(Part, PartDescendant)
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


function config.Aiming.IgnorePlayer(Player)
    local Ignored = config.Aiming.Ignored
    local IgnoredPlayers = Ignored.Players

    for _, IgnoredPlayer in ipairs(IgnoredPlayers) do
        if IgnoredPlayer == Player then
            return false
        end
    end

    table.insert(IgnoredPlayers, Player)
    return true
end


function config.Aiming.UnIgnorePlayer(Player)
    local Ignored = config.Aiming.Ignored
    local IgnoredPlayers = Ignored.Players

    for i, IgnoredPlayer in ipairs(IgnoredPlayers) do
        if IgnoredPlayer == Player then
            table.remove(IgnoredPlayers, i)
            return true
        end
    end

    return false
end


function config.Aiming.IgnoreTeam(Team, TeamColor)
    local Ignored = config.Aiming.Ignored
    local IgnoredTeams = Ignored.Teams

    for _, IgnoredTeam in ipairs(IgnoredTeams) do
        if IgnoredTeam.Team == Team and IgnoredTeam.TeamColor == TeamColor then
            return false
        end
    end

    table.insert(IgnoredTeams, {Team, TeamColor})
    return true
end

function config.Aiming.UnIgnoreTeam(Team, TeamColor)
    local Ignored = config.Aiming.Ignored
    local IgnoredTeams = Ignored.Teams

    for i, IgnoredTeam in ipairs(IgnoredTeams) do
        if IgnoredTeam.Team == Team and IgnoredTeam.TeamColor == TeamColor then
            table.remove(IgnoredTeams, i)
            return true
        end
    end

    return false
end


function config.Aiming.TeamCheck(Toggle)
    if Toggle then
        return config.Aiming.IgnoreTeam(LocalPlayer.Team, LocalPlayer.TeamColor)
    end

    return config.Aiming.UnIgnoreTeam(LocalPlayer.Team, LocalPlayer.TeamColor)
end


function config.Aiming.IsIgnoredTeam(Player)
    local Ignored = config.Aiming.Ignored
    local IgnoredTeams = Ignored.Teams

    for _, IgnoredTeam in ipairs(IgnoredTeams) do
        if Player.Team == IgnoredTeam.Team and Player.TeamColor == IgnoredTeam.TeamColor then
            return true
        end
    end

    return false
end

function config.Aiming.IsIgnored(Player)
    local Ignored = config.Aiming.Ignored
    local IgnoredPlayers = Ignored.Players

    for _, IgnoredPlayer in ipairs(IgnoredPlayers) do
        if typeof(IgnoredPlayer) == "number" and Player.UserId == IgnoredPlayer then
            return true
        end

        if IgnoredPlayer == Player then
            return true
        end
    end

    return config.Aiming.IsIgnoredTeam(Player)
end


function config.Aiming.Raycast(Origin, Destination, UnitMultiplier)
    if typeof(Origin) == "Vector3" and typeof(Destination) == "Vector3" then
        if not UnitMultiplier then
            UnitMultiplier = 1
        end

        local Direction = (Destination - Origin).Unit * UnitMultiplier

        -- Calculate the distance between Origin and Destination
        local Distance = (Destination - Origin).Magnitude

        -- You may adjust this threshold value based on your specific needs
        local Threshold = 10 -- Adjust this value as needed

        if Distance < Threshold then
            -- The part is within the threshold, consider it "visible"
            return Direction, Vector3.new(0, 1, 0), Enum.Material.Plastic -- Return a default normal and material
        end
    end

    return nil
end


function config.Aiming.Character(Player)
    return Player.Character
end


function config.Aiming.CheckHealth(Player)
    local Character = config.Aiming.Character(Player)
    local Humanoid = FindFirstChildWhichIsA(Character, "Humanoid")

    local Health = (Humanoid and Humanoid.Health or 0)

    return Health > 0
end


function config.Aiming.Check()
    return (config.Aiming.Enabled == true and config.Aiming.Selected ~= LocalPlayer and config.Aiming.SelectedPart ~= nil)
end

return config



function config.Aiming.GetClosestPlayerToCursor()
    local TargetPart = nil
    local ClosestPlayer = nil
    local Chance = CalcChance(config.Aiming.HitChance)
    local ShortestDistance = math.huge

    if not Chance then
        config.Aiming.Selected = LocalPlayer
        config.Aiming.SelectedPart = nil
        return LocalPlayer
    end

    for _, Player in ipairs(Players:GetPlayers()) do
        local Character = config.Aiming.Character(Player)

        if not config.Aiming.IsIgnored(Player) and Character then
            local TargetPartTemp, _, _, Magnitude = config.Aiming.GetClosestTargetPartToCursor(Character)

            if TargetPartTemp and config.Aiming.CheckHealth(Player) then
                if circle.Radius > Magnitude and Magnitude < ShortestDistance then
                    if config.Aiming.VisibleCheck and not config.Aiming.IsPartVisible(TargetPartTemp, Character) then
                        continue
                    end

                    ClosestPlayer = Player
                    ShortestDistance = Magnitude
                    TargetPart = TargetPartTemp
                end
            end
        end
    end

    config.Aiming.Selected = ClosestPlayer
    config.Aiming.SelectedPart = TargetPart
end


Heartbeat:Connect(function()
    config.Aiming.UpdateFOV()
    config.Aiming.GetClosestPlayerToCursor()
end)

return config
