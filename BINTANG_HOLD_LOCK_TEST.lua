--[[
  Bintang — Hold Aim Lock TEST
  1 ID: lungehold rbxassetid://93902163029544
  Tahan lunge → lock ke survivor terdekat di FOV
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local LP = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local HOLD_ID = "rbxassetid://93902163029544" -- lungehold
local FOV = 150
local Predict = 0.1

local locking = false
local FOVFrame, CrossGui

local function isSurvivor(plr)
    if plr == LP then return false end
    if LP.Team and plr.Team and LP.Team == plr.Team then return false end
    local role = plr:GetAttribute("Role") or plr:GetAttribute("role")
    if role and string.lower(tostring(role)):find("kill") then return false end
    return true
end

local function alive(plr)
    local c = plr.Character
    if not c then return false end
    local h = c:FindFirstChildOfClass("Humanoid")
    local r = c:FindFirstChild("HumanoidRootPart")
    return h and h.Health > 0 and r
end

local function getClosest()
    local best, bestD = nil, FOV
    local center = Camera.ViewportSize / 2
    for _, plr in ipairs(Players:GetPlayers()) do
        if isSurvivor(plr) and alive(plr) then
            local char = plr.Character
            local part = char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart")
            if part then
                local pos = part.Position + (part.AssemblyLinearVelocity or Vector3.zero) * Predict
                local v, on = Camera:WorldToViewportPoint(pos)
                if on then
                    local d = (Vector2.new(v.X, v.Y) - center).Magnitude
                    if d < bestD then
                        bestD = d
                        best = pos
                    end
                end
            end
        end
    end
    return best
end

local function ensureVisual()
    if FOVFrame and FOVFrame.Parent then return end
    local g = Instance.new("ScreenGui")
    g.Name = "BintangHoldLock"
    g.IgnoreGuiInset = true
    g.ResetOnSpawn = false
    pcall(function() g.Parent = gethui and gethui() or CoreGui end)
    if not g.Parent then g.Parent = LP:WaitForChild("PlayerGui") end

    FOVFrame = Instance.new("Frame")
    FOVFrame.AnchorPoint = Vector2.new(0.5, 0.5)
    FOVFrame.BackgroundTransparency = 1
    FOVFrame.Parent = g
    local s = Instance.new("UIStroke")
    s.Color = Color3.fromRGB(155, 89, 255)
    s.Thickness = 1.5
    s.Transparency = 0.35
    s.Parent = FOVFrame
    Instance.new("UICorner", FOVFrame).CornerRadius = UDim.new(1, 0)

    CrossGui = Instance.new("Frame")
    CrossGui.AnchorPoint = Vector2.new(0.5, 0.5)
    CrossGui.Size = UDim2.fromOffset(16, 16)
    CrossGui.BackgroundTransparency = 1
    CrossGui.Parent = g
    for _, d in ipairs({
        {0.5, 0, 2, 6}, {0.5, 1, 2, 6}, {0, 0.5, 6, 2}, {1, 0.5, 6, 2}
    }) do
        local f = Instance.new("Frame")
        f.AnchorPoint = Vector2.new(0.5, 0.5)
        f.Position = UDim2.fromScale(d[1], d[2])
        f.Size = UDim2.fromOffset(d[3], d[4])
        f.BackgroundColor3 = Color3.new(1, 1, 1)
        f.BorderSizePixel = 0
        f.Parent = CrossGui
    end
end

RunService.RenderStepped:Connect(function()
    ensureVisual()
    local vp = Camera.ViewportSize
    local cx, cy = vp.X / 2, vp.Y / 2
    FOVFrame.Size = UDim2.fromOffset(FOV * 2, FOV * 2)
    FOVFrame.Position = UDim2.fromOffset(cx, cy)
    CrossGui.Position = UDim2.fromOffset(cx, cy)

    -- highlight FOV when locking
    local st = FOVFrame:FindFirstChildOfClass("UIStroke")
    if st then
        st.Color = locking and Color3.fromRGB(255, 70, 90) or Color3.fromRGB(155, 89, 255)
        st.Transparency = locking and 0.15 or 0.35
    end

    if locking then
        local pos = getClosest()
        if pos then
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(Camera.CFrame.Position, pos), 0.9)
        end
    end
end)

local function hookAnimator(animator)
    animator.AnimationPlayed:Connect(function(track)
        local anim = track.Animation
        local id = anim and anim.AnimationId
        if id ~= HOLD_ID then return end
        locking = true
        print("[Bintang] HOLD LOCK ON", id)
        task.spawn(function()
            while track.IsPlaying do
                task.wait(0.03)
            end
            locking = false
            print("[Bintang] HOLD LOCK OFF")
        end)
    end)
end

local function hookChar(char)
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 8)
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator") or hum:WaitForChild("Animator", 5)
        if animator then
            hookAnimator(animator)
            print("[Bintang] Animator hooked")
        end
    end)
end

if LP.Character then hookChar(LP.Character) end
LP.CharacterAdded:Connect(hookChar)

print("[Bintang] Hold Lock TEST — ID lungehold only")
print("Tahan lunge → FOV merah + aim lock")
