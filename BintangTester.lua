-- ============================================================
-- BINTANGHUB | FULL 70 FITUR (GABUNGAN GANKUNZ)
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

local Config = {
    -- Visuals
    ESP = false, ESP_Target = "Both", ESP_Style = "Chams", ESP_Info = "Names, Distance", FillTrans = 0.5, OutlineTrans = 0.3, TextSize = 12, Color_Survivor = Color3.fromRGB(0, 255, 0), Color_Killer = Color3.fromRGB(255, 0, 0),
    WorldESP = false, WorldESP_Targets = "Generators, Hooks, Gates", WorldESP_Name = false, WorldESP_Dist = false, WorldESP_MaxDist = 150, Color_Gen = Color3.fromRGB(0, 170, 255), Color_Hook = Color3.fromRGB(255, 0, 0), Color_Gate = Color3.fromRGB(255, 255, 0), Color_Window = Color3.fromRGB(255, 255, 255), Color_Pallet = Color3.fromRGB(255, 170, 0), Color_Pumpkin = Color3.fromRGB(255, 130, 0),
    Camera_FOV = false, Camera_FOVVal = 70, Camera_UnlockZoom = false, Camera_MaxZoom = 400, Camera_DBD = false, Camera_DBDSmooth = 0.2,
    Light_Fullbright = false, Light_FullbrightVal = 180, Light_NoFog = false, Light_SkipCutscene = false, Light_ReduceTex = false, Light_RemoveTree = false,
    -- Survivor
    AutoSkill = "Disabled", BypassGen = "Manual Repair", BoostGen = false, Flowstate = false, PerfectVault = false,
    AutoParry = false, AutoParry_Aggressive = false, Parry_Dist = 8, Parry_ShowCircle = false, Parry_Color = Color3.fromRGB(170, 0, 255),
    GodMode = false, AntiFall = false, AutoCrouch = false, Invis = false, FakeQR = false, FakePL = false, FakeFS = false, FakeCD = 10,
    -- Aim
    SilentAim = false, Aim_TargetPart = "Torso", Aim_Prediction = true, Aim_BulletSpeed = 200, Aim_Laser = false, Aim_LaserColor = Color3.fromRGB(255, 0, 0), Aim_Flash = false, Aim_FlashY = 1.5,
    -- Killer
    Killer_Aimbot = false, Killer_MeleeDist = 12, Killer_Smooth = 5, DashLock = false,
    Veil_Enabled = false, Veil_Predict = false, Veil_Lead = 1.4, Veil_Speed = 165, Veil_Gravity = 103, Veil_Tracker = false, Veil_ShowFOV = false, Veil_FOVRadius = 150, Veil_FOVColor = Color3.fromRGB(108, 92, 231), Veil_FOVTrans = 0.5, Veil_AuraSpeed = 165, Veil_AuraGrav = 96,
    -- Misc
    Noclip = false, SpeedHack = false, SpeedVal = 0.2, StreamMode = false, NextKiller = false, NextMap = false
}

local State = { ParryLast = 0, ActiveAttackers = {}, ESPInstances = {}, WorldESPInstances = {}, FakePerks = {conns = {}, boost = false, pl = false, fsCD = false, lastQR = 0, lastPL = 0, lastFS = 0}, DashLock = {target = nil, lock = false, timer = nil}, Veil = {target = nil, look = nil, vel = {}}, SpooferConns = {}, CachedZombies = {}, ValidWorldObjects = {} }
local Theme = { Bg = Color3.fromRGB(13, 9, 9), Sidebar = Color3.fromRGB(26, 17, 17), Card = Color3.fromRGB(30, 20, 20), Accent = Color3.fromRGB(193, 39, 45), Text = Color3.fromRGB(238, 238, 238), TextDim = Color3.fromRGB(167, 154, 154), Line = Color3.fromRGB(46, 30, 30) }

local function Create(class, props) local i = Instance.new(class); for k,v in pairs(props) do i[k]=v end; return i end
local function Round(i,r) Create("UICorner",{CornerRadius=UDim.new(0,r),Parent=i}) end
local function Stroke(i,c,t,tr) Create("UIStroke",{Color=c,Thickness=t or 1,Transparency=tr or 0,Parent=i}) end

local Gui = Create("ScreenGui",{Name="BH",ResetOnSpawn=false,DisplayOrder=100,IgnoreGuiInset=true,Parent=CoreGui})
local Window = Create("Frame",{Size=UDim2.new(0,520,0,340),Position=UDim2.new(0.5,-260,0.5,-170),BackgroundColor3=Theme.Bg,BorderSizePixel=0,Active=true,Draggable=true,Parent=Gui})
Round(Window,12); Stroke(Window,Theme.Accent,1.5,0.3)
local Sidebar = Create("Frame",{Size=UDim2.new(0,150,1,0),BackgroundColor3=Theme.Sidebar,BorderSizePixel=0,Parent=Window})
Round(Sidebar,12)

