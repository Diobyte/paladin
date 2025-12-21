local lua_tests = {
    'Test/test_try_maintain_buff.lua',
    'Test/test_my_utility_buff_and_cast.lua',
    'Test/test_try_cast_spell_cdr.lua',
    'Test/test_consecration_return_cooldown.lua',
    'Test/test_zeal_return_cooldown.lua',
    'Test/test_evade_return_cooldown.lua',
    'Test/test_fanaticism_return_cooldown.lua',
    'Test/test_defiance_return_cooldown.lua',
    'Test/test_holy_light_aura_return_cooldown.lua',
    'Test/test_shield_bash_return_cooldown.lua',
    'Test/test_blessed_shield_return_cooldown.lua',
    'Test/test_purify_return_cooldown.lua',
    'Test/test_spell_priority_items.lua',
    'Test/test_spell_priority_dynamic.lua',
    'Test/test_range_and_melee.lua',
    'Test/test_delay_and_cooldown.lua',
    'Test/test_requires_shield.lua',
    'Test/test_target_scoring.lua',
    'Test/test_is_target_within_angle.lua',
    'Test/test_target_selector_tiebreak.lua',
    'Test/test_target_selector_custom_weights.lua',
    'Test/test_delay_selection.lua',
    'Test/test_evade_out_of_combat.lua'
}

local total = #lua_tests
local passed = 0
local failed = 0

for _, t in ipairs(lua_tests) do
    io.write('Running ' .. t .. ' ... ')
    local ok = os.execute('lua ' .. t)
    if ok then
        print('PASS')
        passed = passed + 1
    else
        print('FAIL')
        failed = failed + 1
    end
end

print('---')
print(string.format('Lua tests: Total: %d  Passed: %d  Failed: %d', total, passed, failed))

-- Run busted specs if available
if os.execute("command -v busted >/dev/null 2>&1") then
    print('\nRunning busted specs...')
    local ok = os.execute('busted -v Test')
    if not ok then
        print('Some busted specs failed')
        os.exit(1)
    else
        print('All busted specs passed')
    end
else
    print('\nNote: busted is not installed; skipping spec tests (you can install busted via luarocks)')
end

if failed > 0 then
    os.exit(1)
end
os.exit(0)
