package.path = package.path .. ";data/scripts/lib/?.lua"

function execute(sender, commandName)

    local player = Player()
    if not player then
        return 1, "", "You're not in a ship!"
    end

    local self = player.craft
    if not self then
        return 1, "", "You're not in a ship!"
    end

    local craft = self.selectedObject or self

    craft:addScript("lib/entitydbg.lua")

    return 0, "", ""
end

function getDescription()
    return "启用调试面板"
end

function getHelp()
    return "打开调试面板: /debug"
end
