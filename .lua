local plrs = game:GetService("Players")
local plr = plrs.LocalPlayer
local camera = workspace.CurrentCamera
local runService = game:GetService("RunService")

local FOV_RADIUS = 100
local fovCircle = Drawing.new("Circle")
fovCircle.Visible = true
fovCircle.Thickness = 1
fovCircle.NumSides = 64
fovCircle.Radius = FOV_RADIUS
fovCircle.Filled = false
fovCircle.Transparency = 1

runService.RenderStepped:Connect(function()
    local screenCenter = camera.ViewportSize / 2
    fovCircle.Position = Vector2.new(screenCenter.X, screenCenter.Y)
    fovCircle.Color = Color3.fromHSV(tick() % 5 / 5, 1, 1)
end)

local function notBehindWall(target)
    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {plr.Character}
    raycastParams.FilterType = Enum.RaycastFilterType.Exclude
    local direction = (target.Position - camera.CFrame.Position)
    local result = workspace:Raycast(camera.CFrame.Position, direction, raycastParams)
    if not result or result.Instance:IsDescendantOf(target.Parent) then
        return true
    end
    return false
end

function getClosestPlayerToCenter()
    local target = nil
    local maxDist = FOV_RADIUS
    local screenCenter = camera.ViewportSize / 2
    
    for _, v in pairs(plrs:GetPlayers()) do
        if v ~= plr and v.Character and v.Character:FindFirstChild("HumanoidRootPart") then
            local head = v.Character:FindFirstChild("Head")
            if head then
                local pos, vis = camera:WorldToViewportPoint(head.Position)
                if vis then
                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenCenter - screenPos).Magnitude
                    
                    if dist < maxDist then
                        if notBehindWall(head) then
                            target = head
                            maxDist = dist
                        end
                    end
                end
            end
        end
    end
    return target
end

local gmt = getrawmetatable(game)
setreadonly(gmt, false)
local oldNamecall = gmt.__namecall

gmt.__namecall = newcclosure(function(self, ...)
    local method = getnamecallmethod()
    local args = {...}
    
    if method == "FireServer" and tostring(self) == "HitPart" then
        local closest = getClosestPlayerToCenter()
        if closest then
            args[1] = closest
            args[2] = closest.Position
            return oldNamecall(self, unpack(args))
        end
    end
    
    return oldNamecall(self, ...)
end)
setreadonly(gmt, true)
