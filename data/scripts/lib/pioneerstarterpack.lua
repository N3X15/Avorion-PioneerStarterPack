-- Don't remove or alter the following comment, it tells the game the namespace this script lives in. If you remove it, the script will break.
-- namespace PioneerStarterPack
PioneerStarterPack={}
package.path = package.path .. ";data/scripts/lib/?.lua"
package.path = package.path .. ";data/scripts/?.lua"

-------------------------------------------
-- Instance variables
-------------------------------------------
-- Scaling values

--[[
* Every {ticks} ticks, 1 point is given.
* Pay is distributed as ({points} * {credits_per_point}) + {offset}.
]]--

-- Pay is distributed once this many ticks have elapsed.
_DEFAULT_ONLINEPAY_TICKS=1200
PioneerStarterPack.online_pay_ticks = _DEFAULT_ONLINEPAY_TICKS
-- Multiplier for online pay
_DEFAULT_ONLINEPAY_CREDITS_PER_POINT=5000
PioneerStarterPack.online_pay_credits_per_point = _DEFAULT_ONLINEPAY_CREDITS_PER_POINT
-- Offset for online pay
_DEFAULT_ONLINEPAY_OFFSET=5000
PioneerStarterPack.online_pay_offset = _DEFAULT_ONLINEPAY_OFFSET
-- Online pay is clamped to this maximum value.
_DEFAULT_ONLINEPAY_MAX=100000
PioneerStarterPack.online_pay_max = _DEFAULT_ONLINEPAY_MAX

_PSP_CONFIG_VERSION=0

-- local self = PioneerStarterPack
function PioneerStarterPack.resetConfig()
    self.online_pay_credits_per_point = _DEFAULT_ONLINEPAY_CREDITS_PER_POINT
    self.online_pay_offset = _DEFAULT_ONLINEPAY_OFFSET
    self.online_pay_max = _DEFAULT_ONLINEPAY_MAX
    self.online_pay_ticks = _DEFAULT_ONLINEPAY_TICKS
    self.saveConfig()
end
function PioneerStarterPack.initialize()
    self.loadConfig()
end
function PioneerStarterPack.getConfigDir()
    local dir = "moddata"
    if onServer() then
        dir = Server().folder .. "/" .. dir
    end
end

function PioneerStarterPack.getConfigFile()
    return self.getConfigDir() .. "/pioneerstarterpack.lua"
end
function PioneerStarterPack.loadConfig()
    local fh, err = io.open(self.getConfigFile(), "rb")
    if err then
        print("[PioneerStarterPack]" .. ("Error opening configuration file for read: ${error}"%_t) % { error = err })
        self.resetConfig()
        return
    end
    local contents = fh:read("*all") or ""
    local data, err = loadstring("return" .. contents)
    fh:close()
    if not data then
        print("[PioneerStarterPack]" .. ("Error parsing configuration file! Contents: ${content}"%_t) %
        { content = err })
        self.resetConfig()
        return
    end
    data = data()
    if type(data) ~= "table" then -- empty file
        self.resetConfig()
        return
    end

    function toint(v)
        return math.round(tonumber(v))
    end
    local online_pay = data["online_pay"] or {}
    self.online_pay_ticks = toint(online_pay["ticks"] or _DEFAULT_ONLINEPAY_TICKS)
    self.online_pay_credits_per_point = toint(online_pay["credits_per_point"] or _DEFAULT_ONLINEPAY_CREDITS_PER_POINT)
    self.online_pay_offset = toint(online_pay["offset"] or _DEFAULT_ONLINEPAY_OFFSET)
    self.online_pay_max = toint(online_pay["max"] or _DEFAULT_ONLINEPAY_MAX)
end

function PioneerStarterPack.saveConfig()
    createDirectory(self.getConfigDir())
    local fh, err = io.open(self.getConfigFile(), "wb")
    if err then
        print("[PioneerStarterPack]" .. ("Error opening configuration file for write: ${error}" % _t) % { error = err })
        return
    end
    if fh==nil then return end

    fh.write("{\n")
    fh.write("  [\"online_pay\"] = {\n")
    fh.write("      --[[\n")
    fh.write("       * Every {ticks} ticks, 1 point is given.\n")
    fh.write("       * Pay is distributed as ({points} * {credits_per_point}) + {offset}.\n")
    fh.write("      ]]--\n")
    fh.write("\n")
    fh.write("      -- How many ticks each pay period is. 1 tick = 1/60th of a second\n")
    fh.write("      -- Default: %d\n" % _DEFAULT_ONLINEPAY_TICKS)
    fh.write("      [\"ticks\"] = %d,\n" % self.online_pay_ticks)
    fh.write("\n")
    fh.write("      -- How many credits to give for each point\n")
    fh.write("      -- Default: %d\n" % _DEFAULT_ONLINEPAY_CREDITS_PER_POINT)
    fh.write("      [\"credits_per_point\"] = %d,\n" % self.online_pay_credits_per_point)
    fh.write("\n")
    fh.write("      -- How many credits are to be added on top of the multiplied points\n")
    fh.write("      -- Default: %d\n" % _DEFAULT_ONLINEPAY_OFFSET)
    fh.write("      [\"offset\"] = %d,\n" % self.online_pay_offset)
    fh.write("\n")
    fh.write("      -- Maximum number of credits to give\n")
    fh.write("      -- Default: %d\n" % _DEFAULT_ONLINEPAY_MAX)
    fh.write("      [\"max\"] = %d,\n" % self.online_pay_max)
    fh.write("  },\n")
    fh.write("  -- Do not touch, used for version updates.\n")
    fh.write("  [\"_version_\"]=%d,\n" % _PSP_CONFIG_VERSION)
    fh.write("}\n")

    fh:close()
end

return PioneerStarterPack