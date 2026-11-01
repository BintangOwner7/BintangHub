--[[
    VEIL SILENT AIM — v8 TRUE SILENT
    Base: v7 POST-NERF + ballistic core
    CHANGES:
    - Camera NEVER locked / snapped
    - Silent 100% via Spearthrow remote redirect
    - Ballistic math kept (speed 165, gravity 98.1, MaxLife 4)
    - Dynamic range check + sticky lock + knocked/hook skip kept
    - FOV / UI / CD tracker kept
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LP = Players.LocalPlayer
local Cam = workspace.CurrentCamera

local CONFIG = {
    GRAVITY = 98.1,
    SPEAR_SPEED = 165,          -- post-nerf
    SPAWN_OFFSET = 3,
    MAX_LIFE = 4,
    FOV_DEFAULT = 120,
    AIM_POINT = "HumanoidRootPart",
    AIM_Y_OFFSET = 0,
    MAX_TARGET_DIST_BROAD = 2000,
    PASSIVE_CD = 45,
    COLOR_LOCK = Color3.fromRGB(0, 255, 80),
    COLOR_NO_TARGET = Color3.fromRGB(255, 255, 255)
}

local STATE = {
    autoAimOn = false,
    isHolding = false,
    locked = false,
    minimized = false,
    fovDeg = CONFIG.FOV_DEFAULT,
    lockedTarget = nil,
    gui = nil,
    panel = nil,
    floatingBtn = nil,
    fovCircle = nil,
    lockLabel = nil,
    miniBtn = nil,
    cdLabel = nil,
    cdEndTime = 0,
    connections = {},
    scanConn = nil,
    oldNamecall = nil,
    hookMT = nil,
    -- silent runtime
    lastAimDir = nil,
    lastOrigin = nil,
    lastFlightTime = nil
}

-- ============================================================
-- BALLISTIC CORE (same as v7)
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

    if disc < 0 then
        return false, nil, nil
    end

    local sqrtDisc = math.sqrt(disc)
    local tanTheta = (v2 - sqrtDisc) / (g * d)
    local theta = math.atan(tanTheta)
    local cosTheta = math.cos(theta)
    if cosTheta <= 0.001 then
        return false, nil, nil
    end

    local t = d / (speed * cosTheta)
    if t < 0 or t > CONFIG.MAX_LIFE then
        return false, nil, nil
    end
    return true, t, theta
end

local function computeAimDirection(origin, targetPos, speed)
    local g = CONFIG.GRAVITY
    local dir = (targetPos - origin).Unit
    local lastT = nil

    for i = 1, 3 do
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

        local cosT = math.cos(theta)
        if cosT > 0.001 then
            lastT = d / (speed * cosT)
        end
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

-- ============================================================
-- FOV & TARGET SCAN (same sticky logic)
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
    if not (STATE.autoAimOn and STATE.isHolding) then
        STATE.lockedTarget = nil
        STATE.lastAimDir = nil
        if STATE.lockLabel then STATE.lockLabel.Visible = false end
        return
    end

    -- sticky lock
    if STATE.lockedTarget then
        local tChar = STATE.lockedTarget.Character
        local tHum = tChar and tChar:FindFirstChildOfClass("Humanoid")
        local tHrp = tChar and tChar:FindFirstChild(CONFIG.AIM_POINT)

        if not (tChar and tChar.Parent and tHum and tHrp and isValidTarget(tChar, tHum)) then
            STATE.lockedTarget = nil
            STATE.lastAimDir = nil
        else
            local myPos = Cam.CFrame.Position
            local targetLivePos = tHrp.Position + Vector3.new(0, CONFIG.AIM_Y_OFFSET, 0)
            local reachable = isReachable(myPos, targetLivePos)
            if not reachable then
                STATE.lockedTarget = nil
                STATE.lastAimDir = nil
            else
                local worldDist = (tHrp.Position - myPos).Magnitude
                if worldDist > CONFIG.MAX_TARGET_DIST_BROAD then
                    STATE.lockedTarget = nil
                    STATE.lastAimDir = nil
                else
                    -- update silent aim data every frame
                    local aimDir, ok, t = computeAimDirection(myPos, targetLivePos, CONFIG.SPEAR_SPEED)
                    if ok then
                        STATE.lastAimDir = aimDir
                        STATE.lastOrigin = myPos
                        STATE.lastFlightTime = t
                    end
                    return
                end
            end
        end
    end

    scanAccum = scanAccum + dt
    if scanAccum < 0.05 then return end
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
                    local livePos = hrp.Position + Vector3.new(0, CONFIG.AIM_Y_OFFSET, 0)
                    local reachable = isReachable(camPos, livePos)
                    if reachable then
                        local worldDist = (hrp.Position - camPos).Magnitude
                        if worldDist <= CONFIG.MAX_TARGET_DIST_BROAD then
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
            local livePos = hrp.Position + Vector3.new(0, CONFIG.AIM_Y_OFFSET, 0)
            local aimDir, ok, t = computeAimDirection(camPos, livePos, CONFIG.SPEAR_SPEED)
            if ok then
                STATE.lastAimDir = aimDir
                STATE.lastOrigin = camPos
                STATE.lastFlightTime = t
            end
        end
    else
        STATE.lastAimDir = nil
    end
end

-- ============================================================
-- SILENT LABEL (no camera move)
-- ============================================================
local function updateLockLabel()
    if not STATE.lockLabel then return end
    if not (STATE.autoAimOn and STATE.isHolding and STATE.lockedTarget and STATE.lastAimDir) then
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
        STATE.lockLabel.Position = UDim2.fromOffset(sp.X, sp.Y - 20)
        STATE.lockLabel.Text = string.format("SILENT\n%.0f studs | t=%.2fs", dist, STATE.lastFlightTime or 0)
        STATE.lockLabel.TextColor3 = CONFIG.COLOR_LOCK
    else
        STATE.lockLabel.Visible = false
    end
end

-- ============================================================
-- CD TRACKER + SILENT REMOTE HOOK
-- ============================================================
local function setupCdTrackerAndSilent()
    -- CD tracker (keep)
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

    -- TRUE SILENT: redirect Spearthrow payload
    local ok2, spRemote = pcall(function() return ReplicatedStorage.Remotes.Killers.Veil.Spearthrow end)
    if not ok2 or not spRemote then
        warn("[VeilSilent] Spearthrow remote not found — silent disabled")
        return
    end

    if type(hookmetamethod) ~= "function" then
        warn("[VeilSilent] hookmetamethod not available")
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
            -- CD tracking (keep)
            local payload = args[1]
            if type(payload) == "table" then
                local t = payload.Time
                local rel = payload.ReleasedAt
                if type(t) == "number" and type(rel) == "number" then
                    if (t - rel) >= 2.0 then
                        STATE.cdEndTime = tick() + CONFIG.PASSIVE_CD
                    end
                end
            end

            -- SILENT REDIRECT
            if STATE.autoAimOn and STATE.isHolding and STATE.lastAimDir and STATE.lockedTarget then
                local newPayload = payload
                if type(newPayload) ~= "table" then
                    newPayload = {}
                else
                    -- shallow copy biar ga rusak original reference
                    local copy = {}
                    for k, v in pairs(newPayload) do
                        copy[k] = v
                    end
                    newPayload = copy
                end

                -- overwrite direction fields yang umum dipakai projectile
                newPayload.Direction = STATE.lastAimDir
                newPayload.LookVector = STATE.lastAimDir
                newPayload.Velocity = STATE.lastAimDir * CONFIG.SPEAR_SPEED
                newPayload.Origin = STATE.lastOrigin or Cam.CFrame.Position
                newPayload.Position = STATE.lastOrigin or Cam.CFrame.Position

                -- force through-veil style jika ada flag
                if newPayload.Pierce ~= nil then newPayload.Pierce = true end
                if newPayload.ThroughVeil ~= nil then newPayload.ThroughVeil = true end
                if newPayload.IgnoreCollision ~= nil then newPayload.IgnoreCollision = true end

                -- ganti argumen pertama
                args[1] = newPayload
                return oldNamecall(self, unpack(args))
            end
        end

        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)
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
    STATE.isHolding = false
    STATE.autoAimOn = false
    STATE.lastAimDir = nil

    if getgenv().VeilAutoAimCleanup == cleanup then
        getgenv().VeilAutoAimCleanup = nil
    end
    print("[VeilSilent v8] Unloaded cleanly.")
end

-- ============================================================
-- UI (sama, cuma label jadi SILENT)
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
    cdLbl.Size = UDim2.fromOffset(250, 34)
    cdLbl.Position = UDim2.new(0.5, -125, 0, 20)
    cdLbl.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    cdLbl.BackgroundTransparency = 0.3
    cdLbl.BorderSizePixel = 0
    cdLbl.Text = ""
    cdLbl.TextColor3 = Color3.fromRGB(255, 200, 60)
    cdLbl.Font = Enum.Font.GothamBold
    cdLbl.TextSize = 15
    cdLbl.Visible = false
    cdLbl.ZIndex = 50
    cdLbl.Parent = gui
    Instance.new("UICorner", cdLbl).CornerRadius = UDim.new(0, 8)
    STATE.cdLabel = cdLbl

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
    fs.Thickness = 1
    fs.Transparency = 0.5
    STATE.fovCircle = fov

    local lockLbl = Instance.new("TextLabel")
    lockLbl.AnchorPoint = Vector2.new(0.5, 0.5)
    lockLbl.BackgroundTransparency = 1
    lockLbl.Text = ""
    lockLbl.TextColor3 = CONFIG.COLOR_LOCK
    lockLbl.Font = Enum.Font.GothamBold
    lockLbl.TextSize = 13
    lockLbl.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    lockLbl.TextStrokeTransparency = 0.5
    lockLbl.Visible = false
    lockLbl.ZIndex = 3
    lockLbl.Parent = gui
    STATE.lockLabel = lockLbl

    local panel = Instance.new("Frame")
    panel.Size = UDim2.fromOffset(260, 140)
    panel.Position = UDim2.new(0.5, -130, 0, 80)
    panel.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    panel.BorderSizePixel = 0
    panel.Active = true
    panel.Draggable = true
    panel.Visible = true
    panel.ZIndex = 10
    panel.Parent = gui
    Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 8)
    local ps = Instance.new("UIStroke", panel); ps.Color = Color3.fromRGB(60, 60, 72); ps.Parent = panel
    STATE.panel = panel

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -60, 0, 30)
    title.Position = UDim2.fromOffset(10, 0)
    title.BackgroundTransparency = 1
    title.Text = "SILENT AIM v8 — NO CAM LOCK"
    title.TextColor3 = Color3.fromRGB(235, 235, 245)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.ZIndex = 11
    title.Parent = panel

    local minBtn = Instance.new("TextButton")
    minBtn.Size = UDim2.fromOffset(24, 24)
    minBtn.Position = UDim2.new(1, -56, 0, 3)
    minBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
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
    closeBtn.Position = UDim2.new(1, -28, 0, 3)
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
    toggle.Size = UDim2.fromOffset(240, 32)
    toggle.Position = UDim2.fromOffset(10, 35)
    toggle.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
    toggle.Text = "SILENT: OFF"
    toggle.TextColor3 = Color3.new(1,1,1)
    toggle.Font = Enum.Font.GothamBold
    toggle.TextSize = 13
    toggle.BorderSizePixel = 0
    toggle.ZIndex = 11
    toggle.Parent = panel
    Instance.new("UICorner", toggle).CornerRadius = UDim.new(0, 6)

    local fovLabel = Instance.new("TextLabel")
    fovLabel.Size = UDim2.fromOffset(240, 20)
    fovLabel.Position = UDim2.fromOffset(10, 75)
    fovLabel.BackgroundTransparency = 1
    fovLabel.Text = "FOV: 120"
    fovLabel.TextColor3 = Color3.fromRGB(200, 200, 210)
    fovLabel.Font = Enum.Font.Gotham
    fovLabel.TextSize = 12
    fovLabel.TextXAlignment = Enum.TextXAlignment.Left
    fovLabel.ZIndex = 11
    fovLabel.Parent = panel

    local slider = Instance.new("Frame")
    slider.Size = UDim2.fromOffset(240, 6)
    slider.Position = UDim2.fromOffset(10, 100)
    slider.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    slider.BorderSizePixel = 0
    slider.ZIndex = 11
    slider.Parent = panel
    Instance.new("UICorner", slider).CornerRadius = UDim.new(1, 0)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0.33, 1)
    fill.BackgroundColor3 = Color3.fromRGB(0, 200, 80)
    fill.BorderSizePixel = 0
    fill.ZIndex = 12
    fill.Parent = slider
    Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)

    toggle.MouseButton1Click:Connect(function()
        STATE.autoAimOn = not STATE.autoAimOn
        toggle.Text = STATE.autoAimOn and "SILENT: ON" or "SILENT: OFF"
        toggle.BackgroundColor3 = STATE.autoAimOn and Color3.fromRGB(0, 140, 60) or Color3.fromRGB(40, 40, 50)
        STATE.fovCircle.Visible = STATE.autoAimOn
        STATE.floatingBtn.Visible = STATE.autoAimOn
        if not STATE.autoAimOn then
            STATE.lockedTarget = nil
            STATE.lastAimDir = nil
            STATE.lockLabel.Visible = false
        end
    end)

    local function updateSlider(inputPos)
        local rel = math.clamp((inputPos.X - slider.AbsolutePosition.X) / slider.AbsoluteSize.X, 0, 1)
        fill.Size = UDim2.fromScale(rel, 1)
        STATE.fovDeg = 30 + rel * 330
        fovLabel.Text = string.format("FOV: %.0f", STATE.fovDeg)
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

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.fromOffset(70, 70)
    btn.AnchorPoint = Vector2.new(0.5, 0.5)
    btn.Position = UDim2.fromScale(0.5, 0.75)
    btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    btn.BorderSizePixel = 0
    btn.Text = "SILENT"
    btn.TextColor3 = Color3.new(1,1,1)
    btn.Font = Enum.Font.GothamBold
    btn.TextSize = 14
    btn.AutoButtonColor = false
    btn.Active = true
    btn.Visible = false
    btn.ZIndex = 20
    btn.Parent = gui
    Instance.new("UICorner", btn).CornerRadius = UDim.new(1, 0)

    local stroke = Instance.new("UIStroke", btn)
    stroke.Color = Color3.fromRGB(80, 80, 80)
    stroke.Thickness = 2
    STATE.floatingBtn = btn

    local lockBtn = Instance.new("TextButton")
    lockBtn.Size = UDim2.fromOffset(24, 24)
    lockBtn.Position = UDim2.new(1, -24, 0, 0)
    lockBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
    lockBtn.Text = "🔓"
    lockBtn.TextColor3 = Color3.new(1,1,1)
    lockBtn.Font = Enum.Font.GothamBold
    lockBtn.TextSize = 12
    lockBtn.BorderSizePixel = 0
    lockBtn.ZIndex = 21
    lockBtn.Parent = btn
    Instance.new("UICorner", lockBtn).CornerRadius = UDim.new(1, 0)

    lockBtn.MouseButton1Click:Connect(function()
        STATE.locked = not STATE.locked
        lockBtn.Text = STATE.locked and "🔒" or "🔓"
        lockBtn.BackgroundColor3 = STATE.locked and Color3.fromRGB(180, 60, 60) or Color3.fromRGB(50, 50, 50)
    end)

    btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = UserInputService:GetMouseLocation()
            local btnPos = btn.AbsolutePosition
            local isLockBtn = (mousePos.X > btnPos.X + btn.AbsoluteSize.X - 24) and (mousePos.Y < btnPos.Y + 24)
            if not isLockBtn then
                STATE.isHolding = true
                STATE.lockedTarget = nil
                STATE.lastAimDir = nil
                btn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
                stroke.Color = Color3.fromRGB(0, 255, 80)
            end
        end
    end)

    btn.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            STATE.isHolding = false
            STATE.lockedTarget = nil
            STATE.lastAimDir = nil
            btn.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
            stroke.Color = Color3.fromRGB(80, 80, 80)
        end
    end)

    local dragging, dragStart, startPos
    btn.InputBegan:Connect(function(input)
        if STATE.locked then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local mousePos = UserInputService:GetMouseLocation()
            local btnPos = btn.AbsolutePosition
            if mousePos.X > btnPos.X + btn.AbsoluteSize.X - 24 and mousePos.Y < btnPos.Y + 24 then return end

            dragging = true
            dragStart = input.Position
            startPos = btn.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)

    btn.InputChanged:Connect(function(input)
        if not dragging then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            btn.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)

    local mini = Instance.new("TextButton")
    mini.Size = UDim2.fromOffset(130, 32)
    mini.Position = UDim2.new(0, 20, 0, 20)
    mini.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
    mini.BorderSizePixel = 0
    mini.Text = "≡  Silent"
    mini.TextColor3 = Color3.new(1,1,1)
    mini.Font = Enum.Font.GothamBold
    mini.TextSize = 13
    mini.Visible = false
    mini.Active = true
    mini.ZIndex = 15
    mini.Parent = gui
    Instance.new("UICorner", mini).CornerRadius = UDim.new(0, 8)
    local miniStroke = Instance.new("UIStroke", mini)
    miniStroke.Color = Color3.fromRGB(80, 80, 100)
    miniStroke.Thickness = 1
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
    end)

    print("[VeilSilent v8] Loaded — camera free, silent via Spearthrow redirect | Speed=165 Gravity=98.1")
end

init()
