local my_utility = require('my_utility/my_utility')

-- Stub console.print to detect calls
local called = false
console = { print = function(...) called = true end }
_G.console = console

-- By default debug printing should be OFF
my_utility.set_debug_enabled(false)
my_utility.debug_print("should not print")
if called then
    print('TEST FAIL: debug_print should not call console.print by default')
    os.exit(1)
end
print('TEST PASS: debug_print does not call console.print when disabled')

-- Enable debug printing and verify it calls console.print
called = false
my_utility.set_debug_enabled(true)
my_utility.debug_print("should print")
if not called then
    print('TEST FAIL: debug_print did not call console.print when enabled')
    os.exit(2)
end
print('TEST PASS: debug_print called console.print when enabled')

-- Reset debug flag to default for other tests
my_utility.set_debug_enabled(false)
os.exit(0)
