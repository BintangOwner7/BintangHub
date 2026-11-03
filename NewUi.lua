-- ============================================================
-- BINTANGHUB LIGHT UI (NO LIBRARY)
-- ============================================================
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local CoreGui = game:GetService("CoreGui") or Players.LocalPlayer:WaitForChild("PlayerGui")

local Theme = {
    Bg = Color3.fromRGB(14, 14, 18),
    Sidebar = Color3.fromRGB(20, 20, 25),
    Card = Color3.fromRGB(30, 30, 38),
    Accent = Color3.fromRGB(200, 40, 40),
    Text = Color3.fromRGB(240, 240, 240),
    TextDim = Color3.fromRGB(160, 160, 170),
    Line = Color3.fromRGB(45, 45, 55)
}

local function Create(class, props)
    local inst = Instance.new(class)
    for k, v in pairs(props) do inst[k] = v end
    return inst
end

local function Round(inst, radius)
    Create("UICorner", { CornerRadius = UDim.new(0, radius), Parent = inst })
end

local function Stroke(inst, color, thick, trans)
    Create("UIStroke", { Color = color, Thickness = thick or 1, Transparency = trans or 0, Parent = inst })
end

-- ============================================================
-- MAIN WINDOW
-- ============================================================
local Gui = Create("ScreenGui", { Name = "BintangHub", ResetOnSpawn = false, DisplayOrder = 100, IgnoreGuiInset = true, Parent = CoreGui })

-- Floating Icon
local Icon = Create("TextButton", {
    Size = UDim2.new(0, 40, 0, 40),
    Position = UDim2.new(0, 20, 0, 20),
    BackgroundColor3 = Theme.Accent,
    Text = "BH",
    TextColor3 = Color3.new(1, 1, 1),
    Font = Enum.Font.GothamBlack,
    TextSize = 16,
    AutoButtonColor = false,
    Parent = Gui
})
Round(Icon, 20)
Stroke(Icon, Theme.Accent, 2)

local Window = Create("Frame", {
    Size = UDim2.new(0, 480, 0, 300),
    Position = UDim2.new(0.5, -240, 0.5, -150),
    BackgroundColor3 = Theme.Bg,
    BorderSizePixel = 0,
    Active = true,
    Draggable = true,
    Visible = false,
    Parent = Gui
})
Round(Window, 10)
Stroke(Window, Theme.Line, 1.5)

Icon.MouseButton1Click:Connect(function()
    Window.Visible = not Window.Visible
end)

-- Sidebar
local Sidebar = Create("Frame", { Size = UDim2.new(0, 130, 1, 0), BackgroundColor3 = Theme.Sidebar, BorderSizePixel = 0, Parent = Window })
Round(Sidebar, 10)

-- Title
Create("TextLabel", {
    Size = UDim2.new(1, -20, 0, 40),
    Position = UDim2.new(0, 10, 0, 5),
    BackgroundTransparency = 1,
    Text = "BintangHub☠️",
    TextColor3 = Theme.Accent,
    Font = Enum.Font.GothamBlack,
    TextSize = 16,
    TextXAlignment = Enum.TextXAlignment.Left,
    Parent = Sidebar
})

-- Tab Container
local TabContainer = Create("ScrollingFrame", {
    Size = UDim2.new(1, -10, 1, -70),
    Position = UDim2.new(0, 5, 0, 50),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    ScrollBarThickness = 0,
    Parent = Sidebar
})
Create("UIListLayout", { Padding = UDim.new(0, 3), SortOrder = Enum.SortOrder.LayoutOrder, Parent = TabContainer })

-- Content
local Content = Create("Frame", { Size = UDim2.new(1, -130, 1, 0), Position = UDim2.new(0, 130, 0, 0), BackgroundTransparency = 1, Parent = Window })

