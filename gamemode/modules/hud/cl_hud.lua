--[[---------------------------------------------------------------------------
HUD ConVars
---------------------------------------------------------------------------]]
local ConVars = {}
local HUDWidth
local HUDHeight

local Color = Color
local CurTime = CurTime
local cvars = cvars
local DarkRP = DarkRP
local draw = draw
local GetConVar = GetConVar
local hook = hook
local IsValid = IsValid
local Lerp = Lerp
local localplayer
local math = math
local pairs = pairs
local ScrW, ScrH = ScrW, ScrH
local SortedPairs = SortedPairs
local string = string
local surface = surface
local table = table
local timer = timer
local tostring = tostring
local plyMeta = FindMetaTable("Player")

local colors = {}
colors.black = color_black
colors.blue = Color(0, 0, 255, 255)
colors.brightred = Color(200, 30, 30, 255)
colors.darkred = Color(0, 0, 70, 100)
colors.darkblack = Color(0, 0, 0, 200)
colors.gray1 = Color(0, 0, 0, 155)
colors.gray2 = Color(51, 58, 51,100)
colors.red = Color(255, 0, 0, 255)
colors.white = color_white
colors.white1 = Color(255, 255, 255, 200)

local function ReloadConVars()
    ConVars = {
        background = {0,0,0,100},
        Healthbackground = {0,0,0,200},
        Healthforeground = {140,0,0,180},
        HealthText = {255,255,255,200},
        Job1 = {0,0,150,200},
        Job2 = {0,0,0,255},
        salary1 = {0,150,0,200},
        salary2 = {0,0,0,255}
    }

    for name, Colour in pairs(ConVars) do
        ConVars[name] = {}
        for num, rgb in SortedPairs(Colour) do
            local CVar = GetConVar(name .. num) or CreateClientConVar(name .. num, rgb, true, false)
            table.insert(ConVars[name], CVar:GetInt())

            if not cvars.GetConVarCallbacks(name .. num, false) then
                cvars.AddChangeCallback(name .. num, function()
                    timer.Simple(0, ReloadConVars)
                end)
            end
        end
        ConVars[name] = Color(unpack(ConVars[name]))
    end


    HUDWidth =  (GetConVar("HudW") or CreateClientConVar("HudW", 240, true, false)):GetInt()
    HUDHeight = (GetConVar("HudH") or CreateClientConVar("HudH", 115, true, false)):GetInt()

    if not cvars.GetConVarCallbacks("HudW", false) and not cvars.GetConVarCallbacks("HudH", false) then
        cvars.AddChangeCallback("HudW", function() timer.Simple(0,ReloadConVars) end)
        cvars.AddChangeCallback("HudH", function() timer.Simple(0,ReloadConVars) end)
    end
end
ReloadConVars()

local Scrw, Scrh, RelativeX, RelativeY
--[[---------------------------------------------------------------------------
HUD separate Elements
---------------------------------------------------------------------------]]
local Health = 0
local function DrawHealth()
    local maxHealth = localplayer:GetMaxHealth()
    local myHealth = localplayer:Health()
    Health = math.min(maxHealth, (Health == myHealth and Health) or Lerp(0.1, Health, myHealth))

    local healthRatio = math.Min(Health / maxHealth, 1)
    local rounded = math.Round(3 * healthRatio)
    local Border = math.Min(6, rounded * rounded)
    draw.RoundedBox(Border, RelativeX + 4, RelativeY - 30, HUDWidth - 8, 20, ConVars.Healthbackground)
    draw.RoundedBox(Border, RelativeX + 5, RelativeY - 29, (HUDWidth - 9) * healthRatio, 18, ConVars.Healthforeground)

    draw.DrawNonParsedText(math.Max(0, math.Round(myHealth)), "DarkRPHUD2", RelativeX + 4 + (HUDWidth - 8) / 2, RelativeY - 32, ConVars.HealthText, 1)

    -- Armor
    local armor = math.Clamp(localplayer:Armor(), 0, 100)
    if armor ~= 0 then
        draw.RoundedBox(2, RelativeX + 4, RelativeY - 15, (HUDWidth - 8) * armor / 100, 5, colors.blue)
    end
