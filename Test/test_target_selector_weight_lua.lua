local ts = require('my_utility/my_target_selector')

local champion = {
    get_buffs = function() return {} end,
    get_max_health = function() return 100 end,
    get_current_health = function() return 100 end,
    is_vulnerable = function() return false end,
    is_champion = function() return true end,
    is_elite = function() return false end
}

local vulnerable = {
    get_buffs = function() return {} end,
    get_max_health = function() return 100 end,
    get_current_health = function() return 100 end,
    is_vulnerable = function() return true end,
    is_champion = function() return false end,
    is_elite = function() return false end
}

local elite = {
    get_buffs = function() return {} end,
    get_max_health = function() return 100 end,
    get_current_health = function() return 100 end,
    is_vulnerable = function() return false end,
    is_champion = function() return false end,
    is_elite = function() return true end
}

local normal = {
    get_buffs = function() return {} end,
    get_max_health = function() return 100 end,
    get_current_health = function() return 100 end,
    is_vulnerable = function() return false end,
    is_champion = function() return false end,
    is_elite = function() return false end
}

local cscore = ts.get_unit_weight(champion)
local vscore = ts.get_unit_weight(vulnerable)
local escore = ts.get_unit_weight(elite)
local nscore = ts.get_unit_weight(normal)

if not (cscore > vscore and vscore > escore and escore > nscore) then
    print('TEST FAIL: Weight ordering incorrect', cscore, vscore, escore, nscore)
    os.exit(1)
end

local best = ts.get_best_weighted_target({ champion, vulnerable, elite, normal })
if best ~= champion then
    print('TEST FAIL: Best target is not champion')
    os.exit(1)
end

print('TEST PASS: target selector weight ordering and selection OK')
os.exit(0)
