package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/server/?.lua"
include ("factions")
include ("stringutility")
include ("randomext")
local FactionPacks = include ("factionpacks")
local SectorTurretGenerator = include ("sectorturretgenerator")

--NYdebug
include("nvcx")
--local update = include("Gnvcx/update")
local debug

function initialize()
    Server():registerCallback("onPlayerLogIn", "onPlayerLogIn")
    Server():registerCallback("onPlayerLogOff", "onPlayerLogOff")
    Galaxy():registerCallback("onPlayerCreated", "onPlayerCreated")
    Galaxy():registerCallback("onFactionCreated", "onFactionCreated")

    FactionPacks.initialize()
end

-- guardian_respawn_time:   Respawn Time of Guardian (updated in line 22ff, set in wormholeguardian.lua:79)  
-- xsotan_swarm_time:       Respawn Time of Xsotan Swarm (updated in line 34ff and set in line 55 and 65)  
-- xsotan_swarm_duration:   Base time player have to complete the xsotan swarm event, is increased by 10 min if end boss spawns  

-- 守护者的重生时间 设置于 wormholeguard.lua
-- 如果虫守复活且暴动，则暴动增加10分钟

function getUpdateInterval() return 0.1 end

function update(timeStep)
    local server = Server()
    -- .2| 检查并更新虫母状态   冷却 or 复活
    local guardianRespawnTime = server:getValue("guardian_respawn_time")
    -- | 当守护者存活时 guardian_respawn_time = nil
    if guardianRespawnTime then 
        guardianRespawnTime = guardianRespawnTime - timeStep

        if guardianRespawnTime < 0 then
            guardianRespawnTime = nil
            server:broadcastChatMessage("Server", ChatMessageType.Information, "Strong subspace disturbances have been detected. They seem to be originating from the center of the galaxy."%_T)
            -- 配置守护者相关内容需要前往 wormholeguardian.lua 这里只做通知和更新时间
        end
        server:setValue("guardian_respawn_time", guardianRespawnTime)
    end
    --[[
        xsotan_swarm_active     暴动状态
        xsotan_swarm_success    战果
        xsotan_swarm_duration   暴动计时器 (发生
        xsotan_swarm_time       暴动计时器 (冷却
    ]]
    -- .2| 检查并更新暴动状态   休整 or 暴动
    local xsotanSwarmSpawnTime = server:getValue("xsotan_swarm_time")
    if xsotanSwarmSpawnTime then
        xsotanSwarmSpawnTime = xsotanSwarmSpawnTime - timeStep
        -- | 索坦的暴动倒计时低于或等于 0 的话,那么便可以开始下一场暴动.
        if xsotanSwarmSpawnTime <= 0 then
            server:setValue("xsotan_swarm_active", true) -- | 暴动状态
            server:setValue("xsotan_swarm_success", nil) -- | 暴动结果
            server:setValue("xsotan_swarm_duration", 30 * 60) -- | 暴动持续时间
            server:setValue("xsotan_swarm_time", nil) -- | 清空暴动倒计时,防止多重暴动
            server:broadcastChatMessage("", ChatMessageType.Information, "Massive amounts of Xsotan are swarming in the center of the galaxy."%_T)
        else
            server:setValue("xsotan_swarm_time", xsotanSwarmSpawnTime)
        end
    end
    
    -- .3| 检查并更新暴动状态   胜利 or 失败
    local xsotanSwarmEventTime = server:getValue("xsotan_swarm_duration")
    if xsotanSwarmEventTime then
        -- | 提前储存并更新倒计时,如果胜利/失败再次清空 这样会损失微乎其微的性能?
        xsotanSwarmEventTime = xsotanSwarmEventTime - timeStep
        server:setValue("xsotan_swarm_duration", xsotanSwarmEventTime)

        -- | 胜利结算
        local success = server:getValue("xsotan_swarm_success")
        if success then
            settleXsotanSwarmEvent("victory")
        end
        -- | 失败结算
        if xsotanSwarmEventTime <= 0 and not success then
            settleXsotanSwarmEvent("failed")
        end
    end
    local serverRuntime = server:getValue("online_time") or 0
    serverRuntime = serverRuntime + timeStep
    server:setValue("online_time", serverRuntime)
end

function settleXsotanSwarmEvent(state)
    local server = Server()
    -- | 关闭暴动状态和清空持续时间
    server:setValue("xsotan_swarm_active", false)
    server:setValue("xsotan_swarm_duration", nil)

    local stableValue = server:getValue("xsotanStableValue")
    if not stableValue then 
        -- | 安定值每 50 会增加一小时延迟 最高 36 小时
        -- | 初始化后的安定值仅有 200 即 4 小时暴动
        -- | 安定值的最低限制为 600 ,也就是说，即使是失败，也不会低于 200,随着不断地胜利,安定值最终会抵达 2400 的上限
        -- | 但是 2400 并不会提供 48H(4day) 的冷却时间， 而是在 36H(3day) 后抵达上限
        stableValue = 200
        print("server: Initializing stability value | ${value}"%_t % {value=stableValue})
    end

    if state == "victory" then
        stableValue = (stableValue < 2400) and (stableValue + 50) or stableValue
        server:sendCallback("onXsotanSwarmEventWon")
        server:broadcastChatMessage("", ChatMessageType.Information, "The Xsotan swarm invasion has been defeated!"%_T)
    end
    if state == "failed" then
        stableValue = (stableValue >= 600) and (stableValue - 100) or stableValue
        server:sendCallback("onXsotanSwarmEventFailed")
        server:setValue("xsotan_swarm_success", false)
        server:broadcastChatMessage("", ChatMessageType.Information, "The defenses were overrun. The attack of the Xsotan swarm succeded."%_T)
        
    end
    local cds = 60
    if stableValue < 600 then
        server:broadcastChatMessage("", ChatMessageType.Information, "Rift Research Institute: The space within the barrier remains unstable, like a broken basket. We fear they will soon return..."%_T)
        cds = 30
    end
    if stableValue < 1200 and stableValue >= 600 then
        server:broadcastChatMessage("", ChatMessageType.Information, "Rift Research Institute: A portion of the barrier has calmed down. We should be able to enjoy a moment of peace."%_T)
        cds = 40
    end
    if stableValue < 1800 and stableValue >= 1200 then
        server:broadcastChatMessage("", ChatMessageType.Information, "Rift Research Institute: Most of the space within the barrier has become completely peaceful, and a Xsotan attack is unlikely for some time."%_T)
        cds = 50
    end
    if stableValue >= 1800 then -- 上限
        server:broadcastChatMessage("", ChatMessageType.Information, "Rift Research Institute: The Xsotan will be silent for a long time, but our war seems to never end..."%_T)
        server:broadcastChatMessage("", ChatMessageType.Information, "Rift Research Institute: But this is the best outcome, isn't it?"%_T)
        cds = 60
    end

    local nextTime = stableValue / 50
    nextTime = (nextTime > 36) and 36 or nextTime
    server:setValue("xsotan_swarm_time", nextTime * 60 * cds)--| 更新倒计时
    server:setValue("xsotanStableValue", stableValue) -- | 更新安定值
    -- print("server: 本次暴动结算 安定值 | "..stableValue)
end

function onPlayerCreated(index)
    local player = Player(index)

    chatFirstMessage("create", player)

end

function onFactionCreated(index) end

function onPlayerLogIn(playerIndex)
    local player = Player(playerIndex)
    
    chatFirstMessage("login", player)
    player.infiniteResources = Server().infiniteResources

    local settings = GameSettings()
    if settings.fullBuildingUnlocked then
        player.maxBuildableMaterial = Material(MaterialType.Avorion)
    end

    if settings.unlimitedProcessingPower or settings.fullBuildingUnlocked then
        player.maxBuildableSockets = 0
    end

    payUpdate(player)

    if onServer() then
        --print("检测到玩家登录，开始运行检测玩家数据")
        checkPlayerValue(player)
    end
    
end

function onPlayerLogOff(playerIndex)
    local player = Player(playerIndex)
    
    chatFirstMessage("logoff", player)
end

function chatFirstMessage(action, player)

    local seed = GameSeed().int32
    if onServer() then seed = os.time() end
    math.randomseed(seed)
    local texts

    if action == "create" then
        texts = {
            "Rumor has it that a traveler named ${player} has embarked on a journey across the stars."%_t,
            "An explorer named ${player} appears in the distance, and his story begins in this starry sky."%_t,
        }
    end
    if action == "login" then
        texts = {
            "After a short rest, ${player} set sail again."%_t,
            "${player} sets sail again, ready to face new challenges."%_t,
            "${player} ends his short vacation and embarks on a new adventure."%_t,
        }
    end
    if action == "logoff" then
        texts = {
            "Due to the end of his schedule, ${player} closed the star map."%_t,
            "Perhaps because the journey has reached a certain stage, ${player} has made a new vacation schedule."%_t,
            "${player} seems to be no longer active, and there are few rumors about him in the stars recently."%_t,
        }
    end
    -- getInt是获取随机整数
    local sum = #texts
    local rd = getInt(1, sum)
    local bt = texts[rd]

    Server():broadcastChatMessage("Server", ChatMessageType.ServerInfo, bt % {player=player.name})

    -- if debug then
    --     print("==============================")
    --     print("seed:" .. seed)
    --     print("player:" .. player.name)
    --     print("texts: MAX&SELECT:" .. sum .. "|" .. rd)
    --     print("type:" .. bt)
    --     print("==============================")
    -- end

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
    local server = Server()

    local d = day
    if log < date then
        -- 今日未登录
        d = d + 1
        player:setValue("logtime",date)
        player:setValue("playday", d)
        -- print("updatePlayerValue:检测到" .. player.name .. "今日首次登录")
        print("updatePlayerValue: Detected that ${name} logged in for the first time today"%_t % {name=player.name})
        -- payday(player)
    else
    end
    player:sendChatMessage("System"%_t, ChatMessageType.Information, "Welcome to ${servername}"%_t % {servername=server.name})
    -- player:sendChatMessage("System"%_t, ChatMessageType.Information, "您的注册日期为：" .. reg)
    -- player:sendChatMessage("System"%_t, ChatMessageType.Information, "您的游戏天数为：" .. d)
    player:sendChatMessage("System"%_t, ChatMessageType.Information, "Good hunting"%_t)
end

function regPlayerValue(player)
    local time = os.time()
    local date = os.date("%Y-%m-%d",time)

    if not reg then
        -- print("regPlayerValue:正在注册 " .. player.name .. " 注册账号日期")
        player:setValue("regtime",date)
        player:sendChatMessage("System"%_t, ChatMessageType.Information, "Successfully registered new player data. Your registration date is: ${date}"%_t % {date=date})
    end
    if not log then
        -- print("regPlayerValue:正在注册 " .. player.name .. " 最后登录日期")
        player:setValue("logtime",date)
    end
    if not day then
        -- print("regPlayerValue:正在注册 " .. player.name .. " 累计登录天数")
        player:setValue("playday", 1)
    end
    -- 再次运行检测步骤
    checkPlayerValue(player)
end


function payUpdate(player)
if onServer() then
    -- local updates = player:getValue("bugfix_warbonus")
    -- if not updates then
    --     local mail = Mail()
    --     mail.header = "逆夜的垃圾堆" 
    --     mail.sender = "NVCX Server" 
    --     mail.text = "2024-07-02资源补偿\n"
    --     .."本邮件作为战报结算补给补偿\n"
    --     .."战报结算补给之后会由冒险家协会发放\n"
    --     mail.money = 1000000
    --     mail:setResources(200000, 125000, 10000, 648)
    --     mail.id = "bugfix_warbonus"
    --     player:addMail(mail)
    --     player:setValue("bugfix_warbonus", true)
    -- end

    local updates = player:getValue("only_newPlayer")
    local server = Server()
    if not updates then
        local mail = Mail()
        mail.header = "Welcome to ${servername}"%_t % {servername=server.name} --标题
        mail.sender = "Server Administrator"%_t --Server administrator (backtranslated)
        mail.text = "Hello, new adventurer!\n\nTo ensure a pleasant gaming experience for all on this server, please follow the rules as set out in the MOTD.\n\nIf you have any questions or need any help, please join the server's Discord channel.\n\nBest of luck!"%_t
        mail.money = 520
        mail:setResources(95000, 45000, 648)
        mail.id = "NewPlayer"
        player:addMail(mail)
        player:setValue("only_newPlayer", true)
    end
    
end
end

-- function payday(player)
-- if onServer() then
--     local time = os.time()
--     local date = os.date("%w",time)

--     local updates = player:getValue("only_newPlayer")
--     if not updates then
--         local mail = Mail()
--         mail.header = "Welcome to the Starry Sailing Server"%_T --标题
--         mail.sender = "繁星服务器 管理员" --名字
--         mail.text = "新来的冒险家您好:\n\n"
--         .."为了保证所有的冒险家的游玩体验请您务必阅读并遵守以下规则:\n"
--         .. "1.避免使用堆叠方块舰船/空间站进行游戏，这会导致服务器崩溃。\n"
--         .."2.禁止使用恶性Bug对副武器造成破坏/影响其他玩家正常游戏。\n\n"
--         .."如果拥有疑惑或者需要帮助    欢迎加入Avorion游戏讨论QQ群:249540861\n"
--         .."以上\n祝君武运昌隆"
--         mail.money = 520
--         mail.id = "NewPlayer"
--         player:addMail(mail)
--         player:setValue("only_newPlayer", true)
--     end
    
-- end
-- end
