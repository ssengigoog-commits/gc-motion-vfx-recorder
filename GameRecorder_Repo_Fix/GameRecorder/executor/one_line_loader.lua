local function describeError(value)
    local message = tostring(value)
    local traceback = type(debug) == 'table' and debug.traceback
    if type(traceback) == 'function' then
        local ok, result = pcall(traceback, message, 2)
        if ok then return result end
    end
    return message
end
local function start()
    local base = 'https://raw.githubusercontent.com/ssengigoog-commits/gc-motion-vfx-recorder/main/'
    local path = 'dist/GC_MotionVFX_Baker_v7_0_2.luau'
    if type(loadstring) ~= 'function' then error('[GC] loadstring unavailable in this environment', 0) end
    local failures = {}
    for _, prefix in ipairs({'', 'GameRecorder/', 'gc-motion-vfx-recorder/'}) do
        local url = base .. prefix .. path
        local ok, source = pcall(function() return game:HttpGet(url) end)
        if ok and type(source) == 'string' and source:find("Core.RECORDER_VERSION='7.0.2'", 1, true) then
            local compiled, chunk, reason = pcall(loadstring, source)
            if not compiled then error('[GC] Compile failed: ' .. tostring(chunk), 0) end
            if type(chunk) ~= 'function' then error('[GC] Compile failed: ' .. tostring(reason), 0) end
            local ran, err = xpcall(chunk, describeError)
            if not ran then error('[GC] Recorder startup failed: ' .. tostring(err), 0) end
            print('[GC] Recorder v7.0.2 loaded from ' .. url)
            return
        end
        failures[#failures + 1] = url .. ': ' .. (ok and 'unexpected response or wrong version' or tostring(source))
    end
    error('[GC] Download failed:\n' .. table.concat(failures, '\n'), 0)
end
local ok, err = pcall(start)
if not ok then warn(tostring(err)) end
