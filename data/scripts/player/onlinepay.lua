package.path = package.path .. ";data/scripts/lib/?.lua"
include("stringutility")
local cyclic = 1200

function getUpdateInterval() return 1 end

function update(timeStep)
    if onServer() then
        local player = Player()
        local online = tonumber(player:getValue("onlinetime")) or 0
        local points = tonumber(player:getValue("pointsnumber")) or 0

        online = online + 1
    
        if online >= cyclic then
            points = points + 1
            online = online - cyclic
            local pay = points * 5000 + 5000

            if pay > 100000 then pay = 100000 end
            payUpdate(pay)
        end

        player:setValue("onlinetime", math.floor(online))
        player:setValue("pointsnumber", math.floor(points))

    end
    
end

function payUpdate(pay)
    local player = Player()

    local mail = Mail()
    mail.header = "Hello Pioneer"%_t
    mail.sender = "Star Alliance Incentive Fund Committee"%_t
    mail.text = string.format("20min active time incentive fund has been received: %d credit points"%_t, pay)

    mail.money = math.floor(tonumber(pay) or 0)
    mail.id = "online_"
    
    player:addMail(mail)
end