--[[
    BINTANG SILENT
    Premium silent for The Veil — Violence District
    - 280 stud hardcap
    - Auto-active
    - Camera never locked
    - Clean premium UI (no floating button)
    - RightShift toggle also works
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local CONFIG = {
    GRAVITY = 98.1,
    SPEAR_SPEED = 165,
    SPAWN_OFFSET = 3,
    MAX_LIFE = 4,
    FOV_DEFAULT = 145,
    AIM_POINT = "HumanoidRootPart",
    AIM_Y_OFFSET = 0.6,
    MAX_RANGE = 280,
    PREDICTION = 1.12
}

local STATE = {
    enabled = true,
    fovDeg = CONFIG.FOV_DEFAULT,
    lockedTarget = nil,
    lastAimDir = nil,
    lastOrigin = nil,
    lastFlightTime = nil,
    gui = nil,
    panel = nil,
    fovCircle = nil,
    lockLabel = nil,
    statusLabel = nil,
    toggleBtn = nil,
    oldNamecall = nil,
    hookMT = nil,
    conn = nil
}

-- ============================================================
-- BALLISTIC
-- ============================================================
local function ballisticCheck(origin, targetPos, speed)
    local g = CONFIG.GRAVITY
    local delta = targetPos - origin
    local horiz = Vector3.new(delta.X, 0, delta.Z)
    local d = horiz.Magnitude
    local y = delta.Y

    if d < 0.1 then
        return math.abs(y) / speed <= CONFIG.MAX_LIFE, math.abs(y) / speed
    end

    local v2 = speed * speed
    local disc = v2 * v2 - g * (g * d * d + 2 * y * v2)
    if disc < 0 then return false, nil end

    local tanTheta = (v2 - math.sqrt(disc)) / (g * d)
    local theta = math.atan(tanTheta)
    local cosT = math.cos(theta)
    if cosT <= 0.001 then return false, nil end

    local t = d / (speed * cosT)
    if t < 0 or t > CONFIG.MAX_LIFE then return false, nil end
    return true, t
end

local function computeAim(origin, targetPos)
    local speed = CONFIG.SPEAR_SPEED
    local g = CONFIG.GRAVITY
    local dir = (targetPos - origin).Unit

    for _ = 1, 3 do
        local actual = origin + dir * CONFIG.SPAWN_OFFSET
        local delta = targetPos - actual
        local horiz = Vector3.new(delta.X, 0, delta.Z)
        local d = horiz.Magnitude
        local y = delta.Y

        if d < 0.1 then
            return (targetPos - origin).Unit, true, 0.1
        end

        local v2 = speed * speed
        local disc = v2 * v2 - g * (g * d * d + 2 * y * v2)
        if disc < 0 then
            return (targetPos - origin).Unit, false, nil
        end

        local tanTheta = (v2 - math.sqrt(disc)) / (g * d)
        local theta = math.atan(tanTheta)
        dir = (horiz.Unit * math.cos(theta)) + Vector3.new(0, math.sin(theta), 0)
    end

    local ok, t = ballisticCheck(origin + dir * CONFIG.SPAWN_OFFSET, targetPos, speed)
    return dir, ok, t
end

local function predict(part, t)
    if not part then return nil end
    local vel = part.AssemblyLinearVelocity or Vector3.zero
    local lead = Vector3.new(vel.X, vel.Y * 0.3, vel.Z) * (t or 0.55) * CONFIG.PREDICTION
    return part.Position + lead + Vector3.new(0, CONFIG.AIM_Y_OFFSET, 0)
end

-- ============================================================
-- TARGET
-- ============================================================
local function isEnemy(plr)
    if plr == LP then return false end
    local a, b = LP.Team, plr.Team
    if a and b then return a ~= b end
    return true
end

local function isValid(char, hum)
    if not hum or hum.Health <= 20 then return false end
    if char:GetAttribute("Knocked") or char:GetAttribute("IsKnocked") then return false end
    if char:GetAttribute("IsHooked") then return false end
    local hp = char:GetAttribute("HookPhase") or char:GetAttribute("HookedPhase")
    if hp and hp > 0 then return false end
    return true
end

local function fovRadius()
    local vp = Cam.ViewportSize
    local half = math.rad(math.min(STATE.fovDeg, 359) * 0.5)
    return (vp.Y / 2) * (math.tan(half) / math.tan(math.rad(Cam.FieldOfView) / 2))
end

local accum = 0
local function updateTarget(dt)
    if not STATE.enabled then
        STATE.lockedTarget = nil
        STATE.lastAimDir = nil
        return
    end

    if STATE.lockedTarget then
        local ch = STATE.lockedTarget.Character
        local hum = ch and ch:FindFirstChildOfClass("Humanoid")
        local hrp = ch and ch:FindFirstChild(CONFIG.AIM_POINT)
        if not (ch and ch.Parent and hum and hrp and isValid(ch, hum)) then
            STATE.lockedTarget = nil
            STATE.lastAimDir = nil
        else
            local origin = Cam.CFrame.Position
            local dist = (hrp.Position - origin).Magnitude
            if dist > CONFIG.MAX_RANGE then
                STATE.lockedTarget = nil
                STATE.lastAimDir = nil
            else
                local pred = predict(hrp, dist / CONFIG.SPEAR_SPEED)
                local dir, ok, t = computeAim(origin, pred)
                if ok then
                    STATE.lastAimDir = dir
                    STATE.lastOrigin = origin
                    STATE.lastFlightTime = t
                    return
                else
                    STATE.lockedTarget = nil
                    STATE.lastAimDir = nil
                end
            end
        end
    end

    accum = accum + dt
    if accum < 0.04 then return end
    accum = 0

    local center = Vector2.new(Cam.ViewportSize.X / 2, Cam.ViewportSize.Y / 2)
    local r = fovRadius()
    local origin = Cam.CFrame.Position
    local best, bestD = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local ch = plr.Character
            if ch then
                local hrp = ch:FindFirstChild(CONFIG.AIM_POINT)
                local hum = ch:FindFirstChildOfClass("Humanoid")
                if hrp and hum and isValid(ch, hum) then
                    local dist = (hrp.Position - origin).Magnitude
                    if dist <= CONFIG.MAX_RANGE then
                        local pred = predict(hrp, dist / CONFIG.SPEAR_SPEED)
                        local _, ok = computeAim(origin, pred)
                        if ok then
                            local sp, on = Cam:WorldToViewportPoint(hrp.Position)
                            if on then
                                local sd = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if sd <= r and sd < bestD then
                                    best = plr
                                    bestD = sd
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    STATE.lockedTarget = best
    if best then
        local hrp = best.Character:FindFirstChild(CONFIG.AIM_POINT)
        if hrp then
            local pred = predict(hrp, (hrp.Position - origin).Magnitude / CONFIG.SPEAR_SPEED)
            local dir, ok, t = computeAim(origin, pred)
            if ok then
                STATE.lastAimDir = dir
                STATE.lastOrigin = origin
                STATE.lastFlightTime = t
            end
        end
    else
        STATE.lastAimDir = nil
    end
end

-- ============================================================
-- SILENT HOOK
-- ============================================================
local function setupHook()
    local remote
    pcall(function() remote = ReplicatedStorage.Remotes.Killers.Veil.Spearthrow end)
    if not remote then
        pcall(function()
            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                if r:IsA("RemoteEvent") and (r.Name:lower():find("spear") or r.Name:lower():find("throw")) then
                    remote = r
                    break
                end
            end
        end)
    end
    if not remote or type(hookmetamethod) ~= "function" then
        warn("[BINTANG] remote / hookmetamethod missing")
        return
    end

    local mt = getrawmetatable(game)
    local old = mt.__namecall
    STATE.oldNamecall = old
    STATE.hookMT = mt

    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "FireServer" and self == remote then
            if STATE.enabled and STATE.lastAimDir and STATE.lockedTarget then
                local payload = args[1]
                local np = type(payload) == "table" and {} or {}
                if type(payload) == "table" then
                    for k, v in pairs(payload) do np[k] = v end
                end

                np.Direction = STATE.lastAimDir
                np.LookVector = STATE.lastAimDir
                np.Velocity = STATE.lastAimDir * CONFIG.SPEAR_SPEED
                np.Origin = STATE.lastOrigin or Cam.CFrame.Position
                np.Position = STATE.lastOrigin or Cam.CFrame.Position
                if np.Pierce ~= nil then np.Pierce = true end
                if np.ThroughVeil ~= nil then np.ThroughVeil = true end
                if np.IgnoreCollision ~= nil then np.IgnoreCollision = true end

                args[1] = np
                return old(self, unpack(args))
            end
        end
        return old(self, ...)
    end)
    setreadonly(mt, true)
end

-- ============================================================
-- PREMIUM UI (no floating)
-- ============================================================
local function buildUI()
    local parent = (type(gethui) == "function" and gethui()) or CoreGui

    local gui = Instance.new("ScreenGui")
    gui.Name = "BintangSilent"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999
    gui.Parent = parent
    STATE.gui = gui

    -- FOV circle
    local fov = Instance.new("Frame")
    fov.AnchorPoint = Vector2.new(0.5, 0.5)
    fov.Position = UDim2.fromScale(0.5, 0.5)
    fov.Size = UDim2.fromOffset(320, 320)
    fov.BackgroundTransparency = 1
    fov.Visible = STATE.enabled
    fov.ZIndex = 2
    fov.Parent = gui
    Instance.new("UICorner", fov).CornerRadius = UDim.new(1, 0)
    local fs = Instance.new("UIStroke", fov)
    fs.Color = Color3.fromRGB(255, 215, 0)
    fs.Thickness = 1.4
    fs.Transparency = 0.55
    STATE.fovCircle = fov

    -- lock label
    local lock = Instance.new("TextLabel")
    lock.AnchorPoint = Vector2.new(0.5, 0.5)
    lock.BackgroundTransparency = 1
    lock.Text = ""
    lock.TextColor3 = Color3.fromRGB(0, 255, 140)
    lock.Font = Enum.Font.GothamBold
    lock.TextSize = 13
    lock.TextStrokeTransparency = 0.5
    lock.Visible = false
    lock.ZIndex = 5
    lock.Parent = gui
    STATE.lockLabel = lock

    -- main panel
    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(280, 168)
    panel.Position = UDim2.new(0.5, -140, 0, 70)
    panel.BackgroundColor3 = Color3.fromRGB(12, 12, 16)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = true
    panel.ZIndex = 10
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 10)
    local stroke = Instance.new("UIStroke", panel)
    stroke.Color = Color3.fromRGB(255, 200, 40)
    stroke.Thickness = 1.2
    stroke.Transparency = 0.3
    STATE.panel = panel

    -- gold top bar
    local top = Instance.new("Frame")
    top.Size = UDim2.new(1, 0, 0, 36)
    top.BackgroundColor3 = Color3.fromRGB(22, 18, 8)
    top.BorderSizePixel = 0
    top.ZIndex = 11
    top.Parent = panel
    Instance.new("UICorner", top).CornerRadius = UDim.new(0, 10)
    local topFix = Instance.new("Frame")
    topFix.Size = UDim2.new(1, 0, 0, 12)
    topFix.Position = UDim2.new(0, 0, 1, -12)
    topFix.BackgroundColor3 = Color3.fromRGB(22, 18, 8)
    topFix.BorderSizePixel = 0
    topFix.ZIndex = 11
    topFix.Parent = top

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -50, 1, 0)
    title.Position = UDim2.fromOffset(14, 0)
    title.BackgroundTransparency = 1
    title.Text = "★  BINTANG SILENT"
    title.TextColor3 = Color3.fromRGB(255, 215, 60)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 12
    title.Parent = top

    local close = Instance.new("TextButton")
    close.Size = UDim2.fromOffset(28, 28)
    close.Position = UDim2.new(1, -32, 0, 4)
    close.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    close.Text = "✕"
    close.TextColor3 = Color3.new(1,1,1)
    close.Font = Enum.Font.GothamBold
    close.TextSize = 14
    close.BorderSizePixel = 0
    close.ZIndex = 13
    close.Parent = top
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 6)

    -- status
    local status = Instance.new("TextLabel")
    status.Size = UDim2.fromOffset(252, 22)
    status.Position = UDim2.fromOffset(14, 46)
    status.BackgroundTransparency = 1
    status.Text = "STATUS: ACTIVE"
    status.TextColor3 = Color3.fromRGB(0, 255, 140)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.ZIndex = 11
    status.Parent = panel
    STATE.statusLabel = status

    -- toggle
    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.fromOffset(252, 36)
    toggle.Position = UDim2.fromOffset(14, 72)
    toggle.BackgroundColor3 = Color3.fromRGB(0, 140, 70)
    toggle.Text = "SILENT  •  ON"
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.BorderSizePixel = 0
    toggle.ZIndex = 11
    toggle.Parent = panel
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 7)
    STATE.toggleBtn = toggle

    -- fov label + slider
    local fovLbl = Instance.new("TextLabel")
    fovLbl.Size = UDim2.fromOffset(252, 18)
    fovLbl.Position = UDim2.fromOffset(14, 116)
    fovLbl.BackgroundTransparency = 1
    fovLbl.Text = "FOV  145    |    RANGE  280"
    fovLbl.TextColor3 = Color3.fromRGB(180, 180, 195)
    fovLbl.Font = Enum.Font.Gotham
    fovLbl.TextSize = 11
    fovLbl.TextXAlignment = Enum.TextXAlignment.Left
    fovLbl.ZIndex = 11
    fovLbl.Parent = panel

    local sliderBg = Instance.new("Frame")
    sliderBg.Size = UDim2.fromOffset(252, 6)
    sliderBg.Position = UDim2.fromOffset(14, 140)
    sliderBg.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    sliderBg.BorderSizePixel = 0
    sliderBg.ZIndex = 11
    sliderBg.Parent = panel
    Instance.new("UICorner", sliderBg).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0.38, 1)
    fill.BackgroundColor3 = Color3.fromRGB(255, 200, 40)
    fill.BorderSizePixel = 0
    fill.ZIndex = 12
    fill.Parent = sliderBg
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    -- logic
    local function setEnabled(on)
        STATE.enabled = on
        toggle.Text = on and "SILENT  •  ON" or "SILENT  •  OFF"
        toggle.BackgroundColor3 = on and Color3.fromRGB(0, 140, 70) or Color3.fromRGB(50, 50, 60)
        status.Text = on and "STATUS: ACTIVE" or "STATUS: OFF"
        status.TextColor3 = on and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(255, 100, 100)
        STATE.fovCircle.Visible = on
        if not on then
            STATE.lockedTarget = nil
            STATE.lastAimDir = nil
            STATE.lockLabel.Visible = false
        end
    end

    toggle.MouseButton1Click:Connect(function()
        setEnabled(not STATE.enabled)
    end)

    close.MouseButton1Click:Connect(function()
        if STATE.conn then STATE.conn:Disconnect() end
        if STATE.hookMT and STATE.oldNamecall then
            pcall(function()
                setreadonly(STATE.hookMT, false)
                STATE.hookMT.__namecall = STATE.oldNamecall
                setreadonly(STATE.hookMT, true)
            end)
        end
        gui:Destroy()
        print("[BINTANG SILENT] Unloaded")
    end)

    local function updateSlider(pos)
        local rel = math.clamp((pos.X - sliderBg.AbsolutePosition.X) / sliderBg.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.fromScale(rel, 1)
        STATE.fovDeg = 40 + rel * 320
        fovLbl.Text = string.format("FOV  %.0f    |    RANGE  280", STATE.fovDeg)
        local r = fovRadius()
        STATE.fovCircle.Size = UDim2.fromOffset(r * 2, r * 2)
    end

    sliderBg.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input.Position)
            local m
            m = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    updateSlider(inp.Position)
                end
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End and m then m:Disconnect() end
            end)
        end
    end)

    -- init circle size
    local r = fovRadius()
    STATE.fovCircle.Size = UDim2.fromOffset(r * 2, r * 2)
