--[[
The base elements are shared by every custom item
]]
local baseSchema = tc.checkTable{
    buttonColor =
        tc.addHint(
            tc.optional(tc.tableOf(isnumber)),
            "The buttonColor must be a Color value."
        ),

    category =
        tc.addHint(
            tc.optional(isstring),
            "The category must be the name of an existing category!"
        ),

    customCheck =
        tc.addHint(
            tc.optional(isfunction),
            "The customCheck must be a function."
        ),

    CustomCheckFailMsg =
        tc.addHint(
            tc.optional(isstring, isfunction),
            "The CustomCheckFailMsg must be either a string or a function."
        ),

    sortOrder =
        tc.addHint(
            tc.optional(isnumber),
            "The sortOrder must be a number."
        ),

    label =
        tc.addHint(
            tc.optional(isstring),
            "The label must be a valid string."
        ),
}

--[[
Properties shared by anything buyable
]]
local buyableSchema = fn.FAnd{baseSchema, tc.checkTable{
    allowed =
        tc.addHint(
            tc.optional(tc.tableOf(isnumber), isnumber),
            "The allowed field must be either an existing team or a table of existing teams.",
            {"Is there a job here that doesn't exist (anymore)?"}
        ),

    getPrice =
        tc.addHint(
            tc.optional(isfunction),
            "The getPrice must be a function."
        ),

    model =
        tc.addHint(
            isstring,
            "The model must be valid."
        ),

    price =
        tc.addHint(
            function(v, tbl) return isnumber(v) or isfunction(tbl.getPrice) end,
            "The price must be an existing number or (for advanced users) the getPrice field must be a function."
        ),

    spawn =
        tc.addHint(
            tc.optional(isfunction),
            "The spawn must be a function."
        ),
    allowPurchaseWhileDead =
        tc.addHint(
            tc.default(false),
            "The allowPurchaseWhileDead must be either true or false"
        )
}}

-- The command of an entity must be unique
local uniqueEntity = function(cmd, tbl)
    for _, v in pairs(DarkRPEntities) do
        if v.cmd ~= cmd then continue end

        return
            false,
            "This entity does not have a unique command.",
            {
                "There must be some other entity that has the same thing for 'cmd'.",
                "Fix this by changing the 'cmd' field of your entity to something else."
            }
    end

    return true
end

-- The command of a job must be unique
local uniqueJob = function(v, tbl)
    local job = DarkRP.getJobByCommand(v)

    if not job then return true end

    return
        false,
        "This job does not have a unique command.",
        {
            "There must be some other job that has the same command.",
            "Fix this by changing the 'command' of your job to something else."
        }
end

