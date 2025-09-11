package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/server/?.lua"
include ("factions")
include ("stringutility")
include ("randomext")
local FactionPacks = include ("factionpacks")
local SectorTurretGenerator = include ("sectorturretgenerator")

function es(name)
    return "data/scripts/systems/" .. name ..".lua"
end

function initialize()
    Server():registerCallback("onPlayerLogIn", "onPlayerLogIn")
end



function onPlayerLogIn(playerIndex)
    local player = Player(playerIndex)
    payUpdate(player)

    -- This is too damn verbose for us. - N3X
    -- Server():broadcastChatMessage("Server", ChatMessageType.ServerInfo, "${player} ended his short vacation and started a new pioneering journey."%_t, player.name)
    -- Server():broadcastChatMessage("Server", ChatMessageType.ServerInfo, "${player} has taken over the command of the fleet. Commander, welcome to take over the fleet."%_t, player.name)
    -- Server():broadcastChatMessage("Server", ChatMessageType.ServerInfo, "${player} --The fleet is ready--, --awaiting the commander's orders--."%_t, player.name)
    local possibilities = {
        "${player} ended his short vacation and started a new journey."%_t,
        "${player} has returned. Commander, you are welcome to take over the fleet."%_t,
        "The fleet is ready, awaiting ${player}'s orders."%_t
    }
    Server():broadcastChatMessage("Server/* Context: onPlayerLogin */"%_t, ChatMessageType.ServerInfo, possibilities[getInt(1,#possibilities)])

    if onServer() then
        checkPlayerValue(player)
    end
end

function checkPlayerValue(player)
    local reg = player:getValue("regtime")
    local log = player:getValue("logtime")
    local day = player:getValue("playday")

    if reg and log and day then
        updatePlayerValue(player, reg, log, day)
    else
        regPlayerValue(player)
    end

end

function updatePlayerValue(player, reg, log, day)
    local time = os.time()
    local date = os.date("%Y-%m-%d",time)

    local d = day
    if log < date then
        d = d + 1
        player:setValue("logtime",date)
        player:setValue("playday", d)
        player:setValue("onlinetime", 0)
        player:setValue("pointsnumber", 0)
        -- print("updatePlayerValue:检测到" .. player.name .. "Login information"%_t)
        print("updatePlayerValue: ${name} login information detected"%_t % {name=player.name})
        payday(player)
    end
    player:sendChatMessage("System"%_t, ChatMessageType.Information, "Welcome Pioneers"%_t)
    player:sendChatMessage("System"%_t, ChatMessageType.Information, "Good luck"%_t)
end

function regPlayerValue(player)
    local time = os.time()
    local date = os.date("%Y-%m-%d",time)

    if not reg then player:setValue("regtime",date) end
    if not log then player:setValue("logtime",date) end
    if not day then player:setValue("playday", 1) end
    -- again
    checkPlayerValue(player)
end
-----------------------------------------------------------------------------------------------------------------------
function payUpdate(player)
    local updates = player:getValue("only_newPlayer")
    if not updates then
        local generator = SectorTurretGenerator()
        local sys_1 = SystemUpgradeTemplate(es("civiltcs"), Rarity(1), Seed(1))
        local sys_2 = SystemUpgradeTemplate(es("militarytcs"), Rarity(1), Seed(1))
        local tur = generator:generate(260, 260, 0, Rarity(1), WeaponType.MiningLaser, Material(1))

        local mail = Mail()
        mail.header = "Hello New Pioneers"%_t --标题
        mail.sender = "Galaxy Development Alliance"%_t --名字
        mail.text = "Welcome to the galactic exploration journey:\n\nStar Alliance will provide newcomer benefits to every new pioneer.\nThank you for joining the galactic exploration journey. To support your initial development, we offer you a starter resource pack.\nWishing you great military success."%_t
        mail.money = 50000
        mail:setResources(5000)
        mail.id = "NewDay"
        mail:addItem(sys_1) mail:addItem(sys_2)
        mail:addTurret(tur)
        player:addMail(mail)
        player:setValue("only_newPlayer", true)
    end
        
end