end

local JobWalletText
local function DrawInfo()
    JobWalletText = JobWalletText or string.format("%s\n%s",
        DarkRP.getPhrase("wallet", DarkRP.formatMoney(localplayer:getDarkRPVar("money")), "")
    )

    draw.DrawNonParsedText(JobWalletText, "DarkRPHUD2", RelativeX + 5, RelativeY - HUDHeight + h + 6, ConVars.Job1, 0)
    draw.DrawNonParsedText(JobWalletText, "DarkRPHUD2", RelativeX + 4, RelativeY - HUDHeight + h + 5, ConVars.Job2, 0)
end

--[[---------------------------------------------------------------------------
Drawing the HUD elements such as Health etc.
---------------------------------------------------------------------------]]
local function DrawHUD(gamemodeTable)
    local shouldDraw = hook.Call("HUDShouldDraw", gamemodeTable, "DarkRP_HUD")
    if shouldDraw == false then return end

    Scrw, Scrh = ScrW(), ScrH()
    RelativeX, RelativeY = 0, Scrh

    shouldDraw = hook.Call("HUDShouldDraw", gamemodeTable, "DarkRP_LocalPlayerHUD")
    shouldDraw = shouldDraw ~= false
    if shouldDraw then
        --Background
        draw.RoundedBox(6, 0, Scrh - HUDHeight, HUDWidth, HUDHeight, ConVars.background)
        DrawHealth()
        DrawInfo()
    end
    DrawVoiceChat(gamemodeTable)
end

--[[---------------------------------------------------------------------------
Entity HUDPaint things
---------------------------------------------------------------------------]]
-- Draw a player's name, health and/or job above the head
-- This syntax allows for easy overriding
plyMeta.drawPlayerInfo = plyMeta.drawPlayerInfo or function(self)
    local pos = self:EyePos()

    pos.z = pos.z + 10 -- The position we want is a bit above the position of the eyes
    pos = pos:ToScreen()

    if GAMEMODE.Config.showname then
        local nick = self:Nick()
        draw.DrawNonParsedText(nick, "DarkRPHUD2", pos.x + 1, pos.y + 1, colors.black, 1)
    end

    if GAMEMODE.Config.showhealth then
        local health = DarkRP.getPhrase("health", math.max(0, self:Health()))
        draw.DrawNonParsedText(health, "DarkRPHUD2", pos.x + 1, pos.y + 21, colors.black, 1)
        draw.DrawNonParsedText(health, "DarkRPHUD2", pos.x, pos.y + 20, colors.white1, 1)
    end
end

--[[---------------------------------------------------------------------------
Remove some elements from the HUD in favour of the DarkRP HUD
---------------------------------------------------------------------------]]
local noDraw = {
    ["CHudHealth"] = true,
    ["CHudBattery"] = true,
    ["CHudSuitPower"] = true,
    ["CHUDQuickInfo"] = true
}
function GM:HUDShouldDraw(name)
    if noDraw[name] or (HelpToggled and name == "CHudChat") then
        return false
    else
        return self.Sandbox.HUDShouldDraw(self, name)
    end
end

--[[---------------------------------------------------------------------------
Disable players' names popping up when looking at them
---------------------------------------------------------------------------]]
function GM:HUDDrawTargetID()
    return false
end

--[[---------------------------------------------------------------------------
Actual HUDPaint hook
---------------------------------------------------------------------------]]
function GM:HUDPaint()
    localplayer = localplayer or LocalPlayer()

    DrawHUD(self)
    DrawEntityDisplay(self)

    self.Sandbox.HUDPaint(self)
end
