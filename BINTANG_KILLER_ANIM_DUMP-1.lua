--[[
  Bintang — Full Animation Dumper + Deteksi konteks
  Log SEMUA anim (termasuk idle optional)
  Konteks: tool, humanoid state, waktu, marker
]]

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LP = Players.LocalPlayer

local Config = {
    SkipIdleWalk = false, -- true = skip idle/walk/run; false = SEMUA
    LogMarkers = true,
    PrintTableEvery = true,
}

local SKIP = {
    idle = true, walk = true, run = true, jump = true, fall = true,
    climb = true, swim = true, sit = true, land = true,
}

local collected = {} -- id -> info
local logCount = 0

local function shouldSkip(name)
    if not Config.SkipIdleWalk then return false end
    local n = string.lower(tostring(name or ""))
    for k in pairs(SKIP) do
        if n:find(k, 1, true) then return true end
    end
    return false
end

local function toolName(char)
    if not char then return "-" end
    local t = char:FindFirstChildOfClass("Tool")
    if t then return t.Name end
    -- backpack equipped visual
    return "-"
end

local function humState(hum)
    if not hum then return "?" end
    local ok, st = pcall(function() return hum:GetState().Name end)
    return ok and st or "?"
end

local function guessType(name, trackName, tool, length)
    local n = string.lower(tostring(name or "") .. " " .. tostring(trackName or "") .. " " .. tostring(tool or ""))
    if n:find("attack") or n:find("swing") or n:find("slash") or n:find("punch") or n:find("hit") then
        return "ATTACK"
    end
    if n:find("veil") or n:find("spear") or n:find("throw") or n:find("tombak") or n:find("projectile") then
        return "THROW/VEIL"
    end
    if n:find("lunge") or n:find("dash") or n:find("rush") or n:find("charge") then
        return "LUNGE/DASH"
    end
    if n:find("skill") or n:find("ability") or n:find("power") or n:find("special") then
        return "SKILL"
    end
    if n:find("carry") or n:find("grab") or n:find("hook") or n:find("pickup") then
        return "CARRY/HOOK"
    end
    if n:find("stun") or n:find("hurt") or n:find("hitreact") then
        return "STUN/HIT"
    end
    if n:find("idle") then return "IDLE" end
    if n:find("walk") or n:find("run") then return "MOVE" end
    if n:find("emote") or n:find("dance") then return "EMOTE" end
    -- length heuristic
    if length and length > 0 and length <= 0.35 then return "QUICK (maybe attack)" end
    if length and length >= 0.6 and length <= 1.2 then return "MEDIUM (skill/throw?)" end
    if length and length > 1.2 then return "LONG (ability?)" end
    return "UNKNOWN — ingat gerakanmu saat ini"
end

local function printSummary()
    print("======== RINGKASAN ID ========")
    for id, info in pairs(collected) do
        print(string.format("[%s] %s | %s | tool=%s | from=%s",
            info.guess, id, info.name, info.tool, info.from))
    end
    print("-------- TABLE COPY --------")
    print("local KILLER_ANIMS = {")
    for id, info in pairs(collected) do
        print(string.format('    ["%s"] = {name="%s", guess="%s", tool="%s"},',
            id, info.name, info.guess, info.tool))
    end
    print("}")
    print("==============================")
end

local function log(plr, track)
    local anim = track.Animation
    local id = anim and anim.AnimationId
    if not id or id == "" then return end

    local name = (anim and anim.Name) or "?"
    local trackName = track.Name or "?"
    if shouldSkip(name) or shouldSkip(trackName) then return end

    local char = plr.Character
    local hum = char and char:FindFirstChildOfClass("Humanoid")
    local tool = toolName(char)
    local length = track.Length or 0
    local guess = guessType(name, trackName, tool, length)
    local isNew = collected[id] == nil

    collected[id] = {
        name = name,
        track = trackName,
        tool = tool,
        guess = guess,
        length = length,
        from = plr.Name,
    }
    logCount += 1

    print(string.format(
        "[%s] #%d %s\n  Player : %s (%s)\n  Name   : %s | Track: %s\n  ID     : %s\n  Length : %.2fs | Speed: %s | State: %s\n  Tool   : %s\n  GUESS  : %s%s",
        os.date("%H:%M:%S"),
        logCount,
        isNew and "NEW" or "repeat",
        plr.DisplayName or plr.Name,
        plr.Name,
        name,
        trackName,
        id,
        length,
        tostring(track.Speed),
        humState(hum),
        tool,
        guess,
        isNew and "" or " (sudah ada)"
    ))

    if Config.LogMarkers then
        pcall(function()
            track:GetMarkerReachedSignal("Hit"):Connect(function()
                print("  >> MARKER Hit @", id)
            end)
            track:GetMarkerReachedSignal("Swing"):Connect(function()
                print("  >> MARKER Swing @", id)
            end)
            track:GetMarkerReachedSignal("Throw"):Connect(function()
                print("  >> MARKER Throw @", id)
            end)
        end)
    end

    if isNew and Config.PrintTableEvery then
        printSummary()
    end
end

local watching = {}

local function watchChar(plr, char)
    task.spawn(function()
        local hum = char:WaitForChild("Humanoid", 10)
        if not hum then return end
        local animator = hum:FindFirstChildOfClass("Animator")
        if not animator then
            pcall(function() animator = hum:WaitForChild("Animator", 6) end)
        end
        if not animator then
            warn("[Bintang] No Animator:", plr.Name)
            return
        end

        animator.AnimationPlayed:Connect(function(track)
            pcall(log, plr, track)
        end)

        for _, t in ipairs(animator:GetPlayingAnimationTracks()) do
            pcall(log, plr, t)
        end

        char.ChildAdded:Connect(function(c)
            if c:IsA("Tool") then
                print("[TOOL EQUIP]", plr.Name, "→", c.Name)
            end
        end)

        print("[Bintang] Watching", plr.Name)
    end)
end

local function hookPlayer(plr)
    if watching[plr] then return end
    watching[plr] = true
    if plr.Character then watchChar(plr, plr.Character) end
    plr.CharacterAdded:Connect(function(c) watchChar(plr, c) end)
end

for _, p in ipairs(Players:GetPlayers()) do hookPlayer(p) end
Players.PlayerAdded:Connect(hookPlayer)

-- tombol ringkas: tekan P di console suggestion — also chat command style
print("========================================")
print(" Bintang FULL Anim Dump + Deteksi")
print(" SkipIdleWalk =", Config.SkipIdleWalk)
print(" Main normal: swing, skill, throw, lunge")
print(" Tiap anim → GUESS + ID di Console")
print(" Set Config.SkipIdleWalk=true di source")
print(" kalau log terlalu ramai idle")
print("========================================")