--[[
Validate jobs
]]
DarkRP.validateJob = fn.FAnd{baseSchema, tc.checkTable{
    name =
        tc.addHint(
            isstring,
            "The name must be a valid string."
        ),

    color =
        tc.addHint(
            tc.tableOf(isnumber),
            "The color must be a Color value.",
            {"Color values look like this: Color(r, g, b, a), where r, g, b and a are numbers between 0 and 255."}
        ),

    model =
        tc.addHint(
            fn.FOr{isstring, tc.nonEmpty(tc.tableOf(isstring))},
            "The model must either be a table of correct model strings or a single correct model string.",
            {
                "This error could happens when the model does not exist on the server.",
                "Are you sure the model path is right?",
                "Is the model from an addon that is not properly installed?"
            }
        ),

    description =
        tc.addHint(
            isstring,
            "The description must be a string."
        ),

    weapons =
        tc.addHint(
            tc.optional(tc.tableOf(isstring)),
            "The weapons must be a valid table of strings.",
            {"Example: weapons = {\"med_kit\", \"weapon_bugbait\"},"}
        ),

    command =
        fn.FAnd
        {
            tc.addHint(
                isstring,
                "The command must be a string."
            ),
            uniqueJob
        },

    max =
        tc.addHint(
            fn.FAnd{isnumber, fp{fn.Lte, 0}},
            "The max must be a number greater than or equal to zero.",
            {
                "Zero means infinite.",
                "A decimal between 0 and 1 is seen as a percentage."
            }
        ),

    salary =
        tc.addHint(
            fn.FAnd{isnumber, fp{fn.Lte, 0}},
            "The salary must be a number and it must be greater than zero."
        ),

    admin =
        tc.default(0,
            tc.addHint(
                fn.FAnd{isnumber, fp{fn.Lte, 0}, fp{fn.Gte, 2}},
                "The admin value must be a number and it must be greater than or equal to zero and smaller than three."
            )
        ),

    vote =
        tc.addHint(
            tc.optional(isbool),
            "The vote must be either true or false."
        ),

    ammo =
        tc.addHint(
            tc.optional(tc.tableOf(isnumber)),
            "The ammo must be a table containing numbers.",
            {"See example on https://darkrp.miraheze.org/wiki/DarkRP:CustomJobFields"}
        ),

    hasLicense =
        tc.addHint(
            tc.optional(isbool),
            "The hasLicense must be either true or false."
        ),

    NeedToChangeFrom =
        tc.addHint(
            tc.optional(tc.tableOf(isnumber), isnumber),
            "The NeedToChangeFrom must be either an existing team or a table of existing teams",
            {"Is there a job here that doesn't exist (anymore)?"}
        ),

    modelScale =
        tc.addHint(
            tc.optional(isnumber),
            "The modelScale must be a number."
        ),

    maxpocket =
        tc.addHint(
            tc.optional(isnumber),
            "The maxPocket must be a number."
        ),

    maps =
        tc.addHint(
            tc.optional(tc.tableOf(isstring)),
            "The maps value must be a table of valid map names."
        ),

    candemote =
        tc.default(true,
            tc.addHint(
                isbool,
                "The candemote value must be either true or false."
            )
        ),

    mayor =
        tc.addHint(
            tc.optional(isbool),
            "The mayor value must be either true or false."
        ),

    chief =
        tc.addHint(
            tc.optional(isbool),
            "The chief value must be either true or false."
        ),

    medic =
        tc.addHint(
            tc.optional(isbool),
            "The medic value must be either true or false."
        ),

    cook =
        tc.addHint(
            tc.optional(isbool),
            "The cook value must be either true or false."
        ),

    hobo =
        tc.addHint(
            tc.optional(isbool),
            "The hobo value must be either true or false."
        ),

    playerClass =
        tc.addHint(
            tc.optional(isstring),
            "The playerClass must be a valid string."
        ),

    CanPlayerSuicide =
        tc.addHint(
            tc.optional(isfunction),
            "The CanPlayerSuicide must be a function."
        ),

    PlayerCanPickupWeapon =
        tc.addHint(
            tc.optional(isfunction),
            "The PlayerCanPickupWeapon must be a function."
        ),

    PlayerDeath =
        tc.addHint(
            tc.optional(isfunction),
            "The PlayerDeath must be a function."
        ),

    PlayerLoadout =
        tc.addHint(
            tc.optional(isfunction),
            "The PlayerLoadout must be a function."
        ),

    PlayerSelectSpawn =
        tc.addHint(
            tc.optional(isfunction),
            "The PlayerSelectSpawn must be a function."
        ),

    PlayerSetModel =
        tc.addHint(
            tc.optional(isfunction),
            "The PlayerSetModel must be a function."
        ),

    PlayerSpawn =
        tc.addHint(
            tc.optional(isfunction),
            "The PlayerSpawn must be a function."
        ),

    PlayerSpawnProp =
        tc.addHint(
            tc.optional(isfunction),
            "The PlayerSpawnProp must be a function."
        ),

    RequiresVote =
        tc.addHint(
            tc.optional(isfunction),
            "The RequiresVote must be a function."
        ),

    ShowSpare1 =
        tc.addHint(
            tc.optional(isfunction),
            "The ShowSpare1 must be a function."
        ),

    ShowSpare2 =
        tc.addHint(
            tc.optional(isfunction),
            "The ShowSpare2 must be a function."
        ),

    canStartVote =
        tc.addHint(
            tc.optional(isfunction),
            "The canStartVote must be a function."
        ),

    canStartVoteReason =
        tc.addHint(
            tc.optional(isstring, isfunction),
            "The canStartVoteReason must be either a string or a function."
        ),
}}

