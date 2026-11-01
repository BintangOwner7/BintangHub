--[[
    VEIL SILENT AIM — v10 FULL GACOR
    - 280 stud hardcap
    - Auto-active (no hold button)
    - Camera never locked
    - Aggressive remote redirect (multi-key + deep)
    - Better prediction + lead
    - Optional AutoThrow (F key)
    - Sticky + knocked/hook skip
    - FOV + Aura CD tracker
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local CONFIG = {
    GRAVITY = 98.1,
    SPEAR_SPEED = 165,
    SPAWN_OFFSET = 3,
    MAX_LIFE = 4,
    FOV_DEFAULT = 150,
    AIM_POINT = "HumanoidRootPart",
    AIM_Y_OFFSET = 0.8,               -- slight head bias
    MAX_RANGE = 280,
    PASSIVE_CD = 45,
    PREDICTION_MULT = 1.15,            -- more aggressive lead
    AUTO_THROW = true,                 -- auto fire when locked
    AUTO_THROW_DELAY = 0.35,           -- small charge feel
    COLOR_LOCK = Color3.fromRGB(0, 255, 80),
    COLOR_NO_TARGET = Color3.fromRGB(255, 255, 255)
}

local STATE = {
    autoAimOn = false,
    minimized = false,
    fovDeg = CONFIG.FOV_DEFAULT,
    lockedTarget = nil,
    gui = nil,
    panel = nil,
    fovCircle = nil,
    lockLabel = nil,
    miniBtn = nil,
    cdLabel = nil,
    statusLabel = nil,
    cdEndTime = 0,
    connections = {},
    scanConn = nil,
    oldNamecall = nil,
    hookMT = nil,
    lastAimDir = nil,
    lastOrigin = nil,
    lastFlightTime = nil,
    lastThrow = 0,
    autoThrowArmed = false
}

-- ============================================================
-- BALLISTIC + PREDICTION
-- ============================================================
local function ballisticCheck(actualOrigin, targetPos, speed)
    local g = CONFIG.GRAVITY
    local delta = targetPos - actualOrigin
    local horiz = Vector3.new(delta.X, 0, delta.Z)
    local d = horiz.Magnitude
    local y = delta.Y

    if d < 0.1 then
        local t = math.abs(y) / speed
        return t <= CONFIG.MAX_LIFE, t, 0
    end

    local v2 = speed * speed
    local v4 = v2 * v2
    local disc = v4 - g * (g * d * d + 2 * y * v2)
    if disc < 0 then return false, nil, nil end

    local sqrtDisc = math.sqrt(disc)
    local tanTheta = (v2 - sqrtDisc) / (g * d)
    local theta = math.atan(tanTheta)
    local cosTheta = math.cos(theta)
    if cosTheta <= 0.001 then return false, nil, nil end

    local t = d / (speed * cosTheta)
    if t < 0 or t > CONFIG.MAX_LIFE then return false, nil, nil end
    return true, t, theta
end

local function computeAimDirection(origin, targetPos, speed)
    local dir = (targetPos - origin).Unit

    for i = 1, 4 do
        local actualOrigin = origin + dir * CONFIG.SPAWN_OFFSET
        local delta = targetPos - actualOrigin
        local horiz = Vector3.new(delta.X, 0, delta.Z)
        local d = horiz.Magnitude
        local y = delta.Y

        if d < 0.1 then
            return (targetPos - origin).Unit, true, 0.1
        end

        local v2 = speed * speed
        local v4 = v2 * v2
        local disc = v4 - g * (g * d * d + 2 * y * v2)
        if disc < 0 then
            return (targetPos - origin).Unit, false, nil
        end

        local tanTheta = (v2 - math.sqrt(disc)) / (g * d)
        local theta = math.atan(tanTheta)
        local hdir = horiz.Unit
        dir = (hdir * math.cos(theta)) + Vector3.new(0, math.sin(theta), 0)
    end

    local finalOrigin = origin + dir * CONFIG.SPAWN_OFFSET
    local reachable, t = ballisticCheck(finalOrigin, targetPos, speed)
    return dir, reachable, t
end

local function isReachable(origin, targetPos)
    local finalDir = (targetPos - origin).Unit
    local actualOrigin = origin + finalDir * CONFIG.SPAWN_OFFSET
    local ok, t = ballisticCheck(actualOrigin, targetPos, CONFIG.SPEAR_SPEED)
    if not ok then
        local _, reachable2, t2 = computeAimDirection(origin, targetPos, CONFIG.SPEAR_SPEED)
        return reachable2, t2
    end
    return ok, t
end

local function predictPosition(part, flightTime)
    if not part then return nil end
    local vel = part.AssemblyLinearVelocity or Vector3.zero
    -- stronger horizontal lead
    local lead = Vector3.new(vel.X, vel.Y * 0.35, vel.Z) * (flightTime or 0.6) * CONFIG.PREDICTION_MULT
    return part.Position + lead + Vector3.new(0, CONFIG.AIM_Y_OFFSET, 0)
end

-- ============================================================
-- FOV + TARGET
-- ============================================================
local function getFovRadius()
    local vp = Cam.ViewportSize
    local camFov = math.rad(Cam.FieldOfView)
    local cappedFov = math.min(STATE.fovDeg, 359)
    local half = math.rad(cappedFov * 0.5)
    local r = (vp.Y / 2) * (math.tan(half) / math.tan(camFov / 2))
    return math.min(r, vp.Y * 0.95)
end

local function updateFovCircle()
    if not STATE.fovCircle then return end
    local r = getFovRadius()
    STATE.fovCircle.Size = UDim2.fromOffset(r * 2, r * 2)
end

local function isEnemy(plr)
    if plr == LP then return false end
    local a, b = LP.Team, plr.Team
    if not a or not b then return false end
    return a ~= b
end

local function isValidTarget(char, hum)
    if not hum or hum.Health <= 20 then return false end
    if char:GetAttribute("Knocked") == true or char:GetAttribute("IsKnocked") == true then return false end
    if char:GetAttribute("IsHooked") == true then return false end
    local hookPhase = char:GetAttribute("HookPhase") or char:GetAttribute("HookedPhase")
    if hookPhase and hookPhase > 0 then return false end
    return true
end

local scanAccum = 0
local function updateTarget(dt)
    if not STATE.autoAimOn then
        STATE.lockedTarget = nil
        STATE.lastAimDir = nil
        STATE.autoThrowArmed = false
        if STATE.lockLabel then STATE.lockLabel.Visible = false end
        return
    end

    -- sticky
    if STATE.lockedTarget then
        local tChar = STATE.lockedTarget.Character
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
        local tHrp = tChar and tChar:FindFirstChild(CONFIG.AIM_POINT)

        if not (tChar and tChar.Parent and tHum and tHrp and isValidTarget(tChar, tHum)) then
            STATE.lockedTarget = nil
            STATE.lastAimDir = nil
            STATE.autoThrowArmed = false
        else
            local myPos = Cam.CFrame.Position
            local worldDist = (tHrp.Position - myPos).Magnitude
            if worldDist > CONFIG.MAX_RANGE then
                STATE.lockedTarget = nil
                STATE.lastAimDir = nil
                STATE.autoThrowArmed = false
            else
                local roughT = worldDist / CONFIG.SPEAR_SPEED
                local predPos = predictPosition(tHrp, roughT)
                local reachable, t = isReachable(myPos, predPos)
                if not reachable then
                    STATE.lockedTarget = nil
                    STATE.lastAimDir = nil
                    STATE.autoThrowArmed = false
                else
                    local aimDir, ok, ft = computeAimDirection(myPos, predPos, CONFIG.SPEAR_SPEED)
                    if ok then
                        STATE.lastAimDir = aimDir
                        STATE.lastOrigin = myPos
                        STATE.lastFlightTime = ft
                        STATE.autoThrowArmed = true
                    end
                    return
                end
            end
        end
    end

    scanAccum = scanAccum + dt
    if scanAccum < 0.035 then return end
    scanAccum = 0

    local vp = Cam.ViewportSize
    local center = Vector2.new(vp.X / 2, vp.Y / 2)
    local r = getFovRadius()
    local camPos = Cam.CFrame.Position

    local best, bestD = nil, math.huge

    for _, plr in ipairs(Players:GetPlayers()) do
        if isEnemy(plr) then
            local ch = plr.Character
            if ch then
                local hrp = ch:FindFirstChild(CONFIG.AIM_POINT)
                local hum = ch:FindFirstChildOfClass("Humanoid")

                if hrp and hum and isValidTarget(ch, hum) then
                    local worldDist = (hrp.Position - camPos).Magnitude
                    if worldDist <= CONFIG.MAX_RANGE then
                        local roughT = worldDist / CONFIG.SPEAR_SPEED
                        local predPos = predictPosition(hrp, roughT)
                        local reachable = isReachable(camPos, predPos)
                        if reachable then
                            local sp, on = Cam:WorldToViewportPoint(hrp.Position)
                            if on then
                                local screenD = (Vector2.new(sp.X, sp.Y) - center).Magnitude
                                if screenD <= r and screenD < bestD then
                                    best = plr
                                    bestD = screenD
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
        local hrp = best.Character and best.Character:FindFirstChild(CONFIG.AIM_POINT)
        if hrp then
            local worldDist = (hrp.Position - camPos).Magnitude
            local roughT = worldDist / CONFIG.SPEAR_SPEED
            local predPos = predictPosition(hrp, roughT)
            local aimDir, ok, ft = computeAimDirection(camPos, predPos, CONFIG.SPEAR_SPEED)
            if ok then
                STATE.lastAimDir = aimDir
                STATE.lastOrigin = camPos
                STATE.lastFlightTime = ft
                STATE.autoThrowArmed = true
            end
        end
    else
        STATE.lastAimDir = nil
        STATE.autoThrowArmed = false
    end
end

local function updateLockLabel()
    if not STATE.lockLabel then return end
    if not (STATE.autoAimOn and STATE.lockedTarget and STATE.lastAimDir) then
        STATE.lockLabel.Visible = false
        return
    end

    local tChar = STATE.lockedTarget.Character
    local targetPart = tChar and tChar:FindFirstChild(CONFIG.AIM_POINT)
    if not targetPart then
        STATE.lockLabel.Visible = false
        return
    end

    local liveTargetPos = targetPart.Position + Vector3.new(0, CONFIG.AIM_Y_OFFSET, 0)
    local sp, on = Cam:WorldToViewportPoint(liveTargetPos)
    if on then
        local dist = (liveTargetPos - Cam.CFrame.Position).Magnitude
        STATE.lockLabel.Visible = true
        STATE.lockLabel.Position = UDim2.fromOffset(sp.X, sp.Y - 22)
        STATE.lockLabel.Text = string.format("SILENT LOCK\n%.0f studs | t=%.2fs", dist, STATE.lastFlightTime or 0)
        STATE.lockLabel.TextColor3 = CONFIG.COLOR_LOCK
    else
        STATE.lockLabel.Visible = false
    end
end

-- ============================================================
-- AGGRESSIVE REMOTE REDIRECT
-- ============================================================
local function deepReplaceVectors(tbl, aimDir, origin)
    if type(tbl) ~= "table" then return end
    for k, v in pairs(tbl) do
        local tk = type(k) == "string" and k:lower() or ""
        if typeof(v) == "Vector3" then
            if tk:find("dir") or tk:find("look") or tk:find("vel") or tk:find("aim") or tk:find("forward") then
                tbl[k] = aimDir
            elseif tk:find("origin") or tk:find("pos") or tk:find("start") then
                tbl[k] = origin
            end
        elseif typeof(v) == "CFrame" then
            tbl[k] = CFrame.lookAt(origin, origin + aimDir)
        elseif type(v) == "table" then
            deepReplaceVectors(v, aimDir, origin)
        end
    end
end

local function setupCdTrackerAndSilent()
    local ok, remote = pcall(function() return ReplicatedStorage.Remotes.Killers.Veil.SpearState end)
    if ok and remote then
        local conn = remote.OnClientEvent:Connect(function(kind, data)
            if (kind == "launch" or kind == "cooldown") and type(data) == "table" then
                local ready = data.SpecialReadyAt
                if type(ready) == "number" and ready > 0 then
                    local remaining = ready - workspace:GetServerTimeNow()
                    if remaining > 0 then
                        STATE.cdEndTime = tick() + remaining
                    end
                end
            end
        end)
        table.insert(STATE.connections, conn)
    end

    local ok2, spRemote = pcall(function() return ReplicatedStorage.Remotes.Killers.Veil.Spearthrow end)
    if not ok2 or not spRemote then
        -- fallback search
        pcall(function()
            for _, r in ipairs(ReplicatedStorage:GetDescendants()) do
                if r:IsA("RemoteEvent") and (r.Name:lower():find("spear") or r.Name:lower():find("throw")) then
                    spRemote = r
                    break
                end
            end
        end)
    end

    if not spRemote then
        warn("[VeilSilent v10] Spearthrow remote not found")
        return
    end

    if type(hookmetamethod) ~= "function" then
        warn("[VeilSilent v10] hookmetamethod missing")
        return
    end

    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    STATE.oldNamecall = oldNamecall
    STATE.hookMT = mt

    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        local args = {...}

        if method == "FireServer" and self == spRemote then
            local payload = args[1]

            -- CD track
            if type(payload) == "table" then
                local t = payload.Time or payload.time
                local rel = payload.ReleasedAt or payload.releasedAt
                if type(t) == "number" and type(rel) == "number" and (t - rel) >= 1.8 then
                    STATE.cdEndTime = tick() + CONFIG.PASSIVE_CD
                end
            end

            -- FULL GACOR REDIRECT
            if STATE.autoAimOn and STATE.lastAimDir and STATE.lockedTarget then
                local origin = STATE.lastOrigin or Cam.CFrame.Position
                local aimDir = STATE.lastAimDir

                if type(payload) == "table" then
                    local newPayload = {}
                    for k, v in pairs(payload) do
                        newPayload[k] = v
                    end

                    -- force common keys
                    newPayload.Direction = aimDir
                    newPayload.LookVector = aimDir
                    newPayload.Velocity = aimDir * CONFIG.SPEAR_SPEED
                    newPayload.Origin = origin
                    newPayload.Position = origin
                    newPayload.Start = origin
                    newPayload.Aim = aimDir

                    -- force pierce / veil flags
                    newPayload.Pierce = true
                    newPayload.ThroughVeil = true
                    newPayload.IgnoreCollision = true
                    newPayload.Wallbang = true
                    newPayload.Special = true

                    -- deep replace any nested Vector3/CFrame
                    deepReplaceVectors(newPayload, aimDir, origin)

                    args[1] = newPayload
                else
                    -- if payload is not table, try to rebuild
                    args[1] = {
                        Direction = aimDir,
                        LookVector = aimDir,
                        Velocity = aimDir * CONFIG.SPEAR_SPEED,
                        Origin = origin,
                        Pierce = true,
                        ThroughVeil = true
                    }
                end

                return oldNamecall(self, unpack(args))
            end
        end

        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
end

-- ============================================================
-- AUTO THROW (optional)
-- ============================================================
local function tryAutoThrow()
    if not CONFIG.AUTO_THROW then return end
    if not STATE.autoAimOn or not STATE.autoThrowArmed or not STATE.lastAimDir then return end
    if tick() - STATE.lastThrow < 1.1 then return end  -- prevent spam

    -- simple input simulation (works on many executors)
    pcall(function()
        -- press attack / charge briefly
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.MouseLeftButton, false, game)
        task.wait(CONFIG.AUTO_THROW_DELAY)
        VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.MouseLeftButton, false, game)
    end)

    STATE.lastThrow = tick()
