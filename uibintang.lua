-- ============================================================
-- BINTANGHUB | FULL LOGIC & UI (LIGHT VERSION)
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CoreGui = game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local Theme = {
    Bg = Color3.fromRGB(10, 11, 15),
    Sidebar = Color3.fromRGB(15, 16, 22),
    Card = Color3.fromRGB(22, 24, 32),
    Element = Color3.fromRGB(32, 35, 46),
    Accent = Color3.fromRGB(255, 60, 60),
    AccentDark = Color3.fromRGB(180, 30, 30),
    Text = Color3.fromRGB(235, 235, 240),
    TextDim = Color3.fromRGB(130, 135, 150),
    Line = Color3.fromRGB(45, 48, 60)
}

local Config = {
    ESP = false, ESP_Target = "Both", ESP_Style = "Chams", ESP_Name = false, ESP_Dist = false, Color_Survivor = Color3.fromRGB(0, 255, 0), Color_Killer = Color3.fromRGB(255, 0, 0),
    WorldESP = false, WorldESP_Targets = "All",
    Camera_FOV = false, Camera_FOVVal = 70, Camera_DBD = false,
    Light_Fullbright = false, Light_NoFog = false,
    AutoSkill = "Disabled", BoostGen = false,
    AutoParry = false, Parry_Aggressive = false, Parry_Dist = 15,
    GodMode = false, AntiFall = false, AutoCrouch = false, Invis = false,
    FakeQR = false, FakePL = false, FakeFS = false,
    SilentAim = false, AimTarget = "Killer", Aim_Flash = false,
    Veil_Enabled = false, Veil_Predict = false, Veil_Speed = 165, Veil_Gravity = 103, Veil_Lead = 1.4, Veil_AuraSpeed = 165, Veil_AuraGrav = 96, Veil_Tracker = false, Veil_ShowFOV = false, Veil_FOVRadius = 150,
    Killer_Aimbot = false, Killer_MeleeDist = 12, Killer_Smooth = 5, DashLock = false, HoldingM2 = false,
    Noclip = false, SpeedHack = false, SpeedVal = 20,
    NextKiller = false, NextMap = false
}

local State = { 
    ParryLast = 0, ActiveAttackers = {}, ESPInstances = {}, WorldESPInstances = {}, ValidWorldObjects = {},
    FakePerks = {conns = {}, boost = false, pl = false, fsCD = false, lastQR = 0, lastPL = 0, lastFS = 0},
    DashLock = {target = nil, lock = false, lastLock = 0, timer = nil},
    Veil = {target = nil, look = nil, vel = {}},
    SpooferConns = {}
}

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function Round(inst, radius) Create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = inst }) end
local function Stroke(inst, color, thick, trans) Create("UIStroke", { Color = color, Thickness = thick or 1, Transparency = trans or 0, Parent = inst }) end

local Gui = Create("ScreenGui", { Name = "BintangHub", ResetOnSpawn = false, DisplayOrder = 100, IgnoreGuiInset = true, Parent = CoreGui })

local Icon = Create("TextButton", { Size = UDim2.new(0, 45, 0, 45), Position = UDim2.new(0, 20, 0, 20), BackgroundColor3 = Theme.Bg, Text = "BH", TextColor3 = Theme.Accent, Font = Enum.Font.GothamBlack, TextSize = 18, AutoButtonColor = false, Parent = Gui })
Round(Icon, 22); Stroke(Icon, Theme.Accent, 1.5, 0.2)

local Window = Create("Frame", { Size = UDim2.new(0, 540, 0, 360), Position = UDim2.new(0.5, -270, 0.5, -180), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Active = true, Draggable = true, Visible = false, Parent = Gui })
Round(Window, 14); Stroke(Window, Theme.Line, 1.5, 0.2)

Icon.MouseButton1Click:Connect(function() Window.Visible = not Window.Visible end)

local Sidebar = Create("Frame", { Size = UDim2.new(0, 140, 1, 0), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = Window })
Round(Sidebar, 14)

Create("TextLabel", { Size = UDim2.new(1, -20, 0, 50), Position = UDim2.new(0, 15, 0, 5), BackgroundTransparency = 1, Text = "BintangHub☠️", TextColor3 = Theme.Accent, Font = Enum.Font.GothamBlack, TextSize = 16, TextXAlignment = Enum.TextXAlignment.Left, Parent = Sidebar })

local TabContainer = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -70), Position = UDim2.new(0, 10, 0, 55), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 0, Parent = Sidebar })
Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabContainer })

local Content = Create("Frame", { Size = UDim2.new(1, -140, 1, 0), Position = UDim2.new(0, 140, 0, 0), BackgroundTransparency = 1, Parent = Window })

local Tabs = {}
local function AddTab(name)
    local btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Sidebar, Text = "", AutoButtonColor = false, Parent = TabContainer })
    Round(btn, 6)
    Create("TextLabel", { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.TextDim, Font = Enum.Font.GothamBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })
    local activeBar = Create("Frame", { Size = UDim2.new(0, 3, 1, -12), Position = UDim2.new(0, 0, 0, 6), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Visible = false, Parent = btn })
    Round(activeBar, 1.5)
    local page = Create("ScrollingFrame", { Size = UDim2.new(1, -20, 1, -20), Position = UDim2.new(0, 10, 0, 10), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Accent, Visible = false, Parent = Content })
    Create("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    Tabs[name] = { Button = btn, Page = page, Bar = activeBar }
    btn.MouseButton1Click:Connect(function()
        for tName, t in pairs(Tabs) do
            t.Page.Visible = (tName == name)
            t.Button.BackgroundColor3 = (tName == name) and Theme.Card or Theme.Sidebar
            t.Bar.Visible = (tName == name)
            local txt = t.Button:FindFirstChildOfClass("TextLabel")
            if txt then txt.TextColor3 = (tName == name) and Theme.Text or Theme.TextDim end
        end
    end)
    return page
end

local function AddSection(page, title)
    local sec = Create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.2, BorderSizePixel = 0, Parent = page })
    Round(sec, 10); Stroke(sec, Theme.Line, 1, 0.3)
    Create("TextLabel", { Size = UDim2.new(1, -30, 0, 30), Position = UDim2.new(0, 15, 0, 5), BackgroundTransparency = 1, Text = title:upper(), TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = sec })
    Create("Frame", { Size = UDim2.new(1, -30, 0, 1), Position = UDim2.new(0, 15, 0, 30), BackgroundColor3 = Theme.Line, BorderSizePixel = 0, Parent = sec })
    local cont = Create("Frame", { Size = UDim2.new(1, -30, 0, 0), Position = UDim2.new(0, 15, 0, 40), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Parent = sec })
    Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = cont })
    return cont
end

local function AddToggle(parent, name, default, callback)
    local state = default
    local btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 32), BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.3, Text = "", AutoButtonColor = false, Parent = parent })
    Round(btn, 8); Stroke(btn, Theme.Line, 1, 0.8)
    Create("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.new(0, 12, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })
    local track = Create("Frame", { Size = UDim2.new(0, 36, 0, 18), Position = UDim2.new(1, -48, 0.5, -9), BackgroundColor3 = state and Theme.AccentDark or Theme.Line, BorderSizePixel = 0, Parent = btn })
    Round(track, 9)
    local knob = Create("Frame", { Size = UDim2.new(0, 14, 0, 14), Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7), BackgroundColor3 = state and Theme.Accent or Theme.TextDim, BorderSizePixel = 0, Parent = track })
    Round(knob, 7)
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, TweenInfo.new(0.2), { BackgroundColor3 = state and Theme.AccentDark or Theme.Line }):Play()
        TweenService:Create(knob, TweenInfo.new(0.2), { BackgroundColor3 = state and Theme.Accent or Theme.TextDim, Position = state and UDim2.new(1, -16, 0.5, -7) or UDim2.new(0, 2, 0.5, -7) }):Play()
        if callback then callback(state) end
    end)
end