local Logo = Create("Frame",{Size=UDim2.new(0,30,0,30),Position=UDim2.new(0,10,0,10),BackgroundColor3=Theme.Accent,BorderSizePixel=0,Parent=Sidebar})
Round(Logo,6); Create("TextLabel",{Size=UDim2.new(1,0,1,0),BackgroundTransparency=1,Text="BH",TextColor3=Color3.new(1,1,1),Font=Enum.Font.GothamBlack,TextSize=14,Parent=Logo})
Create("TextLabel",{Size=UDim2.new(1,-50,0,30),Position=UDim2.new(0,45,0,10),BackgroundTransparency=1,Text="BintangHub☠️",TextColor3=Theme.Accent,Font=Enum.Font.GothamBlack,TextSize=16,TextXAlignment=Enum.TextXAlignment.Left,Parent=Sidebar})
local TabC = Create("ScrollingFrame",{Size=UDim2.new(1,-20,1,-100),Position=UDim2.new(0,10,0,60),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=0,Parent=Sidebar})
Create("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=TabC})
Create("TextLabel",{Size=UDim2.new(1,-20,0,40),Position=UDim2.new(0,10,1,-50),BackgroundTransparency=1,Text="Owner: "..LocalPlayer.DisplayName,TextColor3=Theme.TextDim,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=Sidebar})
local Content = Create("Frame",{Size=UDim2.new(1,-150,1,0),Position=UDim2.new(0,150,0,0),BackgroundTransparency=1,Parent=Window})

local Tabs = {}
local function AddTab(n)
    local b = Create("TextButton",{Size=UDim2.new(1,0,0,30),BackgroundColor3=Theme.Sidebar,Text="  "..n,TextColor3=Theme.TextDim,Font=Enum.Font.GothamBold,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,AutoButtonColor=false,Parent=TabC})
    Round(b,6)
    local p = Create("ScrollingFrame",{Size=UDim2.new(1,-20,1,-20),Position=UDim2.new(0,10,0,10),BackgroundTransparency=1,BorderSizePixel=0,ScrollBarThickness=2,ScrollBarImageColor3=Theme.Accent,Visible=false,Parent=Content})
    Create("UIListLayout",{Padding=UDim.new(0,6),SortOrder=Enum.SortOrder.LayoutOrder,Parent=p})
    Tabs[n] = {Button=b,Page=p}
    b.MouseButton1Click:Connect(function()
        for tn,t in pairs(Tabs) do t.Page.Visible=(tn==n); t.Button.BackgroundColor3=(tn==n) and Theme.Card or Theme.Sidebar; t.Button.TextColor3=(tn==n) and Theme.Accent or Theme.TextDim end
    end)
    return p
end

local function AddSec(p,t)
    local s = Create("Frame",{Size=UDim2.new(1,0,0,0),AutomaticSize=Enum.AutomaticSize.Y,BackgroundColor3=Theme.Card,BackgroundTransparency=0.3,BorderSizePixel=0,Parent=p})
    Round(s,8); Stroke(s,Theme.Line,1,0.5)
    Create("TextLabel",{Size=UDim2.new(1,-20,0,25),Position=UDim2.new(0,10,0,5),BackgroundTransparency=1,Text=t:upper(),TextColor3=Theme.Accent,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Left,Parent=s})
    local c = Create("Frame",{Size=UDim2.new(1,-20,0,0),Position=UDim2.new(0,10,0,30),BackgroundTransparency=1,AutomaticSize=Enum.AutomaticSize.Y,Parent=s})
    Create("UIListLayout",{Padding=UDim.new(0,4),SortOrder=Enum.SortOrder.LayoutOrder,Parent=c})
    return c
end

local function AddTog(p,n,d,cb)
    local st=d
    local b = Create("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=Theme.Card,BackgroundTransparency=0.5,Text="",AutoButtonColor=false,Parent=p})
    Round(b,6)
    Create("TextLabel",{Size=UDim2.new(1,-40,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=n,TextColor3=Theme.Text,Font=Enum.Font.Gotham,TextSize=12,TextXAlignment=Enum.TextXAlignment.Left,Parent=b})
    local tr = Create("Frame",{Size=UDim2.new(0,30,0,16),Position=UDim2.new(1,-38,0.5,-8),BackgroundColor3=st and Theme.Accent or Theme.Line,BorderSizePixel=0,Parent=b})
    Round(tr,8)
    local k = Create("Frame",{Size=UDim2.new(0,12,0,12),Position=st and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6),BackgroundColor3=Color3.new(1,1,1),BorderSizePixel=0,Parent=tr})
    Round(k,6)
    b.MouseButton1Click:Connect(function()
        st=not st
        TweenService:Create(tr,TweenInfo.new(0.15),{BackgroundColor3=st and Theme.Accent or Theme.Line}):Play()
        TweenService:Create(k,TweenInfo.new(0.15),{Position=st and UDim2.new(1,-14,0.5,-6) or UDim2.new(0,2,0.5,-6)}):Play()
        cb(st)
    end)
end

local function AddSli(p,n,mn,mx,d,cb)
    local v=d
    local f = Create("Frame",{Size=UDim2.new(1,0,0,40),BackgroundColor3=Theme.Card,BackgroundTransparency=0.5,BorderSizePixel=0,Parent=p})
    Round(f,6)
    Create("TextLabel",{Size=UDim2.new(1,-60,0,18),Position=UDim2.new(0,10,0,4),BackgroundTransparency=1,Text=n,TextColor3=Theme.Text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=f})
    local vl = Create("TextLabel",{Size=UDim2.new(0,50,0,18),Position=UDim2.new(1,-60,0,4),BackgroundTransparency=1,Text=tostring(v),TextColor3=Theme.Accent,Font=Enum.Font.GothamBold,TextSize=11,TextXAlignment=Enum.TextXAlignment.Right,Parent=f})
    local tr = Create("Frame",{Size=UDim2.new(1,-20,0,6),Position=UDim2.new(0,10,0,26),BackgroundColor3=Theme.Line,BorderSizePixel=0,Parent=f})
    Round(tr,3)
    local fl = Create("Frame",{Size=UDim2.new((v-mn)/(mx-mn),0,1,0),BackgroundColor3=Theme.Accent,BorderSizePixel=0,Parent=tr})
    Round(fl,3)
    local dr=false
    local function upd(i) local r=math.clamp((i.Position.X-tr.AbsolutePosition.X)/tr.AbsoluteSize.X,0,1); v=math.floor(mn+r*(mx-mn)+0.5); fl.Size=UDim2.new(r,0,1,0); vl.Text=tostring(v); cb(v) end
    tr.InputBegan:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=true; upd(i) end end)
    UserInputService.InputChanged:Connect(function(i) if dr and (i.UserInputType==Enum.UserInputType.MouseMovement or i.UserInputType==Enum.UserInputType.Touch) then upd(i) end end)
    UserInputService.InputEnded:Connect(function(i) if i.UserInputType==Enum.UserInputType.MouseButton1 or i.UserInputType==Enum.UserInputType.Touch then dr=false end end)
end

local function AddDrop(p,n,opts,d,cb)
    local s=d
    local f = Create("Frame",{Size=UDim2.new(1,0,0,50),BackgroundTransparency=1,Parent=p})
    local b = Create("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=Theme.Card,BackgroundTransparency=0.5,Text="",AutoButtonColor=false,Parent=f})
    Round(b,6)
    Create("TextLabel",{Size=UDim2.new(1,-50,1,0),Position=UDim2.new(0,10,0,0),BackgroundTransparency=1,Text=n,TextColor3=Theme.Text,Font=Enum.Font.Gotham,TextSize=11,TextXAlignment=Enum.TextXAlignment.Left,Parent=b})
    local sl = Create("TextLabel",{Size=UDim2.new(0,80,1,0),Position=UDim2.new(1,-85,0,0),BackgroundTransparency=1,Text=s.." v",TextColor3=Theme.Accent,Font=Enum.Font.GothamBold,TextSize=10,TextXAlignment=Enum.TextXAlignment.Right,Parent=b})
    local l = Create("Frame",{Size=UDim2.new(1,0,0,0),Position=UDim2.new(0,0,0,30),BackgroundColor3=Theme.Card,BorderSizePixel=0,Visible=false,AutomaticSize=Enum.AutomaticSize.Y,Parent=f})
    Round(l,6); Create("UIListLayout",{Padding=UDim.new(0,2),Parent=l})
    for _,o in pairs(opts) do
        local ob = Create("TextButton",{Size=UDim2.new(1,-10,0,24),BackgroundColor3=Theme.Bg,Text=o,TextColor3=Theme.TextDim,Font=Enum.Font.Gotham,TextSize=11,Parent=l})
        Round(ob,4)
        ob.MouseButton1Click:Connect(function() s=o; sl.Text=s.." v"; l.Visible=false; cb(o) end)
    end
    b.MouseButton1Click:Connect(function() l.Visible = not l.Visible end)
end

local function AddBtn(p,n,cb)
    local b = Create("TextButton",{Size=UDim2.new(1,0,0,28),BackgroundColor3=Theme.Accent,BackgroundTransparency=0.8,Text=n:upper(),TextColor3=Theme.Text,Font=Enum.Font.GothamBold,TextSize=11,Parent=p})
    Round(b,6)
    b.MouseEnter:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundTransparency=0.6}):Play() end)
    b.MouseLeave:Connect(function() TweenService:Create(b,TweenInfo.new(0.15),{BackgroundTransparency=0.8}):Play() end)
    b.MouseButton1Click:Connect(cb)