--[[
Validate shipments
]]
DarkRP.validateShipment = fn.FAnd{buyableSchema, tc.checkTable{
    name =
        tc.addHint(
            isstring,
            "The name must be a valid string."
        ),

    entity =
        tc.addHint(
            isstring, "The entity of the shipment must be a string."
        ),

    amount =
        tc.addHint(
            fn.FAnd{isnumber, fp{fn.Lte, 0}}, "The amount must be a number and it must be greater than zero."
        ),

    separate =
        tc.addHint(
            tc.optional(isbool), "the separate field must be either true or false."
        ),

    pricesep =
        tc.addHint(
            function(v, tbl) return not tbl.separate or isnumber(v) and v >= 0 end,
            "The pricesep must be a number and it must be greater than or equal to zero."
        ),

    noship =
        tc.addHint(
            tc.optional(isbool),
            "The noship must be either true or false."
        ),

    shipmodel =
        tc.addHint(
            tc.optional(isstring),
            "The shipmodel must be a valid model."
        ),

    weight =
        tc.addHint(
            tc.optional(isnumber),
            "The weight must be a number."
        ),

    spareammo =
        tc.addHint(
            tc.optional(isnumber),
            "The spareammo must be a number."
        ),

    clip1 =
        tc.addHint(
            tc.optional(isnumber),
            "The clip1 must be a number."
        ),

    clip2 =
        tc.addHint(
            tc.optional(isnumber),
            "The clip2 must be a number."
        ),

    shipmentClass =
        tc.addHint(
            tc.optional(isstring),
            "The shipmentClass must be a string."
        ),

    onBought =
        tc.addHint(
            tc.optional(isfunction),
            "The onBought must be a function."
        ),

}}

--[[
Validate Entities
]]
DarkRP.validateEntity = fn.FAnd{buyableSchema, tc.checkTable{
    ent =
        tc.addHint(
            isstring,
            "The ent field must be a string."
        ),

    max =
        tc.addHint(
            function(v, tbl) return isnumber(v) or isfunction(tbl.getMax) end,
            "The max must be an existing number or (for advanced users) the getMax field must be a function."
        ),

    cmd =
        fn.FAnd
        {
            tc.addHint(isstring, "The cmd must be a valid string."),
            uniqueEntity
        },

    name =
        tc.addHint(
            isstring,
            "The name must be a valid string."
        ),

    allowTools =
        tc.default(false,
            tc.addHint(
                tc.optional(isbool),
                "The allowTools must be either true or false."
            )
        ),

    delay =
        tc.addHint(
            tc.optional(isnumber),
            "The delay must be a number."
        ),
}}

--[[
Validate Categories
]]
DarkRP.validateCategory = tc.checkTable{
    name =
        tc.addHint(
            isstring,
            "The name must be a string."
        ),

    categorises =
        tc.addHint(
            tc.oneOf{"jobs", "entities", "shipments", "weapons", "vehicles", "ammo"},
            [[The categorises must be one of "jobs", "entities", "shipments", "weapons", "vehicles", "ammo"]],
            {
                "Mind that this is case sensitive.",
                "Also mind the quotation marks."
            }
        ),

    startExpanded =
        tc.addHint(
            isbool,
            "The startExpanded must be either true or false."
        ),

    color =
        tc.addHint(
            tc.tableOf(isnumber),
            "The color must be a Color value."
        ),

    canSee =
        tc.addHint(
            tc.optional(isfunction),
            "The canSee must be a function."
        ),

    sortOrder =
        tc.addHint(
            tc.optional(isnumber),
            "The sortOrder must be a number."
        ),
}