-- ============================================================
-- UI BUILDER
-- ============================================================
local Tabs = {}
local function AddTab(name)
    local btn = Create("TextButton", {
        Size = UDim2.new(1, 0, 0, 30),
        BackgroundColor3 = Theme.Sidebar,
        Text = "  " .. name,
        TextColor3 = Theme.TextDim,
        Font = Enum.Font.GothamBold,
        TextSize = 12,
        TextXAlignment = Enum.TextXAlignment.Left,
        AutoButtonColor = false,
        Parent = TabContainer
    })
    Round(btn, 6)
    
    local page = Create("ScrollingFrame", {
        Size = UDim2.new(1, -15, 1, -15),
        Position = UDim2.new(0, 10, 0, 10),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Accent,
        Visible = false,
        Parent = Content
    })
    Create("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = page })
    
    Tabs[name] = { Button = btn, Page = page }
    
    btn.MouseButton1Click:Connect(function()
        for tName, t in pairs(Tabs) do
            t.Page.Visible = (tName == name)
            t.Button.BackgroundColor3 = (tName == name) and Theme.Card or Theme.Sidebar
            t.Button.TextColor3 = (tName == name) and Theme.Accent or Theme.TextDim
        end
    end)
    return page
end

local function AddSection(page, title)
    local sec = Create("Frame", { Size = UDim2.new(1, 0, 0, 0), AutomaticSize = Enum.AutomaticSize.Y, BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = page })
    Round(sec, 8); Stroke(sec, Theme.Line, 1, 0.5)
    Create("TextLabel", { Size = UDim2.new(1, -20, 0, 25), Position = UDim2.new(0, 10, 0, 5), BackgroundTransparency = 1, Text = title:upper(), TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = sec })
    local cont = Create("Frame", { Size = UDim2.new(1, -20, 0, 0), Position = UDim2.new(0, 10, 0, 30), BackgroundTransparency = 1, AutomaticSize = Enum.AutomaticSize.Y, Parent = sec })
    Create("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.LayoutOrder, Parent = cont })
    return cont
end

local function AddToggle(parent, name, default, callback)
    local state = default
    local btn = Create("TextButton", { Size = UDim2.new(1, 0, 0, 28), BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.5, Text = "", AutoButtonColor = false, Parent = parent })
    Round(btn, 6)
    Create("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.new(0, 10, 0, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn })
    local track = Create("Frame", { Size = UDim2.new(0, 30, 0, 16), Position = UDim2.new(1, -38, 0.5, -8), BackgroundColor3 = state and Theme.Accent or Theme.Line, BorderSizePixel = 0, Parent = btn })
    Round(track, 8)
    local knob = Create("Frame", { Size = UDim2.new(0, 12, 0, 12), Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6), BackgroundColor3 = Color3.new(1,1,1), BorderSizePixel = 0, Parent = track })
    Round(knob, 6)
    
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, TweenInfo.new(0.15), { BackgroundColor3 = state and Theme.Accent or Theme.Line }):Play()
        TweenService:Create(knob, TweenInfo.new(0.15), { Position = state and UDim2.new(1, -14, 0.5, -6) or UDim2.new(0, 2, 0.5, -6) }):Play()
        if callback then callback(state) end
    end)
end

local function AddSlider(parent, name, min, max, default, callback)
    local value = default
    local frame = Create("Frame", { Size = UDim2.new(1, 0, 0, 40), BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.5, BorderSizePixel = 0, Parent = parent })
    Round(frame, 6)
    Create("TextLabel", { Size = UDim2.new(1, -60, 0, 18), Position = UDim2.new(0, 10, 0, 4), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.Text, Font = Enum.Font.Gotham, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, Parent = frame })
    local valLbl = Create("TextLabel", { Size = UDim2.new(0, 50, 0, 18), Position = UDim2.new(1, -60, 0, 4), BackgroundTransparency = 1, Text = tostring(value), TextColor3 = Theme.Accent, Font = Enum.Font.GothamBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = frame })
    local track = Create("Frame", { Size = UDim2.new(1, -20, 0, 6), Position = UDim2.new(0, 10, 0, 26), BackgroundColor3 = Theme.Line, BorderSizePixel = 0, Parent = frame })
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
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

-- ============================================================
-- INIT TABS
-- ============================================================
local TabMain = AddTab("Main")
local SecMain = AddSection(TabMain, "General")
AddToggle(SecMain, "Enable Feature", false, function(v) print("Feature:", v) end)
AddSlider(SecMain, "Speed Value", 0, 100, 50, function(v) print("Speed:", v) end)

for _, t in pairs(Tabs) do t.Page.Visible = false end
Tabs["Main"].Page.Visible = true