end

-- ==========================================
-- ESP ENGINE
-- ==========================================
local function ClearESP()
    for p, inst in pairs(State.ESPInstances) do
        if inst.Highlight then inst.Highlight:Destroy() end
        if inst.Billboard then inst.Billboard:Destroy() end
        State.ESPInstances[p] = nil
    end
end

local function ClearWorldESP()
    for obj, inst in pairs(State.WorldESPInstances) do
        if inst.Highlight then inst.Highlight:Destroy() end
        if inst.Billboard then inst.Billboard:Destroy() end
        State.WorldESPInstances[obj] = nil
    end
end

local function ProcessWorldObj(obj)
    if not obj:IsA("Model") then return end
    local n = string.lower(obj.Name)
    local tType, tName = nil, nil
    if string.find(n, "generator") then tType, tName = "Generators", "Generator"
    elseif string.find(n, "hook") then tType, tName = "Hooks", "Hook"
    elseif (string.find(n, "gate") or obj:FindFirstChild("ExitLever")) then tType, tName = "Gates", "Gate"
    elseif string.find(n, "window") then tType, tName = "Windows", "Window"
    elseif string.find(n, "pallet") then tType, tName = "Pallets", "Pallet"
    elseif string.find(n, "pumpkin") then tType, tName = "Pumpkins", "Pumpkin"
    elseif (string.find(n, "zombie") or string.find(n, "scp")) then
        if obj:FindFirstChildOfClass("Humanoid") then table.insert(State.CachedZombies, obj) end
        tType, tName = "Zombies", "Zombie"
    end
    if tType then
        local p = obj.PrimaryPart or obj:FindFirstChildWhichIsA("BasePart", true)
        State.ValidWorldObjects[obj] = {Type = tType, Name = tName, Part = p}
    end
