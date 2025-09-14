package.path = package.path .. ";data/scripts/lib/?.lua"
include("stringutility")
local PioneerStarterPack = include("pioneerstarterpack")
function execute(sender, commandName)
    local player = Player()
    if not player then
        return 1, "", "You're not a player"
    end
    if onServer() then
        local player = Player()
        -- if not Server():hasAdminPrivileges(player) then
        --     return 1, "", "pspcheck: You're not an admin!"
        -- end
        -- local online = tonumber(player:getValue("onlinetime")) or 0
        local points = tonumber(player:getValue("pointsnumber")) or 0
        local multiplier = PioneerStarterPack.online_pay_credits_per_point
        local offset = PioneerStarterPack.online_pay_offset
        local max = PioneerStarterPack.online_pay_max
        -- local ticks = PioneerStarterPack.online_pay_ticks
        if points < 1 then points = 1 end
        local calculated = (points * multiplier) + offset
        if calculated >= max then calculated = max end
        player:sendChatMessage("PioneerStarterPack", 0, "Online Pay - Values:"%_t)
        player:sendChatMessage("PioneerStarterPack", 0, " - points=${points}" % { points = points })
        player:sendChatMessage("PioneerStarterPack", 0, " - multiplier=${multiplier}" % { multiplier = multiplier })
        player:sendChatMessage("PioneerStarterPack", 0, " - offset=${offset}" % { offset = offset })
        player:sendChatMessage("PioneerStarterPack", 0, " - max=${max}" % { max = max })
        return 0, "",
            ("Your online pay is ${points}×${multiplier}+${offset}, with a maximum of ${max} = ${calculated}."%_t) %
            {
                points = points,
                multiplier = multiplier,
                offset = offset,
                max = max,
                calculated = calculated
            }
    end
    return 0, "", ""
end

function getDescription()
    return "Display pay values"%_t
end

function getHelp()
    return ("Display current pay values: ${cmd}"%_t) % { cmd = "/checkpay" }
end
