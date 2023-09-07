local entMeta = FindMetaTable("Entity")

local queuedForRemoval = {}

function GM:Initialize()
    self.Sandbox.Initialize(self)
end

function GM:playerBuyDoor(ply, ent)
    return true
end

function GM:getDoorCost(ply, ent)
    return GAMEMODE.Config.doorcost ~= 0 and GAMEMODE.Config.doorcost or 30
end

function GM:getVehicleCost(ply, ent)
    return GAMEMODE.Config.vehiclecost ~= 0 and GAMEMODE.Config.vehiclecost or 40
end

function GM:canDemote(ply, target, reason)

end

function GM:canVote(ply, vote)

end

function GM:playerWalletChanged(ply, amount)

end

function GM:playerGetSalary(ply, amount)

end

function GM:DarkRPVarChanged(ply, var, oldvar, newvalue)

end

function GM:playerBoughtVehicle(ply, ent, cost)

end

function GM:playerBoughtDoor(ply, ent, cost)

end

function GM:canDropWeapon(ply, weapon)
    if not IsValid(weapon) then return false end
    local class = string.lower(weapon:GetClass())

    if not GAMEMODE.Config.dropspawnedweapons then
        local jobTable = ply:getJobTable()
        if jobTable.weapons and table.HasValue(jobTable.weapons, class) then return false end
    end

    if self.Config.DisallowDrop[class] then return false end

    if not GAMEMODE.Config.restrictdrop then return true end

    for _, v in pairs(CustomShipments) do
        if v.entity ~= class then continue end

        return true
    end

    return false
end

function GM:DatabaseInitialized()
    DarkRP.initDatabase()
end


function GM:PlayerSpawnProp(ply, model)
    -- No prop spawning means no prop spawning.
    local allowed = GAMEMODE.Config.propspawning

    if not allowed then return false end
    if ply:isArrested() then return false end

    model = string.gsub(tostring(model), "\\", "/")
    model = string.gsub(tostring(model), "//", "/")

    local jobTable = ply:getJobTable()
    if jobTable.PlayerSpawnProp then
        jobTable.PlayerSpawnProp(ply, model)
    end

    return self.Sandbox.PlayerSpawnProp(self, ply, model)
end

function GM:PlayerSpawnedProp(ply, model, ent)
    self.Sandbox.PlayerSpawnedProp(self, ply, model, ent)
    ent.SID = ply.SID
    ent:CPPISetOwner(ply)

    local phys = ent:GetPhysicsObject()
    if IsValid(phys) then
        ent.RPOriginalMass = phys:GetMass()
    end
end

function GM:EntityRemoved(ent)
    self.Sandbox.EntityRemoved(self, ent)

    local owner = ent.Getowning_ent and ent:Getowning_ent() or Player(ent.SID or 0)
    if ent.DarkRPItem and IsValid(owner) and not ent.IsPocketing then owner:removeCustomEntity(ent.DarkRPItem) end
    if ent.isKeysOwnable and ent:isKeysOwnable() then ent:removeDoorData() end
end

function GM:ShowSpare1(ply)
    local jobTable = ply:getJobTable()
    if jobTable.ShowSpare1 then
        return jobTable.ShowSpare1(ply)
    end
end

function GM:ShowSpare2(ply)
    local jobTable = ply:getJobTable()
    if jobTable.ShowSpare2 then
        return jobTable.ShowSpare2(ply)
    end
end

function GM:ShowTeam(ply)
end

function GM:ShowHelp(ply)
end

function GM:KeyPress(ply, code)
    self.Sandbox.KeyPress(self, ply, code)
end

function GM:CanPlayerSuicide(ply)
    return false
end

function GM:DoPlayerDeath(ply, attacker, dmginfo, ...)
    self.Sandbox.DoPlayerDeath(self, ply, attacker, dmginfo, ...)
end