end

task.spawn(function()
    while true do
        task.wait(2)
        local map = workspace:FindFirstChild("Map")
        if map then
            for _, obj in pairs(map:GetDescendants()) do ProcessWorldObj(obj) end
        end
    end
end)

RunService.RenderStepped:Connect(function()
    -- Player ESP
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
                        inst.Highlight.FillColor = col; inst.Highlight.OutlineColor = col; inst.Highlight.Enabled = true; inst.Highlight.Adornee = char; inst.Highlight.FillTransparency = Config.FillTrans; inst.Highlight.OutlineTransparency = Config.OutlineTrans
                        inst.Billboard.Enabled = true
                        inst.Text.TextSize = Config.TextSize; inst.Text.TextColor3 = col
                        local txt = ""
                        if string.find(Config.ESP_Info, "Names") then txt = plr.Name .. "\n" end
                        if string.find(Config.ESP_Info, "Distance") then txt = txt .. "[" .. math.floor((hrp.Position - Camera.CFrame.Position).Magnitude) .. "m]\n" end
                        if string.find(Config.ESP_Info, "Health") then txt = txt .. "HP: " .. math.floor(hum.Health) .. "\n" end
                        inst.Text.Text = txt
                    else
                        if State.ESPInstances[plr] then State.ESPInstances[plr].Highlight.Enabled = false; State.ESPInstances[plr].Billboard.Enabled = false end
                    end
                end
            end
        end
    end

    -- World ESP
    if not Config.WorldESP then ClearWorldESP() else
        for obj, data in pairs(State.ValidWorldObjects) do
            if obj and obj.Parent and string.find(Config.WorldESP_Targets, data.Type) then
                if not State.WorldESPInstances[obj] then
                    local hl = Instance.new("Highlight", obj)
                    local p = data.Part or obj
                    local bb = Instance.new("BillboardGui", p)
                    bb.Size = UDim2.new(0, 150, 0, 50); bb.AlwaysOnTop = true; bb.StudsOffset = Vector3.new(0, 3, 0)
                    local txt = Instance.new("TextLabel", bb)
                    txt.Size = UDim2.new(1,0,1,0); txt.BackgroundTransparency = 1; txt.Font = Enum.Font.GothamBold; txt.TextStrokeTransparency = 0
                    State.WorldESPInstances[obj] = { Highlight = hl, Billboard = bb, Text = txt }
                end
                local inst = State.WorldESPInstances[obj]
                local col = Config["Color_" .. data.Type:sub(1,4)] or Color3.fromRGB(255,255,255)
                if data.Type == "Generators" then col = Config.Color_Gen elseif data.Type == "Hooks" then col = Config.Color_Hook elseif data.Type == "Gates" then col = Config.Color_Gate elseif data.Type == "Windows" then col = Config.Color_Window elseif data.Type == "Pallets" then col = Config.Color_Pallet elseif data.Type == "Pumpkins" then col = Config.Color_Pumpkin end
                inst.Highlight.FillColor = col; inst.Highlight.OutlineColor = col; inst.Highlight.Enabled = true; inst.Highlight.Adornee = obj
                inst.Billboard.Enabled = true
                local txt = ""
                if Config.WorldESP_Name then txt = data.Name .. "\n" end
                if Config.WorldESP_Dist and data.Part then txt = txt .. "[" .. math.floor((data.Part.Position - Camera.CFrame.Position).Magnitude) .. "m]" end
                inst.Text.Text = txt; inst.Text.TextColor3 = col
            else
                if State.WorldESPInstances[obj] then State.WorldESPInstances[obj].Highlight.Enabled = false; State.WorldESPInstances[obj].Billboard.Enabled = false end
            end
        end
    end
end)

