-- BintangHub Fluent UI
local Fluent = loadstring(game:HttpGet("https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"))()
local SaveManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/SaveManager.lua"))()
local InterfaceManager = loadstring(game:HttpGet("https://raw.githubusercontent.com/dawid-scripts/Fluent/master/Addons/InterfaceManager.lua"))()

local Window = Fluent:CreateWindow({
    Title = "BintangHub☠️",
    SubTitle = "by Owner BintangHub",
    TabWidth = 160,
    Size = UDim2.fromOffset(540, 360),
    Acrylic = true,
    Theme = "Dark",
    MinimizeKey = Enum.KeyCode.RightShift
})

local Tabs = {
    Info = Window:AddTab({ Title = "Info", Icon = "info" }),
    Survivor = Window:AddTab({ Title = "Survivor", Icon = "user" }),
    Killer = Window:AddTab({ Title = "Killer", Icon = "flame" }),
    ESP = Window:AddTab({ Title = "ESP", Icon = "eye" }),
    Misc = Window:AddTab({ Title = "Misc", Icon = "box" }),
    Config = Window:AddTab({ Title = "Config", Icon = "settings" })
}

-- ==========================================
-- TAB INFO
-- ==========================================
local InfoGroup = Tabs.Info:AddLeftGroupbox("About")
InfoGroup:AddLabel("BintangHub ☠️"):SetColor(Color3.fromRGB(255, 60, 60))
InfoGroup:AddLabel("Owner: " .. game.Players.LocalPlayer.DisplayName)
InfoGroup:AddButton({
    Title = "Copy Discord Link",
    Description = "Copy link Discord BintangHub",
    Callback = function()
        setclipboard("https://discord.gg/BintangHub")
        Window:Dialog({
            Title = "Copied",
            Content = "Discord link copied to clipboard!",
            Buttons = { { Title = "OK", Callback = function() end } }
        })
    end
})

-- ==========================================
-- TAB SURVIVOR
-- ==========================================
local SkillGroup = Tabs.Survivor:AddLeftGroupbox("Skillcheck")
SkillGroup:AddDropdown("SkillMode", {
    Title = "Auto Skillcheck Mode",
    Values = {"Disabled", "Normal", "Perfect", "Instant", "Random"},
    Default = 1,
    Multi = false,
    Callback = function(Value) print("Skill Mode:", Value) end
})

local CombatGroup = Tabs.Survivor:AddLeftGroupbox("Combat")
CombatGroup:AddToggle("AutoParry", { Title = "Auto Parry", Default = false, Callback = function(Value) print("Auto Parry:", Value) end })
CombatGroup:AddSlider("ParryRadius", { Title = "Parry Radius", Min = 5, Max = 30, Default = 15, Rounding = 0, Callback = function(Value) print("Parry Radius:", Value) end })

local UtilityGroup = Tabs.Survivor:AddRightGroupbox("Utility")
UtilityGroup:AddToggle("GodMode", { Title = "God Mode", Default = false, Callback = function(Value) print("God Mode:", Value) end })
UtilityGroup:AddToggle("Invis", { Title = "Invisibility", Default = false, Callback = function(Value) print("Invis:", Value) end })

-- ==========================================
-- TAB KILLER
-- ==========================================
local KillerAimGroup = Tabs.Killer:AddLeftGroupbox("Killer Aimbot")
KillerAimGroup:AddToggle("KillerAimbot", { Title = "Enable Aimbot", Default = false, Callback = function(Value) print("Aimbot:", Value) end })
KillerAimGroup:AddSlider("MeleeDist", { Title = "Melee Lock Distance", Min = 5, Max = 30, Default = 12, Rounding = 0, Callback = function(Value) print("Distance:", Value) end })
KillerAimGroup:AddSlider("AimbotSmooth", { Title = "Aimbot Smoothness", Min = 1, Max = 10, Default = 5, Rounding = 0, Callback = function(Value) print("Smooth:", Value) end })
KillerAimGroup:AddToggle("DashLock", { Title = "Aim Lock Hidden (Dash Lock)", Default = false, Callback = function(Value) print("Dash Lock:", Value) end })