local function AddSlider(parent, name, min, max, default, callback)
    local value = default
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 45), BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = parent })
    Round(frame, 8); Stroke(frame, Theme.Line, 1, 0.8)
    Create("TextLabel", { Size = UDim2.new(1, -60, 0, 20), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    local valLbl = Create("TextLabel", { Size = UDim2.new(0, 50, 0, 20), Position = UDim2.new(1, -60, 0, 5), BackgroundTransparency = 1, Text = tostring(value), TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame })
    local track = Create("Frame", { Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 0, 30), BackgroundColor3 = Theme.Line, BorderSizePixel = 0, Parent = frame })
    Round(track, 3)
    local fill = Create("Frame", { Size = UDim2.new((value-min)/(max-min), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track })
    Round(fill, 3)
    local dragging = false
    local function update(input)
        local rel = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        value = math.floor(min + rel * (max - min) + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        valLbl.Text = tostring(value)
        if callback then callback(value) end
    end
    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; update(input) end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then update(input) end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

local function AddDropdown(parent, name, options, default, callback)
    local selected = default or options[1]
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 55), BackgroundColor3 = Theme.Element, BackgroundTransparency = 0.3, BorderSizePixel = 0, Parent = parent })
    Round(frame, 8); Stroke(frame, Theme.Line, 1, 0.8)
    Create("TextLabel", { Size = UDim2.new(1, -60, 0, 20), Position = UDim2.new(0, 12, 0, 5), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, Font = Enum.Font.GothamMedium, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    local selLbl = Create("TextLabel", { Size = UDim2.new(0, 80, 0, 20), Position = UDim2.new(1, -90, 0, 5), BackgroundTransparency = 1, Text = selected .. " v", TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame })
    local list = Create("Frame", { Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 25), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Visible = false, AutomaticSize = Enum.AutomaticSize.Y, Parent = frame })
    Round(list, 6); Create("UIListLayout", { Padding = UDim.new(0, 2), Parent = list })
    for _, opt in pairs(options) do
        local optBtn = Create("TextButton", { Size = UDim2.new(1, -10, 0, 24), BackgroundColor3 = Theme.Card, Text = opt, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, Parent = list })
        Round(optBtn, 4)
        optBtn.MouseButton1Click:Connect(function()
            selected = opt; selLbl.Text = selected .. " v"; list.Visible = false
            if callback then callback(opt) end
        end)
    end
    local click = Create("TextButton", { Size = UDim2.new(1, 0, 0, 25), BackgroundTransparency = 1, Text = "", Parent = frame })
    click.MouseButton1Click:Connect(function() list.Visible = not list.Visible end)
end

local function AddButton(parent, name, callback)
    local btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 30), BackgroundColor3 = Theme.Accent, BackgroundTransparency = 0.8, Text = name:upper(), TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 11, Parent = parent })
    Round(btn, 6)
    btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.6 }):Play() end)
    btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.15), { BackgroundTransparency = 0.8 }):Play() end)
    btn.MouseButton1Click:Connect(callback)
end

-- ==========================================
-- LOGIC: ESP
-- ==========================================
local function ClearESP()
    for p, inst in pairs(State.ESPInstances) do
        if inst.Highlight then inst.Highlight:Destroy() end
        if inst.Billboard then inst.Billboard:Destroy() end
        State.ESPInstances[p] = nil
    end
end

RunService.RenderStepped:Connect(function()
    if not Config.ESP then ClearESP() else
        for _, plr in pairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer and plr.Character then
                local char = plr.Character
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local hum = char:FindFirstChildOfClass("Humanoid")
                if hrp and hum and hum.Health > 0 then
                    local isKiller = plr.Team and (plr.Team.Name:lower():find("killer"))
                    local active = (Config.ESP_Target == "Killer" and isKiller) or (Config.ESP_Target == "Survivor" and not isKiller) or (Config.ESP_Target == "Both")
                    if active then
                        if not State.ESPInstances[plr] then
                            local hl = Instance.new("Highlight", char)
                            local bb = Instance.new("BillboardGui", hrp)
                            bb.Size = UDim2.new(0, 200, 0, 50); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 3, 0)
                            local txt = Instance.new("TextLabel", bb)
                            txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBold; txt.TextStrokeTransparency = 0
                            State.ESPInstances[plr] = { Highlight = hl, Billboard = bb, Text = txt }
                        end
                        local inst = State.ESPInstances[plr]
                        local col = isKiller and Config.Color_Killer or Config.Color_Survivor
                        inst.Highlight.FillColor = col; inst.Highlight.OutlineColor = col; inst.Highlight.Enabled = true; inst.Highlight.Adornee = char
                        inst.Billboard.Enabled = true
                        local txt = ""
                        if Config.ESP_Name then txt = plr.Name .. "\n" end
                        if Config.ESP_Dist then txt = txt .. "[" .. math.floor((hrp.Position - Camera.CFrame.Position).Magnitude) .. "m]" end
                        inst.Text.Text = txt; inst.Text.TextColor3 = col
                    else
                        if State.ESPInstances[plr] then State.ESPInstances[plr].Highlight.Enabled = false; State.ESPInstances[plr].Billboard.Enabled = false end
                    end
                end
            end
        end
    end
end)

