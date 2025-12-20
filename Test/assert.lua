local M = {}

function M.assert_true(cond, msg)
    if not cond then
        error("ASSERT TRUE FAILED: " .. (msg or ""))
    end
end

function M.assert_false(cond, msg)
    if cond then
        error("ASSERT FALSE FAILED: " .. (msg or ""))
    end
end

function M.assert_equal(expected, actual, msg)
    if expected ~= actual then
        error(string.format("ASSERT EQUAL FAILED: expected=%s actual=%s %s", tostring(expected), tostring(actual),
            msg or ""))
    end
end

function M.fail(msg)
    error("FAIL: " .. (msg or ""))
end

return M