end

-- ============================================================
-- CLEANUP
-- ============================================================
local cleanup
cleanup = function()
    if STATE.scanConn then
        pcall(function() STATE.scanConn:Disconnect() end)
        STATE.scanConn = nil
    end
    for _, conn in ipairs(STATE.connections) do
        pcall(function() conn:Disconnect() end)
    end
    STATE.connections = {}

    if STATE.hookMT and STATE.oldNamecall then
        pcall(function()
            setreadonly(STATE.hookMT, false)
            STATE.hookMT.__namecall = STATE.oldNamecall
            setreadonly(STATE.hookMT, true)
        end)
        STATE.hookMT = nil
        STATE.oldNamecall = nil
    end

    if STATE.gui then
        pcall(function() STATE.gui:Destroy() end)
        STATE.gui = nil
    end
    STATE.lockedTarget = nil
    STATE.autoAimOn = false
    STATE.lastAimDir = nil

    if getgenv().VeilAutoAimCleanup == cleanup then
        getgenv().VeilAutoAimCleanup = nil
    end
    print("[VeilSilent v10] Unloaded.")
end

-- ============================================================
-- UI
-- ============================================================
local function buildUI()
    local parent = (type(gethui) == "function" and gethui()) or CoreGui

    local gui = Instance.new("ScreenGui")
    gui.Name = "VeilSilentUI"
    gui.ResetOnSpawn = false
    gui.IgnoreGuiInset = true
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.DisplayOrder = 999999
    gui.Parent = parent
    STATE.gui = gui

    local cdLbl = Instance.new("TextLabel")
    cdLbl.Size = UDim2.fromOffset(260, 32)
    cdLbl.Position = UDim2.new(0.5, -130, 0, 18)
    cdLbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    cdLbl.BackgroundTransparency = 0.3
    cdLbl.BorderSizePixel = 0
    cdLbl.Text = ""
    cdLbl.TextColor3 = Color3.fromRGB(255, 200, 60)
    cdLbl.Font = Enum.Font.GothamBold
    cdLbl.TextSize = 14
    cdLbl.Visible = false
    cdLbl.ZIndex = 50
    cdLbl.Parent = gui
    Instance.new("UICorner", cdLbl).CornerRadius = UDim.new(0, 8)
    STATE.cdLabel = cdLbl

    local status = Instance.new("TextLabel")
    status.Size = UDim2.fromOffset(220, 26)
    status.Position = UDim2.new(0.5, -110, 0, 52)
    status.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    status.BackgroundTransparency = 0.4
    status.BorderSizePixel = 0
    status.Text = "SILENT READY"
    status.TextColor3 = Color3.fromRGB(0, 255, 140)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 13
    status.Visible = false
    status.ZIndex = 50
    status.Parent = gui
    Instance.new("UICorner", status).CornerRadius = UDim.new(0, 6)
    STATE.statusLabel = status

    local fov = Instance.new("Frame")
    fov.AnchorPoint = Vector2.new(0.5, 0.5)
    fov.Position = UDim2.fromScale(0.5, 0.5)
    fov.Size = UDim2.fromOffset(300, 300)
    fov.BackgroundTransparency = 1
    fov.BorderSizePixel = 0
    fov.ZIndex = 2
    fov.Visible = false
    fov.Parent = gui
    Instance.new("UICorner", fov).CornerRadius = UDim.new(1, 0)
    local fs = Instance.new("UIStroke", fov)
    fs.Color = CONFIG.COLOR_NO_TARGET
    fs.Thickness = 1.6
    fs.Transparency = 0.4
    STATE.fovCircle = fov

    local lockLbl = Instance.new("TextLabel")
    lockLbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lockLbl.BackgroundTransparency = 1
    lockLbl.Text = ""
    lockLbl.TextColor3 = CONFIG.COLOR_LOCK
    lockLbl.Font = Enum.Font.GothamBold
    lockLbl.TextSize = 13
    lockLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lockLbl.TextStrokeTransparency = 0.45
    lockLbl.Visible = false
    lockLbl.ZIndex = 3
    lockLbl.Parent = gui
    STATE.lockLabel = lockLbl

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(270, 155)
    panel.Position = UDim2.new(0.5, -135, 0, 90)
    panel.BackgroundColor3 = Color3.fromRGB(14, 14, 18)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = true
    panel.Visible = true
    panel.ZIndex = 10
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local ps = Instance.new("UIStroke", panel)
    ps.Color = Color3.fromRGB(55, 55, 70)
    STATE.panel = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 28)
    title.Position = UDim2.fromOffset(12, 2)
    title.BackgroundTransparency = 1
    title.Text = "SILENT v10 FULL GACOR"
    title.TextColor3 = Color3.fromRGB(240, 240, 250)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 14
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 11
    title.Parent = panel

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(24, 24)
    minBtn.Position = UDim2.new(1, -56, 0, 4)
    minBtn.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
    minBtn.Text = "—"
    minBtn.TextColor3 = Color3.new(1,1,1)
    minBtn.Font = Enum.Font.GothamBold
    minBtn.TextSize = 16
    minBtn.BorderSizePixel = 0
    minBtn.ZIndex = 12
    minBtn.Parent = panel
    Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 4)

    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.fromOffset(24, 24)
    closeBtn.Position = UDim2.new(1, -28, 0, 4)
    closeBtn.BackgroundColor3 = Color3.fromRGB(180, 40, 40)
    closeBtn.Text = "X"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 14
    closeBtn.BorderSizePixel = 0
    closeBtn.ZIndex = 12
    closeBtn.Parent = panel
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 4)
    closeBtn.MouseButton1Click:Connect(function() cleanup() end)

    local toggle = Instance.new("TextButton")
    toggle.Size = UDim2.fromOffset(246, 34)
    toggle.Position = UDim2.fromOffset(12, 36)
    toggle.BackgroundColor3 = Color3.fromRGB(35, 35, 45)
    toggle.Text = "SILENT: OFF"
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 14
    toggle.BorderSizePixel = 0
    toggle.ZIndex = 11
    toggle.Parent = panel
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

    local fovLabel = Instance.new("TextLabel")
    fovLabel.Size = UDim2.fromOffset(246, 18)
    fovLabel.Position = UDim2.fromOffset(12, 80)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = "FOV: 150  |  Range: 280"
    fovLabel.TextColor3 = Color3.fromRGB(190, 190, 205)
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.TextSize = 12
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.ZIndex = 11
    fovLabel.Parent = panel

    local slider = Instance.new("Frame")
    slider.Size = UDim2.fromOffset(246, 7)
    slider.Position = UDim2.fromOffset(12, 108)
    slider.BackgroundColor3 = Color3.fromRGB(45, 45, 55)
    slider.BorderSizePixel = 0
    slider.ZIndex = 11
    slider.Parent = panel
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0.4, 1)
    fill.BackgroundColor3 = Color3.fromRGB(0, 210, 90)
    fill.BorderSizePixel = 0
    fill.ZIndex = 12
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    local info = Instance.new("TextLabel")
    info.Size = UDim2.fromOffset(246, 18)
    info.Position = UDim2.fromOffset(12, 125)
    info.BackgroundTransparency = 1
    info.Text = "AutoThrow: ON (F to toggle)"
    info.TextColor3 = Color3.fromRGB(160, 160, 180)
    info.Font = Enum.Font.Gotham
    info.TextSize = 11
    info.TextXAlignment = Enum.TextXAlignment.Left
    info.ZIndex = 11
    info.Parent = panel

    toggle.MouseButton1Click:Connect(function()
        STATE.autoAimOn = not STATE.autoAimOn
        toggle.Text = STATE.autoAimOn and "SILENT: ON" or "SILENT: OFF"
        toggle.BackgroundColor3 = STATE.autoAimOn and Color3.fromRGB(0, 150, 70) or Color3.fromRGB(35, 35, 45)
        STATE.fovCircle.Visible = STATE.autoAimOn
        STATE.statusLabel.Visible = STATE.autoAimOn
        if not STATE.autoAimOn then
            STATE.lockedTarget = nil
            STATE.lastAimDir = nil
            STATE.lockLabel.Visible = false
        end
    end)

    local function updateSlider(inputPos)
        local rel = math.clamp((inputPos.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.fromScale(rel, 1)
        STATE.fovDeg = 40 + rel * 320
        fovLabel.Text = string.format("FOV: %.0f  |  Range: 280", STATE.fovDeg)
        updateFovCircle()
    end

    slider.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            updateSlider(input.Position)
            local moveConn
            moveConn = UserInputService.InputChanged:Connect(function(inp)
                if inp.UserInputType == Enum.UserInputType.MouseMovement or inp.UserInputType == Enum.UserInputType.Touch then
                    updateSlider(inp.Position)
                end
            end)
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    if moveConn then moveConn:Disconnect() end
                end
            end)
        end
    end)

    -- F key toggle AutoThrow
    UserInputService.InputBegan:Connect(function(input, gpe)
        if gpe then return end
        if input.KeyCode == Enum.KeyCode.F then
            CONFIG.AUTO_THROW = not CONFIG.AUTO_THROW
            info.Text = "AutoThrow: " .. (CONFIG.AUTO_THROW and "ON" or "OFF") .. " (F to toggle)"
        end
    end)

    local mini = Instance.new("TextButton")
    mini.Size = UDim2.fromOffset(130, 32)
    mini.Position = UDim2.new(0, 20, 0, 20)
    mini.BackgroundColor3 = Color3.fromRGB(18, 18, 22)
    mini.BorderSizePixel = 0
    mini.Text = "≡  Silent v10"
    mini.TextColor3 = Color3.new(1,1,1)
    mini.Font = Enum.Font.GothamBold
    mini.TextSize = 13
    mini.Visible = false
    mini.Active = true
    mini.ZIndex = 15
    mini.Parent = gui
    Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 8)
    local miniStroke = Instance.new("UIStroke", mini)
    miniStroke.Color = Color3.fromRGB(70, 70, 90)
    STATE.miniBtn = mini

    minBtn.MouseButton1Click:Connect(function()
        STATE.minimized = true
        mini.Position = panel.Position
        panel.Visible = false
        mini.Visible = true
    end)

    mini.MouseButton1Click:Connect(function()
        STATE.minimized = false
        panel.Position = mini.Position
        panel.Visible = true
        mini.Visible = false
    end)

    local mDragging, mDragStart, mStartPos
    mini.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            mDragging = true
            mDragStart = input.Position
            mStartPos = mini.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then mDragging = false end
            end)
        end
    end)
    mini.InputChanged:Connect(function(input)
        if not mDragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - mDragStart
            mini.Position = UDim2.new(mStartPos.X.Scale, mStartPos.X.Offset + delta.X, mStartPos.Y.Scale, mStartPos.Y.Offset + delta.Y)
        end
    end)