-- ==========================================
-- AUTO PARRY
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
                if Config.AutoParry_Aggressive then
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
-- AUTO SKILLCHECK
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
-- SILENT AIM (PISTOL & FLASHLIGHT)
-- ==========================================
local AimCache = { LookVector = nil, TargetPos = nil, IsAiming = false, IsFlash = false }
UserInputService.InputBegan:Connect(function(i, gp) if not gp then if i.UserInputType == Enum.UserInputType.MouseButton2 then AimCache.IsAiming = true; AimCache.IsFlash = true end end end)
UserInputService.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton2 then AimCache.IsAiming = false; AimCache.IsFlash = false end end)
RunService.Heartbeat:Connect(function()
    if not Config.SilentAim then return end
    local char = LocalPlayer.Character
    if not char then return end
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
        if Config.Aim_Flash and AimCache.IsFlash then
            cam.CFrame = cam.CFrame:Lerp(CFrame.lookAt(cam.CFrame.Position, best.Position + Vector3.new(0, Config.Aim_FlashY, 0)), 0.5)
        end
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
-- KILLER AIMBOT & DASH LOCK
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
-- SILENT VEIL SPEAR
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

local oldNamecall2 = nil
task.spawn(function()
    oldNamecall2 = hookmetamethod(game, "__namecall", function(self, ...)
        local method = getnamecallmethod(); local args = {...}
        if not checkcaller() and method == "FireServer" and typeof(self) == "Instance" and self.Name == "Spearthrow" then
            if Config.Veil_Enabled and State.Veil.look then
                if typeof(args[1]) == "table" and args[1].Direction then args[1].Direction = State.Veil.look elseif typeof(args[1]) == "Vector3" then args[1] = State.Veil.look end
                return oldNamecall2(self, unpack(args))
            end
        end
        return oldNamecall2(self, ...)
    end)
end)

-- ==========================================
-- FAKE PERKS
-- ==========================================
local function isSlowVaulting(char)
    local hum = char:FindFirstChildOfClass("Humanoid")
    local animator = hum and hum:FindFirstChildOfClass("Animator")
    if animator then
        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
            if track.Animation and string.find(tostring(track.Animation.AnimationId), "126081405469607") then return true end
        end
    end
    return false
end

local function SetupFakePerks(char)
    if not char then return end
    for _, conn in pairs(State.FakePerks.conns) do conn:Disconnect() end
    State.FakePerks.conns = {}
    table.insert(State.FakePerks.conns, char:GetAttributeChangedSignal("isvaulting"):Connect(function()
        if not Config.FakeQR then return end
        if char:GetAttribute("isvaulting") == true then
            task.spawn(function()
                task.wait(0.05)
                local slow = isSlowVaulting(char)
                if not slow then task.wait(0.05); slow = isSlowVaulting(char) end
                if not slow and char:GetAttribute("isvaulting") == true then
                    if State.FakePerks.boost then return end
                    if (tick() - State.FakePerks.lastQR) < Config.FakeCD then return end
                    State.FakePerks.boost = true; State.FakePerks.lastQR = tick()
                    local st = tick()
                    task.spawn(function()
                        while Config.FakeQR and (tick() - st) < 3 do if char.Parent then char:SetAttribute("speedboost", 1.4) end; task.wait() end
                        if char.Parent then char:SetAttribute("speedboost", 1) end
                        State.FakePerks.boost = false
                    end)
                end
            end)
        end
    end))
    table.insert(State.FakePerks.conns, char:GetAttributeChangedSignal("speedboost"):Connect(function()
        if not Config.FakePL then return end
        if char:GetAttribute("speedboost") == 0.625 then
            if State.FakePerks.pl then return end
            if (tick() - State.FakePerks.lastPL) < Config.FakeCD then return end
            State.FakePerks.pl = true; State.FakePerks.lastPL = tick()
            local st = tick()
            task.spawn(function()
                while Config.FakePL and (tick() - st) < 3 do if char.Parent then char:SetAttribute("speedboost", 1.4) end; task.wait() end
                if char.Parent then char:SetAttribute("speedboost", 1) end
                State.FakePerks.pl = false
            end)
        end
    end))
    local hum = char:WaitForChild("Humanoid", 3)
    local animator = hum and hum:WaitForChild("Animator", 3)
    if animator then
        table.insert(State.FakePerks.conns, animator.AnimationPlayed:Connect(function(track)
            if not Config.FakeFS then return end
            if track.Animation and string.find(tostring(track.Animation.AnimationId), "136962284480779") then
                local sc; sc = track.Stopped:Connect(function()
                    if sc then sc:Disconnect() end
                    State.FakePerks.lastFS = tick(); State.FakePerks.fsCD = true
                    if char.Parent then char:SetAttribute("Flowstate", false) end
                    task.delay(Config.FakeCD, function()
                        State.FakePerks.fsCD = false
                        if Config.FakeFS and char.Parent then char:SetAttribute("Flowstate", true) end
                    end)
                end)
            end
        end))
    end
    table.insert(State.FakePerks.conns, char:GetAttributeChangedSignal("Flowstate"):Connect(function()
        if not Config.FakeFS then return end
        if char:GetAttribute("Flowstate") == true then
            if State.FakePerks.fsCD or (tick() - State.FakePerks.lastFS) < Config.FakeCD then char:SetAttribute("Flowstate", false) end
        elseif char:GetAttribute("Flowstate") == false then
            if not State.FakePerks.fsCD and (tick() - State.FakePerks.lastFS) >= Config.FakeCD then char:SetAttribute("Flowstate", true) end
        end
    end))
    task.wait(0.5)
    if Config.FakeFS and char.Parent then char:SetAttribute("Flowstate", true) end
end

LocalPlayer.CharacterAdded:Connect(function(char) task.wait(0.5); SetupFakePerks(char) end)
if LocalPlayer.Character then task.spawn(function() SetupFakePerks(LocalPlayer.Character) end) end

-- ==========================================
-- UTILITY (GOD MODE, ANTI FALL, CROUCH, INVIS)
-- ==========================================
local function TriggerCrouch()
    pcall(function()
        local b = LocalPlayer:FindFirstChild("PlayerGui")
        for segment in string.gmatch("Survivor-mob.Controls.crouch.icon", "[^%.]+") do if b then b = b:FindFirstChild(segment) end end
        if b and b:IsA("GuiObject") and b.Visible and b.Parent and b.Parent:IsA("GuiButton") then
            local btn = b.Parent
            if UserInputService.TouchEnabled and type(firesignal) == "function" then
                firesignal(btn.MouseButton1Click); task.wait(1.4); firesignal(btn.MouseButton1Click); return
            end
        end
        VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.LeftControl, false, game); task.wait(1.4); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.LeftControl, false, game)
    end)