-- ==========================================
-- LOGIC: AUTO PARRY
-- ==========================================
local KillerAttackAnims = { ["rbxassetid://78432063483146"]="attack", ["rbxassetid://121216847022485"]="attack", ["rbxassetid://74968262036854"]="attack", ["rbxassetid://122812055447896"]="lungehold" }
local function ExecuteParry()
    if tick() - State.ParryLast < 0.2 then return end
    State.ParryLast = tick()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mobBtn = pGui and pGui:FindFirstChild("Survivor-mob") and pGui["Survivor-mob"]:FindFirstChild("Controls") and pGui["Survivor-mob"].Controls:FindFirstChild("Gui-mob")
    if mobBtn and type(firesignal) == "function" then
        firesignal(mobBtn.MouseButton1Down); task.delay(0.05, function() if mobBtn and mobBtn.Parent then firesignal(mobBtn.MouseButton1Up) end end)
    else
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.05); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end
end
RunService.Heartbeat:Connect(function()
    if not Config.AutoParry then return end
    local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
    if not myRoot then return end
    for plr, data in pairs(State.ActiveAttackers) do
        if data.track and data.track.IsPlaying and data.char then
            local kRoot = data.char:FindFirstChild("HumanoidRootPart")
            if kRoot then
                local dist = (myRoot.Position - kRoot.Position).Magnitude
                if Config.Parry_Aggressive then
                    local ping = math.clamp(LocalPlayer:GetNetworkPing(), 0, 0.3)
                    local vel = kRoot.AssemblyLinearVelocity
                    local predPos = kRoot.Position + (Vector3.new(vel.X,0,vel.Z) * ping)
                    if (myRoot.Position - predPos).Magnitude <= (Config.Parry_Dist + 2) and Vector3.new(vel.X,0,vel.Z).Magnitude > 8 then ExecuteParry() end
                else
                    if dist <= Config.Parry_Dist then ExecuteParry() end
                end
            end
        else State.ActiveAttackers[plr] = nil end
    end
end)
for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function(char)
            local hum = char:WaitForChild("Humanoid", 5)
            if hum then
                local anim = hum:WaitForChild("Animator", 5)
                if anim then
                    anim.AnimationPlayed:Connect(function(track)
                        local id = tostring(track.Animation.AnimationId)
                        if KillerAttackAnims[id] then State.ActiveAttackers[plr] = { char = char, track = track } end
                    end)
                end
            end
        end)
    end
end

-- ==========================================
-- LOGIC: AUTO SKILLCHECK
-- ==========================================
local function DoSkillCheck()
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local mobBtn = pGui and pGui:FindFirstChild("Survivor-mob") and pGui["Survivor-mob"]:FindFirstChild("Controls") and pGui["Survivor-mob"].Controls:FindFirstChild("action")
    if mobBtn and type(firesignal) == "function" then
        firesignal(mobBtn.MouseButton1Down); task.delay(0.05, function() if mobBtn and mobBtn.Parent then firesignal(mobBtn.MouseButton1Up) end end)
    else
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.01); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game)
    end
end
RunService.RenderStepped:Connect(function()
    if Config.AutoSkill == "Disabled" then return end
    local pGui = LocalPlayer:FindFirstChild("PlayerGui")
    local prompt = pGui and (pGui:FindFirstChild("SkillCheckPromptGui") or pGui:FindFirstChild("SkillCheckPromptGui-con"))
    if prompt then
        local check = prompt:FindFirstChild("Check")
        if check and check.Visible then
            local line = check:FindFirstChild("Line"); local goal = check:FindFirstChild("Goal")
            if line and goal then
                if Config.AutoSkill == "Instant" then
                    line.Rotation = goal.Rotation + 109; DoSkillCheck()
                else
                    local relRot = (line.Rotation - goal.Rotation) % 360
                    local minR, maxR = (Config.AutoSkill == "Perfect") and 104 or 114, (Config.AutoSkill == "Perfect") and 114 or 155
                    if relRot >= minR and relRot <= maxR then DoSkillCheck() end
                end
            end
        end
    end
end)

