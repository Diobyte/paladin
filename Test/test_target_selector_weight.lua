describe("my_target_selector.get_unit_weight and get_best_weighted_target", function()
    local ts = require('my_utility/my_target_selector')

    it("ranks champion highest and returns it as best target", function()
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

        assert.is_true(cscore > vscore)
        assert.is_true(vscore > escore)
        assert.is_true(escore > nscore)

        local best = ts.get_best_weighted_target({ champion, vulnerable, elite, normal })
        assert.are.equal(champion, best)
    end)
end)