end

RunService.Heartbeat:Connect(function()
    local char = LocalPlayer.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    if not hum then return end
    if Config.GodMode then
        pcall(function()
            if hum.Health < hum.MaxHealth and hum.Health > 0 then hum.Health = hum.MaxHealth end
            local bad = {"Injured","Bleeding","Hurt","Broken","Wounded","Knocked","Downed","Carried","Grabbed","Ragdolled","IsKnocked","IsCarried","Disabled","Stunned"}
            for _, attr in ipairs(bad) do if char:GetAttribute(attr) == true then char:SetAttribute(attr, false) end end
            if hum.PlatformStand then hum.PlatformStand = false end
            if hum.Sit then hum.Sit = false end
            hum.AutoRotate = true
        end)
    end
    if Config.Invis and char then
        for _, v in ipairs(char:GetDescendants()) do
            if (v:IsA("BasePart") or v:IsA("Decal")) and v.Name ~= "HumanoidRootPart" then
                if not v:GetAttribute("OriTrans") then v:SetAttribute("OriTrans", v.Transparency) end
                if v:GetAttribute("OriTrans") < 1 then v.Transparency = 0.5 end
            end
        end
    end
    if Config.Noclip and char then
        for _, part in ipairs(char:GetDescendants()) do if part:IsA("BasePart") and part.CanCollide then part.CanCollide = false end end
    end
    if Config.SpeedHack and char then
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local kn = char:GetAttribute("Knocked") or char:GetAttribute("Downed") or char:GetAttribute("Carried")
        local cr = char:GetAttribute("Crouching") or char:GetAttribute("Crouchingserver")
        if hrp and not kn and not cr then
            local md = hum.MoveDirection
            if md.Magnitude > 0 then hrp.CFrame = hrp.CFrame + (md * (Config.SpeedVal * 15) * (1/60)) end
        end
    end
end)

for _, plr in pairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        plr.CharacterAdded:Connect(function(char)
            task.wait(1)
            local hum = char:WaitForChild("Humanoid", 3)
            if hum then
                local anim = hum:WaitForChild("Animator", 3)
                if anim then
                    anim.AnimationPlayed:Connect(function(track)
                        local id = tostring(track.Animation.AnimationId)
                        if Config.AutoCrouch and string.find(id, "80411309607666") then
                            local myRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                            local kRoot = char:FindFirstChild("HumanoidRootPart")
                            if myRoot and kRoot and (myRoot.Position - kRoot.Position).Magnitude <= 40 then task.spawn(TriggerCrouch) end
                        end
                    end)
                end
            end
        end)
    end
end

-- ==========================================
-- LIGHTING & MISC
-- ==========================================
local Lighting = game:GetService("Lighting")
local OrigLight = {Saved = false, Ambient = Lighting.Ambient, OutdoorAmbient = Lighting.OutdoorAmbient, Brightness = Lighting.Brightness, ClockTime = Lighting.ClockTime, GlobalShadows = Lighting.GlobalShadows, FogStart = Lighting.FogStart, FogEnd = Lighting.FogEnd}