-- ==========================================
-- LOGIC: SILENT AIM (PISTOL)
-- ==========================================
local AimCache = { LookVector = nil, TargetPos = nil, IsAiming = false }
UserInputService.InputBegan:Connect(function(i, gp) if not gp and i.UserInputType == Enum.UserInputType.MouseButton2 then AimCache.IsAiming = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then AimCache.IsAiming = false end end)
RunService.Heartbeat:Connect(function()
    if not Config.SilentAim then return end
    local char = LocalPlayer.Character
    if not char or not char:FindFirstChild("Twist of Fate") then return end
    local cam = workspace.CurrentCamera; local root = char:FindFirstChild("HumanoidRootPart")
    if not root then return end
    local best, minD = nil, math.huge
    for _, p in pairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Character then
            local isK = p.Team and p.Team.Name:lower():find("killer")
            if (Config.AimTarget == "Killer" and isK) or (Config.AimTarget == "Survivor" and not isK) then
                local hrp = p.Character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    local d = (hrp.Position - root.Position).Magnitude
                    if d < minD then minD = d; best = hrp end
                end
            end
        end
    end
    if best then
        AimCache.TargetPos = best.Position
        AimCache.LookVector = (best.Position - cam.CFrame.Position).Unit
    else
        AimCache.TargetPos = nil; AimCache.LookVector = nil
    end
end)
local oldNamecall = nil
task.spawn(function()
    oldNamecall = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod(); local args = {...}
        if not checkcaller() and method == "FireServer" and typeof(self) == "Instance" then
            if Config.SilentAim and self.Parent and self.Parent.Name == "Twist of Fate" and self.Name == "Fire" then
                if AimCache.LookVector then
                    for i = 1, #args do if typeof(args[i]) == "Vector3" then args[i] = AimCache.LookVector end end
                    return oldNamecall(self, unpack(args))
                end
            end
        end
        return oldNamecall(self, ...)
    end)
end)

-- ==========================================
-- LOGIC: DBD CAMERA & FOV
-- ==========================================
RunService.RenderStepped:Connect(function()
    if Config.Camera_DBD then
        local hrp = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
        if hrp then
            Camera.CameraType = Enum.CameraType.Scriptable
            local targetPos = hrp.Position - (hrp.CFrame.LookVector * 12) + Vector3.new(0, 4, 0)
            Camera.CFrame = Camera.CFrame:Lerp(CFrame.new(targetPos, hrp.Position + Vector3.new(0,1,0)), 0.2)
        end
    else
        if Camera.CameraType == Enum.CameraType.Scriptable then Camera.CameraType = Enum.CameraType.Custom end
    end
    if Config.Camera_FOV then Camera.FieldOfView = Config.Camera_FOVVal end
end)

-- ==========================================
-- LOGIC: LIGHTING
-- ==========================================
local Lighting = game:GetService("Lighting")
local OrigLight = {Saved = false}
RunService.Heartbeat:Connect(function()
    if Config.Light_Fullbright then
        pcall(function()
            if not OrigLight.Saved then OrigLight.Ambient = Lighting.Ambient; OrigLight.OutdoorAmbient = Lighting.OutdoorAmbient; OrigLight.Brightness = Lighting.Brightness; OrigLight.ClockTime = Lighting.ClockTime; OrigLight.GlobalShadows = Lighting.GlobalShadows; OrigLight.Saved = true end
            Lighting.Ambient = Color3.fromRGB(180, 180, 180); Lighting.OutdoorAmbient = Color3.fromRGB(180, 180, 180)
            Lighting.Brightness = 2; Lighting.ClockTime = 12; Lighting.GlobalShadows = false
        end)
    elseif OrigLight.Saved then
        pcall(function() Lighting.Ambient = OrigLight.Ambient; Lighting.OutdoorAmbient = OrigLight.OutdoorAmbient; Lighting.Brightness = OrigLight.Brightness; Lighting.ClockTime = OrigLight.ClockTime; Lighting.GlobalShadows = OrigLight.GlobalShadows; OrigLight.Saved = false end)
    end
    if Config.Light_NoFog then
        pcall(function()
            if not OrigLight.FogSaved then OrigLight.FogStart = Lighting.FogStart; OrigLight.FogEnd = Lighting.FogEnd; OrigLight.FogSaved = true end
            Lighting.FogStart = 100000; Lighting.FogEnd = 100000
            local atm = Lighting:FindFirstChildOfClass("Atmosphere"); if atm then atm.Density = 0 end
        end)
    end
end)

-- ==========================================
-- LOGIC: KILLER AIMBOT & DASH LOCK
-- ==========================================
local function GetClosestTargetForDash()
    local closestPlayer = nil
    local shortestDistance = math.huge
    local myChar = LocalPlayer.Character
    local myHRP = myChar and myChar:FindFirstChild("HumanoidRootPart")
    if not myHRP then return nil end
    for _, plr in ipairs(Players:GetPlayers()) do
        if plr ~= LocalPlayer and plr.Team and plr.Team.Name == "Survivors" and plr.Character then
            local targetHRP = plr.Character:FindFirstChild("HumanoidRootPart")
            local hum = plr.Character:FindFirstChildOfClass("Humanoid")
            local isDowned = plr.Character:GetAttribute("Knocked") == true or plr.Character:GetAttribute("IsHooked") == true
            if targetHRP and hum and hum.Health > 0 and not isDowned then
                local distance = (myHRP.Position - targetHRP.Position).Magnitude
                if distance < shortestDistance and distance < 100 then
                    shortestDistance = distance
                    closestPlayer = plr.Character
                end
            end
        end
    end
    return closestPlayer