function GM:PlayerDeath(ply, weapon, killer)

    ply.blackScreen = true
    SendUserMessage("blackScreen", ply, true)

    if weapon:IsVehicle() and weapon:GetDriver():IsPlayer() then killer = weapon:GetDriver() end

    ply:Extinguish()

    ply:ExitVehicle()

    ply.DeathPos = ply:GetPos()

    if IsValid(ply) and (ply ~= killer or ply.Slayed) and not ply:isArrested() then
        ply.DeathPos = nil
        ply.Slayed = false
    end

    ply.ConfiscatedWeapons = nil

    local KillerName = (killer:IsPlayer() and killer:Nick()) or tostring(killer)
    local WeaponName = IsValid(weapon) and ((weapon:IsPlayer() and weapon:GetActiveWeapon():IsValid() and weapon:GetActiveWeapon():GetClass()) or weapon:GetClass()) or "unknown"

    if killer == ply then
        KillerName = "Themself"
        WeaponName = "suicide trick"
    end

    DarkRP.(ply:Nick() .. " was killed by " .. KillerName .. " with a " .. WeaponName, Color(255, 190, 0))
end

function GM:PlayerCanPickupWeapon(ply, weapon)
    if ply:isArrested() then return false end
    if weapon.PlayerUse == false then return false end
    return true
end