RunService.Heartbeat:Connect(function()
    if Config.Light_Fullbright then
        pcall(function()
            if not OrigLight.Saved then OrigLight.Ambient = Lighting.Ambient; OrigLight.OutdoorAmbient = Lighting.OutdoorAmbient; OrigLight.Brightness = Lighting.Brightness; OrigLight.ClockTime = Lighting.ClockTime; OrigLight.GlobalShadows = Lighting.GlobalShadows; OrigLight.Saved = true end
            local val = Config.Light_FullbrightVal
            Lighting.Ambient = Color3.fromRGB(val, val, val); Lighting.OutdoorAmbient = Color3.fromRGB(val, val, val)
            Lighting.Brightness = 2; Lighting.ClockTime = 12; Lighting.GlobalShadows = false
        end)
    elseif OrigLight.Saved then
        pcall(function()
            Lighting.Ambient = OrigLight.Ambient; Lighting.OutdoorAmbient = OrigLight.OutdoorAmbient; Lighting.Brightness = OrigLight.Brightness; Lighting.ClockTime = OrigLight.ClockTime; Lighting.GlobalShadows = OrigLight.GlobalShadows; OrigLight.Saved = false
        end)
    end
    if Config.Light_NoFog then
        pcall(function()
            if not OrigLight.FogSaved then OrigLight.FogStart = Lighting.FogStart; OrigLight.FogEnd = Lighting.FogEnd; OrigLight.FogSaved = true end
            Lighting.FogStart = 100000; Lighting.FogEnd = 100000
            local atm = Lighting:FindFirstChildOfClass("Atmosphere"); if atm then atm.Density = 0 end
        end)
    end
    if Config.Light_SkipCutscene then
        pcall(function()
            local map = workspace:FindFirstChild("Map")
            if map then local es = map:FindFirstChild("endscreen", true); if es then es:Destroy() end end
        end)
    end
end)

-- ==========================================
-- UI POPULATE (SEMUA FITUR)
-- ==========================================
-- TAB MAIN (VISUALS)
local TabMain = AddTab("Main (Visuals)")
local SecESP = AddSec(TabMain, "Player ESP")
AddTog(SecESP, "Enable Player ESP", false, function(v) Config.ESP = v end)
AddDrop(SecESP, "ESP Target", {"Both", "Killer", "Survivor"}, "Both", function(v) Config.ESP_Target = v end)
AddDrop(SecESP, "ESP Style", {"Chams", "Box", "Skeleton"}, "Chams", function(v) Config.ESP_Style = v end)
AddDrop(SecESP, "ESP Info", {"Names, Distance", "Names, Health", "All"}, "Names, Distance", function(v) Config.ESP_Info = v end)
AddSli(SecESP, "Fill Transparency", 0, 1, 0.5, function(v) Config.FillTrans = v end)
AddSli(SecESP, "Text Size", 8, 24, 12, function(v) Config.TextSize = v end)

local SecWESP = AddSec(TabMain, "World ESP")
AddTog(SecWESP, "Enable World ESP", false, function(v) Config.WorldESP = v end)
AddDrop(SecWESP, "World Targets", {"Generators, Hooks, Gates", "All", "Generators Only"}, "Generators, Hooks, Gates", function(v) Config.WorldESP_Targets = v end)
AddTog(SecWESP, "World Nametags", false, function(v) Config.WorldESP_Name = v end)
AddTog(SecWESP, "World Distance", false, function(v) Config.WorldESP_Dist = v end)

local SecCam = AddSec(TabMain, "Camera")
AddTog(SecCam, "Enable FOV Modifier", false, function(v) Config.Camera_FOV = v end)
AddSli(SecCam, "Camera FOV", 70, 120, 70, function(v) Config.Camera_FOVVal = v end)
AddTog(SecCam, "Unlock Camera Zoom", false, function(v) Config.Camera_UnlockZoom = v end)
AddSli(SecCam, "Max Zoom", 128, 2000, 400, function(v) Config.Camera_MaxZoom = v end)
AddTog(SecCam, "DBD Camera", false, function(v) Config.Camera_DBD = v end)
AddSli(SecCam, "DBD Smoothness", 1, 10, 2, function(v) Config.Camera_DBDSmooth = v / 10 end)

local SecLight = AddSec(TabMain, "Lighting")
AddTog(SecLight, "Fullbright", false, function(v) Config.Light_Fullbright = v end)
AddTog(SecLight, "No Fog", false, function(v) Config.Light_NoFog = v end)
AddTog(SecLight, "Skip Cutscene", false, function(v) Config.Light_SkipCutscene = v end)

-- TAB SURVIVOR
local TabSurv = AddTab("Survivor")
local SecSkill = AddSec(TabSurv, "Skill Check")
AddDrop(SecSkill, "Auto Skill Check", {"Disabled", "Normal", "Perfect", "Instant"}, "Disabled", function(v) Config.AutoSkill = v end)
AddDrop(SecSkill, "Bypass Gen Mode", {"Manual Repair", "Auto Repair"}, "Manual Repair", function(v) Config.BypassGen = v end)
AddTog(SecSkill, "Enable Boost Generator", false, function(v) Config.BoostGen = v end)