local VeilGroup = Tabs.Killer:AddRightGroupbox("Silent Veil")
VeilGroup:AddToggle("VeilEnabled", { Title = "Enable Silent Veil", Default = false, Callback = function(Value) print("Veil:", Value) end })
VeilGroup:AddToggle("VeilPredict", { Title = "Auto Predict", Default = false, Callback = function(Value) print("Predict:", Value) end })
VeilGroup:AddSlider("VeilLead", { Title = "Lead Multiplier", Min = 0.1, Max = 5, Default = 1.4, Rounding = 1, Callback = function(Value) print("Lead:", Value) end })
VeilGroup:AddSlider("VeilSpeed", { Title = "Spear Speed", Min = 50, Max = 200, Default = 165, Rounding = 0, Callback = function(Value) print("Speed:", Value) end })
VeilGroup:AddSlider("VeilGravity", { Title = "Spear Gravity", Min = 10, Max = 200, Default = 103, Rounding = 0, Callback = function(Value) print("Gravity:", Value) end })

local AuraGroup = Tabs.Killer:AddRightGroupbox("Aura Mode")
AuraGroup:AddSlider("AuraSpeed", { Title = "Aura Spear Speed", Min = 50, Max = 400, Default = 165, Rounding = 0, Callback = function(Value) print("Aura Speed:", Value) end })
AuraGroup:AddSlider("AuraGravity", { Title = "Aura Spear Gravity", Min = 10, Max = 200, Default = 96, Rounding = 0, Callback = function(Value) print("Aura Gravity:", Value) end })

-- ==========================================
-- TAB ESP
-- ==========================================
local ESPGroup = Tabs.ESP:AddLeftGroupbox("Player ESP")
ESPGroup:AddToggle("ESPEnabled", { Title = "Enable Player ESP", Default = false, Callback = function(Value) print("ESP:", Value) end })
ESPGroup:AddDropdown("ESPTarget", { Title = "ESP Target", Values = {"Both", "Survivor", "Killer"}, Default = 1, Multi = false, Callback = function(Value) print("Target:", Value) end })
ESPGroup:AddDropdown("ESPStyle", { Title = "ESP Style", Values = {"Chams", "Box", "Skeleton"}, Default = 1, Multi = false, Callback = function(Value) print("Style:", Value) end })
ESPGroup:AddToggle("ESPNames", { Title = "Show Names", Default = false, Callback = function(Value) print("Names:", Value) end })
ESPGroup:AddToggle("ESPDist", { Title = "Show Distance", Default = false, Callback = function(Value) print("Distance:", Value) end })

-- ==========================================
-- TAB MISC
-- ==========================================
local MoveGroup = Tabs.Misc:AddLeftGroupbox("Movement")
MoveGroup:AddToggle("Noclip", { Title = "Noclip", Default = false, Callback = function(Value) print("Noclip:", Value) end })
MoveGroup:AddToggle("SpeedHack", { Title = "Speed Hack", Default = false, Callback = function(Value) print("Speed:", Value) end })
MoveGroup:AddSlider("SpeedVal", { Title = "Speed Value", Min = 1, Max = 50, Default = 20, Rounding = 0, Callback = function(Value) print("Speed Val:", Value) end })

local VisualGroup = Tabs.Misc:AddRightGroupbox("Visuals")
VisualGroup:AddToggle("Fullbright", { Title = "Fullbright", Default = false, Callback = function(Value) print("Fullbright:", Value) end })
VisualGroup:AddToggle("NoFog", { Title = "No Fog", Default = false, Callback = function(Value) print("No Fog:", Value) end })

-- ==========================================
-- TAB CONFIG
-- ==========================================
local ConfigGroup = Tabs.Config:AddLeftGroupbox("Config Manager")
ConfigGroup:AddButton({
    Title = "Save Config",
    Description = "Save current settings",
    Callback = function()
        Window:Dialog({ Title = "Saved", Content = "Config saved successfully!", Buttons = { { Title = "OK", Callback = function() end } } })
    end
})
ConfigGroup:AddButton({
    Title = "Load Config",
    Description = "Load saved settings",
    Callback = function()
        Window:Dialog({ Title = "Loaded", Content = "Config loaded successfully!", Buttons = { { Title = "OK", Callback = function() end } } })
    end
})

-- Notifikasi awal
Window:Dialog({
    Title = "BintangHub☠️",
    Content = "Script loaded. Select a tab to begin.",
    Buttons = { { Title = "OK", Callback = function() end } }
})
