-- Logger utility for Paladin plugin
local logger = {}

-- Logger state
local log_file = nil
local is_initialized = false

-- Initialize the logger with a timestamped filename
function logger.init()
    if is_initialized then
        return true
    end

    -- Create filename with timestamp
    local timestamp = os.date("%Y%m%d_%H%M%S")
    local filename = "paladin_debug_" .. timestamp .. ".txt"

    -- Try to create in a more accessible location first
    local accessible_locations = {
        "C:\\temp\\" .. filename,
        "C:\\Users\\Public\\" .. filename,
        filename -- fallback to current directory
    }

    -- Try to open the file for writing in accessible locations
    for _, location in ipairs(accessible_locations) do
        log_file = io.open(location, "w")
        if log_file then
            is_initialized = true
            log_file:write("=== Paladin Plugin Debug Log Started ===\n")
            log_file:write("Location: " .. location .. "\n")
            log_file:write("Timestamp: " .. timestamp .. "\n")
            break
        end
    end

    if not is_initialized then
        console.print("Failed to initialize logger - could not open file")
    end

    return is_initialized
end

-- Check if logger is ready
function logger.is_ready()
    return is_initialized and log_file ~= nil
end

-- Log a message
function logger.log(message)
    if not logger.is_ready() then
        return
    end

    local timestamp = os.date("%H:%M:%S")
    local log_entry = string.format("[%s] %s\n", timestamp, message)
    log_file:write(log_entry)
    log_file:flush()
end

-- Close the logger
function logger.close()
    if log_file then
        log_file:close()
        log_file = nil
        is_initialized = false
    end
end

return logger