end

local function TriggerDashLock()
    if not Config.DashLock then return end
    if State.DashLock.lock then return end
    if tick() - State.DashLock.lastLock < 0.2 then return end
    local myTeam = LocalPlayer.Team
    if not myTeam or (myTeam.Name ~= "Killer" and myTeam.Name ~= "Killers" and not string.find(string.lower(myTeam.Name), "iller")) then return end
    State.DashLock.lastLock = tick()
    State.DashLock.target = GetClosestTargetForDash()
    if State.DashLock.target and State.DashLock.target:FindFirstChild("HumanoidRootPart") then
        State.DashLock.lock = true
        if State.DashLock.timer then task.cancel(State.DashLock.timer) end
        State.DashLock.timer = task.delay(2, function()
            State.DashLock.lock = false
            State.DashLock.target = nil
        end)
    end
end

RunService.Heartbeat:Connect(function()
    if Config.DashLock and State.DashLock.lock and State.DashLock.target then
        local cam = workspace.CurrentCamera
        local targetPos = State.DashLock.target.HumanoidRootPart.Position
        cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, targetPos), 0.6)
    end
    if Config.Killer_Aimbot and Config.HoldingM2 then
        local myTeam = LocalPlayer.Team
        if myTeam and (myTeam.Name == "Killer" or myTeam.Name == "Killers" or string.find(string.lower(myTeam.Name), "iller")) then
            local cam = workspace.CurrentCamera
            local myChar = LocalPlayer.Character
            local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
            if myRoot then
                local closest, shortest = nil, Config.Killer_MeleeDist
                for _, plr in ipairs(Players:GetPlayers()) do
                    if plr ~= LocalPlayer and plr.Team and plr.Team.Name == "Survivors" and plr.Character then
                        local hrp = plr.Character:FindFirstChild("UpperTorso") or plr.Character:FindFirstChild("HumanoidRootPart")
                        local hum = plr.Character:FindFirstChildOfClass("Humanoid")
                        if hrp and hum and hum.Health > 0 then
                            local dist = (hrp.Position - myRoot.Position).Magnitude
                            if dist <= shortest then
                                local _, on = cam:WorldToViewportPoint(hrp.Position)
                                if on then shortest = dist; closest = hrp end
                            end
                        end
                    end
                end
                if closest then
                    local smooth = Config.Killer_Smooth / 10
                    cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, closest.Position), smooth)
                end
            end
        end
    end
end)

UserInputService.InputBegan:Connect(function(i, gp) if not gp and (i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2) then Config.HoldingM2 = true end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.MouseButton2 then Config.HoldingM2 = false end end)

-- ==========================================
-- LOGIC: SILENT VEIL
-- ==========================================
local function solvePitch(p, d, dy)
    d = math.max(d, 0.1)
    local s2 = p.v0 * p.v0
    local root = s2 * s2 - p.g * (p.g * d * d + 2 * dy * s2)
    local out = false
    if root < 0 then root = 0; out = true end
    local tanTheta = (s2 - math.sqrt(root)) / (p.g * d)
    local theta = math.atan(tanTheta)
    local t = d / (p.v0 * math.cos(theta))
    return theta, out, t
end