end

local function updateVisuals()
    if not STATE.lockLabel then return end
    if not (STATE.enabled and STATE.lockedTarget and STATE.lastAimDir) then
        STATE.lockLabel.Visible = false
        return
    end
    local ch = STATE.lockedTarget.Character
    local hrp = ch and ch:FindFirstChild(CONFIG.AIM_POINT)
    if not hrp then
        STATE.lockLabel.Visible = false
        return
    end
    local pos = hrp.Position + Vector3.new(0, CONFIG.AIM_Y_OFFSET, 0)
    local sp, on = Cam:WorldToViewportPoint(pos)
    if on then
        local dist = (pos - Cam.CFrame.Position).Magnitude
        STATE.lockLabel.Visible = true
        STATE.lockLabel.Position = UDim2.fromOffset(sp.X, sp.Y - 22)
        STATE.lockLabel.Text = string.format("★ LOCK\n%.0f studs", dist)
    else
        STATE.lockLabel.Visible = false
    end
end

-- ============================================================
-- INIT
-- ============================================================
UserInputService.InputBegan:Connect(function(input, gpe)
    if gpe then return end
    if input.KeyCode == Enum.KeyCode.RightShift then
        STATE.enabled = not STATE.enabled
        if STATE.toggleBtn then
            STATE.toggleBtn.Text = STATE.enabled and "SILENT  •  ON" or "SILENT  •  OFF"
            STATE.toggleBtn.BackgroundColor3 = STATE.enabled and Color3.fromRGB(0, 140, 70) or Color3.fromRGB(50, 50, 60)
        end
        if STATE.statusLabel then
            STATE.statusLabel.Text = STATE.enabled and "STATUS: ACTIVE" or "STATUS: OFF"
            STATE.statusLabel.TextColor3 = STATE.enabled and Color3.fromRGB(0, 255, 140) or Color3.fromRGB(255, 100, 100)
        end
        if STATE.fovCircle then STATE.fovCircle.Visible = STATE.enabled end
        if not STATE.enabled then
            STATE.lockedTarget = nil
            STATE.lastAimDir = nil
        end
        print("[BINTANG] Silent:", STATE.enabled and "ON" or "OFF")
    end
end)

buildUI()
setupHook()

STATE.conn = RunService.RenderStepped:Connect(function(dt)
    updateTarget(dt)
    updateVisuals()
end)

print("[BINTANG SILENT] Loaded — 280 stud | premium UI | RightShift toggle")