end

local function updateCdLabel()
    if not STATE.cdLabel then return end
    local remaining = STATE.cdEndTime - tick()
    if remaining > 0.05 then
        STATE.cdLabel.Visible = true
        STATE.cdLabel.Text = string.format("⏱ Aura CD: %.1fs", remaining)
    else
        STATE.cdLabel.Visible = false
    end
end

local function updateStatus()
    if not STATE.statusLabel then return end
    if not STATE.autoAimOn then
        STATE.statusLabel.Visible = false
        return
    end
    STATE.statusLabel.Visible = true
    if STATE.lockedTarget and STATE.lastAimDir then
        STATE.statusLabel.Text = "LOCKED — READY"
        STATE.statusLabel.TextColor3 = Color3.fromRGB(0, 255, 120)
    else
        STATE.statusLabel.Text = "SCANNING..."
        STATE.statusLabel.TextColor3 = Color3.fromRGB(255, 200, 80)
    end
end

-- ============================================================
-- INIT
-- ============================================================
local function init()
    if getgenv().VeilAutoAimCleanup then
        pcall(getgenv().VeilAutoAimCleanup)
    end
    getgenv().VeilAutoAimCleanup = cleanup

    buildUI()
    updateFovCircle()
    setupCdTrackerAndSilent()

    STATE.scanConn = RunService.RenderStepped:Connect(function(dt)
        updateFovCircle()
        updateTarget(dt)
        updateLockLabel()
        updateCdLabel()
        updateStatus()
        if CONFIG.AUTO_THROW then
            tryAutoThrow()
        end
    end)

    print("[VeilSilent v10 FULL GACOR] 280 stud | aggressive redirect | AutoThrow | prediction+")
end

init()
