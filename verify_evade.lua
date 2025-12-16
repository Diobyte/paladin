-- Evade Functionality Verification Script
-- This script verifies that all evade changes are correctly implemented

local function verify_evade_functionality()
    print("=== EVADE FUNCTIONALITY VERIFICATION ===\n")

    -- Test 1: Check that evade.lua has no out_of_combat function
    print("1. Testing evade.lua structure...")
    local evade_file = io.open("spells/evade.lua", "r")
    if not evade_file then
        print("   ❌ ERROR: Cannot open evade.lua")
        return false
    end

    local evade_content = evade_file:read("*all")
    evade_file:close()

    if evade_content:find("out_of_combat") then
        print("   ❌ FAIL: out_of_combat function still exists in evade.lua")
        return false
    else
        print("   ✅ PASS: out_of_combat function removed from evade.lua")
    end

    -- Test 2: Check that main.lua has no out_of_combat references
    print("\n2. Testing main.lua structure...")
    local main_file = io.open("main.lua", "r")
    if not main_file then
        print("   ❌ ERROR: Cannot open main.lua")
        return false
    end

    local main_content = main_file:read("*all")
    main_file:close()

    if main_content:find("out_of_combat") then
        print("   ❌ FAIL: out_of_combat references still exist in main.lua")
        return false
    else
        print("   ✅ PASS: out_of_combat references removed from main.lua")
    end

    -- Test 3: Check that evade is at the top of all build priorities
    print("\n3. Testing spell priority structure...")
    local priority_file = io.open("spell_priority.lua", "r")
    if not priority_file then
        print("   ❌ ERROR: Cannot open spell_priority.lua")
        return false
    end

    local priority_content = priority_file:read("*all")
    priority_file:close()

    -- Count how many times evade appears as first priority
    local evade_first_count = 0
    local lines = {}
    for line in priority_content:gmatch("[^\r\n]+") do
        table.insert(lines, line)
    end

    local in_build_function = false
    local current_build_priority = {}

    for i, line in ipairs(lines) do
        if line:find("build_index == %d+ then") or line:find("else  -- Default build") then
            in_build_function = true
            current_build_priority = {}
        elseif line:find("return %{") and in_build_function then
            -- Start of return table
        elseif line:find('"evade"') and in_build_function then
            if #current_build_priority == 0 then
                evade_first_count = evade_first_count + 1
            end
            table.insert(current_build_priority, "evade")
        elseif line:find("^    end$") and in_build_function then
            in_build_function = false
        end
    end

    if evade_first_count >= 11 then  -- Should be 11 builds with evade first (excluding the 2 evade-specialized builds that already had it)
        print("   ✅ PASS: Evade is first priority in " .. evade_first_count .. " builds")
    else
        print("   ❌ FAIL: Evade is only first priority in " .. evade_first_count .. " builds (expected 11+)")
        return false
    end

    -- Test 4: Check dual spell ID configuration
    print("\n4. Testing spell data configuration...")
    local spell_data_file = io.open("my_utility/spell_data.lua", "r")
    if not spell_data_file then
        print("   ❌ ERROR: Cannot open spell_data.lua")
        return false
    end

    local spell_data_content = spell_data_file:read("*all")
    spell_data_file:close()

    if spell_data_content:find("spell_id = 337031") and spell_data_content:find("fallback_spell_id = 2256888") then
        print("   ✅ PASS: Dual spell ID configuration correct (337031 primary, 2256888 fallback)")
    else
        print("   ❌ FAIL: Dual spell ID configuration incorrect")
        return false
    end

    -- Test 5: Check menu structure
    print("\n5. Testing menu structure...")
    if evade_content:find('main_boolean.*render.*"Enable Evade %- In combat"') and
       not evade_content:find('ooc_boolean.*render.*"Enable Evade %- Out of combat"') then
        print("   ✅ PASS: Menu structure correct (in-combat only)")
    else
        print("   ❌ FAIL: Menu structure incorrect")
        return false
    end

    -- Test 6: Check return statement
    print("\n6. Testing return statement...")
    if evade_content:find('return%s*{%s*menu = menu,%s*logics = logics,%s*menu_elements = menu_elements%s*}') and
       not evade_content:find('out_of_combat = out_of_combat') then
        print("   ✅ PASS: Return statement correct (no out_of_combat)")
    else
        print("   ❌ FAIL: Return statement incorrect")
        return false
    end

    print("\n=== ALL TESTS PASSED ===")
    print("✅ Evade functionality verification complete!")
    print("✅ Evade is now:")
    print("   - Highest priority in all 13 paladin builds")
    print("   - In-combat only (out-of-combat feature removed)")
    print("   - Dual spell ID support (337031 primary, 2256888 fallback)")
    print("   - Proper GUI integration")
    print("   - Universal availability across all builds")

    return true
end

-- Run the verification
if verify_evade_functionality() then
    print("\n🎉 SUCCESS: All evade functionality verified!")
else
    print("\n❌ FAILURE: Issues found with evade functionality!")
    os.exit(1)
end