RunService.RenderStepped:Connect(function()
    if not Config.Veil_Enabled then State.Veil.look = nil; return end
    if LocalPlayer:GetAttribute("SelectedKiller") ~= "Veil" then State.Veil.look = nil; return end
    local cam = workspace.CurrentCamera
    local char = LocalPlayer.Character
    local hrp = char and char:FindFirstChild("HumanoidRootPart")
    if not cam or not hrp then return end
    local nearest, bestDist = nil, Config.Veil_FOVRadius
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer and p.Team and not string.find(string.lower(p.Team.Name), "iller") and p.Character then
            local isDown = p.Character:GetAttribute("Knocked") == true or p.Character:GetAttribute("HookProgressDepleting") == true
            if not isDown then
                local hum = p.Character:FindFirstChildOfClass("Humanoid")
                local tp = p.Character:FindFirstChild("UpperTorso") or p.Character:FindFirstChild("HumanoidRootPart")
                if hum and hum.Health > 0 and tp then
                    local sp, on = cam:WorldToViewportPoint(tp.Position)
                    if on and sp.Z > 0 then
                        local sd = (Vector2.new(sp.X, sp.Y) - Vector2.new(cam.ViewportSize.X/2, cam.ViewportSize.Y/2)).Magnitude
                        if sd < bestDist then bestDist = sd; nearest = p end
                    end
                end
            end
        end
    end
    if nearest and nearest.Character then
        local tpPart = nearest.Character:FindFirstChild("UpperTorso") or nearest.Character:FindFirstChild("HumanoidRootPart")
        if tpPart then
            local tp = tpPart.Position
            local hand = char:FindFirstChild("Right Arm") or char:FindFirstChild("RightHand")
            local origin = (hand and hand:IsA("BasePart")) and hand.Position or hrp.Position
            local dir = tp - origin
            local dist = dir.Magnitude
            if dist > 0.1 and dist <= 1000 then
                local isAura = char:GetAttribute("special") == true
                local v0 = isAura and Config.Veil_AuraSpeed or Config.Veil_Speed
                local g = isAura and Config.Veil_AuraGrav or Config.Veil_Gravity
                local aimPoint = tp
                if Config.Veil_Predict then
                    local vel = tpPart.AssemblyLinearVelocity or Vector3.zero
                    local flatVel = Vector3.new(vel.X, 0, vel.Z)
                    if flatVel.Magnitude > 0.5 then
                        local h0 = Vector3.new(dir.X, 0, dir.Z)
                        local _, _, tF = solvePitch({v0=v0, g=g}, h0.Magnitude, dir.Y)
                        local ping = math.clamp(LocalPlayer:GetNetworkPing(), 0, 0.35)
                        local delay = tF + 0.10 + ping + 0.04
                        aimPoint = tp + (flatVel * delay * Config.Veil_Lead)
                    end
                end
                local adir = aimPoint - origin
                local ah = Vector3.new(adir.X, 0, adir.Z)
                local pitch = solvePitch({v0=v0, g=g}, ah.Magnitude, adir.Y)
                State.Veil.look = ah.Unit * math.cos(pitch) + Vector3.new(0, math.sin(pitch), 0)
            end
        end
    else
        State.Veil.look = nil
    end
end)

local oldNamecallVeil = nil
task.spawn(function()
    oldNamecallVeil = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod(); local args = {...}
        if not checkcaller() and method == "FireServer" and typeof(self) == "Instance" and self.Name == "Spearthrow" then
            if Config.Veil_Enabled and State.Veil.look then
                if typeof(args[1]) == "table" and args[1].Direction then args[1].Direction = State.Veil.look elseif typeof(args[1]) == "Vector3" then args[1] = State.Veil.look end
                return oldNamecallVeil(self, unpack(args))
            end
        end
        return oldNamecallVeil(self, ...)
    end)
end)

-- ==========================================
-- UI POPULATE
-- ==========================================
local TabInfo = AddTab("Info")
local SecInfo = AddSection(TabInfo, "About")
Create("TextLabel", { Size = UDim2.new(1, 0, 0, 20), BackgroundTransparency = 1, Text = "BintangHub ☠️", TextColor3 = Theme.Text, Font = Enum.Font.GothamBold, TextSize = 14, TextXAlignment = Enum.TextXAlignment.Left, Parent = SecInfo })
Create("TextLabel", { Size = UDim2.new(1, 0, 0, 15), BackgroundTransparency = 1, Text = "Owner: " .. LocalPlayer.DisplayName, TextColor3 = Theme.TextDim, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = SecInfo })
AddButton(SecInfo, "Copy Discord Link", function() setclipboard("https://discord.gg/BintangHub") end)

local TabSurvivor = AddTab("Survivor")
local SecSurvSkill = AddSection(TabSurvivor, "Skillcheck")
AddDropdown(SecSurvSkill, "Auto Skillcheck", {"Disabled", "Perfect", "Instant", "Normal"}, "Disabled", function(v) Config.AutoSkill = v end)
local SecSurvCombat = AddSection(TabSurvivor, "Combat")
AddToggle(SecSurvCombat, "Auto Parry", false, function(v) Config.AutoParry = v end)
AddToggle(SecSurvCombat, "Auto Parry Aggressive", false, function(v) Config.Parry_Aggressive = v end)
AddSlider(SecSurvCombat, "Parry Radius", 5, 30, 15, function(v) Config.Parry_Dist = v end)
local SecSurvUtility = AddSection(TabSurvivor, "Utility")
AddToggle(SecSurvUtility, "God Mode", false, function(v) Config.GodMode = v end)
AddToggle(SecSurvUtility, "Invisibility", false, function(v) Config.Invis = v end)
AddToggle(SecSurvUtility, "Auto Crouch", false, function(v) Config.AutoCrouch = v end)

