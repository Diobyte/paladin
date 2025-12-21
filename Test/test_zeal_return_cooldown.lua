local zeal = require('spells/zeal')

-- Stub environment
package.loaded['utility'] = { is_spell_ready = function() return true end }
_G.cast_spell = { target = function(target, spell_id) return true end }
_G.get_time_since_inject = function() return 200 end

local fake_target = {
    is_elite = function() return true end,
    get_position = function() return { x = 0, y = 0, z = 0 } end
}

local ok, cooldown = zeal.logics(fake_target)
if not ok then
    print('TEST FAIL: zeal.logics should return true when cast succeeds')
    os.exit(1)
end
if type(cooldown) ~= 'number' then
    print('TEST FAIL: zeal.logics should return cooldown as number')
    os.exit(1)
end

print('TEST PASS: zeal.logics returns success and cooldown (', cooldown, ')')

-- cleanup
package.loaded['utility'] = nil
_G.cast_spell = nil
_G.get_time_since_inject = nil
os.exit(0)
