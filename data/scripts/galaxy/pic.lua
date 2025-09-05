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

    Server():broadcastChatMessage("Server", ChatMessageType.ServerInfo, "%s 结束了他短暂的假期，开始了新的开拓之旅。", player.name)
    Server():broadcastChatMessage("Server", ChatMessageType.ServerInfo, "%s 已接管舰队指挥权限，欢迎指挥官接管舰队。", player.name)
    Server():broadcastChatMessage("Server", ChatMessageType.ServerInfo, "%s --舰队已整装完毕--，--等待指挥官命令--。", player.name)

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
        print("updatePlayerValue:检测到" .. player.name .. "登入信息"%_t)
        payday(player)
    end
    player:sendChatMessage("系统", ChatMessageType.Information, "欢迎开拓者"%_t)
    player:sendChatMessage("系统", ChatMessageType.Information, "祝君好运"%_t)
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
        mail.header = "您好新晋开拓者"%_t --标题
        mail.sender = "星河开拓联盟"%_t --名字
        mail.text = "欢迎加入银河开拓之旅:\n\n"%_t--内容
        .."星联将为每一位新晋开拓者发放新人福利\n"%_t
        .."感谢您加入宇宙开拓，为支持您的初期发展，特此奉上启动资源包\n祝君武运昌隆"%_t
        mail.money = 50000
        mail:setResources(5000)
        mail.id = "NewDay"
        mail:addItem(sys_1) mail:addItem(sys_2)
        mail:addTurret(tur)
        player:addMail(mail)
        player:setValue("only_newPlayer", true)
    end
        
end