local TabKiller = AddTab("Killer")
local SecKillAim = AddSection(TabKiller, "Killer Aimbot")
AddToggle(SecKillAim, "Enable Aimbot", false, function(v) Config.Killer_Aimbot = v end)
AddSlider(SecKillAim, "Melee Lock Distance", 5, 30, 12, function(v) Config.Killer_MeleeDist = v end)
AddSlider(SecKillAim, "Aimbot Smoothness", 1, 10, 5, function(v) Config.Killer_Smooth = v end)
AddToggle(SecKillAim, "Aim Lock Hidden (Dash Lock)", false, function(v) Config.DashLock = v end)
local SecKillVeil = AddSection(TabKiller, "Silent Veil")
AddToggle(SecKillVeil, "Enable Silent Veil", false, function(v) Config.Veil_Enabled = v end)
AddToggle(SecKillVeil, "Auto Predict", false, function(v) Config.Veil_Predict = v end)
AddSlider(SecKillVeil, "Lead Multiplier", 0.1, 5, 1.4, function(v) Config.Veil_Lead = v end)
AddSlider(SecKillVeil, "Spear Speed", 50, 200, 165, function(v) Config.Veil_Speed = v end)
AddSlider(SecKillVeil, "Spear Gravity", 10, 200, 103, function(v) Config.Veil_Gravity = v end)
local SecKillAura = AddSection(TabKiller, "Aura Mode Modifier")
AddSlider(SecKillAura, "Aura Spear Speed", 50, 400, 165, function(v) Config.Veil_AuraSpeed = v end)
AddSlider(SecKillAura, "Aura Spear Gravity", 10, 200, 96, function(v) Config.Veil_AuraGrav = v end)

local TabESP = AddTab("ESP")
local SecESPPlayer = AddSection(TabESP, "Player ESP")
AddToggle(SecESPPlayer, "Enable Player ESP", false, function(v) Config.ESP = v; if not v then ClearESP() end end)
AddDropdown(SecESPPlayer, "ESP Target", {"Both", "Survivor", "Killer"}, "Both", function(v) Config.ESP_Target = v end)
AddDropdown(SecESPPlayer, "ESP Style", {"Chams", "Box", "Skeleton"}, "Chams", function(v) Config.ESP_Style = v end)
AddToggle(SecESPPlayer, "Show Names", false, function(v) Config.ESP_Name = v end)
AddToggle(SecESPPlayer, "Show Distance", false, function(v) Config.ESP_Dist = v end)

local TabMisc = AddTab("Misc")
local SecMiscMove = AddSection(TabMisc, "Movement")
AddToggle(SecMiscMove, "Noclip", false, function(v) Config.Noclip = v end)
AddToggle(SecMiscMove, "Speed Hack", false, function(v) Config.SpeedHack = v end)
AddSlider(SecMiscMove, "Speed Value", 1, 50, 20, function(v) Config.SpeedVal = v end)
AddToggle(SecMiscMove, "Fullbright", false, function(v) Config.Light_Fullbright = v end)
AddToggle(SecMiscMove, "No Fog", false, function(v) Config.Light_NoFog = v end)
local SecMiscInfo = AddSection(TabMisc, "Info")
AddToggle(SecMiscInfo, "Next Killer Prediction", false, function(v) Config.NextKiller = v end)
AddToggle(SecMiscInfo, "Next Map Prediction", false, function(v) Config.NextMap = v end)

local TabConfig = AddTab("Config")
local SecConfig = AddSection(TabConfig, "Config Manager")
AddButton(SecConfig, "Save Config", function() print("Config saved") end)
AddButton(SecConfig, "Load Config", function() print("Config loaded") end)

for _, t in pairs(Tabs) do
    t.Page.Visible = false
    t.Button.BackgroundColor3 = Theme.Sidebar
    t.Bar.Visible = false
end
Tabs["Info"].Page.Visible = true
Tabs["Info"].Button.BackgroundColor3 = Theme.Card
Tabs["Info"].Bar.Visible = true