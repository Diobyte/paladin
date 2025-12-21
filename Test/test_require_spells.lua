local spells = {
    'spells/zenith.lua',
    'spells/zeal.lua',
    'spells/spear_of_the_heavens.lua',
    'spells/shield_charge.lua',
    'spells/shield_bash.lua',
    'spells/rally.lua',
    'spells/purify.lua',
    'spells/paladin_evade.lua',
    'spells/holy_light_aura.lua',
    'spells/holy_bolt.lua',
    'spells/heavens_fury.lua',
    'spells/fortress.lua',
    'spells/fanaticism_aura.lua',
    'spells/falling_star.lua',
    'spells/evade.lua',
    'spells/divine_lance.lua',
    'spells/defiance_aura.lua',
    'spells/consecration.lua',
    'spells/condemn.lua',
    'spells/clash.lua',
    'spells/brandish.lua',
    'spells/blessed_shield.lua',
    'spells/blessed_hammer.lua',
    'spells/arbiter_of_justice.lua',
    'spells/aegis.lua',
    'spells/advance.lua'
}

local failed = 0
for _, p in ipairs(spells) do
    io.write('Executing ' .. p .. ' ... ')
    local ok, err = pcall(dofile, p)
    if ok then
        print('OK')
    else
        print('FAIL')
        print('  error:', tostring(err))
        failed = failed + 1
    end
end

if failed == 0 then
    print('TEST PASS: All spells required without runtime errors')
    os.exit(0)
else
    print('TEST FAIL: ' .. failed .. ' spells failed to require')
    os.exit(1)
end