function GM:PlayerSetModel(ply)
    local jobTable = ply:getJobTable()

    if not jobTable then return self.Sandbox.PlayerSetModel(ply) end

    if jobTable.PlayerSetModel then
        local model = jobTable.PlayerSetModel(ply)
        if model then ply:SetModel(model) return end
    end

    local EndModel = ""
    if GAMEMODE.Config.enforceplayermodel then
        if istable(jobTable.model) then
            local ChosenModel = string.lower(ply:getPreferredModel(ply:Team()) or "")

            local found
            for _, Models in pairs(jobTable.model) do
                if ChosenModel == string.lower(Models) then
                    EndModel = Models
                    found = true
                    break
                end
            end

            if not found then
                EndModel = jobTable.model[math.random(#jobTable.model)]
            end
        else
            EndModel = jobTable.model
        end

        ply:SetModel(EndModel)
    else
        local cl_playermodel = ply:GetInfo("cl_playermodel")
        local modelname = player_manager.TranslatePlayerModel(cl_playermodel)
        ply:SetModel(ply:getPreferredModel(ply:Team()) or modelname)
    end

    self.Sandbox.PlayerSetModel(self, ply)

    ply:SetupHands()
end

local function initPlayer(ply)
    ply:updateJob(team.GetName(GAMEMODE.DefaultTeam))
    ply:setSelfDarkRPVar("salary", DarkRP.retrieveSalary(ply))
    ply.LastJob = nil

    ply.Ownedz = {}

    ply:SetTeam(GAMEMODE.DefaultTeam)
    ply.DarkRPInitialised = true
end

local function restoreReconnectedEnts(ply)
    local sid = ply:SteamID64()
    if not queuedForRemoval[sid] then return end

    timer.Remove("DarkRP_removeDisconnected_" .. sid)

    for _, e in pairs(queuedForRemoval[sid]) do
        if not IsValid(e) then continue end

        e.SID = ply.SID

        if e.Setowning_ent then
            e:Setowning_ent(ply)
        end

        if e.DarkRPItem then
            ply:addCustomEntity(e.DarkRPItem)
        end
    end

    queuedForRemoval[sid] = nil
end

function GM:PlayerInitialSpawn(ply)
    self.Sandbox.PlayerInitialSpawn(self, ply)

    local sid = ply:SteamID()
    
    ply:setDarkRPVarsAttribute()
    ply:restorePlayerData()
    initPlayer(ply)
    ply.SID = ply:UserID()

    timer.Simple(1, function()
        if not IsValid(ply) then return end
        local group = GAMEMODE.Config.DefaultPlayerGroups[sid]
        if group then
            ply:SetUserGroup(group)
        end
    end)

    restoreReconnectedEnts(ply)
end

function GM:PlayerSelectSpawn(ply)
    local spawn = self.Sandbox.PlayerSelectSpawn(self, ply)

    local POS
    if spawn and spawn.GetPos then
        POS = spawn:GetPos()
    else
        POS = ply:GetPos()
    end

    local _, hull = ply:GetHull()

    POS = DarkRP.findEmptyPos(POS, {ply}, 600, 30, hull)

    return spawn, POS
end

local oldPlyColor
local function disableBabyGod(ply)
    if not IsValid(ply) or not ply.Babygod then return end

    ply.Babygod = nil
    ply:SetRenderMode(RENDERMODE_NORMAL)
    ply:GodDisable()

    local reinstateOldColor = true

    for _, p in ipairs(player.GetAll()) do
        reinstateOldColor = reinstateOldColor and p.Babygod == nil
    end

    if reinstateOldColor then
        entMeta.SetColor = oldPlyColor
        oldPlyColor = nil
    end

    ply:SetColor(ply.babyGodColor or color_white)

    ply.babyGodColor = nil
end

local function enableBabyGod(ply)
    timer.Remove(ply:EntIndex() .. "babygod")

    ply.Babygod = true
    ply:GodEnable()
    ply.babyGodColor = ply:GetColor()
    ply:SetRenderMode(RENDERMODE_TRANSALPHA)

    if not oldPlyColor then
        oldPlyColor = entMeta.SetColor
        entMeta.SetColor = function(p, c, ...)
            if not p.Babygod then return oldPlyColor(p, c, ...) end

            p.babyGodColor = c
            oldPlyColor(p, Color(c.r, c.g, c.b, 100))
        end
    end

    ply:SetColor(ply.babyGodColor)
    timer.Create(ply:EntIndex() .. "babygod", GAMEMODE.Config.babygodtime or 0, 1, fp{disableBabyGod, ply})
end

function GM:PlayerSpawn(ply)
    if not ply.DarkRPInitialised then
        DarkRP.errorNoHalt(
            string.format("DarkRP was unable to introduce player \"%s\" to the game. Expect further errors and shit generally being fucked!",
                IsValid(ply) and ply:Nick() or "unknown"),
            1,
            {
                "This error most likely does not stand on its own, and previous serverside errors have a very good chance of telling you the cause.",
                "Note that errors from another addon could cause this. Specifically when they're thrown during 'PlayerInitialSpawn'.",
                "This error can also be caused by some other addon returning a value in 'PlayerInitialSpawn', though that is less likely.",
                "Errors in your DarkRP configuration (jobs, shipments, etc.) could also cause this. Earlier errors should tell you when this is the case."
            }
        )
    end

    ply:CrosshairEnable()
    ply:UnSpectate()

    if ply.blackScreen then
        ply.blackScreen = false
        SendUserMessage("blackScreen", ply, false)
    end

    if GAMEMODE.Config.babygod and not ply.IsSleeping and not ply.Babygod then
        enableBabyGod(ply)
    end

    ply:Extinguish()

    for i = 0, 2 do
        local vm = ply:GetViewModel(i)

        if IsValid(vm) then
            vm:Extinguish()
        end
    end

    player_manager.SetPlayerClass(ply, jobTable.playerClass or "player_darkrp")

    ply:applyPlayerClassVars(true)

    player_manager.RunClass(ply, "Spawn")

    hook.Call("PlayerLoadout", self, ply)
    hook.Call("PlayerSetModel", self, ply)

    local ent, pos = hook.Call("PlayerSelectSpawn", self, ply)
    ply:SetPos(pos or ent:GetPos())
end

function GM:PlayerLoadout(ply)
    self.Sandbox.PlayerLoadout(self, ply)
    ply.RPLicenseSpawn = false

    for _, v in pairs(self.Config.DefaultWeapons) do
        ply:Give(v)
    end

    ply:SwitchToDefaultWeapon()
end

local function removeDelayed(entList, ply)
    local removedelay = GAMEMODE.Config.entremovedelay

    if removedelay <= 0 then
        for _, e in pairs(entList) do
            SafeRemoveEntity(e)
        end

        return
    end

    local sid = ply:SteamID64()
    queuedForRemoval[sid] = entList

    timer.Create("DarkRP_removeDisconnected_" .. sid, removedelay, 1, function()
        for _, e in pairs(queuedForRemoval[sid] or {}) do
            SafeRemoveEntity(e)
        end

        queuedForRemoval[sid] = nil
    end)
end

local function collectRemoveEntities(ply)
    if not GAMEMODE.Config.removeondisconnect then return {} end

    local collect = {}
    -- Get the classes of entities to remove
    local remClasses = {}
    for _, customEnt in pairs(DarkRPEntities) do
        remClasses[string.lower(customEnt.ent)] = true
    end

    local sid = ply.SID
    for _, v in ipairs(ents.GetAll()) do
        if v.SID ~= sid or not v:IsVehicle() and not remClasses[string.lower(v:GetClass() or "")] then continue end

        table.insert(collect, v)
    end

    if not ply:isMayor() then return collect end

    for _, ent in pairs(ply.lawboards or {}) do
        if not IsValid(ent) then continue end
        table.insert(collect, ent)
    end

    return collect
end

function GM:PlayerDisconnected(ply)
    self.Sandbox.PlayerDisconnected(self, ply)

    local remList = collectRemoveEntities(ply)
    removeDelayed(remList, ply)

    DarkRP.destroyQuestionsWithEnt(ply)
    DarkRP.destroyVotesWithEnt(ply)

    ply:keysUnOwnAll()
end

function GM:GetFallDamage(ply, flFallSpeed)
    if GetConVar("mp_falldamage"):GetBool() or GAMEMODE.Config.realisticfalldamage then
        if GAMEMODE.Config.falldamagedamper then return flFallSpeed / GAMEMODE.Config.falldamagedamper else return flFallSpeed / 15 end
    else
        if GAMEMODE.Config.falldamageamount then return GAMEMODE.Config.falldamageamount else return 10 end
    end
end

local function fuckQAC()
    local netRecs = {"Debug1", "Debug2", "checksaum", "gcontrol_vars", "control_vars", "QUACK_QUACK_MOTHER_FUCKER"}
    for _, v in pairs(netRecs) do
        net.Receivers[v] = fn.Id
    end
end

function GM:InitPostEntity()
    self.InitPostEntityCalled = true

    local physData = physenv.GetPerformanceSettings()
    physData.MaxVelocity = 2000
    physData.MaxAngularVelocity = 3636

    physenv.SetPerformanceSettings(physData)

    if not GAMEMODE.Config.disallowClientsideScripts then
        game.ConsoleCommand("sv_allowcslua 1\n")
        timer.Simple(1, fuckQAC)
    end
    game.ConsoleCommand("physgun_DampingFactor 0.9\n")
    game.ConsoleCommand("sv_sticktoground 0\n")
    game.ConsoleCommand("sv_airaccelerate 1000\n")
    game.ConsoleCommand("sv_alltalk 0\n")

    for _, v in ipairs(ents.GetAll()) do
        if not v:isDoor() then continue end
        v:Fire("unlock", "", 0)
    end
end
timer.Simple(0.1, function()
    if not GAMEMODE.InitPostEntityCalled then
        GAMEMODE:InitPostEntity()
    end
end)

function GM:PlayerLeaveVehicle(ply, vehicle)
    self.Sandbox.PlayerLeaveVehicle(self, ply, vehicle)
end

local function ClearDecals()
    if GAMEMODE.Config.decalcleaner then
        for _, p in ipairs(player.GetAll()) do
            p:ConCommand("r_cleardecals")
        end
    end
end
timer.Create("RP_DecalCleaner", GM.Config.decaltimer, 0, ClearDecals)

function GM:PlayerSpray()
    return false
end

function GM:GravGunOnPickedUp(ply, ent, ...)
    self.Sandbox.GravGunOnPickedUp(self, ply, ent, ...)
    ent.DarkRPBeingGravGunHeldBy = ply
end

function GM:GravGunOnDropped(ply, ent, ...)
    self.Sandbox.GravGunOnDropped(self, ply, ent, ...)
    ent.DarkRPBeingGravGunHeldBy = nil
end
