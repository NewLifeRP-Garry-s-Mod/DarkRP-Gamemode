local function Me(ply, args)
    if args == "" then
        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
        return ""
    end

    local DoSay = function(text)
        if text == "" then
            DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
            return ""
        end
        if GAMEMODE.Config.alltalk then
            local col = team.GetColor(ply:Team())
            local name = ply:Nick()
            for _, target in ipairs(player.GetAll()) do
                DarkRP.talkToPerson(target, col, name .. " " .. text)
            end
        else
            DarkRP.talkToRange(ply, ply:Nick() .. " " .. text, "", GAMEMODE.Config.meDistance)
        end
    end
    return args, DoSay
end
DarkRP.defineChatCommand("me", Me, 1.5)

local function OOC(ply, args)
    if not GAMEMODE.Config.ooc then
        DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("disabled", DarkRP.getPhrase("ooc"), ""))
        return ""
    end

    local DoSay = function(text)
        if text == "" then
            DarkRP.notify(ply, 1, 4, DarkRP.getPhrase("invalid_x", DarkRP.getPhrase("arguments"), ""))
            return ""
        end
        local col = team.GetColor(ply:Team())
        local col2 = color_white
        if not ply:Alive() then
            col2 = Color(255, 200, 200, 255)
            col = col2
        end

        local phrase = DarkRP.getPhrase("ooc")
        local name = ply:Nick()
        for _, v in ipairs(player.GetAll()) do
            DarkRP.talkToPerson(v, col, "(" .. phrase .. ") " .. name, col2, text, ply)
        end
    end
    return args, DoSay
end
DarkRP.defineChatCommand("/", OOC, true, 1.5)
DarkRP.defineChatCommand("a", OOC, true, 1.5)
DarkRP.defineChatCommand("ooc", OOC, true, 1.5)