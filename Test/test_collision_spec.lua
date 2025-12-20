describe("CheckActorCollision and get_target_list collision behavior (busted)", function()
    local ts

    setup(function()
        ts = require('my_utility/my_target_selector')
        _G.vec2 = { new = function(x, y) return { x = x, y = y } end }
    end)

    it("determines points inside and outside a width correctly", function()
        local StartPoint = { _x = 0, _y = 0 }
        function StartPoint:x() return self._x end

        function StartPoint:y() return self._y end

        local EndPoint = { _x = 10, _y = 0 }
        function EndPoint:x() return self._x end

        function EndPoint:y() return self._y end

        local closePoint = { _x = 5, _y = 1 }
        function closePoint:x() return self._x end

        function closePoint:y() return self._y end

        local farPoint = { _x = 5, _y = 3 }
        function farPoint:x() return self._x end

        function farPoint:y() return self._y end

        assert.is_true(CheckActorCollision(StartPoint, EndPoint, closePoint, 2))
        assert.is_false(CheckActorCollision(StartPoint, EndPoint, farPoint, 2))
    end)

    it("respects prediction.is_wall_collision in get_target_list", function()
        _G.target_selector = { get_near_target_list = function(src, range) return { { is_untargetable = function() return false end, is_immune = function() return false end, get_position = function() return { x = 0, y = 0, z = 0 } end } } end }
        _G.prediction = { is_wall_collision = function() return true end }

        local vis, all = ts.get_target_list({ x = 0, y = 0, z = 0 }, 10, { true, 1 }, { false, 0 }, { false, 0 })
        assert.are.equal(1, #all)
        assert.are.equal(0, #vis)
    end)
end)
