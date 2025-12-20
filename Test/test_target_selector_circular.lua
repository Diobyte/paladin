describe("my_target_selector.get_most_hits_circular", function()
    local ts = require('my_utility/my_target_selector')

    setup(function()
        _G.target_selector = {}
    end)

    it("returns valid data when target_selector reports hits", function()
        _G.target_selector.get_most_hits_target_circular_area_heavy = function(source, distance, radius)
            return { n_hits = 3, main_target = 'dummy', victim_list = { 'a', 'b' }, score = 2 }
        end

        local area = ts.get_most_hits_circular(nil, 30, 5)
        assert.is_truthy(area.is_valid)
        assert.are.equal(3, area.hits_amount)
        assert.are.equal('dummy', area.main_target)
        assert.are.equal(2, #area.victim_list)
    end)

    it("returns invalid when no hits", function()
        _G.target_selector.get_most_hits_target_circular_area_heavy = function(source, distance, radius)
            return { n_hits = 0 }
        end

        local area2 = ts.get_most_hits_circular(nil, 30, 5)
        assert.is_falsy(area2.is_valid)
    end)
end)
