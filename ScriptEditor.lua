local function DebugScriptAt(o)
    if typeof(o) ~= "Instance" then return "Need Instance" end
    local c = o.ClassName
    if c ~= "LocalScript" and c ~= "Script" and c ~= "ModuleScript" then return "bad class: " .. c end

    if not getsenv then return "no getsenv" end

    local env = getsenv(o)
    if type(env) ~= "table" then
        if c == "ModuleScript" then
            local ok, m = pcall(require, o)
            if ok then
                if type(m) == "function" then
                    env = getfenv(m)
                elseif type(m) == "table" then
                    env = m
                end
            end
        end
        if type(env) ~= "table" then return "env not table" end
    end

    local scriptName = o.Name
    local mainFunc = getscriptfunction and getscriptfunction(o)
    local scriptSource = mainFunc and pcall(function() return debug.getinfo(mainFunc).source end) and debug.getinfo(mainFunc).source or "unknown"

    local path
    if not o:IsDescendantOf(game) then
        local ancestors = {}
        local current = o
        while current do
            table.insert(ancestors, 1, current.Name)
            current = current.Parent
        end
        if ancestors[1] == "Dex Internal Storage" then
            table.remove(ancestors, 1)
        end
        if ancestors[1] == "Nil Instances" then
            table.remove(ancestors, 1)
        end

        if #ancestors > 0 then
            local pathParts = {"getnilinstances()"}
            for i = 1, #ancestors do
                local name = ancestors[i]
                if name:match("^[%a_][%w_]*$") then
                    table.insert(pathParts, "." .. name)
                else
                    local escapedName = name:gsub('"', '\\"')
                    table.insert(pathParts, "[\"" .. escapedName .. "\"]")
                end
            end
            path = table.concat(pathParts, "")
        else
            path = "getnilinstances()"
        end
    else
        local ancestors = {}
        local current = o
        while current.Parent ~= game do
            table.insert(ancestors, 1, current.Name)
            current = current.Parent
        end
            
        local ServiceName = current.ClassName
            
        local pathParts = {string.format("game:GetService(\"%s\")", ServiceName)}
        for i = 1, #ancestors do
            local name = ancestors[i]
            if name:match("^[%a_][%w_]*$") then
                table.insert(pathParts, "." .. name)
            else
                local escapedName = name:gsub('"', '\\"')
                table.insert(pathParts, "[\"" .. escapedName .. "\"]")
            end
        end
            
        path = table.concat(pathParts, "")
    end

    local function tableToString(t, depth)
        if depth > 3 then return "{...}" end
        if type(t) ~= "table" then return tostring(t) end
        local str = "{"
        local first = true
        for k, v in pairs(t) do
            if not first then str = str .. ", " end
            str = str .. tostring(k) .. "=" .. tableToString(v, depth + 1)
            first = false
        end
        return str .. "}"
    end

    local function getUpvalues(fn)
        local ups = {}
        if not debug.getupvalue then return ups end
        local i = 1
        while true do
            local success, name, val = pcall(debug.getupvalue, fn, i)
            if not success or not name then break end
            local valStr = type(val) == "table" and tableToString(val, 0) or tostring(val)
            table.insert(ups, ("%s=%s"):format(tostring(name), valStr))
            i = i + 1
        end
        return ups
    end

    local function getConstants(fn)
        local cons = {}
        if not debug.getconstant then return cons end
        local i = 1
        while true do
            local success, val = pcall(debug.getconstant, fn, i)
            if not success or val == nil then break end
            local valStr = type(val) == "table" and tableToString(val, 0) or tostring(val)
            table.insert(cons, valStr)
            i = i + 1
        end
        return cons
    end

    local function formatSource(src)
        if src and src:sub(1,1) == "=" then
            return src:sub(2)
        end
        return src or "N/A"
    end

    local function collectNestedFunctions(fn)
        local info = debug.getinfo(fn)
        local hash = getfunctionhash and getfunctionhash(fn) or "N/A"
        local entry = {
            name = tostring(fn) .. " [" .. (info and info.name or "Anonymous Function") .. "]",
            info = info,
            hash = hash,
            source = formatSource(info and info.source),
            upvalues = getUpvalues(fn),
            constants = getConstants(fn),
            children = {}
        }
        local protos = getprotos and getprotos(fn)
        if protos then
            for idx = 1, #protos do
                local closures = getproto and getproto(fn, idx, true)
                if closures then
                    for _, closure in ipairs(closures) do
                        local childEntry = collectNestedFunctions(closure)
                        table.insert(entry.children, childEntry)
                    end
                end
            end
        end
        return entry
    end

    local function printFunctionHierarchy(entry, out, indent)
        table.insert(out, indent .. entry.name .. " (Source: " .. entry.source .. ", Hash: " .. entry.hash .. ")")
        if entry.info then
            table.insert(out, indent .. "  Params: " .. (entry.info.nparams or 0) .. ", Vararg: " .. tostring(entry.info.isvararg) .. ", Lines: " .. (entry.info.linedefined or 0) .. "-" .. (entry.info.lastlinedefined or 0))
        end
        if #entry.upvalues > 0 then
            table.insert(out, indent .. "  UPVALUES: " .. table.concat(entry.upvalues, ", "))
        end
        if #entry.constants > 0 then
            table.insert(out, indent .. "  CONSTANTS: " .. table.concat(entry.constants, ", "))
        end
        if #entry.children > 0 then
            table.insert(out, indent .. "  CHILDREN:")
            for _, child in ipairs(entry.children) do
                printFunctionHierarchy(child, out, indent .. "    ")
            end
        end
    end

    local envTables = {}
    for k, v in pairs(env) do
        if type(v) == "table" then
            local size = 0
            for _ in pairs(v) do size = size + 1 end
            envTables[tostring(k)] = size
        end
    end

    local gcFunctions = {}
    local gc = getgc(true)
    for _, obj in ipairs(gc) do
        if type(obj) == "function" then
            local fenv = getfenv(obj)
            if fenv and fenv.script == o then
                local rootEntry = collectNestedFunctions(obj)
                table.insert(gcFunctions, rootEntry)
            end
        end
    end

    local scriptThreads = {}
    local mainThread = getscriptthread and getscriptthread(o)
    if mainThread then
        local threadInfo = debug.getinfo(mainThread)
        table.insert(scriptThreads, {
            name = "Main Thread",
            thread = mainThread,
            info = threadInfo,
            status = coroutine.status(mainThread)
        })
    end
    for _, v in ipairs(getgc(true)) do
        if typeof(v) == "thread" and v ~= mainThread then
            local threadInfo = debug.getinfo(v)
            if threadInfo and threadInfo.source and threadInfo.source:find(scriptName) then
                table.insert(scriptThreads, {
                    name = threadInfo.name or "Unnamed Thread",
                    thread = v,
                    info = threadInfo,
                    status = coroutine.status(v)
                })
            end
        end
    end

    local out = {}
    table.insert(out, "=== SCRIPT DEBUG REPORT ===")
    table.insert(out, "SCRIPT PATH: " .. path)
    table.insert(out, "SCRIPT CLASS: " .. c)
    table.insert(out, "SCRIPT SOURCE: " .. formatSource(scriptSource))
    table.insert(out, "")

    local envTableList = {}
    for n, size in pairs(envTables) do
        table.insert(envTableList, n .. "[" .. size .. "]")
    end
    if #envTableList > 0 then
        table.insert(out, "ENVIRONMENT TABLES: " .. table.concat(envTableList, ", "))
    else
        table.insert(out, "No tables in environment.")
    end
    table.insert(out, "")

    if #gcFunctions > 0 then
        table.insert(out, "--- GC FUNCTIONS (" .. #gcFunctions .. ") ---")
        for i, rootEntry in ipairs(gcFunctions) do
            printFunctionHierarchy(rootEntry, out, "  " .. i .. ". ")
            table.insert(out, "")
        end
    else
        table.insert(out, "No functions in GC associated with script.")
    end
    table.insert(out, "")

    if #scriptThreads > 0 then
        table.insert(out, "--- SCRIPT THREADS (" .. #scriptThreads .. ") ---")
        for i, thr in ipairs(scriptThreads) do
            table.insert(out, string.format("THREAD #%d: %s (Status: %s)", i, thr.name, thr.status or "N/A"))
            if thr.info then
                table.insert(out, string.format("  Source: %s, Lines: %d-%d", formatSource(thr.info.source), thr.info.linedefined or 0, thr.info.lastlinedefined or 0))
            end
            table.insert(out, "")
        end
    else
        table.insert(out, "No threads associated with script.")
    end

    return table.concat(out, "\n")
end