local SecVault = AddSec(TabSurv, "Vault Exploits")
AddTog(SecVault, "Fast Vault (Flowstate)", false, function(v) Config.Flowstate = v end)
AddTog(SecVault, "Perfect Vault", false, function(v) Config.PerfectVault = v end)

local SecParry = AddSec(TabSurv, "Combat")
AddTog(SecParry, "Auto Parry", false, function(v) Config.AutoParry = v end)
AddTog(SecParry, "Auto Parry Aggressive", false, function(v) Config.AutoParry_Aggressive = v end)
AddSli(SecParry, "Parry Radius", 4, 25, 8, function(v) Config.Parry_Dist = v end)
AddTog(SecParry, "Show Parry Circle", false, function(v) Config.Parry_ShowCircle = v end)

local SecUtil = AddSec(TabSurv, "Utility")
AddTog(SecUtil, "Auto Crouch (Abysswalker)", false, function(v) Config.AutoCrouch = v end)
AddTog(SecUtil, "God Mode", false, function(v) Config.GodMode = v end)
AddTog(SecUtil, "Anti Fall", false, function(v) Config.AntiFall = v end)
AddTog(SecUtil, "Invisibility", false, function(v) Config.Invis = v end)

local SecFP = AddSec(TabSurv, "Fake Perks")
AddTog(SecFP, "Fake Quick Recovery", false, function(v) Config.FakeQR = v end)
AddTog(SecFP, "Fake Perfect Landing", false, function(v) Config.FakePL = v end)
AddTog(SecFP, "Fake Flowstate", false, function(v) Config.FakeFS = v end)
AddSli(SecFP, "Perks Cooldown", 0, 180, 10, function(v) Config.FakeCD = v end)

-- TAB AIM
local TabAim = AddTab("Aim")
local SecSA = AddSec(TabAim, "Silent Aim (Pistol)")
AddTog(SecSA, "Silent Aim", false, function(v) Config.SilentAim = v end)
AddDrop(SecSA, "Target Part", {"Head", "Torso", "Root"}, "Torso", function(v) Config.Aim_TargetPart = v end)
AddTog(SecSA, "Enable Prediction", true, function(v) Config.Aim_Prediction = v end)
AddSli(SecSA, "Bullet Speed", 50, 1000, 200, function(v) Config.Aim_BulletSpeed = v end)
AddTog(SecSA, "Laser Pointer", false, function(v) Config.Aim_Laser = v end)
AddTog(SecSA, "Silent Aim Flashlight", false, function(v) Config.Aim_Flash = v end)
AddSli(SecSA, "Flash Head Offset Y", 1, 15, 8, function(v) Config.Aim_FlashY = v end)

-- TAB KILLER
local TabKiller = AddTab("Killer")
local SecKA = AddSec(TabKiller, "Killer Aimbot")
AddTog(SecKA, "Enable Aimbot", false, function(v) Config.Killer_Aimbot = v end)
AddSli(SecKA, "Melee Lock Distance", 5, 30, 12, function(v) Config.Killer_MeleeDist = v end)
AddSli(SecKA, "Aimbot Smoothness", 1, 10, 5, function(v) Config.Killer_Smooth = v end)
AddTog(SecKA, "Aim Lock Hidden (Dash Lock)", false, function(v) Config.DashLock = v end)

local SecVeil = AddSec(TabKiller, "Silent Veil")
AddTog(SecVeil, "Enable Silent Veil", false, function(v) Config.Veil_Enabled = v end)
AddTog(SecVeil, "Auto Predict", false, function(v) Config.Veil_Predict = v end)
AddSli(SecVeil, "Lead Multiplier", 0.1, 5, 1.4, function(v) Config.Veil_Lead = v end)
AddSli(SecVeil, "Spear Speed", 50, 200, 165, function(v) Config.Veil_Speed = v end)
AddSli(SecVeil, "Spear Gravity", 10, 200, 103, function(v) Config.Veil_Gravity = v end)
AddTog(SecVeil, "Show Tracker", false, function(v) Config.Veil_Tracker = v end)
AddTog(SecVeil, "Show FOV", false, function(v) Config.Veil_ShowFOV = v end)
AddSli(SecVeil, "FOV Radius", 30, 500, 150, function(v) Config.Veil_FOVRadius = v end)

-- TAB MISC
local TabMisc = AddTab("Misc")
AddTog(TabMisc, "Noclip", false, function(v) Config.Noclip = v end)
AddTog(TabMisc, "Speed Hack", false, function(v) Config.SpeedHack = v end)
AddSli(TabMisc, "Speed Value", 0.1, 1, 0.2, function(v) Config.SpeedVal = v end)
AddTog(TabMisc, "Stream Mode", false, function(v) Config.StreamMode = v end)
AddTog(TabMisc, "Next Killer Prediction", false, function(v) Config.NextKiller = v end)
AddTog(TabMisc, "Next Map Prediction", false, function(v) Config.NextMap = v end)

for _, t in pairs(Tabs) do t.Page.Visible = false end
Tabs["Main (Visuals)"].Page.Visible = true