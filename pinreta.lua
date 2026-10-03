    script_key="KEY-MTELN-CY3BA-5LRSC-CTBR4-2K9DP"
    local Workspace = game:GetService('Workspace')
    local ReplicatedStorage = game:GetService('ReplicatedStorage')
    local Players = game:GetService('Players')
    local RunService = game:GetService('RunService')

    local type_custom = typeof
    if not LPH_OBFUSCATED then
        LPH_JIT = function(...)
            return ...;
        end;
        LPH_JIT_MAX = function(...)
            return ...;
        end;
        LPH_NO_VIRTUALIZE = function(...)
            return ...;
        end;
        LPH_NO_UPVALUES = function(f)
            return (function(...)
                return f(...);
            end);
        end;
        LPH_ENCSTR = function(...)
            return ...;
        end;
        LPH_ENCNUM = function(...)
            return ...;
        end;
        LPH_ENCFUNC = function(func, key1, key2)
            if key1 ~= key2 then return print("LPH_ENCFUNC mismatch") end
            return func
        end
        LPH_CRASH = function()
            return print(debug.traceback());
        end;
        SWG_DiscordUser = "swim"
        SWG_DiscordID = 1337
        SWG_Private = true
        SWG_Dev = false
        SWG_Version = "dev"
        SWG_Title = 'GHOST_HOOK %s - %s'
        SWG_ShortName = 'dev'
        SWG_FullName = 'GHOST_HOOK dev build'
        SWG_FFA = false
    end;
    local workspace = cloneref(Workspace)
    local Players = cloneref(Players)
    local RunService = cloneref(RunService)
    local Lighting = cloneref(game:GetService("Lighting"))
    local UserInputService = cloneref(game:GetService("UserInputService"))
    local HttpService = cloneref(game:GetService("HttpService"))
    local GuiInset = cloneref(game:GetService("GuiService")):GetGuiInset()
    local LocalPlayer = Players.LocalPlayer
    local Mouse = LocalPlayer:GetMouse()
    local Camera = workspace.CurrentCamera
    local cheat

    local _CFramenew = CFrame.new
    local _Vector2new = Vector2.new
    local _Vector3new = Vector3.new
    local _IsDescendantOf = game.IsDescendantOf
    local _FindFirstChild = game.FindFirstChild
    local _FindFirstChildOfClass = game.FindFirstChildOfClass
    local _Raycast = workspace.Raycast
    local _IsKeyDown = UserInputService.IsKeyDown
    local _WorldToViewportPoint = Camera.WorldToViewportPoint
    local _Vector3zeromin = Vector3.zero.Min
    local _Vector2zeromin = Vector2.zero.Min
    local _Vector3zeromax = Vector3.zero.Max

    -- Neutralise a game-side keybind crash. Mouse buttons do not live in Enum.KeyCode --
    -- they are input SIGNALS (Enum.UserInputType). Several of the game's own scripts
    -- (FunctionLibraryExtension:156 GetEstimatedCameraPosition, CharacterController:1005,
    -- CameraSensitivity:10, HealthLocal:57, GyroAimController:176, FirstPersonBody:265,
    -- VknCharacterSounds:425, ...) resolve the stored aim/ads key name against
    -- Enum.KeyCode, so when the stored bind is a mouse button the raw enum index THROWS:
    --   "MouseButton2 is not a valid member of Enum.KeyCode"
    -- That error fired every frame from ~15 scripts, jamming the game's input handlers
    -- (inventory would not open, camera froze, character visibility glitched).
    -- We route mouse-button names to a valid, never-physically-produced KeyCode, so the
    -- lookups return a value instead of throwing and the storm stops at the source.
    do
        -- Cached BEFORE hooking, so the hook body itself never performs an enum lookup.
        local KEYCODE_ENUM = Enum.KeyCode
        local mouse_names = {
            MouseButton1 = true, MouseButton2 = true, MouseButton3 = true,
            MouseButton4 = true, MouseButton5 = true, MouseWheel = true,
        }
        local orig_index = nil
        local recursing = false
        -- A valid KeyCode that no keyboard/mouse input ever reports, so IsKeyDown(...)
        -- reads "not held" and input.KeyCode comparisons never falsely match.
        local substitute = KEYCODE_ENUM.ButtonA

        local function safe_index(enum_t, key)
            -- Scope guard is ESSENTIAL: every Roblox enum shares ONE __index, so without it
            -- the substitution also fired for Enum.UserInputType and handed a KeyCode to
            -- IsMouseButtonPressed -> "Unable to cast KeyCode to UserInputType".
            if enum_t == KEYCODE_ENUM and not recursing and type(key) == "string" and mouse_names[key] then
                return substitute
            end
            -- Delegate ONLY to the captured original. Never call a METHOD on the enum in
            -- here: GetEnumItems and friends are reached through this same hooked __index,
            -- so calling one recurses until every enum lookup in the game breaks.
            if type(orig_index) ~= "function" then
                return nil
            end
            recursing = true
            local ok, res = pcall(orig_index, enum_t, key)
            recursing = false
            if ok then
                return res
            end
            -- preserve the genuine "not a valid member" error for every other name
            error(res, 0)
        end

        -- Reuse the TRUE original across re-executions. hookmetamethod returns whatever
        -- __index is currently installed, so re-running the script would otherwise chain
        -- our own hook onto itself, one layer deeper on every execute.
        local genv = (getgenv and getgenv()) or _G
        local store = type(genv) == "table" and rawget(genv, "__GHOST_ENUM_KEYCODE") or nil
        local hooked = false

        if type(store) == "table" and type(store.orig) == "function" then
            orig_index = store.orig
            hooked = pcall(function()
                hookmetamethod(KEYCODE_ENUM, "__index", safe_index)
            end)
        else
            -- hookmetamethod copes with the READ-ONLY enum metatable. Writing
            -- getrawmetatable(Enum.KeyCode).__index directly throws
            -- "attempt to modify a readonly table".
            local ok_hook, orig = pcall(function()
                return hookmetamethod(KEYCODE_ENUM, "__index", safe_index)
            end)
            if ok_hook and type(orig) == "function" then
                orig_index = orig
                hooked = true
                if type(genv) == "table" then
                    pcall(function() rawset(genv, "__GHOST_ENUM_KEYCODE", { orig = orig }) end)
                end
            end
        end

        if not hooked then
            -- Fallback: unprotect the metatable when the executor exposes setreadonly.
            local ok_mt, keycode_mt = pcall(function() return getrawmetatable(Enum.KeyCode) end)
            if ok_mt and type(keycode_mt) == "table" then
                pcall(function()
                    if isreadonly(keycode_mt) then
                        setreadonly(keycode_mt, false)
                    end
                end)
                if not orig_index then
                    orig_index = rawget(keycode_mt, "__index")
                end
                local ok_set = pcall(function()
                    keycode_mt.__index = safe_index
                end)
                pcall(function() setreadonly(keycode_mt, true) end)
                hooked = ok_set
            end
        end
    end
    local _Vector2zeromax = Vector2.zero.Max
    local _IsA = game.IsA
    local tablecreate = table.create
    local mathfloor = math.floor
    local mathround = math.round
    local tostring = tostring
    local unpack = unpack
    local getupvalues = debug.getupvalues
    local getupvalue = debug.getupvalue
    local setupvalue = debug.setupvalue
    local getconstants = debug.getconstants
    local getconstant = debug.getconstant
    local setconstant = debug.setconstant
    local getstack = debug.getstack
    local setstack = debug.setstack
    local getinfo = debug.getinfo
    local rawget = rawget

    -- Scoped in a `do...end` block so its many one-time bootstrap locals
    -- (key validation, hookfile helpers, UI library loader) free their
    -- registers once the UI is built, instead of staying live for the rest
    -- of the script and exhausting Lua's 200-local-per-function limit.
    local ui
    local tipanel_settings
    do
    local function ghostKeyNotify(title, text, duration)
        pcall(function()
            game:GetService("StarterGui"):SetCore("SendNotification", {
                Title = tostring(title or "GHOST_HOOK Key"),
                Text = tostring(text or ""),
                Duration = tonumber(duration) or 3,
            })
        end)
    end

    local function ghostKeySave(value, path)
        if not writefile or type(path) ~= "string" then return false end
        local ok = pcall(function()
            writefile(path, tostring(value))
        end)
        return ok
    end

    local function ghostKeyLoad(path)
        if not isfile or not readfile or type(path) ~= "string" or not isfile(path) then
            return nil
        end

        local ok, value = pcall(readfile, path)
        if ok then
            return value
        end
        return nil
    end

    local KEY_SERVER_VALIDATE_URL = "https://web-eight-mu-4k76n8qoag.vercel.app/api/validate-key"

    local function getGhostProvidedKey()
        local env = getgenv and getgenv() or nil
        return (env and (env.Key or env.script_key))
            or rawget(_G, "script_key")
            or (shared and shared.script_key)
            or rawget(_G, "Key")
            or script_key
    end

    local function getGhostDeviceId()
        if syn and syn.crypt and syn.crypt.hwid then
            local ok, value = pcall(syn.crypt.hwid)
            if ok and value then
                return tostring(value)
            end
        end

        local clientId = nil
        pcall(function()
            clientId = game:GetService("RbxAnalyticsService"):GetClientId()
        end)

        local executor = "executor"
        pcall(function()
            if identifyexecutor then
                executor = tostring(identifyexecutor())
            elseif getexecutorname then
                executor = tostring(getexecutorname())
            end
        end)

        if clientId and tostring(clientId) ~= "" then
            return executor .. "-" .. tostring(clientId)
        end

        local savedId = ghostKeyLoad("GhostKeyDevice")
        if savedId and tostring(savedId) ~= "" then
            return tostring(savedId)
        end

        savedId = executor .. "-" .. tostring(math.random(100000, 999999)) .. "-" .. tostring(os.time())
        ghostKeySave(savedId, "GhostKeyDevice")
        return savedId
    end

    local function ghostHttpRequest(requestData)
        local requester = (syn and syn.request) or http_request or request or (http and http.request)
        if requester then
            return requester(requestData)
        end

        return HttpService:RequestAsync(requestData)
    end

    local function validateGhostKey()
        local providedKey = getGhostProvidedKey()
        if not providedKey or tostring(providedKey) == "" then
            return false, "Missing key"
        end

        providedKey = tostring(providedKey)
        local env = getgenv and getgenv() or nil
        if env then
            env.Key = providedKey
        end

        local deviceId = getGhostDeviceId()
        local body = HttpService:JSONEncode({
            key = providedKey,
            deviceId = deviceId,
            hwid = deviceId,
            userId = LocalPlayer and tostring(LocalPlayer.UserId) or nil,
        })

        for attempt = 1, 3 do
            local ok, response = pcall(ghostHttpRequest, {
                Url = KEY_SERVER_VALIDATE_URL,
                Method = "POST",
                Headers = {
                    ["Content-Type"] = "application/json",
                },
                Body = body,
            })

            if ok and response then
                local responseBody = response.Body or response.body or ""
                local decodedOk, decoded = pcall(function()
                    return HttpService:JSONDecode(responseBody)
                end)

                if decodedOk and decoded then
                    if decoded.success == true then
                        return true, decoded.message or "Key validated", decoded
                    end

                    return false, decoded.message or decoded.error or "Key validation failed"
                end

                return false, "Invalid response from key server"
            end

            if attempt < 3 then
                task.wait(1)
            end
        end

        return false, "Could not reach key server"
    end

    local ghostKeyOk, ghostKeyMessage, ghostKeyInfo = validateGhostKey()
    if not ghostKeyOk then
        ghostKeyNotify("GHOST_HOOK Key", tostring(ghostKeyMessage), 5)
        return
    end

    ghostKeyNotify("GHOST_HOOK Key", tostring(ghostKeyMessage), 2.5)

    local function ghostParseIsoUnix(value)
        if type(value) ~= "string" or value == "" then
            return nil
        end

        if DateTime and DateTime.fromIsoDate then
            local ok, parsed = pcall(DateTime.fromIsoDate, value)
            if ok and parsed then
                return parsed.UnixTimestamp
            end
        end

        local year, month, day, hour, minute, second = value:match("^(%d+)%-(%d+)%-(%d+)T(%d+):(%d+):(%d+)")
        if not year then
            return nil
        end

        return os.time({
            year = tonumber(year),
            month = tonumber(month),
            day = tonumber(day),
            hour = tonumber(hour),
            min = tonumber(minute),
            sec = tonumber(second),
        })
    end

    local ghostKeyExpiresAtUnix = ghostKeyInfo and ghostParseIsoUnix(ghostKeyInfo.expiresAt or ghostKeyInfo.expires_at) or nil
    local ghostKeyExpiresAfterHours = ghostKeyInfo and tonumber(ghostKeyInfo.expiresAfterHours or ghostKeyInfo.expires_after_hours) or nil
    local ghostKeyServerOffset = 0
    do
        local serverUnix = ghostKeyInfo and ghostParseIsoUnix(ghostKeyInfo.serverTime or ghostKeyInfo.server_time) or nil
        if serverUnix then
            ghostKeyServerOffset = serverUnix - os.time()
        end
    end

    local function ghostFormatKeyDuration(hours)
        hours = tonumber(hours)
        if not hours or hours <= 0 then
            return "Lifetime"
        end

        if hours < 1 then
            return tostring(math.ceil(hours * 60)) .. "m"
        end
        if hours < 48 then
            return tostring(math.ceil(hours)) .. "h"
        end
        return tostring(math.ceil(hours / 24)) .. "d"
    end

    local function ghostFormatKeyTimeLeft()
        if not ghostKeyExpiresAtUnix then
            return "Active " .. ghostFormatKeyDuration(ghostKeyExpiresAfterHours)
        end

        local secondsLeft = ghostKeyExpiresAtUnix - (os.time() + ghostKeyServerOffset)
        if secondsLeft <= 0 then
            return "Expired"
        end

        local minutesLeft = math.ceil(secondsLeft / 60)
        local hoursLeft = math.ceil(secondsLeft / 3600)
        local daysLeft = math.ceil(secondsLeft / 86400)

        if minutesLeft < 60 then
            return "Active " .. tostring(minutesLeft) .. "m"
        end
        if hoursLeft < 48 then
            return "Active " .. tostring(hoursLeft) .. "h"
        end
        return "Active " .. tostring(daysLeft) .. "d"
    end

    local function ghostGetKeyTimerText()
        local status = ghostFormatKeyTimeLeft()
        if status == "" or status == "Active" then
            return ""
        end
        return status:gsub("^Active%s*", "")
    end

    local function ghostFindMenuBase()
        if cheat and cheat.instances then
            for instance in pairs(cheat.instances) do
                if typeof(instance) == "Instance" and instance.Parent then
                    if instance.Name == "Base" and instance:IsA("GuiObject") then
                        return instance
                    end

                    local base = instance:FindFirstChild("Base", true)
                    if base and base:IsA("GuiObject") then
                        return base
                    end
                end
            end
        end

        local roots = {}
        pcall(function()
            table.insert(roots, game:GetService("CoreGui"))
        end)
        pcall(function()
            if LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui") then
                table.insert(roots, LocalPlayer:FindFirstChildOfClass("PlayerGui"))
            end
        end)

        for _, root in ipairs(roots) do
            local base = root and root:FindFirstChild("Base", true)
            if base and base:IsA("GuiObject") then
                return base
            end
        end
    end

    local function ghostCreateKeyStatusOverlay(timerText, expired)
        timerText = tostring(timerText or "")

        local base = ghostFindMenuBase()
        if not base then
            return false
        end

        local existing = base:FindFirstChild("GhostHookKeyStatus", true)
        if existing then
            existing:Destroy()
        end

        local sidebar = base:FindFirstChild("Sidebar", true)
        local sidebarGroup = sidebar and sidebar:FindFirstChild("SidebarGroup")
        local userInfo = sidebarGroup and sidebarGroup:FindFirstChild("UserInfo")
        if not userInfo then
            return false
        end

        local STATUS_OVERLAY_INSET = 70
        local frame = cheat.utility.track_instance(Instance.new("Frame"))
        frame.Name = "GhostHookKeyStatus"
        frame.AnchorPoint = Vector2.new(0, 0)
        frame.BackgroundTransparency = 1
        frame.BorderSizePixel = 0
        frame.Position = UDim2.new(0, STATUS_OVERLAY_INSET, 0, 9)
        frame.Size = UDim2.new(1, -STATUS_OVERLAY_INSET - 18, 0, 20)
        frame.ZIndex = 1000
        frame.Parent = userInfo

        local dot = Instance.new("Frame")
        dot.Name = "Dot"
        dot.AnchorPoint = Vector2.new(0, 0.5)
        dot.BackgroundColor3 = expired and Color3.fromRGB(255, 65, 65) or Color3.fromRGB(32, 255, 65)
        dot.BorderSizePixel = 0
        dot.Position = UDim2.new(0, 0, 0.5, 0)
        dot.Size = UDim2.fromOffset(8, 8)
        dot.ZIndex = 1001
        dot.Parent = frame

        local dotCorner = Instance.new("UICorner")
        dotCorner.CornerRadius = UDim.new(1, 0)
        dotCorner.Parent = dot

        local active = Instance.new("TextLabel")
        active.Name = "ActiveText"
        active.BackgroundTransparency = 1
        active.BorderSizePixel = 0
        active.Font = Enum.Font.GothamMedium
        active.Position = UDim2.new(0, 14, 0, 0)
        -- only needs to fit "Active" / "Expired"; the duration sits beside it
        active.Size = UDim2.fromOffset(46, 20)
        active.Text = expired and "Expired" or "Active"
        active.TextColor3 = Color3.fromRGB(255, 255, 255)
        active.TextSize = 14
        active.TextXAlignment = Enum.TextXAlignment.Left
        active.TextYAlignment = Enum.TextYAlignment.Center
        active.TextTruncate = Enum.TextTruncate.AtEnd
        active.ZIndex = 1001
        active.Parent = frame

        local timer = Instance.new("TextLabel")
        timer.Name = "TimerText"
        timer.BackgroundTransparency = 1
        timer.BorderSizePixel = 0
        timer.Font = Enum.Font.GothamMedium
        -- sits immediately after "Active", joined by a dash
        timer.Position = UDim2.new(0, 58, 0, 0)
        timer.Size = UDim2.new(1, -58, 1, 0)
        timer.Text = (expired or timerText == "") and "" or ("- " .. tostring(timerText))
        timer.TextColor3 = Color3.fromRGB(255, 255, 255)
        timer.TextSize = 14
        timer.TextXAlignment = Enum.TextXAlignment.Left
        timer.TextYAlignment = Enum.TextYAlignment.Center
        timer.TextTruncate = Enum.TextTruncate.AtEnd
        timer.ZIndex = 1001
        timer.Parent = frame

        return true
    end

    local function getfile(name)
        local repo = "https://raw.githubusercontent.com/kristerstomasuns-hub/essentials/main/"
        local success, content = pcall(request, {Url = repo..name, Method = "GET"})
        if success then
            if content.StatusCode == 200 then
                return content.Body
            else
                return print("getfile returned error code: " .. tostring(content.StatusCode))
            end
        else
            return print("getfile pcall error: " .. tostring(content))
        end
    end
    local function isGhostHookfile(file)
        return isfile("GHOST_HOOK/new/files/"..file)
    end
    local function readGhostHookfile(file)
        if not isGhostHookfile(file) then return false end
        local success, returns = pcall(readfile, "GHOST_HOOK/new/files/"..file)
        if success then return returns else return print(returns) end
    end
    local function loadGhostHookfile(file)
        if not isGhostHookfile(file) then return false end
        local success, returns = pcall(loadstring, readGhostHookfile(file))
        if success then return returns else return print(returns) end
    end
    local function getGhostHookasset(file)
        if isGhostHookfile(file) then return false end
        local success, returns = pcall(getcustomasset, "GHOST_HOOK/new/files/"..file)
        if success then return returns else return print(returns) end
    end
    do
        if not isfolder("GHOST_HOOK") then makefolder("GHOST_HOOK") end
        if not isfolder("GHOST_HOOK/new") then makefolder("GHOST_HOOK/new") end
        if not isfolder("GHOST_HOOK/new/files") then makefolder("GHOST_HOOK/new/files") end
        local function getfiles(force, list)
            for _, file in list do
                if (force or not force and not isGhostHookfile(file)) then
                    writefile("GHOST_HOOK/new/files/"..file, getfile(file))
                end
            end
        end
        local gotassets = getfile("assets.json")
        if not gotassets then return end
        local assets = HttpService:JSONDecode(gotassets)
        local localassets = readGhostHookfile("assets.json")
        if localassets then
            localassets = HttpService:JSONDecode(localassets)
            if localassets.version ~= assets.version then
                writefile("GHOST_HOOK/new/files/assets.json", gotassets)
                getfiles(true, assets.list)
            end
        else
            writefile("GHOST_HOOK/new/files/assets.json", gotassets)
        end
        getfiles(false, assets.list)
    end
    cheat = {
        -- MUST exist and start true. Every background loop guards on `while cheat.alive`
        -- and spawn_damage_number tears its drawing down on `not cheat.alive`, so with the
        -- field missing (nil) the damage numbers were removed on their very first frame
        -- and Auto Refill Mag / the report display / the weather tracker never ran at all.
        alive = true,
        Library = nil,
        Toggles = nil,
        Options = nil,
        ThemeManager = nil,
        SaveManager = nil,
        connections = {
            heartbeats = {},
            renderstepped = {},
            generic = {}
        },
        drawings = {},
        instances = {},
        hooks = {},
        unloaded = false,
        loading_active = false,
        loading_finished = false,
        ui_ready = false,
        keybind_indicator_enabled = false,
        hitlogs_enabled = false,
        hitlogs_y = 500,
        hitlogs_size = 14,
        hitlogs_font = 2,
        hitlogs_valid_color = Color3.fromRGB(150, 255, 150),
        hitlogs_invalid_color = Color3.fromRGB(255, 150, 150),
        hitlogs = { pending = {}, active = {} }
    }
    tipanel_settings = {
        bgcolor = Color3.fromRGB(15, 15, 15),
        bordercolor = Color3.fromRGB(45, 45, 45),
        accentcolor = Color3.fromRGB(120, 110, 180),
        glowcolor = Color3.fromRGB(120, 110, 180),
        bgtrans = 0.9,
    }
    local function getTerrainDecoration(default)
        local terrain = _FindFirstChildOfClass(workspace, "Terrain")
        if not terrain then return default end

        if gethiddenproperty then
            local ok, value = pcall(gethiddenproperty, terrain, "Decoration")
            if ok and value ~= nil then
                return value
            end
        end

        local ok, value = pcall(function()
            return terrain.Decoration
        end)
        if ok and value ~= nil then
            return value
        end

        return default
    end
    local function setTerrainDecoration(value)
        local terrain = _FindFirstChildOfClass(workspace, "Terrain")
        if not terrain then return false end

        if sethiddenproperty then
            local ok = pcall(sethiddenproperty, terrain, "Decoration", value)
            if ok then
                return true
            end
        end

        local ok = pcall(function()
            terrain.Decoration = value
        end)
        return ok
    end
    cheat.setTerrainDecoration = setTerrainDecoration
    cheat.original_state = {
        Ambient = Lighting.Ambient,
        OutdoorAmbient = Lighting.OutdoorAmbient,
        ClockTime = Lighting.ClockTime,
        GlobalShadows = Lighting.GlobalShadows,
        FieldOfView = Camera.FieldOfView,
        CameraType = Camera.CameraType,
        CameraSubject = Camera.CameraSubject,
        MouseBehavior = UserInputService.MouseBehavior,
        CameraMode = LocalPlayer.CameraMode,
        CameraMinZoomDistance = LocalPlayer.CameraMinZoomDistance,
        CameraMaxZoomDistance = LocalPlayer.CameraMaxZoomDistance,
        TerrainDecoration = getTerrainDecoration(true),
    }
    ui = {}
    cheat.utility = {} do
        cheat.utility.new_heartbeat = function(func)
            local obj = {}
            cheat.connections.heartbeats[func] = func
            function obj:Disconnect()
                if func then
                    cheat.connections.heartbeats[func] = nil
                    func = nil
                end
            end
            return obj
        end
        cheat.utility.new_renderstepped = function(func)
            local obj = {}
            cheat.connections.renderstepped[func] = func
            function obj:Disconnect()
                if func then
                    cheat.connections.renderstepped[func] = nil
                    func = nil
                end
            end
            return obj
        end
        cheat.utility.track_connection = function(connection_object)
            if connection_object then
                cheat.connections.generic[connection_object] = connection_object
            end
            return connection_object
        end
        cheat.utility.track_instance = function(instance)
            if instance then
                cheat.instances[instance] = instance
            end
            return instance
        end
        cheat.utility.safe_destroy = function(object)
            if not object then return end
            pcall(function()
                if typeof(object) == "Instance" then
                    object:Destroy()
                elseif object.Remove then
                    object:Remove()
                elseif object.Destroy then
                    object:Destroy()
                end
            end)
        end
        
        local vischeck_params = RaycastParams.new()
        vischeck_params.FilterType = Enum.RaycastFilterType.Exclude
        vischeck_params.CollisionGroup = "WeaponRay"
        vischeck_params.IgnoreWater = true
        cheat._visibility_cache = cheat._visibility_cache or setmetatable({}, { __mode = "k" })

        cheat.utility.is_visible = function(cframe, target, target_part)
            if not (target and target_part and cframe) then return false end
            if cheat.freecam_enabled and cheat.Toggles.freecam_vis_original and cheat.Toggles.freecam_vis_original.Value then
                local my_char = LocalPlayer.Character
                local my_head = my_char and (my_char:FindFirstChild("Head") or my_char:FindFirstChild("CollisionPilot", true) or my_char:FindFirstChild("Mi24_Prop_M", true))
                if my_head then
                    cframe = my_head.CFrame
                end
            end
            local origin = cframe.p
            local part_pos = target_part.Position
            local cached = cheat._visibility_cache[target_part]
            local now = os.clock()
            if cached
                and cached.target == target
                and (now - cached.t) <= 0.08
                and (cached.origin - origin).Magnitude <= 2
                and (cached.pos - part_pos).Magnitude <= 2 then
                return cached.visible
            end
            local char = LocalPlayer.Character
            if char ~= cheat.utility._last_vis_char then
                cheat.utility._last_vis_char = char
                vischeck_params.FilterDescendantsInstances = { Workspace.NoCollision, Camera, char }
            end
            local castresults = Workspace:Raycast(origin, part_pos - origin, vischeck_params)
            local visible = false
            if not castresults then
                visible = true
            elseif castresults.Instance then
                visible = castresults.Instance == target_part or castresults.Instance:IsDescendantOf(target)
            end
            cheat._visibility_cache[target_part] = {
                t = now,
                target = target,
                origin = origin,
                pos = part_pos,
                visible = visible
            }
            return visible
        end

        cheat.utility.clear_visibility_cache = function()
            for part in pairs(cheat._visibility_cache) do
                cheat._visibility_cache[part] = nil
            end
        end

        cheat.utility.is_visible_uncached = function(cframe, target, target_part)
            if not (target and target_part and cframe) then return false end
            local char = LocalPlayer.Character
            if char ~= cheat.utility._last_vis_char then
                cheat.utility._last_vis_char = char
                vischeck_params.FilterDescendantsInstances = { Workspace.NoCollision, Camera, char }
            end
            local castresults = Workspace:Raycast(cframe.p, target_part.Position - cframe.p, vischeck_params)
            if not castresults then return true end
            if castresults and castresults.Instance then
                if target_part and castresults.Instance == target_part then return true end
                return castresults.Instance:IsDescendantOf(target)
            end
            return false
        end
        
        cheat.utility.spawn_kill_effect = function(pos)
            local part = Instance.new("Part")
            part.Anchored = true
            part.CanCollide = false
            part.Transparency = 1
            part.Position = pos
            part.Parent = workspace.Terrain
            
            local emit = Instance.new("ParticleEmitter")
            emit.Texture = "rbxasset://textures/particles/sparkles_main.dds"
            emit.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 1.5), NumberSequenceKeypoint.new(1, 0)})
            emit.Color = ColorSequence.new(Color3.new(1, 1, 1))
            emit.LightEmission = 1
            emit.LightInfluence = 0
            emit.ZOffset = 1
            emit.Lifetime = NumberRange.new(1, 2)
            emit.Rate = 0
            emit.Speed = NumberRange.new(15, 40)
            emit.SpreadAngle = Vector2.new(360, 360)
            emit.Drag = 2
            emit.Parent = part
            
            local amount = cheat.Options.killeffect_amount and cheat.Options.killeffect_amount.Value or 100
            emit:Emit(amount)
            
            game:GetService("Debris"):AddItem(part, 3)
        end
        
        cheat.utility.world_to_screen = function(world)
            local screen, inBounds = Camera:WorldToViewportPoint(world)
            return Vector2.new(screen.X, screen.Y), inBounds, screen.Z
        end
        cheat.utility.new_drawing = function(drawobj, args)
            local obj = Drawing.new(drawobj)
            for i, v in pairs(args) do
                obj[i] = v
            end
            cheat.drawings[obj] = obj
            return obj
        end
        -- ─── Damage Numbers (ported from pin.reta V2) ─────────────────────────
        -- Spawns a floating "-N" Drawing at a world position, drifts it with a
        -- simple velocity/gravity model and fades it out over 1.2s. Reads colour,
        -- random-direction and spread straight off `cheat` so the Visuals controls
        -- take effect immediately.
        cheat.utility.spawn_damage_number = function(pos, damage)
        if not pos or not damage then return end
        local rounded_dmg = math.round(damage)
        if rounded_dmg <= 0 then return end
        
        local text_str = "-" .. tostring(rounded_dmg)
        local color = cheat.damagenumbers_color or Color3.fromRGB(255, 75, 75)
        local start_time = os.clock()
        local lifetime = 1.2
        local is_random = cheat.damagenumbers_random_dir or (cheat.Toggles and cheat.Toggles.damagenumbers_random_dir and cheat.Toggles.damagenumbers_random_dir.Value)
        local spread_mult = cheat.damagenumbers_spread or (cheat.Options and cheat.Options.damagenumbers_spread and cheat.Options.damagenumbers_spread.Value) or 1
        
        local vx_px, vy_px
        local gravity_px = 0
        local init_x_px = 0
        local init_y_px = 0
        
        if is_random then
            local angle = math.random() * math.pi * 2
            local speed = math.random(55, 95) * spread_mult
            vx_px = math.cos(angle) * speed
            vy_px = (math.sin(angle) * speed * 0.6) - (math.random(35, 70) * math.clamp(spread_mult, 0.2, 3))
            gravity_px = 140
        else
            vx_px = 0
            vy_px = -50
            gravity_px = 0
            init_x_px = math.random(-15, 15) * spread_mult
            init_y_px = math.random(-8, 8) * spread_mult
        end
        
        local text = cheat.utility.new_drawing("Text", {
            Text = text_str,
            Size = 16,
            Font = 2,
            Center = true,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Color = color,
            Transparency = 1,
            Visible = false,
            ZIndex = 110
        })
        
        local conn
        conn = RunService.RenderStepped:Connect(function()
            local elapsed = os.clock() - start_time
            if elapsed >= lifetime or not cheat.alive then
                if conn then conn:Disconnect() end
                cheat.drawings[text] = nil
                pcall(function() text:Remove() end)
            else
                local screen_pos, on_screen = _WorldToViewportPoint(Camera, pos)
                if on_screen and screen_pos.Z > 0 then
                    local px_x = screen_pos.X + init_x_px + (vx_px * elapsed)
                    local px_y = screen_pos.Y + init_y_px + (vy_px * elapsed) + (0.5 * gravity_px * elapsed * elapsed)
                    text.Position = _Vector2new(px_x, px_y)
                    local alpha = 1
                    if elapsed > lifetime * 0.5 then
                        alpha = 1 - ((elapsed - lifetime * 0.5) / (lifetime * 0.5))
                    end
                    text.Transparency = math.clamp(alpha, 0, 1)
                    text.Visible = true
                else
                    text.Visible = false
                end
            end
        end)
        end

        cheat.utility.new_hook = function(f, newf, usecclosure) LPH_NO_VIRTUALIZE(function()
            if usecclosure then
                local old; old = hookfunction(f, newcclosure(function(...)
                    return newf(old, ...)
                end))
                cheat.hooks[f] = old
                return old
            else
                local old; old = hookfunction(f, function(...)
                    return newf(old, ...)
                end)
                cheat.hooks[f] = old
                return old
            end
        end)() end
        cheat.utility.restore_player_control = function()
            pcall(function() RunService:UnbindFromRenderStep("AADesyncRestore") end)
            pcall(function() RunService:UnbindFromRenderStep("TPKillAutoLook") end)
            pcall(function() UserInputService.MouseBehavior = cheat.original_state.MouseBehavior or Enum.MouseBehavior.Default end)
            pcall(function()
                Camera.CameraType = cheat.original_state.CameraType or Enum.CameraType.Custom
                local current_humanoid = LocalPlayer.Character and LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if current_humanoid then
                    Camera.CameraSubject = current_humanoid
                elseif cheat.original_state.CameraSubject then
                    Camera.CameraSubject = cheat.original_state.CameraSubject
                end
            end)
            pcall(function()
                LocalPlayer.ReplicationFocus = nil
                LocalPlayer.CameraMode = cheat.original_state.CameraMode or Enum.CameraMode.Classic
                LocalPlayer.CameraMinZoomDistance = cheat.original_state.CameraMinZoomDistance or 0.5
                LocalPlayer.CameraMaxZoomDistance = cheat.original_state.CameraMaxZoomDistance or 128
            end)

            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if hum then
                pcall(function()
                    hum.AutoRotate = true
                    hum.PlatformStand = false
                    hum.Sit = false
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                    if hum.WalkSpeed <= 0 or hum.WalkSpeed > 24 then
                        hum.WalkSpeed = 18
                    end
                    hum:ChangeState(Enum.HumanoidStateType.Running)
                end)
            end
            if hrp then
                pcall(function()
                    if cheat.real_CFrame then
                        hrp.CFrame = cheat.real_CFrame
                    end
                    hrp.AssemblyLinearVelocity = Vector3.zero
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end)
            end
            cheat.real_CFrame = nil
            cheat.desync_active = false
            cheat.freecam_enabled = false
            pcall(function()
                for _, container in ipairs({workspace, workspace.Terrain}) do
                    local focus = container:FindFirstChild("FreecamFocus")
                    if focus then focus:Destroy() end
                    local ghost = container:FindFirstChild("FreecamGhost_ESP_IGNORE")
                    if ghost then ghost:Destroy() end
                end
                local platform = workspace:FindFirstChild("TPKillPlatform")
                if platform then platform:Destroy() end
            end)
            pcall(function()
                if cheat.utility.restore_viewmodel then
                    cheat.utility.restore_viewmodel()
                end
            end)
            pcall(function()
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                local head = char and char:FindFirstChild("Head")
                local hrp2 = char and char:FindFirstChild("HumanoidRootPart")
                if hum then
                    Camera.CameraType = Enum.CameraType.Custom
                    Camera.CameraSubject = hum
                end
                if head then
                    Camera.CFrame = CFrame.new(head.Position + Vector3.new(0, 1.5, 0), head.Position + head.CFrame.LookVector * 8)
                elseif hrp2 then
                    Camera.CFrame = hrp2.CFrame * CFrame.new(0, 2, 8)
                end
            end)
        end
        local connection; connection = RunService.Heartbeat:Connect(LPH_NO_VIRTUALIZE(function(delta)
            for _, func in pairs(cheat.connections.heartbeats) do
                func(delta)
            end
        end))
        local connection1; connection1 = RunService.RenderStepped:Connect(LPH_NO_VIRTUALIZE(function(delta)
            for _, func in pairs(cheat.connections.renderstepped) do
                func(delta)
            end
        end))
        cheat.utility.unload = function()
            if cheat.unloaded then return end
            cheat.unloaded = true
            -- Stop the `while cheat.alive` background loops too, otherwise they keep
            -- polling the game after an unload.
            cheat.alive = false
            for _, toggle in pairs(cheat.Toggles or {}) do
                if toggle and toggle.SetValue then
                    pcall(function() toggle:SetValue(false) end)
                end
            end
            pcall(function()
                if cheat.utility.restore_chams then
                    cheat.utility.restore_chams()
                end
            end)
            cheat.utility.restore_player_control()
            pcall(function()
                if cheat.EspLibrary and cheat.EspLibrary.__loaded and cheat.EspLibrary.unload then
                    cheat.EspLibrary.unload()
                end
            end)
            pcall(function() connection:Disconnect() end)
            pcall(function() connection1:Disconnect() end)
            for key, _ in pairs(cheat.connections.heartbeats) do
                cheat.connections.heartbeats[key] = nil
            end
            for key, _ in pairs(cheat.connections.renderstepped) do
                cheat.connections.renderstepped[key] = nil
            end
            for key, conn in pairs(cheat.connections.generic) do
                pcall(function() conn:Disconnect() end)
                cheat.connections.generic[key] = nil
            end
            for _, drawing in pairs(cheat.drawings) do
                cheat.utility.safe_destroy(drawing)
                cheat.drawings[_] = nil
            end
            for instance, _ in pairs(cheat.instances) do
                cheat.utility.safe_destroy(instance)
                cheat.instances[instance] = nil
            end
            pcall(function()
                if cheat.Library and cheat.Library._ghostMenu then
                    if cheat.Library._ghostMenu.SetOpen then
                        cheat.Library._ghostMenu.SetOpen(false)
                    end
                    if cheat.Library._ghostMenu.gui then
                        cheat.Library._ghostMenu.gui:Destroy()
                    elseif cheat.Library._ghostMenu.GetGui then
                        local gui = cheat.Library._ghostMenu:GetGui()
                        if gui then gui:Destroy() end
                    end
                end
            end)
            -- Sweep any additional menu windows this or a previous run left behind,
            -- so a reload can never stack a second menu on top of the new one.
            pcall(function()
                if cheat.utility and cheat.utility.purge_ghost_menu_windows then
                    cheat.utility.purge_ghost_menu_windows(false)
                end
            end)
            -- Zero all globals flags BEFORE restoring camera/lighting so that the
            -- __newindex metamethod hook (which is never removed from the game metatable)
            -- no longer swallows Roblox's own Camera.FieldOfView / Lighting writes.
            -- Leaving globals.fov_enabled=true after unload causes the hook to silently
            -- eat every Camera.FieldOfView write from Roblox's CameraController, which
            -- breaks movement input processing (can look but can't walk).
            pcall(function()
                if globals then
                    globals.fov_enabled = false
                    globals.zoom_enabled = false
                    globals.EnableTime = false
                    globals.noshadows = false
                    globals.gradientenabled = false
                end
            end)
            pcall(function()
                if cheat.original_state then
                    Lighting.Ambient = cheat.original_state.Ambient
                    Lighting.OutdoorAmbient = cheat.original_state.OutdoorAmbient
                    Lighting.ClockTime = cheat.original_state.ClockTime
                    Lighting.GlobalShadows = cheat.original_state.GlobalShadows
                    Camera.FieldOfView = cheat.original_state.FieldOfView
                    setTerrainDecoration(cheat.original_state.TerrainDecoration)
                end
            end)
            cheat.utility.restore_player_control()
            for hooked, original in pairs(cheat.hooks) do
                if type(original) == "function" then
                    pcall(function() hookfunction(hooked, clonefunction(original)) end)
                else
                    pcall(function() hookmetamethod(original["instance"], original["metamethod"], clonefunction(original["func"])) end)
                end
            end
            -- Final restore after hook cleanup, in case any hook restoration
            -- triggered side-effects that locked movement again.
            cheat.utility.restore_player_control()
            if getgenv then
                getgenv().Toggles = nil
                getgenv().Options = nil
            end
            _G.Injected = false
            _G.InjectedGui = false
        end
        -- GHOST_HOOK themed loading screen: compact blue panel.
        cheat.utility.create_loading_screen = function()
            cheat.loading_active = true
            cheat.loading_finished = false
            if cheat.Library and cheat.Library.SetOpen then
                pcall(function()
                    cheat.Library:SetOpen(false)
                end)
            end

            local TweenService = game:GetService("TweenService")
            local RunService = game:GetService("RunService")

            local ASSET_SKULL = "rbxassetid://79150590038090"
            local ASSET_WORDMARK = "rbxassetid://124387443158274"
            local ASSET_BG = "rbxassetid://109358861518455"
            local ASSET_CORNER = "rbxassetid://81933545840996"
            local ASSET_FONT = "rbxassetid://12187365364"

            -- Blue theme, matched to the skull.
            local BLUE = Color3.fromRGB(0, 170, 255)
            local BLUE_SOFT = Color3.fromRGB(120, 205, 255)
            local INK = Color3.fromRGB(8, 10, 14)

            -- Narrower than before and 20% shorter than the 200px version.
            local PANEL_W, PANEL_H = 350, 160

            local screen = cheat.utility.track_instance(Instance.new("ScreenGui"))
            screen.Name = "GhostHookLoading"
            screen.ResetOnSpawn = false
            screen.IgnoreGuiInset = true
            screen.DisplayOrder = 100000
            screen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
            screen.Parent = game:GetService("CoreGui")

            local root = Instance.new("Frame")
            root.Name = "Root"
            root.BackgroundTransparency = 1
            root.BorderSizePixel = 0
            root.Size = UDim2.fromScale(1, 1)
            root.ZIndex = 1
            root.Parent = screen

            local function font(weight)
                local ok, face = pcall(function()
                    return Font.new(ASSET_FONT, weight or Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                end)
                return ok and face or nil
            end

            -- Dim the world only slightly; the art now lives inside the panel.
            local dim = Instance.new("Frame")
            dim.Name = "Dim"
            dim.BackgroundColor3 = INK
            dim.BackgroundTransparency = 0.55
            dim.BorderSizePixel = 0
            dim.Size = UDim2.fromScale(1, 1)
            dim.ZIndex = 2
            dim.Parent = root

            local panel = Instance.new("Frame")
            panel.Name = "Panel"
            panel.AnchorPoint = Vector2.new(0.5, 0.5)
            panel.BackgroundColor3 = INK
            panel.BackgroundTransparency = 0.04
            panel.BorderSizePixel = 0
            panel.Position = UDim2.fromScale(0.5, 0.5)
            panel.Size = UDim2.fromOffset(PANEL_W, PANEL_H)
            panel.ZIndex = 10
            panel.Parent = root

            -- One clean blue borderline, nothing else.
            local panelStroke = Instance.new("UIStroke")
            panelStroke.Color = BLUE
            panelStroke.Thickness = 1
            panelStroke.Transparency = 0.15
            panelStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            panelStroke.Parent = panel

            -- The background art goes INSIDE the panel (420x244, Crop to fill).
            local backdrop = Instance.new("ImageLabel")
            backdrop.Name = "Backdrop"
            backdrop.AnchorPoint = Vector2.new(0.5, 0.5)
            backdrop.BackgroundTransparency = 1
            backdrop.BorderSizePixel = 0
            backdrop.Image = ASSET_BG
            backdrop.ImageTransparency = 0.25
            backdrop.Position = UDim2.fromScale(0.5, 0.5)
            backdrop.ScaleType = Enum.ScaleType.Crop
            backdrop.Size = UDim2.fromScale(1, 1)
            backdrop.ZIndex = 11
            backdrop.Parent = panel
            -- Corner bracket. The source canvas is 420x263 but the art only
            -- occupies x 103..330, y 35..238, so we crop tight to that. With the
            -- art filling the container, rotation stays centred and each piece
            -- can be pinned to a panel corner without guesswork.
            local CROP_X, CROP_Y = 103, 35
            local CROP_W, CROP_H = 228, 204
            local ARM = 70                                  -- drawn length of the bracket arm
            local PIECE_W = ARM
            local PIECE_H = math.floor(ARM * CROP_H / CROP_W + 0.5)
            local INSET = 6                                 -- nudge outward so it reads on the panel edge

            local cornerSpecs = {
                { name = "TopLeft",     ax = 0, ay = 0 },
                { name = "TopRight",    ax = 1, ay = 0 },
                { name = "BottomRight", ax = 1, ay = 1 },
                { name = "BottomLeft",  ax = 0, ay = 1 },
            }
            for _, spec in ipairs(cornerSpecs) do
                local piece = Instance.new("ImageLabel")
                piece.Name = "Corner" .. spec.name
                piece.AnchorPoint = Vector2.new(spec.ax, spec.ay)
                piece.BackgroundTransparency = 1
                piece.BorderSizePixel = 0
                piece.Image = ASSET_CORNER
                piece.ImageTransparency = 0.1
                -- crop to the art: the canvas is 420x263 but the bracket only
                -- occupies x 103..330, y 35..238, so drop the surrounding padding
                piece.ImageRectOffset = Vector2.new(CROP_X, CROP_Y)
                piece.ImageRectSize = Vector2.new(CROP_W, CROP_H)
                piece.Size = UDim2.fromOffset(PIECE_W, PIECE_H)
                -- AnchorPoint picks which edge of the piece sits on the panel
                -- corner; the offset then moves it INSET px inside that edge.
                -- Right/bottom edges need a negative offset to move inwards.
                piece.Position = UDim2.new(
                    spec.ax,
                    (spec.ax == 1) and (-INSET - PIECE_W) or INSET,
                    spec.ay,
                    (spec.ay == 1) and (-INSET - PIECE_H) or INSET
                )
                piece.ZIndex = 20
                piece.Parent = panel
            end

            local stack = Instance.new("Frame")
            stack.Name = "Stack"
            stack.AnchorPoint = Vector2.new(0.5, 0)
            stack.BackgroundTransparency = 1
            stack.Position = UDim2.new(0.5, 0, 0, 10)
            stack.Size = UDim2.fromOffset(PANEL_W - 32, PANEL_H - 28)
            stack.ZIndex = 12
            stack.Parent = panel

            local skull = Instance.new("ImageLabel")
            skull.Name = "Skull"
            skull.AnchorPoint = Vector2.new(0.5, 0)
            skull.BackgroundTransparency = 1
            skull.BorderSizePixel = 0
            skull.Image = ASSET_SKULL
            skull.Position = UDim2.new(0.5, 0, 0, 0)
            skull.Size = UDim2.fromOffset(56, 56)
            skull.ZIndex = 13
            skull.Parent = stack

            -- Wordmark art in place of the old text title.
            local title = Instance.new("ImageLabel")
            title.Name = "Title"
            title.AnchorPoint = Vector2.new(0.5, 0)
            title.BackgroundTransparency = 1
            title.BorderSizePixel = 0
            title.Image = ASSET_WORDMARK
            title.ScaleType = Enum.ScaleType.Fit
            title.Position = UDim2.new(0.5, 0, 0, 56)
            -- asset is 420x54 (7.78:1); match that ratio so Fit does not shrink it
            title.Size = UDim2.fromOffset(236, 30)
            title.ZIndex = 13
            title.Parent = stack

            local percent = Instance.new("TextLabel")
            percent.Name = "Percent"
            percent.AnchorPoint = Vector2.new(0.5, 0)
            percent.BackgroundTransparency = 1
            percent.FontFace = font(Enum.FontWeight.Bold)
            percent.Text = "0%"
            percent.TextColor3 = BLUE
            percent.TextSize = 26
            percent.Position = UDim2.new(0.5, 0, 0, 86)
            percent.Size = UDim2.fromOffset(PANEL_W - 60, 30)
            percent.ZIndex = 13
            percent.Parent = stack

            local barTrack = Instance.new("Frame")
            barTrack.Name = "BarTrack"
            barTrack.AnchorPoint = Vector2.new(0.5, 0)
            barTrack.BackgroundColor3 = Color3.fromRGB(24, 28, 34)
            barTrack.BorderSizePixel = 0
            barTrack.Position = UDim2.new(0.5, 0, 0, 118)
            barTrack.Size = UDim2.fromOffset(PANEL_W - 90, 5)
            barTrack.ZIndex = 13
            barTrack.Parent = stack
            local trackCorner = Instance.new("UICorner")
            trackCorner.CornerRadius = UDim.new(1, 0)
            trackCorner.Parent = barTrack

            local barFill = Instance.new("Frame")
            barFill.Name = "BarFill"
            barFill.AnchorPoint = Vector2.new(0, 0.5)
            barFill.BackgroundColor3 = BLUE
            barFill.BorderSizePixel = 0
            barFill.Position = UDim2.new(0, 0, 0.5, 0)
            barFill.Size = UDim2.new(0, 0, 1, 0)
            barFill.ZIndex = 14
            barFill.Parent = barTrack
            local fillCorner = Instance.new("UICorner")
            fillCorner.CornerRadius = UDim.new(1, 0)
            fillCorner.Parent = barFill

            local statusText = Instance.new("TextLabel")
            statusText.Name = "Status"
            statusText.AnchorPoint = Vector2.new(0.5, 0)
            statusText.BackgroundTransparency = 1
            statusText.FontFace = font(Enum.FontWeight.Medium)
            statusText.Text = "Bypassing anticheat..."
            statusText.TextColor3 = Color3.fromRGB(165, 178, 190)
            statusText.TextSize = 11
            statusText.Position = UDim2.new(0.5, 0, 0, 123)
            statusText.Size = UDim2.fromOffset(PANEL_W - 40, 14)
            statusText.ZIndex = 13
            statusText.Parent = stack

            panel.BackgroundTransparency = 1
            skull.ImageTransparency = 1
            title.ImageTransparency = 1
            TweenService:Create(panel, TweenInfo.new(0.3), { BackgroundTransparency = 0.04 }):Play()
            TweenService:Create(skull, TweenInfo.new(0.5), { ImageTransparency = 0 }):Play()
            TweenService:Create(title, TweenInfo.new(0.6), { ImageTransparency = 0 }):Play()

            local statuses = {
                "Bypassing anticheat...", "Loading core modules...", "Initializing combat engine...",
                "Fetching latest config...", "Connecting to server...", "Optimizing performance...",
                "Setting up visual environment...", "Securing connection...", "Cleaning memory caches...",
            }

            local start = os.clock()
            local lastStatus = 0
            local shown = 0
            -- Watchdog: never leave the player staring at a stuck bar.
            local MAX_LOAD_SECONDS = 30

            while true do
                local elapsed = os.clock() - start
                local timedOut = elapsed >= MAX_LOAD_SECONDS
                local target = (cheat.ui_ready or timedOut) and 1 or math.min(0.92, elapsed / 4.5)
                shown = shown + (target - shown) * 0.12
                if target >= 1 and shown > 0.995 then shown = 1 end

                percent.Text = math.floor(shown * 100 + 0.5) .. "%"
                barFill.Size = UDim2.new(shown, 0, 1, 0)

                local beat = 1 + math.sin(os.clock() * 2.2) * 0.04
                skull.Size = UDim2.fromOffset(math.floor(56 * beat), math.floor(56 * beat))

                if os.clock() - lastStatus > 0.75 and not cheat.ui_ready then
                    lastStatus = os.clock()
                    statusText.Text = statuses[math.random(1, #statuses)]
                end
                if cheat.ui_ready then
                    statusText.Text = "Ready."
                elseif timedOut then
                    statusText.Text = "Taking longer than expected..."
                end

                if shown >= 1 and (cheat.ui_ready or timedOut) then
                    break
                end
                RunService.RenderStepped:Wait()
            end

            statusText.Text = "Welcome."
            task.wait(0.4)
            TweenService:Create(skull, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
            TweenService:Create(title, TweenInfo.new(0.3), { ImageTransparency = 1 }):Play()
            TweenService:Create(panel, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(dim, TweenInfo.new(0.35), { BackgroundTransparency = 1 }):Play()
            TweenService:Create(backdrop, TweenInfo.new(0.35), { ImageTransparency = 1 }):Play()
            for _, d in ipairs(panel:GetChildren()) do
                if d.Name:sub(1, 6) == "Corner" and d:IsA("ImageLabel") then
                    TweenService:Create(d, TweenInfo.new(0.35), { ImageTransparency = 1 }):Play()
                end
            end
            task.wait(0.4)

            pcall(function() screen:Destroy() end)

            cheat.loading_active = false
            cheat.loading_finished = true
            if cheat.ui_ready and cheat.Library and not cheat.unloaded then
                if cheat.Library.SetOpen then
                    cheat.Library:SetOpen(true)
                else
                    game:GetService("VirtualInputManager"):SendKeyEvent(true, Enum.KeyCode.RightShift, false, game)
                    game:GetService("VirtualInputManager"):SendKeyEvent(false, Enum.KeyCode.RightShift, false, game)
                end
            end
        end
    end
    _G.__ghostLoadStart = os.clock()
    _G.__ghostLoadMark = _G.__ghostLoadStart
    task.spawn(cheat.utility.create_loading_screen)

    -- ── GAME-READINESS GATE ────────────────────────────────────────────────
    -- The freeze is the game's own preloader: it runs a huge synchronous asset
    -- load (ReplicatedFirst.Loader) that stalls the whole engine for 6-15s.
    -- Building our UI during that window makes the client jank and can crash it.
    -- So: wait until the game itself reports ready, then build. The loading
    -- screen keeps animating via RenderStepped in the meantime.
    local _gate_waited = 0
    local function game_is_loaded()
        local RS = game:GetService("ReplicatedStorage")
        local plrFolder = RS:FindFirstChild("Players") and RS.Players:FindFirstChild(LocalPlayer.Name)
        local gv = plrFolder and plrFolder:FindFirstChild("Status") and plrFolder.Status:FindFirstChild("GameplayVariables")
        if gv and gv:GetAttribute("Loaded") == true and gv:GetAttribute("Spawned") == true then
            return true
        end
        local cp = game:GetService("ContentProvider")
        return cp.RequestQueueSize == 0
    end
    repeat
        task.wait(0.1)
        _gate_waited = _gate_waited + 0.1
    until game_is_loaded() or _gate_waited >= 30
    print(string.format("[LOAD] gate: game ready after %.1fs (loaded=%s)", _gate_waited, tostring(game_is_loaded())))


    local function loadGhostHookUiStack()
        local GHOST_LIBRARY_URL = "https://raw.githubusercontent.com/kristerstomasuns-hub/essentials/main/test%20lib?v=mousefix-20261003"
        local Toggles = {}
        local Options = {}

        local function notify(title, text, duration)
            pcall(function()
                game:GetService("StarterGui"):SetCore("SendNotification", {
                    Title = tostring(title or "GHOST_HOOK"),
                    Text = tostring(text or ""),
                    Duration = tonumber(duration) or 3,
                })
            end)
        end

        local function ensureFolder(path)
            if isfolder and makefolder and type(path) == "string" and path ~= "" and not isfolder(path) then
                makefolder(path)
            end
        end

        local function serializeValue(value)
            if typeof(value) == "Color3" then
                return { __type = "Color3", R = value.R, G = value.G, B = value.B }
            elseif type(value) == "table" then
                local copy = {}
                for key, child in pairs(value) do
                    copy[key] = serializeValue(child)
                end
                return copy
            end
            return value
        end

        local function deserializeValue(value)
            if type(value) ~= "table" then
                return value
            end
            if value.__type == "Color3" or (value.R ~= nil and value.G ~= nil and value.B ~= nil) then
                return Color3.new(tonumber(value.R) or 0, tonumber(value.G) or 0, tonumber(value.B) or 0)
            end
            local copy = {}
            for key, child in pairs(value) do
                copy[key] = deserializeValue(child)
            end
            return copy
        end

        local function selectedDefault(values, default)
            if type(values) ~= "table" then
                return default
            end
            if type(default) == "number" then
                return values[default] or values[1]
            end
            return default or values[1]
        end

        local function makeValueObject(rawElement, valueKind, initialValue, flag, callback)
            local object = {
                Value = initialValue,
                _raw = rawElement,
                _kind = valueKind,
                _flag = flag,
                Text = flag,
                _callbacks = {},
            }

            if callback then
                table.insert(object._callbacks, callback)
            end

            local function fire(value)
                object.Value = value
                for _, cb in ipairs(object._callbacks) do
                    pcall(cb, value)
                end
            end

            function object:OnChanged(cb)
                if cb then
                    table.insert(self._callbacks, cb)
                end
                return self
            end

            function object:SetValue(value, skipCallback)
                self.Value = value
                if rawElement and rawElement.set_value then
                    if valueKind == "Toggle" then
                        rawElement:set_value({ Toggle = value and true or false }, true)
                    elseif valueKind == "Slider" then
                        rawElement:set_value({ Slider = tonumber(value) or 0 }, true)
                    elseif valueKind == "Dropdown" then
                        rawElement:set_value({ Dropdown = value }, true)
                    elseif valueKind == "Combo" then
                        rawElement:set_value({ Combo = type(value) == "table" and value or {} }, true)
                    elseif valueKind == "Text" then
                        rawElement:set_value({ Text = tostring(value or "") }, true)
                    elseif valueKind == "Color" then
                        rawElement:set_value({ Color = value }, true)
                    else
                        rawElement:set_value(value, true)
                    end
                end
                if not skipCallback then
                    fire(self.Value)
                end
                return self
            end

            function object:SetValues(values)
                self.Values = values or {}
                if rawElement then
                    pcall(function()
                        if rawElement.ClearOptions then
                            rawElement:ClearOptions()
                        end
                        if rawElement.InsertOptions then
                            rawElement:InsertOptions(self.Values)
                        end
                    end)
                end
                return self
            end

            function object:SetVisible(state)
                if rawElement and rawElement.set_visible then
                    rawElement:set_visible(state and true or false)
                end
                return self
            end

            function object:AddColorPicker(colorFlag, config)
                config = config or {}
                local colorValue = config.Default or Color3.new(1, 1, 1)
                local transparency = config.Transparency
                if transparency == nil then
                    transparency = config.Alpha
                end
                if transparency == nil then
                    transparency = 0
                end
                local colorObject

                if rawElement and rawElement.add_color then
                    local rawColor = rawElement:add_color({
                        Color = colorValue,
                        Transparency = transparency,
                    }, transparency ~= nil, function(value)
                        colorObject.Value = value.Color
                        colorObject.Transparency = value.Transparency or 0
                        if config.Callback then
                            pcall(config.Callback, colorObject.Value, colorObject.Transparency)
                        end
                    end)

                    colorObject = makeValueObject(rawColor, "Color", colorValue, colorFlag, config.Callback)
                    colorObject.Transparency = transparency
                else
                    colorObject = makeValueObject(nil, "Color", colorValue, colorFlag, config.Callback)
                    colorObject.Transparency = transparency
                end

                Options[colorFlag] = colorObject
                return self
            end

            function object:AddKeyPicker(keyFlag, config)
                config = config or {}
                local defaultMode = config.Mode or "Hold"
                -- IMPORTANT: a bind NEVER changes its master toggle.
                -- The toggle is the master switch for a feature; the bind is only a
                -- held/toggled modifier that features read through feature_active().
                -- Driving the toggle from here is exactly what made releasing a Hold
                -- bind switch the whole feature off. Do not reintroduce SyncToggleState
                -- or any self:SetValue() call in this callback.
                local keyValue = {
                    Key = config.Default or "None",
                    Type = defaultMode,
                    Active = defaultMode == "Always",
                }
                local keyObject

                if rawElement and rawElement.add_keybind then
                    local rawKey = rawElement:add_keybind({
                        Key = config.Default or "None",
                        Type = defaultMode,
                    }, function(value)
                        keyObject.Value = value
                        keyObject.Key = value.Key or keyObject.Key
                        keyObject.Mode = value.Type or value.Mode or keyObject.Mode
                        keyObject.Active = keyObject.Mode == "Always"
                            or value.Active == true
                        keyObject.State = keyObject.Active
                        keyObject.Value.Active = keyObject.Active
                        -- The bind only reports its own held state. It must not touch
                        -- the toggle (see the note above AddKeyPicker).
                        if config.Callback then
                            pcall(config.Callback, keyObject.Active, value)
                        end
                    end)
                    keyObject = makeValueObject(rawKey, "Keybind", keyValue, keyFlag)
                    pcall(function()
                        rawKey:set_value({
                            Key = config.Default or "None",
                            Type = defaultMode,
                            Active = defaultMode == "Always",
                        }, true)
                    end)
                else
                    keyObject = makeValueObject(nil, "Keybind", keyValue, keyFlag)
                end

                keyObject.Text = config.Text or keyFlag
                keyObject.Key = keyValue.Key
                keyObject.Mode = keyValue.Type

                -- A bind may only start active when its mode is "Always".
                -- Hold/Toggle start released, so nothing is enabled until the key is pressed.
                local startupActive = keyObject.Mode == "Always"
                keyObject.Active = startupActive
                keyObject.State = startupActive
                keyObject.Value.Active = startupActive
                if config.Callback then
                    pcall(config.Callback, startupActive, keyObject.Value)
                end
                local baseKeySetValue = keyObject.SetValue
                function keyObject:SetValue(value)
                    if type(value) == "table" then
                        self.Key = value.Key or value.key or self.Key
                        self.Mode = value.Type or value.type or value.Mode or value.mode or self.Mode
                    elseif type(value) == "string" then
                        if value == "Hold" or value == "Toggle" or value == "Always" then
                            self.Mode = value
                        else
                            self.Key = value
                        end
                    end
                    -- Hold and Toggle binds ALWAYS restore released. Only "Always" may
                    -- come back active. Otherwise a saved bind would switch its feature on
                    -- by itself the moment the config finished loading.
                    self.Active = self.Mode == "Always"
                    self.State = self.Active
                    self.Value.Key = self.Key
                    self.Value.Type = self.Mode
                    self.Value.Active = self.Active
                    -- Push key + mode (including the bind MODE) back into the real UI
                    -- element so the menu shows what was restored.
                    if self._raw and self._raw.set_value then
                        pcall(function()
                            self._raw:set_value({ Key = self.Key, Type = self.Mode, Active = self.Active }, true)
                        end)
                    end
                    if config.Callback then
                        pcall(config.Callback, self.State, self.Value)
                    end
                    return self
                end
                Options[keyFlag] = keyObject
                return self
            end

            function object:AddButton(text, cb)
                if cb then
                    pcall(cb)
                end
                return self
            end

            if flag then
                if valueKind == "Toggle" then
                    Toggles[flag] = object
                else
                    Options[flag] = object
                end
            end

            return object, fire
        end

        local function loadGhostLibrary()
            local maclibLoaderPatch = [==[
    local function patchMacLibSource(macSource)
        macSource = macSource:gsub("RunService%.RenderStepped:Connect%(UpdateOrientation%)", "if acrylicBlur then RunService.RenderStepped:Connect(UpdateOrientation) end")
        macSource = macSource:gsub("colorC%.BackgroundTransparency = ColorpickerFunctions%.Alpha or 0", "colorC.BackgroundTransparency = 0")
        macSource = macSource:gsub("colorC%.BackgroundTransparency = isAlpha and %(1 %- ColorpickerFunctions%.Alpha%) or 0", "colorC.BackgroundTransparency = 0")
        macSource = macSource:gsub("colorC%.BackgroundTransparency = alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%)", "colorC.BackgroundTransparency = 0")
        macSource = macSource:gsub("colorC%.BackgroundTransparency = alpha", "colorC.BackgroundTransparency = 0")
        macSource = macSource:gsub("color1%.BackgroundTransparency = isAlpha and ColorpickerFunctions%.Alpha or 0", "color1.BackgroundTransparency = 0")
        macSource = macSource:gsub("color1%.BackgroundTransparency = isAlpha and alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%) or 0", "color1.BackgroundTransparency = 0")
        macSource = macSource:gsub("color1%.BackgroundTransparency = alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%)", "color1.BackgroundTransparency = 0")
        macSource = macSource:gsub("colour%.BackgroundTransparency = clampInput%(modifierInputs%.Alpha%.Text, 0, 1%)", "colour.BackgroundTransparency = 0")
        macSource = macSource:gsub("colour%.BackgroundTransparency = isAlpha and ColorpickerFunctions%.Alpha or 0", "colour.BackgroundTransparency = 0")
        macSource = macSource:gsub("colour%.BackgroundTransparency = isAlpha and alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%) or 0", "colour.BackgroundTransparency = 0")
        macSource = macSource:gsub("colour%.BackgroundTransparency = alphaToPreviewTransparency%(ColorpickerFunctions%.Alpha%)", "colour.BackgroundTransparency = 0")
        macSource = macSource:gsub("Color3%.fromRGB%(7, 7, 7%)", "Color3.fromRGB(0, 0, 0)")
        macSource = macSource:gsub("Color3%.fromRGB%(12, 13, 15%)", "Color3.fromRGB(0, 0, 0)")
        macSource = macSource:gsub("Color3%.fromRGB%(0, 221, 191%)", "Color3.fromRGB(103, 182, 254)")
        macSource = macSource:gsub("Color3%.fromRGB%(0, 174, 151%)", "Color3.fromRGB(103, 182, 254)")
        macSource = macSource:gsub("Color3%.fromRGB%(82, 82, 88%)", "Color3.fromRGB(11, 13, 15)")
        macSource = macSource:gsub("Color3%.fromRGB%(58, 58, 64%)", "Color3.fromRGB(42, 46, 52)")
        macSource = macSource:gsub("Color3%.fromRGB%(13, 13, 13%)", "Color3.fromRGB(11, 13, 15)")
        macSource = macSource:gsub("Color3%.fromRGB%(9, 12, 13%)", "Color3.fromRGB(17, 19, 20)")
        macSource = macSource:gsub("Color3%.fromRGB%(132, 40, 148%)", "Color3.fromRGB(103, 182, 254)")
        macSource = macSource:gsub("Color3%.fromRGB%(79, 95, 239%)", "Color3.fromRGB(103, 182, 254)")
        macSource = macSource:gsub("Color3%.fromRGB%(56, 67, 163%)", "Color3.fromRGB(103, 182, 254)")
        macSource = macSource:gsub("togglerDot%.Size = UDim2%.fromOffset%(3, 3%)", "togglerDot.Size = UDim2.fromOffset(0, 0)")
        macSource = macSource:gsub("togglerDot%.Parent = togglerHead", "togglerDot.Visible = false\n\t\t\t\t\ttogglerDot.Parent = togglerHead")
        macSource = macSource:gsub("togglerDotUIStroke%.Transparency = 0", "togglerDotUIStroke.Transparency = 1")
        -- Hide the toggle knob's own border so it reads as a solid filled
        -- square instead of a hollow outline (the border was previously as
        -- visible as the white fill, making the knob look like just a ring).
        macSource = macSource:gsub("togglerHeadUIStroke%.Transparency = 0", "togglerHeadUIStroke.Transparency = 1")
        macSource = macSource:gsub("ColorpickerFunctions%.Alpha = %(cX / width%)", "ColorpickerFunctions.Alpha = 1 - (cX / width)")
        macSource = macSource:gsub("local cX = ColorpickerFunctions%.Alpha %* width", "local cX = (1 - ColorpickerFunctions.Alpha) * width")
        macSource = macSource:gsub("local cX = math%.clamp%(alpha or 0, 0, 1%) %* width", "local cX = (1 - ColorpickerFunctions.Alpha) * width")
        macSource = macSource:gsub("modifierInputs%.Alpha%.Text = isAlpha and %(1 %- ColorpickerFunctions%.Alpha%) or 0", "modifierInputs.Alpha.Text = isAlpha and ColorpickerFunctions.Alpha or 0")
        macSource = macSource:gsub("information%.Size = UDim2%.new%(1, 0, 0, 63%)", "information.Size = UDim2.new(1, 0, 0, 74)")
        macSource = macSource:gsub("divider%.Parent = sidebar", "divider.Visible = false\n\tdivider.Parent = sidebar")
        macSource = macSource:gsub("divider2%.Parent = information", "divider2.Visible = false\n\tdivider2.Parent = information")
        macSource = macSource:gsub("sidebarGroup%.Position = UDim2%.fromOffset%(0, 63%)", "sidebarGroup.Position = UDim2.fromOffset(0, 74)")
        macSource = macSource:gsub("sidebarGroup%.Size = UDim2%.new%(1, 0, 1, %-63%)", "sidebarGroup.Size = UDim2.new(1, 0, 1, -74)")
        macSource = macSource:gsub("userInfo%.Size = UDim2%.new%(1, 0, 0, 107%)", "userInfo.Size = UDim2.new(1, 0, 0, 100)")
        macSource = macSource:gsub("userInfo%.Size = UDim2%.new%(1, 0, 0, 76%)", "userInfo.Size = UDim2.new(1, 0, 0, 76)")
        macSource = macSource:gsub("informationGroup%.Parent = userInfo", "informationGroup.Visible = false\n\tinformationGroup.Parent = userInfo")
        macSource = macSource:gsub("userInfoUIPadding%.Parent = userInfo", "userInfoUIPadding.Parent = userInfo\n\n\ttitleFrame.Parent = userInfo\n\ttitleFrame.Position = UDim2.new(0, 20, 0, 34)\n\ttitleFrame.Size = UDim2.new(1, -40, 0, 42)\n\ttitle.TextSize = 13\n\tsubtitle.TextSize = 9\n\tsubtitle.TextColor3 = Color3.fromRGB(0, 210, 190)\n\tsubtitle.TextTransparency = 0")
        macSource = macSource:gsub("titleFrame%.Position = UDim2%.new%(0, 18, 0, 14%)", "titleFrame.Position = UDim2.new(0, 20, 0, 14)")
        macSource = macSource:gsub("titleFrame%.Size = UDim2%.new%(1, %-36, 0, 46%)", "titleFrame.Size = UDim2.new(1, -40, 0, 42)")
        macSource = macSource:gsub("ghostLogo%.AnchorPoint = Vector2%.new%(0, 1%)", "ghostLogo.AnchorPoint = Vector2.new(0, 0)")
        macSource = macSource:gsub("ghostLogo%.Position = UDim2%.new%(0, 4, 1, %-12%)", "ghostLogo.Position = UDim2.new(0, -8, 0, -8)")
        macSource = macSource:gsub("ghostLogo%.Position = UDim2%.new%(0, %-18, 0, %-12%)", "ghostLogo.Position = UDim2.new(0, -8, 0, -8)")
        macSource = macSource:gsub("ghostLogo%.Size = UDim2%.new%(1, %-6, 0, 104%)", "ghostLogo.Size = UDim2.new(1, -14, 0, 96)")
        macSource = macSource:gsub("ghostLogo%.Size = UDim2%.new%(1, 0, 0, 112%)", "ghostLogo.Size = UDim2.new(1, -14, 0, 96)")
        macSource = macSource:gsub("ghostLogo%.Visible = false", "ghostLogo.Visible = true")
        macSource = macSource:gsub("ghostLogo%.Parent = userInfo", "ghostLogo.Parent = informationHolder")
        macSource = macSource:gsub("ghostSkull%.Position = UDim2%.new%(0, 0, 1, %-45%)", "ghostSkull.Position = UDim2.new(0, 0, 0.5, -2)")
        macSource = macSource:gsub("ghostSkull%.Size = UDim2%.fromOffset%(90, 90%)", "ghostSkull.Size = UDim2.fromOffset(82, 82)")
        macSource = macSource:gsub("ghostSkull%.Size = UDim2%.fromOffset%(94, 94%)", "ghostSkull.Size = UDim2.fromOffset(82, 82)")
        macSource = macSource:gsub("ghostWordmark%.Position = UDim2%.new%(0, 68, 1, %-146%)", "ghostWordmark.Position = UDim2.fromOffset(58, -22)")
        macSource = macSource:gsub("ghostWordmark%.Position = UDim2%.fromOffset%(58, %-22%)", "ghostWordmark.Position = UDim2.fromOffset(54, -34)")
        macSource = macSource:gsub("ghostWordmark%.Size = UDim2%.fromOffset%(225, 225%)", "ghostWordmark.Size = UDim2.fromOffset(208, 208)")
        macSource = macSource:gsub("ghostWordmark%.Size = UDim2%.fromOffset%(232, 232%)", "ghostWordmark.Size = UDim2.fromOffset(208, 208)")
        macSource = macSource:gsub("ghostLuaL%.Position = UDim2%.new%(0, 68, 1, %-146%)", "ghostLuaL.Position = UDim2.fromOffset(58, -22)")
        macSource = macSource:gsub("ghostLuaL%.Position = UDim2%.fromOffset%(58, %-22%)", "ghostLuaL.Position = UDim2.fromOffset(54, -34)")
        macSource = macSource:gsub("ghostLuaL%.Size = UDim2%.fromOffset%(225, 225%)", "ghostLuaL.Size = UDim2.fromOffset(208, 208)")
        macSource = macSource:gsub("ghostLuaL%.Size = UDim2%.fromOffset%(232, 232%)", "ghostLuaL.Size = UDim2.fromOffset(208, 208)")
        macSource = macSource:gsub("ghostLua%.Position = UDim2%.new%(0, 68, 1, %-146%)", "ghostLua.Position = UDim2.fromOffset(58, -22)")
        macSource = macSource:gsub("ghostLua%.Position = UDim2%.fromOffset%(58, %-22%)", "ghostLua.Position = UDim2.fromOffset(54, -34)")
        macSource = macSource:gsub("ghostLua%.Size = UDim2%.fromOffset%(225, 225%)", "ghostLua.Size = UDim2.fromOffset(208, 208)")
        macSource = macSource:gsub("ghostLua%.Size = UDim2%.fromOffset%(232, 232%)", "ghostLua.Size = UDim2.fromOffset(208, 208)")
        macSource = macSource:gsub("tabSwitchers%.Size = UDim2%.new%(1, 0, 1, %-107%)", "tabSwitchers.Size = UDim2.new(1, 0, 1, -104)")
        macSource = macSource:gsub("tabSwitchers%.Size = UDim2%.new%(1, 0, 1, %-80%)", "tabSwitchers.Size = UDim2.new(1, 0, 1, -80)")
        macSource = macSource:gsub("tabSwitcherUIStroke%.Color = Color3%.fromRGB%(255, 255, 255%)", "tabSwitcherUIStroke.Color = Color3.fromRGB(103, 182, 254)")
        macSource = macSource:gsub("tabImage%.ImageColor3 = Color3%.fromRGB%(103, 182, 254%)", "tabImage.ImageColor3 = Color3.fromRGB(255, 255, 255)")
        if not macSource:find("ImageColor3 = (i == tabSwitcher and Color3.fromRGB(103, 182, 254)", 1, true) then
            macSource = macSource:gsub("ImageTransparency = %(i == tabSwitcher and 0%.1 or 0%.5%)", "ImageColor3 = (i == tabSwitcher and Color3.fromRGB(103, 182, 254) or Color3.fromRGB(255, 255, 255)),\n\t\t\t\t\t\t\tImageTransparency = (i == tabSwitcher and 0.1 or 0.5)")
        end
        macSource = macSource:gsub("tabSwitcherUIStroke%.Transparency = 1", "tabSwitcherUIStroke.Thickness = 1.25\n\t\t\ttabSwitcherUIStroke.Transparency = 1")
        macSource = macSource:gsub("Transparency = %(i == tabSwitcher and 0%.95 or 1%)", "Transparency = (i == tabSwitcher and 0 or 1)")
        macSource = macSource:gsub("tabSwitchersScrollingFrame%.BackgroundTransparency = 0", "tabSwitchersScrollingFrame.BackgroundTransparency = 1")
        macSource = macSource:gsub("tabSwitchersScrollingFrame%.Size = UDim2%.fromScale%(1, 1%)", "tabSwitchersScrollingFrame.Size = UDim2.fromScale(1, 1)\n\ttabSwitchersScrollingFrame.ZIndex = 2", 1)
        macSource = macSource:gsub("BackgroundTransparency = %(i == tabSwitcher and 0 or 1%)", "BackgroundTransparency = (i == tabSwitcher and 0.62 or 1)")
        macSource = macSource:gsub('tabSwitchersBackground%.Image = "rbxassetid://139913314515436"', 'tabSwitchersBackground.Image = "rbxassetid://104673673037299"')
        macSource = macSource:gsub('tabSwitchersBackground%.Image = "rbxassetid://83675218406550"', 'tabSwitchersBackground.Image = "rbxassetid://104673673037299"')
        macSource = macSource:gsub("tabSwitchersBackground%.ImageTransparency = 0%.35", "tabSwitchersBackground.ImageTransparency = 0.34")
        macSource = macSource:gsub("tabSwitchersBackground%.ScaleType = Enum%.ScaleType%.Crop", "tabSwitchersBackground.ScaleType = Enum.ScaleType.Fit")
        macSource = macSource:gsub("tabSwitchersBackground%.Size = UDim2%.fromScale%([%d%.]+, [%d%.]+%)", "tabSwitchersBackground.Size = UDim2.fromScale(1, 1)")
        macSource = macSource:gsub("tabSwitchersBackground%.Position = UDim2%.fromScale%([%d%.]+, [%d%.]+%)", "tabSwitchersBackground.Position = UDim2.fromScale(0.5, 0.5)")
        macSource = macSource:gsub("tabSwitchersBackground%.Parent = tabSwitchers", "tabSwitchersBackground.Parent = sidebar")
        -- even out the box gaps: the middle column gap is 15, the in-column gap was 10
        macSource = macSource:gsub("elementsScrollingUIListLayout%.Padding = UDim%.new%(%d+, %d+%)", "elementsScrollingUIListLayout.Padding = UDim.new(0, 15)")
        macSource = macSource:gsub("leftUIListLayout%.Padding = UDim%.new%(%d+, %d+%)", "leftUIListLayout.Padding = UDim.new(0, 15)")
        macSource = macSource:gsub("rightUIListLayout%.Padding = UDim%.new%(%d+, %d+%)", "rightUIListLayout.Padding = UDim.new(0, 15)")
        macSource = macSource:gsub("topbarBackground%.AnchorPoint = Vector2%.new%(0%.5, 0%.5%)", "topbarBackground.AnchorPoint = Vector2.new(0, 0)")
        macSource = macSource:gsub('topbarBackground%.Image = "rbxassetid://109786881980249"', 'topbarBackground.Image = ""')
        macSource = macSource:gsub("topbarBackground%.ImageTransparency = 0", "topbarBackground.ImageTransparency = 1")
        macSource = macSource:gsub("topbarBackground%.Position = UDim2%.new%(0%.5, 0, 0%.5, 0%)", "topbarBackground.Position = UDim2.new(0, -30, 0, -7)")
        macSource = macSource:gsub("topbarBackground%.Position = UDim2%.new%(0%.5, 0, 0%.5, %-4%)", "topbarBackground.Position = UDim2.new(0, -30, 0, -7)")
        macSource = macSource:gsub("topbarBackground%.Size = UDim2%.new%(1, 0, 1, 0%)", "topbarBackground.Size = UDim2.new(1, 60, 0, 72)")
        macSource = macSource:gsub("topbarBackground%.Visible = true", "topbarBackground.Visible = false")

        if not macSource:find('Name = "LibrarySearch"', 1, true) then
            local searchSource = [[
    currentTab.Size = UDim2.new(1, -230, 0, 0)

    local librarySearch = Instance.new("TextBox")
    librarySearch.Name = "LibrarySearch"
    librarySearch.AnchorPoint = Vector2.new(1, 0.5)
    librarySearch.BackgroundColor3 = Color3.fromRGB(7, 9, 10)
    librarySearch.BorderSizePixel = 0
    librarySearch.ClearTextOnFocus = false
    librarySearch.FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    librarySearch.PlaceholderColor3 = Color3.fromRGB(140, 145, 150)
    librarySearch.PlaceholderText = "Search library"
    librarySearch.Position = UDim2.new(1, 0, 0.5, 0)
    librarySearch.Size = UDim2.fromOffset(190, 30)
    librarySearch.Text = ""
    librarySearch.TextColor3 = Color3.fromRGB(235, 235, 235)
    librarySearch.TextSize = 13
    librarySearch.TextXAlignment = Enum.TextXAlignment.Left
    librarySearch.ZIndex = 4
    librarySearch.Parent = elements

    local librarySearchCorner = Instance.new("UICorner")
    librarySearchCorner.CornerRadius = UDim.new(0, 5)
    librarySearchCorner.Parent = librarySearch

    local librarySearchStroke = Instance.new("UIStroke")
    librarySearchStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    librarySearchStroke.Color = Color3.fromRGB(42, 46, 52)
    librarySearchStroke.Thickness = 1
    librarySearchStroke.Parent = librarySearch

    local librarySearchPadding = Instance.new("UIPadding")
    librarySearchPadding.PaddingLeft = UDim.new(0, 10)
    librarySearchPadding.PaddingRight = UDim.new(0, 10)
    librarySearchPadding.Parent = librarySearch

    local function updateLibrarySearch()
        local query = string.lower(librarySearch.Text):gsub("^%s+", ""):gsub("%s+$", "")

        for tabSwitcher, tabInfo in pairs(tabs) do
            local tabName = tabInfo.switcherName and tabInfo.switcherName.Text or ""
            tabSwitcher.Visible = query == "" or string.find(string.lower(tabName), query, 1, true) ~= nil
        end

        for _, tabGroup in ipairs(tabSwitchersScrollingFrame:GetChildren()) do
            if tabGroup.Name == "Section" then
                local hasMatch = false
                for _, descendant in ipairs(tabGroup:GetDescendants()) do
                    if descendant.Name == "TabSwitcher" and descendant.Visible then
                        hasMatch = true
                        break
                    end
                end
                tabGroup.Visible = hasMatch
            end
        end
    end

    librarySearch:GetPropertyChangedSignal("Text"):Connect(updateLibrarySearch)
    librarySearch.Focused:Connect(function()
        librarySearchStroke.Color = Color3.fromRGB(103, 182, 254)
    end)
    librarySearch.FocusLost:Connect(function()
        librarySearchStroke.Color = Color3.fromRGB(42, 46, 52)
    end)]]
            macSource = macSource:gsub("currentTab%.Parent = elements", "currentTab.Parent = elements\n\n" .. searchSource, 1)
        end

        if not macSource:find('Name = "TabSwitchersBackground"', 1, true) then
            local tabBackgroundSource = [[
        local themeAccentLineTop = Instance.new("Frame")
        themeAccentLineTop.Name = "ThemeAccentLineTop"
        themeAccentLineTop.BackgroundColor3 = Color3.fromRGB(103, 182, 254)
        themeAccentLineTop.BackgroundTransparency = 0.1
        themeAccentLineTop.BorderSizePixel = 0
        themeAccentLineTop.Position = UDim2.new(0, 0, 0, 74)
        themeAccentLineTop.Size = UDim2.new(1, 0, 0, 1)
        themeAccentLineTop.Visible = false
        themeAccentLineTop.ZIndex = 20
        themeAccentLineTop.Parent = sidebar

        local themeAccentLineRight = Instance.new("Frame")
        themeAccentLineRight.Name = "ThemeAccentLineRight"
        themeAccentLineRight.BackgroundColor3 = Color3.fromRGB(34, 40, 42)
        themeAccentLineRight.BackgroundTransparency = 0.2
        themeAccentLineRight.BorderSizePixel = 0
        themeAccentLineRight.Position = UDim2.new(1, -1, 0, 0)
        themeAccentLineRight.Size = UDim2.new(0, 1, 1, 0)
        themeAccentLineRight.ZIndex = 20
        themeAccentLineRight.Parent = sidebar

        local tabSwitchersBackground = Instance.new("ImageLabel")
        tabSwitchersBackground.Name = "TabSwitchersBackground"
        tabSwitchersBackground.Image = "rbxassetid://104673673037299"
        tabSwitchersBackground.ImageTransparency = 0.28
        tabSwitchersBackground.ImageColor3 = Color3.fromRGB(220, 220, 220)
        tabSwitchersBackground.ScaleType = Enum.ScaleType.Fit
        tabSwitchersBackground.BackgroundTransparency = 1
        tabSwitchersBackground.BorderSizePixel = 0
        tabSwitchersBackground.AnchorPoint = Vector2.new(0.5, 0.5)
        tabSwitchersBackground.Position = UDim2.fromScale(0.62, 0.48)
        tabSwitchersBackground.Size = UDim2.fromScale(0.72, 0.72)
        tabSwitchersBackground.ZIndex = 0
        tabSwitchersBackground.Active = false
        tabSwitchersBackground.Parent = sidebar

        local themeAccentLineBottom = Instance.new("Frame")
        themeAccentLineBottom.Name = "ThemeAccentLineBottom"
        themeAccentLineBottom.BackgroundColor3 = Color3.fromRGB(103, 182, 254)
        themeAccentLineBottom.BackgroundTransparency = 1
        themeAccentLineBottom.BorderSizePixel = 0
        themeAccentLineBottom.Position = UDim2.new(0, 0, 1, -1)
        themeAccentLineBottom.Size = UDim2.new(1, 0, 0, 1)
        themeAccentLineBottom.Visible = false
        themeAccentLineBottom.ZIndex = 20
        themeAccentLineBottom.Parent = tabSwitchers]]
            macSource = macSource:gsub("tabSwitchers%.Size = UDim2%.new%(1, 0, 1, %-104%)[\r\n]", "tabSwitchers.Size = UDim2.new(1, 0, 1, -104)\n\n" .. tabBackgroundSource .. "\n\n", 1)
        end

        local alphaTextReady = macSource:find('Name = "AlphaText"', 1, true) ~= nil
        if not alphaTextReady then
            local alphaTextSource = [[
                        local colorAlphaText = Instance.new("TextLabel")
                        colorAlphaText.Name = "AlphaText"
                        colorAlphaText.AnchorPoint = Vector2.new(0.5, 0.5)
                        colorAlphaText.BackgroundTransparency = 1
                        colorAlphaText.BorderSizePixel = 0
                        colorAlphaText.FontFace = Font.new(assets.interFont, Enum.FontWeight.Medium, Enum.FontStyle.Normal)
                        colorAlphaText.Position = UDim2.fromScale(0.5, 0.5)
                        colorAlphaText.Size = UDim2.fromScale(1, 1)
                        colorAlphaText.Text = ""
                        colorAlphaText.TextColor3 = Color3.fromRGB(255, 255, 255)
                        colorAlphaText.TextSize = 9
                        colorAlphaText.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
                        colorAlphaText.TextStrokeTransparency = 0.35
                        colorAlphaText.TextXAlignment = Enum.TextXAlignment.Center
                        colorAlphaText.TextYAlignment = Enum.TextYAlignment.Center
                        colorAlphaText.ZIndex = 7
                        colorAlphaText.Parent = colorCbg]]
            local count
            macSource, count = macSource:gsub("colorC%.Parent = colorCbg", "colorC.Parent = colorCbg\n\n" .. alphaTextSource, 1)
            alphaTextReady = count > 0
        end

        local helperSource = [[
                        local function formatAlphaLabel(alpha)
                            local value = math.clamp(tonumber(alpha) or 0, 0, 1)
                            if value == 0 or value == 1 then
                                return tostring(value)
                            end
                            return string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")
                        end

                        local function updateAlphaPreviewText()
                            colorAlphaText.Visible = isAlpha
                            colorAlphaText.Text = isAlpha and formatAlphaLabel(ColorpickerFunctions.Alpha) or ""
                        end]]
        if alphaTextReady and not macSource:find("formatAlphaLabel", 1, true) then
            macSource = macSource:gsub("local function update%(%)[\r\n]", helperSource .. "\n\n					local function update()\n", 1)
        end
        if alphaTextReady and macSource:find("updateAlphaPreviewText", 1, true) then
            macSource = macSource:gsub("update%(%)[\r\n](%s*end)", "update()\n						updateAlphaPreviewText()\n%1")
            macSource = macSource:gsub("(UpdateRingFromHSV%(hue, saturation, value%)[\r\n])", "%1						updateAlphaPreviewText()\n")
        end
        return macSource
    end

    local macSource = game:HttpGet(MACLIB_URL)
    macSource = patchMacLibSource(macSource)
    return loadstring(macSource)()
    ]==]
            local source
            pcall(function()
                source = game:HttpGet(GHOST_LIBRARY_URL, true)
            end)

            if source and source ~= "" then
                source = source:gsub('Subtitle%s*=%s*"[^"]*"', 'Subtitle = "Credits - KT.RK.JD"', 1)
                source = source:gsub('AcrylicBlur%s*=%s*true', 'AcrylicBlur = false')
                source = source:gsub('object%.Name == "ToggleUIStroke" or object%.Name == "ColorPickerOutline"', 'object.Name == "ToggleUIStroke" or object.Name == "TabSwitcherUIStroke"')
                source = source:gsub('menu%.SetMenuKeybind%(value%)', 'menu.SetMenuKeybind(value.Key or value.Bind or value)')
                source = source:gsub(
                    'return%s+loadstring%(%s*game:HttpGet%(%s*MACLIB_URL%s*%)%s*%)%(%s*%)',
                    maclibLoaderPatch
                )
                pcall(function()
                    writefile("GHOST_HOOK/new/files/library_main.lua", source)
                end)
                local ok, loaded = pcall(function()
                    return loadstring(source)()
                end)
                if ok and type(loaded) == "table" then
                    return loaded
                end
            end

            local localSource = readGhostHookfile("library_main.lua")
            if localSource then
                localSource = localSource:gsub('Subtitle%s*=%s*"[^"]*"', 'Subtitle = "Credits - KT.RK.JD"', 1)
                localSource = localSource:gsub('AcrylicBlur%s*=%s*true', 'AcrylicBlur = false')
                localSource = localSource:gsub('object%.Name == "ToggleUIStroke" or object%.Name == "ColorPickerOutline"', 'object.Name == "ToggleUIStroke" or object.Name == "TabSwitcherUIStroke"')
                localSource = localSource:gsub('menu%.SetMenuKeybind%(value%)', 'menu.SetMenuKeybind(value.Key or value.Bind or value)')
                localSource = localSource:gsub(
                    'return%s+loadstring%(%s*game:HttpGet%(%s*MACLIB_URL%s*%)%s*%)%(%s*%)',
                    maclibLoaderPatch
                )
                local localChunk = loadstring(localSource)
                local ok, loaded, loadedToggles, loadedOptions = pcall(localChunk)
                if ok and type(loaded) == "table" then
                    return loaded, loadedToggles, loadedOptions
                end
            end
        end

        local ghostLibrary, loadedToggles, loadedOptions = loadGhostLibrary()

        if type(ghostLibrary) == "table" and type(ghostLibrary.CreateWindow) == "function" then
            Toggles = type(loadedToggles) == "table" and loadedToggles or Toggles
            Options = type(loadedOptions) == "table" and loadedOptions or Options
            local themeChunk = loadGhostHookfile("library_theme.lua")
            local saveChunk = loadGhostHookfile("library_save.lua")
            local _, themeManager = pcall(function()
                return themeChunk and themeChunk()
            end)
            local _, saveManager = pcall(function()
                return saveChunk and saveChunk()
            end)
            return ghostLibrary, Toggles, Options, themeManager or {}, saveManager or {}
        end

        if type(ghostLibrary) ~= "table" or type(ghostLibrary.new) ~= "function" then
            error("GHOST_HOOK failed to load Ghost-compatible library_main.lua")
        end

        local Library = {
            Toggles = Toggles,
            Options = Options,
            KeybindFrame = { Visible = false },
        }

        local ghostTabIcons = {
            Combat = "rbxassetid://109366020496537",
            Visuals = "rbxassetid://119385181967075",
            Movement = "rbxassetid://139044864852433",
            Player = "rbxassetid://98375642144966",
            World = "rbxassetid://137174378463882",
            Misc = "rbxassetid://130943404476007",
            Settings = "rbxassetid://130507927595367",
        }

        local function normalizeTabArgs(name, icon)
            if type(name) == "table" then
                icon = name.Icon or name.Image or name.icon or name.image or icon
                name = name.Name or name.Title or name.name or name.title
            end

            name = tostring(name or "Tab")
            icon = icon or ghostTabIcons[name]
            return name, icon
        end

        local function wrapSector(sector)
            local group = {}

            function group:AddToggle(flag, config)
                config = config or {}
                local text = config.Text or flag
                local object
                local raw = sector.element("Toggle", text, {
                    default = { Toggle = config.Default and true or false },
                }, function(value)
                    object.Value = value.Toggle and true or false
                    if config.Callback then
                        pcall(config.Callback, object.Value)
                    end
                    for _, cb in ipairs(object._callbacks) do
                        if cb ~= config.Callback then
                            pcall(cb, object.Value)
                        end
                    end
                end, nil, flag)

                object = makeValueObject(raw, "Toggle", config.Default and true or false, flag, config.Callback)
                return object
            end

            function group:AddSlider(flag, config)
                config = config or {}
                local rounding = tonumber(config.Rounding) or 0
                local scale = rounding > 0 and (10 ^ rounding) or 1
                local min = tonumber(config.Min) or 0
                local max = tonumber(config.Max) or 100
                local default = tonumber(config.Default) or min
                local object

                local raw = sector.element("Slider", config.Text or flag, {
                    default = {
                        min = min * scale,
                        max = max * scale,
                        default = default * scale,
                    },
                }, function(value)
                    object.Value = (tonumber(value.Slider) or 0) / scale
                    if config.Callback then
                        pcall(config.Callback, object.Value)
                    end
                    for _, cb in ipairs(object._callbacks) do
                        if cb ~= config.Callback then
                            pcall(cb, object.Value)
                        end
                    end
                end, nil, flag)

                object = makeValueObject(raw, "Slider", default, flag, config.Callback)
                local baseSetValue = object.SetValue
                function object:SetValue(value, skipCallback)
                    value = tonumber(value) or min
                    self.Value = value
                    if raw and raw.set_value then
                        raw:set_value({ Slider = value * scale }, true)
                    end
                    if not skipCallback then
                        for _, cb in ipairs(self._callbacks) do
                            pcall(cb, self.Value)
                        end
                    end
                    return self
                end
                object._baseSetValue = baseSetValue
                return object
            end

            function group:AddDropdown(flag, config)
                config = config or {}
                local values = config.Values or config.Options or {}
                local isMulti = config.Multi and true or false
                local default = isMulti and (type(config.Default) == "table" and config.Default or {}) or selectedDefault(values, config.Default)
                local elementType = isMulti and "Combo" or "Dropdown"
                local object

                local raw = sector.element(elementType, config.Text or flag, {
                    options = values,
                    default = isMulti and { Combo = default } or { Dropdown = default },
                }, function(value)
                    object.Value = isMulti and (value.Combo or {}) or value.Dropdown
                    if config.Callback then
                        pcall(config.Callback, object.Value)
                    end
                    for _, cb in ipairs(object._callbacks) do
                        if cb ~= config.Callback then
                            pcall(cb, object.Value)
                        end
                    end
                end, nil, flag)

                object = makeValueObject(raw, isMulti and "Combo" or "Dropdown", default, flag, config.Callback)
                object.Values = values
                return object
            end

            function group:AddInput(flag, config)
                config = config or {}
                local default = config.Default or ""
                local object
                local raw = sector.element("TextBox", config.Text or flag, {
                    default = { Text = default },
                    clearTextOnFocus = config.ClearTextOnFocus == true,
                }, function(value)
                    if type(value) == "table" then
                        object.Value = value.Text or value.Value or value.value or ""
                    else
                        object.Value = tostring(value or "")
                    end
                    if config.Callback then
                        pcall(config.Callback, object.Value)
                    end
                    for _, cb in ipairs(object._callbacks) do
                        if cb ~= config.Callback then
                            pcall(cb, object.Value)
                        end
                    end
                end, nil, flag)

                object = makeValueObject(raw, "Text", default, flag, config.Callback)
                function object:GetInput()
                    if raw and raw.GetInput then
                        return raw:GetInput()
                    elseif raw and raw.get_value then
                        local rawValue = raw:get_value()
                        if type(rawValue) == "table" then
                            return rawValue.Text or rawValue.Value or rawValue.value or self.Value
                        end
                        return rawValue
                    end
                    return self.Value
                end
                return object
            end

            function group:AddKeybind(flag, config)
                config = config or {}
                local default = config.Default or config.default or "None"
                local defaultMode = config.Mode or "Hold"
                local object
                local raw = sector.element("Keybind", config.Text or flag, {
                    default = default,
                }, function(value)
                    object.Value = value
                    if type(value) == "table" then
                        object.Key = value.Key or value.key or object.Key
                        object.Mode = value.Type or value.type or value.Mode or value.mode or object.Mode
                        object.State = value.Active == true or value.active == true
                    elseif value ~= nil then
                        object.Key = value
                    end
                    if config.Callback then
                        pcall(config.Callback, value)
                    end
                    for _, cb in ipairs(object._callbacks) do
                        if cb ~= config.Callback then
                            pcall(cb, value)
                        end
                    end
                end, nil, flag)

                object = makeValueObject(raw, "Keybind", { Key = default, Type = defaultMode, Active = defaultMode == "Always" }, flag, config.Callback)
                object.Text = config.Text or flag
                object.Key = default
                object.Mode = defaultMode
                -- Only "Always" may start active; Hold/Toggle start released
                object.Active = defaultMode == "Always"
                object.State = object.Active
                if type(object.Value) == "table" then
                    object.Value.Active = object.Active
                end
                return object
            end

            function group:AddButton(text, callback)
                local button = {}
                sector.element("Button", text, {}, function()
                    if callback then
                        pcall(callback)
                    end
                end)
                function button:AddButton(nextText, nextCallback)
                    return group:AddButton(nextText, nextCallback)
                end
                return button
            end

            function group:AddLabel(text)
                local label = { Text = tostring(text or "") }
                sector.element("Label", label.Text, {}, function() end)
                function label:SetText(newText)
                    self.Text = tostring(newText or "")
                    return self
                end
                return label
            end

            function group:AddDivider()
                if sector.create_line then
                    sector.create_line()
                end
                return self
            end

            function group:AddDependencyBox()
                local dep = wrapSector(sector)
                function dep:SetupDependencies()
                    return self
                end
                return dep
            end

            function group:SetupDependencies()
                return self
            end

            return group
        end

        local function wrapTab(oldTab)
            local tab = {
                _old = oldTab,
                _tabboxCount = 0,
                _groupboxCount = 0,
            }

            local function makeSection(prefix)
                tab._tabboxCount = tab._tabboxCount + 1
                return oldTab.new_section(prefix .. " " .. tostring(tab._tabboxCount))
            end

            local function addTabbox(side)
                local section = makeSection(side .. " Tabbox")
                return {
                    AddTab = function(_, name)
                        return wrapSector(section.new_sector(name or "Tab", side))
                    end,
                }
            end

            local function addGroupbox(side, name)
                tab._groupboxCount = tab._groupboxCount + 1
                local section = oldTab.new_section(name or (side .. " Groupbox " .. tostring(tab._groupboxCount)))
                return wrapSector(section.new_sector(name or "Groupbox", side))
            end

            function tab:AddLeftTabbox()
                return addTabbox("Left")
            end

            function tab:AddRightTabbox()
                return addTabbox("Right")
            end

            function tab:AddLeftGroupbox(name)
                return addGroupbox("Left", name)
            end

            function tab:AddRightGroupbox(name)
                return addGroupbox("Right", name)
            end

            return tab
        end

        function Library:CreateWindow(config)
            config = config or {}
            local menu = ghostLibrary.new(config.Title or "GHOST_HOOK", "GHOST_HOOK/")
            self._ghostMenu = menu
            self.Opened = menu.IsOpen and menu.IsOpen() or true
            if menu.SetOpen and not menu._ghostHookOpenWrapped then
                local originalSetOpen = menu.SetOpen
                menu.SetOpen = function(state)
                    self.Opened = state and true or false
                    return originalSetOpen(state)
                end
                menu._ghostHookOpenWrapped = true
            end
            if menu.gui then
                cheat.utility.track_instance(menu.gui)
            elseif menu.GetGui then
                pcall(function()
                    local gui = menu:GetGui()
                    if gui then cheat.utility.track_instance(gui) end
                end)
            end
            if config.AutoShow == false or cheat.loading_active then
                self:SetOpen(false)
            end
            self._window = {
                _menu = menu,
                AddTab = function(_, name, icon)
                    local tabName, tabIcon = normalizeTabArgs(name, icon)
                    return wrapTab(menu.new_tab(tabIcon, tabName))
                end,
                SetStatusText = function(_, text, color)
                    if menu.SetStatusText then
                        menu:SetStatusText(text, color)
                    end
                end,
            }
            return self._window
        end

        function Library:SetOpen(state)
            self.Opened = state and true or false
            if self._ghostMenu and self._ghostMenu.SetOpen then
                pcall(function()
                    self._ghostMenu.SetOpen(self.Opened)
                end)
            end
            if self._ghostMenu and self._ghostMenu.gui then
                self._ghostMenu.gui.Enabled = self.Opened
            end
        end

        function Library:SetToggleKey(key)
            if type(key) == "table" then
                key = key.Key or key.key or key.Value or key.value
            end
            if self._ghostMenu and self._ghostMenu.SetMenuKeybind then
                return self._ghostMenu.SetMenuKeybind(key)
            end
            return false
        end

        function Library:Notify(title, text, duration)
            if self._ghostMenu and self._ghostMenu.window and self._ghostMenu.window.Notify then
                pcall(function()
                    self._ghostMenu.window:Notify({
                        Title = tostring(title or "GHOST_HOOK"),
                        Description = tostring(text or ""),
                        Lifetime = tonumber(duration) or 3,
                    })
                end)
            end
            notify(title, text, duration)
        end

        local function makeSaveManager()
            local manager = {
                Folder = "GHOST_HOOK",
                Ignore = {},
                Library = Library,
                Options = Options,
                Toggles = Toggles,
            }

            function manager:SetOptionsTEMP(newOptions, newToggles)
                self.Options = newOptions or self.Options
                self.Toggles = newToggles or self.Toggles
            end

            function manager:SetLibrary(lib)
                self.Library = lib
            end

            local function cleanConfigName(name)
                name = tostring(name or "Default")
                name = name:gsub("%.json$", ""):gsub("%.txt$", "")
                name = name:gsub("^%s+", ""):gsub("%s+$", "")
                return name ~= "" and name or "Default"
            end

            local function getGhostMenu(self)
                return self.Library and self.Library._ghostMenu
            end

            function manager:IgnoreThemeSettings() end

            function manager:SetFolder(folder)
                self.Folder = folder or self.Folder
                ensureFolder(self.Folder)
                ensureFolder(self.Folder .. "/settings")
            end

            function manager:RefreshConfigList()
                ensureFolder(self.Folder)
                ensureFolder(self.Folder .. "/settings")
                local out = {}
                local seen = {}
                local function add(name)
                    name = cleanConfigName(name)
                    if name ~= "" and name ~= "autoload" and not seen[name] then
                        seen[name] = true
                        table.insert(out, name)
                    end
                end

                local function addFilesFrom(folder)
                    if not (listfiles and type(folder) == "string" and folder ~= "") then
                        return
                    end

                    local ok, files = pcall(listfiles, folder)
                    if not ok or type(files) ~= "table" then
                        return
                    end

                    for _, file in ipairs(files) do
                        local path = tostring(file)
                        local name = path:match("([^/\\]+)%.json$") or path:match("([^/\\]+)%.txt$")
                        if name and name ~= "settings" then
                            add(name)
                        end
                    end
                end

                addFilesFrom(self.Folder .. "/settings")
                addFilesFrom(self.Folder)

                local ghostMenu = getGhostMenu(self)
                if ghostMenu and ghostMenu.cfg_location then
                    addFilesFrom(ghostMenu.cfg_location)
                    addFilesFrom(tostring(ghostMenu.cfg_location) .. "/settings")
                end

                return out
            end

            function manager:Save(name)
                name = cleanConfigName(name)
                local ghostMenu = getGhostMenu(self)
                if ghostMenu and type(ghostMenu.save_cfg) == "function" then
                    -- The library writes its own menu.values verbatim, so any flag left
                    -- behind by a UI element that no longer exists (moved or removed tabs)
                    -- is re-written on every save and re-applied on every load. A config
                    -- was found carrying the same flag twice under two different labels --
                    -- e.g. flyhack_enabled in both the old and new Flyhack tab. Prune
                    -- values whose flag is no longer registered in menu._elements.
                    pcall(function()
                        local values = ghostMenu.values
                        local elements = ghostMenu._elements
                        if type(values) ~= "table" or type(elements) ~= "table" then return end
                        local live = {}
                        for tabNum, sections in pairs(elements) do
                            for sectionName, sectors in pairs(sections) do
                                for sectorName, flags in pairs(sectors) do
                                    for flag in pairs(flags) do
                                        live[tostring(flag)] = true
                                    end
                                end
                            end
                        end
                        local pruned = 0
                        for tabNum, sections in pairs(values) do
                            for sectionName, sectors in pairs(sections) do
                                for sectorName, flags in pairs(sectors) do
                                    if type(flags) == "table" then
                                        for flag in pairs(flags) do
                                            -- Match by flag NAME only. A flag whose whole
                                            -- path moved (e.g. Flyhack's tab was relocated)
                                            -- must be kept, otherwise its saved value is
                                            -- silently lost. Only names that exist nowhere
                                            -- in the live element registry are truly dead.
                                            if not live[tostring(flag)] then
                                                flags[flag] = nil
                                                pruned = pruned + 1
                                            end
                                        end
                                    end
                                end
                            end
                        end
                        if pruned > 0 then
                            print("[config] pruned " .. pruned .. " stale entr(ies) from " .. tostring(name))
                        end
                    end)

                    -- "Default" is the all-off baseline. Force every toggle off and release
                    -- every bind BEFORE the library snapshots menu.values, otherwise saving
                    -- Default while features happen to be on bakes them in permanently.
                    if name == "Default" then
                        pcall(function()
                            for _, object in pairs(self.Toggles or {}) do
                                if object and object.SetValue then
                                    object:SetValue(false)
                                end
                            end
                            if cheat.release_all_binds then cheat.release_all_binds() end
                        end)
                    end

                    local ok, resultOrErr = ghostMenu.save_cfg(name)
                    if ok then
                        return true, resultOrErr
                    end
                end

                if type(name) ~= "string" or name:gsub("%s+", "") == "" then
                    return false, "invalid config name"
                end
                ensureFolder(self.Folder)
                ensureFolder(self.Folder .. "/settings")
                local data = { Toggles = {}, Options = {} }

                -- A keybind may only be persisted as active when its mode is "Always".
                -- Hold/Toggle are always saved released, so loading a config can never
                -- bring a bound feature up switched on. Master toggles still save normally.
                local function serializeOptionValue(object)
                    -- Color pickers keep their alpha on the object, not inside Value, so
                    -- it must be written explicitly or every load loses the transparency.
                    if object and object._kind == "Color" then
                        return {
                            __kind = "Color",
                            Color = serializeValue(object.Value),
                            Transparency = tonumber(object.Transparency) or 0,
                        }
                    end
                    local value = object and object.Value
                    if type(value) ~= "table" then
                        return serializeValue(value)
                    end
                    local mode = value.Type or value.type or object.Mode
                    local copy = serializeValue(value)
                    if type(copy) == "table" and mode ~= "Always" then
                        copy.Active = false
                    end
                    return copy
                end

                -- "Default" is the all-off baseline. Whatever happened to be enabled
                -- when it was written must never be baked in, or those features switch
                -- themselves on at every startup (charge shot did exactly that).
                local is_default = (name == "Default")
                for flag, object in pairs(self.Toggles or {}) do
                    local value = object.Value
                    if is_default then value = false end
                    data.Toggles[flag] = serializeValue(value)
                end
                for flag, object in pairs(self.Options or {}) do
                    if is_default then
                        local v = object.Value
                        if type(v) == "table" then
                            local copy = serializeOptionValue(object)
                            if type(copy) == "table" then copy.Active = false end
                            data.Options[flag] = copy
                        else
                            data.Options[flag] = serializeOptionValue(object)
                        end
                    else
                        data.Options[flag] = serializeOptionValue(object)
                    end
                end
                local ok, encoded = pcall(function()
                    return HttpService:JSONEncode(data)
                end)
                if not ok then
                    return false, encoded
                end
                writefile(self.Folder .. "/settings/" .. name .. ".json", encoded)
                return true
            end

            function manager:Load(name)
                name = cleanConfigName(name)
                local ghostMenu = getGhostMenu(self)
                local function applyLoadedTheme()
                    task.defer(function()
                        local menu = getGhostMenu(self)
                        if menu and menu.SetThemeAccent then
                            local theme_toggle = self.Toggles and self.Toggles.ThemeManager_CustomTheme
                            local theme_color = self.Options and self.Options.ThemeManager_CustomThemeColor
                            menu.SetThemeAccent(
                                theme_toggle and theme_toggle.Value or false,
                                theme_color and theme_color.Value or Color3.fromRGB(103, 182, 254)
                            )
                        end
                    end)
                end
                if ghostMenu and type(ghostMenu.load_cfg) == "function" then
                    local ok, resultOrErr = ghostMenu.load_cfg(name)
                    if ok then
                        applyLoadedTheme()
                        -- The library only forces Hold/Toggle binds released when the config
                        -- is named literally "default" (see its applyLoadedConfigValues:
                        -- `loadName == "default"`). For any other name -- "mine" is the one
                        -- actually in use -- it restores the saved Active flag as-is, so
                        -- every binded feature came up switched on. This early-return path
                        -- used to skip our own bind release entirely, which is why the
                        -- features stayed on until a key was pressed and released.
                        pcall(cheat.release_all_binds)
                        task.spawn(function()
                            for _, step in ipairs({ 0.1, 0.4, 1.0, 2.0 }) do
                                task.wait(step)
                                pcall(cheat.release_all_binds)
                            end
                        end)
                        return true, resultOrErr
                    elseif tostring(resultOrErr) ~= "config not found" then
                        return false, resultOrErr
                    end
                end

                if type(name) ~= "string" or name == "" then
                    return false, "invalid config name"
                end
                local path = self.Folder .. "/settings/" .. name .. ".json"
                if not isfile or not isfile(path) then
                    return false, "config not found"
                end
                local ok, decoded = pcall(function()
                    return HttpService:JSONDecode(readfile(path))
                end)
                if not ok or type(decoded) ~= "table" then
                    return false, decoded
                end
                -- Apply in small batches with a pause between them. A heavy config holds
                -- hundreds of entries and every SetValue fires that feature's callback
                -- (hooks, visuals, remotes); doing it in one loop froze the client.
                local function apply_batch(list, store)
                    local pending = {}
                    for flag in pairs(list) do
                        if store[flag] and store[flag].SetValue then
                            pending[#pending + 1] = flag
                        end
                    end
                    -- Hold off until the UI has actually finished. Features must not
                    -- start coming up while the window is still being constructed.
                    local waited = 0
                    while not cheat.loading_finished and waited < 10 do
                        task.wait(0.05)
                        waited = waited + 0.05
                    end
                    if cheat.ui_ready == nil then return end

                    -- One feature per step with a 2ms pause, so the config trickles in
                    -- one feature at a time instead of switching everything on at once.
                    -- Each SetValue runs that feature's callback (hooks, visuals,
                    -- remotes) -- the expensive part we are spreading out.
                    local STEP_DELAY = 0.002
                    for i = 1, #pending do
                        local flag = pending[i]
                        local raw = list[flag]
                        pcall(function()
                            local obj = store[flag]
                            if type(raw) == "table" and raw.__kind == "Color" then
                                -- Restore the colour AND its alpha, then notify the
                                -- callback with both (function(color, alpha)).
                                local col = deserializeValue(raw.Color)
                                local alpha = tonumber(raw.Transparency) or 0
                                obj.Value = col
                                obj.Transparency = alpha
                                if obj._raw and obj._raw.set_value then
                                    pcall(function()
                                        obj._raw:set_value({ Color = col, Transparency = alpha }, true)
                                    end)
                                end
                                for _, cb in ipairs(obj._callbacks or {}) do
                                    pcall(cb, col, alpha)
                                end
                            else
                                obj:SetValue(deserializeValue(raw))
                            end
                        end)
                        if i < #pending then
                            task.wait(STEP_DELAY)
                        end
                    end
                end
                -- Validation stays synchronous so callers get a truthful result;
                -- only the heavy apply is deferred, because it yields.
                task.spawn(function()
                    local okApply, applyErr = pcall(function()
                        apply_batch(decoded.Toggles or {}, self.Toggles)
                        apply_batch(decoded.Options or {}, self.Options)
                    end)
                    if not okApply and self.Library and self.Library.Notify then
                        pcall(function()
                            self.Library:Notify("Config", "Config apply error: " .. tostring(applyErr))
                        end)
                    end
                    -- Every Hold/Toggle bind is forced RELEASED after a config load.
                    pcall(cheat.release_all_binds)
                    applyLoadedTheme()
                end)
                return true
            end

            function manager:Delete(name)
                name = cleanConfigName(name)
                if name == "Default" then
                    return false, "default config cannot be deleted"
                end
                if type(name) ~= "string" or name == "" then
                    return false, "invalid config name"
                end

                if not delfile then
                    return false, "delfile unavailable"
                end

                local paths = {
                    self.Folder .. "/settings/" .. name .. ".json",
                    self.Folder .. "/" .. name .. ".txt",
                    self.Folder .. name .. ".txt",
                }
                local deleted = false
                for _, path in ipairs(paths) do
                    if isfile and isfile(path) then
                        local ok, err = pcall(delfile, path)
                        if not ok then
                            return false, err
                        end
                        deleted = true
                    end
                end
                if not deleted then
                    return false, "config not found"
                end
                return true
            end

            function manager:LoadAutoloadConfig()
                local path = self.Folder .. "/settings/autoload.txt"
                local name
                if isfile and isfile("AutoLoadConfig") then
                    name = readfile("AutoLoadConfig")
                elseif isfile and isfile(path) then
                    name = readfile(path)
                end
                if name then
                    local normalized_name = cleanConfigName(name)
                    if normalized_name == "Default" then
                        self:Save("Default")
                        name = "Default"
                    else
                        name = normalized_name
                    end
                    local ok, err = self:Load(name)
                    if not ok then
                        -- The pointer can outlive the config it names (a saved config
                        -- gets deleted, or was never written). Falling back to the
                        -- all-off baseline is far better than leaving the menu in a
                        -- half-applied state or spamming a failure notice.
                        if name ~= "Default" then
                            local okDefault = self:Load("Default")
                            if okDefault then ok, err = true, nil end
                        end
                    end
                    if not ok and self.Library and self.Library.Notify then
                        self.Library:Notify("Config", "Failed to load autoload config: " .. tostring(err))
                    end
                end
            end

            manager:SetFolder(manager.Folder)
            return manager
        end

        local function makeThemeManager()
            local manager = {
                Folder = "GHOST_HOOK",
                Library = Library,
                Options = Options,
                Toggles = Toggles,
            }

            function manager:SetOptionsTEMP(newOptions, newToggles)
                self.Options = newOptions or self.Options
                self.Toggles = newToggles or self.Toggles
            end

            function manager:SetLibrary(lib)
                self.Library = lib
            end

            function manager:SetFolder(folder)
                self.Folder = folder or self.Folder
                ensureFolder(self.Folder)
                ensureFolder(self.Folder .. "/themes")
            end

            function manager:ApplyTheme() end
            function manager:LoadDefault() end
            function manager:SaveDefault() end

            manager:SetFolder(manager.Folder)
            return manager
        end

        return Library, Toggles, Options, makeThemeManager(), makeSaveManager()
    end

    cheat.Library, cheat.Toggles, cheat.Options, cheat.ThemeManager, cheat.SaveManager = loadGhostHookUiStack()
    Toggles = cheat.Toggles
    Options = cheat.Options
    if getgenv then
        getgenv().Toggles = cheat.Toggles
        getgenv().Options = cheat.Options
    end
    -- Purge windows left behind by previous executions BEFORE building a new one.
    -- Each past run kept a live UserInputService.InputBegan handler bound to the
    -- menu key, so without this every Ctrl press toggles the current menu *and*
    -- every stale one -- which shows up as two or more identical menus on screen.
    -- A GHOST_HOOK menu window is identifiable by having both a Base and a
    -- Notifications child; Roblox's own ScreenGuis do not match that pair.
    -- The final `true` keeps the most recent one, which some executors surface via
    -- gethui() as a container we must not destroy.
    do
        local function purge_ghost_menu_windows(keep_last)
            local parents, seen = {}, {}
            local function add(p)
                if p and not seen[p] then seen[p] = true; parents[#parents + 1] = p end
            end
            pcall(function() add(game:GetService("CoreGui")) end)
            pcall(function() if gethui then add(gethui()) end end)
            pcall(function()
                local lp = game:GetService("Players").LocalPlayer
                if lp then add(lp:FindFirstChildOfClass("PlayerGui")) end
            end)

            local found = {}
            for _, parent in ipairs(parents) do
                pcall(function()
                    for _, child in ipairs(parent:GetChildren()) do
                        if child:IsA("ScreenGui")
                            and child:FindFirstChild("Base")
                            and child:FindFirstChild("Notifications") then
                            found[#found + 1] = child
                        end
                    end
                end)
            end

            local limit = keep_last and (#found - 1) or #found
            local removed = 0
            for i = 1, limit do
                pcall(function() found[i]:Destroy() end)
                removed += 1
            end
            return removed
        end
        cheat.utility.purge_ghost_menu_windows = purge_ghost_menu_windows
        local removed = purge_ghost_menu_windows(true)
        if removed > 0 then
            print("[GHOST_HOOK] removed " .. removed .. " stale menu window(s) from a previous execution")
        end
    end

    ui = {
        window = cheat.Library:CreateWindow({
            Title="GHOST_HOOK | Project Delta |",
        Center=true,AutoShow=false,TabPadding=8})
    }
    task.spawn(function()
        local timerText = ghostGetKeyTimerText()
        local expired = ghostFormatKeyTimeLeft() == "Expired"

        for _ = 1, 40 do
            if ghostCreateKeyStatusOverlay(timerText, expired) then
                break
            end
            task.wait(0.05)
        end
    end)
    if cheat.Library and cheat.Library.SetOpen then
        cheat.Library:SetOpen(false)
    end
    end
    local globals = {
        fov_enabled = false,
        zoom_enabled = false,
        EnableTime = false,
        Time = 12,
        noshadows = false,
        gradientenabled = false,
    }
    ui.tabs = {
        combat = ui.window:AddTab('Combat'),
        visuals = ui.window:AddTab('Visuals'),
        movement = ui.window:AddTab('Movement'),
        player = ui.window:AddTab('Player'),
        world = ui.window:AddTab('World'),
        misc = ui.window:AddTab('Misc'),
        settings = ui.window:AddTab('Settings'),
    }
    ui.box = {
        -- Combat tab
        aimbot = ui.tabs.combat:AddLeftTabbox(),
        mods = ui.tabs.combat:AddRightTabbox(),

        -- Visuals tab
        esp = ui.tabs.visuals:AddLeftTabbox(),
        object_esp = ui.tabs.visuals:AddRightTabbox(),

        -- Movement tab
        move = ui.tabs.movement:AddLeftTabbox(),
        move_extra = ui.tabs.movement:AddRightTabbox(),

        -- Player tab
        player = ui.tabs.player:AddLeftTabbox(),
        player_extra = ui.tabs.player:AddRightTabbox(),

        -- World tab
        world = ui.tabs.world:AddLeftTabbox(),
        world_effects = ui.tabs.world:AddRightTabbox(),

        -- Misc tab
        antiaim = ui.tabs.misc:AddLeftTabbox(),
        misc = ui.tabs.misc:AddLeftTabbox(),
        misc_sounds = ui.tabs.misc:AddRightTabbox(),

        -- Settings tab
        config = ui.tabs.settings:AddLeftGroupbox('Config'),
        client = ui.tabs.settings:AddLeftGroupbox('Client'),
        crosshair = ui.tabs.settings:AddLeftTabbox(),
        script = ui.tabs.settings:AddRightGroupbox('Script Control'),
        themes = ui.tabs.settings:AddRightGroupbox('Themes'),
        keybinds = ui.tabs.settings:AddRightGroupbox('Key Binds'),
        detection = ui.tabs.settings:AddRightGroupbox('Detection'),
        npc = ui.tabs.settings:AddRightGroupbox('Npc'),
    }
    local player_viewmodel_tab = ui.box.player:AddTab("ViewModel")
    local player_anti_aim_tab = ui.box.player:AddTab("Anti Aim")
    local player_camera_tab = ui.box.player_extra:AddTab("Camera")
    -- The "Fake Lag" tab is gone. Its remaining anti-aim/utility controls now live
    -- in the Anti Aim tab; its own fake-lag + server-position visualiser were removed.
    local player_fake_lag_tab = player_anti_aim_tab
    local world_radar_tab = ui.box.world_effects:AddTab("Radar")
    local world_thirdperson_tab = ui.box.world_effects:AddTab("Third Person")
    local world_performance_tab = ui.box.world_effects:AddTab("Performance")
    local world_inventory_tab = ui.box.world_effects:AddTab("Inventory / Finder")
    local world_freecam_tab = ui.box.world:AddTab("Freecam")
    local custom_sound_tab = ui.box.misc_sounds:AddTab("Custom Hit/Shoot Sounds")
    local effects_tab = ui.box.misc_sounds:AddTab("Effects")
    -- The right-hand Player box needs its own label, otherwise both sides of the
    -- Player tab read "Player" and the right one is indistinguishable.
    pcall(function() ui.box.player_extra:AddLabel("Player") end)
    local settings_skinchanger_box = ui.tabs.settings:AddRightGroupbox('Skin Changer')
    local function keybind_allows(key_flag, require_assigned)
        local option = cheat.Options and cheat.Options[key_flag]
        -- A MISSING bind element must never count as "allowed". This used to return true,
        -- so a feature whose bind does not exist (nil) ran freely -- the toggle alone
        -- switched it on and the bind was never consulted.
        if not option then return false end

        -- Read the LIVE library element rather than our cached copy. Restoring a config
        -- calls the library's keybind:set_value(value, "load"), which updates the element
        -- but DELIBERATELY skips its keyCallback (see its `elseif not cb then
        -- keyCallback(...)`), so our cached Key/Mode/Active keep their creation defaults
        -- -- the bind showed NONE/Toggle and its saved key/mode were ignored.
        local value = option.Value
        if option._raw and option._raw.get_value then
            local okLive, live = pcall(function() return option._raw:get_value() end)
            if okLive and type(live) == "table" then
                value = live
                option.Value = live
            end
        end
        local key = option.Key
        local mode = option.Mode
        local active = option.State
        if type(value) == "table" then
            key = value.Key or key
            mode = value.Type or value.Mode or mode
            -- Must be an explicit if, NOT `value.Active ~= nil and value.Active or active`:
            -- when value.Active is false that idiom collapses to the fallback and keeps the
            -- stale option.State, so a RELEASED bind still read as active and its feature
            -- came up switched on at load.
            if value.Active ~= nil then
                active = value.Active
            end
        end

        -- A nil key means the bind was never initialised (a genuinely nil value) -- keep
        -- the feature OFF. "None"/"" is the deliberate "no key chosen" state, which is
        -- handled below. Distinguishing the two before tostring() is the whole point:
        -- after `tostring(key or "None")` a nil and a real "None" are indistinguishable.
        if key == nil then return false end

        key = tostring(key or "None")
        if key == "" or key == "None" or key == "NONE" then
            -- The DELIBERATE "no key chosen" state (a genuinely missing key already
            -- returned false above). Returning false unconditionally here -- as this
            -- briefly did -- turned every bind-gated feature inert until a key was
            -- assigned, so TP Kill (whose config stores Key = "None") could never
            -- activate at all. Strictness is opt-in per caller via require_assigned.
            if mode == "Always" then return true end
            return require_assigned ~= true
        end

        if mode == "Always" then return true end

        -- HOLD binds are judged by the PHYSICAL key, not by the library's Active flag.
        -- Loading a config calls the library's keybind:set_value(..., "load"), which
        -- rebinds the key and can leave Active reported as held -- so a Hold-bind feature
        -- (flyhack, noclip, bunnyhop, xray) behaved as if the key were pressed down from
        -- the moment the script loaded. Reading UserInputService directly cannot lie.
        if mode == "Hold" then
            local ok, enumKey = pcall(function() return Enum.KeyCode[key] end)
            if ok and enumKey then
                local down = false
                pcall(function() down = UserInputService:IsKeyDown(enumKey) end)
                -- Gamepad / mouse binds fall back to the library's own state.
                return down == true or active == true
            end
            return active == true
        end

        return active == true
    end

    local function keybind_is_always(key_flag)
        local option = cheat.Options and cheat.Options[key_flag]
        if not option then return false end

        local value = option.Value
        local mode = option.Mode
        if type(value) == "table" then
            mode = value.Type or value.Mode or mode
        end

        return mode == "Always"
    end

    local function feature_active(enabled, key_flag, allow_always_without_toggle, require_assigned)
        -- A bind is OPTIONAL. The toggle is the master switch, so with no key assigned
        -- the toggle alone controls the feature; once a key IS assigned the bind also
        -- gates it (Hold must be held, Toggle must be toggled on). Defaulting this to
        -- true made every feature inert until its bind was assigned.
        if require_assigned == nil then require_assigned = false end
        local master_enabled = enabled or (allow_always_without_toggle and keybind_is_always(key_flag))
        return master_enabled and keybind_allows(key_flag, require_assigned)
    end

    -- Force every Hold/Toggle bind into the RELEASED state. A bind is only a held
    -- modifier; if it restores "active" its feature comes up running before the user
    -- pressed anything. Called on a few timers after startup and after a config load.
    --
    -- CRITICAL: Key and Mode are read from the LIVE library element, never from our own
    -- cache. After a config load the library updates the element but deliberately skips
    -- its keyCallback, so our cached obj.Key/obj.Mode still hold the creation defaults
    -- ("None"/"Toggle"). Writing those back here used to overwrite the restored keybind
    -- in the element AND in menu.values, so the saved key and mode were destroyed on
    -- every load and the loss was then persisted by the next save.
    function cheat.release_all_binds()
        for _, obj in pairs(cheat.Options or {}) do
            if type(obj) == "table" and obj.Mode and obj.Mode ~= "Always" then
                obj.Active = false
                obj.State = false
                if type(obj.Value) == "table" then
                    obj.Value.Active = false
                end
                if obj._raw and obj._raw.set_value then
                    local liveKey, liveMode
                    if obj._raw.get_value then
                        local okLive, live = pcall(function() return obj._raw:get_value() end)
                        if okLive and type(live) == "table" then
                            liveKey = live.Key
                            liveMode = live.Type or live.Mode
                        end
                    end
                    -- Fall back to the cache only if the element has no get_value.
                    liveKey = liveKey or obj.Key
                    liveMode = liveMode or obj.Mode
                    -- refresh our cache so every other reader (the Key Binds list, the
                    -- feature gate) sees the restored key and mode too
                    obj.Key = liveKey
                    obj.Mode = liveMode
                    if type(obj.Value) == "table" then
                        obj.Value.Key = liveKey
                        obj.Value.Type = liveMode
                    end
                    pcall(function()
                        obj._raw:set_value({ Key = liveKey, Type = liveMode, Active = false }, true)
                    end)
                end
            end
        end
    end

    cheat._game_inventory_preview_cache = cheat._game_inventory_preview_cache or {
        last_check = 0,
        active = false,
    }
    local function gui_object_visible(object)
        local current = object
        while current do
            if current:IsA("GuiObject") and not current.Visible then
                return false
            end
            current = current.Parent
        end
        return true
    end
    cheat.utility.is_game_inventory_preview_open = function()
        local cache = cheat._game_inventory_preview_cache
        local now = os.clock()
        if now - cache.last_check < 0.08 then
            return cache.active
        end

        cache.last_check = now
        cache.active = false

        local player_gui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
        local main_gui = player_gui and _FindFirstChild(player_gui, "MainGui")
        local backpack = main_gui and _FindFirstChild(main_gui, "BackpackFrame", true)
        if not (backpack and backpack:IsA("GuiObject") and gui_object_visible(backpack)) then
            return false
        end

        local character_frame = _FindFirstChild(backpack, "CharacterFrame", true)
        if not (character_frame and character_frame:IsA("GuiObject") and gui_object_visible(character_frame)) then
            return false
        end

        local appearance = _FindFirstChild(character_frame, "Apparance", true) or _FindFirstChild(character_frame, "Appearance", true)
        local viewport = appearance and appearance:FindFirstChildWhichIsA("ViewportFrame", true)
            or character_frame:FindFirstChildWhichIsA("ViewportFrame", true)
        cache.active = viewport and gui_object_visible(viewport) or false
        return cache.active
    end

    cheat.utility.create_keybind_indicator = function()
        if cheat.keybind_indicator then return cheat.keybind_indicator end

        local indicator = {
            max_rows = 16,
            pos = _Vector2new(30, 40),
            width = 235,
            height = 24,
            dragging = false,
            dragoffset = _Vector2new(0, 0),
        }
        indicator.bg = cheat.utility.new_drawing("Square", {
            Visible = false,
            Filled = true,
            Color = Color3.fromRGB(0, 0, 0),
            Transparency = 0.72,
            ZIndex = 200,
        })
        indicator.border = cheat.utility.new_drawing("Square", {
            Visible = false,
            Filled = false,
            Color = Color3.fromRGB(75, 75, 75),
            Thickness = 1,
            Transparency = 1,
            ZIndex = 201,
        })
        indicator.title = cheat.utility.new_drawing("Text", {
            Visible = false,
            Text = "Keybinds",
            Size = 15,
            Font = Drawing.Fonts.Monospace,
            Color = Color3.fromRGB(255, 255, 255),
            Outline = true,
            ZIndex = 202,
        })
        indicator.rows = {}
        for i = 1, indicator.max_rows do
            indicator.rows[i] = cheat.utility.new_drawing("Text", {
                Visible = false,
                Text = "",
                Size = 14,
                Font = Drawing.Fonts.Monospace,
                Color = Color3.fromRGB(210, 210, 210),
                Outline = true,
                ZIndex = 202,
            })
        end

        local function format_keybind_key(key)
            key = tostring(key or "None")
            key = key:gsub("^Enum%.KeyCode%.", "")
            key = key:gsub("^Enum%.UserInputType%.", "")
            key = key:gsub("^MouseButton(%d+)$", "MB%1")
            return key
        end

        cheat.utility.new_renderstepped(function()
            local visible = cheat.keybind_indicator_enabled and not cheat.unloaded
            if not visible then
                if indicator.bg.Visible then indicator.bg.Visible = false end
                if indicator.border.Visible then indicator.border.Visible = false end
                if indicator.title.Visible then indicator.title.Visible = false end
                for i = 1, indicator.max_rows do
                    if indicator.rows[i].Visible then
                        indicator.rows[i].Visible = false
                    end
                end
                indicator.dragging = false
                return
            end

            local entries = {}
            local widest = 0
            for flag, option in pairs(cheat.Options or {}) do
                if option and option._kind == "Keybind" then
                    local value = option.Value
                    local key = option.Key
                    local mode = option.Mode
                    local active = option.State
                    if type(value) == "table" then
                        key = value.Key or key
                        mode = value.Type or mode
                        if value.Active ~= nil then
                            active = value.Active
                        end
                    end
                    if mode == "Always" then
                        active = true
                    end
                    key = tostring(key or "None")
                    local has_key = key ~= "" and key ~= "None" and key ~= "NONE"
                    -- Show every bind from startup, not only ones that already have a key set
                    local label = option.Text or option._flag or flag
                    local formatted_key = has_key and format_keybind_key(key) or "-"
                    local state_text = active and "on" or tostring(mode or "Hold")
                    local text = tostring(label) .. " [" .. formatted_key .. "] - " .. state_text
                    widest = math.max(widest, #text)
                    table.insert(entries, {
                        text = text,
                        active = active and true or false,
                    })
                end
            end
            table.sort(entries, function(a, b) return a.text < b.text end)

            local count = math.min(#entries, indicator.max_rows)
            local row_height = 16
            local height = 24 + (count * row_height)
            local width = math.max(indicator.width, 16 + (widest * 8))
            indicator.height = height

            if visible and cheat.Library.Opened then
                local mousepos = _Vector2new(Mouse.X, Mouse.Y + GuiInset.Y)
                local in_bounds = mousepos.X >= indicator.pos.X
                    and mousepos.X <= indicator.pos.X + width
                    and mousepos.Y >= indicator.pos.Y
                    and mousepos.Y <= indicator.pos.Y + height
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    if in_bounds or indicator.dragging then
                        if not indicator.dragging then
                            indicator.dragging = true
                            indicator.dragoffset = indicator.pos - mousepos
                        end
                        indicator.pos = mousepos + indicator.dragoffset
                    end
                else
                    indicator.dragging = false
                end
            else
                indicator.dragging = false
            end

            indicator.bg.Visible = visible
            indicator.border.Visible = visible
            indicator.title.Visible = visible
            indicator.bg.Position = indicator.pos
            indicator.bg.Size = _Vector2new(width, height)
            indicator.border.Position = indicator.pos
            indicator.border.Size = _Vector2new(width, height)
            indicator.title.Position = indicator.pos + _Vector2new(8, 4)
            for i = 1, indicator.max_rows do
                local row = indicator.rows[i]
                local entry = entries[i]
                row.Visible = visible and entry ~= nil
                if entry then
                    row.Text = entry.text
                    row.Color = entry.active and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(210, 210, 210)
                    row.Position = indicator.pos + _Vector2new(8, 20 + (i - 1) * row_height)
                end
            end
        end)

        cheat.keybind_indicator = indicator
        return indicator
    end
    cheat.EspLibrary = {} LPH_NO_VIRTUALIZE(function()
        local esp_table = {}
        local workspace = cloneref(Workspace)
        local rservice = cloneref(RunService)
        local plrs = cloneref(Players)
        local lplr = plrs.LocalPlayer
        local success, coregui = pcall(game.GetService, game, "CoreGui")
        local container = cheat.utility.track_instance(Instance.new("Folder", (success and coregui:FindFirstChild("RobloxGui")) or lplr:WaitForChild("PlayerGui")))
        esp_table = {
            __loaded = false,
            main_settings = {
                textSize = 15,
                textFont = Drawing.Fonts.Monospace,
                distancelimit = false,
                maxdistance = 5000,
                fadetime = 1,
                infiniterange = false
            },
            main_object_settings = {
                textSize = 15,
                textFont = Drawing.Fonts.Monospace,
                distancelimit = false,
                maxdistance = 200,
                useteamcolor = false,
                teamcheck = false,
                sleepcheck = false,
                allowed = {}
            },
            settings = {
                enemy = {
                    enabled = false,
                    box = false,
                    box_fill = false,
                    realname = false,
                    displayname = false,
                    health = false,
                    dist = false,
                    weapon = false,
                    skeleton = false,
                    box_outline = false,
                    realname_outline = false,
                    displayname_outline = false,
                    health_outline = false,
                    dist_outline = false,
                    weapon_outline = false,
                    box_color = { Color3.new(1, 1, 1), 1 },
                    box_fill_color = { Color3.new(1, 0, 0), 0.5 },
                    realname_color = { Color3.new(1, 1, 1), 1 },
                    displayname_color = { Color3.new(1, 1, 1), 1 },
                    health_color = { Color3.new(1, 1, 1), 1 },
                    dist_color = { Color3.new(1, 1, 1), 1 },
                    weapon_color = { Color3.new(1, 1, 1), 1 },
                    skeleton_color = { Color3.new(1, 1, 1), 1 },
                    box_outline_color = { Color3.new(), 1 },
                    realname_outline_color = Color3.new(),
                    displayname_outline_color = Color3.new(),
                    health_color_top = Color3.new(0, 1, 0),
                    health_color_bottom = Color3.new(1, 0, 0),
                    health_thickness = 2,
                    health_glow_size = 5,
                    dist_outline_color = Color3.new(),
                    weapon_outline_color = Color3.new(),
                    box_outline_vis = false,
                    realname_outline_vis = false,
                    displayname_outline_vis = false,
                    dist_outline_vis = false,
                    weapon_outline_vis = false,
                    box_outline_vis_color = { Color3.new(), 1 },
                    realname_outline_vis_color = Color3.new(),
                    displayname_outline_vis_color = Color3.new(),
                    dist_outline_vis_color = Color3.new(),
                    weapon_outline_vis_color = Color3.new(),
                    chams = false,
                    chams_visible_only = false,
                    chams_hidden = true,
                    chams_visible = false,
                    cham_color = Color3.fromRGB(255, 255, 255),
                    cham_transparency = 0.5,
                    chams_fill_color = { Color3.new(1, 1, 1), 0.5 },
                    chams_visible_color = { Color3.new(1, 1, 1), 0.5 },
                    chams_hidden_color = { Color3.new(1, 1, 1), 0.5 },
                    high_kd_marker = false,
                    high_kd_outline_color = Color3.fromRGB(255, 0, 0),
                    high_kd_chams_transparency = 0.15,
                },
                corpse = {
                    enabled = false,
                    name = true,
                    distance = false,
                    color = Color3.fromRGB(0, 255, 0),
                    outline = false,
                    outline_color = Color3.new()
                }
            }
        }
        local loaded_plrs = {}
        local camera = workspace.CurrentCamera
        local viewportsize = camera.ViewportSize
        local VERTICES = {
            _Vector3new(-1, -1, -1),
            _Vector3new(-1, 1, -1),
            _Vector3new(-1, 1, 1),
            _Vector3new(-1, -1, 1),
            _Vector3new(1, -1, -1),
            _Vector3new(1, 1, -1),
            _Vector3new(1, 1, 1),
            _Vector3new(1, -1, 1)
        }
        local skeleton_order = {
            ["LeftFoot"] = "LeftLowerLeg",
            ["LeftLowerLeg"] = "LeftUpperLeg",
            ["LeftUpperLeg"] = "LowerTorso",
            ["RightFoot"] = "RightLowerLeg",
            ["RightLowerLeg"] = "RightUpperLeg",
            ["RightUpperLeg"] = "LowerTorso",
            ["LeftHand"] = "LeftLowerArm",
            ["LeftLowerArm"] = "LeftUpperArm",
            ["LeftUpperArm"] = "UpperTorso",
            ["RightHand"] = "RightLowerArm",
            ["RightLowerArm"] = "RightUpperArm",
            ["RightUpperArm"] = "UpperTorso",
            ["LowerTorso"] = "UpperTorso",
            ["UpperTorso"] = "Head"
        }
        local esp = {}
        esp.create_obj = function(type, args)
            local obj = Drawing.new(type)
            for i, v in args do
                obj[i] = v
            end
            return obj
        end
        local function isBodyPart(name)
            return name == "Head" or name:find("Torso") or name:find("Leg") or name:find("Arm") or name:find("Mi24") or name:find("Prop_") or name:find("Hull") or name:find("BTR") or name:find("Pilot")
        end
        local function getBoundingBox(parts)
            local min, max
            for i = 1, #parts do
                local part = parts[i]
                local cframe, size = part.CFrame, part.Size
                min = _Vector3zeromin(min or cframe.Position, (cframe - size * 0.5).Position)
                max = _Vector3zeromax(max or cframe.Position, (cframe + size * 0.5).Position)
            end
            local center = (min + max) * 0.5
            local front = _Vector3new(center.X, center.Y, max.Z)
            return _CFramenew(center, front), max - min
        end
        local function worldToScreen(world)
            local screen, inBounds = _WorldToViewportPoint(camera, world)
            return _Vector2new(screen.X, screen.Y), inBounds, screen.Z
        end
        local function calculateCorners(cframe, size)
            local corners = table.create(#VERTICES)
            for i = 1, #VERTICES do
                corners[i] = worldToScreen((cframe + size * 0.5 * VERTICES[i]).Position)
            end
            local min = _Vector2zeromin(camera.ViewportSize, unpack(corners))
            local max = _Vector2zeromax(Vector2.zero, unpack(corners))
            return {
                corners = corners,
                topLeft = _Vector2new(mathfloor(min.X), mathfloor(min.Y)),
                topRight = _Vector2new(mathfloor(max.X), mathfloor(min.Y)),
                bottomLeft = _Vector2new(mathfloor(min.X), mathfloor(max.Y)),
                bottomRight = _Vector2new(mathfloor(max.X), mathfloor(max.Y))
            }
        end
        local get_mainpart = function(model, modelname)
            if modelname == "corpse" then
                return _FindFirstChild(model, "UpperTorso")
            end
        end
        local identify_model = function(model, modelname)
            if not model then return false, false end
            if modelname == "corpse" and _FindFirstChildOfClass(model, "Humanoid") then
                return model.Name.."'s corpse"
            end
            return false, false
        end
        local ghost_chams_template = Instance.new("Highlight")
        local function remove_ghost_player_chams(character)
            if not character then return end
            local visible = character:FindFirstChild("HighlightVisible")
            local hidden = character:FindFirstChild("HighlightHidden")
            if visible then visible:Destroy() end
            if hidden then hidden:Destroy() end
        end
        function esp_table.update_player_chams(player, enabled)
            if not player then return end
            if typeof(player) ~= "Instance" then return end

            local character
            if player:IsA("Player") then
                if player == lplr then return end
                character = player.Character
            elseif player:IsA("Model") then
                if player.Name == "MI24V" then return end
                local dropped = workspace:FindFirstChild("DroppedItems")
                if dropped and player:IsDescendantOf(dropped) then
                    remove_ghost_player_chams(player)
                    return
                end
                character = player
            else
                return
            end
            if not character then return end

            local settings = esp_table.settings.enemy
            if not (enabled and settings.enabled and settings.chams) then
                remove_ghost_player_chams(character)
                return
            end

            local plr_state = loaded_plrs[player]
            local high_kd_chams = settings.high_kd_marker and plr_state and plr_state._kd_is_cheater
            local cham_color = high_kd_chams and settings.high_kd_outline_color or settings.cham_color or (settings.chams_hidden_color and settings.chams_hidden_color[1]) or Color3.new(1, 1, 1)
            local cham_transparency = settings.cham_transparency
            if cham_transparency == nil then
                cham_transparency = 0.5
            end
            if high_kd_chams then
                cham_transparency = settings.high_kd_chams_transparency or cham_transparency
            end

            local visible = character:FindFirstChild("HighlightVisible")
            if settings.chams_visible then
                if not visible then
                    visible = ghost_chams_template:Clone()
                    visible.Name = "HighlightVisible"
                    visible.Parent = character
                end
                visible.FillColor = cham_color
                visible.OutlineColor = cham_color
                visible.FillTransparency = cham_transparency
                visible.OutlineTransparency = 0
                visible.DepthMode = Enum.HighlightDepthMode.Occluded
            elseif visible then
                visible:Destroy()
            end

            local hidden = character:FindFirstChild("HighlightHidden")
            if settings.chams_hidden then
                if not hidden then
                    hidden = ghost_chams_template:Clone()
                    hidden.Name = "HighlightHidden"
                    hidden.Parent = character
                end
                hidden.FillColor = cham_color
                hidden.OutlineColor = cham_color
                hidden.FillTransparency = cham_transparency
                hidden.OutlineTransparency = 0
                hidden.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            elseif hidden then
                hidden:Destroy()
            end
        end
        local function create_esp(player, isnpc)
            if not player then return end
            if player.ClassName == "Model" then isnpc = true end
            loaded_plrs[player] = {
                obj = {
                    box_fill = esp.create_obj("Square", { Filled = true, Visible = false }),
                    box_outline = esp.create_obj("Square", { Filled = false, Thickness = 3, Visible = false, ZIndex = -1 }),
                    box = esp.create_obj("Square", { Filled = false, Thickness = 1, Visible = false }),
                    realname = esp.create_obj("Text", { Center = true, Visible = false, Text = player.Name }),
                    displayname = esp.create_obj("Text", { Center = true, Visible = false, Text = isnpc and "" or player.Name == player.DisplayName and "" or player.DisplayName }),
                    healthtext = esp.create_obj("Text", { Center = false, Visible = false }),
                    health_bar_cap_top = esp.create_obj("Circle", { Visible = false, Filled = true, ZIndex = 2 }),
                    health_bar_cap_bottom = esp.create_obj("Circle", { Visible = false, Filled = true, ZIndex = 2 }),
                    dist = esp.create_obj("Text", { Center = true, Visible = false }),
                    weapon = esp.create_obj("Text", { Center = true, Visible = false }),
                },
                plr_instance = player
            }
            for required, _ in next, skeleton_order do
                loaded_plrs[player].obj["skeleton_" .. required] = esp.create_obj("Line", { Visible = false })
            end
            for i = 1, 10 do
                loaded_plrs[player].obj["health_bar_" .. i] = esp.create_obj("Line", { Visible = false, Thickness = 2, ZIndex = 2 })
            end
            for i = 1, 6 do
                loaded_plrs[player].obj["health_bar_glow_" .. i] = esp.create_obj("Line", { Visible = false, ZIndex = 1 })
                loaded_plrs[player].obj["health_bar_glow_cap_top_" .. i] = esp.create_obj("Circle", { Visible = false, Filled = true, ZIndex = 1 })
                loaded_plrs[player].obj["health_bar_glow_cap_bottom_" .. i] = esp.create_obj("Circle", { Visible = false, Filled = true, ZIndex = 1 })
            end
            local plr = loaded_plrs[player]
            local obj = plr.obj
            local esp = plr.esp
            local box = obj.box
            local box_outline = obj.box_outline
            local box_fill = obj.box_fill
            local healthtext = obj.healthtext
            local realname = obj.realname
            local displayname = obj.displayname
            local dist = obj.dist
            local weapon = obj.weapon
            local settings = esp_table.settings.enemy
            local main_settings = esp_table.main_settings
            local character = isnpc and player or not isnpc and player.Character
            local head = character and _FindFirstChild(character, "Head")
            local humanoid = character and _FindFirstChildOfClass(character, "Humanoid")
            local setvis_cache = false
            local fadetime = main_settings.fadetime
            local fadethread
            function plr:forceupdate()
                fadetime = main_settings.fadetime
                esp_table.update_player_chams(player, settings.enabled and settings.chams)
                box.Color = settings.box_color[1]
                box_outline.Color = settings.box_outline_color[1]
                box_fill.Color = settings.box_fill_color[1]
                realname.Size = main_settings.textSize
                realname.Font = main_settings.textFont
                realname.Color = settings.realname_color[1]
                realname.Outline = settings.realname_outline
                realname.OutlineColor = settings.realname_outline_color
                displayname.Size = main_settings.textSize
                displayname.Font = main_settings.textFont
                displayname.Color = settings.displayname_color[1]
                displayname.Outline = settings.displayname_outline
                displayname.OutlineColor = settings.displayname_outline_color
                dist.Size = main_settings.textSize
                dist.Font = main_settings.textFont
                dist.Color = settings.dist_color[1]
                dist.Outline = settings.dist_outline
                dist.OutlineColor = settings.dist_outline_color
                weapon.Size = main_settings.textSize
                weapon.Font = main_settings.textFont
                weapon.Color = settings.weapon_color[1]
                weapon.Outline = settings.weapon_outline
                weapon.OutlineColor = settings.weapon_outline_color
                for required, _ in next, skeleton_order do
                    local skeletonobj = obj["skeleton_" .. required]
                    if skeletonobj then
                        skeletonobj.Color = settings.skeleton_color[1]
                    end
                end
                box.Transparency = settings.box_color[2]
                box_outline.Transparency = settings.box_outline_color[2]
                box_fill.Transparency = settings.box_fill_color[2]
                realname.Transparency = settings.realname_color[2]
                displayname.Transparency = settings.displayname_color[2]
                dist.Transparency = settings.dist_color[2]
                weapon.Transparency = settings.weapon_color[2]
                for required, _ in next, skeleton_order do
                    obj["skeleton_" .. required].Transparency = settings.skeleton_color[2]
                end

                for i = 1, 10 do
                    if obj["health_bar_"..i] then
                        obj["health_bar_"..i].Thickness = settings.health_thickness
                    end
                end
                if setvis_cache then
                    esp_table.update_player_chams(player, true)
                    box.Visible = false
                    box_outline.Visible = false
                    box_fill.Visible = false
                    realname.Visible = settings.realname
                    displayname.Visible = settings.displayname
                    obj.health_bar_cap_top.Visible = settings.health
                    obj.health_bar_cap_bottom.Visible = settings.health
                    for i = 1, 6 do
                        if obj["health_bar_glow_"..i] then 
                            obj["health_bar_glow_"..i].Visible = settings.health
                            obj["health_bar_glow_cap_top_"..i].Visible = settings.health
                            obj["health_bar_glow_cap_bottom_"..i].Visible = settings.health
                        end
                    end
                    for i = 1, 10 do
                        if obj["health_bar_"..i] then
                            obj["health_bar_"..i].Visible = settings.health
                        end
                    end
                    dist.Visible = settings.dist
                    weapon.Visible = settings.weapon
                    for required, _ in next, skeleton_order do
                        local skeletonobj = obj["skeleton_" .. required]
                        if (skeletonobj) then
                            skeletonobj.Visible = settings.skeleton
                        end
                    end
                end
            end
            function plr:togglevis(bool, fade)
                if setvis_cache ~= bool then
                    setvis_cache = bool
                    if not bool then
                            for _, v in obj do v.Visible = false end
                    else
                        esp_table.update_player_chams(player, true)
                        box.Visible = false
                        box_outline.Visible = false
                        box_fill.Visible = false
                        realname.Visible = settings.realname
                        displayname.Visible = settings.displayname
                        healthtext.Visible = false -- disabled for neon bar
                        obj.health_bar_cap_top.Visible = settings.health
                        obj.health_bar_cap_bottom.Visible = settings.health
                        for i = 1, 6 do
                            if obj["health_bar_glow_"..i] then 
                                obj["health_bar_glow_"..i].Visible = settings.health
                                obj["health_bar_glow_cap_top_"..i].Visible = settings.health
                                obj["health_bar_glow_cap_bottom_"..i].Visible = settings.health
                            end
                        end
                        for i = 1, 10 do
                            obj["health_bar_"..i].Visible = settings.health
                        end
                        dist.Visible = settings.dist
                        weapon.Visible = settings.weapon
                        for required, _ in next, skeleton_order do
                            local skeletonobj = obj["skeleton_" .. required]
                            if (skeletonobj) then
                                skeletonobj.Visible = settings.skeleton
                            end
                        end
                    end
                end
            end
            plr.connection = cheat.utility.new_renderstepped(function(delta)
                local plr = loaded_plrs[player]

                -- Damage Numbers / kill effect are their OWN features, so the health
                -- tracking runs BEFORE the ESP visibility gate below. In pin.reta V2 this
                -- block sat AFTER `if not settings.enabled then return end`, so damage
                -- numbers silently required ESP to be switched on. The detection itself is
                -- V2's: a health drop on a target, attributed to us only when a hitmarker
                -- sound landed within the last 0.25s.
                character = isnpc and player or not isnpc and player.Character
                humanoid = character and _FindFirstChildOfClass(character, "Humanoid")
                head = character and _FindFirstChild(character, "Head")
                if isnpc and character and (character.Name == "MI24V" or character.Name == "BTR80") then
                    head = character:FindFirstChild("CollisionPilot", true) or character:FindFirstChild("Mi24_Prop_M", true)
                    humanoid = humanoid or { Health = character:GetAttribute("Health") or 1000, MaxHealth = 1000, Parent = character }
                end
                if character and character.Parent and humanoid and head then
                    local dmg_now = os.clock()
                    if not plr._next_dmg_check or dmg_now >= plr._next_dmg_check then
                        plr._next_dmg_check = dmg_now + 0.05
                        local hp = humanoid.Health
                        if plr.last_health and hp < plr.last_health then
                            local hitmarker_recent = cheat.utility.last_hitmarker_tick
                                and (tick() - cheat.utility.last_hitmarker_tick < 0.25)
                            if hitmarker_recent then
                                local dmg = plr.last_health - hp
                                if cheat.Toggles.killeffect and cheat.Toggles.killeffect.Value then
                                    pcall(function() cheat.utility.spawn_kill_effect(head.Position) end)
                                end
                                if cheat.damagenumbers_enabled
                                    or (cheat.Toggles.damagenumbers and cheat.Toggles.damagenumbers.Value) then
                                    if cheat.utility.spawn_damage_number then
                                        pcall(function() cheat.utility.spawn_damage_number(head.Position, dmg) end)
                                    end
                                end
                            end
                        end
                        plr.last_health = hp
                    end
                end

                if not settings.enabled then
                    if not plr._esp_disabled then
                        esp_table.update_player_chams(player, false)
                        plr:togglevis(false)
                        plr._esp_disabled = true
                    end
                    return
                end
                plr._esp_disabled = false
                character = isnpc and player or not isnpc and player.Character
                humanoid = character and _FindFirstChildOfClass(character, "Humanoid")
                head = character and _FindFirstChild(character, "Head")
                
                local is_heli = isnpc and (character.Name == "MI24V" or character.Name == "BTR80")
                if is_heli then
                    local pilots = _FindFirstChild(character, "Pilots")
                    head = character:FindFirstChild("CollisionPilot", true) or character:FindFirstChild("Mi24_Prop_M", true)
                    humanoid = humanoid or { Health = character:GetAttribute("Health") or 1000, MaxHealth = 1000, Parent = character }
                end

                local dropped_folder = workspace:FindFirstChild("DroppedItems")
                if dropped_folder and character and character:IsDescendantOf(dropped_folder) then
                    esp_table.update_player_chams(player, false)
                    return plr:togglevis(false)
                end
                
                if not (character and head and humanoid and character.Parent and (head.Parent or is_heli) and (humanoid.Parent or is_heli)) then
                    esp_table.update_player_chams(player, false)
                    if main_settings.infiniterange and not isnpc then
                        local res = (function()
                            local rp_plr = _FindFirstChild(ReplicatedStorage.Players, player.Name)
                            local plrstatus = rp_plr and _FindFirstChild(rp_plr, "Status")
                            local worldpos = plrstatus and _FindFirstChild(plrstatus, "UAC") and _FindFirstChild(plrstatus, "UAC"):GetAttribute("LastVerifiedPos")
                            local screenpos, onscreen = typeof(worldpos) == "Vector3" and worldToScreen(worldpos)
                            if not (onscreen) then return false end
                            realname.Position = screenpos
                            realname.Text = player.Name .. " ["..mathround((worldpos - camera.CFrame.p).Magnitude / 3).."]"
                            return true
                        end)();
                        plr:togglevis(false)
                        realname.Visible = res
                        return
                    else
                        realname.Visible = false
                        return plr:togglevis(false)
                    end
                end
                local _, onScreen = _WorldToViewportPoint(camera, head.Position)
                if not onScreen then
                    esp_table.update_player_chams(player, true)
                    return plr:togglevis(false)
                end
                local humanoid_distance = (camera.CFrame.p - head.Position).Magnitude
                if main_settings.distancelimit and humanoid_distance > main_settings.maxdistance then
                    esp_table.update_player_chams(player, true)
                    return plr:togglevis(false)
                end
                local frame_now = os.clock()
                local update_interval = settings.skeleton and (1 / 30) or (humanoid_distance < 300 and (1 / 45) or humanoid_distance < 900 and (1 / 24) or (1 / 15))
                if plr._next_esp_update and frame_now < plr._next_esp_update then
                    return
                end
                plr._next_esp_update = frame_now + update_interval
                local humanoid_health = humanoid.Health

                if humanoid_health <= 0 then
                    if not plr.was_dead then
                        plr.was_dead = true
                    end
                    esp_table.update_player_chams(player, false)
                    return plr:togglevis(false)
                else
                    plr.was_dead = false
                end
                local humanoid_max_health = humanoid.MaxHealth
                local corners do
                    if plr.last_character ~= character then
                        if plr.last_character then
                            remove_ghost_player_chams(plr.last_character)
                        end
                        plr.last_character = character
                        plr.body_parts = {}
                        plr._skel_parts = nil
                        remove_ghost_player_chams(character)
                        local check_descendants = isnpc and (character.Name == "MI24V" or character.Name == "BTR80")
                        local parts_to_check = check_descendants and character:GetDescendants() or character:GetChildren()
                        for _, part in parts_to_check do
                            if _IsA(part, "BasePart") and isBodyPart(part.Name) then
                                plr.body_parts[#plr.body_parts + 1] = part
                            end
                        end
                    end
                    local cache = plr.body_parts
                    if not cache or #cache <= 0 then
                        esp_table.update_player_chams(player, false)
                        return plr:togglevis(false)
                    end
                    corners = calculateCorners(getBoundingBox(cache))
                end
                plr:togglevis(true)
                
                local is_vis = false
                if settings.box_outline_vis or settings.realname_outline_vis or settings.displayname_outline_vis or settings.dist_outline_vis or settings.weapon_outline_vis then
                    if not plr.last_vis_check or (os.clock() - plr.last_vis_check) > 0.15 then
                        plr.last_vis_check = os.clock()
                        plr.is_vis_cached = cheat.utility.is_visible(camera.CFrame, character, head)
                    end
                    is_vis = plr.is_vis_cached or false
                end
                do
                    local is_cheater = false
                    if not isnpc and settings.high_kd_marker then
                        if not plr._kd_cached_time or (os.clock() - plr._kd_cached_time) > 2 then
                            plr._kd_cached_time = os.clock()
                            local pfolder = ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(player.Name)
                            local stats_obj = pfolder and (pfolder:FindFirstChild("WipeStatistics", true) or pfolder:FindFirstChild("Statistics", true))
                            if stats_obj then
                                local kills = stats_obj:GetAttribute("Kills") or 0
                                local deaths = stats_obj:GetAttribute("Deaths") or 0
                                local ratio = kills / math.max(1, deaths)
                                plr._kd_is_cheater = ratio > 5
                            else
                                plr._kd_is_cheater = false
                            end
                        end
                        is_cheater = plr._kd_is_cheater or false
                    end

                    local pos = corners.topLeft
                    local size = corners.bottomRight - corners.topLeft
                    box.Position = pos
                    box.Size = size
                    local drawingFix = getgenv().DrawingFix
                    if drawingFix then
                        box_outline.Position = pos - _Vector2new(1, 1)
                        box_outline.Size = size + _Vector2new(2, 2)
                    else
                        box_outline.Position = pos
                        box_outline.Size = size
                    end
                    box_fill.Position = pos
                    box_fill.Size = size
                    if settings.box_outline_vis and is_vis then
                        box_outline.Color = settings.box_outline_vis_color[1]
                        box_outline.Transparency = settings.box_outline_vis_color[2]
                    else
                        box_outline.Color = settings.box_outline_color[1]
                        box_outline.Transparency = settings.box_outline_color[2]
                    end
                end
                do
                    local min_healthbar_height = 5
                    local healthbar_top_y = corners.topLeft.Y
                    if (corners.bottomLeft.Y - corners.topLeft.Y) < min_healthbar_height then
                        healthbar_top_y = corners.bottomLeft.Y - min_healthbar_height
                    end
                    local top_text_y = math.min(corners.topLeft.Y, healthbar_top_y)
                    
                    local pos = _Vector2new((corners.topLeft.X + corners.topRight.X) * 0.5, top_text_y) - Vector2.yAxis
                    realname.Position = pos - (Vector2.yAxis * realname.TextBounds.Y) - _Vector2new(0, 2)
                    displayname.Position = pos - Vector2.yAxis * displayname.TextBounds.Y - (realname.Visible and Vector2.yAxis * realname.TextBounds.Y or Vector2.zero)
                    
                    local name_str = player.Name
                    if not isnpc and settings.high_kd_marker and loaded_plrs[player]._kd_is_cheater then
                        name_str = "[CHEATER] " .. name_str
                    end
                    realname.Text = name_str
                    
                    if settings.realname_outline_vis and is_vis then
                        realname.OutlineColor = settings.realname_outline_vis_color
                    else
                        realname.OutlineColor = settings.realname_outline_color
                    end
                    if settings.displayname_outline_vis and is_vis then
                        displayname.OutlineColor = settings.displayname_outline_vis_color
                    else
                        displayname.OutlineColor = settings.displayname_outline_color
                    end
                end
                do
                    local pos = (corners.bottomLeft + corners.bottomRight) * 0.5
                    dist.Text = mathround(humanoid_distance / 3) .. "m"
                    dist.Position = pos
                    if not plr._gun_cache_time or (os.clock() - plr._gun_cache_time) > 0.5 then
                        plr._gun_cache_time = os.clock()
                        plr._gun_cache_text = isnpc and "" or esp_table.get_gun(player)
                    end
                    weapon.Text = plr._gun_cache_text or ""
                    weapon.Position = pos + (dist.Visible and Vector2.yAxis * dist.TextBounds.Y - _Vector2new(0, 2) or Vector2.zero)
                    
                    if settings.dist_outline_vis and is_vis then
                        dist.OutlineColor = settings.dist_outline_vis_color
                    else
                        dist.OutlineColor = settings.dist_outline_color
                    end
                    if settings.weapon_outline_vis and is_vis then
                        weapon.OutlineColor = settings.weapon_outline_vis_color
                    else
                        weapon.OutlineColor = settings.weapon_outline_color
                    end
                end
                -- Neon Gradient Health Bar
                healthtext.Visible = false
                local h_percent = math.clamp(humanoid_health / humanoid_max_health, 0, 1)
                local bar_start = corners.bottomLeft - _Vector2new(6, 0)
                local bar_end = corners.topLeft - _Vector2new(6, 0)
                
                local min_healthbar_height = 5
                if (bar_start.Y - bar_end.Y) < min_healthbar_height then
                    bar_end = bar_start - _Vector2new(0, min_healthbar_height)
                end
                
                local glow_color = settings.health_color_top:Lerp(settings.health_color_bottom, 0.5)
                
                for i = 1, 6 do
                    local glow = obj["health_bar_glow_"..i]
                    local cap_top = obj["health_bar_glow_cap_top_"..i]
                    local cap_bottom = obj["health_bar_glow_cap_bottom_"..i]
                    
                    if settings.health and h_percent > 0 then
                        local th = (i / 6) * settings.health_glow_size
                        local tr = 0.3 - (i * 0.04)
                        
                        glow.Visible = true
                        glow.From = bar_start
                        glow.To = bar_start:Lerp(bar_end, h_percent)
                        glow.Color = glow_color
                        glow.Thickness = th
                        glow.Transparency = tr
                        
                        cap_top.Visible = true
                        cap_top.Position = bar_start:Lerp(bar_end, h_percent)
                        cap_top.Color = glow_color
                        cap_top.Radius = th / 2
                        cap_top.Transparency = tr
                        
                        cap_bottom.Visible = true
                        cap_bottom.Position = bar_start
                        cap_bottom.Color = glow_color
                        cap_bottom.Radius = th / 2
                        cap_bottom.Transparency = tr
                    else
                        glow.Visible = false
                        cap_top.Visible = false
                        cap_bottom.Visible = false
                    end
                end
                
                if settings.health and h_percent > 0 then
                    obj.health_bar_cap_top.Visible = true
                    obj.health_bar_cap_top.Position = bar_start:Lerp(bar_end, h_percent)
                    obj.health_bar_cap_top.Color = settings.health_color_top:Lerp(settings.health_color_bottom, 1 - h_percent)
                    obj.health_bar_cap_top.Radius = settings.health_thickness / 2

                    obj.health_bar_cap_bottom.Visible = true
                    obj.health_bar_cap_bottom.Position = bar_start
                    obj.health_bar_cap_bottom.Color = settings.health_color_bottom
                    obj.health_bar_cap_bottom.Radius = settings.health_thickness / 2
                else
                    obj.health_bar_cap_top.Visible = false
                    obj.health_bar_cap_bottom.Visible = false
                end
                
                for i = 1, 10 do
                    local seg_line = obj["health_bar_"..i]
                    if settings.health and i <= math.ceil(h_percent * 10) then
                        seg_line.Visible = true
                        local seg_start = bar_start:Lerp(bar_end, (i - 1) / 10)
                        local seg_end = bar_start:Lerp(bar_end, i / 10)
                        if i == math.ceil(h_percent * 10) then
                            seg_end = bar_start:Lerp(bar_end, h_percent)
                        end
                        seg_line.From = seg_start
                        seg_line.To = seg_end
                        local col_percent = 1 - (i / 10)
                        seg_line.Color = settings.health_color_top:Lerp(settings.health_color_bottom, col_percent)
                    else
                        seg_line.Visible = false
                    end
                end
                if settings.skeleton then
                    if not plr._skel_parts then
                        plr._skel_parts = {}
                        for _, part in next, character:GetChildren() do
                            local parent_name = skeleton_order[part.Name]
                            if parent_name then
                                local parent_instance = _FindFirstChild(character, parent_name)
                                local line = obj["skeleton_" .. part.Name]
                                if parent_instance and line then
                                    plr._skel_parts[#plr._skel_parts + 1] = { part = part, parent = parent_instance, line = line }
                                end
                            end
                        end
                    end
                    for i = 1, #plr._skel_parts do
                        local entry = plr._skel_parts[i]
                        if entry.part.Parent and entry.parent.Parent then
                            local part_position = _WorldToViewportPoint(camera, entry.part.Position)
                            local parent_part_position = _WorldToViewportPoint(camera, entry.parent.Position)
                            entry.line.From = _Vector2new(part_position.X, part_position.Y)
                            entry.line.To = _Vector2new(parent_part_position.X, parent_part_position.Y)
                        end
                    end
                end
                esp_table.update_player_chams(player, true)
            end)
            plr:forceupdate()
        end
        local function create_object_esp(model, modelname)
            if not model then return end
            local espname = identify_model(model, modelname)
            if not (espname) then return end
            loaded_plrs[model] = {
                obj = {
                    name = esp.create_obj("Text", { Center = true, Visible = false, Text = espname }),
                }
            }
            local plr = loaded_plrs[model]
            local obj = plr.obj
            local realname = obj.name
            
            local main_settings = esp_table.main_settings
            local enemy_settings = esp_table.settings.enemy
            local corpse_settings = esp_table.settings.corpse
            
            local setvis_cache = false
            function plr:forceupdate()
                realname.Size = main_settings.textSize
                realname.Font = main_settings.textFont
                realname.Color = corpse_settings.color
                realname.Outline = corpse_settings.outline
                realname.OutlineColor = corpse_settings.outline_color
                realname.Transparency = 1
            end
            function plr:togglevis(bool)
                if setvis_cache ~= bool then
                    for _, v in obj do v.Visible = bool end
                    setvis_cache = bool
                end
            end
            plr.connection = cheat.utility.new_heartbeat(function(delta)
                local plr = loaded_plrs[model]
                if not corpse_settings.enabled then
                    return plr:togglevis(false)
                end
                
                local mainpart = get_mainpart(model, modelname)
                local worldPos = mainpart and mainpart.Position or model:GetPivot().Position
                local position, onscreen = worldToScreen(worldPos)
                if not onscreen then
                    return plr:togglevis(false)
                end
                local now = os.clock()
                if plr._next_object_esp_update and now < plr._next_object_esp_update then
                    return
                end
                local object_distance = (Camera.CFrame.p - worldPos).Magnitude
                plr._next_object_esp_update = now + (object_distance < 300 and 0.05 or object_distance < 900 and 0.1 or 0.2)
                
                local str = ""
                if corpse_settings.name then str = espname end
                if corpse_settings.distance then
                    local dist = math.floor(object_distance / 4)
                    if str ~= "" then str = str .. " [" .. dist .. "m]" else str = "[" .. dist .. "m]" end
                end
                
                if str == "" then
                    return plr:togglevis(false)
                end
                
                realname.Text = str
                realname.Position = position
                plr:togglevis(true)
            end)
            plr:forceupdate()
        end
        local function destroy_esp(player)
            if not loaded_plrs[player] then return end
            if loaded_plrs[player].connection then
                loaded_plrs[player].connection:Disconnect()
            end
            for i,v in loaded_plrs[player].obj do
                v:Remove()
            end
            esp_table.update_player_chams(player, false)
            loaded_plrs[player] = nil
        end
        local function is_corpse_entry(entry)
            local dropped = workspace:FindFirstChild("DroppedItems")
            return dropped and typeof(entry) == "Instance" and entry:IsDescendantOf(dropped)
        end
        function esp_table.ensure_player_entities()
            for _, v in next, plrs:GetPlayers() do
                if v ~= lplr and not loaded_plrs[v] then
                    create_esp(v)
                end
            end
            local zones = workspace:FindFirstChild("AiZones")
            if zones then
                for _, folder in next, zones:GetChildren() do
                    for _, npc in next, folder:GetChildren() do
                        if not loaded_plrs[npc] then
                            create_esp(npc, true)
                        end
                    end
                end
            end
        end
        function esp_table.clear_player_entities()
            local remove = {}
            for entry in next, loaded_plrs do
                if typeof(entry) == "Instance" and not is_corpse_entry(entry) then
                    remove[#remove + 1] = entry
                end
            end
            for i = 1, #remove do
                destroy_esp(remove[i])
            end
        end
        function esp_table.ensure_corpse_entities()
            local dropped = workspace:FindFirstChild("DroppedItems")
            if not dropped then return end
            for _, item in next, dropped:GetChildren() do
                if not loaded_plrs[item] then
                    create_object_esp(item, "corpse")
                end
            end
        end
        function esp_table.clear_corpse_entities()
            local remove = {}
            for entry in next, loaded_plrs do
                if is_corpse_entry(entry) then
                    remove[#remove + 1] = entry
                end
            end
            for i = 1, #remove do
                destroy_esp(remove[i])
            end
        end
        function esp_table.load()
            assert(not esp_table.__loaded, "[ESP] already loaded");
            local shortcut = function(is_obj, remove, name)
                return function(model)
                    if remove then
                        destroy_esp(model)
                    elseif is_obj then
                        if esp_table.settings.corpse.enabled then
                            create_object_esp(model, name)
                        end
                    elseif esp_table.settings.enemy.enabled then
                        create_esp(model)
                    end
                end
            end
            esp_table.objectAdded = {
                plrs.PlayerAdded:Connect(shortcut(false, false)),
                workspace.DroppedItems.ChildAdded:Connect(shortcut(true, false, "corpse"))
            };
            esp_table.objectRemoving = {
                plrs.PlayerRemoving:Connect(shortcut(false, true)),
                workspace.DroppedItems.ChildRemoved:Connect(shortcut(true, true, "corpse"))
            };
            for _, __no in pairs(workspace.AiZones:GetChildren()) do
                esp_table.objectAdded[#esp_table.objectAdded + 1] = __no.ChildAdded:Connect(shortcut(false, false))
                esp_table.objectRemoving[#esp_table.objectRemoving + 1] = __no.ChildRemoved:Connect(shortcut(false, true))
            end
            esp_table.__loaded = true;
        end
        function esp_table.unload()
            assert(esp_table.__loaded, "[ESP] not loaded yet");
            for player, _ in next, loaded_plrs do
                destroy_esp(player)
            end
            for _, connection in next, esp_table.objectAdded do
                connection:Disconnect()
            end
            for _, connection in next, esp_table.objectRemoving do
                connection:Disconnect()
            end
            esp_table.__loaded = false;
        end
        function esp_table.get_gun(player)
            local Player = _FindFirstChild(ReplicatedStorage.Players, player.Name);
            if Player and _FindFirstChild(Player, "Status") and _FindFirstChild(Player.Status, "GameplayVariables") and _FindFirstChild(Player.Status.GameplayVariables, "EquippedTool") and Player.Status.GameplayVariables.EquippedTool.Value then
                local Equipped = Player.Status.GameplayVariables.EquippedTool.Value;
                return tostring(Equipped);
            end;
            return "None";
        end
        local forceupdate_queued = false
        function esp_table.icaca()
            if forceupdate_queued then
                return
            end

            forceupdate_queued = true
            task.defer(function()
                forceupdate_queued = false
                local processed = 0
                for _, v in loaded_plrs do
                    if v and v.forceupdate then
                        pcall(function()
                            v:forceupdate()
                        end)
                        processed = processed + 1
                        if processed % 25 == 0 then
                            task.wait()
                        end
                    end
                end
            end)
        end
        cheat.EspLibrary = esp_table
    end)()
    local is_visible = cheat.utility.is_visible
    cheat._pos_vis_params = cheat._pos_vis_params or RaycastParams.new()
    cheat._pos_vis_params.FilterType = Enum.RaycastFilterType.Exclude
    cheat._pos_vis_params.CollisionGroup = "WeaponRay"
    cheat._pos_vis_params.IgnoreWater = true
    cheat._pos_vis_filter = cheat._pos_vis_filter or table.create(3)
    local function is_pos_visible(posfrom, posto, target)
        if not (posfrom and posto and target) then return false end
        for i = #cheat._pos_vis_filter, 1, -1 do
            cheat._pos_vis_filter[i] = nil
        end
        local nocollision = workspace:FindFirstChild("NoCollision")
        if nocollision then cheat._pos_vis_filter[#cheat._pos_vis_filter + 1] = nocollision end
        cheat._pos_vis_filter[#cheat._pos_vis_filter + 1] = Camera
        if LocalPlayer.Character then cheat._pos_vis_filter[#cheat._pos_vis_filter + 1] = LocalPlayer.Character end
        cheat._pos_vis_params.FilterDescendantsInstances = cheat._pos_vis_filter
        local castresults = _Raycast(workspace, posfrom, posto - posfrom, cheat._pos_vis_params)
        return not (castresults and castresults.Instance) or _IsDescendantOf(castresults.Instance, target)
    end
    local function predict_velocity(Origin, Destination, DestinationVelocity, ProjectileSpeed)
        local Distance = (Destination - Origin).Magnitude;
        local TimeToHit = (Distance / ProjectileSpeed);
        local Predicted = Destination + DestinationVelocity * TimeToHit;
        local Delta = (Predicted - Origin).Magnitude / ProjectileSpeed;
        TimeToHit = TimeToHit + (Delta / ProjectileSpeed);
        local Actual = Destination + DestinationVelocity * TimeToHit;
        return Actual;
    end;
    local function predict_drop(Origin, Destination, ProjectileSpeed, ProjectileDrop)
        if ProjectileDrop == 0 then return 0 end
        local Distance = (Destination - Origin).Magnitude;
        local TimeToHit = (Distance / ProjectileSpeed);
        TimeToHit = TimeToHit + (Distance / ProjectileSpeed);
        local DropTime = ProjectileDrop * TimeToHit ^ 2;
        if tostring(DropTime):find("nan") or (Distance <= 100) then
            return 0 
        end;
        return DropTime;
    end;
    local target_trigger_params = RaycastParams.new()
    target_trigger_params.FilterType = Enum.RaycastFilterType.Exclude
    target_trigger_params.IgnoreWater = true
    cheat._target_scan_candidates = cheat._target_scan_candidates or table.create(32)
    local silent_aim
    local function is_player_teammate(player)
        if not (silent_aim and silent_aim.team_check) or not player or player == LocalPlayer then
            return false
        end

        local players_folder = ReplicatedStorage and _FindFirstChild(ReplicatedStorage, "Players")
        local function get_clan(plr)
            local player_data = players_folder and _FindFirstChild(players_folder, plr.Name)
            local status = player_data and _FindFirstChild(player_data, "Status")
            local journey = status and _FindFirstChild(status, "Journey")
            local clan = journey and _FindFirstChild(journey, "Clan")
            return clan and clan:GetAttribute("CurrentClan")
        end

        local local_clan = get_clan(LocalPlayer)
        local target_clan = get_clan(player)
        return local_clan and target_clan and local_clan ~= "nil" and target_clan ~= "nil" and local_clan == target_clan
    end

    local function get_closest_target(usefov, fov_size, aimpart, npc, is_rage, rage_dist, target_heli, target_players, require_triggerable, allow_manip, manip_origin)
        local ermm_part, isnpc = nil, false
        local maximum_distance = is_rage and rage_dist or (usefov and fov_size or math.huge)
        local mousepos = _Vector2new(Mouse.X, Mouse.Y)
        local camera = Camera
        local camera_cframe = camera.CFrame
        local camera_pos = camera_cframe.p
        local needs_visibility_ray = require_triggerable or is_rage
        local max_visibility_checks = require_triggerable and 8 or 10
        for i = #cheat._target_scan_candidates, 1, -1 do
            cheat._target_scan_candidates[i] = nil
        end
        
        local function is_triggerable(parent, part)
            if is_visible(camera_cframe, parent, part) then return true end
            if allow_manip and manip_origin then
                local noc = workspace:FindFirstChild("NoCollision")
                if noc then target_trigger_params.FilterDescendantsInstances = {LocalPlayer.Character, Camera, noc}
                else target_trigger_params.FilterDescendantsInstances = {LocalPlayer.Character, Camera} end
                local res = workspace:Raycast(manip_origin, part.Position - manip_origin, target_trigger_params)
                if not res or (res.Instance and res.Instance:IsDescendantOf(parent)) then return true end
            end
            return false
        end

        local function consider_candidate(parent, part, candidate_isnpc)
            local position, onscreen = _WorldToViewportPoint(camera, part.Position)
            if usefov and not onscreen and not is_rage then return end
            local distance = is_rage and ((camera_pos - part.Position).Magnitude / 3) or (_Vector2new(position.X, position.Y - GuiInset.Y) - mousepos).Magnitude
            if (is_rage or (usefov and onscreen or not usefov)) and distance <= maximum_distance then
                if needs_visibility_ray then
                    cheat._target_scan_candidates[#cheat._target_scan_candidates + 1] = {
                        part = part,
                        parent = parent,
                        distance = distance,
                        isnpc = candidate_isnpc
                    }
                else
                    ermm_part = part
                    maximum_distance = distance
                    isnpc = candidate_isnpc
                end
            end
        end

        LPH_NO_VIRTUALIZE(function()
            if npc then
                for _, __no in pairs(workspace.AiZones:GetChildren()) do for _, npcs in pairs(__no:GetChildren()) do
                    local part = _FindFirstChild(npcs, aimpart)
                    
                    local is_heli = false
                    if target_heli and (npcs.Name == "MI24V" or npcs.Name == "BTR80") then
                        is_heli = true
                        part = npcs:FindFirstChild("CollisionPilot", true) or npcs:FindFirstChild("Mi24_Prop_M", true)
                    end
                    
                    if not is_heli and (npcs.Name == "MI24V" or npcs.Name == "BTR80") then continue end

                    local humanoid = _FindFirstChildOfClass(npcs, "Humanoid")
                    if part and (is_heli or (humanoid and humanoid.Health > 0)) then
                        if (camera_pos - part.Position).Magnitude < 2500 then
                            consider_candidate(npcs, part, true)
                        end
                    end
                end end
            end
            if target_players then
                for _, plr in Players:GetPlayers() do
                    local character = plr.Character
                    if plr ~= LocalPlayer and character and not is_player_teammate(plr) then
                        local part = _FindFirstChild(character, aimpart)
                        local humanoid = _FindFirstChildOfClass(character, "Humanoid")
                        if part and humanoid and humanoid.Health > 0 then
                            consider_candidate(character, part, false)
                        end
                    end
                end
            end
        end)()
        if needs_visibility_ray and #cheat._target_scan_candidates > 0 then
            table.sort(cheat._target_scan_candidates, function(a, b)
                return a.distance < b.distance
            end)
            local checked = 0
            for i = 1, #cheat._target_scan_candidates do
                local candidate = cheat._target_scan_candidates[i]
                checked = checked + 1
                if require_triggerable then
                    if is_triggerable(candidate.parent, candidate.part) then
                        ermm_part = candidate.part
                        isnpc = candidate.isnpc
                        break
                    end
                elseif is_visible(camera_cframe, candidate.parent, candidate.part) then
                    ermm_part = candidate.part
                    isnpc = candidate.isnpc
                    break
                end
                if checked >= max_visibility_checks then
                    break
                end
            end
        end
        return ermm_part, isnpc
    end
    local function make_beam(Origin, Position, Color, Thickness)
        local part1, part2 = Instance.new("Part", workspace.NoCollision), Instance.new("Part", workspace.NoCollision)
        part1.Position = Origin; part2.Position = Position;
        part1.Transparency = 1; part2.Transparency = 1;
        part1.CanCollide = false; part2.CanCollide = false;
        part1.Size = Vector3.zero; part2.Size = Vector3.zero;
        part1.Anchored = true; part2.Anchored = true;
        local OriginAttachment = Instance.new("Attachment", part1)
        local PositionAttachment = Instance.new("Attachment", part2)
        local Beam = Instance.new("Beam", workspace.NoCollision)
        Beam.Name = "Beam"
        Beam.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0,Color),
            ColorSequenceKeypoint.new(1,Color)
        };
        Beam.LightEmission = 1
        Beam.LightInfluence = 1
        Beam.TextureMode = Enum.TextureMode.Static
        Beam.TextureSpeed = 0
        Beam.Texture = "http://www.roblox.com/asset/?id=446111271"
        Beam.Transparency = NumberSequence.new(0)
        Beam.Attachment0 = OriginAttachment
        Beam.Attachment1 = PositionAttachment
        Beam.FaceCamera = true
        Beam.Segments = 1
        Beam.Width0 = Thickness or 0.25
        Beam.Width1 = Thickness or 0.25
        return Beam, part1, part2
    end

    local function create_advanced_tracer(Origin, Position, Color1, Color2, Thickness)
        local part1, part2 = Instance.new("Part", workspace.NoCollision), Instance.new("Part", workspace.NoCollision)
        part1.Position = Origin; part2.Position = Position;
        part1.Transparency = 1; part2.Transparency = 1;
        part1.CanCollide = false; part2.CanCollide = false;
        part1.Size = Vector3.zero; part2.Size = Vector3.zero;
        part1.Anchored = true; part2.Anchored = true;
        local OriginAttachment = Instance.new("Attachment", part1)
        local PositionAttachment = Instance.new("Attachment", part2)
        local colorSeq = ColorSequence.new{ColorSequenceKeypoint.new(0,Color1), ColorSequenceKeypoint.new(0.3,Color2), ColorSequenceKeypoint.new(1,Color2)}
        local CoreBeam = Instance.new("Beam", workspace.NoCollision)
        CoreBeam.Name = "CoreBeam"
        CoreBeam.Color = colorSeq
        CoreBeam.Width0 = Thickness
        CoreBeam.Width1 = Thickness
        CoreBeam.Texture = ""
        CoreBeam.TextureSpeed = 0
        CoreBeam.LightEmission = 1
        CoreBeam.LightInfluence = 0
        CoreBeam.TextureMode = Enum.TextureMode.Stretch
        CoreBeam.Attachment0 = OriginAttachment
        CoreBeam.Attachment1 = PositionAttachment
        CoreBeam.FaceCamera = true
        CoreBeam.Segments = 1
        CoreBeam.Transparency = NumberSequence.new(0)
        local PulseBeam = Instance.new("Beam", workspace.NoCollision)
        PulseBeam.Name = "PulseBeam"
        PulseBeam.Color = colorSeq
        PulseBeam.Width0 = Thickness * 0.5
        PulseBeam.Width1 = Thickness * 0.5
        PulseBeam.Texture = "rbxassetid://446111271"
        PulseBeam.TextureSpeed = 0
        PulseBeam.LightEmission = 1
        PulseBeam.LightInfluence = 0
        PulseBeam.TextureMode = Enum.TextureMode.Stretch
        PulseBeam.Attachment0 = OriginAttachment
        PulseBeam.Attachment1 = PositionAttachment
        PulseBeam.FaceCamera = true
        PulseBeam.Segments = 1
        PulseBeam.Transparency = NumberSequence.new(0)
        return {CoreBeam, PulseBeam}, part1, part2
    end

    local dark_tracer_pool = {
        parts = {},
        attachments = {},
        beams = {},
    }
    local dark_tracer_tween_service = game:GetService("TweenService")

    local function take_dark_tracer_object(PoolName, ClassName)
        local Pool = dark_tracer_pool[PoolName]
        return (#Pool > 0 and table.remove(Pool)) or Instance.new(ClassName)
    end

    local function return_dark_tracer_object(PoolName, Object)
        if not Object then return end
        Object.Parent = nil
        table.insert(dark_tracer_pool[PoolName], Object)
    end

    local function create_dark_beam_lines_tracer(Origin, Position, Color, Thickness, Lifetime)
        if typeof(Origin) ~= "Vector3" or typeof(Position) ~= "Vector3" then return end
        task.spawn(function()
            local StartPart = take_dark_tracer_object("parts", "Part")
            local EndPart = take_dark_tracer_object("parts", "Part")
            local StartAttachment = take_dark_tracer_object("attachments", "Attachment")
            local EndAttachment = take_dark_tracer_object("attachments", "Attachment")
            local Beam = take_dark_tracer_object("beams", "Beam")
            local TravelTween, TextureTween
            local Recycled = false

            local function recycle()
                if Recycled then return end
                Recycled = true
                if TravelTween then pcall(function() TravelTween:Cancel() end) end
                if TextureTween then pcall(function() TextureTween:Cancel() end) end
                Beam.Enabled = false
                Beam.Attachment0 = nil
                Beam.Attachment1 = nil
                StartAttachment.Parent = nil
                EndAttachment.Parent = nil
                return_dark_tracer_object("beams", Beam)
                return_dark_tracer_object("attachments", StartAttachment)
                return_dark_tracer_object("attachments", EndAttachment)
                return_dark_tracer_object("parts", StartPart)
                return_dark_tracer_object("parts", EndPart)
            end

            local Success = pcall(function()
                local Parent = workspace:FindFirstChild("NoCollision") or workspace
                for _, Part in ipairs({StartPart, EndPart}) do
                    Part.Transparency = 1
                    Part.Size = Vector3.new(0.05, 0.05, 0.05)
                    Part.Anchored = true
                    Part.CanCollide = false
                    Part.CanTouch = false
                    Part.CanQuery = false
                    Part.CastShadow = false
                    Part.Position = Origin
                    Part.Parent = Parent
                end
                StartAttachment.Parent = StartPart
                EndAttachment.Parent = EndPart
                Beam.Name = "DarkBeamLinesTracer"
                Beam.Color = ColorSequence.new(Color or Color3.fromRGB(255, 170, 232))
                Beam.Enabled = true
                Beam.FaceCamera = true
                Beam.Attachment0 = StartAttachment
                Beam.Attachment1 = EndAttachment
                Beam.Width0 = math.max(tonumber(Thickness) or 0.5, 0.05)
                Beam.Width1 = Beam.Width0
                Beam.Brightness = 8
                Beam.LightEmission = 0.25
                Beam.LightInfluence = 1
                Beam.Texture = "rbxassetid://12781848822"
                Beam.TextureLength = 4
                Beam.TextureSpeed = 1
                Beam.TextureMode = Enum.TextureMode.Static
                Beam.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0),
                    NumberSequenceKeypoint.new(1, 0),
                })
                Beam.Segments = 1
                Beam.Parent = Parent

                TravelTween = dark_tracer_tween_service:Create(
                    EndPart,
                    TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out),
                    {Position = Position}
                )
                TextureTween = dark_tracer_tween_service:Create(
                    Beam,
                    TweenInfo.new(2, Enum.EasingStyle.Exponential, Enum.EasingDirection.Out),
                    {TextureSpeed = 0.5}
                )
                TravelTween:Play()
                TextureTween:Play()

                task.delay(math.max(tonumber(Lifetime) or 2, 0.05), function()
                    local FadeSuccess = pcall(function()
                        if Recycled then return end
                        if not Beam.Parent then
                            recycle()
                            return
                        end
                        local FadeTween = dark_tracer_tween_service:Create(Beam, TweenInfo.new(1), {
                            Width0 = 0,
                            Width1 = 0,
                            TextureSpeed = 0,
                        })
                        FadeTween:Play()
                        FadeTween.Completed:Wait()
                        recycle()
                    end)
                    if not FadeSuccess then recycle() end
                end)
            end)
            if not Success then recycle() end
        end)
    end

    local function create_bent_tracer(Origin, Position, Color1, Color2, Thickness, Lifetime)
        if typeof(Origin) ~= "Vector3" or typeof(Position) ~= "Vector3" then return end
        local dir = (Position - Origin)
        local dist = dir.Magnitude
        if dist < 0.5 then return end

        local color_start = Color1 or Color3.new(1, 1, 1)
        local color_end = Color2 or color_start
        local tracer_thickness = math.max(tonumber(Thickness) or 0.5, 0.1)
        local duration = math.max(tonumber(Lifetime) or 1, 0.1)

        local forward = dir.Unit
        local arbitrary = (math.abs(forward.Y) < 0.99) and Vector3.yAxis or Vector3.xAxis
        local right = forward:Cross(arbitrary).Unit
        local up = forward:Cross(right).Unit

        local rand_angle = math.random() * math.pi * 2
        local bend_dir = (right * math.cos(rand_angle) + up * math.sin(rand_angle)).Unit

        local dist_m = dist / 3
        local dist_factor = math.clamp(dist_m / 400, 0, 1)
        local bend_offset_dist = 12 + dist_factor * (40 - 12)

        local control_point = (Origin + Position) * 0.5 + (bend_dir * bend_offset_dist)

        local num_segments = 10
        local points = {}
        for i = 0, num_segments do
            local t = i / num_segments
            local omt = 1 - t
            points[#points + 1] = (omt * omt * Origin) + (2 * omt * t * control_point) + (t * t * Position)
        end

        local Parent = workspace:FindFirstChild("NoCollision") or workspace
        local folder = Instance.new("Folder")
        folder.Name = "BentTracer"
        folder.Parent = Parent

        local parts = {}
        local beams = {}

        for i = 1, #points do
            local p = Instance.new("Part")
            p.Transparency = 1
            p.Size = Vector3.new(0.05, 0.05, 0.05)
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Position = points[i]
            p.Parent = folder
            parts[#parts + 1] = p
        end

        for i = 1, #points - 1 do
            local att0 = Instance.new("Attachment", parts[i])
            local att1 = Instance.new("Attachment", parts[i + 1])
            local t_ratio = i / (#points - 1)
            local seg_color = ColorSequence.new(color_start:Lerp(color_end, t_ratio))

            local core_beam = Instance.new("Beam")
            core_beam.Name = "CoreBeam"
            core_beam.Attachment0 = att0
            core_beam.Attachment1 = att1
            core_beam.FaceCamera = true
            core_beam.Width0 = tracer_thickness
            core_beam.Width1 = tracer_thickness
            core_beam.LightEmission = 1
            core_beam.LightInfluence = 0
            core_beam.Texture = ""
            core_beam.Color = seg_color
            core_beam.Segments = 1
            core_beam.Transparency = NumberSequence.new(0)
            core_beam.Parent = folder
            beams[#beams + 1] = core_beam

            local pulse_beam = Instance.new("Beam")
            pulse_beam.Name = "PulseBeam"
            pulse_beam.Attachment0 = att0
            pulse_beam.Attachment1 = att1
            pulse_beam.FaceCamera = true
            pulse_beam.Width0 = tracer_thickness * 1.5
            pulse_beam.Width1 = tracer_thickness * 1.5
            pulse_beam.LightEmission = 1
            pulse_beam.LightInfluence = 0
            pulse_beam.Texture = "rbxassetid://446111271"
            pulse_beam.TextureSpeed = 8
            pulse_beam.TextureLength = 6
            pulse_beam.TextureMode = Enum.TextureMode.Wrap
            pulse_beam.Color = seg_color
            pulse_beam.Segments = 1
            pulse_beam.Transparency = NumberSequence.new(0)
            pulse_beam.Parent = folder
            beams[#beams + 1] = pulse_beam
        end

        local elapsed = 0
        local conn; conn = cheat.utility.new_renderstepped(function(delta)
            elapsed = elapsed + delta
            local alpha = math.clamp((elapsed / duration) ^ 2, 0, 1)
            local pulse = (math.sin(elapsed * 20) + 1) / 2
            for _, b in ipairs(beams) do
                b.Transparency = NumberSequence.new(alpha)
                if b.Name == "PulseBeam" then
                    b.Width0 = tracer_thickness * (1 + pulse * 0.8)
                    b.Width1 = tracer_thickness * (1 + pulse * 0.8)
                end
            end
            if elapsed >= duration then
                conn:Disconnect()
                folder:Destroy()
            end
        end)
    end
    -- ═══════════════════════════════════════════════════════════════════
    --  RAGE BOT CORE HELPERS
    -- ═══════════════════════════════════════════════════════════════════
    local ragebot_last_target = nil
    local ragebot_last_switch = 0
    local ragebot_last_shot = 0
    local ragebot_target_switch_delay = 0.15

    local function ragebot_is_alive(part)
        if not part or not part.Parent then return false end
        local hum = part.Parent:FindFirstChildOfClass("Humanoid")
        return hum ~= nil and hum.Health > 0
    end

    local function ragebot_get_humanoid(part)
        if not part or not part.Parent then return nil end
        return part.Parent:FindFirstChildOfClass("Humanoid")
    end

    local function ragebot_predict_position(origin, target_pos, target_vel, proj_speed, mult)
        if not target_vel or target_vel.Magnitude < 0.1 then
            return target_pos
        end
        proj_speed = math.max(tonumber(proj_speed) or 900, 1)
        mult = tonumber(mult) or 1.0
        local dist = (target_pos - origin).Magnitude
        local t = dist / proj_speed
        return target_pos + (target_vel * t * mult)
    end

    local function ragebot_backtrack_position(part, ms)
        -- Backtrack: sample the part's recent positions using the part's
        -- AssemblyLinearVelocity history approximation. For a real
        -- implementation you would cache positions per-frame; here we
        -- approximate by rewinding velocity * time.
        if not part or not part.Parent then return part and part.Position end
        local vel = part.AssemblyLinearVelocity or Vector3.zero
        local rewind = math.clamp(tonumber(ms) or 200, 0, 1000) / 1000
        return part.Position - (vel * rewind)
    end

    local function ragebot_wallbangable(origin, target_pos)
        if not (origin and target_pos) then return false end
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.FilterDescendantsInstances = { LocalPlayer.Character, workspace.CurrentCamera }
        local noc = workspace:FindFirstChild("NoCollision")
        if noc then params.FilterDescendantsInstances = { LocalPlayer.Character, workspace.CurrentCamera, noc } end
        local res = workspace:Raycast(origin, target_pos - origin, params)
        if not res or not res.Instance then
            return true -- nothing blocking
        end
        local part = res.Instance
        local size = part.Size
        local min_axis = math.min(size.X, size.Y, size.Z)
        return minAxisLeq(min_axis, silent_aim.rage_bot_wallbang_thickness or 2.0)
    end

    function minAxisLeq(a, b)
        return (tonumber(a) or 0) <= (tonumber(b) or 0)
    end

    local function ragebot_should_fire(hit_chance)
        hit_chance = math.clamp(tonumber(hit_chance) or 100, 1, 100)
        return math.random(1, 100) <= hit_chance
    end

    local function ragebot_get_projectile_speed(loaded_ammo)
        if not loaded_ammo then return 900 end
        return loaded_ammo:GetAttribute("MuzzleVelocity") or 900
    end
    -- ═══════════════════════════════════════════════════════════════════
 silent_aim = {
    -- pin.reta fields
    enabled = false, triggerbot = false, target_ai = false, target_heli = false,
    testwallbang = false, wallbang_tp = false, part = "Head", random_part = false,
    fov = false, fov_show = false, fov_fill = false, fov_color = Color3.new(1,1,1),
    fov_top_color = Color3.fromRGB(140,135,180), fov_bottom_color = Color3.fromRGB(45,45,45),
    fov_outline = false, fov_outline_color = Color3.new(0,0,0), fov_size = 100,
    fov_glow_intensity = 1, fov_outline_transparency = 100, fov_fill_transparency = 35,
    indicator = false, indicator_text = "", nospread = false,
    instant = false, instant_method = "instant hit", magic_bullet = false,
    corner_shoot = false, hitscan_range = 4, hitscan_multiscan = false,
    hitscan_parts = {"Head","UpperTorso"}, hitscan_ticking = false,
    hitscan_tick_value = 0.03, hitscanning = false,
    manipulation = false, manipulation_active = false, manipulation_multiscan = true,
    manipulation_parts = {"Head","UpperTorso","RightUpperArm","LeftUpperArm","RightLowerLeg","LeftUpperLeg"},
    manipulation_underground = false, manipulation_max_offset = 30,
    manipulation_offset_distance = nil, manipulation_base_origin = nil,
    manipulation_bar = true, manipulation_bar_width = 100, manipulation_bar_height = 6,
    manipulation_bar_offset = 46, manipulation_bar_best_offset = 3,
    manipulation_bar_worst_offset = 30,
    manipulation_bar_low_color = Color3.fromRGB(255,55,55),
    manipulation_bar_high_color = Color3.fromRGB(55,255,90),
    origin_method = nil, crosshair_status = false,
    status_bar_width = 100, status_bar_height = 6, status_bar_offset = 32,
    status_bar_visible_color = Color3.fromRGB(55,255,90),
    status_bar_blocked_color = Color3.fromRGB(255,55,55),
    manipulated = false, manipulated_origin = nil,
    target_part = nil, is_npc = false, isvisible = false,
    instantreload = false, tracer = false, tracer_style = "Tracer 1",
    tracer_color = Color3.new(1,1,1), tracer_color2 = Color3.new(0,0.5,1),
    tracer_thickness = 0.5, tracer_lifetime = 1,
    tipanel_x = 20, tipanel_y = 350, target_line = false,
    rage_bot = false, rage_max_dist = 500,
    lift_hitboxes = false, lift_hitboxes_height = 2,
    method = "Ghost hook old",
    rage_bot_active = false, rage_bot_range = 4000,

    -- GHOST_HOOK fields kept so its existing UI doesn't nil-index
    target_players = true, team_check = false, target_npc = false,
    selected_part = "Head",
    crosshair_status_always = false,
    server_aim = false, camlock = false,
    target_chams = false, target_chams_color = Color3.fromRGB(255,60,60),
    target_chams_transparency = 0.25,
    rage_bot_hitchance = 100, rage_bot_min_damage = 1,
    rage_bot_auto_fire = true, rage_bot_target_switch_delay = 0.15,
    rage_bot_prioritize = "Distance", rage_bot_backtrack = false,
    rage_bot_backtrack_ms = 200, rage_bot_prediction = true,
    rage_bot_prediction_mult = 1.0, rage_bot_wallbang = false,
    rage_bot_wallbang_thickness = 2.0, rage_bot_penetration = false,
    rage_bot_auto_scope = false, rage_bot_silent_aim = true,
    rage_bot_head_only = true, rage_bot_prefer_head = true,
    rage_bot_body_aim = false, rage_bot_multi_target = false,
    rage_bot_force_shot = false, rage_bot_shot_delay = 0.05,
    rage_bot_shot_log = false,
}
do
    local ignorelist = require(ReplicatedStorage.Modules.UniversalTables).ReturnTable("GlobalIgnoreListProjectile")
    -- "new" method state: fake_part redirects AimPart CFrame; bullet_infos tracks seed→timing
    cheat._sa_fake_part = Instance.new("Part")
    cheat._sa_fake_part.Anchored = true
    cheat._sa_fake_part.Transparency = 1
    cheat._sa_fake_part.CanCollide = false
    cheat._sa_fake_part.Size = Vector3.new(0.05, 0.05, 0.05)
    cheat._sa_fake_part.Parent = ReplicatedStorage
    cheat._sa_bullet_infos = {}
end
    cheat.utility.fast_namecall_needed = function()
        return (cheat.hitlogs_enabled == true)
            or (cheat.freecam_enabled == true)
            or silent_aim.nospread
            or silent_aim.triggerbot
            or silent_aim.enabled
            or silent_aim.rage_bot
            or silent_aim.instant
            or silent_aim.corner_shoot
            or (cheat._gun_sounds_volume and cheat._gun_sounds_volume() < 100)
            or (cheat._hitmarker_sounds_volume and cheat._hitmarker_sounds_volume() < 100)
    end
    local function silent_aim_active()
        return feature_active(silent_aim.enabled, 'silentaim_bind')
    end
local function has_silent_aim_origin()
    return silent_aim.manipulated_origin ~= nil
        and silent_aim.hitscanning
end

local function silent_aim_shot_active()
    return silent_aim.enabled or silent_aim.hitscanning
end
    local function rage_bot_active()
        return feature_active(silent_aim.rage_bot, 'ragebot_bind')
    end

    local function triggerbot_active()
        return feature_active(silent_aim.triggerbot, 'triggerbot_bind')
    end

    local function lift_hitboxes_active()
        return feature_active(silent_aim.lift_hitboxes, 'lifthitboxes_bind')
    end

    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local ignorelist=require(ReplicatedStorage.Modules.UniversalTables).ReturnTable("GlobalIgnoreListProjectile")
        local function get_local_weapon()
            local Player = ReplicatedStorage.Players:FindFirstChild(LocalPlayer.Name)
            if Player and Player:FindFirstChild("Status") and Player.Status:FindFirstChild("GameplayVariables") and Player.Status.GameplayVariables:FindFirstChild("EquippedTool") and Player.Status.GameplayVariables.EquippedTool.Value then
                local Equipped = Player.Status.GameplayVariables.EquippedTool.Value
                return Equipped.Name
            end
            return "None"
        end
        local shoot_debounce = tick()
        local rpplrs = ReplicatedStorage.Players
        local bulletmodule = require(ReplicatedStorage.Modules.FPS.Bullet)
        local CreateBullet = require(ReplicatedStorage.Modules.FPS.Bullet).CreateBullet
        -- Non-blocking: WaitForChild on the server-created "Remotes" folder could
        -- stall the entire script for up to a minute when the game is still loading.
        -- These remotes exist by the time the player can shoot, and the calls are
        -- pcall-guarded, so a nil here is safe and recovers on the next shot.
        local _nb_remotes = ReplicatedStorage:FindFirstChild("Remotes")
        local ProjectileInflict = _nb_remotes and _nb_remotes:FindFirstChild("ProjectileInflict")
        local FireProjectile = _nb_remotes and _nb_remotes:FindFirstChild("FireProjectile")
        function cheat.shoot_weapon(speedmult)
            local weapon = get_local_weapon()
            local rpinv = rpplrs[LocalPlayer.Name] and rpplrs[LocalPlayer.Name].Inventory
            local aimpart = Camera and _FindFirstChild(Camera, "ViewModel") and _FindFirstChild(Camera.ViewModel, "AimPart")
            local inv_weapon = rpinv and _FindFirstChild(rpinv, weapon)
            local charweapon = LocalPlayer.Character and _FindFirstChild(LocalPlayer.Character, weapon)
            local magazine = inv_weapon and _FindFirstChild(inv_weapon, "Attachments") and _FindFirstChild(inv_weapon.Attachments, "Magazine") and inv_weapon.Attachments.Magazine:FindFirstChildOfClass("StringValue")
            local loadedammo = magazine and magazine.ItemProperties:FindFirstChild("LoadedAmmo") and magazine.ItemProperties.LoadedAmmo:FindFirstChildOfClass("Folder")
            if weapon ~= "None" and rpinv and aimpart and inv_weapon and _FindFirstChild(inv_weapon, "SettingsModule") and charweapon and loadedammo then
                local weapon_settings = require(_FindFirstChild(inv_weapon, "SettingsModule"))
                if rawget(weapon_settings, "FireRate") and shoot_debounce <= tick() then
                    local bullet_type = loadedammo:GetAttribute("AmmoType")
                    CreateBullet(bulletmodule, inv_weapon, LocalPlayer.Character:FindFirstChild(weapon),
                    Camera:FindFirstChild("ViewModel"), "Idle", bullet_type, 0, 1, Camera.ViewModel:FindFirstChild("AimPart"))
                    shoot_debounce = tick() + (rawget(weapon_settings, "FireRate") * speedmult)
                end
            end
        end
        function cheat.shoot_weapon_packet(isvis, speedmult, prediction, hitscan, hitscanwalls)
            local weapon = get_local_weapon()
            local rpinv = _FindFirstChild(rpplrs, LocalPlayer.Name) and rpplrs[LocalPlayer.Name].Inventory
            local inv_weapon = rpinv and weapon and _FindFirstChild(rpinv, weapon)
            local aimpart = Camera and _FindFirstChild(Camera, "ViewModel") and _FindFirstChild(Camera.ViewModel, "AimPart")
            if inv_weapon and _FindFirstChild(inv_weapon, "SettingsModule") then
                local weapon_settings = require(_FindFirstChild(inv_weapon, "SettingsModule"))
                if rawget(weapon_settings, "FireRate") and shoot_debounce <= tick() then
                    local real_orig = Camera.CFrame.p
                    if silent_aim.corner_shoot and silent_aim.manipulated_origin then
                        real_orig = silent_aim.manipulated_origin
                    elseif cheat.freecam_enabled then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("Head") then real_orig = char.Head.Position end
                    end
                    
                    local dist = silent_aim.target_part and (silent_aim.target_part.Position - real_orig).Magnitude or 0
                    autoshootdelay = tick() - (dist / 1000)
                    local rnd = math.random(-10000, 10000)
                    if silent_aim then
                        silent_aim._exact_fire_tick = tick()
                        -- Hitscan arms its one-frame teleport window here.
                        if silent_aim.hitscanning then
                            silent_aim._hitscan_fire_tick = silent_aim._exact_fire_tick
                        end
                    end
                    
                    local as_dir = silent_aim.target_part and (silent_aim.target_part.Position - real_orig).Unit or Vector3.new(0, 1, 0)
                    if FireProjectile:InvokeServer(as_dir, rnd, autoshootdelay) then
                        ProjectileInflict:FireServer(
                            silent_aim.target_part,
                            silent_aim.target_part.CFrame:ToObjectSpace(CFrame.new(0, 0.0001, 0)),
                            rnd,
                            tick()
                        )
                        if silent_aim.tracer then
                            local t_orig = real_orig
                            if not (silent_aim.corner_shoot and silent_aim.manipulated_origin) and not cheat.freecam_enabled then
                                t_orig = aimpart and aimpart.Position or Camera.CFrame.p
                            end
                            local drawing, deleteme, deleteme1 = make_beam(t_orig, silent_aim.target_part.Position, silent_aim.autoshootcolor)
                            local wtf = -1
                            local conn; conn = cheat.utility.new_renderstepped(function(delta)
                                wtf = wtf + delta
                                drawing.Transparency = NumberSequence.new(math.clamp(wtf, 0, 1))
                                if wtf >= 1 then
                                    drawing:Destroy()
                                    deleteme:Destroy()
                                    deleteme1:Destroy()
                                    conn:Disconnect()
                                end
                            end)
                        end
                    end
                    shoot_debounce = tick() + (rawget(weapon_settings, "FireRate") * speedmult)
                end
            end
        end
    end
    -- --- INSTANT RELOAD + AUTO RELOAD (ported from pin.reta V2) ----------------
    -- Self-contained "swim-accurate" reload mechanics: its own GC scan locates the
    -- FPS reload/use type tables, then hooks magazine / loadByHand to complete a
    -- reload in one frame, and hooks RangedWeaponDefault's remove-bullet upvalue for
    -- auto reload. Toggle state lives on `cheat` because the Gun Mods toggle is
    -- owned by a sibling do-block.
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        -- remotes — non-blocking lookups; they exist by the time the player acts.
        -- (no extra locals: the chunk is right at Luau's 200-local limit)
        local reload_remote        = (ReplicatedStorage:FindFirstChild("Remotes") or {}):FindFirstChild("Reload")
        local equip_remote         = (ReplicatedStorage:FindFirstChild("Remotes") or {}):FindFirstChild("Equip")
        local inventorymove_remote = (ReplicatedStorage:FindFirstChild("Remotes") or {}):FindFirstChild("InventoryMove")

        -- local_game_data = swim's project_delta.local_game_data
        -- NOTE: WaitForChild here blocks the whole script for up to a minute while
        -- the game is still creating the player's data folder ("Waiting For Player
        -- To Spawn"). Use FindFirstChild so nothing blocks; every consumer below
        -- already guards against nil.
        local players_folder = ReplicatedStorage:FindFirstChild("Players")
        local local_game_data = players_folder and players_folder:FindFirstChild(LocalPlayer.Name)
        -- Reuse the same folder variable for gameplayvars instead of adding a local
        -- (the chunk sits at Luau's 200-local ceiling).
        local local_gameplayvars = local_game_data and local_game_data:FindFirstChild("Status")
            and local_game_data.Status:FindFirstChild("GameplayVariables")

        -- fps_module — same require swim uses for update_fps upvalue extraction
        local fps_module = require(ReplicatedStorage.Modules.FPS)

        -- update_fps = swim's project_delta.update_fps — getupvalue(fps_module.new, 5)
        local update_fps = getupvalue(fps_module.new, 5)

        -- dedicated GC scan — swim's exact pattern at line 4879
        local fps_reloadtypes, fps_usetypes
        for _, v in getgc(true) do
            if type(v) ~= "table" then continue end
            if not fps_reloadtypes and rawget(v, "loadByHand") and type(rawget(v, "magazine")) == "function" then
                fps_reloadtypes = v
            end
            if not fps_usetypes and type(rawget(v, "RangedWeaponDefault")) == "function" and type(rawget(v, "MeleeWeaponDefault")) == "function" then
                fps_usetypes = v
            end
            if fps_reloadtypes and fps_usetypes then break end
        end

        -- get_compatible_mag — selects the magazine with highest loaded ammo
        local function get_compatible_mag(fps_object)
            local chosen_mag, loaded_mag_ammo = nil, 0
            local compatable_mags = fps_object.itemProperties and fps_object.itemProperties.CompatibleMagazines
            if not compatable_mags then return nil, 0 end
            if not local_game_data or not local_game_data:FindFirstChild("Inventory") then return nil, 0 end
            for _, container in local_game_data.Inventory:GetChildren() do
                local inventory = _FindFirstChild(container, "Inventory")
                if not inventory then continue end
                for _, item in inventory:GetChildren() do
                    if not compatable_mags:GetAttribute(item.Name) then continue end
                    local loaded_ammo = item:GetAttribute("LoadedAmmo") or 0
                    if loaded_ammo > 0 and loaded_ammo > loaded_mag_ammo then
                        chosen_mag = item
                        loaded_mag_ammo = loaded_ammo
                    elseif not chosen_mag then
                        chosen_mag = item
                        loaded_mag_ammo = loaded_ammo
                    end
                end
            end

            return chosen_mag, loaded_mag_ammo
        end

        -- Background auto refill mag loop (scans inventory every 0.5 seconds)
        local itemsList = ReplicatedStorage:FindFirstChild("ItemsList")
        local function getItemTemplate(itemName)
            if itemsList and itemsList:FindFirstChild(itemName) then
                return itemsList[itemName]:FindFirstChild("ItemProperties")
            end
            local found = ReplicatedStorage:FindFirstChild(itemName, true)
            if found then
                return found:FindFirstChild("ItemProperties") or (found.Parent and found.Parent:FindFirstChild("ItemProperties"))
            end
            return nil
        end

        local explicit_mag_ammo_map = {
            -- 5.56x45mm
            Mag556 = {["556x45AP"]=true, ["556x45Tracer"]=true},
            ["20Rnd556"] = {["556x45AP"]=true, ["556x45Tracer"]=true},
            PMAG10rnd = {["556x45AP"]=true, ["556x45Tracer"]=true},
            Mag556Rnd100 = {["556x45AP"]=true, ["556x45Tracer"]=true},

            -- 7.62x39mm
            ["762x39MAG"] = {["762x39AP"]=true, ["762x39Tracer"]=true},
            ["762x39ImprMAG"] = {["762x39AP"]=true, ["762x39Tracer"]=true},
            ["762x39Rnd75Mag"] = {["762x39AP"]=true, ["762x39Tracer"]=true},

            -- 7.62x51mm (FAL & R700)
            ["20rndFAL"] = {["762x51AP"]=true, ["762x51Tracer"]=true},
            ["30rndFAL"] = {["762x51AP"]=true, ["762x51Tracer"]=true},
            MagR700 = {["762x51AP"]=true, ["762x51Tracer"]=true},

            -- 7.62x54mm (SVD & PKM)
            ["762x54Rnd10Mag"] = {["762x54AP"]=true, ["762x54Tracer"]=true},
            ["762x54Rnd20Mag"] = {["762x54AP"]=true, ["762x54Tracer"]=true},
            AmmoBoxPKM100rnd = {["762x54AP"]=true, ["762x54Tracer"]=true},

            -- 7.62x25mm (TT33 & VZ61 / PPSH)
            ["762x25MAG"] = {["762x25AP"]=true, ["762x25Tracer"]=true},
            ["762x25TTMAG"] = {["762x25AP"]=true, ["762x25Tracer"]=true},
            ["762x25Rnd71Mag"] = {["762x25AP"]=true, ["762x25Tracer"]=true},

            -- 9x18mm (Makarov & VZ61)
            ["9x18MakarovMAG"] = {["9x18AP"]=true, ["9x18Tracer"]=true, ["9x18Z"]=true},
            ["9x18MakarovDrumMag"] = {["9x18AP"]=true, ["9x18Tracer"]=true, ["9x18Z"]=true},
            ["9x18vzMag"] = {["9x18AP"]=true, ["9x18Tracer"]=true, ["9x18Z"]=true},
            ["9x18vzDrumMag"] = {["9x18AP"]=true, ["9x18Tracer"]=true, ["9x18Z"]=true},

            -- 9x19mm (MP443 & MP5)
            ["9x19MP443MAG"] = {["9x19AP"]=true, ["9x19Tracer"]=true},
            ["9x19MP5MAG"] = {["9x19AP"]=true, ["9x19Tracer"]=true},
            ["9x19MP5DrumMAG"] = {["9x19AP"]=true, ["9x19Tracer"]=true},

            -- 9x39mm (AsVal / VSS)
            ["9x39Mag"] = {["9x39AP"]=true, ["9x39Z"]=true},
            ["9x39Rnd30Mag"] = {["9x39AP"]=true, ["9x39Z"]=true},

            -- 12 Gauge (Saiga)
            SaigaMag5rnd = {["12gaAP"]=true, ["12gaBuckshot"]=true, ["12gaFlechette"]=true, ["12gaSlug"]=true},
            SaigaMag20rnd = {["12gaAP"]=true, ["12gaBuckshot"]=true, ["12gaFlechette"]=true, ["12gaSlug"]=true},

            -- .338 Lapua (TFZ98S)
            MagTFZ98 = {["338AP"]=true, ["338T"]=true},

            -- .45 ACP (MK23)
            MK23ExtMag = {["45AP"]=true, ["45Tracer"]=true},
        }

        -- The duplicate auto-refill loop that used to live here has been REMOVED.
        -- It read `auto_refill_mag`, a local belonging to the gun-mods do-block
        -- further down and therefore NOT in scope here, so it silently resolved to
        -- a nil global and never ran. The single live loop now lives in the
        -- gun-mods block, where it can actually read the toggle. Verified against
        -- the live game: InventoryMove(ammoSlot, magSlot, ammoInv, magInv, nil)
        -- transfers rounds correctly (112 -> 104 ammo, mag 0 -> 8).

        -- get_compatible_ammo — swim's project_delta.get_compatible_ammo (line 4992)
        local function get_compatible_ammo(fps_object, arg_ammo, override_needed)
            local needed_ammo = override_needed or (fps_object.MaxAmmo - fps_object.Bullets)
            local chosen_ammo, ammo_amount = arg_ammo, arg_ammo and arg_ammo:GetAttribute("Amount") or 0
            if needed_ammo <= 0 or (chosen_ammo and ammo_amount) then
                return chosen_ammo, needed_ammo > ammo_amount and ammo_amount or needed_ammo
            end
            local item_properties = fps_object.itemProperties
            local compatible_ammo = item_properties and item_properties.CompatibleAmmo
            local preferred_ammo  = item_properties and item_properties:GetAttribute("PreferredAmmo")
            if not compatible_ammo then return nil, 0 end
            if not local_game_data or not local_game_data:FindFirstChild("Inventory") then return nil, 0 end
            for _, container in local_game_data.Inventory:GetChildren() do
                local inventory = _FindFirstChild(container, "Inventory")
                if not inventory then continue end
                for _, item in inventory:GetChildren() do
                    if not compatible_ammo:GetAttribute(item.Name) then continue end
                    if preferred_ammo and preferred_ammo ~= item.Name then continue end
                    local loaded_ammo = item:GetAttribute("Amount") or 0
                    if chosen_ammo and ammo_amount >= loaded_ammo then continue end
                    ammo_amount = loaded_ammo
                    chosen_ammo = item
                end
            end
            return chosen_ammo, needed_ammo > ammo_amount and ammo_amount or needed_ammo
        end

        -- ── Auto Reload ───────────────────────────────────────────────────────
        -- The v2 approach was `getupvalue(RangedWeaponDefault, 4)` -> an internal
        -- remove-bullet routine. Verified against this game build: that function has
        -- NO upvalues at all, and no table anywhere in the GC exposes a removeBullet,
        -- so that hook could never install. CreateBullet's `self` is the Bullet module
        -- (only a CreateBullet field), not the weapon.
        --
        -- Ammo actually lives on the equipped container's magazine (LoadedAmmo) and the
        -- game exposes a `Reload` RemoteFunction -- the same one the instant-reload code
        -- already calls. So: when a shot is created, start a short watchdog on the
        -- active weapon; if its magazine reads empty, invoke Reload for it.
        local auto_reload_inflight = false
        -- How many rounds left in the magazine should trigger a reload. 0 keeps the
        -- original behaviour (only when completely dry). Read live so the slider
        -- takes effect immediately; the ammo figure itself comes from the magazine
        -- slot's LoadedAmmo attribute, which is the same number the HUD draws.
        cheat._auto_reload_at = 0

        -- Find the magazine the equipped weapon is actually using. Verified layout:
        -- the gun's own container (e.g. "Makarov") has NO Inventory child and carries
        -- only Durability / FireModeIndex / Slot -- no ammo. Ammo lives on magazine
        -- items inside worn containers, as a `LoadedAmmo` attribute. The weapon links
        -- to its magazine through ItemProperties.CompatibleMagazines, so use that
        -- rather than guessing by container name.
        local function auto_reload_find_mag(wpn)
            if not wpn then return nil end
            local compat = wpn:FindFirstChild("CompatibleMagazines")
                or (wpn.ItemProperties and wpn.ItemProperties:FindFirstChild("CompatibleMagazines"))
            local containers = local_game_data and local_game_data.Inventory
            if not containers then return nil end
            local best, best_loaded = nil, nil
            for _, container in ipairs(containers:GetChildren()) do
                local ci = _FindFirstChild(container, "Inventory")
                if ci then
                    for _, slot in ipairs(ci:GetChildren()) do
                        local loaded = slot:GetAttribute("LoadedAmmo")
                        if loaded ~= nil then
                            local compatible = true
                            if compat then
                                compatible = compat:GetAttribute(slot.Name) ~= nil
                            end
                            if compatible then
                                -- prefer the fullest magazine, but tolerate an empty
                                -- one so a reload can still be issued
                                if best_loaded == nil or loaded > best_loaded then
                                    best, best_loaded = slot, loaded
                                end
                            end
                        end
                    end
                end
            end
            return best, best_loaded
        end

        local function auto_reload_tick()
            if not cheat._auto_reload then return end
            if auto_reload_inflight then return end
            if not reload_remote then return end
            auto_reload_inflight = true
            task.spawn(function()
                -- let the shot apply and the server replicate the new LoadedAmmo
                task.wait(0.08)
                local char = LocalPlayer.Character
                local tool = char and char:FindFirstChildOfClass("Tool")
                if not tool then auto_reload_inflight = false return end
                local wpn = tool:FindFirstChild("ItemProperties") or tool
                local mag, loaded = auto_reload_find_mag(wpn)
                -- Reload once the magazine has dropped to the configured count.
                -- Threshold 0 reproduces the old dry-only behaviour.
                local threshold = tonumber(cheat._auto_reload_at) or 0
                if mag and loaded ~= nil and loaded <= threshold then
                    cheat._auto_reload_last = tick()
                    pcall(function() reload_remote:InvokeServer(nil, 1, mag) end)
                end
                auto_reload_inflight = false
            end)
        end
        cheat._auto_reload_tick = auto_reload_tick

        -- The tick used to run only from the create-bullet hook, so once the magazine
        -- was empty there were no more shots to clock it and a reload the server
        -- rejected was never retried. Poll as well, rate limited, so a reload always
        -- eventually lands.
        task.spawn(function()
            while cheat.alive do
                task.wait(0.5)
                if cheat._auto_reload and not auto_reload_inflight
                    and (tick() - (cheat._auto_reload_last or 0)) > 0.6 then
                    pcall(auto_reload_tick)
                end
            end
        end)

        -- instant reload
        if fps_reloadtypes then
            local old_reload_magazine   = fps_reloadtypes.magazine
            local old_reload_loadbyhand = fps_reloadtypes.loadByHand

            local fle_module = nil
            local swap_mag_fn = nil
            local update_bullets_fn = nil
            pcall(function()
                fle_module = require(ReplicatedStorage.Modules.FunctionLibraryExtension)
                local u = debug.getupvalues(old_reload_magazine)
                swap_mag_fn = u[5]
                update_bullets_fn = u[7]
            end)

            fps_reloadtypes.magazine = LPH_JIT(function(fps_object, arg_mag)
                if not cheat._instant_reload then
                    return old_reload_magazine(fps_object, arg_mag)
                end

                local mag, loaded_ammo = arg_mag or get_compatible_mag(fps_object)
                if not mag or (loaded_ammo and loaded_ammo <= 0) then return end

                if fps_object.useDebounce then return end

                -- Stop any inspect or aim zoom immediately
                if fps_object.Scope or (fps_object.sight and fps_object.sight:GetAttribute("NoReloadAim")) then
                    pcall(function() fps_object:aim(false) end)
                end
                if fps_object.clientAnimationTracks.Inspect then
                    pcall(function()
                        fps_object.clientAnimationTracks.Inspect:Stop()
                        if fps_object.serverAnimationTracks.Inspect then fps_object.serverAnimationTracks.Inspect:Stop() end
                    end)
                end
                if fps_object.clientAnimationTracks.Use then pcall(function() fps_object.clientAnimationTracks.Use:Stop() end) end
                if fps_object.serverAnimationTracks.Use then pcall(function() fps_object.serverAnimationTracks.Use:Stop() end) end
                if fps_object.clientAnimationTracks.UseAiming then pcall(function() fps_object.clientAnimationTracks.UseAiming:Stop() end) end
                if fps_object.serverAnimationTracks.UseAiming then pcall(function() fps_object.serverAnimationTracks.UseAiming:Stop() end) end

                -- Stop reload animation tracks
                if fps_object.clientAnimationTracks.Reload then pcall(function() fps_object.clientAnimationTracks.Reload:Stop(0) end) end
                if fps_object.clientAnimationTracks.ReloadChamber then pcall(function() fps_object.clientAnimationTracks.ReloadChamber:Stop(0) end) end
                if fps_object.clientAnimationTracks.ReloadNoMag then pcall(function() fps_object.clientAnimationTracks.ReloadNoMag:Stop(0) end) end
                if fps_object.clientAnimationTracks.Empty then pcall(function() fps_object.clientAnimationTracks.Empty:Stop(0) end) end
                if fps_object.clientAnimationTracks.BoltLock then pcall(function() fps_object.clientAnimationTracks.BoltLock:Stop(0) end) end
                if fps_object.clientAnimationTracks.BoltOpen then pcall(function() fps_object.clientAnimationTracks.BoltOpen:Stop(0) end) end

                if fps_object.serverAnimationTracks.Reload then pcall(function() fps_object.serverAnimationTracks.Reload:Stop(0) end) end
                if fps_object.serverAnimationTracks.ReloadChamber then pcall(function() fps_object.serverAnimationTracks.ReloadChamber:Stop(0) end) end
                if fps_object.serverAnimationTracks.ReloadNoMag then pcall(function() fps_object.serverAnimationTracks.ReloadNoMag:Stop(0) end) end

                -- Determine reload mode v183 (1 = Tactical with chambered round, 2 = Empty from chamber, 3 = Empty no mag)
                local current_mag = fle_module and fle_module:FindFirstChildOfSlotType(fps_object.weapon.Attachments, "Magazine")
                local reload_mode = 1
                if fps_object.Bullets == 0 then
                    reload_mode = current_mag and 2 or 3
                end

                -- Visual viewmodel magazine swap
                if swap_mag_fn then
                    pcall(function() swap_mag_fn(fps_object, mag.Name, mag) end)
                end

                -- Server handshake invocation (spawned so no network stall)
                task.spawn(function()
                    pcall(function()
                        reload_remote:InvokeServer(nil, reload_mode, mag)
                    end)
                    if update_bullets_fn then
                        pcall(function() update_bullets_fn(fps_object) end)
                    end
                    if update_fps then
                        pcall(function() update_fps(fps_object) end)
                    end
                end)

                -- Update local state immediately for instant firing capability
                if update_bullets_fn then
                    pcall(function() update_bullets_fn(fps_object) end)
                end

                local new_mag = fle_module and fle_module:FindFirstChildOfSlotType(fps_object.weapon.Attachments, "Magazine")
                if new_mag and new_mag.Value and new_mag.Value:FindFirstChild("ItemProperties") then
                    fps_object.MaxAmmo = new_mag.Value.ItemProperties:GetAttribute("MaxLoadedAmmo") or fps_object.MaxAmmo
                end

                if update_fps then
                    pcall(function() update_fps(fps_object) end)
                end

                fps_object.reloading = false
                fps_object.useDebounce = false
                fps_object.RecoilPatternPos = 0
            end)

            fps_reloadtypes.loadByHand = LPH_JIT(function(fps_object, arg_ammo)
                if not cheat._instant_reload then
                    return old_reload_loadbyhand(fps_object, arg_ammo)
                end

                if not fps_object.clientAnimationTracks.Equip or (not fps_object.clientAnimationTracks.Equip.IsPlaying or fps_object.clientAnimationTracks.Equip.TimePosition > fps_object.clientAnimationTracks.Equip.Length * 0.8) then
                    if fps_object.useDebounce then return end

                    local ammo, ammo_amount = get_compatible_ammo(fps_object, arg_ammo)
                    if not ammo or ammo_amount <= 0 then return end

                    -- Stop any reload/aim/use animations immediately
                    if fps_object.clientAnimationTracks.Inspect then pcall(function() fps_object.clientAnimationTracks.Inspect:Stop() end) end
                    if fps_object.clientAnimationTracks.Reload then pcall(function() fps_object.clientAnimationTracks.Reload:Stop(0) end) end
                    if fps_object.clientAnimationTracks.ReloadEnter then pcall(function() fps_object.clientAnimationTracks.ReloadEnter:Stop(0) end) end
                    if fps_object.clientAnimationTracks.ReloadLoop then pcall(function() fps_object.clientAnimationTracks.ReloadLoop:Stop(0) end) end

                    for i = 1, ammo_amount do
                        pcall(function()
                            reload_remote:InvokeServer(nil, 1, ammo)
                        end)
                        if update_bullets_fn then
                            pcall(function() update_bullets_fn(fps_object) end)
                        end
                    end

                    if update_fps then
                        pcall(function() update_fps(fps_object) end)
                    end

                    fps_object.reloading = false
                    fps_object.useDebounce = false
                    fps_object.cancellingReload = false
                end
            end)
        else
            print("[pin.reta] instant reload: fps_reloadtypes not found in GC")
        end
    end

    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local norecoil, nobob = false, false
        local instantreload, forceauto, instantaim = false, false, false
        local autoshoot, packetautoshoot, packetpred, packetscan, packetthruscan, shootspeed = false, false, false, false, false, 1
        local target_part, is_npc, isvisible;
        local instant_equip = false
        local rapid_fire = false
        local rapid_fire_delay = 0.1
        local unlock_firemodes = false
        local salobox = ui.box.aimbot:AddTab('Aimbot')
        local triggerbotbox = ui.box.aimbot:AddTab('Trigger Bot')
        local bullet_tracers_box = ui.box.aimbot:AddTab('Bullet Tracers')
        local gunmodbox = ui.box.mods:AddTab('Gun Mods')
        local fovbox = ui.box.mods:AddTab('FOV')
        local statusbarbox = ui.box.mods:AddTab('Status Bar')
        local aim_miscbox = ui.box.misc:AddTab('Aim Misc')
        ui.gunmodbox = gunmodbox
        local got_that = false
        -- ─── Melee (ported from pin.reta V2) ──────────────────────────────────
        -- no_melee_cooldown: clears useDebounce and fires StartSwing immediately.
        -- melee_reach: pushes RangeNormal/RangePower on the weapon tool.
        local no_melee_cooldown = false
        local melee_reach = false
        local melee_reach_dist = 5.0
        local melee_module_ref = nil
        local hooked_springs = setmetatable({}, { __mode = "k" })
        local hooked_spring_creates = setmetatable({}, { __mode = "k" })
        local hooked_spring_instances = setmetatable({}, { __mode = "k" })

        -- pin.reta compatibility stubs (GHOST_HOOK doesn't have these features)
        local charge_shot_enabled = false

        -- ─── One Tap (was Charge Shot) ────────────────────────────────
        -- Nothing is charged any more. The create-bullet hook below fires a fixed
        -- burst in a single shot, so the hold-to-charge ramp, its progress bar and
        -- every slider that configured them are gone.
        local charge_shot_bullets = 10

        -- ─── AUTO REFILL MAG (ported verbatim from pin.reta V2) ───────────────
        -- Background loop: every 0.5s it walks the player's inventory containers,
        -- finds magazines below MaxLoadedAmmo, resolves compatible ammo through
        -- ItemProperties.CompatibleAmmo (plus an explicit caliber map) and fires
        -- InventoryMove to load them. Guarded so a missing remote cannot stall.
        local inventorymove_remote = ReplicatedStorage:FindFirstChild("Remotes")
            and ReplicatedStorage.Remotes:FindFirstChild("InventoryMove")
        local local_game_data = ReplicatedStorage:FindFirstChild("Players")
            and ReplicatedStorage.Players:FindFirstChild(LocalPlayer.Name)
        if not inventorymove_remote or not local_game_data then
            task.spawn(function()
                inventorymove_remote = inventorymove_remote
                    or (ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("InventoryMove"))
                local_game_data = local_game_data
                    or (ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(LocalPlayer.Name))
            end)
        end
        local auto_refill_mag = false
        -- Background auto refill mag loop (scans inventory every 0.5 seconds)
        local itemsList = ReplicatedStorage:FindFirstChild("ItemsList")
        local function getItemTemplate(itemName)
            if itemsList and itemsList:FindFirstChild(itemName) then
                return itemsList[itemName]:FindFirstChild("ItemProperties")
            end
            local found = ReplicatedStorage:FindFirstChild(itemName, true)
            if found then
                return found:FindFirstChild("ItemProperties") or (found.Parent and found.Parent:FindFirstChild("ItemProperties"))
            end
            return nil
        end

        local explicit_mag_ammo_map = {
            -- 5.56x45mm
            Mag556 = {["556x45AP"]=true, ["556x45Tracer"]=true},
            ["20Rnd556"] = {["556x45AP"]=true, ["556x45Tracer"]=true},
            PMAG10rnd = {["556x45AP"]=true, ["556x45Tracer"]=true},
            Mag556Rnd100 = {["556x45AP"]=true, ["556x45Tracer"]=true},

            -- 7.62x39mm
            ["762x39MAG"] = {["762x39AP"]=true, ["762x39Tracer"]=true},
            ["762x39ImprMAG"] = {["762x39AP"]=true, ["762x39Tracer"]=true},
            ["762x39Rnd75Mag"] = {["762x39AP"]=true, ["762x39Tracer"]=true},

            -- 7.62x51mm (FAL & R700)
            ["20rndFAL"] = {["762x51AP"]=true, ["762x51Tracer"]=true},
            ["30rndFAL"] = {["762x51AP"]=true, ["762x51Tracer"]=true},
            MagR700 = {["762x51AP"]=true, ["762x51Tracer"]=true},

            -- 7.62x54mm (SVD & PKM)
            ["762x54Rnd10Mag"] = {["762x54AP"]=true, ["762x54Tracer"]=true},
            ["762x54Rnd20Mag"] = {["762x54AP"]=true, ["762x54Tracer"]=true},
            AmmoBoxPKM100rnd = {["762x54AP"]=true, ["762x54Tracer"]=true},

            -- 7.62x25mm (TT33 & VZ61 / PPSH)
            ["762x25MAG"] = {["762x25AP"]=true, ["762x25Tracer"]=true},
            ["762x25TTMAG"] = {["762x25AP"]=true, ["762x25Tracer"]=true},
            ["762x25Rnd71Mag"] = {["762x25AP"]=true, ["762x25Tracer"]=true},

            -- 9x18mm (Makarov & VZ61)
            ["9x18MakarovMAG"] = {["9x18AP"]=true, ["9x18Tracer"]=true, ["9x18Z"]=true},
            ["9x18MakarovDrumMag"] = {["9x18AP"]=true, ["9x18Tracer"]=true, ["9x18Z"]=true},
            ["9x18vzMag"] = {["9x18AP"]=true, ["9x18Tracer"]=true, ["9x18Z"]=true},
            ["9x18vzDrumMag"] = {["9x18AP"]=true, ["9x18Tracer"]=true, ["9x18Z"]=true},

            -- 9x19mm (MP443 & MP5)
            ["9x19MP443MAG"] = {["9x19AP"]=true, ["9x19Tracer"]=true},
            ["9x19MP5MAG"] = {["9x19AP"]=true, ["9x19Tracer"]=true},
            ["9x19MP5DrumMAG"] = {["9x19AP"]=true, ["9x19Tracer"]=true},

            -- 9x39mm (AsVal / VSS)
            ["9x39Mag"] = {["9x39AP"]=true, ["9x39Z"]=true},
            ["9x39Rnd30Mag"] = {["9x39AP"]=true, ["9x39Z"]=true},

            -- 12 Gauge (Saiga)
            SaigaMag5rnd = {["12gaAP"]=true, ["12gaBuckshot"]=true, ["12gaFlechette"]=true, ["12gaSlug"]=true},
            SaigaMag20rnd = {["12gaAP"]=true, ["12gaBuckshot"]=true, ["12gaFlechette"]=true, ["12gaSlug"]=true},

            -- .338 Lapua (TFZ98S)
            MagTFZ98 = {["338AP"]=true, ["338T"]=true},

            -- .45 ACP (MK23)
            MK23ExtMag = {["45AP"]=true, ["45Tracer"]=true},
        }

        task.spawn(function()
            while cheat.alive do
                task.wait(0.5)
                if auto_refill_mag then
                    pcall(function()
                        if not local_game_data or not local_game_data:FindFirstChild("Inventory") then return end
                        -- Scan all containers in inventory
                        for _, container in ipairs(local_game_data.Inventory:GetChildren()) do
                            local inventory = _FindFirstChild(container, "Inventory")
                            if not inventory then continue end
                            for _, item in ipairs(inventory:GetChildren()) do
                                local loadedAmmo = item:GetAttribute("LoadedAmmo")
                                local propObj = item:FindFirstChild("ItemProperties")
                                local propVal = (propObj and propObj:IsA("ObjectValue")) and propObj.Value
                                local templateProp = getItemTemplate(item.Name) or (propVal and getItemTemplate(propVal.Name))

                                local slotType = item:GetAttribute("SlotType") or (templateProp and templateProp:GetAttribute("SlotType"))
                                local itemType = item:GetAttribute("ItemType") or (templateProp and templateProp:GetAttribute("ItemType"))
                                
                                local isMag = (loadedAmmo ~= nil) or (slotType == "Magazine") or (itemType == "Magazine") or item.Name:find("Mag") or item.Name:find("Drum") or item.Name:find("AmmoBox")

                                if isMag then
                                    loadedAmmo = loadedAmmo or 0
                                    local maxAmmo = item:GetAttribute("MaxLoadedAmmo") or (templateProp and templateProp:GetAttribute("MaxLoadedAmmo")) or item:GetAttribute("MaxAmmo") or item:GetAttribute("Capacity") or 30

                                    if loadedAmmo < maxAmmo then
                                        -- Retrieve exact compatible ammo types for this magazine
                                        local compatibleAmmo = (templateProp and templateProp:FindFirstChild("CompatibleAmmo")) or (propVal and propVal:FindFirstChild("CompatibleAmmo"))
                                        local magCaliber = (templateProp and templateProp:GetAttribute("AmmoType")) or (propVal and propVal:GetAttribute("AmmoType")) or item:GetAttribute("AmmoType")
                                        local explicitMap = explicit_mag_ammo_map[item.Name]
                                        local foundAmmo = nil

                                        if not local_game_data or not local_game_data:FindFirstChild("Inventory") then return end
                                        for _, c2 in ipairs(local_game_data.Inventory:GetChildren()) do
                                            local inv2 = _FindFirstChild(c2, "Inventory")
                                            if not inv2 then continue end
                                            for _, ammoItem in ipairs(inv2:GetChildren()) do
                                                local ammoAmount = ammoItem:GetAttribute("Amount")
                                                if ammoAmount and ammoAmount > 0 then
                                                    local ammoTemplate = getItemTemplate(ammoItem.Name)
                                                    local ammoSlotType = ammoItem:GetAttribute("SlotType") or (ammoTemplate and ammoTemplate:GetAttribute("SlotType"))
                                                    local ammoItemType = ammoItem:GetAttribute("ItemType") or (ammoTemplate and ammoTemplate:GetAttribute("ItemType"))

                                                    -- Filter out medical/consumable items explicitly
                                                    if ammoSlotType ~= "Consumable" and ammoItemType ~= "Consumable" and not ammoItem.Name:find("AI%d") and not ammoItem.Name:find("AA%d") and not ammoItem.Name:find("Serum") and not ammoItem.Name:find("Bandage") then
                                                        local isCompat = false
                                                        if explicitMap and explicitMap[ammoItem.Name] then
                                                            isCompat = true
                                                        elseif compatibleAmmo then
                                                            isCompat = (compatibleAmmo:GetAttribute(ammoItem.Name) ~= nil)
                                                        end
                                                        if not isCompat and magCaliber and magCaliber ~= "" then
                                                            isCompat = (ammoSlotType == magCaliber) or ammoItem.Name:find(magCaliber)
                                                        end
                                                        if not isCompat then
                                                            local cleanMag = item.Name:gsub("Mag.*", ""):gsub("Drum.*", ""):gsub("AmmoBox.*", ""):gsub("20Rnd", ""):gsub("30Rnd", ""):gsub("100Rnd", "")
                                                            if cleanMag ~= "" and cleanMag ~= item.Name then
                                                                isCompat = ammoItem.Name:find(cleanMag)
                                                            end
                                                        end

                                                        if isCompat then
                                                            foundAmmo = ammoItem
                                                            break
                                                        end
                                                    end
                                                end
                                            end
                                            if foundAmmo then break end
                                        end

                                        if foundAmmo then
                                            local ammoSlot = foundAmmo:GetAttribute("Slot")
                                            local magSlot = item:GetAttribute("Slot")
                                            local ammoParent = foundAmmo.Parent
                                            local magParent = item.Parent
                                            if ammoSlot and magSlot and ammoParent and magParent then
                                                inventorymove_remote:FireServer(ammoSlot, magSlot, ammoParent, magParent, nil)
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end)
                end
            end
        end)

        cheat.utility.get_bullet_tracer_color = function(secondary)
    task.wait()
            local option = cheat.Options and cheat.Options[secondary and "silentaim_tracer_color2" or "silentaim_tracer_color"]
            local value = option and (option.Value or option.Color)
            if type(value) == "table" then
                value = value.Color or value.Value
            end
            if typeof(value) == "Color3" then
                if secondary then
                    silent_aim.tracer_color2 = value
                else
                    silent_aim.tracer_color = value
                end
                return value
            end

            value = secondary and silent_aim.tracer_color2 or silent_aim.tracer_color
            if type(value) == "table" then
                value = value.Color or value.Value
            end
            if typeof(value) == "Color3" then
                return value
            end

            return secondary and Color3.new(0, 0.5, 1) or Color3.new(1, 1, 1)
        end
        cheat.utility.draw_regular_bullet_tracer = function(args)
            if not silent_aim.tracer then return end
            local aimpart
            for _, v in args do
                if typeof(v) == "Instance" and v.Name == "AimPart" then
                    aimpart = v
                    break
                end
            end
            if not aimpart then return end

            local t_orig = aimpart.Position
            local t_end = Mouse and Mouse.Hit and Mouse.Hit.Position or (t_orig + aimpart.CFrame.LookVector * 10000)
            if silent_aim.tracer_style == "Tracer 2" then
                local beams, d1, d2 = create_advanced_tracer(t_orig, t_end, cheat.utility.get_bullet_tracer_color(false), cheat.utility.get_bullet_tracer_color(true), silent_aim.tracer_thickness)
                local lifetime, t = silent_aim.tracer_lifetime, 0
                local conn; conn = cheat.utility.new_renderstepped(function(delta)
                    t = t + delta
                    local trans = math.clamp((t / lifetime) ^ 2, 0, 1)
                    local pulse = (math.sin(t * 20) + 1) / 2
                    for _, b in pairs(beams) do
                        b.Transparency = NumberSequence.new(trans)
                        if b.Name == "PulseBeam" then
                            b.Width0 = silent_aim.tracer_thickness * (0.5 + pulse)
                            b.Width1 = silent_aim.tracer_thickness * (0.5 + pulse)
                        end
                    end
                    if t >= lifetime then
                        for _, b in pairs(beams) do b:Destroy() end
                        d1:Destroy(); d2:Destroy(); conn:Disconnect()
                    end
                end)
                return
            end

            local drawing, deleteme, deleteme1 = make_beam(t_orig, t_end, cheat.utility.get_bullet_tracer_color(false), silent_aim.tracer_thickness)
            local wtf = -1
    task.wait()
            local conn; conn = cheat.utility.new_renderstepped(function(delta)
                wtf = wtf + delta
                drawing.Transparency = NumberSequence.new(math.clamp(wtf, 0, 1))
                if wtf >= 1 then
                    drawing:Destroy()
                    deleteme:Destroy()
                    deleteme1:Destroy()
                    conn:Disconnect()
                end
            end)
        end
        -- Hook installation moved OFF the main load path. The console's 30s
        -- timeout stack traced here (melee wrap + retry line): while the game was
        -- still loading, this loop's retries kept the script alive past the
        -- executor's limit and froze the client. As a spawned task it no longer
        -- blocks the UI, and the retry cap stops it spinning forever.
        cheat._hook_retries = 0
        task.spawn(function()
        repeat LPH_JIT_MAX(function()
            for i, gc in next, getgc(true) do
                if type(gc) == "table" then
                    if type(rawget(gc, "shove")) == "function" and type(rawget(gc, "update")) == "function" and not hooked_springs[gc] then
                        hooked_springs[gc] = true
                        local shove, update = gc.shove, gc.update
                        pcall(function()
                            gc.shove = function(...)
                                if norecoil then
                                    return nil
                                end
                                local ok, result = pcall(shove, ...)
                                if ok then
                                    return result
                                end
                                return nil
                            end
                            gc.update = function(...)
                                if nobob then
                                    return Vector3.zero
                                end
                                local ok, result = pcall(update, ...)
                                if ok then
                                    return result
                                end
                                return Vector3.zero
                            end
                        end)
                    end
                    if type(rawget(gc, "create")) == "function" and getinfo(gc.create).short_src == "ReplicatedStorage.Modules.SpringV2" and not hooked_spring_creates[gc] then
                        hooked_spring_creates[gc] = true
                        local old_create = (gc.create)
                        cheat.utility.new_hook(old_create, function(old, ...)
                            local create = type(old) == "function" and old or old_create
                            local returns = create(...)
                            if type(returns) ~= "table" or hooked_spring_instances[returns] then
                                return returns
                            end

                            hooked_spring_instances[returns] = true
                            local shove, update = returns.shove, returns.update
                            if type(shove) == "function" then
                                pcall(function()
                                    returns.shove = function(...)
                                        if norecoil then
                                            return nil
                                        end
                                        local ok, result = pcall(shove, ...)
                                        if ok then
                                            return result
                                        end
                                        return nil
                                    end
                                end)
                            end
                            if type(update) == "function" then
                                pcall(function()
                                    returns.update = function(...)
                                        if nobob then
                                            return Vector3.zero
                                        end
                                        local ok, result = pcall(update, ...)
                                        if ok then
                                            return result
                                        end
                                        return Vector3.zero
                                    end
                                end)
                            end
                            return returns
                        end, true)
                    end
                    -- Melee: hook EVERY gc table exposing MeleeWeaponDefault. The live game
                    -- carries several distinct function objects for it (two in gc, and the
                    -- require()d Modules.FPS exposes yet another), so hooking a single gc
                    -- copy can miss the function the game actually calls. Dedupe by function
                    -- object so a shared function is only wrapped once.
                    do
                        local ok_melee, melee_module = pcall(function()
                            return require(ReplicatedStorage.Modules.FPS.Melee)
                        end)
                        if ok_melee and melee_module then
                            melee_module_ref = melee_module
                            local seen_melee_fns = cheat._melee_hooked_fns
                            if not seen_melee_fns then
                                seen_melee_fns = setmetatable({}, { __mode = "k" })
                                cheat._melee_hooked_fns = seen_melee_fns
                            end
                            local function wrap_melee(old_melee_def)
                                if type(old_melee_def) ~= "function" then return false end
                                if seen_melee_fns[old_melee_def] then return false end
                                seen_melee_fns[old_melee_def] = true
                                cheat.utility.new_hook(old_melee_def, LPH_JIT_MAX(function(old, self, ...)
                                    if no_melee_cooldown and self and cheat.ui_ready then
                                        self.useDebounce = false
                                        -- Driving StartSwing while the weapon ObjectValue
                                        -- was still unloaded fed a half-built weapon into
                                        -- the game's Effects script and error-stormed it
                                        -- (FunctionLibraryExtension:156 GetAttribute nil).
                                        local weapon_ref = typeof(self.weapon) == "Instance"
                                            and (self.weapon:IsA("ObjectValue") and self.weapon.Value or self.weapon)
                                        if weapon_ref then
                                            pcall(function()
                                                melee_module:StartSwing(weapon_ref, self.worldModel, self.viewModel, "NormalAttack", self.SprintStrafe)
                                            end)
                                        end
                                    end
                                    return old(self, ...)
                                end), true)
                                return true
                            end
                            -- the gc table currently being scanned by the outer loop
                            if type(rawget(gc, "MeleeWeaponDefault")) == "function" then
                                wrap_melee(rawget(gc, "MeleeWeaponDefault"))
                            end
                            -- The outer loop already walks every gc table; a second full
                            -- getgc(true) scan here would be O(n^2) across ~80k objects
                            -- (the 30-52s freeze). Hook only the require()d module copy,
                            -- which the gc never exposes, and let the outer loop handle
                            -- every gc-visible copy via the current `gc` table below.
                            local okfps, fps_mod = pcall(function() return require(ReplicatedStorage.Modules.FPS) end)
                            if okfps and type(fps_mod) == "table" then
                                wrap_melee(rawget(fps_mod, "MeleeWeaponDefault"))
                            end

                            -- Reach: wrap StartSwing once, raising the weapon tool's
                            -- range attributes whenever a swing starts.
                            if melee_module.StartSwing and not melee_module._reach_hooked then
                                melee_module._reach_hooked = true
                                local old_start_swing = melee_module.StartSwing
                                melee_module.StartSwing = function(self, p1, p2, p3, p4, p5, p6)
                                    if melee_reach then
                                        local obj = (typeof(p2) == "Instance" and p2:IsA("ObjectValue") and p2.Value)
                                            or (typeof(p1) == "Instance" and p1:IsA("ObjectValue") and p1.Value)
                                            or (typeof(p2) == "Instance" and p2)
                                            or (typeof(p1) == "Instance" and p1)
                                        if obj and obj:FindFirstChild("ItemProperties")
                                            and obj.ItemProperties:FindFirstChild("Tool") then
                                            local tool = obj.ItemProperties.Tool
                                            tool:SetAttribute("RangeNormal", 3 + melee_reach_dist)
                                            tool:SetAttribute("RangePower", 3 + melee_reach_dist)
                                        end
                                    end
                                    return old_start_swing(self, p1, p2, p3, p4, p5, p6)
                                end
                            end
                        end
                    end
                    if type(rawget(gc, "CreateBullet")) == "function" then
                        local old_bullet = gc.CreateBullet
                        cheat.utility.new_hook(old_bullet, LPH_JIT_MAX(function(old, self, ...)
                            local args = { ... };
                            local argCount = select("#", ...);
                            -- Peek Blink: the moment we shoot, drop the blink so the
                            -- owning Heartbeat returns us to the recorded position.
                            -- State lives on `cheat` because the toggle belongs to a
                            -- sibling block -- a local here would be a DIFFERENT
                            -- variable and the return would silently never fire.
                            if cheat._peek_blink_active then
                                if cheat.Toggles and cheat.Toggles.peek_blink then
                                    cheat.Toggles.peek_blink:SetValue(false)
                                else
                                    cheat._peek_blink_active = false
                                end
                            end
                            -- Auto Reload: a shot is a useful clock for an ammo check.
                            if cheat._auto_reload_tick then pcall(cheat._auto_reload_tick) end
                            local charged_shots = 1
                            -- ONE TAP: no charge ramp to read and no keybind -- the master
                            -- toggle alone decides, so the full burst goes out with one shot.
                            if charge_shot_enabled then
                                charged_shots = math.clamp(math.floor(charge_shot_bullets), 1, 15)
                            end
                            if charged_shots > 1 then
                                for _ = 2, charged_shots do
                                    local duplicate_args = table.clone(args)
                                    task.spawn(function()
                                        old(self, unpack(duplicate_args, 1, argCount))
                                    end)
                                end
                            end
                            if silent_aim_shot_active() or silent_aim.rage_bot then
                                local loadedammo, aimpart_index do
                                    for i, v in args do
                                        if typeof(v) == "Instance" and v.Name == "AimPart" then
                                            aimpart_index = i
                                        end
                                        if type(v) == "string" then
                                            local tmp = _FindFirstChild(ReplicatedStorage.AmmoTypes, v)
                                            if tmp then loadedammo = tmp end
                                        end
                                    end
                                end
                                if not (loadedammo and aimpart_index) then
                                    return old(self, unpack(args, 1, argCount))
                                end
                                -- ── "new" method ──
                                if silent_aim.method == "new" and silent_aim.target_part then
                                    local real_aimpart = args[aimpart_index]
                                    if not real_aimpart then
                                        return old(self, unpack(args, 1, argCount))
                                    end
                                    cheat._sa_fake_part.CFrame = real_aimpart.CFrame
                                    args[aimpart_index] = cheat._sa_fake_part
                                    local char = LocalPlayer.Character
                                    local hrp = char and _FindFirstChild(char, "HumanoidRootPart")
                                    local hum = char and _FindFirstChildOfClass(char, "Humanoid")
                                    local origin = hrp and (hrp.Position + (hum and hum:GetAttribute("Crouch") and _Vector3new(0, 0.6, 0) or _Vector3new(0, 1.6, 0))) or Camera.CFrame.p
                                    if has_silent_aim_origin() then
                                        origin = silent_aim.manipulated_origin
                                    end
                                    cheat._sa_fake_part.CFrame = CFrame.lookAt(origin, silent_aim.target_part.Position)
                                    if silent_aim.tracer then
                                        if silent_aim.tracer_style == "Dark Beam Lines" then
                                            create_dark_beam_lines_tracer(origin, silent_aim.target_part.Position, silent_aim.tracer_color, silent_aim.tracer_thickness, silent_aim.tracer_lifetime)
                                        elseif silent_aim.tracer_style == "Tracer 2 (bend)" then
                                            create_bent_tracer(origin, silent_aim.target_part.Position, silent_aim.tracer_color, silent_aim.tracer_color2, silent_aim.tracer_thickness, silent_aim.tracer_lifetime)
                                        elseif silent_aim.tracer_style == "Tracer 2" then
                                            local beams, d1, d2 = create_advanced_tracer(origin, silent_aim.target_part.Position, cheat.utility.get_bullet_tracer_color(false), cheat.utility.get_bullet_tracer_color(true), silent_aim.tracer_thickness)
                                            local lifetime = silent_aim.tracer_lifetime
                                            local t = 0
                                            local conn; conn = cheat.utility.new_renderstepped(function(delta)
                                                t = t + delta
                                                local trans = math.clamp((t / lifetime) ^ 2, 0, 1)
                                                local pulse = (math.sin(t * 20) + 1) / 2
                                                for _, b in pairs(beams) do
                                                    b.Transparency = NumberSequence.new(trans)
                                                    if b.Name == "PulseBeam" then
                                                        b.Width0 = silent_aim.tracer_thickness * (0.5 + pulse)
                                                        b.Width1 = silent_aim.tracer_thickness * (0.5 + pulse)
                                                    end
                                                end
                                                if t >= lifetime then
                                                    for _, b in pairs(beams) do b:Destroy() end
                                                    d1:Destroy(); d2:Destroy(); conn:Disconnect()
                                                end
                                            end)
                                        else
                                            local drawing, dm, dm1 = make_beam(origin, silent_aim.target_part.Position, cheat.utility.get_bullet_tracer_color(false), silent_aim.tracer_thickness)
                                            local wtf = -1
                                            local conn; conn = cheat.utility.new_renderstepped(function(delta)
                                                wtf = wtf + delta
                                                drawing.Transparency = NumberSequence.new(math.clamp(wtf, 0, 1))
                                                if wtf >= 1 then
                                                    drawing:Destroy(); dm:Destroy(); dm1:Destroy(); conn:Disconnect()
                                                end
                                            end)
                                        end
                                    end
                                    return old(self, unpack(args, 1, argCount))
                                end
                                -- ── "Ghost hook old" method ──
                                if silent_aim.tracer then
                                    if silent_aim.tracer_style == "Dark Beam Lines" then
                                        local t_orig = silent_aim.manipulated_origin or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position) or args[aimpart_index].Position
                                        local t_end = silent_aim.target_part and silent_aim.target_part.Position or (t_orig + args[aimpart_index].CFrame.LookVector * 10000)
                                        create_dark_beam_lines_tracer(t_orig, t_end, silent_aim.tracer_color, silent_aim.tracer_thickness, silent_aim.tracer_lifetime)
                                    elseif silent_aim.tracer_style == "Tracer 2 (bend)" then
                                        local t_orig = silent_aim.manipulated_origin or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position) or args[aimpart_index].Position
                                        local t_end = silent_aim.target_part and silent_aim.target_part.Position or (t_orig + args[aimpart_index].CFrame.LookVector * 10000)
                                        create_bent_tracer(t_orig, t_end, silent_aim.tracer_color, silent_aim.tracer_color2, silent_aim.tracer_thickness, silent_aim.tracer_lifetime)
                                    elseif silent_aim.tracer_style == "Tracer 2" then
                                        local t_orig = silent_aim.manipulated_origin or (LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Head") and LocalPlayer.Character.Head.Position) or args[aimpart_index].Position
                                        local beams, d1, d2 = create_advanced_tracer(t_orig, silent_aim.target_part and silent_aim.target_part.Position or args[aimpart_index].CFrame.LookVector * 10000, cheat.utility.get_bullet_tracer_color(false), cheat.utility.get_bullet_tracer_color(true), silent_aim.tracer_thickness)
                                        local lifetime = silent_aim.tracer_lifetime
                                        local t = 0
                                        local conn; conn = cheat.utility.new_renderstepped(function(delta)
                                            t = t + delta
                                            local trans = math.clamp((t / lifetime) ^ 2, 0, 1)
                                            local pulse = (math.sin(t * 20) + 1) / 2
                                            for _, b in pairs(beams) do
                                                b.Transparency = NumberSequence.new(trans)
                                                if b.Name == "PulseBeam" then
                                                    b.Width0 = silent_aim.tracer_thickness * (0.5 + pulse)
                                                    b.Width1 = silent_aim.tracer_thickness * (0.5 + pulse)
                                                end
                                            end
                                            if t >= lifetime then
                                                for _, b in pairs(beams) do b:Destroy() end
                                                d1:Destroy(); d2:Destroy(); conn:Disconnect()
                                            end
                                        end)
                                    else
                                        local real_orig = Camera.CFrame.p
                                        if has_silent_aim_origin() and not silent_aim.rage_bot_active then
                                            real_orig = silent_aim.manipulated_origin
                                        elseif cheat.freecam_enabled then
                                            local char = LocalPlayer.Character
                                            if char and char:FindFirstChild("Head") then real_orig = char.Head.Position end
                                        end
                                        local t_orig = real_orig
                                        if not has_silent_aim_origin() and not cheat.freecam_enabled then
                                            t_orig = args[aimpart_index].Position
                                        end
                                        local drawing, deleteme, deleteme1 = make_beam(t_orig, silent_aim.target_part and silent_aim.target_part.Position or args[aimpart_index].CFrame.LookVector * 10000, cheat.utility.get_bullet_tracer_color(false), silent_aim.tracer_thickness)
                                        local wtf = -1
                                        local conn; conn = cheat.utility.new_renderstepped(function(delta)
                                            wtf = wtf + delta
                                            drawing.Transparency = NumberSequence.new(math.clamp(wtf, 0, 1))
                                            if wtf >= 1 then
                                                drawing:Destroy(); deleteme:Destroy(); deleteme1:Destroy(); conn:Disconnect()
                                            end
                                        end)
                                    end
                                end
                                if silent_aim.instant then
                                    return old(self, unpack(args, 1, argCount))
                                end
                                if not silent_aim.target_part or silent_aim.instant then
                                    return old(self, unpack(args, 1, argCount))
                                end
                                local ProjectileSpeed = ragebot_get_projectile_speed(loadedammo)
                                local Destination = silent_aim.target_part.Position
                                local DestinationVelocity = silent_aim.target_part.AssemblyLinearVelocity or Vector3.zero
                                local Origin = Camera.CFrame.p
                                if rage_bot_active() then
                                    if silent_aim.rage_bot_backtrack then
                                        Destination = ragebot_backtrack_position(silent_aim.target_part, silent_aim.rage_bot_backtrack_ms)
                                    end
                                    if silent_aim.rage_bot_prediction then
                                        Destination = ragebot_predict_position(Origin, Destination, DestinationVelocity, ProjectileSpeed, silent_aim.rage_bot_prediction_mult)
                                    end
                                    if not silent_aim.rage_bot_wallbang and not silent_aim.isvisible then
                                        return old(self, unpack(args, 1, argCount))
                                    end
                                end
                                if lift_hitboxes_active() then
                                    local lift_h = silent_aim.lift_hitboxes_height or 2
                                    Destination = Destination + Vector3.new(0, lift_h, 0)
                                end
                                local real_aimpart = args[aimpart_index]
                                if not real_aimpart then
                                    return old(self, unpack(args, 1, argCount))
                                end
                                local old_cf = real_aimpart.CFrame
                                real_aimpart.CFrame = _CFramenew(real_aimpart.Position, Destination)
                                local ret = old(self, unpack(args, 1, argCount))
                                real_aimpart.CFrame = old_cf
                                return ret
                            else
                                return old(self, ...)
                            end
                        end), true)
                    end
                    if type(rawget(gc, "updateClient")) == "function" then
                        local old_update = gc.updateClient
                        cheat.utility.new_hook(old_update, LPH_JIT_MAX(function(old, ...)
                            local args = {...};
                            local argCount = select("#", ...);
                            if instantaim then
                                args[1].AimInSpeed = 0
                                args[1].AimOutSpeed = 0
                            end;
                            if forceauto then
                                args[1].FireMode = "Auto"
                            end
                            if unlock_firemodes and rawget(args[1], "FireModes") then
                                args[1].FireModes = {
                                    "Auto",
                                    "Semi"
                                }
                            end
                            if rapid_fire then
                                args[1].FireRate = rapid_fire_delay
                            end
                            if no_melee_cooldown and type(rawget(args[1], "MeleeWeaponDefault")) == "function" then
                                args[1].useDebounce = false
                            end
                            return old(unpack(args, 1, argCount))
                        end), true)
                        got_that = true
                    end
                end
            end
        end)() if not got_that then cheat._hook_retries = cheat._hook_retries + 1 print("Waiting For Player To Spawn", cheat._hook_retries) task.wait(0.25) end until got_that or cheat._hook_retries >= 4
        end)
        
    gunmodbox:AddToggle('gunmods_rapidfire', {Text = 'Rapid Fire', Default = false, Callback = function(first)
        rapid_fire = first
    end})
    task.wait()
    gunmodbox:AddSlider('gunmods_rapidfire_rate', {Text = 'Fire Rate (RPM)', Default = 1200, Min = 60, Max = 3000, Rounding = 0, Callback = function(v)
        rapid_fire_delay = 60 / v
    end})

    -- Force hit (moved here from the aimbot tab, under Rapid Fire).
    -- Three methods, each lies about a different part of the shot:
    --   instant hit         - back-dates the FireProjectile timestamp (args[3])
    --   Silent force-hit    - returns a fabricated RaycastResult from the Bullet module
    --   validation override - swaps only the hit-part arg on ProjectileInflict
    gunmodbox:AddToggle('silentaim_instant', {Text = 'Force Hit',Default = false,Callback = function(first)
        silent_aim.instant = first
    end})
    gunmodbox:AddDropdown('silentaim_instant_method', {
        Values = {'instant hit', 'Silent force-hit', 'validation override'},
        Default = 1,
        Multi = false,
        Text = 'Force Hit Method',
        Callback = function(v)
            if type(v) == "table" then v = v[1] or v.Value end
            if v then silent_aim.instant_method = v end
        end
    })
        
        gunmodbox:AddToggle('gunmods_norecoil', {Text = 'No Recoil',Default = false,Callback = function(first)
            norecoil = first
        end})

        -- Magic Bullet: fabricates the RaycastResult the Bullet module asks for, so
        -- the shot reports your silent-aim target instead of what the ray actually
        -- hit. Affects space (what the ray hits), not time -- see Instant Hit for
        -- the timing variant. The plausibility gate below still applies: the fake
        -- result is only returned when wallbang is on, the target is visible, or a
        -- manipulated origin was found.
        gunmodbox:AddToggle('gunmods_magic_bullet', {Text = 'Magic Bullet', Default = false, Callback = function(first)
            silent_aim.magic_bullet = first
        end})

        gunmodbox:AddToggle('gunmods_nospread', {Text = 'No Spread',Default = false,Callback = function(first)
            silent_aim.nospread = first
        end})
        gunmodbox:AddToggle('gunmods_nobob', {Text = 'No Gun Bob',Default = false,Callback = function(first)
            nobob = first
        end})
        gunmodbox:AddToggle('gunmods_instantaim', {Text = 'Instant Aim',Default = false,Callback = function(first)
            instantaim = first
        end})
    task.wait()
        gunmodbox:AddToggle('gunmods_unlockfiremodes', {Text = 'Unlock Firemodes',Default = false,Callback = function(first)
            unlock_firemodes = first
        end})

    task.wait()
        -- One Tap: a fixed 10-round burst in a single shot. The bullet-count slider and
        -- the whole charge-bar control group (width / height / Y offset) are gone
        -- along with the ramp they configured. The flag stays gunmods_chargeshot so
        -- existing configs keep working.
        local charge_shot_toggle = gunmodbox:AddToggle('gunmods_chargeshot', {
            Text = 'One Tap',
            Default = false,
            Tooltip = 'fires 10 rounds in a single shot -- nothing to charge',
            Callback = function(v)
                charge_shot_enabled = v == true
            end
        })
        gunmodbox:AddToggle('gunmods_instantreload', {Text = 'Instant Reload', Default = false, Callback = function(v)
            cheat._instant_reload = v and true or false
        end})
        gunmodbox:AddToggle('gunmods_autoreload', {Text = 'Auto Reload', Default = false, Callback = function(v)
            cheat._auto_reload = v and true or false
        end})
        -- Reload early instead of waiting for the magazine to run dry.
        gunmodbox:AddSlider('gunmods_autoreload_at', {
            Text = 'Auto Reload At',
            Default = 0, Min = 0, Max = 30, Rounding = 0,
            Suffix = ' bullets', Compact = true,
            Tooltip = 'reload once this many rounds are left in the magazine (0 = only when empty)',
            Callback = function(v) cheat._auto_reload_at = v end
        })
        gunmodbox:AddToggle('gunmods_autorefillmag', {Text = 'Auto Refill Mag', Default = false, Callback = function(v)
            auto_refill_mag = v
        end})
        salobox:AddDropdown('silentaim_method', {
            Values = {'Ghost hook old', 'new'},
            Default = 2,
            Multi = false,
            Text = 'Silent Aim Method',
            Tooltip = '"new" = swim-style fake_part + Bullet stack-checked Raycast redirect + ProjectileInflict seed-timing fix',
            Callback = function(v)
                silent_aim.method = v
            end
        })
        salobox:AddToggle('silentaim_enabled', {Text = 'Silent Aim',Default = false,Callback = function(first)
            silent_aim.enabled = first
        end}):AddKeyPicker('silentaim_bind', {Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Silent Aim', NoUI = false})
        salobox:AddDropdown('silentaim_hitreg', {Values = {'Head','FaceHitBox','HeadTopHitbox','UpperTorso','LowerTorso','HumanoidRootPart','LeftFoot','LeftLowerLeg','LeftUpperLeg','LeftHand','LeftLowerArm','LeftUpperArm','RightFoot','RightLowerLeg','RightUpperLeg','RightHand','RightLowerArm','RightUpperArm'},Default = 1,Multi = false,Text = 'Aim Part',Tooltip = 'select part',Callback = function(Value)
            silent_aim.part = Value
            silent_aim.selected_part = Value
        end})

        -- ─── Aim Assist (camera smoothing) ────────────────────────────────────
        -- This executor exposes no mousemoverel / mousemoveabs, so a true mouse-delta
        -- aimbot is not possible. Instead this steers the camera itself: it computes
        -- the direction to the current silent-aim target and lerps Camera.CFrame toward
        -- it, with the smoothness slider controlling how fast it converges. Bound at
        -- RenderPriority.Camera so it runs AFTER Roblox's camera controller each frame
        -- (otherwise the controller overwrites the change immediately).
        local aimassist_enabled = false
        local aimassist_held = false
        local aimassist_smooth = 6

        local aimassist_tog = salobox:AddToggle('aimassist_enabled', {
            Text = 'Aim Assist',
            Default = false,
            Tooltip = 'Smoothly steers the camera toward the current silent-aim target. Works on the camera, not the mouse.',
            Callback = function(v)
                aimassist_enabled = v and true or false
            end
        })
        aimassist_tog:AddKeyPicker('aimassist_key', {
            Default = 'None',
            SyncToggleState = false,
            Mode = 'Hold',
            Text = 'Aim Assist key',
            NoUI = false,
            Callback = function(active)
                aimassist_held = active and true or false
            end
        })
        salobox:AddSlider('aimassist_smoothness', {
            Text = 'Aim Smoothness',
            Default = 6,
            Min = 1,
            Max = 20,
            Rounding = 0,
            Tooltip = 'Higher = slower, smoother tracking. Lower = snappier.',
            Callback = function(v)
                aimassist_smooth = math.clamp(tonumber(v) or 6, 1, 20)
            end
        })

        if not cheat._aimassist_bound then
            cheat._aimassist_bound = true
            RunService:BindToRenderStep("PinRetaAimAssist", Enum.RenderPriority.Camera.Value, function()
                if not (aimassist_enabled and aimassist_held) then return end
                local cam = workspace.CurrentCamera
                local target = silent_aim and silent_aim.target_part
                if not cam or not target or not target.Parent then return end
                local eye = cam.CFrame.Position
                local goal = (target.Position - eye)
                if goal.Magnitude < 0.05 then return end
                local desired = CFrame.lookAt(eye, target.Position)
                -- smooth >= 1; blend factor shrinks as smoothing increases
                local alpha = math.clamp(1 / math.max(1, aimassist_smooth), 0.02, 1)
                cam.CFrame = cam.CFrame:Lerp(desired, alpha)
            end)
        end
        -- ═══════════════════════════════════════════════════════════════
        --  FULL RAGE BOT UI
        -- ═══════════════════════════════════════════════════════════════
        local ragebot_tab = ui.box.aimbot:AddTab('Rage Bot')
        ragebot_tab:AddToggle('ragebot_enabled', {
            Text = 'Rage Bot',
            Default = false,
            Tooltip = 'Full rage bot: ignores FOV, auto-fires, hitchance, prediction, backtrack',
            Callback = function(first)
                silent_aim.rage_bot = first
    task.wait()
                silent_aim.rage_bot_active = first
            end
        }):AddKeyPicker('ragebot_bind', {
            Default = 'None',
            SyncToggleState = true,
            Mode = 'Toggle',
            Text = 'Rage Bot',
            NoUI = false,
            Callback = function(v)
                silent_aim.rage_bot_active = v
            end
        })

        ragebot_tab:AddSlider('ragebot_max_dist', {
            Text = 'Rage Max Distance (m)',
            Default = 500,
            Min = 1,
            Max = 4000,
            Rounding = 0,
            Callback = function(v)
                silent_aim.rage_max_dist = v
                silent_aim.rage_bot_range = v
            end
        })

        ragebot_tab:AddSlider('ragebot_hitchance', {
            Text = 'Hit Chance (%)',
            Default = 100,
            Min = 1,
            Max = 100,
            Rounding = 0,
            Callback = function(v)
                silent_aim.rage_bot_hitchance = v
            end
        })

        ragebot_tab:AddSlider('ragebot_min_damage', {
            Text = 'Min Damage',
            Default = 1,
            Min = 1,
            Max = 100,
            Rounding = 0,
            Callback = function(v)
                silent_aim.rage_bot_min_damage = v
            end
        })

        ragebot_tab:AddDropdown('ragebot_prioritize', {
            Text = 'Target Priority',
            Default = 1,
            Values = { 'Distance', 'Health', 'FOV' },
            Callback = function(v)
                silent_aim.rage_bot_prioritize = v
            end
        })

        ragebot_tab:AddToggle('ragebot_auto_fire', {
            Text = 'Auto Fire',
            Default = true,
            Callback = function(v)
                silent_aim.rage_bot_auto_fire = v
            end
        })

        ragebot_tab:AddToggle('ragebot_head_only', {
            Text = 'Head Only',
            Default = true,
            Callback = function(v)
                silent_aim.rage_bot_head_only = v
                if v then silent_aim.part = "Head" end
            end
        })

        ragebot_tab:AddToggle('ragebot_prediction', {
            Text = 'Velocity Prediction',
            Default = true,
            Callback = function(v)
                silent_aim.rage_bot_prediction = v
            end
        })

        ragebot_tab:AddSlider('ragebot_prediction_mult', {
            Text = 'Prediction Multiplier',
            Default = 1.0,
            Min = 0.1,
            Max = 3.0,
            Rounding = 1,
            Callback = function(v)
                silent_aim.rage_bot_prediction_mult = v
            end
        })

        ragebot_tab:AddToggle('ragebot_backtrack', {
            Text = 'Backtrack',
            Default = false,
            Callback = function(v)
                silent_aim.rage_bot_backtrack = v
            end
        })

        ragebot_tab:AddSlider('ragebot_backtrack_ms', {
            Text = 'Backtrack MS',
            Default = 200,
            Min = 50,
            Max = 1000,
            Rounding = 0,
            Callback = function(v)
                silent_aim.rage_bot_backtrack_ms = v
            end
        })

        ragebot_tab:AddToggle('ragebot_wallbang', {
            Text = 'Auto Wallbang',
            Default = false,
            Callback = function(v)
                silent_aim.rage_bot_wallbang = v
            end
        })

        ragebot_tab:AddSlider('ragebot_wallbang_thickness', {
            Text = 'Max Wall Thickness',
            Default = 2.0,
            Min = 0.5,
            Max = 10,
            Rounding = 1,
            Callback = function(v)
                silent_aim.rage_bot_wallbang_thickness = v
            end
        })

        ragebot_tab:AddToggle('ragebot_auto_scope', {
            Text = 'Auto Scope',
            Default = false,
            Callback = function(v)
                silent_aim.rage_bot_auto_scope = v
            end
        })

        ragebot_tab:AddSlider('ragebot_shot_delay', {
            Text = 'Shot Delay (s)',
            Default = 0.05,
            Min = 0.01,
            Max = 1.0,
            Rounding = 2,
            Callback = function(v)
                silent_aim.rage_bot_shot_delay = v
    task.wait()
            end
        })

        -- ═══════════════════════════════════════════════════════════════
        salobox:AddToggle('silentaim_target_players', {Text = 'Target Players',Default = false,Callback = function(first)
            silent_aim.target_players = first
        end})
        salobox:AddToggle('silentaim_team_check', {Text = 'Team Check',Default = false,Callback = function(first)
            silent_aim.team_check = first
        end})
        salobox:AddToggle('silentaim_npcaim', {Text = 'Target AI',Default = false,Callback = function(first)
            silent_aim.target_npc = first
        end})
        salobox:AddToggle('silentaim_heliaim', {Text = 'Target Helicopters',Default = false,Callback = function(first)
            silent_aim.target_heli = first
        end})
        bullet_tracers_box:AddToggle('silentaim_tracer', {Text = 'Bullet Tracer',Default = false,Callback = function(Value)
            silent_aim.tracer = Value
        end}):AddColorPicker('silentaim_tracer_color',{Default = Color3.new(1, 1, 1),Title = 'Tracer Color',Transparency = 0,Callback = function(Value)
            if type(Value) == "table" then Value = Value.Color or Value.Value end
            if typeof(Value) == "Color3" then silent_aim.tracer_color = Value end
        end}):AddColorPicker('silentaim_tracer_color2',{Default = Color3.new(0, 0.5, 1),Title = 'Tracer Pulse Color',Transparency = 0,Callback = function(Value)
            if type(Value) == "table" then Value = Value.Color or Value.Value end
            if typeof(Value) == "Color3" then silent_aim.tracer_color2 = Value end
        end})
        bullet_tracers_box:AddDropdown('silentaim_tracer_style', {Values = {'Tracer 1', 'Tracer 2', 'Beam'}, Default = 1, Multi = false, Text = 'Tracer Style', Callback = function(v) silent_aim.tracer_style = v end})
        bullet_tracers_box:AddSlider('tracer_thickness', { Text = 'Tracer Thickness', Default = 0.5, Min = 0.1, Max = 10, Rounding = 1, Compact = true, Callback = function(v) silent_aim.tracer_thickness = v end })
        bullet_tracers_box:AddSlider('tracer_lifetime', { Text = 'Tracer Lifetime', Default = 1, Min = 0.1, Max = 5, Rounding = 1, Compact = true, Callback = function(v) silent_aim.tracer_lifetime = v end })
        salobox:AddToggle('silentaim_wallbang', {Text = 'Wallbang',Default = false,Callback = function(first)
            -- pin.reta V2 sets ONLY this flag. Ours additionally forced
            -- silent_aim.isvisible = true, which made the triggerbot treat every
            -- obstructed target as visible and fire through any wall of any
            -- thickness. That, not the material raycast, was the real source of the
            -- wallbang difference from V2, so it is gone.
            silent_aim.testwallbang = first
        end})

        -- Wallbang TP: teleport the root just PAST the blocking wall for one window
        -- and only let the trigger fire once the server's own UAC.LastVerifiedPos has
        -- converged on that origin, so the shot is credited from beyond the
        -- obstruction. A separate flag, so silentaim_wallbang keeps its exact
        -- pin.reta V2 behaviour.
        salobox:AddToggle('silentaim_wallbang_tp', {Text = 'Wallbang TP', Default = false, Tooltip = 'teleports you past the wall for one frame and fires only once the server has verified the new position', Callback = function(v)
            silent_aim.wallbang_tp = v
        end}):AddKeyPicker('wallbang_tp_bind', {
            -- Hold: the teleport only runs while the key is down. No Callback, so
            -- the bind never touches the master toggle.
            Default = 'None',
            SyncToggleState = false,
            Mode = 'Hold',
            Text = 'Wallbang TP',
            NoUI = false
        })
        
        salobox:AddToggle('silentaim_corner', {Text = 'Corner Shoot',Default = false,Callback = function(first)
            silent_aim.corner_shoot = first
        end})
        salobox:AddSlider('silentaim_corner_dist', {Text = 'Corner Shoot Distance', Default = 5, Min = 5, Max = 15, Rounding = 0, Callback = function(v)
            silent_aim.corner_shoot_dist = v
        end})
        
        statusbarbox:AddToggle('silentaim_crosshairstat', {Text = 'Crosshair Status Bar',Default = false,Callback = function(first)
            silent_aim.crosshair_status = first
        end})
        statusbarbox:AddToggle('silentaim_crosshairstat_always', {Text = 'Force Status Bar',Default = false,Callback = function(first)
            silent_aim.crosshair_status_always = first
        end})
        statusbarbox:AddSlider('silentaim_status_width', {Text = 'Status Bar Width', Default = 100, Min = 10, Max = 300, Rounding = 0, Callback = function(v)
            silent_aim.status_bar_width = v
        end})
        statusbarbox:AddSlider('silentaim_status_height', {Text = 'Status Bar Height', Default = 6, Min = 1, Max = 50, Rounding = 0, Callback = function(v)
            silent_aim.status_bar_height = v
        end})
        statusbarbox:AddSlider('silentaim_status_offset', {Text = 'Status Bar Offset', Default = 32, Min = -100, Max = 200, Rounding = 0, Callback = function(v)
            silent_aim.status_bar_offset = v
        end})
        
        local resolve_desync = false
        local resolve_desync_tab = player_anti_aim_tab
        resolve_desync_tab:AddToggle('resolve_desync', {Text = 'Resolve Desync', Default = false, Callback = function(v)
            resolve_desync = v
        end}):AddKeyPicker('resolve_desync_bind', {Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Resolve Desync'})
        
        local hitbox_adjust_was_active = false
        cheat.utility.new_renderstepped(function()
            local resolve_desync_active = feature_active(resolve_desync, 'resolve_desync_bind')
            local lift_active = lift_hitboxes_active()
            if not resolve_desync_active and not lift_active then
                if not hitbox_adjust_was_active then
                    return
                end
                hitbox_adjust_was_active = false
            else
                hitbox_adjust_was_active = true
            end

            local rep_players = ReplicatedStorage:FindFirstChild("Players")
            if not rep_players then return end
            -- We loop over all players to handle either desync resolution or hitbox lifting (physically shifting the character models up by 2 studs)
            for _, player in ipairs(Players:GetPlayers()) do
                if player ~= LocalPlayer then
                    local character = player.Character
                    local root = character and character:FindFirstChild("HumanoidRootPart")
                    if root then
                        -- Resolve desync location / lift hitboxes without accumulating offsets
                        local p_folder = rep_players:FindFirstChild(player.Name)
                        local status = p_folder and p_folder:FindFirstChild("Status")
                        local uac = status and status:FindFirstChild("UAC")
                        local lastpos = uac and uac:GetAttribute("LastVerifiedPos")
                        
                        if resolve_desync_active and lastpos and typeof(lastpos) == "Vector3" then
                            local base_cf = (root.CFrame - root.Position) + lastpos
                            if lift_active then
                                local lift_h = silent_aim.lift_hitboxes_height or 2
                                root.CFrame = base_cf + Vector3.new(0, lift_h, 0)
                            else
                                root.CFrame = base_cf
                            end
                        else
                            -- Fallback for when LastVerifiedPos is not available or resolver is off (keeps baseline in sync)
                            local current_cf = root.CFrame
                            local last_lifted = root:GetAttribute("LastLiftedCFrame")
                            local base_cf = current_cf
                            
                            if last_lifted and typeof(last_lifted) == "CFrame" then
                                local last_h = root:GetAttribute("LastLiftedHeight") or 2
                                -- If the current Y matches our previously lifted Y closely, we preserve the new horizontal movement (X, Z) 
                                -- from Roblox's replication engine but strip our vertical lift to find the true baseline.
                                if math.abs(current_cf.Position.Y - last_lifted.Position.Y) < 0.05 then
                                    base_cf = current_cf - Vector3.new(0, last_h, 0)
                                end
                            end
                            
                            if lift_active then
                                local lift_h = silent_aim.lift_hitboxes_height or 2
                                local new_cf = base_cf + Vector3.new(0, lift_h, 0)
                                root.CFrame = new_cf
                                root:SetAttribute("LastLiftedCFrame", new_cf)
                                root:SetAttribute("LastLiftedHeight", lift_h)
                            else
                                root.CFrame = base_cf
                                root:SetAttribute("LastLiftedCFrame", nil)
                                root:SetAttribute("LastLiftedHeight", nil)
                            end
                        end
                    end
                end
            end
        end)
        salobox:AddToggle('silentaim_random_part', {Text = 'Random Hit Part', Default = false, Callback = function(Value)
            silent_aim.random_part = Value
        end})
        aim_miscbox:AddToggle('silentaim_lifthitbox', {Text = 'Lift Hitboxes', Default = false, Callback = function(Value)
            silent_aim.lift_hitboxes = Value
        end}):AddKeyPicker('lifthitboxes_bind', {Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Lift Hitboxes', NoUI = false})
        aim_miscbox:AddSlider('silentaim_lifthitbox_height', {Text = 'Lift Height', Default = 2, Min = 1, Max = 10, Rounding = 1, Callback = function(v)
            silent_aim.lift_hitboxes_height = v
        end})
        aim_miscbox:AddToggle('silentaim_target_chams', {Text = 'Target Chams', Default = false, Callback = function(Value)
            silent_aim.target_chams = Value
        end}):AddColorPicker('silentaim_target_chams_color', {Default = Color3.fromRGB(255, 60, 60), Title = 'Target Chams Color', Transparency = 0.25, Callback = function(Value, Alpha)
            silent_aim.target_chams_color = Value
            silent_aim.target_chams_transparency = Alpha or silent_aim.target_chams_transparency
    task.wait()
        end})
        
        local tbot_tab = triggerbotbox
        tbot_tab:AddToggle('triggerbot_enabled', {Text = 'Triggerbot', Default = false, Callback = function(v) silent_aim.triggerbot = v end}):AddKeyPicker('triggerbot_bind', {Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Triggerbot', NoUI = false})
        tbot_tab:AddToggle('triggerbot_manip', {Text = 'Shoot on Manipulated', Default = false, Callback = function(v) silent_aim.triggerbot_manipulation = v end})
        tbot_tab:AddSlider('triggerbot_hitchance', {
            Text = 'Hit Chance (%)',
            Default = 100,
            Min = 1,
            Max = 100,
            Rounding = 0,
            Callback = function(v)
                -- value is stored; no extra logic needed
            end
        })
        -- Peek Blink: freezes the replicated position while peeking and snaps
        -- back to the recorded spot the instant a bullet is created. The toggle is
        -- owned here; the create-bullet hook in this same block reads
        -- `cheat._peek_blink_active`, so state is shared by reference not by scope.
        local blink_table = {}
        local blink_visual_part = nil
        local blink_visual_beam = nil

        tbot_tab:AddToggle('peek_blink', {
            Text = 'Peek Blink',
            Default = false,
            Tooltip = 'Freezes your server position while peeking, then snaps you back to the recorded spot the moment you shoot.',
            Callback = function(v)
                cheat._peek_blink_active = v and true or false
                if v then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp then
                        cheat._peek_blink_pos = hrp.CFrame

                        local startpart = Instance.new("Part")
                        startpart.Name = "PinReta_BlinkOrigin"
                        startpart.CanCollide = false
                        startpart.CanQuery = false
                        startpart.Transparency = 0.5
                        startpart.Material = Enum.Material.ForceField
                        startpart.Color = Color3.fromRGB(255, 255, 255)
                        startpart.Size = hrp.Size
                        startpart.CFrame = hrp.CFrame
                        startpart.Anchored = true
                        startpart.Parent = workspace

                        local beam = Instance.new("Beam")
                        beam.Name = "PinReta_BlinkBeam"
                        beam.Attachment0 = Instance.new("Attachment", startpart)
                        beam.Attachment1 = Instance.new("Attachment", hrp)
                        beam.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
                        beam.Width0 = 0.1
                        beam.Width1 = 0.1
                        beam.FaceCamera = true
                        beam.LightEmission = 1
                        beam.Parent = workspace

                        local highlight = Instance.new("Highlight")
                        highlight.Name = "PinReta_BlinkHighlight"
                        highlight.FillColor = Color3.fromRGB(255, 255, 255)
                        highlight.OutlineColor = Color3.fromRGB(255, 255, 255)
                        highlight.FillTransparency = 0.5
                        highlight.OutlineTransparency = 1
                        highlight.Adornee = startpart
                        highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                        highlight.Parent = startpart

                        blink_visual_part = startpart
                        blink_visual_beam = beam
                    end
                else
                    if blink_visual_part then pcall(function() blink_visual_part:Destroy() end) blink_visual_part = nil end
                    if blink_visual_beam then pcall(function() blink_visual_beam:Destroy() end) blink_visual_beam = nil end
                    if cheat._peek_blink_pos and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
                        LocalPlayer.Character.HumanoidRootPart.CFrame = cheat._peek_blink_pos
                    end
                    cheat._peek_blink_pos = nil
                end
            end
        }):AddKeyPicker('peek_blink_key', {
            Default = 'U',
            SyncToggleState = true,
            Mode = 'Toggle',
            Text = 'Peek Blink key',
            NoUI = false
        })

        -- Freeze the replicated position every frame while the blink is armed.
        -- The toggle is the master switch; the Peek Blink bind gates it further once a
        -- key is assigned (keybind_allows treats "None" as no extra gate).
        cheat.utility.new_heartbeat(function()
            if not (cheat._peek_blink_active and keybind_allows('peek_blink_key', false)) then return end
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            blink_table[1] = hrp.CFrame
            blink_table[2] = hrp.AssemblyLinearVelocity
            hrp.Anchored = true
            RunService.RenderStepped:Wait()
            if hrp and hrp.Parent then
                hrp.Anchored = false
                hrp.CFrame = blink_table[1]
                hrp.AssemblyLinearVelocity = blink_table[2]
            end
        end)

        fovbox:AddToggle('silentaim_fov', {Text = 'Use FOV',Default = false,Callback = function(Value)
            silent_aim.fov = Value
        end})
        gunmodbox:AddToggle('instant_equip', {Text = 'Instant Equip', Default = false, Callback = function(v)
            instant_equip = v
        end})
        -- Instant equip: hook camera for ViewModel equip animation
        cheat.utility.track_connection(Camera.ChildAdded:Connect(function(child)
            if not instant_equip then return end
            if child.Name == LocalPlayer.Name then return end
            if not child:IsA("Model") then return end
            task.spawn(function()
                local iters = 0
                while child.Parent and iters < 500 do
                    iters = iters + 1
                    local hum = child:FindFirstChild("Humanoid")
                    if hum and hum.Animator then
                        for _, track in ipairs(hum.Animator:GetPlayingAnimationTracks()) do
                            if track.Animation.Name == "Equip" then
                                pcall(function()
                                    track:AdjustSpeed(15)
                                    track.TimePosition = track.Length - 0.01
                                end)
                                return
                            end
                        end
                    end
                    task.wait(0.02)
                end
            end)
        end))
        local Depbox1 = fovbox:AddDependencyBox();
        Depbox1:AddToggle('silentaim_fov_show', {Text = 'Show FOV',Default = false,Callback = function(Value)
            silent_aim.fov_show = Value
        end}):AddColorPicker('silentaim_fov_color',{Default = Color3.new(1, 1, 1),Title = 'FOV Color',Transparency = 0,Callback = function(Value)
            silent_aim.fov_color = Value
        end})
        Depbox1:AddToggle('silentaim_fov_outline', {Text = 'FOV Outline',Default = false,Callback = function(Value)
            silent_aim.fov_outline = Value
        end})
        Depbox1:AddSlider('silentaim_fov_size',{Text = 'FOV Radius',Default = 100,Min = 10,Max = 1000,Rounding = 0,Compact = true,Callback = function(State)
            silent_aim.fov_size = State
    task.wait()
        end})
        Depbox1:AddSlider('silentaim_fov_glow_intensity',{Text = 'FOV Glow Intensity',Default = 1,Min = 0.1,Max = 10,Rounding = 1,Compact = true,Callback = function(v)
            silent_aim.fov_glow_intensity = v
        end})
        Depbox1:SetupDependencies({
            { cheat.Toggles.silentaim_fov, true }
        });
        local CircleInline = cheat.utility.new_drawing("Circle", {
            Transparency = 1,
            Thickness = 1,
            ZIndex = 2,
            Visible = false,
        })
        local StatusBarBg = cheat.utility.new_drawing("Square", {
            Filled = true,
            Color = Color3.new(0, 0, 0),
            ZIndex = 2,
            Visible = false,
        })

        local StatusBarFill = cheat.utility.new_drawing("Square", {
            Filled = true,
            ZIndex = 3,
            Visible = false,
        })
        local fov_glow = {}
        for i = 1, 20 do
            fov_glow[i] = cheat.utility.new_drawing("Circle", {
                Thickness = 1,
                ZIndex = 1,
                Visible = false
            })
        end
        local target_chams_highlight = cheat.utility.track_instance(Instance.new("Highlight"))
        target_chams_highlight.Name = "GhostHookTargetHighlight"
        target_chams_highlight.Enabled = false
        target_chams_highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        target_chams_highlight.Parent = game:GetService("CoreGui")
        local fov_glow_was_visible = false
        cheat.utility.new_renderstepped(LPH_NO_VIRTUALIZE(function()
            local pos = (_Vector2new(Mouse.X, Mouse.Y + GuiInset.Y))
            local fov_visible = silent_aim.fov and silent_aim.fov_show
            local glow_visible = silent_aim.fov and silent_aim.fov_show and silent_aim.fov_outline
            if fov_visible then
                CircleInline.Position = pos
                CircleInline.Radius = silent_aim.fov_size
                CircleInline.Color = silent_aim.fov_color
                CircleInline.Visible = true
            elseif CircleInline.Visible then
                CircleInline.Visible = false
            end

            if glow_visible then
                local intensity = silent_aim.fov_glow_intensity
                local thickness = 1 + (intensity * 0.5)
                for i = 1, 10 do
                    local out_circle = fov_glow[i]
                    out_circle.Position = pos
                    out_circle.Radius = silent_aim.fov_size + (i * (intensity * 0.5))
                    out_circle.Color = silent_aim.fov_color
                    out_circle.Transparency = (0.2 - (i * 0.02))
                    out_circle.Thickness = thickness
                    out_circle.Visible = true

                    local in_circle = fov_glow[i+10]
                    in_circle.Position = pos
                    in_circle.Radius = math.max(0, silent_aim.fov_size - (i * (intensity * 0.5)))
                    in_circle.Color = silent_aim.fov_color
                    in_circle.Transparency = (0.2 - (i * 0.02))
                    in_circle.Thickness = thickness
                    in_circle.Visible = true
                end
                fov_glow_was_visible = true
            elseif fov_glow_was_visible then
                for i = 1, 20 do
                    fov_glow[i].Visible = false
                end
                fov_glow_was_visible = false
            end
            
            local status_bar_forced = silent_aim.crosshair_status_always
            local status_bar_active = silent_aim_active()
            if silent_aim.crosshair_status and (status_bar_active or status_bar_forced) then
                local barWidth = silent_aim.status_bar_width or 100
                local barHeight = silent_aim.status_bar_height or 6
                local barOffset = silent_aim.status_bar_offset or 32
                
                -- TP Kill bar standard position starts at screen center Y + 20 and has height 6.
                -- We place our status bar below it dynamically.
                local viewport = Camera.ViewportSize
                local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
                local barPos = center + Vector2.new(-barWidth / 2, 20 + 6 + barOffset)
                
                local ratio = 1
                local barColor = Color3.new(0, 0, 0)
                
                if not silent_aim.target_part then
                    ratio = 0
                    barColor = Color3.fromRGB(60, 60, 60)
                elseif silent_aim.isvisible then
                    ratio = 1
                    barColor = Color3.new(0, 1, 0)
                elseif silent_aim.manipulated and silent_aim.manipulated_origin then
                    local camera = workspace.CurrentCamera
                    local dist = 0
                    if camera then
                        dist = (silent_aim.manipulated_origin - camera.CFrame.Position).Magnitude
                    end
                    if dist <= 5 then
                        ratio = 1
                        barColor = Color3.new(0, 1, 0)
                    else
                        local t = math.clamp((dist - 5) / 10, 0, 1)
                        ratio = 1 - t
                        barColor = Color3.new(t, 1, 0)
                    end
                else
                    ratio = 0
                    barColor = Color3.new(1, 0, 0)
                end
                
                StatusBarBg.Position = barPos - Vector2.new(1, 1)
                StatusBarBg.Size = Vector2.new(barWidth + 2, barHeight + 2)
                StatusBarBg.Color = Color3.fromRGB(20, 20, 20)
                StatusBarBg.Visible = true
                
                StatusBarFill.Position = barPos
                StatusBarFill.Size = Vector2.new(barWidth * ratio, barHeight)
                StatusBarFill.Color = barColor
                StatusBarFill.Visible = true
            else
                StatusBarBg.Visible = false
                StatusBarFill.Visible = false
            end

            local target_model = silent_aim.target_part and silent_aim.target_part.Parent
            if silent_aim.target_chams and target_model then
                target_chams_highlight.Enabled = true
                target_chams_highlight.Adornee = target_model
                target_chams_highlight.FillColor = silent_aim.target_chams_color
                target_chams_highlight.OutlineColor = silent_aim.target_chams_color
                target_chams_highlight.FillTransparency = silent_aim.target_chams_transparency
                target_chams_highlight.OutlineTransparency = 0.05
            else
                target_chams_highlight.Enabled = false
                target_chams_highlight.Adornee = nil
    task.wait()
            end
        end))
        local random_part_timer = tick()
        local available_random_parts = {"Head", "UpperTorso", "LowerTorso", "LeftUpperLeg", "RightUpperLeg", "LeftLowerArm", "RightLowerArm"}
        local target_scan_interval = 1 / 20
        local fast_target_scan_interval = 1 / 30
        local last_target_scan = 0
        local last_triggerable_scan = 0
        local corner_search_interval = 0.12
        local last_corner_search = 0
        local corner_params = RaycastParams.new()
        corner_params.FilterType = Enum.RaycastFilterType.Exclude
        corner_params.IgnoreWater = true
    -- --- HITSCAN TELEPORT + CAMERA GUARD (ported verbatim from pin.reta V2) ----
    -- Teleports the root to the solved origin for a single frame so the shot is
    -- credited from there, then restores. The camera is deliberately pinned to
    -- its pre-spoof transform (bound at RenderPriority.Last) so Roblox's camera
    -- controller cannot follow the temporary firing position.
    -- Keep the root spoof alive until the render boundary, but pin the camera
    -- to its pre-spoof transform so Roblox's camera controller cannot follow
    -- the temporary firing position.
    local function restore_hitscan_spoof(state, restore_camera)
        if not state then return end

        if restore_camera then
            local camera = state.camera
            if camera and camera.Parent then
                local camera_cframe = camera.CFrame
                local camera_displacement = camera_cframe.Position
                    - state.camera_cframe.Position
                local root_displacement = state.replicated_cframe.Position
                    - state.root_cframe.Position
                local correction = nil

                if root_displacement.Magnitude > 0.001 then
                    local follow_error = (camera_displacement - root_displacement).Magnitude
                    local follow_tolerance = math.max(8, root_displacement.Magnitude * 0.2)
                    if follow_error <= follow_tolerance then
                        -- Preserve this frame's rotation/FOV matrix and remove
                        -- only the translation inherited from the root spoof.
                        correction = -root_displacement
                    elseif camera_displacement.Magnitude > math.max(12, root_displacement.Magnitude * 0.5) then
                        -- Fallback for custom camera controllers that do not
                        -- follow the character by the exact root delta.
                        correction = state.camera_cframe.Position - camera_cframe.Position
                    end
                end

                if correction then
                    camera.CFrame = camera_cframe + correction
                    camera.Focus = camera.Focus + correction
                end
            end
        end

        local root = state.root
        if root and root.Parent
            and (root.Position - state.replicated_cframe.Position).Magnitude <= 0.5
        then
            root.CFrame = state.root_cframe
            root.AssemblyLinearVelocity = state.root_velocity
        end

        if cheat._hitscan_restore_state == state then
            cheat._hitscan_restore_state = nil
        end
    end

    pcall(function()
        RunService:UnbindFromRenderStep("PinRetaHitscanCameraGuard")
    end)
    RunService:BindToRenderStep(
        "PinRetaHitscanCameraGuard",
        Enum.RenderPriority.Last.Value,
        function()
            restore_hitscan_spoof(cheat._hitscan_restore_state, true)
        end
    )

    local function apply_hitscan_player_spoof()
        -- Recover first if a render was skipped while the window was minimized
        -- or Roblox otherwise missed the previous render callback.
        restore_hitscan_spoof(cheat._hitscan_restore_state, true)

        local fired_at = silent_aim._hitscan_fire_tick
        if not (silent_aim.hitscanning
            and silent_aim.manipulated_origin
            and silent_aim.target_part
            and type(fired_at) == "number")
        then
            return
        end

        local hold_time = silent_aim.hitscan_ticking
            and math.clamp(tonumber(silent_aim.hitscan_tick_value) or 0.03, 0.016, 0.15)
            or 0.03
        if tick() - fired_at > hold_time then
            return
        end

        local toggles = cheat.Toggles
        if cheat.freecam_enabled
            or (toggles and toggles.desync_enabled and toggles.desync_enabled.Value)
            or (toggles and toggles.peek_blink and toggles.peek_blink.Value)
            or (toggles and toggles.tpkill_enabled and toggles.tpkill_enabled.Value)
        then
            return
        end

        local camera = workspace.CurrentCamera
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local head = character and character:FindFirstChild("Head")
        local target_part = silent_aim.target_part
        if not (camera and root and target_part and target_part.Parent) then
            return
        end

        local replicated_cframe
        if silent_aim.origin_method == "manipulation" then
            if not head then
                return
            end
            -- The fixed-point result is a head-relative origin, so translate the full
            -- character by the same delta and land the Head on that origin.
            local head_delta = silent_aim.manipulated_origin - head.Position
            replicated_cframe = root.CFrame + head_delta
        else
            -- Preserve Pin's original Hitscan destination and orientation.
            replicated_cframe = CFrame.new(silent_aim.manipulated_origin, target_part.Position)
        end
        cheat._hitscan_restore_state = {
            camera = camera,
            camera_cframe = camera.CFrame,
            root = root,
            root_cframe = root.CFrame,
            root_velocity = root.AssemblyLinearVelocity,
            replicated_cframe = replicated_cframe,
            origin_method = silent_aim.origin_method,
        }
        root.CFrame = replicated_cframe
        return true
    end

    -- --- WALLBANG TP: TELEPORT PAST THE WALL, GATED ON LastVerifiedPos ----------
    -- Magic Bullet only fabricates the CLIENT-side collision result; the server still
    -- rebuilds the shot origin from its own record, because the shot remote carries a
    -- direction and not a position. That record is UAC.LastVerifiedPos. So Wallbang TP
    -- moves the apex of the shot: solve an origin just PAST the blocking wall, teleport
    -- the root onto it, and let the trigger fire only once LastVerifiedPos has actually
    -- converged there -- firing earlier credits the shot from behind the wall.
    --
    -- Everything lives on cheat.wallbang_tp on purpose: this chunk already sits at Lua's
    -- 200-local ceiling, so declaring locals here breaks compilation outright.
    cheat.wallbang_tp = {
        max_step = 40,      -- studs; refuse absurd teleports
        tolerance = 3,      -- LastVerifiedPos must land this close to count
        wait_max = 0.18,    -- stop waiting for the server after this long
        settle = 0.05,      -- hold the spoof this long past convergence
    }

    -- Is silent aim's LOCKED target actually inside the FOV circle? Used to gate the
    -- teleport so it cannot fire off a stale or peripheral lock.
    cheat.wallbang_tp.target_in_fov = function()
        local target = silent_aim.target_part
        if not target then return false end
        local camera = workspace.CurrentCamera
        if not camera then return false end
        local sp, on_screen = _WorldToViewportPoint(camera, target.Position)
        if not on_screen then return false end
        if not silent_aim.fov then return true end
        local vp = camera.ViewportSize
        local dx = sp.X - (vp.X * 0.5)
        local dy = sp.Y - (vp.Y * 0.5)
        return math.sqrt(dx * dx + dy * dy) <= (silent_aim.fov_size or 100)
    end

    cheat.wallbang_tp.last_verified_pos = function()
        local rp = ReplicatedStorage:FindFirstChild("Players")
        local p_folder = rp and rp:FindFirstChild(LocalPlayer.Name)
        local status = p_folder and p_folder:FindFirstChild("Status")
        local uac = status and status:FindFirstChild("UAC")
        local pos = uac and uac:GetAttribute("LastVerifiedPos")
        return typeof(pos) == "Vector3" and pos or nil
    end

    -- Walk the shot line to the first obstruction, step past its far face along the same
    -- line, and accept the spot only if the target is genuinely exposed from there.
    cheat.wallbang_tp.solve = function(cam_origin, target_pos)
        if not (cam_origin and target_pos) then return nil end
        local self = cheat.wallbang_tp
        local filter = { LocalPlayer.Character, workspace.CurrentCamera }
        local target_char = silent_aim.target_part and silent_aim.target_part.Parent
        if target_char then table.insert(filter, target_char) end
        local noc = workspace:FindFirstChild("NoCollision")
        if noc then table.insert(filter, noc) end

        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Exclude
        params.IgnoreWater = true
        params.FilterDescendantsInstances = filter

        local ray = target_pos - cam_origin
        if ray.Magnitude < 0.05 then return nil end
        local hit = workspace:Raycast(cam_origin, ray, params)
        if not (hit and hit.Instance) then return nil end   -- clear line: nothing to solve

        local size = hit.Instance.Size
        local thickness = math.min(size.X, size.Y, size.Z)
        local candidate = hit.Position + ray.Unit * (thickness + 0.6)
        if (candidate - cam_origin).Magnitude > self.max_step then return nil end

        local probe = workspace:Raycast(candidate, target_pos - candidate, params)
        if probe and probe.Instance then return nil end
        return candidate
    end

    -- True once the server's own record has caught up with our teleport.
    cheat.wallbang_tp.ready = function()
        local self = cheat.wallbang_tp
        local origin = silent_aim._wallbang_origin
        local armed = silent_aim._wallbang_arm_tick
        if not (origin and armed) then return false end
        if tick() - armed > self.wait_max then return false end
        local verified = self.last_verified_pos()
        if not verified then return false end
        return (verified - origin).Magnitude <= self.tolerance
    end

    cheat.wallbang_tp.clear = function()
        silent_aim._wallbang_origin = nil
        silent_aim._wallbang_arm_tick = nil
        silent_aim._wallbang_ready = false
    end

    cheat.wallbang_tp.apply = function()
        local self = cheat.wallbang_tp
        -- recover first, exactly like the hitscan window
        restore_hitscan_spoof(cheat._wallbang_restore_state, true)
        cheat._wallbang_restore_state = nil

        local origin = silent_aim._wallbang_origin
        local armed = silent_aim._wallbang_arm_tick
        if not (origin and armed) then return end
        if tick() - armed > self.wait_max + self.settle then
            self.clear()
            return
        end

        local toggles = cheat.Toggles
        if cheat.freecam_enabled
            or (toggles and toggles.desync_enabled and toggles.desync_enabled.Value)
            or (toggles and toggles.peek_blink and toggles.peek_blink.Value)
            or (toggles and toggles.tpkill_enabled and toggles.tpkill_enabled.Value)
        then
            return
        end

        local camera = workspace.CurrentCamera
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local target_part = silent_aim.target_part
        if not (camera and root and target_part and target_part.Parent) then return end

        local replicated_cframe = CFrame.new(origin, target_part.Position)
        cheat._wallbang_restore_state = {
            camera = camera,
            camera_cframe = camera.CFrame,
            root = root,
            root_cframe = root.CFrame,
            root_velocity = root.AssemblyLinearVelocity,
            replicated_cframe = replicated_cframe,
        }
        root.CFrame = replicated_cframe
    end

    -- --- TP KILL TELEPORT VERIFICATION ------------------------------------------
    -- TP Kill drops you ~200 studs above the target, but the hit is still credited from
    -- whatever position the server believes you hold (UAC.LastVerifiedPos). Firing the
    -- instant the teleport lands credits the shot from the ground, so the kill does not
    -- register. Same idea as Wallbang TP: wait for the server to catch up before firing.
    cheat.tpkill = {
        tolerance = 4,
        wait_max = 0.45,
        -- One frame after the trigger actually presses. A literal 1 ms is below
        -- Roblox's 16.7 ms frame, so the shot would never be discharged; one frame
        -- is the shortest window that still lands the round.
        settle = 0.02,
        -- Safety net: if nothing ever fired, do not hang above the target.
        max_hold = 0.15,
    }
    cheat.tpkill.destination = nil
    cheat.tpkill.arm_tick = nil
    cheat.tpkill.verified = false
    cheat.tpkill.verified_at = nil
    cheat.tpkill.fired_at = nil
    cheat.tpkill.returning = false

    cheat.tpkill.arm = function(destination)
        cheat.tpkill.destination = destination
        cheat.tpkill.arm_tick = tick()
        cheat.tpkill.verified = false
        cheat.tpkill.verified_at = nil
        cheat.tpkill.fired_at = nil
        cheat.tpkill.returning = false
    end

    cheat.tpkill.clear = function()
        cheat.tpkill.destination = nil
        cheat.tpkill.arm_tick = nil
        cheat.tpkill.verified = false
        cheat.tpkill.verified_at = nil
        cheat.tpkill.fired_at = nil
        cheat.tpkill.returning = false
    end

    -- Snap back to the recorded position the moment the round is away. Runs on the same
    -- heartbeat as the wallbang window; it never waits for the toggle.
    cheat.tpkill.update = function()
        local self = cheat.tpkill
        if self.returning then return end
        local dest = self.destination
        local armed = self.arm_tick
        if not (dest and armed) then return end

        local now = tick()
        if not self.verified then
            local lvp = cheat.wallbang_tp.last_verified_pos()
            if lvp and (lvp - dest).Magnitude <= self.tolerance then
                self.verified = true
            elseif now - armed > self.wait_max then
                self.verified = true   -- give up waiting and shoot anyway
            end
        end
        if self.verified and not self.verified_at then
            self.verified_at = now
        end

        -- the trigger presses only once triggerable clears, i.e. after verification
        if silent_aim._trigger_held and not self.fired_at then
            self.fired_at = now
        end

        local done = self.fired_at and (now - self.fired_at) >= self.settle
        local stalled = self.verified_at and (now - self.verified_at) >= self.max_hold
        if not (done or stalled) then return end

        self.returning = true
        if cheat._tpkill_force_off then
            pcall(cheat._tpkill_force_off)
        end
    end

    -- true while a teleport is still waiting for the server. Once verified (or once the
    -- wait expires, so the player is never left unable to shoot) this returns false.
    cheat.tpkill.awaiting_verification = function()
        local self = cheat.tpkill
        local dest = self.destination
        local armed = self.arm_tick
        if not (dest and armed) then return false end
        if self.verified then return false end
        local verified = cheat.wallbang_tp.last_verified_pos()
        if verified and (verified - dest).Magnitude <= self.tolerance then
            self.verified = true
            return false
        end
        if tick() - armed > self.wait_max then
            self.verified = true
            return false
        end
        return true
    end

    cheat.utility.track_connection(RunService.Heartbeat:Connect(function()
        apply_hitscan_player_spoof()
        cheat.wallbang_tp.apply()
        cheat.tpkill.update()
    task.wait()
    end))

        -- --- MANIPULATION FIXED-POINT CATALOG (ported verbatim from pin.reta V2) ---
        -- Head-relative fake-origin catalogue: a proven inner set, deterministic
        -- outer rings out to the configured radius, and an underground set. Every
        -- candidate is ray-validated nearest-first, so the first hit is always the
        -- closest origin that actually works. Origin is head-relative, not absolute.
    local _hitscan_params = RaycastParams.new()
    _hitscan_params.FilterType = Enum.RaycastFilterType.Exclude
    _hitscan_params.CollisionGroup = "WeaponRay"
    _hitscan_params.IgnoreWater = true
    -- Manipulation uses ordinary exclusion rays and does not force Pin's
    -- WeaponRay collision group.
    local _manipulation_params = RaycastParams.new()
    _manipulation_params.FilterType = Enum.RaycastFilterType.Exclude
    _manipulation_params.IgnoreWater = true
    local _hitscan_offsets = {
        Vector3.new(0.5, 0, 0), Vector3.new(-0.5, 0, 0),
        Vector3.new(0, 0, 0.5), Vector3.new(0, 0, -0.5),
        Vector3.new(0, 0.5, 0), Vector3.new(0, -0.5, 0),
        Vector3.new(0.5, 0.5, 0), Vector3.new(0.5, -0.5, 0),
        Vector3.new(-0.5, 0.5, 0), Vector3.new(-0.5, -0.5, 0),
        Vector3.new(0, 0.5, 0.5), Vector3.new(0, -0.5, 0.5),
        Vector3.new(0, 0.5, -0.5), Vector3.new(0, -0.5, -0.5),
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        Vector3.new(0, 1, 0), Vector3.new(0, -1, 0),
    }
    -- Proven fixed manipulation points from the fixed-point ray system. They
    -- stay head-relative and are sorted by true distance before every scan so
    -- the first working result is always the closest available fixed offset.
    local _manipulation_fixed_offsets = {
        Vector3.new(3, 0, 0), Vector3.new(-3, 0, 0), Vector3.new(-6, 0, 0),
        Vector3.new(6, 0, 0), Vector3.new(3, 2, 0), Vector3.new(-3, 2, 0),
        Vector3.new(-6, 2, 0), Vector3.new(6, 2, 0), Vector3.new(4, 0, 0),
        Vector3.new(-4, 2, 0), Vector3.new(-4, 0, 0), Vector3.new(4, 2, 0),
        Vector3.new(7, 0, 0), Vector3.new(-7, 2, 0), Vector3.new(-7, 0, 0),
        Vector3.new(7, 2, 0), Vector3.new(0.2, 3.9, 0), Vector3.new(1.8, 4.1, 1),
        Vector3.new(2.1, 4.4, 1.1), Vector3.new(0.15, 5.2, 0.1),
        Vector3.new(-1.8, 5.4, -0.2), Vector3.new(-2.3, 6.35, -0.4),
        Vector3.new(0.1, 7.5, 0), Vector3.new(0.1, 8, 0),
    }
    -- Deterministic outer fixed rings extend the original proven catalog to
    -- the requested 30-stud radius. Each point is still ray-validated before
    -- use and the combined list remains sorted nearest-first.
    local _manipulation_outer_fixed_radii = {10, 12, 15, 18, 21, 24, 27, 30}
    local _manipulation_outer_fixed_directions = {
        Vector3.new(1, 0, 0), Vector3.new(-1, 0, 0),
        Vector3.new(0, 0, 1), Vector3.new(0, 0, -1),
        Vector3.new(0, 1, 0),
        Vector3.new(1, 0, 1).Unit, Vector3.new(1, 0, -1).Unit,
        Vector3.new(-1, 0, 1).Unit, Vector3.new(-1, 0, -1).Unit,
        Vector3.new(1, 1, 0).Unit, Vector3.new(-1, 1, 0).Unit,
        Vector3.new(0, 1, 1).Unit, Vector3.new(0, 1, -1).Unit,
    }
    local _manipulation_underground_fixed_offsets = {
        Vector3.new(0, -8, 0),
        Vector3.new(3, -8, 0), Vector3.new(-3, -8, 0),
        Vector3.new(6, -8, 0), Vector3.new(-6, -8, 0),
        Vector3.new(4, -8, 2), Vector3.new(-4, -8, -2),
        Vector3.new(4, -8, 4), Vector3.new(-4, -8, -4),
        Vector3.new(1, -8, 3), Vector3.new(-1, -8, -3),
        Vector3.new(0, -10, 0),
        Vector3.new(3, -10, 0), Vector3.new(-3, -10, 0),
        Vector3.new(6, -10, 0), Vector3.new(-6, -10, 0),
        Vector3.new(5, -10, 3), Vector3.new(-5, -10, -3),
        Vector3.new(2, -10, 0), Vector3.new(-2, -10, 0),
        Vector3.new(0, -12, 0),
        Vector3.new(3, -12, 0), Vector3.new(-3, -12, 0),
        Vector3.new(6, -12, 0), Vector3.new(-6, -12, 0),
        Vector3.new(4, -12, 2), Vector3.new(-4, -12, -2),
        Vector3.new(7, -12, 0), Vector3.new(-7, -12, 0),
    }
    local _manipulation_underground_outer_fixed_directions = {
        Vector3.new(0, -1, 0),
        Vector3.new(1, -1, 0).Unit, Vector3.new(-1, -1, 0).Unit,
        Vector3.new(0, -1, 1).Unit, Vector3.new(0, -1, -1).Unit,
    }
    local _manipulation_fixed_cache = {
        key = nil,
        points = nil,
    }
    local function get_manipulation_fixed_points(max_offset, underground)
        max_offset = math.clamp(math.floor(tonumber(max_offset) or 30), 1, 50)
        local cache_key = string.format("%d:%s", max_offset, underground and "underground" or "normal")
        if _manipulation_fixed_cache.key == cache_key and _manipulation_fixed_cache.points then
            return _manipulation_fixed_cache.points
        end

        local scale = max_offset > 30 and (max_offset / 30) or 1.0

        local sortable = {}
        local order = 0
        local function add_points(source, point_scale)
            local s = point_scale or 1.0
            for _, offset in ipairs(source) do
                local scaled_offset = s ~= 1.0 and (offset * s) or offset
                local distance = scaled_offset.Magnitude
                if distance <= max_offset + 0.001 then
                    order += 1
                    sortable[#sortable + 1] = {
                        offset = scaled_offset,
                        distance = distance,
                        order = order,
                    }
                end
            end
        end

        add_points(_manipulation_fixed_offsets, 1.0)
        for _, radius in ipairs(_manipulation_outer_fixed_radii) do
            local scaled_radius = radius * scale
            if scaled_radius <= max_offset + 0.001 then
                for _, direction in ipairs(_manipulation_outer_fixed_directions) do
                    add_points({direction * scaled_radius})
                end
            end
        end
        if underground then
            add_points(_manipulation_underground_fixed_offsets, scale)
            for _, radius in ipairs(_manipulation_outer_fixed_radii) do
                local scaled_radius = radius * scale
                if radius >= 15 and scaled_radius <= max_offset + 0.001 then
                    for _, direction in ipairs(_manipulation_underground_outer_fixed_directions) do
                        add_points({direction * scaled_radius})
                    end
                end
            end
        end

        table.sort(sortable, function(a, b)
            if math.abs(a.distance - b.distance) <= 0.0001 then
                return a.order < b.order
            end
            return a.distance < b.distance
        end)

        local points = table.create(#sortable)
        for index, entry in ipairs(sortable) do
            points[index] = entry.offset
        end

        _manipulation_fixed_cache.key = cache_key
        _manipulation_fixed_cache.points = points
    task.wait()
        return points
    end
    local _hitscan_cache = {
        character = nil,
        scan_part = nil,
        range = nil,
        multiscan = nil,
        offset = nil,
    }
    local function get_hitscan_parts(character, primary_part)
        local result = {}
        local added = {}

        if silent_aim.hitscan_multiscan and character then
            local selected = silent_aim.hitscan_parts
            if type(selected) == "table" then
                for key, value in pairs(selected) do
                    local part_name
                    if type(key) == "number" and type(value) == "string" then
                        part_name = value
                    elseif value == true and type(key) == "string" then
                        part_name = key
                    end

                    if part_name and not added[part_name] then
                        local part = character:FindFirstChild(part_name, true)
                        if part and part:IsA("BasePart") then
                            added[part_name] = true
                            result[#result + 1] = part
                        end
                    end
                end
            end
        end

        if #result == 0 and primary_part and primary_part:IsA("BasePart") then
            result[1] = primary_part
        end
        return result
    end

    local function get_manipulation_parts(character, primary_part)
        local result = {}
        local added = {}

        if silent_aim.manipulation_multiscan and character then
            local selected = silent_aim.manipulation_parts
            if type(selected) == "table" then
                for key, value in pairs(selected) do
                    local part_name
                    if type(key) == "number" and type(value) == "string" then
                        part_name = value
                    elseif value == true and type(key) == "string" then
                        part_name = key
                    end

                    if part_name and not added[part_name] then
                        local part = character:FindFirstChild(part_name, true)
                        if part and part:IsA("BasePart") then
                            added[part_name] = true
                            result[#result + 1] = part
                        end
                    end
                end
            end
        end

        if #result == 0 and primary_part and primary_part:IsA("BasePart") then
            result[1] = primary_part
        end
        return result
    end

    local function hitscan_candidate_is_valid(shoot_origin, candidate, scan_part, character)
        local origin_hit = workspace:Raycast(
            shoot_origin,
            candidate - shoot_origin,
            _hitscan_params
        )
        if origin_hit then
            return false
        end

        local part_hit = workspace:Raycast(
            candidate,
            scan_part.Position - candidate,
            _hitscan_params
        )
        return part_hit ~= nil
            and part_hit.Instance ~= nil
            and character ~= nil
            and part_hit.Instance:IsDescendantOf(character)
    end

    local function manipulation_candidate_is_valid(candidate, scan_part, character)
        local part_hit = workspace:Raycast(
            candidate,
            scan_part.Position - candidate,
            _manipulation_params
        )
        local hit_instance = part_hit and part_hit.Instance
        if not hit_instance then
            return nil
        end
        if hit_instance == scan_part then
            return scan_part
        end
        if character
            and hit_instance:IsA("BasePart")
            and hit_instance:IsDescendantOf(character)
            and hit_instance:FindFirstAncestorOfClass("Accessory") == nil
        then
            -- A selected ray can legitimately enter another body part first.
            -- Use that actual first body hit rather than rejecting the origin.
            return hit_instance
        end
        return nil
    end

    local function find_hitscan_origin(shoot_origin, primary_part)
        local character = primary_part and primary_part.Parent
        local camera = workspace.CurrentCamera
        if not (character and camera and typeof(shoot_origin) == "Vector3") then
            return nil, nil
        end

        local filter = {}
        if LocalPlayer.Character then filter[#filter + 1] = LocalPlayer.Character end
        filter[#filter + 1] = camera
        local nocollision = workspace:FindFirstChild("NoCollision")
        if nocollision then filter[#filter + 1] = nocollision end
        if type(ignorelist) == "table" then
            for _, instance in ipairs(ignorelist) do
                if typeof(instance) == "Instance" then
                    filter[#filter + 1] = instance
                end
            end
        end
        _hitscan_params.FilterDescendantsInstances = filter

        local range = math.clamp(tonumber(silent_aim.hitscan_range) or 4, 1, 8)
        local multiscan = silent_aim.hitscan_multiscan == true
        local scan_parts = get_hitscan_parts(character, primary_part)
        local cached_part = _hitscan_cache.scan_part
        local cached_offset = _hitscan_cache.offset
    task.wait()
        local cached_part_allowed = false
        for _, scan_part in ipairs(scan_parts) do
            if scan_part == cached_part then
                cached_part_allowed = true
                break
            end
        end
        if _hitscan_cache.character == character
            and _hitscan_cache.range == range
            and _hitscan_cache.multiscan == multiscan
            and cached_part_allowed
            and cached_part
            and cached_part.Parent
            and cached_part:IsDescendantOf(character)
            and cached_offset
        then
            local candidate = (cached_part.CFrame * CFrame.new(cached_offset * range)).Position
            if hitscan_candidate_is_valid(shoot_origin, candidate, cached_part, character) then
                return candidate, cached_part
            end
        end

        for _, scan_part in ipairs(scan_parts) do
            local scan_cframe = scan_part.CFrame
            for _, offset in ipairs(_hitscan_offsets) do
                local candidate = (scan_cframe * CFrame.new(offset * range)).Position
                if hitscan_candidate_is_valid(shoot_origin, candidate, scan_part, character) then
                    _hitscan_cache.character = character
                    _hitscan_cache.scan_part = scan_part
                    _hitscan_cache.range = range
                    _hitscan_cache.multiscan = multiscan
                    _hitscan_cache.offset = offset
                    return candidate, scan_part
                end
            end
        end

        _hitscan_cache.character = character
        _hitscan_cache.scan_part = nil
        _hitscan_cache.range = range
        _hitscan_cache.multiscan = multiscan
        _hitscan_cache.offset = nil
        return nil, nil
    end

    local function find_manipulation_origin(shoot_origin, primary_part)
        local character = primary_part and primary_part.Parent
        local camera = workspace.CurrentCamera
        if not (character and camera and primary_part:IsA("BasePart") and typeof(shoot_origin) == "Vector3") then
            return nil, nil
        end

        local filter = {}
        if LocalPlayer.Character then filter[#filter + 1] = LocalPlayer.Character end
        filter[#filter + 1] = camera
        local nocollision = workspace:FindFirstChild("NoCollision")
        if nocollision then filter[#filter + 1] = nocollision end
        if type(ignorelist) == "table" then
            for _, instance in ipairs(ignorelist) do
                if typeof(instance) == "Instance" then
                    filter[#filter + 1] = instance
                end
            end
        end
        _manipulation_params.FilterDescendantsInstances = filter

        local underground = silent_aim.manipulation_underground == true
        local max_offset = math.clamp(math.floor(tonumber(silent_aim.manipulation_max_offset) or 30), 1, 50)
        local scan_parts = get_manipulation_parts(character, primary_part)
        local fixed_points = get_manipulation_fixed_points(max_offset, underground)

        -- Never short-circuit to an old cached result. Re-test the deterministic
        -- fixed list from nearest to farthest so the returned point is the
        -- closest offset that is proven to work on this scan.
        for _, offset in ipairs(fixed_points) do
            local candidate = shoot_origin + offset
            for _, scan_part in ipairs(scan_parts) do
                local actual_hit_part = manipulation_candidate_is_valid(candidate, scan_part, character)
                if actual_hit_part then
                    return candidate, actual_hit_part, offset.Magnitude
                end
            end
        end

        return nil, nil
    end
        local corner_directions = table.create(5)

        local function target_part_alive(part)
            if not part or not part.Parent then return false end
            local humanoid = part.Parent:FindFirstChildOfClass("Humanoid")
            return not humanoid or humanoid.Health > 0
        end
        
        cheat.utility.new_heartbeat(LPH_NO_VIRTUALIZE(function()
            local now = tick()
            local indtxt = ""
            local aim_active = silent_aim_active()
            local rage_active = rage_bot_active()
            local trigger_active = triggerbot_active()
            local tp_tbot = cheat.Toggles and cheat.Toggles.tpkill_enabled and feature_active(cheat.Toggles.tpkill_enabled.Value, 'tpkill_key') and cheat.Toggles.tpkill_autotbot and cheat.Toggles.tpkill_autotbot.Value
            local needs_target = aim_active
                or rage_active
                or trigger_active
                or tp_tbot
                or autoshoot
                or (silent_aim.crosshair_status and silent_aim.crosshair_status_always)

            if not needs_target then
                silent_aim.target_part = nil
                silent_aim.is_npc = false
                silent_aim.isvisible = false
                silent_aim.hitscanning = false
                silent_aim.manipulated = false
                silent_aim.manipulated_origin = nil
                silent_aim.indicator_text = ""
                if silent_aim._trigger_held then
                    silent_aim._trigger_held = false
                    if mouse1release then mouse1release() end
                end
                return
            end

            local active_target_interval = (rage_active or trigger_active or tp_tbot or autoshoot) and fast_target_scan_interval or target_scan_interval
            local target_invalid = silent_aim.target_part ~= nil and not target_part_alive(silent_aim.target_part)
            -- TP Kill lifts us ~200 studs above the target, which pushes it out of the
            -- FOV circle get_closest_target measures in screen space against the mouse, so
            -- the next re-scan dropped the target and nothing ever fired. While a TP Kill
            -- window is live, keep the lock (still re-scan if the target actually died).
            if (now - last_target_scan >= active_target_interval or target_invalid)
                and not (cheat.tpkill and cheat.tpkill.destination and not target_invalid) then
                last_target_scan = now
                local scan_part = silent_aim.selected_part or silent_aim.part

                -- Rage bot forces head-only if configured
                if rage_active and silent_aim.rage_bot_head_only then
                    scan_part = "Head"
                end

                silent_aim.part = scan_part

                -- When rage bot is active, ignore FOV entirely (rage_dist used)
                if rage_active then
                    silent_aim.target_part, silent_aim.is_npc = get_closest_target(
                        false, nil, scan_part, silent_aim.target_npc,
                        true, silent_aim.rage_bot_range or silent_aim.rage_max_dist,
                        silent_aim.target_heli, silent_aim.target_players
                    )
                else
                    silent_aim.target_part, silent_aim.is_npc = get_closest_target(
                        silent_aim.fov, silent_aim.fov_size, scan_part,
                        silent_aim.target_npc, false, 0,
                        silent_aim.target_heli, silent_aim.target_players
                    )
                end
            end
            
            silent_aim.manipulated = false
            -- V2 clears this on every scan cycle (and on the no-target path); ours
            -- never cleared it at all, so ONE successful hitscan solve left it true for
            -- the rest of the session. triggerable = isvisible or hitscanning then
            -- stayed true forever and the triggerbot fired at targets it could not
            -- possibly hit. Ours re-solves every frame, so clear it per frame.
            silent_aim.hitscanning = false
            local old_origin = silent_aim.manipulated_origin
    task.wait()
            silent_aim.manipulated_origin = nil
            if silent_aim.target_part then
                local tp_active = cheat.Toggles and cheat.Toggles.tpkill_enabled and feature_active(cheat.Toggles.tpkill_enabled.Value, 'tpkill_key')
                if silent_aim.corner_shoot and not tp_active then
                    local hitpart = silent_aim.target_part
                    local camera = workspace.CurrentCamera
                    if camera then
                        local base_pos = camera.CFrame.Position
                        local target_pos = hitpart.Position
                        if lift_hitboxes_active() then
                            local lift_h = silent_aim.lift_hitboxes_height or 2
                            target_pos = target_pos + Vector3.new(0, lift_h, 0)
                        end
                        local nocollision = workspace:FindFirstChild("NoCollision")
                        if nocollision then
                            corner_params.FilterDescendantsInstances = {LocalPlayer.Character, camera, nocollision}
                        else
                            corner_params.FilterDescendantsInstances = {LocalPlayer.Character, camera}
                        end
                        
                        local res = workspace:Raycast(base_pos, target_pos - base_pos, corner_params)
                        if not res or (res.Instance and res.Instance:IsDescendantOf(hitpart.Parent)) then
                            silent_aim.isvisible = true
                        else
                            silent_aim.isvisible = false
                            local found_origin = nil
                            local max_dist = math.min(15, silent_aim.corner_shoot_dist)

                            if old_origin and (old_origin - base_pos).Magnitude <= (max_dist + 3) then
                                local to_old = workspace:Raycast(base_pos, old_origin - base_pos, corner_params)
                                if not to_old then
                                    local old_res = workspace:Raycast(old_origin, target_pos - old_origin, corner_params)
                                    if not old_res or (old_res.Instance and old_res.Instance:IsDescendantOf(hitpart.Parent)) then
                                        found_origin = old_origin
                                    end
                                end
                            end

                            -- Fixed-point catalog: deterministic, ray-validated,
                            -- sorted nearest-first, and reaches further than the
                            -- 5-direction inline sweep below (up to manipulation_max_offset).
                            if not found_origin and not silent_aim.rage_bot_active then
                                local cat_origin, cat_part = find_manipulation_origin(base_pos, hitpart)
                                if cat_origin then
                                    found_origin = cat_origin
                                    if cat_part then hitpart = cat_part end
                                    -- Head-relative result: the teleport translates the
                                    -- whole character and lands the Head on this origin.
                                    silent_aim.origin_method = "manipulation"
                                end
                            end
                            
                            if not found_origin and (now - last_corner_search) >= corner_search_interval then
                                last_corner_search = now
                                local right = camera.CFrame.RightVector
                                local up = camera.CFrame.UpVector
                                corner_directions[1] = right
                                corner_directions[2] = -right
                                corner_directions[3] = up
                                corner_directions[4] = (right + up).Unit
                                corner_directions[5] = (-right + up).Unit
                                
                                for d = 1, max_dist, 1 do
                                    for i = 1, 5 do
                                        local dir = corner_directions[i]
                                    local offset = dir * d
                                    local origin = base_pos + offset
                                    local to_origin_res = workspace:Raycast(base_pos, offset, corner_params)
                                    if not to_origin_res then
                                        local res = workspace:Raycast(origin, target_pos - origin, corner_params)
                                        if not res or (res.Instance and res.Instance:IsDescendantOf(hitpart.Parent)) then
                                            local buffered_offset = dir * (d + 1.5)
                                            local buffered_origin = base_pos + buffered_offset
                                            local b_to_orig = workspace:Raycast(base_pos, buffered_offset, corner_params)
                                            if not b_to_orig then
                                                local b_res = workspace:Raycast(buffered_origin, target_pos - buffered_origin, corner_params)
                                                if not b_res or (b_res.Instance and b_res.Instance:IsDescendantOf(hitpart.Parent)) then
                                                    found_origin = buffered_origin
                                                    break
                                                end
                                            end
                                            
                                            if not found_origin then
                                                found_origin = origin
                                                break
                                            end
                                        end
                                    end
                                end
                                if found_origin then break end
                                end
                            end
                            
                            if found_origin then
                                silent_aim.manipulated = true
                                silent_aim.manipulated_origin = found_origin
                            else
                                silent_aim.manipulated_origin = nil
                            end
                        end
                    end
                else
                    silent_aim.isvisible = is_visible(Camera.CFrame, silent_aim.target_part.Parent, silent_aim.target_part) or false
                end

                -- Stage 2: Hitscan solver, used only when the corner sweep and the
                -- fixed-point catalog both failed to find an origin (same ordering
                -- as v2: manipulation has priority, hitscan is the fallback).
                local tp_active2 = cheat.Toggles and cheat.Toggles.tpkill_enabled and feature_active(cheat.Toggles.tpkill_enabled.Value, 'tpkill_key')
                if silent_aim.corner_shoot
                    and not tp_active2
                    and not rage_active
                    and not silent_aim.isvisible
                    and silent_aim.manipulated_origin == nil
                then
                    local camera2 = workspace.CurrentCamera
                    if camera2 then
                        local hs_origin, hs_part = find_hitscan_origin(camera2.CFrame.Position, silent_aim.target_part)
                        if hs_origin and hs_part then
                            silent_aim.target_part = hs_part
                            silent_aim.manipulated = true
                            silent_aim.manipulated_origin = hs_origin
                            silent_aim.hitscanning = true
                            silent_aim.origin_method = "hitscan"
                        end
                    end
                end
            else
                silent_aim.isvisible = false
                silent_aim.hitscanning = false
            end

            if silent_aim.target_part then
                indtxt = indtxt..(silent_aim.target_part.Parent.Name)
                if silent_aim.isvisible then
                    indtxt = indtxt.." (visible)"
                end
                if silent_aim.is_npc then
                    indtxt = indtxt.." (ai)"
                end
            else
                indtxt = ""
            end
            silent_aim.indicator_text = indtxt
    task.wait()

            -- ═══════════ RAGE BOT AUTO-SCOPE ═══════════
            if rage_active and silent_aim.rage_bot_auto_scope and silent_aim.target_part then
                local char = LocalPlayer.Character
                local hum = char and char:FindFirstChildOfClass("Humanoid")
                if hum then
                    pcall(function()
                        if hum:GetState() ~= Enum.HumanoidStateType.Seated then
                            -- Zoom in via camera FOV
                            local cam = workspace.CurrentCamera
                            if cam and cam.FieldOfView > 25 then
                                cam.FieldOfView = math.max(25, cam.FieldOfView - 5)
                            end
                        end
                    end)
                end
            end
            -- ═══════════════════════════════════════════

            if autoshoot then
                cheat.shoot_weapon_packet(silent_aim.isvisible, shootspeed, packetpred, packetscan, packetthruscan)
            end
            
            -- WALLBANG TP: arm ONLY while its keybind is down and a target is locked inside
            -- the FOV circle. Before this it re-armed every frame and teleported you around
            -- whenever anything was obstructed, even when you were not shooting -- which is
            -- what read as buggy. Then treat the target as triggerable only once the
            -- server's LastVerifiedPos has converged on the teleport (cheat.wallbang_tp.apply).
            -- Flags live on silent_aim because this chunk is at Lua's local ceiling.
            -- require_assigned = true: Wallbang TP is the one feature that must have a
            -- real bound key, so the toggle alone can never move the character.
            silent_aim._wallbang_bind_active = feature_active(silent_aim.wallbang_tp, 'wallbang_tp_bind', false, true)
            if silent_aim._wallbang_bind_active and cheat.wallbang_tp.target_in_fov()
                and not silent_aim.isvisible and not silent_aim.hitscanning then
                local solved = cheat.wallbang_tp.solve(Camera.CFrame.p, silent_aim.target_part.Position)
                if solved then
                    local prev = silent_aim._wallbang_origin
                    if not prev or (prev - solved).Magnitude > 1.5 then
                        silent_aim._wallbang_origin = solved
                        silent_aim._wallbang_arm_tick = tick()
                    end
                else
                    cheat.wallbang_tp.clear()
                end
            else
                cheat.wallbang_tp.clear()
            end
            silent_aim._wallbang_ready = cheat.wallbang_tp.ready()

            -- Triggerability matches pin.reta V2 exactly: the target is visible, or we are
            -- hitscanning (a trace that needs no line of sight), plus a manipulated origin.
            -- The Wallbang toggle itself does NOT belong here: in V2 it gates only Silent
            -- Aim's force-collision result. The material/thin-wall raycast that used to sit
            -- here made Wallbang silently let the triggerbot shoot through thin
            -- Wood/Plastic/Metal/Glass/Concrete walls, which V2 never does.
            local triggerable = silent_aim.isvisible or silent_aim.hitscanning
            if silent_aim.triggerbot_manipulation and silent_aim.manipulated_origin ~= nil then
                triggerable = true
            end
            -- Wallbang TP contributes exactly one thing: the shot is allowed once the server
            -- has verified the teleported origin, so it is credited from past the wall.
            if silent_aim._wallbang_ready then
                triggerable = true
            end
            if rage_active then
                triggerable = true  -- rage bot fires on lock; Auto Wallbang still gates it below
            end
            -- TP Kill: nothing may fire until the server has verified the teleport,
            -- otherwise the hit is credited from the ground and the kill never lands.
            if cheat.tpkill and cheat.tpkill.awaiting_verification() then
                triggerable = false
            end
            
            if trigger_active and not triggerable and now - last_triggerable_scan >= fast_target_scan_interval then
                last_triggerable_scan = now
                local alt_part, alt_npc = get_closest_target(silent_aim.fov, silent_aim.fov_size, silent_aim.selected_part or silent_aim.part, silent_aim.target_npc, false, 0, silent_aim.target_heli, silent_aim.target_players, true, silent_aim.triggerbot_manipulation, silent_aim.manipulated_origin)
                if alt_part then
                    silent_aim.target_part = alt_part
                    silent_aim.is_npc = alt_npc
                    triggerable = true
                end
            end

            -- The verified TP Kill window counts as its own trigger source, so TP Kill
            -- shoots for itself instead of silently doing nothing unless the separate
            -- Auto Triggerbot toggle also happens to be on.
            local should_trigger = (trigger_active or rage_active or tp_tbot
                or (cheat.tpkill and cheat.tpkill.destination and cheat.tpkill.verified
                    and not cheat.tpkill.returning))
                and silent_aim.target_part and triggerable
            if should_trigger then
                -- Rage bot uses its own hitchance
                local hitChance
                if rage_active then
                    hitChance = silent_aim.rage_bot_hitchance or 100
                else
                    hitChance = cheat.Options.triggerbot_hitchance and cheat.Options.triggerbot_hitchance.Value or 100
                end
                if not ragebot_should_fire(hitChance) then
                    should_trigger = false
                end

                -- Rage bot shot delay
                if should_trigger and rage_active then
                    local shot_delay = silent_aim.rage_bot_shot_delay or 0.05
                    if (now - ragebot_last_shot) < shot_delay then
                        should_trigger = false
                    else
                        ragebot_last_shot = now
                    end
                end

                -- Rage bot min damage check
                if should_trigger and rage_active then
                    local hum = ragebot_get_humanoid(silent_aim.target_part)
                    if hum and hum.Health < (silent_aim.rage_bot_min_damage or 1) then
                        should_trigger = false
                    end
                end

                -- Rage bot wallbang check
                if should_trigger and rage_active and not silent_aim.isvisible
                    and not silent_aim.hitscanning and not silent_aim.rage_bot_wallbang
                    and not silent_aim._wallbang_ready then
                    should_trigger = false
                end
            end

            if should_trigger then
                if trigger_active and silent_aim.random_part and not silent_aim.is_npc and now - random_part_timer > 0.12 then
                    random_part_timer = now
                    local character = silent_aim.target_part.Parent
                    for _ = 1, #available_random_parts do
                        local candidate = character and _FindFirstChild(character, available_random_parts[math.random(1, #available_random_parts)])
                        if candidate and candidate:IsA("BasePart") then
                            silent_aim.target_part = candidate
                            break
                        end
                    end
                end
                if not silent_aim._trigger_held then
                    silent_aim._trigger_held = true
                    if mouse1press then mouse1press() end
                end
            else
                if silent_aim._trigger_held then
                    silent_aim._trigger_held = false
                    if mouse1release then mouse1release() end
                end
            end
        end))
    end
    local esp_master_enabled = false
    local refresh_object_esp = nil

    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local espb = ui.box.esp:AddTab("Player ESP")
        local es = cheat.EspLibrary.settings.enemy
        local infinite_range_enabled = false

        local function any_player_esp_enabled()
            return esp_master_enabled and (
                infinite_range_enabled
                or es.realname
                or es.displayname
                or es.health
                or es.dist
                or es.weapon
                or es.skeleton
                or es.chams
                or es.high_kd_marker
            )
        end

        local function refresh_player_esp()
            es.box = false
            es.box_fill = false
            es.box_outline = false
            es.box_outline_vis = false
            es.enabled = any_player_esp_enabled()
            if es.enabled then
                cheat.EspLibrary.ensure_player_entities()
                cheat.EspLibrary.icaca()
            else
                cheat.EspLibrary.clear_player_entities()
            end
        end

        espb:AddToggle('espswitch',{ Text = 'ESP Master Switch', Default = false, Callback = function(c)
            esp_master_enabled = c
            refresh_player_esp()
            if refresh_object_esp then
                refresh_object_esp()
            end
        end})
        espb:AddDropdown('espfont',{ Values = { 'UI', 'System', 'Plex', 'Monospace' }, Default = 4, Multi = false, Text = 'ESP Font', Callback = function(a)
            local font_map = {
                UI = Drawing.Fonts.UI,
                System = Drawing.Fonts.System,
                Plex = Drawing.Fonts.Plex,
                Monospace = Drawing.Fonts.Monospace,
            }
            cheat.EspLibrary.main_settings.textFont = font_map[a] or Drawing.Fonts.Monospace
            cheat.EspLibrary.icaca()
        end})
        espb:AddSlider('espfontsize', { Text = 'ESP Font Size', Default = 13, Min = 1, Max = 30, Rounding = 0, Compact = true, Callback = function(b)
            cheat.EspLibrary.main_settings.textSize = b
            cheat.EspLibrary.icaca()
        end})
        espb:AddToggle('espdistancelimit',{ Text = 'Max Distance Limit', Default = false, Callback = function(c)
            cheat.EspLibrary.main_settings.distancelimit = c
            cheat.EspLibrary.icaca()
        end})
        espb:AddSlider('espmaxdistance', { Text = 'Max ESP Distance', Default = 5000, Min = 100, Max = 5000, Rounding = 0, Compact = true, Callback = function(v)
            cheat.EspLibrary.main_settings.maxdistance = v
        end})
        espb:AddToggle('espinfinite',{ Text = 'Infinite Range', Default = false, Callback = function(c)
            infinite_range_enabled = c
            cheat.EspLibrary.main_settings.infiniterange = c
            refresh_player_esp()
        end})

        espb:AddToggle('esprealname',{ Text = 'Name ESP', Default = false, Callback = function(c)
            es.realname = c
            refresh_player_esp()
        end}):AddColorPicker('esprealnamecolor',{ Default = Color3.new(1, 1, 1), Title = 'Name Color', Transparency = 1, Callback = function(a, alpha)
            es.realname_color[1] = a
            es.realname_color[2] = alpha or es.realname_color[2]
            cheat.EspLibrary.icaca()
        end})
        local esprealnameopacity = espb:AddSlider('esprealnameopacity', { Text = 'Name Opacity', Default = 100, Min = 1, Max = 100, Rounding = 0, Compact = true, Callback = function(v)
            es.realname_color[2] = v / 100
            cheat.EspLibrary.icaca()
        end})
        esprealnameopacity:SetVisible(false)
        local esprealnameoutline = espb:AddToggle('esprealnameoutline',{ Text = 'Name Outline', Default = false, Callback = function(c)
            es.realname_outline = c
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('esprealnameoutlinecolor',{ Default = Color3.new(), Title = 'Name Outline Color', Transparency = 0, Callback = function(a)
            es.realname_outline_color = a
            cheat.EspLibrary.icaca()
        end})
        esprealnameoutline:SetVisible(false)
        local esprealnameoutlinevis = espb:AddToggle('esprealnameoutlinevis',{ Text = 'Name Outline Vis', Default = false, Callback = function(c)
            es.realname_outline_vis = c
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('esprealnameoutlineviscolor',{ Default = Color3.new(), Title = 'Visible Name Outline Color', Transparency = 0, Callback = function(a)
            es.realname_outline_vis_color = a
            cheat.EspLibrary.icaca()
        end})
        esprealnameoutlinevis:SetVisible(false)

        espb:AddToggle('espdisplayname',{ Text = 'Display Name ESP', Default = false, Callback = function(c)
            es.displayname = c
            refresh_player_esp()
        end}):AddColorPicker('espdisplaynamecolor',{ Default = Color3.new(1, 1, 1), Title = 'Display Name Color', Transparency = 1, Callback = function(a, alpha)
            es.displayname_color[1] = a
            es.displayname_color[2] = alpha or es.displayname_color[2]
            cheat.EspLibrary.icaca()
        end})
        local espdisplaynameopacity = espb:AddSlider('espdisplaynameopacity', { Text = 'Display Name Opacity', Default = 100, Min = 1, Max = 100, Rounding = 0, Compact = true, Callback = function(v)
            es.displayname_color[2] = v / 100
            cheat.EspLibrary.icaca()
        end})
        espdisplaynameopacity:SetVisible(false)
        local espdisplaynameoutline = espb:AddToggle('espdisplaynameoutline',{ Text = 'Display Name Outline', Default = false, Callback = function(c)
            es.displayname_outline = c
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('espdisplaynameoutlinecolor',{ Default = Color3.new(), Title = 'Display Name Outline Color', Transparency = 0, Callback = function(a)
            es.displayname_outline_color = a
            cheat.EspLibrary.icaca()
        end})
        espdisplaynameoutline:SetVisible(false)
        local espdisplaynameoutlinevis = espb:AddToggle('espdisplaynameoutlinevis',{ Text = 'Display Name Outline Vis', Default = false, Callback = function(c)
            es.displayname_outline_vis = c
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('espdisplaynameoutlineviscolor',{ Default = Color3.new(), Title = 'Visible Display Name Outline Color', Transparency = 0, Callback = function(a)
            es.displayname_outline_vis_color = a
            cheat.EspLibrary.icaca()
        end})
        espdisplaynameoutlinevis:SetVisible(false)

        espb:AddToggle('esphealth', { Text = 'Health ESP', Default = false, Callback = function(c)
            es.health = c
            refresh_player_esp()
        end}):AddColorPicker('esphealthcolortop',{ Default = Color3.new(0, 1, 0), Title = 'Health Color Top', Transparency = 0, Callback = function(a)
            es.health_color_top = a
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('esphealthcolorbottom',{ Default = Color3.new(1, 0, 0), Title = 'Health Color Bottom', Transparency = 0, Callback = function(a)
            es.health_color_bottom = a
            cheat.EspLibrary.icaca()
        end})
        espb:AddSlider('esphealththickness', { Text = 'Health Bar Thickness', Default = 2, Min = 1, Max = 10, Rounding = 1, Compact = true, Callback = function(v)
            es.health_thickness = v
            cheat.EspLibrary.icaca()
        end})
        espb:AddSlider('esphealthglowsize', { Text = 'Health Glow Size', Default = 5, Min = 1, Max = 20, Rounding = 1, Compact = true, Callback = function(v)
            es.health_glow_size = v
            cheat.EspLibrary.icaca()
        end})

        espb:AddToggle('espdistance',{ Text = 'Distance ESP', Default = false, Callback = function(c)
            es.dist = c
            refresh_player_esp()
        end}):AddColorPicker('espdistancecolor',{ Default = Color3.new(1, 1, 1), Title = 'Distance Color', Transparency = 1, Callback = function(a, alpha)
            es.dist_color[1] = a
            es.dist_color[2] = alpha or es.dist_color[2]
            cheat.EspLibrary.icaca()
        end})
        local espdistanceopacity = espb:AddSlider('espdistanceopacity', { Text = 'Distance Opacity', Default = 100, Min = 1, Max = 100, Rounding = 0, Compact = true, Callback = function(v)
            es.dist_color[2] = v / 100
            cheat.EspLibrary.icaca()
        end})
        espdistanceopacity:SetVisible(false)
        local espdistanceoutline = espb:AddToggle('espdistanceoutline',{ Text = 'Distance Outline', Default = false, Callback = function(c)
            es.dist_outline = c
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('espdistanceoutlinecolor',{ Default = Color3.new(), Title = 'Distance Outline Color', Transparency = 0, Callback = function(a)
            es.dist_outline_color = a
            cheat.EspLibrary.icaca()
        end})
        espdistanceoutline:SetVisible(false)
        local espdistanceoutlinevis = espb:AddToggle('espdistanceoutlinevis',{ Text = 'Distance Outline Vis', Default = false, Callback = function(c)
            es.dist_outline_vis = c
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('espdistanceoutlineviscolor',{ Default = Color3.new(), Title = 'Visible Distance Outline Color', Transparency = 0, Callback = function(a)
            es.dist_outline_vis_color = a
            cheat.EspLibrary.icaca()
        end})
        espdistanceoutlinevis:SetVisible(false)

        espb:AddToggle('espweapon', { Text = 'Weapon ESP', Default = false, Callback = function(c)
            es.weapon = c
            refresh_player_esp()
        end}):AddColorPicker('espweaponcolor',{ Default = Color3.new(1, 1, 1), Title = 'Weapon Color', Transparency = 1, Callback = function(a, alpha)
            es.weapon_color[1] = a
            es.weapon_color[2] = alpha or es.weapon_color[2]
            cheat.EspLibrary.icaca()
        end})
        local espweaponopacity = espb:AddSlider('espweaponopacity', { Text = 'Weapon Opacity', Default = 100, Min = 1, Max = 100, Rounding = 0, Compact = true, Callback = function(v)
            es.weapon_color[2] = v / 100
            cheat.EspLibrary.icaca()
        end})
        espweaponopacity:SetVisible(false)
        local espweaponoutline = espb:AddToggle('espweaponoutline',{ Text = 'Weapon Outline', Default = false, Callback = function(c)
            es.weapon_outline = c
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('espweaponoutlinecolor',{ Default = Color3.new(), Title = 'Weapon Outline Color', Transparency = 0, Callback = function(a)
            es.weapon_outline_color = a
            cheat.EspLibrary.icaca()
        end})
        espweaponoutline:SetVisible(false)
        local espweaponoutlinevis = espb:AddToggle('espweaponoutlinevis',{ Text = 'Weapon Outline Vis', Default = false, Callback = function(c)
            es.weapon_outline_vis = c
            cheat.EspLibrary.icaca()
        end}):AddColorPicker('espweaponoutlineviscolor',{ Default = Color3.new(), Title = 'Visible Weapon Outline Color', Transparency = 0, Callback = function(a)
            es.weapon_outline_vis_color = a
            cheat.EspLibrary.icaca()
        end})
        espweaponoutlinevis:SetVisible(false)

        espb:AddToggle('espskeleton',{ Text = 'Skeleton ESP', Default = false, Callback = function(c)
            es.skeleton = c
            refresh_player_esp()
        end}):AddColorPicker('espskeletoncolor',{ Default = Color3.new(1, 1, 1), Title = 'Skeleton Color', Transparency = 1, Callback = function(a, alpha)
            es.skeleton_color[1] = a
            es.skeleton_color[2] = alpha or es.skeleton_color[2]
            cheat.EspLibrary.icaca()
        end})
        local espskeletonopacity = espb:AddSlider('espskeletonopacity', { Text = 'Skeleton Opacity', Default = 100, Min = 1, Max = 100, Rounding = 0, Compact = true, Callback = function(v)
            es.skeleton_color[2] = v / 100
            cheat.EspLibrary.icaca()
        end})
        espskeletonopacity:SetVisible(false)

        espb:AddToggle('espchams', { Text = 'Chams', Default = false, Callback = function(c)
            es.chams = c; refresh_player_esp()
        end}):AddColorPicker('espchamscolor',{ Default = Color3.new(1, 1, 1), Title = 'Chams Color', Transparency = 0.5, Callback = function(a, alpha)
            es.cham_color = a
            es.cham_transparency = alpha or es.cham_transparency
            es.chams_hidden_color[1] = a
            es.chams_visible_color[1] = a
            es.chams_fill_color[1] = a
            es.chams_hidden_color[2] = es.cham_transparency
            es.chams_visible_color[2] = es.cham_transparency
            es.chams_fill_color[2] = es.cham_transparency
            cheat.EspLibrary.icaca()
        end})
        espb:AddDropdown('espchams_mode', { Text = 'Chams Mode', Default = 'Always Show Chams', Values = { 'Always Show Chams', 'Only When Visible Show Chams' }, Callback = function(v)
            if v == 'Always Show Chams' then
                es.chams_hidden = true
                es.chams_visible = false
            else
                es.chams_hidden = false
                es.chams_visible = true
            end
            es.chams_visible_only = es.chams_visible
            cheat.EspLibrary.icaca()
        end})
        espb:AddToggle('esp_high_kd_marker', { Text = 'Highlight High KD', Default = false, Callback = function(c)
            es.high_kd_marker = c; refresh_player_esp()
        end}):AddColorPicker('esphighkdcolor', { Default = Color3.fromRGB(255, 0, 0), Title = 'High KD Chams Color', Transparency = 0.15, Callback = function(a, alpha)
            es.high_kd_outline_color = a
            es.high_kd_chams_transparency = alpha or es.high_kd_chams_transparency
            cheat.EspLibrary.icaca()
        end})
        refresh_player_esp()
    end
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local object_tab = ui.box.object_esp:AddTab("Object ESP")
        local OBJECT_BILLBOARD_NAME = "GhostHookObjectESP"
        local OBJECT_HIGHLIGHT_NAME = "GhostHookObjectHighlight"
        local EXTRACT_ESP_ICON = "rbxassetid://90942927604185"
        local CORPSE_ESP_ICON = "rbxassetid://123098473360038"
        local QUEST_ESP_ICON = "rbxassetid://102957903928716"
        local VEHICLE_ESP_ICON = "rbxassetid://72334306153050"
        local container_values = {
            "SupplyDropEDF",
            "SupplyDropMilitary",
            "MilitaryCrate",
            "SmallMilitaryBox",
            "LargeMilitaryBox",
            "LargeABPOPABox",
            "Safe",
            "CashRegister",
            "GrenadeCrate",
            "HiddenCache",
            "KGBBag",
            "Toolbox",
            "SportBag",
            "SmallShippingCrate",
            "LargeShippingCrate",
            "FilingCabinet",
            "Fridge",
            "MedBag",
            "SatchelBag",
        }
        local object_esp = {
            dropped = false,
            dropped_color = Color3.fromRGB(255, 100, 0),
            dropped_size = 11,
            corpse = false,
            corpse_color = Color3.fromRGB(0, 255, 0),
            corpse_size = 11,
            corpse_icon_size = 44,
            container = false,
            container_color = Color3.fromRGB(0, 255, 255),
            container_size = 11,
            container_whitelist = {},
            exit = false,
            exit_color = Color3.fromRGB(255, 0, 255),
            exit_size = 11,
            exit_icon_size = 44,
            quest = false,
            quest_color = Color3.fromRGB(45, 150, 99),
            quest_size = 11,
            quest_icon_size = 44,
            vehicle = false,
            vehicle_color = Color3.fromRGB(95, 25, 21),
            vehicle_size = 11,
            vehicle_icon_size = 44,
            ai_highlight = false,
            ai_highlight_color = Color3.fromRGB(255, 0, 0),
            ai_highlight_transparency = 0.5,
            ai_name = false,
            ai_name_color = Color3.fromRGB(255, 255, 0),
            ai_name_size = 11,
        }

        local function get_adornee(object)
            if not object then return nil end
            if object:IsA("BasePart") then
                return object
            end
            if object:IsA("Model") then
                return object.PrimaryPart or object:FindFirstChild("HumanoidRootPart") or object:FindFirstChild("Head") or object:FindFirstChildWhichIsA("BasePart", true)
            end
            return object:FindFirstChildWhichIsA("BasePart", true)
        end

        local function remove_billboard(object)
            if not object then return end
            local old = object:FindFirstChild(OBJECT_BILLBOARD_NAME)
            if old then
                old:Destroy()
            end
        end

        local function make_billboard(object, text, color, size, offset)
            if not object then return end
            local adornee = get_adornee(object)
            if not adornee then return end
            remove_billboard(object)

            local gui = Instance.new("BillboardGui")
            gui.Name = OBJECT_BILLBOARD_NAME
            gui.Adornee = adornee
            gui.AlwaysOnTop = true
            gui.Size = UDim2.new(0, 220, 0, 32)
            gui.StudsOffset = offset or Vector3.new(0, 2, 0)
            gui.Parent = object

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.BackgroundTransparency = 1
            label.Size = UDim2.new(1, 0, 1, 0)
            label.Font = Enum.Font.SourceSansBold
            label.Text = tostring(text or "")
            label.TextColor3 = color
            label.TextSize = size
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = gui

            return gui, label
        end

        local function resize_icon_marker(gui, label, icon, text_size, icon_size)
            text_size = tonumber(text_size) or 11
            icon_size = math.clamp(tonumber(icon_size) or 44, 16, 120)
            local label_y = icon_size + 2
            local label_height = math.max(18, text_size + 10)
            local gui_width = math.max(96, icon_size + 52)
            local gui_height = label_y + label_height + 4

            if gui then
                gui.Size = UDim2.new(0, gui_width, 0, gui_height)
            end
            if icon then
                icon.Size = UDim2.fromOffset(icon_size, icon_size)
            end
            if label then
                label.Position = UDim2.new(0, 0, 0, label_y)
                label.Size = UDim2.new(1, 0, 0, label_height)
                label.TextSize = text_size
            end
        end

        local function make_extract_billboard(object, distance_text)
            if not object then return end
            local adornee = get_adornee(object)
            if not adornee then return end
            remove_billboard(object)

            local gui = Instance.new("BillboardGui")
            gui.Name = OBJECT_BILLBOARD_NAME
            gui.Adornee = adornee
            gui.AlwaysOnTop = true
            gui.StudsOffset = Vector3.new(0, 2.25, 0)
            gui.Parent = object

            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.AnchorPoint = Vector2.new(0.5, 0)
            icon.BackgroundTransparency = 1
            icon.Image = EXTRACT_ESP_ICON
            icon.Position = UDim2.new(0.5, 0, 0, 0)
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Parent = gui

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.SourceSansBold
            label.Text = tostring(distance_text or "0m")
            label.TextColor3 = object_esp.exit_color
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = gui
            resize_icon_marker(gui, label, icon, object_esp.exit_size, object_esp.exit_icon_size)

            return gui, label, icon
        end

        local function make_corpse_billboard(object, distance_text)
            if not object then return end
            local adornee = get_adornee(object)
            if not adornee then return end
            remove_billboard(object)

            local gui = Instance.new("BillboardGui")
            gui.Name = OBJECT_BILLBOARD_NAME
            gui.Adornee = adornee
            gui.AlwaysOnTop = true
            gui.StudsOffset = Vector3.new(0, 2.25, 0)
            gui.Parent = object

            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.AnchorPoint = Vector2.new(0.5, 0)
            icon.BackgroundTransparency = 1
            icon.Image = CORPSE_ESP_ICON
            icon.Position = UDim2.new(0.5, 0, 0, 0)
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Parent = gui

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.SourceSansBold
            label.Text = tostring(distance_text or "0m")
            label.TextColor3 = object.Name == LocalPlayer.Name and Color3.fromRGB(255, 102, 0) or object_esp.corpse_color
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = gui
            resize_icon_marker(gui, label, icon, object_esp.corpse_size, object_esp.corpse_icon_size)

            return gui, label, icon
        end

        local function make_quest_billboard(object, distance_text)
            if not object then return end
            local adornee = get_adornee(object)
            if not adornee then return end
            remove_billboard(object)

            local gui = Instance.new("BillboardGui")
            gui.Name = OBJECT_BILLBOARD_NAME
            gui.Adornee = adornee
            gui.AlwaysOnTop = true
            gui.StudsOffset = Vector3.new(0, 2.25, 0)
            gui.Parent = object

            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.AnchorPoint = Vector2.new(0.5, 0)
            icon.BackgroundTransparency = 1
            icon.Image = QUEST_ESP_ICON
            icon.Position = UDim2.new(0.5, 0, 0, 0)
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Parent = gui

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.SourceSansBold
            label.Text = tostring(distance_text or "0m")
            label.TextColor3 = object_esp.quest_color
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = gui
            resize_icon_marker(gui, label, icon, object_esp.quest_size, object_esp.quest_icon_size)

            return gui, label, icon
        end

        local function make_vehicle_billboard(object, distance_text)
            if not object then return end
            local adornee = get_adornee(object)
            if not adornee then return end
            remove_billboard(object)

            local gui = Instance.new("BillboardGui")
            gui.Name = OBJECT_BILLBOARD_NAME
            gui.Adornee = adornee
            gui.AlwaysOnTop = true
            gui.StudsOffset = Vector3.new(0, 2.25, 0)
            gui.Parent = object

            local icon = Instance.new("ImageLabel")
            icon.Name = "Icon"
            icon.AnchorPoint = Vector2.new(0.5, 0)
            icon.BackgroundTransparency = 1
            icon.Image = VEHICLE_ESP_ICON
            icon.Position = UDim2.new(0.5, 0, 0, 0)
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Parent = gui

            local label = Instance.new("TextLabel")
            label.Name = "Text"
            label.BackgroundTransparency = 1
            label.Font = Enum.Font.SourceSansBold
            label.Text = tostring(distance_text or "0m")
            label.TextColor3 = object_esp.vehicle_color
            label.TextStrokeTransparency = 0
            label.TextStrokeColor3 = Color3.new(0, 0, 0)
            label.Parent = gui
            resize_icon_marker(gui, label, icon, object_esp.vehicle_size, object_esp.vehicle_icon_size)

            return gui, label, icon
        end

        local function get_amount(object)
            local props = object and object:FindFirstChild("ItemProperties")
            if props then
                return props:GetAttribute("Amount") or 1
            end
            return 1
        end

        local function is_corpse(object)
            return object and object:FindFirstChildOfClass("Humanoid") ~= nil
        end

        local function is_npc_corpse(object)
            return is_corpse(object) and not Players:FindFirstChild(object.Name)
        end

        local function format_esp_distance(studs)
            return tostring(math.floor((tonumber(studs) or 0) / 3)) .. "m"
        end

        local function format_corpse_distance(object, studs)
            if is_npc_corpse(object) then
                return "NPC " .. format_esp_distance(studs)
            end
            return format_esp_distance(studs)
        end

        local function apply_dropped_object(object)
            if not object or object:IsA("BillboardGui") then return end
            if not esp_master_enabled then
                remove_billboard(object)
                return
            end
            if is_corpse(object) then
                if object_esp.corpse then
                    make_corpse_billboard(object, format_corpse_distance(object, 0))
                else
                    remove_billboard(object)
                end
            elseif object_esp.dropped then
                make_billboard(object, object.Name .. " " .. tostring(get_amount(object)) .. "X | Item", object_esp.dropped_color, object_esp.dropped_size, Vector3.new(0, 1.5, 0))
            else
                remove_billboard(object)
            end
        end

        local function refresh_dropped()
            local dropped = workspace:FindFirstChild("DroppedItems")
            if not dropped then return end
            if object_esp._refreshing_dropped then
                object_esp._queued_dropped = true
                return
            end
            object_esp._refreshing_dropped = true
            task.spawn(function()
                repeat
                    object_esp._queued_dropped = false
                    local processed = 0
                    for _, object in ipairs(dropped:GetChildren()) do
                        apply_dropped_object(object)
                        processed = processed + 1
                        if processed % 40 == 0 then
                            task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                        end
                    end
                until not object_esp._queued_dropped
                object_esp._refreshing_dropped = false
            end)
        end

        local function walk_container(root, callback)
            if not root then return end
            for _, child in ipairs(root:GetChildren()) do
                if child:IsA("Folder") then
                    walk_container(child, callback)
                else
                    callback(child)
                end
            end
        end

        local function apply_container(object)
            if not object or object:IsA("BillboardGui") then return end
            if not esp_master_enabled then
                remove_billboard(object)
                return
            end
            if object_esp.container and object_esp.container_whitelist[object.Name] then
                make_billboard(object, object.Name .. " | Container", object_esp.container_color, object_esp.container_size, Vector3.new(0, 2, 0))
            else
                remove_billboard(object)
            end
        end

        local function refresh_containers()
            local containers = workspace:FindFirstChild("Containers")
            if not containers then return end
            if object_esp._refreshing_containers then
                object_esp._queued_containers = true
                return
            end
            object_esp._refreshing_containers = true
            task.spawn(function()
                repeat
                    object_esp._queued_containers = false
                    local stack = {containers}
                    local processed = 0
                    while #stack > 0 do
                        local root = table.remove(stack)
                        for _, child in ipairs(root:GetChildren()) do
                            if child:IsA("Folder") then
                                stack[#stack + 1] = child
                            else
                                apply_container(child)
                            end
                            processed = processed + 1
                            if processed % 40 == 0 then
                                task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                            end
                        end
                    end
                until not object_esp._queued_containers
                object_esp._refreshing_containers = false
            end)
        end

        local function get_exit_folder()
            local no_collision = workspace:FindFirstChild("NoCollision")
            return no_collision and no_collision:FindFirstChild("ExitLocations")
        end

        local function apply_exit(object)
            if not object or object:IsA("BillboardGui") then return end
            if not esp_master_enabled then
                remove_billboard(object)
                return
            end
            if object_esp.exit then
                make_extract_billboard(object, "0m")
            else
                remove_billboard(object)
            end
        end

        local function refresh_exits()
            local exits = get_exit_folder()
            if not exits then return end
            if object_esp._refreshing_exits then
                object_esp._queued_exits = true
                return
            end
            object_esp._refreshing_exits = true
            task.spawn(function()
                repeat
                    object_esp._queued_exits = false
                    local processed = 0
                    for _, object in ipairs(exits:GetChildren()) do
                        apply_exit(object)
                        processed = processed + 1
                        if processed % 40 == 0 then
                            task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                        end
                    end
                until not object_esp._queued_exits
                object_esp._refreshing_exits = false
            end)
        end

        local function apply_quest(object)
            if not object or object:IsA("BillboardGui") then return end
            if not esp_master_enabled then
                remove_billboard(object)
                return
            end
            if object_esp.quest and object:GetAttribute("Hidden") == false then
                make_quest_billboard(object, "0m")
            else
                remove_billboard(object)
            end
        end

        local function refresh_quests()
            local quests = workspace:FindFirstChild("QuestItems")
            if not quests then return end
            if object_esp._refreshing_quests then
                object_esp._queued_quests = true
                return
            end
            object_esp._refreshing_quests = true
            task.spawn(function()
                repeat
                    object_esp._queued_quests = false
                    local processed = 0
                    for _, object in ipairs(quests:GetChildren()) do
                        apply_quest(object)
                        processed = processed + 1
                        if processed % 40 == 0 then
                            task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                        end
                    end
                until not object_esp._queued_quests
                object_esp._refreshing_quests = false
            end)
        end

        local function apply_vehicle(object)
            if not object or object:IsA("BillboardGui") then return end
            if not esp_master_enabled then
                remove_billboard(object)
                return
            end
            if object_esp.vehicle then
                make_vehicle_billboard(object, "0m")
            else
                remove_billboard(object)
            end
        end

        local function refresh_vehicles()
            local vehicles = workspace:FindFirstChild("Vehicles")
            if not vehicles then return end
            if object_esp._refreshing_vehicles then
                object_esp._queued_vehicles = true
                return
            end
            object_esp._refreshing_vehicles = true
            task.spawn(function()
                repeat
                    object_esp._queued_vehicles = false
                    local processed = 0
                    for _, object in ipairs(vehicles:GetChildren()) do
                        apply_vehicle(object)
                        processed = processed + 1
                        if processed % 40 == 0 then
                            task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                        end
                    end
                until not object_esp._queued_vehicles
                object_esp._refreshing_vehicles = false
            end)
        end

        local function remove_ai_highlight(model)
            local old = model and model:FindFirstChild(OBJECT_HIGHLIGHT_NAME)
            if old then
                old:Destroy()
            end
        end

        local function apply_ai(model)
            if not (model and model:IsA("Model")) then return end
            if not esp_master_enabled then
                remove_billboard(model)
                remove_ai_highlight(model)
                return
            end
            local humanoid = model:FindFirstChildOfClass("Humanoid")
            if not (humanoid and humanoid.Health > 0) then
                remove_billboard(model)
                remove_ai_highlight(model)
                return
            end

            if object_esp.ai_name then
                make_billboard(model, model.Name .. " | NPC", object_esp.ai_name_color, object_esp.ai_name_size, Vector3.new(0, 1.75, 0))
            else
                remove_billboard(model)
            end

            if object_esp.ai_highlight then
                local hl = model:FindFirstChild(OBJECT_HIGHLIGHT_NAME)
                if not hl then
                    hl = Instance.new("Highlight")
                    hl.Name = OBJECT_HIGHLIGHT_NAME
                    hl.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
                    hl.Parent = model
                end
                hl.FillColor = object_esp.ai_highlight_color
                hl.OutlineColor = object_esp.ai_highlight_color
                hl.FillTransparency = object_esp.ai_highlight_transparency
                hl.OutlineTransparency = math.clamp(object_esp.ai_highlight_transparency * 0.5, 0, 1)
            else
                remove_ai_highlight(model)
            end
        end

        local function refresh_ai()
            local zones = workspace:FindFirstChild("AiZones")
            if not zones then return end
            for _, zone in ipairs(zones:GetChildren()) do
                for _, model in ipairs(zone:GetChildren()) do
                    apply_ai(model)
                end
            end
        end

        local function refresh_all_objects()
            refresh_dropped()
            refresh_containers()
            refresh_exits()
            refresh_quests()
            refresh_vehicles()
            refresh_ai()
        end
        refresh_object_esp = refresh_all_objects

        object_tab:AddToggle('object_dropped_esp', { Text = 'Dropped Items ESP', Default = false, Callback = function(v)
            object_esp.dropped = v
            refresh_dropped()
        end}):AddColorPicker('object_dropped_color', { Default = object_esp.dropped_color, Title = 'Dropped Item Color', Transparency = 0, Callback = function(v)
            object_esp.dropped_color = v
            refresh_dropped()
        end})
        object_tab:AddSlider('object_dropped_size', { Text = 'Dropped Item Size', Default = 11, Min = 1, Max = 20, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.dropped_size = v
            refresh_dropped()
        end})

        object_tab:AddToggle('object_corpse_esp', { Text = 'Corpse ESP', Default = false, Callback = function(v)
            object_esp.corpse = v
            refresh_dropped()
        end}):AddColorPicker('object_corpse_color', { Default = object_esp.corpse_color, Title = 'Corpse Color', Transparency = 0, Callback = function(v)
            object_esp.corpse_color = v
            refresh_dropped()
        end})
        object_tab:AddSlider('object_corpse_size', { Text = 'Corpse Text Size', Default = 11, Min = 1, Max = 20, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.corpse_size = v
            refresh_dropped()
        end})
        object_tab:AddSlider('object_corpse_icon_size', { Text = 'Icon Size', Default = 44, Min = 16, Max = 120, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.corpse_icon_size = v
            refresh_dropped()
        end})

        object_tab:AddToggle('object_container_esp', { Text = 'Container ESP', Default = false, Callback = function(v)
            object_esp.container = v
            refresh_containers()
        end}):AddColorPicker('object_container_color', { Default = object_esp.container_color, Title = 'Container Color', Transparency = 0, Callback = function(v)
            object_esp.container_color = v
            refresh_containers()
        end})
        object_tab:AddDropdown('object_container_whitelist', { Text = 'Container Whitelist', Default = {}, Values = container_values, Multi = true, Callback = function(values)
            object_esp.container_whitelist = {}
            for _, name in ipairs(values or {}) do
                object_esp.container_whitelist[name] = true
            end
            refresh_containers()
        end})
        object_tab:AddSlider('object_container_size', { Text = 'Container Text Size', Default = 11, Min = 1, Max = 20, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.container_size = v
            refresh_containers()
        end})

        object_tab:AddToggle('object_exit_esp', { Text = 'Exit ESP', Default = false, Callback = function(v)
            object_esp.exit = v
            refresh_exits()
        end}):AddColorPicker('object_exit_color', { Default = object_esp.exit_color, Title = 'Exit Color', Transparency = 0, Callback = function(v)
            object_esp.exit_color = v
            refresh_exits()
        end})
        object_tab:AddSlider('object_exit_size', { Text = 'Exit Text Size', Default = 11, Min = 1, Max = 20, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.exit_size = v
            refresh_exits()
        end})
        object_tab:AddSlider('object_exit_icon_size', { Text = 'Icon Size', Default = 44, Min = 16, Max = 120, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.exit_icon_size = v
            refresh_exits()
        end})

        object_tab:AddToggle('object_quest_esp', { Text = 'Quest Item ESP', Default = false, Callback = function(v)
            object_esp.quest = v
            refresh_quests()
        end}):AddColorPicker('object_quest_color', { Default = object_esp.quest_color, Title = 'Quest Item Color', Transparency = 0, Callback = function(v)
            object_esp.quest_color = v
            refresh_quests()
        end})
        object_tab:AddSlider('object_quest_size', { Text = 'Quest Item Text Size', Default = 11, Min = 1, Max = 20, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.quest_size = v
            refresh_quests()
        end})
        object_tab:AddSlider('object_quest_icon_size', { Text = 'Icon Size', Default = 44, Min = 16, Max = 120, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.quest_icon_size = v
            refresh_quests()
        end})

        object_tab:AddToggle('object_vehicle_esp', { Text = 'Vehicle ESP', Default = false, Callback = function(v)
            object_esp.vehicle = v
            refresh_vehicles()
        end}):AddColorPicker('object_vehicle_color', { Default = object_esp.vehicle_color, Title = 'Vehicle Color', Transparency = 0, Callback = function(v)
            object_esp.vehicle_color = v
            refresh_vehicles()
        end})
        object_tab:AddSlider('object_vehicle_size', { Text = 'Vehicle Text Size', Default = 11, Min = 1, Max = 20, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.vehicle_size = v
            refresh_vehicles()
        end})
        object_tab:AddSlider('object_vehicle_icon_size', { Text = 'Icon Size', Default = 44, Min = 16, Max = 120, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.vehicle_icon_size = v
            refresh_vehicles()
        end})

        object_tab:AddToggle('object_ai_chams', { Text = 'AI Chams ESP', Default = false, Callback = function(v)
            object_esp.ai_highlight = v
            refresh_ai()
        end}):AddColorPicker('object_ai_chams_color', { Default = object_esp.ai_highlight_color, Title = 'AI Chams Color', Transparency = 0.5, Callback = function(v, alpha)
            object_esp.ai_highlight_color = v
            object_esp.ai_highlight_transparency = alpha or object_esp.ai_highlight_transparency
            refresh_ai()
        end})
        object_tab:AddToggle('object_ai_nametag', { Text = 'AI Nametag ESP', Default = false, Callback = function(v)
            object_esp.ai_name = v
            refresh_ai()
        end}):AddColorPicker('object_ai_nametag_color', { Default = object_esp.ai_name_color, Title = 'AI Nametag Color', Transparency = 0, Callback = function(v)
            object_esp.ai_name_color = v
            refresh_ai()
        end})
        object_tab:AddSlider('object_ai_size', { Text = 'AI ESP Text Size', Default = 11, Min = 1, Max = 20, Rounding = 0, Compact = true, Callback = function(v)
            object_esp.ai_name_size = v
            refresh_ai()
        end})

        local dropped = workspace:FindFirstChild("DroppedItems")
        if dropped then
            cheat.utility.track_connection(dropped.ChildAdded:Connect(function(object)
                task.defer(apply_dropped_object, object)
            end))
        end

        local containers = workspace:FindFirstChild("Containers")
        if containers then
            cheat.utility.track_connection(containers.DescendantAdded:Connect(function(object)
                task.defer(function()
                    if object and not object:IsA("Folder") then
                        apply_container(object)
                    end
                end)
            end))
        end

        local exits = get_exit_folder()
        if exits then
            cheat.utility.track_connection(exits.ChildAdded:Connect(function(object)
                task.defer(apply_exit, object)
            end))
        end

        local quests = workspace:FindFirstChild("QuestItems")
        if quests then
            cheat.utility.track_connection(quests.ChildAdded:Connect(function(object)
                task.defer(apply_quest, object)
            end))
        end

        local vehicles = workspace:FindFirstChild("Vehicles")
        if vehicles then
            cheat.utility.track_connection(vehicles.ChildAdded:Connect(function(object)
                task.defer(apply_vehicle, object)
            end))
        end

        local zones = workspace:FindFirstChild("AiZones")
        if zones then
            for _, zone in ipairs(zones:GetChildren()) do
                cheat.utility.track_connection(zone.ChildAdded:Connect(function(object)
                    task.defer(apply_ai, object)
                end))
            end
            cheat.utility.track_connection(zones.ChildAdded:Connect(function(zone)
                task.defer(function()
                    if zone then
                        cheat.utility.track_connection(zone.ChildAdded:Connect(function(object)
                            task.defer(apply_ai, object)
                        end))
                    end
                end)
            end))
        end

        local last_exit_distance_update = 0
        cheat.utility.new_renderstepped(function()
            if not (esp_master_enabled and (object_esp.exit or object_esp.corpse or object_esp.quest or object_esp.vehicle)) then return end
            local now = os.clock()
            if now - last_exit_distance_update < 0.25 then return end
            last_exit_distance_update = now
            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local exits_folder = get_exit_folder()
            if object_esp.exit and exits_folder then
                for _, exit in ipairs(exits_folder:GetChildren()) do
                    local gui = exit:FindFirstChild(OBJECT_BILLBOARD_NAME)
                    local label = gui and gui:FindFirstChild("Text")
                    local icon = gui and gui:FindFirstChild("Icon")
                    local adornee = get_adornee(exit)
                    if label and adornee then
                        label.Text = format_esp_distance((root.Position - adornee.Position).Magnitude)
                        label.TextColor3 = object_esp.exit_color
                        resize_icon_marker(gui, label, icon, object_esp.exit_size, object_esp.exit_icon_size)
                    end
                end
            end
            local dropped = workspace:FindFirstChild("DroppedItems")
            if object_esp.corpse and dropped then
                for _, corpse in ipairs(dropped:GetChildren()) do
                    if is_corpse(corpse) then
                        local gui = corpse:FindFirstChild(OBJECT_BILLBOARD_NAME)
                        local label = gui and gui:FindFirstChild("Text")
                        local icon = gui and gui:FindFirstChild("Icon")
                        local adornee = get_adornee(corpse)
                        if label and adornee then
                            label.Text = format_corpse_distance(corpse, (root.Position - adornee.Position).Magnitude)
                            label.TextColor3 = corpse.Name == LocalPlayer.Name and Color3.fromRGB(255, 102, 0) or object_esp.corpse_color
                            resize_icon_marker(gui, label, icon, object_esp.corpse_size, object_esp.corpse_icon_size)
                        end
                    end
                end
            end
            local quests = workspace:FindFirstChild("QuestItems")
            if object_esp.quest and quests then
                for _, quest in ipairs(quests:GetChildren()) do
                    if quest:GetAttribute("Hidden") == false then
                        local gui = quest:FindFirstChild(OBJECT_BILLBOARD_NAME)
                        local label = gui and gui:FindFirstChild("Text")
                        local icon = gui and gui:FindFirstChild("Icon")
                        local adornee = get_adornee(quest)
                        if label and adornee then
                            label.Text = format_esp_distance((root.Position - adornee.Position).Magnitude)
                            label.TextColor3 = object_esp.quest_color
                            resize_icon_marker(gui, label, icon, object_esp.quest_size, object_esp.quest_icon_size)
                        end
                    end
                end
            end
            local vehicles = workspace:FindFirstChild("Vehicles")
            if object_esp.vehicle and vehicles then
                for _, vehicle in ipairs(vehicles:GetChildren()) do
                    local gui = vehicle:FindFirstChild(OBJECT_BILLBOARD_NAME)
                    local label = gui and gui:FindFirstChild("Text")
                    local icon = gui and gui:FindFirstChild("Icon")
                    local adornee = get_adornee(vehicle)
                    if label and adornee then
                        label.Text = format_esp_distance((root.Position - adornee.Position).Magnitude)
                        label.TextColor3 = object_esp.vehicle_color
                        resize_icon_marker(gui, label, icon, object_esp.vehicle_size, object_esp.vehicle_icon_size)
                    end
                end
            end
        end)

        if esp_master_enabled then
            refresh_all_objects()
        end
    end
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local cursor = {
            Enabled = false,
            CustomPos = false,
            Position = _Vector2new(0, 0),
            Speed = 5,
            Radius = 25,
            Color = Color3.fromRGB(180, 50, 255),
            Thickness = 1.7,
            Outline = false,
            Resize = false,
            Dot = false,
            Gap = 10,
            TheGap = false,
            Font = Drawing.Fonts.Monospace,
            Text = {
                Logo = false,
                LogoColor = Color3.new(1, 1, 1),
                Name = false,
                NameColor = Color3.new(1, 1, 1),
                LogoFadingOffset = 0,
            }
        }
        local CrosshairTab = ui.box.crosshair:AddTab("Crosshair")
        cursor.rainbow = false
        cursor.sussy = false
        CrosshairTab:AddToggle('crosshairenable', {Text = 'Enable Crosshair',Default = false,Callback = function(first)
            cursor.Enabled = first
        end}):AddColorPicker('crosshaircolor', {Default = Color3.new(1, 1, 1),Title = 'Crosshair Color',Transparency = 0,Callback = function(Value)
            cursor.Color = Value
        end})
        CrosshairTab:AddSlider('crosshairspeed', {Text = 'Speed',Default = 3,Min = 0.1,Max = 15,Rounding = 1,Compact = true}):OnChanged(function(State)
            cursor.Speed = State / 10
        end)
        CrosshairTab:AddSlider('crosshairradius', {Text = 'Radius',Default = 25,Min = 0.1,Max = 100,Rounding = 1,Compact = true,}):OnChanged(function(State)
            cursor.Radius = State
        end)
        CrosshairTab:AddSlider('crosshairthickness', {Text = 'Thickness',Default = 1.5,Min = 0.1,Max = 10,Rounding = 1,Compact = true,}):OnChanged(function(State)
            cursor.Thickness = State
        end)
        CrosshairTab:AddSlider('crosshairgapsize', {Text = 'Gap',Default = 5,Min = 1,Max = 50,Rounding = 1,Compact = true,}):OnChanged(function(State)
            cursor.Gap = State
        end)
        CrosshairTab:AddToggle('crosshairenabledot', {Text = 'Dot',Default = false,Callback = function(first)
            cursor.Dot = first
        end})
        CrosshairTab:AddToggle('crosshairenablenazi', {Text = 'Special Mode',Default = false,Callback = function(first)
            cursor.sussy = first
            end})
            CrosshairTab:AddToggle('crosshairenablefaggot', {Text = 'Rainbow',Default = false,Callback = function(first)
            cursor.rainbow = first
        end})
        local lines = {}
        local outline = cheat.utility.new_drawing("Square", {
            Visible = true,
            Size = _Vector2new(4, 4),
            Color = Color3.fromRGB(0, 0, 0),
            Filled = true,
            ZIndex = 1,
            Transparency = 1
        })
        local dot = cheat.utility.new_drawing("Square", {
            Visible = true,
            Size = _Vector2new(2, 2),
            Color = cursor.Color,
            Filled = true,
            ZIndex = 2,
            Transparency = 1
        })
        local logotext = cheat.utility.new_drawing("Text", {
            Visible = false,
            Font = cursor.Font,
            Size = 13,
            Color = Color3.fromRGB(138, 128, 255),
            ZIndex = 3,
            Transparency = 1,
            Text = "GHOST_HOOK",
            Center = true,
            Outline = true,
        })
        local target_line = cheat.utility.new_drawing("Line", {
            Visible = false,
            Thickness = 1,
            Color = Color3.new(1, 1, 1),
            Transparency = 1,
            ZIndex = 5
        })
        local tipanel = {}
        tipanel.pos = _Vector2new(20, 350)
        tipanel.width = 250
        tipanel.height = 100
        tipanel.dragging = false
        tipanel.dragoffset = Vector2.zero
        local avatar_cache = {}
        tipanel.bg = cheat.utility.new_drawing("Square", {
            Visible = false, Filled = true,
            Color = tipanel_settings.bgcolor,
            Size = _Vector2new(tipanel.width, tipanel.height),
            Position = tipanel.pos,
            Transparency = tipanel_settings.bgtrans, ZIndex = 10,
        })
        tipanel.border = cheat.utility.new_drawing("Square", {
            Visible = false, Filled = false,
            Color = tipanel_settings.bordercolor,
            Size = _Vector2new(tipanel.width, tipanel.height),
            Position = tipanel.pos,
            Thickness = 1, Transparency = 1, ZIndex = 11,
        })
        tipanel.glow = {}
        for i = 1, 6 do
            tipanel.glow[i] = cheat.utility.new_drawing("Square", {
                Visible = false, Filled = false,
                Color = tipanel_settings.glowcolor,
                Thickness = i,
                Transparency = 0.2 - (i * 0.03),
                ZIndex = 9,
            })
        end
        tipanel.avatar = cheat.utility.new_drawing("Image", {
            Visible = false,
            Size = _Vector2new(80, 80),
            Position = tipanel.pos + _Vector2new(8, 8),
            ZIndex = 12,
        })
        tipanel.avatar_border = cheat.utility.new_drawing("Square", {
            Visible = false, Filled = false,
            Color = Color3.fromRGB(60, 60, 60),
            Size = _Vector2new(82, 82),
            Position = tipanel.pos + _Vector2new(7, 7),
            Thickness = 1, Transparency = 1, ZIndex = 11,
        })
        local label_color = Color3.fromRGB(120, 110, 180)
        local function create_label(text)
            local l = cheat.utility.new_drawing("Text", {
                Visible = false, Font = Drawing.Fonts.Plex, Size = 13,
                Color = tipanel_settings.accentcolor, Text = text, ZIndex = 12, Outline = true
            })
            local v = cheat.utility.new_drawing("Text", {
                Visible = false, Font = Drawing.Fonts.Plex, Size = 13,
                Color = Color3.new(1, 1, 1), Text = "", ZIndex = 12, Outline = true
            })
            return l, v
        end
        tipanel.labels = {}
        tipanel.values = {}
        local rows = {"user", "k / d", "vis"}
        for i, row in ipairs(rows) do
            local l, v = create_label(row)
            tipanel.labels[row] = l
            tipanel.values[row] = v
        end
        tipanel.hours = cheat.utility.new_drawing("Text", {
            Visible = false, Font = Drawing.Fonts.Plex, Size = 13,
            Color = Color3.new(1, 1, 1), Text = "0h", ZIndex = 12, Outline = true, Center = true
        })
        tipanel.hpbg = cheat.utility.new_drawing("Square", {
            Visible = false, Filled = true,
            Color = Color3.fromRGB(30, 30, 30),
            Size = _Vector2new(145, 12),
            ZIndex = 11, Transparency = 1
        })
        tipanel.hpfill = cheat.utility.new_drawing("Square", {
            Visible = false, Filled = true,
            Color = Color3.fromRGB(180, 160, 220),
            Size = _Vector2new(0, 12),
            ZIndex = 12, Transparency = 1
        })
        tipanel.hptext = cheat.utility.new_drawing("Text", {
            Visible = false, Font = Drawing.Fonts.Plex, Size = 11,
            Color = Color3.new(1, 1, 1), Text = "100/100", ZIndex = 13, Outline = true
        })

        local tpw_gui = cheat.utility.track_instance(Instance.new("ScreenGui", game:GetService("CoreGui")))
        tpw_gui.Name = "TipanelWeapons"
        tpw_gui.DisplayOrder = 1000
        tpw_gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
        tpw_gui.IgnoreGuiInset = true

        local tipanel_weapons = {}
        local tipanel_attachments = {}
        
        for i = 1, 3 do
            local wp = Instance.new("ImageLabel", tpw_gui)
            wp.Visible = false
            wp.BackgroundTransparency = 0
            wp.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
            wp.Size = UDim2.new(0, 50, 0, 50)
            wp.BorderSizePixel = 1
            wp.BorderColor3 = Color3.fromRGB(15, 15, 15)
            tipanel_weapons[i] = wp
            
            for j = 1, 4 do
                local att = Instance.new("ImageLabel", tpw_gui)
                att.Visible = false
                att.BackgroundTransparency = 0
                att.BackgroundColor3 = Color3.fromRGB(155, 30, 30)
                att.Size = UDim2.new(0, 16, 0, 18)
                att.ZIndex = 2
                tipanel_attachments[(i-1)*4 + j] = att
            end
        end
        for i = 1, 4 do
            local line_outline = cheat.utility.new_drawing("Line", {
                Visible = true,
                From = _Vector2new(200, 500),
                To = _Vector2new(200, 500),
                Color = Color3.fromRGB(0, 0, 0),
                Thickness = cursor.Thickness + 2.5,
                ZIndex = 1,
                Transparency = 1
            })
            local line = cheat.utility.new_drawing("Line", {
                Visible = true,
                From = _Vector2new(200, 500),
                To = _Vector2new(200, 500),
                Color = cursor.Color,
                Thickness = cursor.Thickness,
                ZIndex = 2,
                Transparency = 1
            })
            local naziline = cheat.utility.new_drawing("Line", {
                Visible = true,
                From = _Vector2new(200, 500),
                To = _Vector2new(200, 500),
                Color = cursor.Color,
                Thickness = cursor.Thickness,
                ZIndex = 2,
                Transparency = 1
            })
            lines[i] = { line, line_outline, naziline }
        end
        local angle = 0
        local transp = 0
        local reverse = false
        local function setreverse(value)
            if reverse ~= value then
                reverse = value
            end
        end
        local pos, rainbow, rotationdegree, color = Vector2.zero, 0, 0, Color3.new()
        local math_cos, math_atan, math_pi, math_sin = math.cos, math.atan, math.pi, math.sin
        local function DEG2RAD(x) return x * math_pi / 180 end
        local function RAD2DEG(x) return x * 180 / math_pi end
        cheat.utility.new_renderstepped(LPH_NO_VIRTUALIZE(function(delta)
            local target = silent_aim.target_part and silent_aim.target_part.Parent
            local info_visible = silent_aim.indicator and target ~= nil
            local target_line_visible = silent_aim.target_line and silent_aim.target_part ~= nil
            local mousepos = _Vector2new(Mouse.X, Mouse.Y + GuiInset.Y)
            tipanel.bg.Visible = info_visible
            tipanel.border.Visible = info_visible
            for _, g in ipairs(tipanel.glow) do g.Visible = info_visible end
            tipanel.avatar.Visible = info_visible
            tipanel.hours.Visible = info_visible
            tipanel.avatar_border.Visible = info_visible
            for _, l in pairs(tipanel.labels) do l.Visible = info_visible end
            for _, v in pairs(tipanel.values) do v.Visible = info_visible end
            tipanel.hpbg.Visible = info_visible
            tipanel.hpfill.Visible = info_visible
            tipanel.hptext.Visible = info_visible
            target_line.Visible = false
            
            if not info_visible then
                for i = 1, 3 do tipanel_weapons[i].Visible = false end
                for i = 1, 12 do tipanel_attachments[i].Visible = false end
            end
            if info_visible then
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) and cheat.Library.Opened then
                    if (mousepos - tipanel.pos).Magnitude < 50 or tipanel.dragging then
                        if not tipanel.dragging then
                            tipanel.dragging = true
                            tipanel.dragoffset = tipanel.pos - mousepos
                        end
                        tipanel.pos = mousepos + tipanel.dragoffset
                        silent_aim.tipanel_x = tipanel.pos.X
                        silent_aim.tipanel_y = tipanel.pos.Y
                    end
                else
                    tipanel.dragging = false
                    tipanel.pos = _Vector2new(silent_aim.tipanel_x, silent_aim.tipanel_y)
                end
                local p = tipanel.pos
                tipanel.bg.Position = p
                tipanel.border.Position = p
                tipanel.bg.Color = tipanel_settings.bgcolor
                tipanel.bg.Transparency = tipanel_settings.bgtrans
                tipanel.border.Color = tipanel_settings.bordercolor
                for i, g in ipairs(tipanel.glow) do
                    g.Position = p - _Vector2new(i, i)
                    g.Size = tipanel.bg.Size + _Vector2new(i*2, i*2)
                    g.Color = tipanel_settings.glowcolor
                end
                tipanel.avatar.Position = p + _Vector2new(8, 8)
                tipanel.avatar_border.Position = p + _Vector2new(7, 7)
                tipanel.hours.Position = p + _Vector2new(48, 92)
                local lx, rx = p.X + 100, p.X + 240
                local y_spacing = 20
                local rows = {"user", "k / d", "vis"}
                for i, row in ipairs(rows) do
                    local y = p.Y + 10 + (i-1) * y_spacing
                    tipanel.labels[row].Position = _Vector2new(lx, y)
                    tipanel.labels[row].Color = tipanel_settings.accentcolor
                    tipanel.values[row].Position = _Vector2new(rx - tipanel.values[row].TextBounds.X, y)
                end
                tipanel.hpbg.Position = p + _Vector2new(95, 75)
                tipanel.hpfill.Position = p + _Vector2new(95, 75)
                tipanel.hptext.Position = p + _Vector2new(170 - tipanel.hptext.TextBounds.X/2, 75)
                
                local player = Players:GetPlayerFromCharacter(target)
                local hum = target:FindFirstChildOfClass("Humanoid")
                local weapon = cheat.EspLibrary.get_gun(player or target)
                local k_d, action = "0.00 (0/0)", "None"
                
                if player then
                    -- Deep search for stats
                    local function find_stat(name)
                        local pfolder = _FindFirstChild(ReplicatedStorage.Players, player.Name)
                        local found = pfolder and pfolder:FindFirstChild(name, true)
                        if found then
                            if found:IsA("AttributeValue") or found:IsA("ValueBase") then return found.Value end
                            return found
                        end
                        -- Check player object too
                        local pstat = player:FindFirstChild(name, true)
                        if pstat then return pstat end
                        return nil
                    end

                    local stats_obj = find_stat("WipeStatistics") or find_stat("Statistics")
                    local h_stat = find_stat("Statistics")
                    local hours = h_stat and h_stat:GetAttribute("TimePlayed") or 0
                    tipanel.hours.Text = math.floor(hours / 3600) .. "h"

                    if stats_obj then
                        local kills = stats_obj:GetAttribute("Kills") or 0
                        local deaths = stats_obj:GetAttribute("Deaths") or 0
                        local ratio = kills / math.max(1, deaths)
                        local kd_val = (ratio % 1 == 0) and string.format("%d", ratio) or string.format("%.1f", ratio)
                        k_d = string.format("%skd(%d/%d)", kd_val, kills, deaths)
                    end
                    
                    local is_vis = false
                    if cheat.utility.is_visible then
                        is_vis = cheat.utility.is_visible(Camera.CFrame, target, silent_aim.target_part)
                    end
                    tipanel.values["vis"].Text = is_vis and "Visible" or "Hidden"
                    tipanel.values["vis"].Color = is_vis and Color3.fromRGB(150, 255, 150) or Color3.fromRGB(255, 150, 150)

                    action = (target:GetAttribute("Action")) or "None"
                    if tipanel.avatar_id ~= player.UserId then
                        tipanel.avatar_id = player.UserId
                        if avatar_cache[player.UserId] then
                            tipanel.avatar.Data = avatar_cache[player.UserId]
                        else
                            task.spawn(function()
                                local thumbUrl = string.format("https://www.roblox.com/headshot-thumbnail/image?userId=%d&width=150&height=150&format=png", player.UserId)
                                local success, data = pcall(function() return game:HttpGet(thumbUrl) end)
                                if success and data and #data > 100 then 
                                    tipanel.avatar.Data = data 
                                    avatar_cache[player.UserId] = data
                                else
                                    local cdnUrl = "https://thumbnails.roblox.com/v1/users/avatar-headshot?userIds="..player.UserId.."&size=150x150&format=Png&isCircular=false"
                                    local s2, d2 = pcall(function() return game:HttpGet(cdnUrl) end)
                                    if s2 and d2 then
                                        local link = d2:match('"imageUrl":"(.-)"')
                                        if link then
                                            local s3, d3 = pcall(function() return game:HttpGet(link) end)
                                            if s3 then 
                                                tipanel.avatar.Data = d3 
                                                avatar_cache[player.UserId] = d3
                                            end
                                        end
                                    end
                                end
                            end)
                        end
                    end
                end
                
                tipanel.values["user"].Text = player and player.Name or target.Name
                tipanel.values["k / d"].Text = k_d
                
                -- Setup weapon icons above info box
                for i = 1, 3 do tipanel_weapons[i].Visible = false end
                for i = 1, 12 do tipanel_attachments[i].Visible = false end
                
                if player then
                    local inv = target and target:FindFirstChild("Inventory")
                    if not inv then
                        local rp = ReplicatedStorage:FindFirstChild("Players")
                        local rpp = rp and rp:FindFirstChild(player.Name)
                        inv = rpp and rpp:FindFirstChild("Inventory")
                    end
                    
                    if inv then
                        local ItemsList = ReplicatedStorage:FindFirstChild("ItemsList")
                        if ItemsList then
                            local weapons = {}
                            for _, slot_item in pairs(inv:GetChildren()) do
                                if #weapons >= 3 then break end
                                local slot_attr = slot_item:GetAttribute("Slot")
                                if slot_attr and not string.find(slot_attr, "Clothing") and slot_item:FindFirstChild("Attachments") then
                                    table.insert(weapons, slot_item)
                                end
                            end
                            
                            local num_weps = #weapons
                            local total_width = (num_weps * 50) + math.max(0, num_weps - 1) * 5
                            local start_x = p.X + (tipanel.width / 2) - (total_width / 2)
                            local wy = p.Y - 65
                            
                            local a_idx = 0
                            for w_idx, slot_item in ipairs(weapons) do
                                local item_ref = ItemsList:FindFirstChild(slot_item.Name)
                                if item_ref and item_ref:FindFirstChild("ItemProperties") and item_ref.ItemProperties:FindFirstChild("ItemIcon") then
                                    local img = tipanel_weapons[w_idx]
                                    img.Image = item_ref.ItemProperties.ItemIcon.Image
                                    img.Visible = true
                                    
                                    local wx = start_x + (w_idx - 1) * 55
                                    img.Position = UDim2.new(0, wx, 0, wy)
                                    
                                    for _, att in pairs(slot_item.Attachments:GetChildren()) do
                                        local att_slot = att:GetAttribute("Slot")
                                        local att_ref = ItemsList:FindFirstChild(att.Name)
                                        local s_i = nil
                                        if att_slot == "Magazine" then s_i = 1
                                        elseif att_slot == "Sight" then s_i = 2
                                        elseif att_slot == "Muzzle" then s_i = 3
                                        elseif att_slot == "Extra" then s_i = 4 end
                                        
                                        if s_i and att_ref and att_ref:FindFirstChild("ItemProperties") and att_ref.ItemProperties:FindFirstChild("ItemIcon") then
                                            local a_img = tipanel_attachments[a_idx + s_i]
                                            a_img.Image = att_ref.ItemProperties.ItemIcon.Image
                                            a_img.Visible = true
                                            local attachment_width = 16
                                            local attachment_gap = 2
                                            local attachment_group_width = (attachment_width * 4) + (attachment_gap * 3)
                                            local attachment_x = wx + ((50 - attachment_group_width) / 2) + ((s_i - 1) * (attachment_width + attachment_gap))
                                            a_img.Position = UDim2.new(0, attachment_x, 0, wy + 32)
                                        end
                                    end
                                end
                                a_idx = a_idx + 4
                            end
                        end
                    end
                end
                
                if hum then
                    local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)
                    tipanel.hpfill.Size = _Vector2new(145 * pct, 12)
                    tipanel.hptext.Text = math.floor(hum.Health) .. "/" .. math.floor(hum.MaxHealth)
                end
            end
            if target_line_visible then
                local head_pos, on_screen = _WorldToViewportPoint(Camera, silent_aim.target_part.Position)
                if on_screen then
                    target_line.From = mousepos
                    target_line.To = _Vector2new(head_pos.X, head_pos.Y)
                    target_line.Visible = true
                end
            end
            if cursor.Enabled then
                rainbow = rainbow + (delta * 0.5)
                if rainbow > 1.0 then rainbow = 0.0 end
                color = Color3.fromHSV(rainbow, 1, 1)
                if cursor.CustomPos then pos = cursor.Position else pos = _Vector2new(
                    Mouse.X,
                    Mouse.Y + GuiInset.Y) end
                if cursor.rainbow then color = Color3.fromHSV(rainbow, 1, 1) else color = cursor.Color end
                if transp <= 1.5 + cursor.Text.LogoFadingOffset and not reverse then
                    transp = transp + ((cursor.Speed * 10) * delta)
                    if transp >= 1.5 + cursor.Text.LogoFadingOffset then setreverse(true) end
                elseif reverse then
                    transp = transp - ((cursor.Speed * 10) * delta)
                    if transp <= 0 - cursor.Text.LogoFadingOffset then setreverse(false) end
                end
                logotext.Position = _Vector2new(pos.X, (pos + _Vector2new(0, cursor.Radius + 5)).Y)
                logotext.Transparency = transp
                logotext.Visible = cursor.Text.Logo
                logotext.Color = cursor.Text.LogoColor
                logotext.Font = cursor.Font
                if cursor.sussy then
                    local frametime = delta
                    local a = cursor.Radius - 10
                    local gamma = math_atan(a / a)
                    if rotationdegree >= 90 then rotationdegree = 0 end
                    for i = 1, 4 do
                        local p_0 = (a * math_sin(DEG2RAD(rotationdegree + (i * 90))))
                        local p_1 = (a * math_cos(DEG2RAD(rotationdegree + (i * 90))))
                        local p_2 = ((a / math_cos(gamma)) * math_sin(DEG2RAD(rotationdegree + (i * 90) + RAD2DEG(gamma))))
                        local p_3 = ((a / math_cos(gamma)) * math_cos(DEG2RAD(rotationdegree + (i * 90) + RAD2DEG(gamma))))
                        lines[i][1].From = _Vector2new(pos.X, pos.Y)
                        lines[i][1].To = _Vector2new(pos.X + p_0, pos.Y - p_1)
                        lines[i][1].Color = color
                        lines[i][1].Thickness = cursor.Thickness
                        lines[i][1].Visible = true
                        lines[i][3].From = _Vector2new(pos.X + p_0, pos.Y - p_1)
                        lines[i][3].To = _Vector2new(pos.X + p_2, pos.Y - p_3)
                        lines[i][3].Color = color
                        lines[i][3].Thickness = cursor.Thickness
                        lines[i][3].Visible = true
                    end
                    rotationdegree = rotationdegree + ((cursor.Speed * frametime) * 1000)
                else
                    angle = angle + ((cursor.Speed * 10) * delta)
                    if angle >= 90 then
                        angle = 0
                    end
                    dot.Visible = cursor.Dot
                    dot.Color = color
                    dot.Position = _Vector2new(pos.X - 1, pos.Y - 1)
                    outline.Visible = cursor.Outline and cursor.Dot
                    outline.Position = _Vector2new(pos.X - 2, pos.Y - 2)
                    for index, line in pairs(lines) do
                        index = index
                        local x, y = {}, {}
                        local x1, y1 = {}, {}
                        if cursor.Resize then
                            x = { pos.X +
                            (math_cos(angle + (index * (math.pi / 2))) * (cursor.Radius + ((cursor.Radius * math_sin(angle)) / 9))),
                                pos.X +
                                (math_cos(angle + (index * (math.pi / 2))) * ((cursor.Radius - 20) - (cursor.TheGap and (((cursor.Radius - 20) * math_cos(angle)) / 4) or (((cursor.Radius - 20) * math_cos(angle)) - 4)))) }
                            y = { pos.Y +
                            (math_sin(angle + (index * (math.pi / 2))) * (cursor.Radius + ((cursor.Radius * math_sin(angle)) / 9))),
                                pos.Y +
                                (math_sin(angle + (index * (math.pi / 2))) * ((cursor.Radius - 20) - (cursor.TheGap and (((cursor.Radius - 20) * math_cos(angle)) / 4) or (((cursor.Radius - 20) * math_cos(angle)) - 4)))) }
                            x1 = { pos.X + (math_cos(angle + (index * (math.pi / 2))) * (cursor.Radius + 1)), pos
                            .X +
                            (math_cos(angle + (index * (math.pi / 2))) * ((cursor.Radius - 20 + 1) - (cursor.TheGap and ((cursor.Radius - 20 + 1) / cursor.Gap) or ((cursor.Radius - 20 + 1) - cursor.Gap)))) }
                            y1 = { pos.Y + (math_sin(angle + (index * (math.pi / 2))) * (cursor.Radius + 1)), pos
                            .Y +
                            (math_sin(angle + (index * (math.pi / 2))) * ((cursor.Radius - 20 + 1) - (cursor.TheGap and ((cursor.Radius - 20 + 1) / cursor.Gap) or ((cursor.Radius - 20 + 1) - cursor.Gap)))) }
                        else
                            x = { pos.X + (math_cos(angle + (index * (math.pi / 2))) * (cursor.Radius)), pos.X +
                            (math_cos(angle + (index * (math.pi / 2))) * ((cursor.Radius - 20) - (cursor.TheGap and ((cursor.Radius - 20) / cursor.Gap) or ((cursor.Radius - 20) - cursor.Gap)))) }
                            y = { pos.Y + (math_sin(angle + (index * (math.pi / 2))) * (cursor.Radius)), pos.Y +
                            (math_sin(angle + (index * (math.pi / 2))) * ((cursor.Radius - 20) - (cursor.TheGap and ((cursor.Radius - 20) / cursor.Gap) or ((cursor.Radius - 20) - cursor.Gap)))) }
                            x1 = { pos.X + (math_cos(angle + (index * (math.pi / 2))) * (cursor.Radius + 1)), pos
                            .X +
                            (math_cos(angle + (index * (math.pi / 2))) * ((cursor.Radius - 20 + 1) - (cursor.TheGap and ((cursor.Radius - 20 + 1) / cursor.Gap) or ((cursor.Radius - 20 + 1) - cursor.Gap)))) }
                            y1 = { pos.Y + (math_sin(angle + (index * (math.pi / 2))) * (cursor.Radius + 1)), pos
                            .Y +
                            (math_sin(angle + (index * (math.pi / 2))) * ((cursor.Radius - 20 + 1) - (cursor.TheGap and ((cursor.Radius - 20 + 1) / cursor.Gap) or ((cursor.Radius - 20 + 1) - cursor.Gap)))) }
                        end
                        line[1].Visible = true
                        line[1].Color = color
                        line[1].From = _Vector2new(x[2], y[2])
                        line[1].To = _Vector2new(x[1], y[1])
                        line[1].Thickness = cursor.Thickness
                        line[2].Visible = cursor.Outline
                        line[2].From = _Vector2new(x1[2], y1[2])
                        line[2].To = _Vector2new(x1[1], y1[1])
                        line[2].Thickness = cursor.Thickness + 2.5
                        line[3].Visible = false
                    end
                end
            else
                dot.Visible = false
                outline.Visible = false
                logotext.Visible = false

                for index, line in pairs(lines) do
                    line[1].Visible = false
                    line[2].Visible = false
                    line[3].Visible = false
                end
            end
        end))
    end
        do
        -- =====================================================
        -- EXACT STATE REPLICATOR + InventoryFrame Cleanup
        -- (Weapon icons remain visible; empty slots show custom texture)
        -- =====================================================
        local Players = game:GetService("Players")
        local RunService = game:GetService("RunService")
        local player = Players.LocalPlayer
        local playerGui = player:WaitForChild("PlayerGui")
        local mainGui = playerGui:WaitForChild("MainGui")
        local mainFrame = mainGui:WaitForChild("MainFrame")

        local runtimeEnvironment = _G
        if type(getgenv) == "function" then
            local ok, environment = pcall(getgenv)
            if ok and type(environment) == "table" then runtimeEnvironment = environment end
        end

        local CONNECTIONS_KEY = "__MinecraftInventoryConnections"
        local previousConnections = runtimeEnvironment[CONNECTIONS_KEY]
        if type(previousConnections) == "table" then
            for _, connection in ipairs(previousConnections) do
                pcall(function() connection:Disconnect() end)
            end
        end

        local activeConnections = {}
        runtimeEnvironment[CONNECTIONS_KEY] = activeConnections

        local function connect(signal, callback)
            local connection = signal:Connect(callback)
            table.insert(activeConnections, connection)
            return connection
        end

        local headerVisibilityConnected = setmetatable({}, { __mode = "k" })
        local lootChromeConnected = setmetatable({}, { __mode = "k" })
        local gearSlotStyleConnected = setmetatable({}, { __mode = "k" })
        local durabilityStyleConnected = setmetatable({}, { __mode = "k" })
        local durabilityBarStyleConnected = setmetatable({}, { __mode = "k" })
        local originalDurabilityBarStyleConnected = setmetatable({}, { __mode = "k" })
        local durabilityStyleApplying = setmetatable({}, { __mode = "k" })
        local equipmentPlaceholderSlotConnected = setmetatable({}, { __mode = "k" })
        local equipmentPlaceholderImageConnected = setmetatable({}, { __mode = "k" })
        local equipmentPlaceholderLabelConnected = setmetatable({}, { __mode = "k" })
        local hiddenCharacterPanelConnected = setmetatable({}, { __mode = "k" })
        local hotbarSlotConnected = setmetatable({}, { __mode = "k" })
        local hotbarObjectConnected = setmetatable({}, { __mode = "k" })
        local hotbarStyleApplying = setmetatable({}, { __mode = "k" })

        local DECOR_ID = "rbxassetid://103684393954887"
        local DEFAULT_ICON_TEXTURE = "rbxassetid://73001094407966"
        local GEAR_SLOT_TEXTURE = "rbxassetid://88138258152734"
        local GEAR_SLOT_BACKGROUND_NAME = "_CustomSlotBackground"
        local GEAR_SLOT_BACKGROUND_SCALE = 1.12
        local INVENTORY_SCALE_NAME = "CharacterLinkedScale"
        local LOOT_SCROLL_BACKGROUND = Color3.fromRGB(198, 198, 198) -- #C6C6C6
        local INVENTORY_BACKPACK_X = UDim.new(0.463999987, 0)
        local DURABILITY_SIZE = UDim2.new(0.899999976, 0, 0.0599999987, 0)
        local DURABILITY_POSITION = UDim2.new(0.5, 0, 1, 0)
        local DURABILITY_ANCHOR = Vector2.new(0.5, 1)
        local DURABILITY_BACKGROUND = Color3.fromRGB(49, 49, 49)
        local DURABILITY_BAR_COLOR = Color3.fromRGB(0, 255, 0)
        local HOTBAR_SLOT_SIZE = 65
        local HOTBAR_SLOT_GAP = 1
        local HOTBAR_SELECTION_SCALE = 1.15
        local HOTBAR_ICON_SCALE = 0.7
        local HOTBAR_BACKGROUND_ASSET = "rbxassetid://70588752589811"
        local HOTBAR_SELECTION_ASSET = "rbxassetid://72935494496554"
        local MINECRAFT_BAR_SLOT_SIZE = 22
        local MINECRAFT_BAR_GROUP_GAP = 270
        local MINECRAFT_BAR_EMPTY_HEART = "rbxassetid://94958343617285"
        local MINECRAFT_BAR_FULL_HEART = "rbxassetid://79495863126032"
        local MINECRAFT_BAR_EMPTY_FOOD = "rbxassetid://131689845619967"
        local MINECRAFT_BAR_FULL_FOOD = "rbxassetid://138496845817935"
        local MINECRAFT_BAR_EMPTY_WATER = "rbxassetid://89290030612930"
        local MINECRAFT_BAR_FULL_WATER = "rbxassetid://110335546571119"
        local CHARACTER_GEAR_SLOT_NAMES = {
            "Melee",
            "ItemHip1",
            "ItemBack2",
            "ItemBack1",
            "ClothingShirt",
            "ClothingPants",
            "ClothingMask",
            "ClothingLegArmor",
            "ClothingHeadware",
            "ClothingGloves",
            "ClothingChestRig",
            "ClothingBackpack",
        }

        -- Captured from the live Loot panel after the user placed it.
        local LOOT_LAYOUT = {
            RootSize = UDim2.new(0.519999981, 0, 0.721000016, 0),
            RootPosition = UDim2.new(0.655999124, 0, 0.141435608, 0),
            RootAnchor = Vector2.new(0, 0),

            InventorySize = UDim2.new(1.50999999, 0, 0.5, 0),
            InventoryPosition = UDim2.new(-1.60000002, 0, 0.0399999991, 0),
            InventoryAnchor = Vector2.new(0, 0),

            ScrollingSize = UDim2.new(1, 0, 1, 0),
            ScrollingPosition = UDim2.new(0, 0, 0, 0),
            ScrollingAnchor = Vector2.new(0, 0),
            ScrollBarThickness = 6,

            ContainerPosition = UDim2.new(0.5, 0, 0, 0),
            ContainerAnchor = Vector2.new(0.5, 0),
            InnerPosition = UDim2.new(0.0160000008, 0, 0, 28),
            InnerAnchor = Vector2.new(0, 0),
            InnerWidthOffset = -17,

            TitleSize = UDim2.new(0.917717397, 0, 0.139884055, 0),
            TitlePosition = UDim2.new(0.0106535805, 0, 0.0454831421, 0),
            TitleAnchor = Vector2.new(0, 0),

            CellSize = UDim2.new(0, 72, 0, 72),
            CellPadding = UDim2.new(0, 3, 0, 3),
            Columns = 9,
        }

        local LOOT_SLOT_LAYOUT = {
            Root = { Size = UDim2.new(0.140000001, 0, 0.140000001, 0), Position = UDim2.new(0.150000006, 0, 0.0500000007, 0), Anchor = Vector2.new(0, 0) },
            ItemName = { Size = UDim2.new(0.925000012, 0, 0.174999997, 0), Position = UDim2.new(0.0500000007, 0, 0.959999979, 0), Anchor = Vector2.new(0, 1) },
            Amount = { Size = UDim2.new(1, 0, 0.200000003, 0), Position = UDim2.new(0.0500000007, 0, 0.0399999991, 0), Anchor = Vector2.new(0, 0) },
            HotKey = { Size = UDim2.new(0.200000003, 0, 0.200000003, 0), Position = UDim2.new(1, 0, 0, 0), Anchor = Vector2.new(1, 0) },
            ImageLabel = { Size = UDim2.new(0.850000024, 0, 0.850000024, 0), Position = UDim2.new(0.5, 0, 0.5, 0), Anchor = Vector2.new(0.5, 0.5) },
            PreImageLabel = { Size = UDim2.new(0.800000012, 0, 0.800000012, 0), Position = UDim2.new(0.5, 0, 0.5, 0), Anchor = Vector2.new(0.5, 0.5) },
            Durability = { Size = DURABILITY_SIZE, Position = DURABILITY_POSITION, Anchor = DURABILITY_ANCHOR },
            ClickDetector = { Size = UDim2.new(1.10000002, 0, 1.10000002, 0), Position = UDim2.new(0.5, 0, 0.5, 0), Anchor = Vector2.new(0.5, 0.5) },
            FastLootIcon = { Size = UDim2.new(1, 0, 1, 0), Position = UDim2.new(0, 0, 0, 0), Anchor = Vector2.new(0, 0) },
        }

        local LOOT_GEAR_COLUMNS = 6
        local LOOT_GEAR_MAX_CELL_SIZE = 82
        local LOOT_GEAR_TITLE_HEIGHT = 22
        local LOOT_GEAR_BOTTOM_GAP = 14

        -- InventoryFrame must stay under BackpackFrame because the game's own scripts
        -- look it up there. A UIScale gives it the same visual resize behaviour as if
        -- it were parented to CharacterFrame, without breaking that expected path.
        local function linkInventoryScale(characterFrame, inventoryFrame, backpackFrame, originalCharacterAbsoluteSize, originalBackpackAbsoluteSize)
            local inventoryScale = inventoryFrame:FindFirstChild(INVENTORY_SCALE_NAME)
            if inventoryScale then
                -- Replacing it makes executor reruns safe: connections left by an older
                -- run can only update the destroyed instance, never this new scaler.
                inventoryScale:Destroy()
            end

            inventoryScale = Instance.new("UIScale")
            inventoryScale.Name = INVENTORY_SCALE_NAME
            inventoryScale.Parent = inventoryFrame

            local baseCharacterAbsoluteSize = originalCharacterAbsoluteSize
            local baseBackpackAbsoluteSize = originalBackpackAbsoluteSize
            inventoryScale:SetAttribute("BaseCharacterAbsoluteSize", baseCharacterAbsoluteSize)
            inventoryScale:SetAttribute("BaseBackpackAbsoluteSize", baseBackpackAbsoluteSize)

            local function updateScale()
                local parentSize = backpackFrame.AbsoluteSize
                local currentSize = characterFrame.AbsoluteSize

                -- Use one uniform scale so square slots, icons and text do not stretch.
                -- The smaller axis also keeps the inventory from overflowing its panel.
                if baseCharacterAbsoluteSize.X > 0 and baseCharacterAbsoluteSize.Y > 0
                    and baseBackpackAbsoluteSize.X > 0 and baseBackpackAbsoluteSize.Y > 0
                    and parentSize.X > 0 and parentSize.Y > 0
                    and currentSize.X > 0 and currentSize.Y > 0 then
                    -- Dividing out BackpackFrame's own resize prevents viewport or
                    -- ancestor UIScale changes from being applied a second time.
                    local parentWidthScale = parentSize.X / baseBackpackAbsoluteSize.X
                    local parentHeightScale = parentSize.Y / baseBackpackAbsoluteSize.Y
                    local widthScale = (currentSize.X / baseCharacterAbsoluteSize.X) / parentWidthScale
                    local heightScale = (currentSize.Y / baseCharacterAbsoluteSize.Y) / parentHeightScale
                    inventoryScale.Scale = math.clamp(math.min(widthScale, heightScale), 0.25, 4)
                end
            end

            connect(characterFrame:GetPropertyChangedSignal("Size"), updateScale)
            connect(characterFrame:GetPropertyChangedSignal("AbsoluteSize"), updateScale)
            connect(backpackFrame:GetPropertyChangedSignal("AbsoluteSize"), updateScale)

            updateScale()
            task.defer(updateScale)
        end

        local function applyGeometry(guiObject, geometry)
            if not guiObject or not guiObject:IsA("GuiObject") or not geometry then return end
            guiObject.Size = geometry.Size
            guiObject.Position = geometry.Position
            guiObject.AnchorPoint = geometry.Anchor
        end

        local function isGearSlot(guiObject)
            if not guiObject or not guiObject:IsA("GuiObject") then return false end

            return guiObject:FindFirstChild("ClickDetector") ~= nil
                or (guiObject:FindFirstChild("PreImageLabel") ~= nil and guiObject:FindFirstChild("ItemName") ~= nil)
                or (guiObject:FindFirstChild("Amount") ~= nil and guiObject:FindFirstChild("Durability") ~= nil)
        end

        local function isRemovedGearChrome(descendant)
            local lowerName = string.lower(descendant.Name)
            return descendant.Name == "SlotType"
                or descendant:IsA("UICorner")
                or descendant.ClassName == "UIShadow"
                or lowerName == "shadow"
                or lowerName == "dropshadow"
                or lowerName == "uishadow"
        end

        local function styleGearSlot(slotFrame)
            if not isGearSlot(slotFrame) then return end

            slotFrame.BackgroundTransparency = 1
            slotFrame.ClipsDescendants = false

            local background = slotFrame:FindFirstChild(GEAR_SLOT_BACKGROUND_NAME)
            if not background then
                background = Instance.new("ImageLabel")
                background.Name = GEAR_SLOT_BACKGROUND_NAME
                background.Parent = slotFrame
            end

            background.AnchorPoint = Vector2.new(0.5, 0.5)
            background.Position = UDim2.fromScale(0.5, 0.5)
            -- Enlarge only the Minecraft slot texture. The parent slot remains the
            -- same size, so item icons, text, durability and interaction do not scale.
            background.Size = UDim2.fromScale(GEAR_SLOT_BACKGROUND_SCALE, GEAR_SLOT_BACKGROUND_SCALE)
            background.BackgroundTransparency = 1
            background.BorderSizePixel = 0
            background.Image = GEAR_SLOT_TEXTURE
            background.ImageColor3 = Color3.new(1, 1, 1)
            background.ImageTransparency = 0
            background.ScaleType = Enum.ScaleType.Stretch
            background.ZIndex = 0

            for _, descendant in ipairs(slotFrame:GetDescendants()) do
                if descendant ~= background and isRemovedGearChrome(descendant) then
                    descendant:Destroy()
                end
            end

            if not gearSlotStyleConnected[slotFrame] then
                gearSlotStyleConnected[slotFrame] = true
                connect(slotFrame:GetPropertyChangedSignal("BackgroundTransparency"), function()
                    if slotFrame.BackgroundTransparency ~= 1 then
                        slotFrame.BackgroundTransparency = 1
                    end
                end)
                connect(slotFrame.DescendantAdded, function(descendant)
                    if descendant ~= background and isRemovedGearChrome(descendant) then
                        descendant:Destroy()
                    end
                end)
                connect(slotFrame.ChildRemoved, function(child)
                    if child == background then
                        task.defer(function()
                            if slotFrame.Parent then styleGearSlot(slotFrame) end
                        end)
                    end
                end)
            end
        end

        local function styleActiveDurabilityBar(bar)
            if not bar or not bar:IsA("GuiObject") then return end
            if durabilityStyleApplying[bar] then return end
            durabilityStyleApplying[bar] = true

            -- Keep X exactly as the game sets it: that axis is the item's real
            -- durability percentage. Only copy the edited thickness and appearance.
            local currentSize = bar.Size
            bar.Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, 3, 0)
            bar.Position = UDim2.new(0, 0, 0.5, 0)
            bar.AnchorPoint = Vector2.new(0, 0.5)
            bar.BackgroundColor3 = DURABILITY_BAR_COLOR
            bar.BackgroundTransparency = 0
            bar.BorderSizePixel = 0
            bar.ZIndex = 3

            for _, child in ipairs(bar:GetChildren()) do
                if child:IsA("UIGradient") then child:Destroy() end
            end

            durabilityStyleApplying[bar] = nil

            if not durabilityBarStyleConnected[bar] then
                durabilityBarStyleConnected[bar] = true
                connect(bar.Changed, function(property)
                    if property == "Size"
                        or property == "Position"
                        or property == "AnchorPoint"
                        or property == "BackgroundColor3"
                        or property == "BackgroundTransparency"
                        or property == "ZIndex" then
                        styleActiveDurabilityBar(bar)
                    end
                end)
                connect(bar.ChildAdded, function(child)
                    if child:IsA("UIGradient") then child:Destroy() end
                end)
            end
        end

        local function styleOriginalDurabilityBar(bar)
            if not bar or not bar:IsA("GuiObject") then return end
            if durabilityStyleApplying[bar] then return end
            durabilityStyleApplying[bar] = true

            local currentSize = bar.Size
            bar.Size = UDim2.new(currentSize.X.Scale, currentSize.X.Offset, 2, 0)
            bar.Position = UDim2.new(1, 0, 0.5, 0)
            bar.AnchorPoint = Vector2.new(1, 0.5)
            bar.BackgroundColor3 = Color3.fromRGB(197, 60, 62)
            bar.BackgroundTransparency = 0.1
            bar.BorderSizePixel = 0
            bar.ZIndex = 2

            durabilityStyleApplying[bar] = nil

            if not originalDurabilityBarStyleConnected[bar] then
                originalDurabilityBarStyleConnected[bar] = true
                connect(bar.Changed, function(property)
                    if property == "Size"
                        or property == "Position"
                        or property == "AnchorPoint"
                        or property == "BackgroundColor3"
                        or property == "BackgroundTransparency"
                        or property == "ZIndex" then
                        styleOriginalDurabilityBar(bar)
                    end
                end)
            end
        end

        local function styleDurability(durability)
            if not durability or durability.Name ~= "Durability" or not durability:IsA("GuiObject") then return end
            if durabilityStyleApplying[durability] then return end
            durabilityStyleApplying[durability] = true

            durability.Size = DURABILITY_SIZE
            durability.Position = DURABILITY_POSITION
            durability.AnchorPoint = DURABILITY_ANCHOR
            durability.BackgroundColor3 = DURABILITY_BACKGROUND
            durability.BackgroundTransparency = 0
            durability.BorderSizePixel = 0
            durability.ZIndex = 2

            durabilityStyleApplying[durability] = nil

            styleActiveDurabilityBar(durability:FindFirstChild("Bar"))
            styleOriginalDurabilityBar(durability:FindFirstChild("OriginalDurabilityBar"))

            if not durabilityStyleConnected[durability] then
                durabilityStyleConnected[durability] = true
                connect(durability.Changed, function(property)
                    if property == "Size"
                        or property == "Position"
                        or property == "AnchorPoint"
                        or property == "BackgroundColor3"
                        or property == "BackgroundTransparency"
                        or property == "ZIndex" then
                        styleDurability(durability)
                    end
                end)
                connect(durability.ChildAdded, function(child)
                    if child.Name == "Bar" then
                        styleActiveDurabilityBar(child)
                    elseif child.Name == "OriginalDurabilityBar" then
                        styleOriginalDurabilityBar(child)
                    end
                end)
            end
        end

        local function setupGlobalDurabilityStyle(backpackFrame)
            for _, descendant in ipairs(backpackFrame:GetDescendants()) do
                if descendant.Name == "Durability" then
                    styleDurability(descendant)
                end
            end

            connect(backpackFrame.DescendantAdded, function(descendant)
                if descendant.Name == "Durability" then
                    task.defer(function()
                        if descendant.Parent then styleDurability(descendant) end
                    end)
                elseif descendant.Name == "Bar" and descendant.Parent and descendant.Parent.Name == "Durability" then
                    styleActiveDurabilityBar(descendant)
                elseif descendant.Name == "OriginalDurabilityBar" and descendant.Parent and descendant.Parent.Name == "Durability" then
                    styleOriginalDurabilityBar(descendant)
                end
            end)
        end

        local function makeSlotTextResponsive(slotFrame)
            for _, child in ipairs(slotFrame:GetChildren()) do
                if child:IsA("TextLabel") or child:IsA("TextButton") then
                    local maxTextSize = math.max(8, math.floor(child.TextSize + 0.5))
                    child.TextScaled = true

                    local constraint = child:FindFirstChild("ResponsiveTextSize")
                    if not constraint then
                        constraint = Instance.new("UITextSizeConstraint")
                        constraint.Name = "ResponsiveTextSize"
                        constraint.Parent = child
                    end
                    constraint.MinTextSize = 6
                    constraint.MaxTextSize = maxTextSize
                end
            end
        end

        local function updateEquipmentPlaceholder(slotFrame)
            if not slotFrame or not slotFrame:IsA("Frame") then return end

            local itemImage = slotFrame:FindFirstChild("ImageLabel")
            local placeholder = slotFrame:FindFirstChild("PreImageLabel")
            if placeholder and placeholder:IsA("GuiObject") then
                -- Equipment slots already contain their correct compass/GPS/radio/etc.
                -- placeholder image. Show it only while no real item image is present.
                local empty = not itemImage
                    or not itemImage:IsA("ImageLabel")
                    or itemImage.Image == ""
                placeholder.Visible = empty
                placeholder.ZIndex = 2

                if not equipmentPlaceholderLabelConnected[placeholder] then
                    equipmentPlaceholderLabelConnected[placeholder] = true
                    connect(placeholder:GetPropertyChangedSignal("Visible"), function()
                        updateEquipmentPlaceholder(slotFrame)
                    end)
                end
            end

            if itemImage and itemImage:IsA("ImageLabel") and not equipmentPlaceholderImageConnected[itemImage] then
                equipmentPlaceholderImageConnected[itemImage] = true
                connect(itemImage:GetPropertyChangedSignal("Image"), function()
                    updateEquipmentPlaceholder(slotFrame)
                end)
            end

            if not equipmentPlaceholderSlotConnected[slotFrame] then
                equipmentPlaceholderSlotConnected[slotFrame] = true
                connect(slotFrame.ChildAdded, function(child)
                    if child.Name == "ImageLabel" or child.Name == "PreImageLabel" then
                        task.defer(function()
                            if slotFrame.Parent then updateEquipmentPlaceholder(slotFrame) end
                        end)
                    end
                end)
                connect(slotFrame.ChildRemoved, function(child)
                    if child.Name == "ImageLabel" or child.Name == "PreImageLabel" then
                        task.defer(function()
                            if slotFrame.Parent then updateEquipmentPlaceholder(slotFrame) end
                        end)
                    end
                end)
            end
        end

        local function isInsideLootGear(instance, scrollingFrame)
            local current = instance
            while current and current ~= scrollingFrame do
                if current.Name == "Gear" then
                    return true
                end
                current = current.Parent
            end
            return false
        end

        local function hideCharacterPanel(panel)
            if not panel or not panel:IsA("GuiObject") then return end
            panel.Visible = false

            if not hiddenCharacterPanelConnected[panel] then
                hiddenCharacterPanelConnected[panel] = true
                connect(panel:GetPropertyChangedSignal("Visible"), function()
                    if panel.Visible then panel.Visible = false end
                end)
            end
        end

        local function setupHiddenCharacterPanels(characterFrame)
            local function handleChild(child)
                if child.Name == "VitalSigns" or child.Name == "ProtectionSatus" then
                    hideCharacterPanel(child)
                end
            end

            handleChild(characterFrame:FindFirstChild("VitalSigns"))
            handleChild(characterFrame:FindFirstChild("ProtectionSatus"))
            connect(characterFrame.ChildAdded, handleChild)
        end

        local function disableHotbarClipping(hotbar)
            local current = hotbar
            while current do
                if current:IsA("GuiObject") then
                    current.ClipsDescendants = false
                end
                if current:IsA("PlayerGui") or current:IsA("CoreGui") or current:IsA("ScreenGui") then
                    break
                end
                current = current.Parent
            end
        end

        local function styleHotbarSlot(slot)
            if not slot or not slot:IsA("Frame") or hotbarStyleApplying[slot] then return end

            local weaponIcon = slot:FindFirstChild("ImageLabel")
            if not weaponIcon or not weaponIcon:IsA("ImageLabel") then return end

            hotbarStyleApplying[slot] = true

            slot.Size = UDim2.new(0, HOTBAR_SLOT_SIZE, 0, HOTBAR_SLOT_SIZE)
            slot.BackgroundTransparency = 1
            slot.ClipsDescendants = false

            local slotType = slot:FindFirstChild("SlotType")
            if slotType and slotType:IsA("GuiObject") then
                slotType.Visible = true
                slotType.ZIndex = 40
            end

            local background = slot:FindFirstChild("SlotBackground")
            if not background then
                background = Instance.new("ImageLabel")
                background.Name = "SlotBackground"
                background.Parent = slot
            end
            if background:IsA("ImageLabel") then
                background.Image = HOTBAR_BACKGROUND_ASSET
                background.Size = UDim2.new(1, 0, 1, 0)
                background.Position = UDim2.new(0, 0, 0, 0)
                background.AnchorPoint = Vector2.new(0, 0)
                background.BackgroundTransparency = 1
                background.BorderSizePixel = 0
                background.ZIndex = 0
            end

            local selection = slot:FindFirstChild("SelectionOverlay")
            if not selection then
                selection = Instance.new("ImageLabel")
                selection.Name = "SelectionOverlay"
                selection.Parent = slot
            end
            if selection:IsA("ImageLabel") then
                local selectionInset = -((HOTBAR_SELECTION_SCALE - 1) / 2)
                selection.Image = HOTBAR_SELECTION_ASSET
                selection.Size = UDim2.new(HOTBAR_SELECTION_SCALE, 0, HOTBAR_SELECTION_SCALE, 0)
                selection.Position = UDim2.new(selectionInset, 0, selectionInset, 0)
                selection.AnchorPoint = Vector2.new(0, 0)
                selection.BackgroundTransparency = 1
                selection.BorderSizePixel = 0
            end

            local highlight = slot:FindFirstChild("Highlight")
            local isActive = highlight and highlight:IsA("GuiObject") and highlight.Visible or false
            if highlight then
                for _, descendant in ipairs(highlight:GetDescendants()) do
                    if descendant:IsA("UIStroke") then
                        descendant.Transparency = 1
                        descendant.Thickness = 0
                    end
                end
            end

            if selection and selection:IsA("GuiObject") then
                selection.Visible = isActive
                selection.ZIndex = isActive and 100 or 50
            end

            -- Preserve the game's Position and ScaleType; only resize the item icon.
            weaponIcon.Size = UDim2.new(HOTBAR_ICON_SCALE, 0, HOTBAR_ICON_SCALE, 0)
            weaponIcon.ZIndex = 30

            hotbarStyleApplying[slot] = nil

            local function watchObject(object, properties)
                if not object or hotbarObjectConnected[object] then return end
                hotbarObjectConnected[object] = true
                connect(object.Changed, function(property)
                    if properties[property] then styleHotbarSlot(slot) end
                end)
            end

            watchObject(slot, {
                Size = true,
                BackgroundTransparency = true,
                ClipsDescendants = true,
            })
            watchObject(weaponIcon, { Size = true, ZIndex = true })
            watchObject(slotType, { Visible = true, ZIndex = true })
            watchObject(background, {
                Image = true,
                Size = true,
                Position = true,
                BackgroundTransparency = true,
                ZIndex = true,
            })
            watchObject(selection, {
                Image = true,
                Size = true,
                Position = true,
                BackgroundTransparency = true,
                Visible = true,
                ZIndex = true,
            })
            watchObject(highlight, { Visible = true })

            if highlight then
                for _, descendant in ipairs(highlight:GetDescendants()) do
                    if descendant:IsA("UIStroke") then
                        watchObject(descendant, { Transparency = true, Thickness = true })
                    end
                end
            end

            if not hotbarSlotConnected[slot] then
                hotbarSlotConnected[slot] = true
                connect(slot.DescendantAdded, function()
                    task.defer(function()
                        if slot.Parent then styleHotbarSlot(slot) end
                    end)
                end)
                connect(slot.DescendantRemoving, function()
                    task.defer(function()
                        if slot.Parent then styleHotbarSlot(slot) end
                    end)
                end)
            end
        end

        local function setupHotbar(mainFrame)
            local hotbar = mainFrame:FindFirstChild("Hotbar") or mainFrame:WaitForChild("Hotbar", 5)
            if not hotbar or not hotbar:IsA("GuiObject") then return end

            disableHotbarClipping(hotbar)

            local function handleHotbarChild(child)
                if child.Name == "Spacer" then
                    child:Destroy()
                elseif child:IsA("UIListLayout") then
                    child.Padding = UDim.new(0, HOTBAR_SLOT_GAP)
                    if not hotbarObjectConnected[child] then
                        hotbarObjectConnected[child] = true
                        connect(child:GetPropertyChangedSignal("Padding"), function()
                            if child.Padding ~= UDim.new(0, HOTBAR_SLOT_GAP) then
                                child.Padding = UDim.new(0, HOTBAR_SLOT_GAP)
                            end
                        end)
                    end
                elseif child:IsA("Frame") then
                    styleHotbarSlot(child)
                end
            end

            for _, child in ipairs(hotbar:GetChildren()) do
                handleHotbarChild(child)
            end
            connect(hotbar.ChildAdded, function(child)
                task.defer(function()
                    if child.Parent == hotbar then handleHotbarChild(child) end
                end)
            end)
        end

        local function setupMinecraftBar(mainFrame, characterFrame)
            local statusEffects = mainFrame:FindFirstChild("Notifications")
                and mainFrame.Notifications:FindFirstChild("StatusEffects")
                or mainFrame:FindFirstChild("StatusEffects")
            hideCharacterPanel(statusEffects)

            local minecraftGui = playerGui:FindFirstChild("MinecraftBar")
            if minecraftGui and not minecraftGui:IsA("ScreenGui") then
                minecraftGui:Destroy()
                minecraftGui = nil
            end
            if not minecraftGui then
                minecraftGui = Instance.new("ScreenGui")
                minecraftGui.Name = "MinecraftBar"
                minecraftGui.Parent = playerGui
            end
            minecraftGui.ResetOnSpawn = false

            -- Rebuild only this custom GUI. Connections from an earlier inventory.lua
            -- run were disconnected by the shared rerun registry at the top.
            for _, child in ipairs(minecraftGui:GetChildren()) do
                child:Destroy()
            end

            local iconSize = MINECRAFT_BAR_SLOT_SIZE
            local iconCount = 10
            local groupWidth = iconSize * iconCount
            local foodStartX = groupWidth + MINECRAFT_BAR_GROUP_GAP
            local waterStartX = foodStartX

            local container = Instance.new("Frame")
            container.Name = "Bars"
            container.Size = UDim2.new(0, foodStartX + groupWidth + 10, 0, iconSize * 2)
            container.Position = UDim2.new(0.5, 0, 1, -(iconSize + 36))
            container.AnchorPoint = Vector2.new(0.495, 1)
            container.BackgroundTransparency = 1
            container.Parent = minecraftGui

            local function createStatusSlot(name, x, y, emptyImage, fullImage)
                local slot = Instance.new("Frame")
                slot.Name = name
                slot.Size = UDim2.new(0, iconSize, 0, iconSize)
                slot.Position = UDim2.new(0, x, 0, y)
                slot.BackgroundTransparency = 1
                slot.Parent = container

                local empty = Instance.new("ImageLabel")
                empty.Name = "Empty"
                empty.Size = UDim2.new(1, 0, 1, 0)
                empty.BackgroundTransparency = 1
                empty.Image = emptyImage
                empty.ScaleType = Enum.ScaleType.Fit
                empty.Parent = slot

                local full = Instance.new("ImageLabel")
                full.Name = "Full"
                full.Size = UDim2.new(1, 0, 1, 0)
                full.BackgroundTransparency = 1
                full.Image = fullImage
                full.ScaleType = Enum.ScaleType.Fit
                full.ImageTransparency = 1
                full.Parent = slot

                return full
            end

            local heartOverlays = {}
            local foodOverlays = {}
            local waterOverlays = {}
            local waterY = -(iconSize + 2)

            for index = 1, iconCount do
                local step = (index - 1) * iconSize
                heartOverlays[index] = createStatusSlot(
                    "Heart" .. index,
                    step,
                    0,
                    MINECRAFT_BAR_EMPTY_HEART,
                    MINECRAFT_BAR_FULL_HEART
                )
                foodOverlays[index] = createStatusSlot(
                    "Food" .. index,
                    foodStartX + step,
                    0,
                    MINECRAFT_BAR_EMPTY_FOOD,
                    MINECRAFT_BAR_FULL_FOOD
                )
                waterOverlays[index] = createStatusSlot(
                    "Water" .. index,
                    waterStartX + step,
                    waterY,
                    MINECRAFT_BAR_EMPTY_WATER,
                    MINECRAFT_BAR_FULL_WATER
                )
            end

            local function readVitalValue(statName)
                local vitalSigns = characterFrame:FindFirstChild("VitalSigns")
                local stat = vitalSigns and vitalSigns:FindFirstChild(statName)
                local numberLabel = stat and stat:FindFirstChild("Number")
                if numberLabel and numberLabel:IsA("TextLabel") then
                    -- Live values include units, e.g. "100/100 hp",
                    -- "1083/2000 cal" and "1869/3700 ml".
                    local currentText, maximumText = string.match(
                        numberLabel.Text,
                        "([%d%.]+)%s*/%s*([%d%.]+)"
                    )
                    local current = tonumber(currentText)
                    local maximum = tonumber(maximumText)
                    if current and maximum and maximum > 0 then
                        return current, maximum
                    end
                end
                return nil
            end

            local function getHealth()
                local current, maximum = readVitalValue("Health")
                if current then return current, maximum end

                local character = player.Character
                local humanoid = character and character:FindFirstChildOfClass("Humanoid")
                if humanoid then return humanoid.Health, humanoid.MaxHealth end
                return 100, 100
            end

            local function getSurvivalValue(statName)
                local current, maximum = readVitalValue(statName)
                if current then return current, maximum end
                return 100, 100
            end

            local function updateOverlays(overlays, current, maximum)
                maximum = math.max(maximum, 1)
                local points = (math.clamp(current, 0, maximum) / maximum) * 20
                for index, overlay in ipairs(overlays) do
                    local value = math.clamp(points - ((index - 1) * 2), 0, 2)
                    if value >= 2 then
                        overlay.ImageTransparency = 0
                    elseif value >= 1 then
                        overlay.ImageTransparency = 0.5
                    else
                        overlay.ImageTransparency = 1
                    end
                end
            end

            local function updateMinecraftBar()
                local health, maxHealth = getHealth()
                local hunger, maxHunger = getSurvivalValue("Hunger")
                local hydration, maxHydration = getSurvivalValue("Hydration")
                updateOverlays(heartOverlays, health, maxHealth)
                updateOverlays(foodOverlays, hunger, maxHunger)
                updateOverlays(waterOverlays, hydration, maxHydration)
            end

            connect(RunService.RenderStepped, updateMinecraftBar)
            connect(player.CharacterAdded, function()
                task.defer(updateMinecraftBar)
            end)
            updateMinecraftBar()
        end

        local function styleMinecraftSlot(slotFrame)
            if not slotFrame:IsA("Frame") then return end

            applyGeometry(slotFrame, LOOT_SLOT_LAYOUT.Root)
            for childName, geometry in pairs(LOOT_SLOT_LAYOUT) do
                if childName ~= "Root" then
                    applyGeometry(slotFrame:FindFirstChild(childName), geometry)
                end
            end

            slotFrame.BackgroundTransparency = 1

            local preImg = slotFrame:FindFirstChild("PreImageLabel")
            if preImg then preImg.Visible = false end

            local bg = slotFrame:FindFirstChild("CustomBG")
            if not bg then
                bg = Instance.new("ImageLabel")
                bg.Name = "CustomBG"
                bg.Parent = slotFrame
            end
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.Position = UDim2.new(0.5, 0, 0.5, 0)
            bg.AnchorPoint = Vector2.new(0.5, 0.5)
            bg.BackgroundTransparency = 1
            bg.Image = DEFAULT_ICON_TEXTURE
            bg.ZIndex = 1

            local img = slotFrame:FindFirstChild("ImageLabel")
            if img and img ~= bg then
                img.ZIndex = 3
            end

            local durability = slotFrame:FindFirstChild("Durability")
            if durability then
                local bar = durability:FindFirstChild("Bar") or durability:FindFirstChild("OriginalDurabilityBar")
                if bar then
                    bar.BackgroundColor3 = DURABILITY_BAR_COLOR
                    local gradient = bar:FindFirstChildOfClass("UIGradient")
                    if gradient then gradient:Destroy() end
                end
            end

            for _, child in ipairs(slotFrame:GetChildren()) do
                if child:IsA("TextLabel") then child.ZIndex = 4 end
                if child:IsA("UICorner") or child:IsA("UIStroke") then child:Destroy() end
            end

            makeSlotTextResponsive(slotFrame)
        end

        local function styleLootGearSlot(slotFrame)
            if not slotFrame:IsA("Frame") then return end

            for childName, geometry in pairs(LOOT_SLOT_LAYOUT) do
                if childName ~= "Root" then
                    applyGeometry(slotFrame:FindFirstChild(childName), geometry)
                end
            end

            slotFrame.BackgroundTransparency = 1
            slotFrame.ClipsDescendants = false

            local bg = slotFrame:FindFirstChild("CustomBG")
            if not bg then
                bg = Instance.new("ImageLabel")
                bg.Name = "CustomBG"
                bg.Parent = slotFrame
            end
            bg.Size = UDim2.new(1, 0, 1, 0)
            bg.Position = UDim2.new(0.5, 0, 0.5, 0)
            bg.AnchorPoint = Vector2.new(0.5, 0.5)
            bg.BackgroundTransparency = 1
            bg.BorderSizePixel = 0
            bg.Image = DEFAULT_ICON_TEXTURE
            bg.ZIndex = 1

            local slotType = slotFrame:FindFirstChild("SlotType")
            if slotType and slotType:IsA("GuiObject") then
                slotType.Visible = true
                slotType.ZIndex = 4
            end

            updateEquipmentPlaceholder(slotFrame)

            local preImg = slotFrame:FindFirstChild("PreImageLabel")
            if preImg and preImg:IsA("GuiObject") then
                preImg.ZIndex = 2
            end

            local img = slotFrame:FindFirstChild("ImageLabel")
            if img and img:IsA("ImageLabel") then
                img.Size = LOOT_SLOT_LAYOUT.ImageLabel.Size
                img.Position = LOOT_SLOT_LAYOUT.ImageLabel.Position
                img.AnchorPoint = LOOT_SLOT_LAYOUT.ImageLabel.Anchor
                img.ZIndex = 3
            end

            for _, child in ipairs(slotFrame:GetChildren()) do
                if child:IsA("TextLabel") then child.ZIndex = 5 end
                if child:IsA("UICorner") or child:IsA("UIStroke") then child:Destroy() end
            end

            makeSlotTextResponsive(slotFrame)
        end

        local function hideLootHeader(vicinityHeader)
            if vicinityHeader and vicinityHeader:IsA("GuiObject") then
                vicinityHeader.Visible = false

                if not headerVisibilityConnected[vicinityHeader] then
                    headerVisibilityConnected[vicinityHeader] = true
                    connect(vicinityHeader:GetPropertyChangedSignal("Visible"), function()
                        if vicinityHeader.Visible then vicinityHeader.Visible = false end
                    end)
                end
            end
        end

        local function styleMinecraftLoot(lootFrame)
            if not lootFrame or not lootFrame:IsA("GuiObject") then return end

            local lootDecor = lootFrame:FindFirstChild("Decor")
            if lootDecor then lootDecor:Destroy() end

            hideLootHeader(lootFrame:FindFirstChild("SwapButton"))

            if not lootChromeConnected[lootFrame] then
                lootChromeConnected[lootFrame] = true
                connect(lootFrame.ChildAdded, function(child)
                    if child.Name == "Decor" then
                        child:Destroy()
                    elseif child.Name == "SwapButton" and child:IsA("GuiObject") then
                        hideLootHeader(child)
                    end
                end)
            end

            lootFrame.Size = LOOT_LAYOUT.RootSize
            lootFrame.Position = LOOT_LAYOUT.RootPosition
            lootFrame.AnchorPoint = LOOT_LAYOUT.RootAnchor
            lootFrame.Visible = true
            lootFrame.BackgroundTransparency = 1
            local corner = lootFrame:FindFirstChildOfClass("UICorner")
            if corner then corner:Destroy() end
            local stroke = lootFrame:FindFirstChildOfClass("UIStroke")
            if stroke then stroke:Destroy() end

            local lootInventory = lootFrame:FindFirstChild("Inventory") or lootFrame:WaitForChild("Inventory", 5)
            local scrollingFrame = lootInventory and (lootInventory:FindFirstChild("ScrollingFrame") or lootInventory:WaitForChild("ScrollingFrame", 5))
            if not scrollingFrame then return end

            lootInventory.Size = LOOT_LAYOUT.InventorySize
            lootInventory.Position = LOOT_LAYOUT.InventoryPosition
            lootInventory.AnchorPoint = LOOT_LAYOUT.InventoryAnchor
            lootInventory.Visible = true

            scrollingFrame.Size = LOOT_LAYOUT.ScrollingSize
            scrollingFrame.Position = LOOT_LAYOUT.ScrollingPosition
            scrollingFrame.AnchorPoint = LOOT_LAYOUT.ScrollingAnchor
            scrollingFrame.ScrollBarThickness = LOOT_LAYOUT.ScrollBarThickness
            scrollingFrame.BackgroundColor3 = LOOT_SCROLL_BACKGROUND
            scrollingFrame.BackgroundTransparency = 1
            scrollingFrame.ScrollBarImageTransparency = 1
            scrollingFrame.Visible = false
            scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
            scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)

            -- Every Loot category has its own title (Container, Gear, Backpack, etc.).
            -- Minecraft-style loot uses one continuous grid, so remove all of them and
            -- also remove replacements made later by the game's pooling code.
            local function removeLootSlotTypes()
                for _, descendant in ipairs(scrollingFrame:GetDescendants()) do
                    if descendant.Name == "SlotType" and not isInsideLootGear(descendant, scrollingFrame) then
                        descendant:Destroy()
                    end
                end
            end
            removeLootSlotTypes()

            local REFERENCE_WIDTH = 689.181213
            local COLUMNS = LOOT_LAYOUT.Columns
            local MAX_CELL_SIZE = LOOT_LAYOUT.CellSize.X.Offset
            local updateQueued = false
            local updatingCanvas = false
            local connectedCategories = setmetatable({}, { __mode = "k" })
            local connectedInnerFrames = setmetatable({}, { __mode = "k" })
            local connectedGrids = setmetatable({}, { __mode = "k" })
            local connectedSlots = setmetatable({}, { __mode = "k" })
            local connectedGearObjects = setmetatable({}, { __mode = "k" })
            local characterGearSuppressed = false

            local applyCharacterGearSuppression
            applyCharacterGearSuppression = function(suppressed)
                characterGearSuppressed = suppressed

                local backpackFrame = lootFrame.Parent
                local characterFrame = backpackFrame and backpackFrame:FindFirstChild("CharacterFrame")
                local gear = characterFrame and characterFrame:FindFirstChild("Gear")
                if not gear then return end

                local enabled = not suppressed
                local function registerGearObject(guiObject)
                    if not guiObject or not guiObject:IsA("GuiObject") then return end

                    if guiObject.Visible ~= enabled then guiObject.Visible = enabled end
                    if guiObject.Active ~= enabled then guiObject.Active = enabled end

                    if not connectedGearObjects[guiObject] then
                        connectedGearObjects[guiObject] = true
                        connect(guiObject:GetPropertyChangedSignal("Visible"), function()
                            task.defer(function()
                                applyCharacterGearSuppression(characterGearSuppressed)
                            end)
                        end)
                        connect(guiObject:GetPropertyChangedSignal("Active"), function()
                            task.defer(function()
                                applyCharacterGearSuppression(characterGearSuppressed)
                            end)
                        end)
                    end
                end

                for _, slotName in ipairs(CHARACTER_GEAR_SLOT_NAMES) do
                    local slotFrame = gear:FindFirstChild(slotName)
                    if slotFrame and slotFrame:IsA("GuiObject") then
                        registerGearObject(slotFrame)
                    end
                end
            end

            local requestUpdate
            requestUpdate = function()
                if updateQueued then return end
                updateQueued = true

                task.defer(function()
                    updateQueued = false

                    lootFrame.Size = LOOT_LAYOUT.RootSize
                    lootFrame.Position = LOOT_LAYOUT.RootPosition
                    lootFrame.AnchorPoint = LOOT_LAYOUT.RootAnchor
                    lootFrame.Visible = true
                    lootInventory.Size = LOOT_LAYOUT.InventorySize
                    lootInventory.Position = LOOT_LAYOUT.InventoryPosition
                    lootInventory.AnchorPoint = LOOT_LAYOUT.InventoryAnchor
                    lootInventory.Visible = true
                    scrollingFrame.Size = LOOT_LAYOUT.ScrollingSize
                    scrollingFrame.Position = LOOT_LAYOUT.ScrollingPosition
                    scrollingFrame.AnchorPoint = LOOT_LAYOUT.ScrollingAnchor
                    scrollingFrame.ScrollBarThickness = LOOT_LAYOUT.ScrollBarThickness
                    scrollingFrame.BackgroundColor3 = LOOT_SCROLL_BACKGROUND

                    removeLootSlotTypes()

                    local availableWidth = scrollingFrame.AbsoluteSize.X
                    if availableWidth <= 0 then return end

                    local widthScale = math.clamp(availableWidth / REFERENCE_WIDTH, 0.35, 1)
                    local gap = math.clamp(math.floor((LOOT_LAYOUT.CellPadding.X.Offset * widthScale) + 0.5), 1, LOOT_LAYOUT.CellPadding.X.Offset)
                    local innerInset = math.max(0, math.floor((-LOOT_LAYOUT.InnerWidthOffset * widthScale) + 0.5))
                    local usableWidth = math.max(1, availableWidth - innerInset)
                    local cellSize = math.floor((usableWidth - (gap * (COLUMNS - 1))) / COLUMNS)
                    cellSize = math.clamp(cellSize, 32, MAX_CELL_SIZE)

                    local categories = {}
                    local lootOpen = false

                    for _, categoryFrame in ipairs(scrollingFrame:GetChildren()) do
                        if categoryFrame:IsA("Frame") then
                            local isGearCategory = categoryFrame.Name == "Gear"
                            local categoryTitle = categoryFrame:FindFirstChild("SlotType")
                            if categoryTitle then
                                if isGearCategory and categoryTitle:IsA("GuiObject") then
                                    categoryTitle.Visible = true
                                    categoryTitle.ZIndex = 5
                                else
                                    categoryTitle:Destroy()
                                end
                            end

                            local innerFrame = categoryFrame:FindFirstChild("Frame")
                            local grid = innerFrame and innerFrame:FindFirstChildOfClass("UIGridLayout")
                            if innerFrame and grid then
                                local categoryColumns = isGearCategory and LOOT_GEAR_COLUMNS or COLUMNS
                                local categoryMaxCellSize = isGearCategory and LOOT_GEAR_MAX_CELL_SIZE or MAX_CELL_SIZE
                                local categoryTopOffset = isGearCategory and LOOT_GEAR_TITLE_HEIGHT or 0
                                local categoryBottomGap = isGearCategory and LOOT_GEAR_BOTTOM_GAP or 0
                                local categoryCellSize = math.floor((usableWidth - (gap * (categoryColumns - 1))) / categoryColumns)
                                categoryCellSize = math.clamp(categoryCellSize, 32, categoryMaxCellSize)

                                categoryFrame.AutomaticSize = Enum.AutomaticSize.None
                                categoryFrame.AnchorPoint = LOOT_LAYOUT.ContainerAnchor
                                categoryFrame.Size = UDim2.new(1, 0, 0, 0)

                                innerFrame.AutomaticSize = Enum.AutomaticSize.None
                                innerFrame.AnchorPoint = LOOT_LAYOUT.InnerAnchor
                                innerFrame.Position = UDim2.new(LOOT_LAYOUT.InnerPosition.X.Scale, LOOT_LAYOUT.InnerPosition.X.Offset, 0, categoryTopOffset)
                                innerFrame.Size = UDim2.new(1, -innerInset, 0, 0)

                                grid.FillDirectionMaxCells = categoryColumns
                                grid.CellSize = UDim2.new(0, categoryCellSize, 0, categoryCellSize)
                                grid.CellPadding = UDim2.new(0, gap, 0, gap)
                                grid.FillDirection = Enum.FillDirection.Horizontal
                                grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
                                grid.VerticalAlignment = Enum.VerticalAlignment.Top

                                for _, slotFrame in ipairs(innerFrame:GetChildren()) do
                                    if slotFrame:IsA("Frame") then
                                        if isGearCategory then
                                            styleLootGearSlot(slotFrame)
                                        else
                                            styleMinecraftSlot(slotFrame)
                                        end

                                        if not connectedSlots[slotFrame] then
                                            connectedSlots[slotFrame] = true
                                            connect(slotFrame:GetPropertyChangedSignal("Visible"), requestUpdate)
                                        end
                                    end
                                end

                                if not connectedCategories[categoryFrame] then
                                    connectedCategories[categoryFrame] = true
                                    connect(categoryFrame:GetPropertyChangedSignal("Visible"), requestUpdate)
                                end
                                if not connectedInnerFrames[innerFrame] then
                                    connectedInnerFrames[innerFrame] = true
                                    connect(innerFrame.ChildAdded, requestUpdate)
                                    connect(innerFrame.ChildRemoved, requestUpdate)
                                end
                                if not connectedGrids[grid] then
                                    connectedGrids[grid] = true
                                    connect(grid:GetPropertyChangedSignal("AbsoluteContentSize"), requestUpdate)
                                end

                                table.insert(categories, {
                                    Frame = categoryFrame,
                                    Inner = innerFrame,
                                    Grid = grid,
                                    TopOffset = categoryTopOffset,
                                    BottomGap = categoryBottomGap,
                                })
                                if categoryFrame.Visible then lootOpen = true end
                            end
                        end
                    end

                    scrollingFrame.Visible = lootOpen
                    scrollingFrame.Active = lootOpen
                    scrollingFrame.ScrollingEnabled = lootOpen
                    scrollingFrame.BackgroundTransparency = lootOpen and 0 or 1
                    scrollingFrame.ScrollBarImageTransparency = lootOpen and 0 or 1
                    applyCharacterGearSuppression(lootOpen)

                    -- Let UIGridLayout publish the resized height, then stack whichever
                    -- Loot categories the game made visible and rebuild the canvas.
                    task.defer(function()
                        table.sort(categories, function(a, b)
                            if a.Frame.LayoutOrder == b.Frame.LayoutOrder then
                                return a.Frame.Name < b.Frame.Name
                            end
                            return a.Frame.LayoutOrder < b.Frame.LayoutOrder
                        end)

                        local totalY = 0
                        for _, category in ipairs(categories) do
                            local contentHeight = category.Grid.AbsoluteContentSize.Y + category.TopOffset + category.BottomGap
                            category.Inner.Size = UDim2.new(1, -innerInset, 0, contentHeight)
                            category.Frame.Size = UDim2.new(1, 0, 0, contentHeight)

                            if category.Frame.Visible then
                                category.Frame.Position = UDim2.new(0.5, 0, 0, totalY)
                                totalY += contentHeight
                            end
                        end

                        local savedCanvasSize = UDim2.new(0, 0, 0, totalY)
                        if scrollingFrame.CanvasSize ~= savedCanvasSize then
                            updatingCanvas = true
                            scrollingFrame.CanvasSize = savedCanvasSize
                            updatingCanvas = false
                        end
                    end)
                end)
            end

            connect(scrollingFrame.DescendantAdded, function(descendant)
                if descendant.Name == "SlotType" then
                    task.defer(function()
                        if descendant.Parent then descendant:Destroy() end
                    end)
                else
                    requestUpdate()
                end
            end)
            connect(scrollingFrame.DescendantRemoving, requestUpdate)
            connect(scrollingFrame:GetPropertyChangedSignal("AbsoluteSize"), requestUpdate)
            connect(scrollingFrame:GetPropertyChangedSignal("CanvasSize"), function()
                if not updatingCanvas then requestUpdate() end
            end)
            connect(scrollingFrame:GetPropertyChangedSignal("Visible"), requestUpdate)
            connect(lootFrame:GetPropertyChangedSignal("Visible"), requestUpdate)
            connect(scrollingFrame:GetPropertyChangedSignal("BackgroundTransparency"), function()
                local wantedTransparency = scrollingFrame.Visible and 0 or 1
                if scrollingFrame.BackgroundTransparency ~= wantedTransparency then
                    scrollingFrame.BackgroundTransparency = wantedTransparency
                end
            end)
            requestUpdate()
        end

        local function setupResponsiveInventory(scrollingFrame)
            local REFERENCE_WIDTH = 689.181213
            local COLUMNS = 9
            local MAX_CELL_SIZE = 72
            local updateQueued = false
            local connectedObjects = setmetatable({}, { __mode = "k" })

            local function requestUpdate()
                if updateQueued then return end
                updateQueued = true

                task.defer(function()
                    updateQueued = false

                    local availableWidth = scrollingFrame.AbsoluteSize.X
                    if availableWidth <= 0 then return end

                    local widthScale = math.clamp(availableWidth / REFERENCE_WIDTH, 0.35, 1)
                    local gap = math.clamp(math.floor((3 * widthScale) + 0.5), 1, 3)
                    local backpackInset = math.max(0, math.floor((16 * widthScale) + 0.5))
                    local categories = {}

                    for _, categoryFrame in ipairs(scrollingFrame:GetChildren()) do
                        if categoryFrame:IsA("Frame") then
                            local innerFrame = categoryFrame:FindFirstChild("Frame")
                            local grid = innerFrame and innerFrame:FindFirstChildOfClass("UIGridLayout")
                            if innerFrame and grid then
                                local leftInset = 0
                                local innerPadding = innerFrame:FindFirstChildOfClass("UIPadding")

                                if categoryFrame.Name == "ClothingBackpack" then
                                    if not innerPadding then
                                        innerPadding = Instance.new("UIPadding")
                                        innerPadding.Name = "UIPadding"
                                        innerPadding.Parent = innerFrame
                                    end
                                    innerPadding.PaddingLeft = UDim.new(0, backpackInset)
                                    leftInset = backpackInset

                                    local categoryPadding = categoryFrame:FindFirstChildOfClass("UIPadding")
                                    if categoryPadding then
                                        categoryPadding.PaddingTop = UDim.new(0, math.max(1, math.floor((5 * widthScale) + 0.5)))
                                    end
                                end

                                local usableWidth = math.max(1, innerFrame.AbsoluteSize.X - leftInset)
                                local cellSize = math.floor((usableWidth - (gap * (COLUMNS - 1))) / COLUMNS)
                                cellSize = math.clamp(cellSize, 32, MAX_CELL_SIZE)

                                grid.FillDirectionMaxCells = COLUMNS
                                grid.CellSize = UDim2.new(0, cellSize, 0, cellSize)
                                grid.CellPadding = UDim2.new(0, gap, 0, gap)
                                grid.FillDirection = Enum.FillDirection.Horizontal
                                grid.VerticalAlignment = Enum.VerticalAlignment.Top

                                categoryFrame.AutomaticSize = Enum.AutomaticSize.Y
                                innerFrame.AutomaticSize = Enum.AutomaticSize.Y
                                categoryFrame.Size = UDim2.new(1, 0, 0, 0)
                                innerFrame.Size = UDim2.new(1, 0, 0, 0)

                                for _, slotFrame in ipairs(innerFrame:GetChildren()) do
                                    if slotFrame:IsA("Frame") then
                                        makeSlotTextResponsive(slotFrame)
                                        if categoryFrame.Name == "Equipment" then
                                            updateEquipmentPlaceholder(slotFrame)
                                        end
                                    end
                                end

                                if not connectedObjects[grid] then
                                    connectedObjects[grid] = true
                                    connect(grid:GetPropertyChangedSignal("AbsoluteContentSize"), requestUpdate)
                                end
                                if not connectedObjects[categoryFrame] then
                                    connectedObjects[categoryFrame] = true
                                    connect(categoryFrame:GetPropertyChangedSignal("Visible"), requestUpdate)
                                    if categoryFrame.Name == "ClothingBackpack" then
                                        -- The game restores its default X position when
                                        -- Inventory opens; immediately pin the user's
                                        -- saved placement again whenever that happens.
                                        connect(categoryFrame:GetPropertyChangedSignal("Position"), requestUpdate)
                                    end
                                end
                                table.insert(categories, categoryFrame)
                            end
                        end
                    end

                    -- Wait for UIGridLayout/AutomaticSize to publish their new heights,
                    -- then stack sections and size the canvas from their real bounds.
                    task.defer(function()
                        table.sort(categories, function(a, b)
                            if a.LayoutOrder == b.LayoutOrder then return a.Name < b.Name end
                            return a.LayoutOrder < b.LayoutOrder
                        end)

                        local totalY = 0
                        for _, categoryFrame in ipairs(categories) do
                            if categoryFrame.Visible then
                                categoryFrame.AnchorPoint = Vector2.new(0.5, 0)
                                if categoryFrame.Name == "ClothingBackpack" then
                                    -- Keep the user's horizontal alignment, but derive
                                    -- Y from the sections above it. A fixed Y=90 made
                                    -- Backpack overlap Shirt/Pants and also excluded its
                                    -- lower rows from the scrolling canvas.
                                    categoryFrame.Position = UDim2.new(
                                        INVENTORY_BACKPACK_X.Scale,
                                        INVENTORY_BACKPACK_X.Offset,
                                        0,
                                        totalY
                                    )
                                    totalY += categoryFrame.AbsoluteSize.Y
                                else
                                    categoryFrame.Position = UDim2.new(0.5, 0, 0, totalY)
                                    totalY += categoryFrame.AbsoluteSize.Y
                                end
                            end
                        end

                        local bottomPadding = math.max(5, math.floor((20 * widthScale) + 0.5))
                        scrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.None
                        scrollingFrame.CanvasSize = UDim2.new(0, 0, 0, totalY + bottomPadding)
                    end)
                end)
            end

            connect(scrollingFrame:GetPropertyChangedSignal("AbsoluteSize"), requestUpdate)
            connect(scrollingFrame:GetPropertyChangedSignal("Visible"), requestUpdate)
            connect(scrollingFrame.DescendantAdded, requestUpdate)
            connect(scrollingFrame.DescendantRemoving, requestUpdate)
            requestUpdate()
        end

        -- Exact Slot Config (Taken directly from your latest log)
        local SLOT_DATA = {
            ["ClothingChestRig"] = { Pos = UDim2.new(0.0900000036, 0, 0.111000001, 0), Anchor = Vector2.new(0.5, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = false, DuraVisible = true, BarSize = UDim2.new(0.760833323, 0, 2, 0) },
            ["ClothingShirt"] = { Pos = UDim2.new(0.800000012, 0, 0.0680000037, 0), Anchor = Vector2.new(0.5, 0), FrameSize = UDim2.new(0.0850000009, 0, 0.0850000009, 0), SlotSize = UDim2.new(0.269999981, 0), SlotVisible = true, SlotColor = Color3.new(0, 0, 0), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = false, DuraVisible = false, BarSize = UDim2.new(0.783333361, 0, 2, 0) },
            ["ClothingPants"] = { Pos = UDim2.new(0.800000012, 0, 0.215000004, 0), Anchor = Vector2.new(0.5, 0), FrameSize = UDim2.new(0.0850000009, 0, 0.0850000009, 0), SlotSize = UDim2.new(0.269999981, 0), SlotVisible = true, SlotColor = Color3.new(0, 0, 0), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = false, DuraVisible = false, BarSize = UDim2.new(0.783333361, 0, 2, 0) },
            ["ItemBack2"] = { Pos = UDim2.new(0.524999976, 0, 0.187999994, 0), Anchor = Vector2.new(1, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = true, ItemVisible = false, AmountVisible = true, HotVisible = false, DuraVisible = false, BarSize = UDim2.new(0.783333361, 0, 2, 0) },
            ["ClothingLegArmor"] = { Pos = UDim2.new(0.131999999, 0, 0.187000006, 0), Anchor = Vector2.new(1, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = false, DuraVisible = true, BarSize = UDim2.new(0.99000001, 0, 2, 0) },
            ["ItemHip1"] = { Pos = UDim2.new(0.526000023, 0, 0.0355000012, 0), Anchor = Vector2.new(1, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = true, HotVisible = true, DuraVisible = true, BarSize = UDim2.new(0.899999976, 0, 2, 0) },
            ["ItemBack1"] = { Pos = UDim2.new(0.439999998, 0, 0.109999999, 0), Anchor = Vector2.new(0, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = true, HotVisible = true, DuraVisible = true, BarSize = UDim2.new(0.643333316, 0, 2, 0) },
            ["Melee"] = { Pos = UDim2.new(0.437999994, 0, 0.263000011, 0), Anchor = Vector2.new(0, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = true, DuraVisible = false, BarSize = UDim2.new(0.783333361, 0, 2, 0) },
            ["ClothingBackpack"] = { Pos = UDim2.new(0.537999988, 0, 0.263000011, 0), Anchor = Vector2.new(0, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = false, DuraVisible = false, BarSize = UDim2.new(0.783333361, 0, 2, 0) },
            ["ClothingHeadware"] = { Pos = UDim2.new(0.0900000036, 0, 0.0350000001, 0), Anchor = Vector2.new(0.5, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = false, DuraVisible = true, BarSize = UDim2.new(0.808333337, 0, 2, 0) },
            ["ClothingGloves"] = { Pos = UDim2.new(0.0460000001, 0, 0.264999986, 0), Anchor = Vector2.new(0, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = false, DuraVisible = false, BarSize = UDim2.new(0.783333361, 0, 2, 0) },
            ["ClothingMask"] = { Pos = UDim2.new(0.625, 0, 0.1875, 0), Anchor = Vector2.new(1, 0), SlotSize = UDim2.new(0.170000002, 0), SlotVisible = false, SlotColor = Color3.new(1, 1, 1), PreVisible = false, ItemVisible = true, AmountVisible = false, HotVisible = false, DuraVisible = false, BarSize = UDim2.new(0.783333361, 0, 2, 0) },
        }

        local DUR_BASE = {
            DuraSize = UDim2.new(1, 0, 0.0399999991, 0),
            DuraPos = UDim2.new(0.5, 0, 1, 0),
            DuraAnchor = Vector2.new(0.5, 1),
            DuraBg = Color3.fromRGB(49, 49, 49),
            BarPos = UDim2.new(0, 0, 0.5, 0),
            BarAnchor = Vector2.new(0, 0.5),
            BarBg = Color3.new(0, 1.01176, 0),
            OrigBarSize = UDim2.new(0, 0, 2, 0),
            OrigBarPos = UDim2.new(1, 0, 0.5, 0),
            OrigBarAnchor = Vector2.new(1, 0.5),
            OrigBarBg = Color3.fromRGB(197, 60, 62)
        }

        local function applyExactState()
            local backpackFrame = mainFrame:FindFirstChild("BackpackFrame")
            if not backpackFrame then return end

            -- ================== CharacterFrame ==================
            local characterFrame = backpackFrame:FindFirstChild("CharacterFrame")
            if not characterFrame then return end
            local inventoryFrame = backpackFrame:FindFirstChild("InventoryFrame")

            -- Keep the original data-bearing panels alive for other scripts (such as
            -- the Minecraft health/food/water bar), but never render them here.
            setupHiddenCharacterPanels(characterFrame)
            local swapButton = characterFrame:FindFirstChild("SwapButton")
            if swapButton then swapButton:Destroy() end

            characterFrame.Size = UDim2.new(0.850000024, 0, 0.600000024, 0)
            characterFrame.Position = UDim2.new(0.5, 0, 0.141000003, 0)
            characterFrame.BackgroundTransparency = 0.05
            characterFrame.BackgroundColor3 = Color3.fromRGB(49, 49, 49)
            characterFrame.Visible = true

            if inventoryFrame then
                -- Capture the baseline after CharacterFrame receives its final layout.
                -- This keeps the user's saved inventory/loot sizes at 1:1 on startup.
                task.defer(function()
                    linkInventoryScale(
                        characterFrame,
                        inventoryFrame,
                        backpackFrame,
                        characterFrame.AbsoluteSize,
                        backpackFrame.AbsoluteSize
                    )
                end)
            end

            local function setupLoot(lootFrame)
                if lootFrame.Name ~= "Loot" or not lootFrame:IsA("GuiObject") then return end

                task.defer(function()
                    styleMinecraftLoot(lootFrame)
                    linkInventoryScale(
                        characterFrame,
                        lootFrame,
                        backpackFrame,
                        characterFrame.AbsoluteSize,
                        backpackFrame.AbsoluteSize
                    )
                end)
            end

            local currentLoot = backpackFrame:FindFirstChild("Loot")
            if currentLoot then
                setupLoot(currentLoot)
            end

            connect(backpackFrame.ChildAdded, function(child)
                setupLoot(child)
            end)

            local gear = characterFrame:FindFirstChild("Gear")
            if not gear then
                gear = Instance.new("Frame")
                gear.Name = "Gear"
                gear.Parent = characterFrame
            end
            gear.Size = UDim2.new(1.00000024, 0, 1.90999997, 0)
            gear.Position = UDim2.new(0, 0, -0.100000001, 0)
            gear.BackgroundTransparency = 1
            gear.Visible = true

            local decor = characterFrame:FindFirstChild("Decor")
            if not decor then
                decor = Instance.new("ImageLabel")
                decor.Name = "Decor"
                decor.Parent = gear
            else
                decor.Parent = gear
            end
            decor.Image = DECOR_ID
            decor.ImageTransparency = 0
            decor.ImageColor3 = Color3.new(1, 1, 1)
            decor.ScaleType = Enum.ScaleType.Stretch
            decor.SliceCenter = Rect.new(0, 0, 0, 0)
            decor.Size = UDim2.new(1, 0, 0.600000024, 0)
            decor.Position = UDim2.new(0.5, 0, 0.300000012, 0)
            decor.AnchorPoint = Vector2.new(0.5, 0.5)
            decor.BackgroundTransparency = 1
            decor.Visible = true

            local apparance = characterFrame:FindFirstChild("Apparance")
            if apparance then
                apparance.Size = UDim2.new(1, 0, 0.610000014, 0)
                apparance.Position = UDim2.new(0, 0, 0, 0)
                apparance.BackgroundTransparency = 1
                apparance.BorderSizePixel = 1
                apparance.BorderColor3 = Color3.fromRGB(27, 42, 53)

                apparance.Visible = true

                local viewport = apparance:FindFirstChildOfClass("ViewportFrame")
                if viewport then
                    viewport.Size = UDim2.new(0.280000001, 0, 0.899999976, 0)
                    viewport.Position = UDim2.new(0.286000013, 0, -0.0199999996, 0)
                    viewport.AnchorPoint = Vector2.new(0.5, 0)
                    viewport.BackgroundTransparency = 1
                    viewport.BorderSizePixel = 0
                    viewport.Visible = true
                    viewport.BackgroundColor3 = Color3.fromRGB(49, 49, 49)

                    local cam = viewport:FindFirstChildOfClass("Camera")
                    if not cam then
                        cam = Instance.new("Camera")
                        cam.Parent = viewport
                    end
                    viewport.CurrentCamera = cam
                    cam.CFrame = CFrame.new(-130.565933, 16.8358727, -408.240936, 0.0524330698, -0.156219169, 0.986329734, 2.47008369e-08, 0.987688363, 0.156434357, -0.998624444, -0.00820230972, 0.0517875366)

                    local previewModelName = player.Name
                    if not viewport:FindFirstChild(previewModelName) then
                        local char = player.Character or player.CharacterAdded:Wait()
                        local modelClone = char:Clone()
                        modelClone.Name = previewModelName
                        modelClone.Parent = viewport
                        local humanoid = modelClone:FindFirstChildOfClass("Humanoid")
                        if humanoid then humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None end
                        local root = modelClone:FindFirstChild("HumanoidRootPart")
                        if root then root.Anchored = true end

                        -- PERF: this preview costs a few ms of frame time because it
                        -- renders a second live copy of the character. Nothing in it
                        -- needs to be simulated, animated or emit effects, so strip
                        -- everything that makes the clone do per-frame work while
                        -- keeping its appearance for the preview.
                        for _, part in ipairs(modelClone:GetDescendants()) do
                            if part:IsA("BasePart") then
                                part.Anchored = true
                                part.CanCollide = false
                                part.CanTouch = false
                                part.CanQuery = false
                            elseif part:IsA("Animator") or part:IsA("AnimationController") then
                                pcall(function() part:Destroy() end)
                            elseif part:IsA("Light") or part:IsA("ParticleEmitter") or part:IsA("Trail")
                                or part:IsA("Beam") or part:IsA("Fire") or part:IsA("Smoke")
                                or part:IsA("Sparkles") or part:IsA("Sound") or part:IsA("Decal") then
                                pcall(function() part:Destroy() end)
                            end
                        end
                    end
                end
            end

            for slotName, data in pairs(SLOT_DATA) do
                local slot = gear:FindFirstChild(slotName)
                if slot then
                    pcall(function()
                        slot.Size = data.FrameSize or UDim2.new(0.064000003, 0, 0.064000003, 0)
                        slot.Position = data.Pos
                        slot.AnchorPoint = data.Anchor
                        -- The game owns every child state (icon, placeholder, name,
                        -- hotkey, click target and durability). Only make the slot's
                        -- own solid background transparent.
                        styleGearSlot(slot)
                    end)
                end
            end

            -- Cover every current and future usable slot directly inside Gear, even
            -- if the game adds a slot name that is not present in SLOT_DATA.
            for _, gearChild in ipairs(gear:GetChildren()) do
                styleGearSlot(gearChild)
            end
            connect(gear.ChildAdded, function(gearChild)
                task.defer(function()
                    if gearChild.Parent == gear then styleGearSlot(gearChild) end
                end)
            end)
            connect(gear.DescendantAdded, function(descendant)
                task.defer(function()
                    local directGearChild = descendant
                    while directGearChild.Parent and directGearChild.Parent ~= gear do
                        directGearChild = directGearChild.Parent
                    end
                    if directGearChild.Parent == gear then styleGearSlot(directGearChild) end
                end)
            end)

            -- ================== InventoryFrame ==================
            if inventoryFrame then
                -- Remove top-level UICorner and UIStroke
                local uiCorner = inventoryFrame:FindFirstChild("UICorner")
                if uiCorner then uiCorner:Destroy() end
                local uiStroke = inventoryFrame:FindFirstChild("UIStroke")
                if uiStroke then uiStroke:Destroy() end

                -- Hide SwapButton
                local swapButtonInv = inventoryFrame:FindFirstChild("SwapButton")
                if swapButtonInv then swapButtonInv.Visible = false end

                -- Delete Decor
                local decorInv = inventoryFrame:FindFirstChild("Decor")
                if decorInv then decorInv:Destroy() end

                -- Set background transparency
                inventoryFrame.BackgroundTransparency = 1

                -- Resize & reposition ScrollingFrame
                local inventory = inventoryFrame:FindFirstChild("Inventory")
                if inventory then
                    local scrollingFrame = inventory:FindFirstChild("ScrollingFrame")
                    if scrollingFrame then
                        scrollingFrame.Size = UDim2.new(1.51, 0, 0.34, 0)
                        scrollingFrame.Position = UDim2.new(1.085, 0, 0.572, 0)
                        scrollingFrame.CanvasSize = UDim2.new(0, 0, 1, 0)
                        scrollingFrame.CanvasPosition = Vector2.new(0, 0)

                        for _, categoryFrame in pairs(scrollingFrame:GetChildren()) do
                            if categoryFrame:IsA("Frame") then
                                -- Only show the "EQUIPMENT" label, hide all others
                                local slotType = categoryFrame:FindFirstChild("SlotType")
                                if slotType then
                                    slotType.Visible = (categoryFrame.Name == "Equipment")
                                end

                                -- Add a visual separator gap above the Backpack section
                                if categoryFrame.Name == "ClothingBackpack" then
                                    local pad = categoryFrame:FindFirstChild("UIPadding") or Instance.new("UIPadding")
                                    pad.Name = "UIPadding"
                                    pad.Parent = categoryFrame
                                    pad.PaddingTop = UDim.new(0, 5) -- Small gap
                                end

                                local innerFrame = categoryFrame:FindFirstChild("Frame")
                                if innerFrame then
                                    -- Use AutomaticSize to prevent rows from squishing/overlapping
                                    categoryFrame.AutomaticSize = Enum.AutomaticSize.Y
                                    innerFrame.AutomaticSize = Enum.AutomaticSize.Y
                                    categoryFrame.Size = UDim2.new(1, 0, 0, 0)
                                    innerFrame.Size = UDim2.new(1, 0, 0, 0)

                                    local grid = innerFrame:FindFirstChildOfClass("UIGridLayout")
                                    if grid then
                                        grid.FillDirectionMaxCells = 9
                                        grid.CellSize = UDim2.new(0, 72, 0, 72)
                                        grid.CellPadding = UDim2.new(0, 3, 0, 3)
                                        grid.FillDirection = Enum.FillDirection.Horizontal
                                        grid.VerticalAlignment = Enum.VerticalAlignment.Top

                                        if categoryFrame.Name == "ClothingBackpack" then
                                            grid.HorizontalAlignment = Enum.HorizontalAlignment.Center
                                            local ipad = innerFrame:FindFirstChild("UIPadding") or Instance.new("UIPadding")
                                            ipad.Name = "UIPadding"
                                            ipad.Parent = innerFrame
                                            ipad.PaddingLeft = UDim.new(0, 16)
                                        else
                                            grid.HorizontalAlignment = Enum.HorizontalAlignment.Left
                                        end
                                    end

                                    for _, slotFrame in pairs(innerFrame:GetChildren()) do
                                        if slotFrame:IsA("Frame") then
                                            slotFrame.BackgroundTransparency = 1

                                            local preImg = slotFrame:FindFirstChild("PreImageLabel")
                                            if categoryFrame.Name == "Equipment" then
                                                updateEquipmentPlaceholder(slotFrame)
                                            elseif preImg then
                                                preImg.Visible = false
                                            end

                                            local bg = slotFrame:FindFirstChild("CustomBG")
                                            if not bg then
                                                bg = Instance.new("ImageLabel")
                                                bg.Name = "CustomBG"
                                                bg.Parent = slotFrame
                                            end
                                            bg.Size = UDim2.new(1, 0, 1, 0)
                                            bg.Position = UDim2.new(0.5, 0, 0.5, 0)
                                            bg.AnchorPoint = Vector2.new(0.5, 0.5)
                                            bg.BackgroundTransparency = 1
                                            bg.Image = DEFAULT_ICON_TEXTURE
                                            bg.ZIndex = 1

                                            local img = slotFrame:FindFirstChild("ImageLabel")
                                            if img then
                                                -- Shrink item icons slightly
                                                img.Size = UDim2.new(0.85, 0, 0.85, 0)
                                                img.Position = UDim2.new(0.5, 0, 0.5, 0)
                                                img.AnchorPoint = Vector2.new(0.5, 0.5)
                                                img.ZIndex = 3
                                            end

                                            local dur = slotFrame:FindFirstChild("Durability")
                                            if dur then
                                                local bar = dur:FindFirstChild("Bar") or dur:FindFirstChild("OriginalDurabilityBar")
                                                if bar then
                                                    -- Make durability bar green like character box
                                                    bar.BackgroundColor3 = DURABILITY_BAR_COLOR
                                                    -- Remove UIGradient if it exists so the green shows purely
                                                    local grad = bar:FindFirstChildOfClass("UIGradient")
                                                    if grad then grad:Destroy() end
                                                end
                                            end

                                            for _, child in ipairs(slotFrame:GetChildren()) do
                                                if child:IsA("TextLabel") then child.ZIndex = 4 end
                                                if child:IsA("UICorner") or child:IsA("UIStroke") then child:Destroy() end
                                            end
                                        end
                                    end
                                end
                            end
                        end

                        setupResponsiveInventory(scrollingFrame)
                    end
                end
            end

            -- Character gear, player inventory, containers, corpses and future pooled
            -- slots all live below BackpackFrame. Style every durability instance and
            -- keep watching for replacements created when the inventory is reopened.
            setupGlobalDurabilityStyle(backpackFrame)
            setupHotbar(mainFrame)
            setupMinecraftBar(mainFrame, characterFrame)
        end

        local minecraftTab = ui.box.object_esp:AddTab("Minecraft")
        minecraftTab:AddToggle("minecraft_ui", {
            Text = "Minecraft",
            Default = false,
            Callback = function(state)
                if state then
                    applyExactState()
                    print("\u{2705} CharacterFrame + InventoryFrame fully replicated \u{2013} weapon icons visible, empty slots show custom texture.")
                else
                    local env = runtimeEnvironment
                    local conns = env and env[CONNECTIONS_KEY]
                    if type(conns) == "table" then
                        for _, connection in ipairs(conns) do
                            pcall(function() connection:Disconnect() end)
                        end
                        env[CONNECTIONS_KEY] = {}
                    end
                    local bar = playerGui:FindFirstChild("MinecraftBar")
                    if bar then bar:Destroy() end
                end
            end,
        })
        end
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        -- Radar system (ported from ghost)
        local radarKillFunction = nil
        local radarDrawObjects = {}

        local function rememberRadarDrawingObject(object)
            if object then
                table.insert(radarDrawObjects, object)
            end
            return object
        end

        local function cleanupPlayerRadar()
            if radarKillFunction then
                pcall(radarKillFunction)
            end

            local globalRadarKill = _G.RadarKill
            if globalRadarKill and globalRadarKill ~= radarKillFunction then
                pcall(globalRadarKill)
            end

            for _, object in ipairs(radarDrawObjects) do
                pcall(function()
                    object.Visible = false
                    if object.Remove then
                        object:Remove()
                    end
                end)
            end

            radarKillFunction = nil
            radarDrawObjects = {}
            _G.RadarKill = nil
            if _G.GhostRadarRememberDrawing == rememberRadarDrawingObject then
                _G.GhostRadarRememberDrawing = nil
            end
        end

        local function setPlayerRadarEnabled(enabled)
            if enabled then
                cleanupPlayerRadar()

                _G.RadarSettings = {
                    RADAR_LINES = true,
                    RADAR_LINE_DISTANCE = 50,
                    RADAR_SCALE = 1,
                    RADAR_RADIUS = 125,
                    RADAR_ROTATION = true,
                    SMOOTH_ROT = true,
                    SMOOTH_ROT_AMNT = 30,
                    CARDINAL_DISPLAY = true,
                    DISPLAY_OFFSCREEN = true,
                    DISPLAY_TEAMMATES = true,
                    DISPLAY_TEAM_COLORS = true,
                    DISPLAY_FRIEND_COLORS = true,
                    DISPLAY_RGB_COLORS = false,
                    MARKER_SCALE_BASE = 1.25,
                    MARKER_SCALE_MAX = 1.25,
                    MARKER_SCALE_MIN = 0.75,
                    MARKER_FALLOFF = true,
                    MARKER_FALLOFF_AMNT = 125,
                    OFFSCREEN_TRANSPARENCY = 0.3,
                    USE_FALLBACK = false,
                    USE_QUADS = true,
                    USE_TEAM_COLORS = false,
                    VISIBLITY_CHECK = false,
                    RADAR_THEME = {
                        Outline = Color3.fromRGB(35, 35, 45),
                        Background = Color3.fromRGB(25, 25, 35),
                        DragHandle = Color3.fromRGB(50, 50, 255),
                        Cardinal_Lines = Color3.fromRGB(110, 110, 120),
                        Distance_Lines = Color3.fromRGB(65, 65, 75),
                        Generic_Marker = Color3.fromRGB(255, 25, 115),
                        Local_Marker = Color3.fromRGB(115, 25, 255),
                        Team_Marker = Color3.fromRGB(25, 115, 255),
                        Friend_Marker = Color3.fromRGB(25, 255, 115),
                    },
                }

                local radarSource = nil
                local fetched, fetchErr = pcall(function()
                    radarSource = game:HttpGet("https://raw.githubusercontent.com/kristerstomasuns-hub/essentials/main/radar?v=autoloadfix-20260719", true)
                end)
                if not fetched or not radarSource or radarSource == "" then
                    cleanupPlayerRadar()
                    notify("Radar", "Failed to load radar: " .. tostring(fetchErr or "empty source"), 4)
                    return
                end

                _G.GhostRadarRememberDrawing = rememberRadarDrawingObject
                radarSource = radarSource:gsub(
                    "local obj = Drawing%.new%(objectClass%)",
                    "local obj = Drawing.new(objectClass)\n    if _G.GhostRadarRememberDrawing then pcall(_G.GhostRadarRememberDrawing, obj) end"
                )
                radarSource = radarSource:gsub(
                    "local notif = Drawing%.new%('Text'%)",
                    "local notif = Drawing.new('Text')\n    if _G.GhostRadarRememberDrawing then pcall(_G.GhostRadarRememberDrawing, notif) end"
                )

                local ok, err = pcall(function()
                    loadstring(radarSource)()
                end)

                if not ok then
                    cleanupPlayerRadar()
                    notify("Radar", "Failed to load radar: " .. tostring(err), 4)
                    return
                end

                radarKillFunction = _G.RadarKill
            else
                cleanupPlayerRadar()
            end
        end

        local WorldTab = ui.box.world:AddTab("Environment")
        local gradientcolor1 = Color3.fromRGB(90, 90, 90)
        local gradientcolor2 = Color3.fromRGB(150, 150, 150)
        local oldgradient1 = Lighting.Ambient
        local oldgradient2 = Lighting.OutdoorAmbient
        local oldTime = mathround(Lighting.ClockTime)
        local nofog = false
        local visuals_BloomInstance = Lighting:FindFirstChildOfClass("BloomEffect")
        local visuals_BloomIntensity = 0
        local visuals_BloomSize = 17
        local visuals_BloomThreshold = 0.9
        local visuals_BloomEnabled = false
        -- Ported from pin.reta V2 ("teleport vehicle next to me"), made generic:
        -- instead of hard-coding the UAZ chassis it grabs the nearest model that has a
        -- VehicleSeat. Sits you in it, then pivots the whole vehicle to where you stood.
        WorldTab:AddButton('Teleport Vehicle To Me', function()
            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not (hrp and hum) then return end
        
            local best_model, best_seat, best_dist = nil, nil, math.huge
            local containers = {}
            local vroot = workspace:FindFirstChild("Vehicles")
            if vroot then table.insert(containers, vroot) end
            table.insert(containers, workspace)
            for _, container in ipairs(containers) do
                for _, v in ipairs(container:GetChildren()) do
                    if v:IsA("Model") then
                        local seat = v:FindFirstChild("VehicleSeat", true)
                        if seat then
                            local d = (seat.Position - hrp.Position).Magnitude
                            if d < best_dist then
                                best_dist, best_model, best_seat = d, v, seat
                            end
                        end
                    end
                end
            end
        
            if not (best_model and best_seat) then
                cheat.Library:Notify("TP Car", "No vehicle with a VehicleSeat found.")
                return
            end
        
            local old_cf = hrp.CFrame
            hrp.CFrame = best_seat.CFrame * CFrame.new(0, 1, 0)
            task.wait(0.1)
            pcall(function() best_seat:Sit(hum) end)
            task.spawn(function()
                local seated = false
                for _ = 1, 50 do
                    if hum.SeatPart == best_seat then seated = true break end
                    task.wait(0.05)
                end
                if seated then
                    task.wait(0.2)
                    pcall(function() best_model:PivotTo(old_cf * CFrame.new(0, 3, 0)) end)
                    for _, part in ipairs(best_model:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.AssemblyLinearVelocity = Vector3.zero
                            part.AssemblyAngularVelocity = Vector3.zero
                        end
                    end
                    cheat.Library:Notify("TP Car", "Teleported " .. best_model.Name)
                else
                    hrp.CFrame = old_cf
                    cheat.Library:Notify("TP Car", "Seating failed -- check for a VehicleSeat.")
                end
            end)
        end)
        
        WorldTab:AddToggle('enabletimechanger', {Text = 'Time Changer',Default = false,Callback = function(first)
            globals.EnableTime = first
        end})
        WorldTab:AddSlider('timechanger',{ Text = 'Time', Default = math.max(1, oldTime), Min = 1, Max = 24, Rounding = 1, Compact = false }):OnChanged(function(State)
            globals.Time = State
        end)
        WorldTab:AddToggle('ambientswitch', {Text = 'Ambient Changer',Default = false,Callback = function(first)
            globals.gradientenabled = first
        end}):AddColorPicker('ambientcolor', {Default = Color3.new(1, 1, 1),Title = 'Ambient Color 1',Transparency = 0,Callback = function(Value)
            gradientcolor1 = Value
        end}):AddColorPicker('ambientcolor1',{Default = Color3.new(1, 1, 1),Title = 'Ambient Color 2',Transparency = 0,Callback = function(Value)
            gradientcolor2 = Value
        end})
        WorldTab:AddToggle('fogswitch', {
            Text = 'No Fog',
            Default = false,
            Callback = function(first)
                nofog = first
            end
        })
        local xray_enabled = false
        local xray_active = false
        local xray_original_transparency = setmetatable({}, { __mode = "k" })
        local function is_xray_part(part)
            if not (part and part:IsA("BasePart")) then return false end
            local parent = part.Parent
            if parent and parent:FindFirstChildOfClass("Humanoid") then return false end
            local character = LocalPlayer.Character
            if character and part:IsDescendantOf(character) then return false end
            return true
        end
        local function set_xray_transparency(active)
            active = active and true or false
            if xray_active == active then return end
            xray_active = active

            if active then
                local origin = Camera.CFrame.Position
                task.spawn(function()
                    local processed = 0
                    local stack = {workspace}
                    while #stack > 0 do
                        local parent = table.remove(stack)
                        for _, object in ipairs(parent:GetChildren()) do
                            stack[#stack + 1] = object
                        if not xray_active then return end
                        if is_xray_part(object) and (origin - object.Position).Magnitude <= 500 and object.Transparency == 0 then
                            xray_original_transparency[object] = object.Transparency
                            object.Transparency = 0.5
                        end
                        processed = processed + 1
                        if processed % 150 == 0 then
                            task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                        end
                    end
                    end
                end)
            else
                for part, original in pairs(xray_original_transparency) do
                    if part and part.Parent and part.Transparency == 0.5 then
                        part.Transparency = original
                    end
                    xray_original_transparency[part] = nil
                end
            end
        end
        local function xray_key_active()
            local option = cheat.Options and cheat.Options.xray_bind
            if not option then return false end
            -- Live element first: a config restore updates the element but skips the
            -- keyCallback, so the cached copy would still read the creation defaults.
            local value = option.Value
            if option._raw and option._raw.get_value then
                local okLive, live = pcall(function() return option._raw:get_value() end)
                if okLive and type(live) == "table" then
                    value = live
                    option.Value = live
                end
            end
            local key = option.Key
            local mode = option.Mode
            local active = option.State
            if type(value) == "table" then
                key = value.Key or key
                mode = value.Type or value.Mode or mode
                if value.Active ~= nil then
                    active = value.Active
                end
            end
            key = tostring(key or "None")
            if key == "" or key == "None" or key == "NONE" then
                return false
            end
            if mode == "Always" then return true end
            -- Hold binds read the physical key; the library's Active flag can report
            -- "held" straight after a config load, which made Xray switch on by itself.
            if mode == "Hold" then
                local ok, enumKey = pcall(function() return Enum.KeyCode[key] end)
                if ok and enumKey then
                    local down = false
                    pcall(function() down = UserInputService:IsKeyDown(enumKey) end)
                    return down == true or active == true
                end
            end
            return active == true
        end
        WorldTab:AddToggle('xray_enabled', {Text = 'Xray', Default = false, Callback = function(v)
            xray_enabled = v
            set_xray_transparency(xray_enabled and xray_key_active())
        end}):AddKeyPicker('xray_bind', {Default = 'None', SyncToggleState = false, Mode = 'Hold', Text = 'Xray', NoUI = false, Callback = function()
            set_xray_transparency(xray_enabled and xray_key_active())
        end})
        cheat.utility.track_connection(workspace.DescendantAdded:Connect(function(object)
            if not (xray_enabled and xray_active and is_xray_part(object)) then return end
            task.defer(function()
                if xray_enabled and xray_active and is_xray_part(object) and object.Transparency == 0 and (Camera.CFrame.Position - object.Position).Magnitude <= 500 then
                    xray_original_transparency[object] = object.Transparency
                    object.Transparency = 0.5
                end
            end)
        end))
       local no_landmines = false
local landmine_connections = {}
local landmine_workspace_connection = nil
local landmine_aizones_connection = nil
local landmine_folder_names = {
    Landmines = true,
    Claymores = true,
    OutpostLandmines = true,
    BridgeClaymines = true,
    HeliCrashClaymores = true,
    ShipWreckClaymores = true,
}
local function is_landmine_object(object)
    return object and object:IsA("Model") and (object.Name == "PMN2" or object.Name == "MON50" or object.Name == "GrenadeTrap" or object.Name == "Grenade_Trap")
end
local function remove_landmine(object)
    if is_landmine_object(object) then
        pcall(function()
            object:Destroy()
        end)
    end
end
local function remove_landmine_later(object)
    if not is_landmine_object(object) then return end
    task.delay(2.5, function()
        if no_landmines then
            remove_landmine(object)
        end
    end)
end
local function watch_landmine_folder(folder)
    if not folder or landmine_connections[folder] then return end
    for _, object in ipairs(folder:GetChildren()) do
        remove_landmine(object)
    end
    landmine_connections[folder] = cheat.utility.track_connection(folder.ChildAdded:Connect(function(object)
        if no_landmines then
            remove_landmine_later(object)
        end
    end))
end
local function refresh_landmines()
    local ai_zones = workspace:FindFirstChild("AiZones")
    if not ai_zones then return end
    if not landmine_aizones_connection then
        landmine_aizones_connection = cheat.utility.track_connection(ai_zones.ChildAdded:Connect(function(child)
            if not no_landmines then return end
            if landmine_folder_names[child.Name] then
                watch_landmine_folder(child)
            else
                remove_landmine_later(child)
            end
        end))
    end
    for folder_name, _ in pairs(landmine_folder_names) do
        watch_landmine_folder(ai_zones:FindFirstChild(folder_name))
    end
end
WorldTab:AddToggle('no_landmines', {Text = 'No Landmines', Default = false, Callback = function(v)
    no_landmines = v
    if v then
        task.spawn(function()
            local processed = 0
            local stack = {workspace}
            while #stack > 0 do
                local parent = table.remove(stack)
                for _, object in ipairs(parent:GetChildren()) do
                    stack[#stack + 1] = object
                if not no_landmines then return end
                remove_landmine(object)
                processed = processed + 1
                if processed % 150 == 0 then
                    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                end
            end
            end
        end)
        refresh_landmines()
        if not landmine_workspace_connection then
            landmine_workspace_connection = cheat.utility.track_connection(workspace.DescendantAdded:Connect(function(object)
                if no_landmines and is_landmine_object(object) then
                    remove_landmine_later(object)
                end
            end))
        end
    else
        if landmine_workspace_connection then
            pcall(function() landmine_workspace_connection:Disconnect() end)
            landmine_workspace_connection = nil
        end
        if landmine_aizones_connection then
            pcall(function() landmine_aizones_connection:Disconnect() end)
            landmine_aizones_connection = nil
        end
        for folder, connection in pairs(landmine_connections) do
            pcall(function() connection:Disconnect() end)
            landmine_connections[folder] = nil
        end
    end
end})
        WorldTab:AddToggle('grassswitch', {
            Text = 'No Grass',
            Default = false,
            Callback = function(first)
                cheat.setTerrainDecoration(not first)
            end
        })
        local muzzle_color = Color3.fromRGB(255, 100, 0)
        local last_star_emit = 0
        local last_landmine_refresh = 0
        local star_texture = "rbxassetid://12555502283" -- Star texture
        local muzzle_tab = ui.gunmodbox or WorldTab
        muzzle_tab:AddToggle('custommuzzleflash', {
            Text = 'Custom Muzzle Flash',
            Default = false,
            Callback = function(first)
            end
        }):AddColorPicker('muzzleflashcolor', { Default = Color3.fromRGB(255, 100, 0), Title = 'Muzzle Flash Color', Callback = function(Value)
            muzzle_color = Value
        end})
        WorldTab:AddToggle('shadowswitch', {
            Text = 'No Shadows',
            Default = false,
            Callback = function(first)
                globals.noshadows = first
            end
        })
        local leafs_enabled = false
        local function apply_no_leafs()
            local zones = workspace:FindFirstChild("SpawnerZones")
            if not zones then return end
            local foliage = zones:FindFirstChild("Foliage")
            if not foliage then return end
            task.spawn(function()
                local stack = {foliage}
                local processed = 0
                while #stack > 0 do
                    local parent = table.remove(stack)
                    for _, v in ipairs(parent:GetChildren()) do
                        stack[#stack + 1] = v
                        if v:FindFirstChildOfClass("SurfaceAppearance") then
                            v.Transparency = leafs_enabled and 1 or 0
                        end
                        processed = processed + 1
                        if processed % 150 == 0 then
                            task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                        end
                    end
                end
            end)
        end
        WorldTab:AddToggle('no_leafs', {Text = 'No Leafs', Default = false, Callback = function(v)
            leafs_enabled = v
            apply_no_leafs()
            if v then
                task.spawn(function()
                    while leafs_enabled do
                        task.wait(10)
                        apply_no_leafs()
                    end
                end)
            end
        end})
        WorldTab:AddToggle('no_clouds_enable', {Text = 'no clouds', Default = false, Callback = function(v)
            no_clouds_enabled = v
            apply_clouds_visibility()
        end})
        WorldTab:AddToggle('noscreenfx', { Text = 'No Screen Effects', Default = false })

        -- ─── Custom Skybox (ported from pin.reta V2) ──────────────────────────
        -- 7 preset skyboxes with a dropdown selector, live brightness and X/Z
        -- rotation. Swaps the six Skybox faces on a Sky instance it owns, and
        -- (like v2) disables Clouds while active so the custom sky reads clean.
        -- The X rotation drives Lighting.GeographicLatitude; the Z rotation steps
        -- the face order in 90-degree increments, which is how a cube sky rotates.
        local skybox_presets = {
            ["Purple Nebula"] = {
                SkyboxBk = "rbxassetid://159454299",
                SkyboxDn = "rbxassetid://159454296",
                SkyboxFt = "rbxassetid://159454293",
                SkyboxLf = "rbxassetid://159454286",
                SkyboxRt = "rbxassetid://159454300",
                SkyboxUp = "rbxassetid://159454288"
            },
            ["Vaporwave"] = {
                SkyboxBk = "rbxassetid://600832720",
                SkyboxDn = "rbxassetid://600833821",
                SkyboxFt = "rbxassetid://600835177",
                SkyboxLf = "rbxassetid://600833341",
                SkyboxRt = "rbxassetid://600834603",
                SkyboxUp = "rbxassetid://600835727"
            },
            ["Deep Space"] = {
                SkyboxBk = "rbxassetid://265805434",
                SkyboxDn = "rbxassetid://265805423",
                SkyboxFt = "rbxassetid://265805445",
                SkyboxLf = "rbxassetid://265805466",
                SkyboxRt = "rbxassetid://265805481",
                SkyboxUp = "rbxassetid://265805502"
            },
            ["Night Sky"] = {
                SkyboxBk = "rbxassetid://12064107",
                SkyboxDn = "rbxassetid://12064152",
                SkyboxFt = "rbxassetid://12064121",
                SkyboxLf = "rbxassetid://12064131",
                SkyboxRt = "rbxassetid://12064115",
                SkyboxUp = "rbxassetid://12064143"
            },
            ["Sunset"] = {
                SkyboxBk = "rbxassetid://924373456",
                SkyboxDn = "rbxassetid://924373468",
                SkyboxFt = "rbxassetid://924373479",
                SkyboxLf = "rbxassetid://924373497",
                SkyboxRt = "rbxassetid://924373508",
                SkyboxUp = "rbxassetid://924373523"
            },
            ["Blood Moon"] = {
                SkyboxBk = "rbxassetid://401664839",
                SkyboxDn = "rbxassetid://401664861",
                SkyboxFt = "rbxassetid://401664883",
                SkyboxLf = "rbxassetid://401664901",
                SkyboxRt = "rbxassetid://401664916",
                SkyboxUp = "rbxassetid://401664936"
            },
            ["Purple Planet"] = {
                SkyboxBk = "rbxassetid://16262356578",
                SkyboxDn = "rbxassetid://16262358026",
                SkyboxFt = "rbxassetid://16262360469",
                SkyboxLf = "rbxassetid://16262362003",
                SkyboxRt = "rbxassetid://16262363873",
                SkyboxUp = "rbxassetid://16262366016"
            }
        }

        local custom_skybox_enabled = false
        local no_clouds_enabled = false
        local selected_skybox = "Purple Nebula"
        local sky_brightness = 100
        local sky_rotation_x = 0
        local sky_rotation_z = 0
        local custom_sky_obj = nil
        local original_geographic_latitude = nil
        local disabled_clouds = {}

        local function apply_clouds_visibility()
            local should_hide = custom_skybox_enabled or no_clouds_enabled
            if should_hide then
                local terrain_clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
                if terrain_clouds and terrain_clouds.Enabled then
                    disabled_clouds[terrain_clouds] = true
                    terrain_clouds.Enabled = false
                end
                for _, v in ipairs(Lighting:GetChildren()) do
                    if v:IsA("Clouds") and v.Enabled then
                        disabled_clouds[v] = true
                        v.Enabled = false
                    end
                end
            else
                for v, _ in pairs(disabled_clouds) do
                    if v and v.Parent then
                        v.Enabled = true
                    end
                end
                table.clear(disabled_clouds)
            end
        end

        local function update_skybox()
            if custom_skybox_enabled then
                if not custom_sky_obj or custom_sky_obj.Parent ~= Lighting then
                    custom_sky_obj = Instance.new("Sky")
                    custom_sky_obj.Name = "PinRetaSky"
                    custom_sky_obj.Parent = Lighting
                end

                for _, child in ipairs(Lighting:GetChildren()) do
                    if child:IsA("Sky") and child ~= custom_sky_obj then
                        child:Destroy()
                    end
                end

                local data = skybox_presets[selected_skybox]
                if data then
                    local z_step = math.floor(((sky_rotation_z % 360) + 45) / 90) % 4
                    local bk, ft, lf, rt
                    if z_step == 0 then
                        bk, ft, lf, rt = data.SkyboxBk, data.SkyboxFt, data.SkyboxLf, data.SkyboxRt
                    elseif z_step == 1 then
                        bk, ft, lf, rt = data.SkyboxLf, data.SkyboxRt, data.SkyboxFt, data.SkyboxBk
                    elseif z_step == 2 then
                        bk, ft, lf, rt = data.SkyboxFt, data.SkyboxBk, data.SkyboxRt, data.SkyboxLf
                    else
                        bk, ft, lf, rt = data.SkyboxRt, data.SkyboxLf, data.SkyboxBk, data.SkyboxFt
                    end

                    if custom_sky_obj.SkyboxBk ~= bk then custom_sky_obj.SkyboxBk = bk end
                    if custom_sky_obj.SkyboxFt ~= ft then custom_sky_obj.SkyboxFt = ft end
                    if custom_sky_obj.SkyboxLf ~= lf then custom_sky_obj.SkyboxLf = lf end
                    if custom_sky_obj.SkyboxRt ~= rt then custom_sky_obj.SkyboxRt = rt end

                    if custom_sky_obj.SkyboxDn ~= data.SkyboxDn then custom_sky_obj.SkyboxDn = data.SkyboxDn end
                    if custom_sky_obj.SkyboxUp ~= data.SkyboxUp then custom_sky_obj.SkyboxUp = data.SkyboxUp end
                end

                if original_geographic_latitude == nil then
                    original_geographic_latitude = Lighting.GeographicLatitude
                end
                Lighting.GeographicLatitude = math.clamp(sky_rotation_x, -90, 90)

                for _, eff in ipairs(Lighting:GetChildren()) do
                    if eff:IsA("Atmosphere") then
                        if sky_brightness < 100 then
                            local factor = (100 - sky_brightness) / 100
                            eff.Density = 0.001
                            eff.Haze = 0
                            eff.Glare = 0
                            eff.Offset = 0
                            local c = math.floor(255 * (1 - factor))
                            eff.Color = Color3.fromRGB(c, c, c)
                        elseif sky_brightness > 100 then
                            local factor = (sky_brightness - 100) / 100
                            eff.Density = 0.001
                            eff.Haze = math.clamp(factor * 1.5, 0, 10)
                            eff.Glare = math.clamp(factor * 3.0, 0, 10)
                            eff.Offset = math.clamp(factor * 0.2, 0, 1)
                            eff.Color = Color3.fromRGB(255, 255, 255)
                        else
                            eff.Density = 0
                            eff.Haze = 0
                            eff.Glare = 0
                            eff.Offset = 0
                        end
                    end
                end
                apply_clouds_visibility()
            else
                if custom_sky_obj then
                    custom_sky_obj:Destroy()
                    custom_sky_obj = nil
                end
                if original_geographic_latitude ~= nil then
                    Lighting.GeographicLatitude = original_geographic_latitude
                    original_geographic_latitude = nil
                end
                apply_clouds_visibility()
            end
        end

        WorldTab:AddToggle('custom_skybox_enable', {Text = 'custom skybox', Default = false, Callback = function(v)
            custom_skybox_enabled = v
            update_skybox()
        end})

        WorldTab:AddDropdown('custom_skybox_select', {Text = 'skybox preset', Default = 1, Values = {'Purple Nebula', 'Purple Planet', 'Vaporwave', 'Deep Space', 'Night Sky', 'Sunset', 'Blood Moon'}, Callback = function(v)
            selected_skybox = v
            if custom_skybox_enabled then update_skybox() end
        end})

        WorldTab:AddSlider('skybox_brightness', {Text = 'sky brightness', Default = 100, Min = 10, Max = 1000, Rounding = 0, Suffix = "%", Compact = false, Callback = function(v)
            sky_brightness = v
            if custom_skybox_enabled then update_skybox() end
        end})

        WorldTab:AddSlider('skybox_rotation_x', {Text = 'sky rotation X', Default = 0, Min = -90, Max = 90, Rounding = 0, Suffix = "°", Compact = false, Callback = function(v)
            sky_rotation_x = v
            if custom_skybox_enabled then update_skybox() end
        end})

        WorldTab:AddSlider('skybox_rotation_z', {Text = 'sky rotation Z', Default = 0, Min = 0, Max = 360, Rounding = 0, Suffix = "°", Compact = false, Callback = function(v)
            sky_rotation_z = v
            if custom_skybox_enabled then update_skybox() end
        end})

        WorldTab:AddButton('apply sky', function()
            update_skybox()
        end)

        Lighting.ChildAdded:Connect(function(child)
            if custom_skybox_enabled and child:IsA("Atmosphere") then
                update_skybox()
            elseif (custom_skybox_enabled or no_clouds_enabled) and child:IsA("Clouds") then
                apply_clouds_visibility()
            end
        end)
        workspace.Terrain.ChildAdded:Connect(function(child)
            if (custom_skybox_enabled or no_clouds_enabled) and child:IsA("Clouds") then
                apply_clouds_visibility()
            end
        end)


        world_radar_tab:AddToggle('radar_enabled', {Text = 'Radar', Default = false, Callback = function(v)
            setPlayerRadarEnabled(v)
        end})
        local last_custom_muzzle_refresh = 0
        local custom_muzzle_active = false
        cheat.utility.new_heartbeat(function()
            local now = tick()
            local custom_muzzle_enabled = cheat.Toggles.custommuzzleflash and cheat.Toggles.custommuzzleflash.Value
            if not (nofog or no_landmines or globals.noshadows or globals.gradientenabled or globals.EnableTime or custom_muzzle_enabled) then
                return
            end
            local char = LocalPlayer.Character
            if nofog and Lighting:FindFirstChildOfClass("Atmosphere") then
                Lighting:FindFirstChildOfClass("Atmosphere").Haze = 0
                Lighting:FindFirstChildOfClass("Atmosphere").Density = 0
            end
            if no_landmines and now - last_landmine_refresh > 1 then
                last_landmine_refresh = now
                refresh_landmines()
            end
            if Lighting.GlobalShadows ~= (not globals.noshadows) then Lighting.GlobalShadows = not globals.noshadows end
            if globals.gradientenabled then
                if Lighting.Ambient ~= gradientcolor1 then Lighting.Ambient = gradientcolor1 end
                if Lighting.OutdoorAmbient ~= gradientcolor2 then Lighting.OutdoorAmbient = gradientcolor2 end
            end
            if globals.EnableTime and Lighting.ClockTime ~= globals.Time then Lighting.ClockTime = globals.Time end
            if custom_muzzle_enabled then
                if now - last_custom_muzzle_refresh > 0.05 then
                    last_custom_muzzle_refresh = now
                    custom_muzzle_active = false
                for _, v in ipairs(Camera:GetDescendants()) do
                    if v:IsA("Light") or (v:IsA("BasePart") and (v.Name:find("Flash") or v.Name:find("Muzzle") or v.Name:find("Smoke"))) or v:IsA("ParticleEmitter") then
                        local is_muzzle_part = v.Name:find("Flash") or v.Name:find("Muzzle") or v.Name:find("Smoke")
                        if (v:IsA("Light") and v.Enabled) or (v:IsA("ParticleEmitter") and v.Enabled) or (v:IsA("BasePart") and v.Transparency < 0.9 and is_muzzle_part) then
                            custom_muzzle_active = true
                        end
                        
                        if v:IsA("Light") then
                            v.Color = muzzle_color
                            v.Brightness = 25
                            v.Range = 25
                        elseif v:IsA("ParticleEmitter") then
                            v.Color = ColorSequence.new(muzzle_color)
                            -- Removed transparency override to keep it natural
                        elseif v:IsA("BasePart") then
                            v.Color = muzzle_color
                            if not v.Name:find("Smoke") then
                                v.Transparency = 0 -- Keep fire visible, but let smoke animate
                            end
                            local sa = v:FindFirstChildOfClass("SurfaceAppearance") or v:FindFirstChildOfClass("Texture")
                            if sa then sa:Destroy() end
                        end
                    end
                end
                
                    if char then
                        for _, v in ipairs(char:GetDescendants()) do
                            if v:IsA("Light") or (v:IsA("BasePart") and (v.Name:find("Flash") or v.Name:find("Muzzle") or v.Name:find("Smoke"))) or v:IsA("ParticleEmitter") then
                                if v:IsA("Light") then
                                    v.Color = muzzle_color
                                    v.Brightness = 25
                                elseif v:IsA("ParticleEmitter") then
                                    v.Color = ColorSequence.new(muzzle_color)
                                elseif v:IsA("BasePart") then
                                    v.Color = muzzle_color
                                    v.Transparency = 0
                                    local sa = v:FindFirstChildOfClass("SurfaceAppearance") or v:FindFirstChildOfClass("Texture")
                                    if sa then sa:Destroy() end
                                end
                            end
                        end
                    end
                end
                
                if custom_muzzle_active and tick() - last_star_emit > 0.04 then
                    last_star_emit = tick()
                    local vm = _FindFirstChildOfClass(Camera, "Model")
                    local item = vm and _FindFirstChild(vm, "Item")
                    local muzzle = (item and (_FindFirstChild(item, "Muzzle") or _FindFirstChild(item, "AimPart"))) or (vm and _FindFirstChild(vm, "AimPart")) or Camera
                    
                    if muzzle then
                        task.spawn(function()
                            local att = Instance.new("Attachment")
                            if muzzle:IsA("Camera") then
                                att.Parent = workspace.Terrain
                                att.WorldPosition = Camera.CFrame.p + (Camera.CFrame.LookVector * 2.5)
                            else
                                att.Parent = muzzle
                            end
                            
                            local emitter = Instance.new("ParticleEmitter")
                            emitter.Texture = star_texture
                            emitter.Color = ColorSequence.new(muzzle_color)
                            emitter.Size = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0)})
                            emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(1, 1)})
                            emitter.Lifetime = NumberRange.new(0.3, 0.5)
                            emitter.Speed = NumberRange.new(15, 35)
                            emitter.SpreadAngle = Vector2.new(60, 60)
                            emitter.ZOffset = 1
                            emitter.Rate = 0
                            emitter.Parent = att
                            emitter:Emit(8)
                            task.wait(0.6)
                            emitter:Destroy()
                            att:Destroy()
                        end)
                    end
                end
            else
                custom_muzzle_active = false
            end
        end)
    end
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local othervisuals = player_camera_tab
        local function get_gameplay_fov()
            local player_folder = ReplicatedStorage:FindFirstChild("Players")
            local local_folder = player_folder and player_folder:FindFirstChild(LocalPlayer.Name)
            local settings = local_folder and local_folder:FindFirstChild("Settings")
            local gameplay = settings and settings:FindFirstChild("GameplaySettings")
            local attr = gameplay and gameplay:GetAttribute("DefaultFOV")
            return tonumber(attr) or tonumber(Camera.FieldOfView) or 90
        end

        local default_fov = math.clamp(get_gameplay_fov(), 1, 120)
        local zoom_enabled, zoom_size = false, 10
        local fov_enabled, fov_size = false, default_fov

        local function set_gameplay_fov(value)
            value = math.clamp(tonumber(value) or default_fov, 1, 120)
            local player_folder = ReplicatedStorage:FindFirstChild("Players")
            local local_folder = player_folder and player_folder:FindFirstChild(LocalPlayer.Name)
            local settings = local_folder and local_folder:FindFirstChild("Settings")
            local gameplay = settings and settings:FindFirstChild("GameplaySettings")
            if gameplay then
                gameplay:SetAttribute("DefaultFOV", value)
            end
            Camera.FieldOfView = value
        end

        local function current_zoom_active()
            return feature_active(zoom_enabled, 'zoom_bind', false, false)
        end

        local function apply_camera_fov()
            local is_zoomed = current_zoom_active()
            globals.zoom_enabled = is_zoomed
            globals.fov_enabled = fov_enabled or is_zoomed
            if is_zoomed then
                set_gameplay_fov(zoom_size)
            elseif fov_enabled then
                set_gameplay_fov(fov_size)
            end
        end

        othervisuals:AddToggle('fov_enabled', {Text = 'FOV Changer',Default = false,Callback = function(first)
            fov_enabled = first
            if not first and not current_zoom_active() then
                globals.fov_enabled = false
                set_gameplay_fov(default_fov)
                return
            end
            apply_camera_fov()
        end})
        local zoom_toggle = othervisuals:AddToggle('zoom_enabled', {Text = 'Zoom',Default = false,Callback = function(first)
            zoom_enabled = first
            apply_camera_fov()
        end})
        local zoom_picker = zoom_toggle:AddKeyPicker('zoom_bind', {Default = 'None',SyncToggleState = true,Mode = 'Toggle',Text = 'Zoom',NoUI = false})
        cheat.utility.new_renderstepped(function()
            if fov_enabled or zoom_enabled then
                apply_camera_fov()
            end
        end)
        othervisuals:AddSlider('zoom_size', { Text = 'Zoom FOV', Default = 10, Min = 1, Max = 90, Rounding = 0, Compact = true, Callback = function(value)
            zoom_size = value
            apply_camera_fov()
        end})
        othervisuals:AddSlider('fov_size', { Text = 'FOV Size', Default = default_fov, Min = 1, Max = 120, Rounding = 0, Compact = true, Callback = function(value)
            fov_size = value
            apply_camera_fov()
        end})
        ui.gunmodbox:AddToggle('nomuzzleflash', { Text = 'Remove Muzzle Flash', Default = false });
        othervisuals:AddToggle('killeffect', { Text = 'Hit Effect (Stars)', Default = false });
        othervisuals:AddSlider('killeffect_amount', { Text = 'Hit Effect Stars Amount', Default = 100, Min = 50, Max = 200, Rounding = 0, Compact = true });
        othervisuals:AddToggle('damagenumbers', { Text = 'Damage Numbers', Default = false, Callback = function(v)
            cheat.damagenumbers_enabled = v
        end}):AddColorPicker('damagenumbers_color', { Default = Color3.fromRGB(255, 75, 75), Title = 'Damage Number Color', Transparency = 0, Callback = function(v)
            cheat.damagenumbers_color = v
        end})
        othervisuals:AddToggle('damagenumbers_random_dir', { Text = 'Random Directions', Default = false, Callback = function(v)
            cheat.damagenumbers_random_dir = v
        end})
        othervisuals:AddSlider('damagenumbers_spread', { Text = 'Numbers Spread', Default = 1, Min = 0, Max = 20, Rounding = 1, Suffix = 'x', Compact = true, Callback = function(v)
            cheat.damagenumbers_spread = v
        end})

        local hitlogs_tab = ui.box.misc:AddTab('Hit Logs')
        local hitlogstog = hitlogs_tab:AddToggle('hitlogs_enabled', { Text = 'Hit Logs', Default = false, Callback = function(v) cheat.hitlogs_enabled = v end })
        hitlogstog:AddColorPicker('hitlogs_valid_color', { Default = cheat.hitlogs_valid_color, Title = 'Valid Hit Color', Transparency = 0, Callback = function(c) cheat.hitlogs_valid_color = c end })
        hitlogstog:AddColorPicker('hitlogs_invalid_color', { Default = cheat.hitlogs_invalid_color, Title = 'Invalid Hit Color', Transparency = 0, Callback = function(c) cheat.hitlogs_invalid_color = c end })
        hitlogs_tab:AddDropdown('hitlogs_font', { Text = 'Hit Logs Font', Default = 2, Values = {'UI', 'System', 'Plex', 'Monospace'}, Callback = function(v)
            local fmap = {["UI"]=0, ["System"]=1, ["Plex"]=2, ["Monospace"]=3}
            cheat.hitlogs_font = fmap[v] or 2
        end})
        hitlogs_tab:AddSlider('hitlogs_size', { Text = 'Hit Logs Text Size', Default = 14, Min = 10, Max = 30, Rounding = 0, Compact = true, Callback = function(v) cheat.hitlogs_size = v end })
        hitlogs_tab:AddSlider('hitlogs_y', { Text = 'Hit Logs Y Position', Default = 500, Min = 1, Max = 1500, Rounding = 0, Compact = true, Callback = function(v) cheat.hitlogs_y = v end })

        local vmchams
        local vmpos
        
        local function safe_lower_text(value)
            local ok, lowered = pcall(function()
                return tostring(value or ""):lower()
            end)
            return ok and lowered or ""
        end

        local function has_muzzle_keyword(text)
            text = safe_lower_text(text)
            return text:find("flash", 1, true)
                or text:find("muzzle", 1, true)
                or text:find("aimpart", 1, true)
                or text:find("smoke", 1, true)
                or text:find("spark", 1, true)
        end

        local function remove_muzzle(v)
            if not (cheat.Toggles.nomuzzleflash and cheat.Toggles.nomuzzleflash.Value) then return end

            local ok, is_target = pcall(function()
                return v:IsA("ParticleEmitter") or v:IsA("Light") or v:IsA("Beam")
            end)
            if not (ok and is_target) then return end

            local parent = v.Parent
            if not (has_muzzle_keyword(v.Name) or has_muzzle_keyword(parent and parent.Name)) then return end

            pcall(function()
                v.Enabled = false
                if v:IsA("ParticleEmitter") then
                    v:Clear()
                    v.Transparency = NumberSequence.new(1)
                end
            end)
        end
        
        cheat.utility.track_connection(workspace.CurrentCamera.DescendantAdded:Connect(remove_muzzle))
        local last_nomuzzle_scan = 0
        cheat.utility.new_heartbeat(function()
            if cheat.Toggles.nomuzzleflash and cheat.Toggles.nomuzzleflash.Value then
                if tick() - last_nomuzzle_scan < 0.25 then return end
                last_nomuzzle_scan = tick()
                for _, v in workspace.CurrentCamera:GetDescendants() do
                    remove_muzzle(v)
                end
            end
        end)
        local inv_tab = world_inventory_tab
        local inventory_checker = {
            enabled = false,
            active = false,
            full = false,
            corpse = false,
            value = false,
            target = false,
            title_color = Color3.fromRGB(255, 255, 255),
        }
        inv_tab:AddToggle('inventorychecker', { Text = 'Inventory Checker', Default = false, Callback = function(v)
            inventory_checker.enabled = v
        end}):AddKeyPicker('inventorychecker_bind', {Default = 'None', SyncToggleState = false, Mode = 'Hold', Text = 'Inventory Checker', NoUI = false, Callback = function(active)
            inventory_checker.active = active
        end})
        inv_tab:AddDropdown('inventorychecker_toggles', { Text = 'Inventory Check Options', Default = {}, Values = { 'Inventory Check Corpses', 'Show Full Inventory', 'Show Inventory Value' }, Multi = true, Callback = function(values)
            inventory_checker.full = false
            inventory_checker.corpse = false
            inventory_checker.value = false
            for _, value in ipairs(values or {}) do
                if value == 'Inventory Check Corpses' then
                    inventory_checker.corpse = true
                elseif value == 'Show Full Inventory' then
                    inventory_checker.full = true
                elseif value == 'Show Inventory Value' then
                    inventory_checker.value = true
                end
            end
        end})
        inv_tab:AddToggle('inventorychecker_target', { Text = 'Show Check Target', Default = false, Callback = function(v)
            inventory_checker.target = v
        end}):AddColorPicker('inventorychecker_target_color', { Default = inventory_checker.title_color, Title = 'Target Text Color', Transparency = 0, Callback = function(v)
            inventory_checker.title_color = v
        end})

        -- These four used to be real toggles marked SetVisible(false), but the
        -- library's set_visible is a no-op against this mclib build, so they still
        -- rendered in the tab. They are internal state for the inventory viewer, not
        -- user-facing options the user wants, so they are now plain locals. Only
        -- X / Y / scale / drag stay registered (and invisible) because the window
        -- drag handler writes back to those flags.
        local inv_show_full = false
        local inv_show_value = false
        local inv_check_corpse = false
        local inv_viewer_enabled = false
        local legacy_inventory_drag = inv_tab:AddToggle('inventoryviewer_drag', { Text = 'Enable Dragging', Default = false }); legacy_inventory_drag:SetVisible(false)
        local legacy_inventory_x = inv_tab:AddSlider('inventoryviewer_x', { Text = 'X Position', Default = math.max(20, Camera.ViewportSize.X - 430), Min = 1, Max = 2000, Rounding = 0, Compact = true }); legacy_inventory_x:SetVisible(false)
        local legacy_inventory_y = inv_tab:AddSlider('inventoryviewer_y', { Text = 'Y Position', Default = 200, Min = 1, Max = 2000, Rounding = 0, Compact = true }); legacy_inventory_y:SetVisible(false)
        local legacy_inventory_scale = inv_tab:AddSlider('inventoryviewer_scale', { Text = 'Icon Scale', Default = 1, Min = 0.5, Max = 2, Rounding = 2, Compact = true }); legacy_inventory_scale:SetVisible(false)
        local legacy_inventory_spacing = inv_tab:AddSlider('inventoryviewer_spacing', { Text = 'Spacing', Default = 1, Min = 0.5, Max = 2, Rounding = 2, Compact = true }); legacy_inventory_spacing:SetVisible(false)
        local legacy_inventory_delay = inv_tab:AddSlider('inventoryviewer_d', { Text = 'Refresh Delay', Default = 0.1, Min = 0.05, Max = 2, Rounding = 2, Compact = true }); legacy_inventory_delay:SetVisible(false)

        local item_finder_items = {}
        local item_finder_item_set = {}
        local function add_item_finder_item(name)
            if type(name) == "string" and name ~= "" and not item_finder_item_set[name] then
                item_finder_item_set[name] = true
                table.insert(item_finder_items, name)
            end
        end
        for _, name in ipairs({"TFZ98S", "R700", "M4", "AsVal", "PKM", "FlareGun", "SPSh44", "Gold", "GoldWatch", "RepairKit"}) do
            add_item_finder_item(name)
        end
        pcall(function()
            local ItemsList = ReplicatedStorage:FindFirstChild("ItemsList")
            if ItemsList then
                for _, item in pairs(ItemsList:GetChildren()) do
                    local is_melee = false
                    local props = item:FindFirstChild("ItemProperties")
                    if props and props:GetAttribute("ItemType") == "Melee" then
                        is_melee = true
                    end
                    if item.Name ~= "Lighter" and not is_melee then
                        add_item_finder_item(item.Name)
                    end
                end
            end
        end)
        table.sort(item_finder_items, function(a, b) return string.lower(a) < string.lower(b) end)
        local inv_finder_cache = {}
        local inv_finder_notified = {}
        local inv_finder_last_scan = 0
        local inv_item_finder = inv_tab:AddDropdown('inv_item_finder', { Text = 'Item Whitelist', Default = {}, Values = item_finder_items, Multi = true, Callback = function()
            inv_finder_cache = {}
            inv_finder_notified = {}
            inv_finder_last_scan = 0
        end})
        local finder_toggle = inv_tab:AddToggle('inv_finder_enabled', { Text = 'Item Finder', Default = false, Callback = function(enabled)
            inv_finder_cache = {}
            inv_finder_notified = {}
            inv_finder_last_scan = 0
            if enabled and cheat.Library and cheat.Library.Notify then
                cheat.Library:Notify('Item Finder', 'Preview Of Item Finder', 1.5)
            end
        end})
        local inv_finder_glow_size = 5
        local inv_finder_glow_color = Color3.fromRGB(120, 110, 180)
        local legacy_finder_glow = inv_tab:AddSlider('inv_finder_glow_size', {Text = 'Neon Glow Size', Default = 5, Min = 1, Max = 15, Rounding = 0, Callback = function(v)
            inv_finder_glow_size = v
        end}); legacy_finder_glow:SetVisible(false)
        finder_toggle:AddColorPicker('inv_finder_glow_color', {Default = inv_finder_glow_color, Title = 'Neon Glow Color', Transparency = 0, Callback = function(v)
            inv_finder_glow_color = v
        end})
        
        local legacy_finder_x = inv_tab:AddSlider('inv_finder_x', { Text = 'Finder X Position', Default = math.max(1, math.floor(workspace.CurrentCamera.ViewportSize.X - 250)), Min = 1, Max = 3000, Rounding = 0, Compact = true }); legacy_finder_x:SetVisible(false)
        local legacy_finder_y = inv_tab:AddSlider('inv_finder_y', { Text = 'Finder Y Position', Default = 50, Min = 1, Max = 3000, Rounding = 0, Compact = true }); legacy_finder_y:SetVisible(false)

        local inv_finder_panel = {}
        inv_finder_panel.pos = _Vector2new(cheat.Options.inv_finder_x.Value, cheat.Options.inv_finder_y.Value)
        inv_finder_panel.width = 200
        inv_finder_panel.dragging = false
        inv_finder_panel.dragoffset = _Vector2new(0,0)
        
        inv_finder_panel.bg = cheat.utility.new_drawing("Square", { Visible = false, Filled = true, Color = Color3.fromRGB(20, 20, 20), ZIndex = 100 })
        inv_finder_panel.border = cheat.utility.new_drawing("Square", { Visible = false, Filled = false, Color = Color3.fromRGB(45, 45, 45), Thickness = 1, ZIndex = 101 })
        inv_finder_panel.title = cheat.utility.new_drawing("Text", { Visible = false, Text = "Item Finder", Size = 16, Center = true, Color = Color3.new(1,1,1), Outline = true, ZIndex = 102 })
        
        inv_finder_panel.glow = {}
        for i = 1, 6 do
            inv_finder_panel.glow[i] = cheat.utility.new_drawing("Square", { Visible = false, Filled = false, Thickness = 1, ZIndex = 99 })
        end
        
        inv_finder_panel.labels = {}
        for i = 1, 30 do
            inv_finder_panel.labels[i] = cheat.utility.new_drawing("Text", { Visible = false, Text = "", Size = 14, Center = true, Color = Color3.fromRGB(200, 200, 200), Outline = true, ZIndex = 102 })
        end
        local inv_finder_scan_interval = 0.5

        local function build_item_finder_lookup(values)
            local lookup = {}
            if type(values) ~= "table" then
                return lookup
            end

            for key, selected in pairs(values) do
                local name
                if type(key) == "number" then
                    name = selected
                    selected = true
                else
                    name = key
                end

                if selected and type(name) == "string" and name ~= "" then
                    lookup[name] = true
                    if name == "Gold" then
                        lookup.Gold50g = true
                    end
                end
            end

            return lookup
        end

        cheat.utility.new_heartbeat(LPH_NO_VIRTUALIZE(function(delta)
            local enabled = cheat.Toggles.inv_finder_enabled and cheat.Toggles.inv_finder_enabled.Value
            if not enabled then
                inv_finder_panel.bg.Visible = false
                inv_finder_panel.border.Visible = false
                inv_finder_panel.title.Visible = false
                for i = 1, 6 do inv_finder_panel.glow[i].Visible = false end
                for i = 1, 30 do inv_finder_panel.labels[i].Visible = false end
                return
            end
            
            if tick() - inv_finder_last_scan >= inv_finder_scan_interval then
                inv_finder_last_scan = tick()
                local selected_items = cheat.Options.inv_item_finder and cheat.Options.inv_item_finder.Value or {}
                local selected_lookup = build_item_finder_lookup(selected_items)
                local found_players = {}
                local rep_players = ReplicatedStorage:FindFirstChild("Players")
                if rep_players and next(selected_lookup) ~= nil then
                    for _, player in ipairs(Players:GetPlayers()) do
                        if player ~= LocalPlayer then
                            local p_folder = rep_players:FindFirstChild(player.Name)
                            local p_inv = p_folder and p_folder:FindFirstChild("Inventory")
                            if p_inv then
                                local found_for_player = {}
                                local function check_item(item)
                                    if selected_lookup[item.Name] and not found_for_player[item.Name] then
                                        found_for_player[item.Name] = true
                                        table.insert(found_players, player.Name .. " (" .. item.Name .. ")")
                                        local notify_key = player.Name .. ":" .. item.Name
                                        if not inv_finder_notified[notify_key] then
                                            inv_finder_notified[notify_key] = true
                                            if cheat.Library and cheat.Library.Notify then
                                                cheat.Library:Notify("Item | Finder", "Player: " .. player.Name .. " Has an: " .. item.Name, 5)
                                            end
                                        end
                                    end
                                    local sub_inv = item:FindFirstChild("Inventory")
                                    if sub_inv then
                                        for _, sub_item in ipairs(sub_inv:GetChildren()) do
                                            check_item(sub_item)
                                        end
                                    end
                                    local atts = item:FindFirstChild("Attachments")
                                    if atts then
                                        for _, att in ipairs(atts:GetChildren()) do
                                            check_item(att)
                                        end
                                    end
                                end
                                for _, item in ipairs(p_inv:GetChildren()) do
                                    check_item(item)
                                end
                            end
                        end
                    end
                end
                inv_finder_cache = found_players
            end
            local found_players = inv_finder_cache
            
            if #found_players > 0 then
                inv_finder_panel.bg.Visible = true
                inv_finder_panel.border.Visible = true
                inv_finder_panel.title.Visible = true
                
                local max_display = math.min(#found_players, 30)
                local h = 45 + (max_display * 16)
                local p = inv_finder_panel.pos
                local size = _Vector2new(inv_finder_panel.width, h)
                
                local mousepos = _Vector2new(Mouse.X, Mouse.Y + GuiInset.Y)
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) then
                    local in_bounds = mousepos.X >= p.X and mousepos.X <= p.X + size.X and mousepos.Y >= p.Y and mousepos.Y <= p.Y + size.Y
                    if in_bounds or inv_finder_panel.dragging then
                        if not inv_finder_panel.dragging then
                            inv_finder_panel.dragging = true
                            inv_finder_panel.dragoffset = p - mousepos
                        end
                        inv_finder_panel.pos = mousepos + inv_finder_panel.dragoffset
                        p = inv_finder_panel.pos
                        
                        if cheat.Options.inv_finder_x and cheat.Options.inv_finder_y then
                            cheat.Options.inv_finder_x:SetValue(p.X)
                            cheat.Options.inv_finder_y:SetValue(p.Y)
                        end
                    end
                else
                    inv_finder_panel.dragging = false
                end
                
                inv_finder_panel.bg.Position = p
                inv_finder_panel.bg.Size = size
                inv_finder_panel.border.Position = p
                inv_finder_panel.border.Size = size
                inv_finder_panel.title.Position = p + _Vector2new(inv_finder_panel.width / 2, 5)
                
                local g_color = inv_finder_glow_color
                local g_size = inv_finder_glow_size
                for i = 1, 6 do
                    local th = (i / 6) * g_size
                    inv_finder_panel.glow[i].Visible = true
                    inv_finder_panel.glow[i].Color = g_color
                    inv_finder_panel.glow[i].Thickness = math.max(1, th)
                    inv_finder_panel.glow[i].Transparency = 0.3 - (i * 0.04)
                    inv_finder_panel.glow[i].Size = size + _Vector2new(th*2, th*2)
                    inv_finder_panel.glow[i].Position = p - _Vector2new(th, th)
                end
                
                for i = 1, 30 do
                    if i <= max_display then
                        inv_finder_panel.labels[i].Visible = true
                        inv_finder_panel.labels[i].Text = found_players[i]
                        inv_finder_panel.labels[i].Position = p + _Vector2new(inv_finder_panel.width / 2, 25 + (i * 15))
                    else
                        inv_finder_panel.labels[i].Visible = false
                    end
                end
            else
                inv_finder_panel.bg.Visible = false
                inv_finder_panel.border.Visible = false
                inv_finder_panel.title.Visible = false
                for i = 1, 6 do inv_finder_panel.glow[i].Visible = false end
                for i = 1, 30 do inv_finder_panel.labels[i].Visible = false end
            end
        end))

        player_viewmodel_tab:AddToggle('viewmodel_changer', { Text = 'ViewModel Changer', Default = false, Callback = function()
            local vm = _FindFirstChildOfClass(Camera, "Model")
            if vm then
                task.defer(function()
                    vmpos(vm)
                end)
            end
        end})
        player_viewmodel_tab:AddLabel("Viewmodel Offset");
        player_viewmodel_tab:AddSlider('viewmodel_x', { Text = 'X', Default = 0, Min = -5, Max = 5, Rounding = 2, Compact = true });
        player_viewmodel_tab:AddSlider('viewmodel_y', { Text = 'Y', Default = 0, Min = -5, Max = 5, Rounding = 2, Compact = true });
        player_viewmodel_tab:AddSlider('viewmodel_z', { Text = 'Z', Default = 0, Min = -5, Max = 5, Rounding = 2, Compact = true });
        cheat._arm_chams_transparency = cheat._arm_chams_transparency or 0
        cheat._body_chams_transparency = cheat._body_chams_transparency or 0
        cheat._gun_chams_transparency = cheat._gun_chams_transparency or 0
        player_viewmodel_tab:AddToggle("ac", { Text = "Arm Chams", Default = false }):AddColorPicker('acc', { Default = Color3.new(1, 1, 1), Title = 'Arm Chams Color', Transparency = 0, Callback = function(_, alpha)
            cheat._arm_chams_transparency = alpha or cheat._arm_chams_transparency
            vmchams(true)
        end });
        player_viewmodel_tab:AddToggle("bc", { Text = "Body Chams", Default = false }):AddColorPicker('bcc', { Default = Color3.new(1, 1, 1), Title = 'Body Chams Color', Transparency = 0, Callback = function(_, alpha)
            cheat._body_chams_transparency = alpha or cheat._body_chams_transparency
        end });
        player_viewmodel_tab:AddToggle("noarms", { Text = "Remove Arms", Default = false, Callback = function(v)
            vmchams(true)
        end });
        player_viewmodel_tab:AddToggle("gm", { Text = "Gun Chams", Default = false }):AddColorPicker('gcc', { Default = Color3.new(1, 1, 1), Title = 'Gun Chams Color', Transparency = 0, Callback = function(_, alpha)
            cheat._gun_chams_transparency = alpha or cheat._gun_chams_transparency
            vmchams(true)
        end });
        player_viewmodel_tab:AddDropdown("acm", { Text = "Arm Chams Material", Default = "SmoothPlastic", Values = { "SmoothPlastic", "ForceField", "Neon", "Plastic", "Glass" } });
        player_viewmodel_tab:AddDropdown("bcm", { Text = "Body Chams Material", Default = "SmoothPlastic", Values = { "SmoothPlastic", "ForceField", "Neon", "Plastic", "Glass" } });
        player_viewmodel_tab:AddDropdown("gcm", { Text = "Gun Chams Material", Default = "SmoothPlastic", Values = { "SmoothPlastic", "ForceField", "Neon", "Plastic", "Glass" } });

        -- ─── Always Suit Arms (ported from pin.reta V2) ───────────────────────
        -- Clones the game's own ViewModelClothing.CivilianShirt and CombatGloves
        -- onto your viewmodel and welds each mesh part to the matching arm bone, so
        -- the 3D suit + wrist watch and the Blackout combat gloves are always worn
        -- regardless of what you have equipped. Mesh parts are named RU/RL/RH/LU/LL/LH
        -- and map to RightUpperArm / RightLowerArm / RightHand / Left*.
        local always_suit_arms_enabled = false
        local _suit_was_active = false
        local _suit_fingerprint = nil

        local function apply_viewmodel_suit(vm)
            vm = vm or _FindFirstChildOfClass(Camera, "Model")
            if not vm then return end

            if not always_suit_arms_enabled then
                if vm:FindFirstChild("CustomSuit") then vm.CustomSuit:Destroy() end
                if vm:FindFirstChild("CustomGloves") then vm.CustomGloves:Destroy() end
                return
            end

            local rs = game:GetService("ReplicatedStorage")
            local vmc = rs:FindFirstChild("ViewModelClothing")
            local cs = vmc and vmc:FindFirstChild("CivilianShirt")
            local cg = vmc and vmc:FindFirstChild("CombatGloves")
            local blackout_skin = rs:FindFirstChild("Skins") and rs.Skins:FindFirstChild("CombatGloves") and rs.Skins.CombatGloves:FindFirstChild("Blackout")

            local function weld_model(model)
                for _, part in ipairs(model:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.Transparency = 0
                        local weld_target_name = part:GetAttribute("WeldTo")
                        if not weld_target_name then
                            if part.Name == "RU" then weld_target_name = "RightUpperArm"
                            elseif part.Name == "RL" then weld_target_name = "RightLowerArm"
                            elseif part.Name == "RH" then weld_target_name = "RightHand"
                            elseif part.Name == "LU" then weld_target_name = "LeftUpperArm"
                            elseif part.Name == "LL" or part.Name == "LH" then weld_target_name = "LeftLowerArm"
                            end
                        end
                        local target_part = weld_target_name and vm:FindFirstChild(weld_target_name)
                        if target_part then
                            local weld = Instance.new("Weld")
                            weld.Part0 = target_part
                            weld.Part1 = part
                            local offset_attr = part:GetAttribute("offset")
                            if typeof(offset_attr) == "CFrame" then
                                weld.C0 = offset_attr
                            elseif typeof(offset_attr) == "string" then
                                local nums = {}
                                for num in offset_attr:gmatch("[-%d%.e]+") do
                                    table.insert(nums, tonumber(num))
                                end
                                if #nums == 12 then
                                    weld.C0 = CFrame.new(unpack(nums))
                                elseif #nums == 3 then
                                    weld.C0 = CFrame.new(nums[1], nums[2], nums[3])
                                end
                            end
                            weld.Parent = part
                        end
                    end
                end
            end

            for _, child in ipairs(vm:GetChildren()) do
                if child:IsA("Model") and (child.Name:find("Shirt") or child.Name:find("Suit") or child.Name:find("Gloves") or child.Name:find("Clothing")) and child.Name ~= "CustomSuit" and child.Name ~= "CustomGloves" then
                    child:Destroy()
                end
            end

            if cs and not vm:FindFirstChild("CustomSuit") then
                local suit_clone = cs:Clone()
                suit_clone.Name = "CustomSuit"
                suit_clone:SetAttribute("ItemType", "CustomSuit")
                weld_model(suit_clone)
                suit_clone.Parent = vm
            end

            if cg and not vm:FindFirstChild("CustomGloves") then
                local gloves_clone = cg:Clone()
                gloves_clone.Name = "CustomGloves"
                gloves_clone:SetAttribute("ItemType", "CustomGloves")
                weld_model(gloves_clone)

                local skin_textures = blackout_skin and blackout_skin:FindFirstChild("Textures")
                local skin_sa = skin_textures and skin_textures:FindFirstChildOfClass("SurfaceAppearance")
                if skin_sa then
                    for _, part in ipairs(gloves_clone:GetChildren()) do
                        if part:IsA("MeshPart") then
                            local existing_sa = part:FindFirstChildOfClass("SurfaceAppearance")
                            if existing_sa then existing_sa:Destroy() end
                            local new_sa = skin_sa:Clone()
                            new_sa.Parent = part
                        end
                    end
                end

                gloves_clone.Parent = vm
            end

            for _, vm_item in ipairs(vm:GetChildren()) do
                if vm_item:IsA("MeshPart") and (vm_item.Name:find("Hand") or vm_item.Name:find("Arm")) then
                    vm_item.Transparency = 0
                end
            end
        end

        player_viewmodel_tab:AddToggle('always_suit_arms', {
            Text = 'Always Suit Arms',
            Default = false,
            Tooltip = 'Always wears the in-game 3D suit with wrist watch and visual combat gloves (Blackout) on your viewmodel.',
            Callback = function(v)
                always_suit_arms_enabled = v
                cheat._suit_needs_apply = true
            end
        })

        -- Drive it from a dirty-flag heartbeat instead of hooking vmchams: the
        -- viewmodel is rebuilt whenever you swap weapons, so we watch a cheap
        -- fingerprint of its children and re-apply only when it actually changes.
        cheat.utility.new_heartbeat(function()
            if not always_suit_arms_enabled then
                if _suit_was_active then
                    _suit_was_active = false
                    _suit_fingerprint = nil
                    pcall(apply_viewmodel_suit, nil)
                end
                return
            end
            local vm = _FindFirstChildOfClass(Camera, "Model")
            if not vm then return end

            local n = 0
            local has_suit, has_gloves = false, false
            for _, c in ipairs(vm:GetChildren()) do
                n = n + 1
                if c.Name == "CustomSuit" then has_suit = true
                elseif c.Name == "CustomGloves" then has_gloves = true end
            end
            local fp = n .. "|" .. tostring(has_suit) .. "|" .. tostring(has_gloves)

            if cheat._suit_needs_apply or fp ~= _suit_fingerprint or not (has_suit and has_gloves) then
                cheat._suit_needs_apply = false
                _suit_fingerprint = fp
                pcall(apply_viewmodel_suit, vm)
            end
            _suit_was_active = true
        end)


        local performance_tab = world_performance_tab
        local force_render_enabled = false
        performance_tab:AddToggle('force_render', { Text = 'Force Render All (3k)', Default = false, Callback = function(v)
            force_render_enabled = v
        end}):AddKeyPicker('force_render_bind', {Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Force Render'})

        local extreme_potato_mode = false
        performance_tab:AddToggle('extreme_potato_mode', { Text = 'Extreme Potato Mode', Default = false, Callback = function(v)
            extreme_potato_mode = v
            if v then
                pcall(function()
                    cheat.setTerrainDecoration(false)
                    workspace.Terrain.WaterWaveSize = 0
                    workspace.Terrain.WaterWaveSpeed = 0
                    workspace.Terrain.WaterReflectance = 0
                    workspace.Terrain.WaterTransparency = 0
                    game:GetService("Lighting").GlobalShadows = false
                    game:GetService("Lighting").FogEnd = 9e9
                    for _, obj in pairs(game:GetService("Lighting"):GetChildren()) do
                        if obj:IsA("PostEffect") or obj:IsA("Atmosphere") or obj:IsA("Sky") or obj:IsA("Clouds") then
                            obj.Enabled = false
                        end
                    end
                end)
                task.spawn(function()
                    local processed = 0
                    local stack = {workspace}
                    while #stack > 0 do
                        local parent = table.remove(stack)
                        for _, obj in ipairs(parent:GetChildren()) do
                            stack[#stack + 1] = obj
                            if not extreme_potato_mode then return end
                            if obj:IsA("BasePart") and not (obj.Parent and obj.Parent:FindFirstChild("Humanoid")) then
                                obj.Material = Enum.Material.SmoothPlastic
                                obj.Reflectance = 0
                                obj.CastShadow = false
                            elseif obj:IsA("Decal") or obj:IsA("Texture") then
                                obj.Transparency = 1
                            end
                            processed = processed + 1
                            if processed % 150 == 0 then
                                task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                            end
                        end
                    end
                end)
            end
        end});

        cheat.utility.track_connection(workspace.DescendantAdded:Connect(function(obj)
            if extreme_potato_mode then
                if obj:IsA("BasePart") and not (obj.Parent and obj.Parent:FindFirstChild("Humanoid")) then
                    obj.Material = Enum.Material.SmoothPlastic
                    obj.Reflectance = 0
                    obj.CastShadow = false
                elseif obj:IsA("Decal") or obj:IsA("Texture") then
                    obj.Transparency = 1
                end
            end
        end))

        task.spawn(function()
            local last_requested = {}
            while task.wait(0.5) do
                if feature_active(force_render_enabled, 'force_render_bind') then
                    local rp_players = ReplicatedStorage:FindFirstChild("Players")
                    local my_char = LocalPlayer.Character
                    local my_pos = my_char and my_char:FindFirstChild("HumanoidRootPart") and my_char.HumanoidRootPart.Position
                    
                    if rp_players and my_pos then
                        for _, p in pairs(Players:GetPlayers()) do
                            if p ~= LocalPlayer and (not p.Character or not p.Character:FindFirstChild("HumanoidRootPart")) then
                                local rp_plr = rp_players:FindFirstChild(p.Name)
                                local status = rp_plr and rp_plr:FindFirstChild("Status")
                                local uac = status and status:FindFirstChild("UAC")
                                local pos = uac and uac:GetAttribute("LastVerifiedPos")
                                
                                if pos and typeof(pos) == "Vector3" then
                                    local dist = (pos - my_pos).Magnitude
                                    if dist <= 12000 then -- 12000 studs ~ 3360m
                                        local now = tick()
                                        if not last_requested[p] or (now - last_requested[p] > 1.5) then
                                            last_requested[p] = now
                                            task.spawn(function()
                                                pcall(function()
                                                    LocalPlayer:RequestStreamAroundAsync(pos, 0.5)
                                                end)
                                            end)
                                            task.wait(0.2)
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end)
        local r52_0 = cheat.utility.track_instance(Instance.new("ScreenGui", game:GetService("CoreGui")))
        r52_0.Name = "EliteInventory"
        r52_0.Enabled = false
        r52_0.DisplayOrder = 999

        local MainFrame = Instance.new("Frame", r52_0)
        MainFrame.BackgroundColor3 = Color3.fromRGB(13, 17, 23)
        MainFrame.BorderSizePixel = 2
        MainFrame.BorderColor3 = Color3.fromRGB(40, 50, 70)
        MainFrame.Size = UDim2.new(0, 410, 0, 800)
        MainFrame.Position = UDim2.new(0, math.max(20, Camera.ViewportSize.X - 430), 0, 200)

        local MainScale = Instance.new("UIScale", MainFrame)
        MainScale.Name = "MainScale"

        local TopHeader = Instance.new("TextLabel", MainFrame)
        TopHeader.BackgroundTransparency = 1
        TopHeader.Position = UDim2.new(0, 15, 0, 15)
        TopHeader.Size = UDim2.new(1, -30, 0, 20)
        TopHeader.Font = Enum.Font.Arcade
        TopHeader.TextSize = 18
        TopHeader.TextColor3 = Color3.fromRGB(220, 230, 255)
        TopHeader.TextXAlignment = Enum.TextXAlignment.Left
        TopHeader.Text = "INVENTORY VIEWER"

        local TargetNameHeader = Instance.new("TextLabel", MainFrame)
        TargetNameHeader.BackgroundTransparency = 1
        TargetNameHeader.Position = UDim2.new(0, 15, 0, 40)
        TargetNameHeader.Size = UDim2.new(1, -30, 0, 20)
        TargetNameHeader.Font = Enum.Font.Arcade
        TargetNameHeader.TextSize = 16
        TargetNameHeader.TextColor3 = Color3.fromRGB(150, 160, 180)
        TargetNameHeader.TextXAlignment = Enum.TextXAlignment.Left
        TargetNameHeader.Text = ""

        local Divider = Instance.new("Frame", MainFrame)
        Divider.BackgroundColor3 = Color3.fromRGB(25, 30, 45)
        Divider.BorderSizePixel = 0
        Divider.Position = UDim2.new(0, 15, 0, 70)
        Divider.Size = UDim2.new(1, -30, 0, 2)

        local SubHeader = Instance.new("TextLabel", MainFrame)
        SubHeader.BackgroundTransparency = 1
        SubHeader.Position = UDim2.new(0, 15, 0, 80)
        SubHeader.Size = UDim2.new(1, -30, 0, 20)
        SubHeader.Font = Enum.Font.Arcade
        SubHeader.TextSize = 16
        SubHeader.TextColor3 = Color3.fromRGB(220, 230, 255)
        SubHeader.TextXAlignment = Enum.TextXAlignment.Left
        SubHeader.Text = "ITEMS"

        local GridContainer = Instance.new("ScrollingFrame", MainFrame)
        GridContainer.BackgroundTransparency = 1
        GridContainer.Position = UDim2.new(0, 15, 0, 110)
        GridContainer.Size = UDim2.new(1, -30, 1, -120)
        GridContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
        GridContainer.ScrollBarThickness = 4
        GridContainer.BorderSizePixel = 0
        
        local GridLayout = Instance.new("UIGridLayout", GridContainer)
        GridLayout.CellSize = UDim2.new(0, 88, 0, 88)
        GridLayout.CellPadding = UDim2.new(0, 8, 0, 8)
        GridLayout.SortOrder = Enum.SortOrder.LayoutOrder
        
        local is_dragging = false
        local drag_offset = Vector2.new(0, 0)
        
        cheat.utility.track_connection(MainFrame.InputBegan:Connect(function(input)
            if cheat.Toggles.inventoryviewer_drag.Value and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
                is_dragging = true
                drag_offset = input.Position - Vector3.new(MainFrame.AbsolutePosition.X, MainFrame.AbsolutePosition.Y, 0)
            end
        end))
        
        cheat.utility.track_connection(game:GetService("UserInputService").InputChanged:Connect(function(input)
            if is_dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local new_pos = input.Position - drag_offset
                cheat.Options.inventoryviewer_x:SetValue(new_pos.X)
                cheat.Options.inventoryviewer_y:SetValue(new_pos.Y)
            end
        end))
        
        cheat.utility.track_connection(game:GetService("UserInputService").InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                is_dragging = false
            end
        end))

        local inventory = {}
        function inventory:refresh() end
        local LastTargetInventory = nil
        
        local function formatMoney(amount)
            local formatted = tostring(amount)
            while true do  
                formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
                if (k==0) then break end
            end
            return formatted
        end

        function inventory:update(__obj)
            if not __obj then 
                r52_0.Enabled = false
                return 
            end
            r52_0.Enabled = false
            MainFrame.Position = UDim2.new(0, cheat.Options.inventoryviewer_x.Value, 0, cheat.Options.inventoryviewer_y.Value)
            local scale_obj = MainFrame:FindFirstChild("MainScale")
            if scale_obj then scale_obj.Scale = cheat.Options.inventoryviewer_scale.Value end
            
            local inv = __obj:FindFirstChild("Inventory")
            if not inv then
                local rp = ReplicatedStorage:FindFirstChild("Players")
                local rpp = rp and rp:FindFirstChild(__obj.Name)
                inv = rpp and rpp:FindFirstChild("Inventory")
            end

            if inv or not (LastTargetInventory == __obj) then
                local existing_cards = {}
                for _, child in pairs(GridContainer:GetChildren()) do
                    if child:IsA("Frame") then 
                        child.Visible = false
                        table.insert(existing_cards, child) 
                    end
                end
                
                local ItemsList = ReplicatedStorage:FindFirstChild("ItemsList")
                local itemCount = 0
                local val = 0
                
                if inv and ItemsList then
                    local function process_item(item_folder, hidden)
                        local n = string.lower(item_folder.Name)
                        if n:find("dagr") or n:find("keychain") or n:find("map") or n:find("lighter") or n:find("radio") or n:find("compass") or n:find("pathfinder") or n:find("dv%-2") or n:find("dv2") then return end
                        
                        local item_ref = ItemsList:FindFirstChild(item_folder.Name)
                        if item_ref and item_ref:FindFirstChild("ItemProperties") and item_ref:FindFirstChild("ItemProperties"):FindFirstChild("ItemIcon") then
                            local itype = item_ref.ItemProperties:GetAttribute("ItemType")
                            if itype == "Melee" or itype == "MeleeWeapon" then return end
                            
                            if item_folder.Name ~= "Rubles" then
                                local price = item_ref.ItemProperties:GetAttribute("Price") or 1
                                if price >= 10 then
                                    local itype = item_ref.ItemProperties:GetAttribute("ItemType")
                                    if itype == "Extra" then price = price * 0.4
                                    elseif itype == "Ammo" then price = price * (item_folder:GetAttribute("Amount") or 1) * 0.7
                                    elseif itype == "Clothing" then price = price * 0.35
                                    elseif itype == "Medical" then price = price * 0.75
                                    elseif itype == "Barter" then price = price * 0.4 end
                                end
                                val = val + price
                            else
                                val = val + (item_folder:GetAttribute("Amount") or 1)
                            end
                            
                            if hidden then return end
                            
                            itemCount = itemCount + 1
                            
                            local card = existing_cards[itemCount]
                            if not card then
                                card = Instance.new("Frame", GridContainer)
                                card.BackgroundColor3 = Color3.fromRGB(25, 30, 40)
                                card.BorderSizePixel = 1
                                card.BorderColor3 = Color3.fromRGB(40, 50, 70)
                                
                                local icon = Instance.new("ImageLabel", card)
                                icon.BackgroundTransparency = 1
                                icon.Size = UDim2.new(0.8, 0, 0.8, 0)
                                icon.Position = UDim2.new(0.1, 0, 0.05, 0)
                                icon.ScaleType = Enum.ScaleType.Fit
                                
                                local label = Instance.new("TextLabel", card)
                                label.BackgroundTransparency = 1
                                label.Position = UDim2.new(0, 5, 1, -15)
                                label.Size = UDim2.new(1, -10, 0, 15)
                                label.Font = Enum.Font.Arcade
                                label.TextSize = 12
                                label.TextColor3 = Color3.fromRGB(220, 230, 255)
                                label.TextXAlignment = Enum.TextXAlignment.Left
                            end
                            
                            card.LayoutOrder = itemCount
                            card.Visible = true
                            card:FindFirstChildOfClass("ImageLabel").Image = item_ref.ItemProperties.ItemIcon.Image
                            
                            local itemName = item_folder.Name:upper()
                            if #itemName > 12 then itemName = itemName:sub(1, 10) .. "..." end
                            card:FindFirstChildOfClass("TextLabel").Text = itemName
                        end
                    end

                    for _, slot in pairs(inv:GetChildren()) do
                        process_item(slot, false)
                        local slot_attr = slot:GetAttribute("Slot")
                        if slot_attr and slot_attr:find("Clothing") and slot:FindFirstChild("Inventory") then
                            if inv_show_full then
                                for _, sub_item in pairs(slot.Inventory:GetChildren()) do
                                    process_item(sub_item, false)
                                end
                            end
                        elseif slot:FindFirstChild("Attachments") then
                            for _, att in pairs(slot.Attachments:GetChildren()) do
                                process_item(att, true)
                            end
                        end
                    end
                end
                
                val = math.floor(val)
                TopHeader.Text = "INVENTORY VIEWER - " .. itemCount .. " ITEMS" .. (inv_show_value and (", $" .. formatMoney(val)) or "")
                TargetNameHeader.Text = __obj.Name:upper()
                SubHeader.Text = "ITEMS (" .. itemCount .. ")"
                
                local rows = math.ceil(itemCount / 4)
                GridContainer.CanvasSize = UDim2.new(0, 0, 0, rows * 96)
                MainFrame.Size = UDim2.new(0, 410, 0, math.clamp(130 + rows * 96, 300, 900))
            end
            LastTargetInventory = __obj
        end
        local ghost_inventory_gui = cheat.utility.track_instance(Instance.new("ScreenGui", game:GetService("CoreGui")))
        ghost_inventory_gui.Name = "GhostHookInventoryChecker"
        ghost_inventory_gui.ResetOnSpawn = false
        ghost_inventory_gui.IgnoreGuiInset = true
        ghost_inventory_gui.DisplayOrder = 1001

        local inventoryViewerTitle = Instance.new("TextLabel", ghost_inventory_gui)
        inventoryViewerTitle.Size = UDim2.new(0.28, 0, 0, 24)
        inventoryViewerTitle.Position = UDim2.new(0.5, 0, 0, 54)
        inventoryViewerTitle.AnchorPoint = Vector2.new(0.5, 0.5)
        inventoryViewerTitle.BackgroundTransparency = 1
        inventoryViewerTitle.TextColor3 = inventory_checker.title_color
        inventoryViewerTitle.Font = Enum.Font.GothamSemibold
        inventoryViewerTitle.Visible = false
        inventoryViewerTitle.TextScaled = true

        local equippedItemIcons = {}
        local attachmentIcons = {}
        local fullInventoryIcons = {}
        local fullInventoryCounts = {}
        local blank_icon = "rbxassetid://12459616555"
        local fullInventoryGrid = {
            pos = nil,
            dragging = false,
            drag_offset = Vector2.zero,
            width = (6 * 35 + 5 * 6),
            height = (9 * 35 + 8 * 5),
            y = 170,
        }

        local function make_inv_icon(size, bg, transparency)
            local icon = Instance.new("ImageLabel", ghost_inventory_gui)
            icon.Visible = false
            icon.Size = UDim2.new(0, size.X, 0, size.Y)
            icon.BackgroundTransparency = transparency
            icon.BackgroundColor3 = bg
            icon.BorderSizePixel = 0
            icon.ScaleType = Enum.ScaleType.Fit
            icon.Image = blank_icon
            local corner = Instance.new("UICorner", icon)
            corner.CornerRadius = UDim.new(0, 8)
            return icon
        end

        -- Main hotbar background image (12 slots)
        inventory_checker.hotbarBg = Instance.new("ImageLabel", ghost_inventory_gui)
        inventory_checker.hotbarBg.Visible = false
        inventory_checker.hotbarBg.BackgroundTransparency = 1
        inventory_checker.hotbarBg.BorderSizePixel = 0
        inventory_checker.hotbarBg.Image = "rbxassetid://92676808440819"
        inventory_checker.hotbarBg.ScaleType = Enum.ScaleType.Stretch
        inventory_checker.hotbarBg.ZIndex = 0

        for i = 1, 12 do
            -- Make slots fully transparent so the hotbar image shows through
            equippedItemIcons[i] = make_inv_icon(Vector2.new(54, 54), Color3.fromRGB(30, 30, 30), 1)
            equippedItemIcons[i].ZIndex = 1
            -- Make attachment icons fully transparent (mini hotbar image will be the background)
            attachmentIcons[i] = make_inv_icon(Vector2.new(16, 18), Color3.fromRGB(155, 30, 30), 1)
            attachmentIcons[i].ZIndex = 2
        end

        -- 3 mini 4-slot attachment hotbar images (no clipping needed, it's a 4-slot asset)
        inventory_checker.attachHotbarBg = {}
        for j = 1, 3 do
            local ab = Instance.new("ImageLabel", ghost_inventory_gui)
            ab.Visible = false
            ab.BackgroundTransparency = 1
            ab.BorderSizePixel = 0
            ab.Image = "rbxassetid://129527357489083"
            ab.ScaleType = Enum.ScaleType.Stretch
            ab.ZIndex = 0
            inventory_checker.attachHotbarBg[j] = ab
        end
        for i = 1, 54 do
            fullInventoryIcons[i] = make_inv_icon(Vector2.new(35, 35), Color3.fromRGB(0, 0, 0), 0.35)
            local count = Instance.new("TextLabel", ghost_inventory_gui)
            count.Visible = false
            count.Text = ""
            count.TextScaled = true
            count.Size = UDim2.new(0, 24, 0, 15)
            count.BackgroundTransparency = 1
            count.TextColor3 = Color3.fromRGB(255, 255, 255)
            count.Font = Enum.Font.GothamSemibold
            count.ZIndex = 3
            fullInventoryCounts[i] = count
        end

        local fullInventoryDragFrame = Instance.new("Frame", ghost_inventory_gui)
        fullInventoryDragFrame.Visible = false
        fullInventoryDragFrame.Active = true
        fullInventoryDragFrame.BackgroundTransparency = 1
        fullInventoryDragFrame.BorderSizePixel = 0
        fullInventoryDragFrame.ZIndex = 1

        local function beginFullInventoryDrag(input)
            if not (inventory_checker.full and fullInventoryDragFrame.Visible) then return end
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fullInventoryGrid.dragging = true
                fullInventoryGrid.drag_offset = _Vector2new(input.Position.X, input.Position.Y) - fullInventoryGrid.pos
            end
        end

        cheat.utility.track_connection(fullInventoryDragFrame.InputBegan:Connect(beginFullInventoryDrag))
        for i = 1, 54 do
            fullInventoryIcons[i].Active = true
            fullInventoryCounts[i].Active = true
            cheat.utility.track_connection(fullInventoryIcons[i].InputBegan:Connect(beginFullInventoryDrag))
            cheat.utility.track_connection(fullInventoryCounts[i].InputBegan:Connect(beginFullInventoryDrag))
        end

        cheat.utility.track_connection(UserInputService.InputChanged:Connect(function(input)
            if not fullInventoryGrid.dragging then return end
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                fullInventoryGrid.pos = _Vector2new(input.Position.X, input.Position.Y) - fullInventoryGrid.drag_offset
            end
        end))

        cheat.utility.track_connection(UserInputService.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                fullInventoryGrid.dragging = false
            end
        end))

        local function positionInventoryViewer()
            local BAR_W       = 822  -- Original size!
            local BAR_H       = 64   -- Original size!
            local SLOT_SZ     = 54   -- Original size!
            local BAR_Y       = 82

            local vp     = Camera.ViewportSize
            local base_x = (vp.X - BAR_W) / 2

            -- Main hotbar background
            inventory_checker.hotbarBg.Size     = UDim2.new(0, BAR_W, 0, BAR_H)
            inventory_checker.hotbarBg.Position = UDim2.new(0, base_x, 0, BAR_Y)

            -- MANUAL EXACT OFFSETS FOR EACH SLOT'S CENTER
            -- Perfectly mathematically spaced for an 822px wide bar (68.5px stride)
            -- If ANY item looks off, literally just change its number here!
            local slot_centers = {
                34,   -- Slot 1
                103,  -- Slot 2
                171,  -- Slot 3
                240,  -- Slot 4
                308,  -- Slot 5
                377,  -- Slot 6
                445,  -- Slot 7
                514,  -- Slot 8
                582,  -- Slot 9
                651,  -- Slot 10
                719,  -- Slot 11
                788   -- Slot 12
            }

            for i = 1, 12 do
                local slot_center = base_x + slot_centers[i]
                equippedItemIcons[i].Size     = UDim2.new(0, SLOT_SZ, 0, SLOT_SZ)
                equippedItemIcons[i].Position = UDim2.new(0, slot_center - SLOT_SZ/2, 0, BAR_Y + (BAR_H - SLOT_SZ)/2)
            end

            -- Mini bars: 4 slots each
            local MINI_W       = 64 -- Sized beautifully under the 68.5px main slots
            local MINI_H       = 16
            local MINI_SLOT_SZ = 12
            
            local att_y = BAR_Y + BAR_H + 4

            for j = 1, 3 do
                -- Center mini bar exactly under weapon slot j
                local parent_slot_center = base_x + slot_centers[j]
                local mini_x  = parent_slot_center - MINI_W/2

                inventory_checker.attachHotbarBg[j].Size     = UDim2.new(0, MINI_W, 0, MINI_H)
                inventory_checker.attachHotbarBg[j].Position = UDim2.new(0, mini_x, 0, att_y)

                -- 4 attachment icons evenly spaced inside the 64px mini bar
                local inner_w = MINI_W - 2
                local mini_stride = inner_w / 4
                for ai = 0, 3 do
                    local idx = (j-1)*4 + ai + 1
                    local icon_center = mini_x + 1 + (ai + 0.5) * mini_stride
                    attachmentIcons[idx].Size     = UDim2.new(0, MINI_SLOT_SZ, 0, MINI_SLOT_SZ)
                    attachmentIcons[idx].Position = UDim2.new(0, icon_center - MINI_SLOT_SZ/2, 0, att_y + (MINI_H - MINI_SLOT_SZ)/2)
                end
            end

            -- Full inventory grid
            if not fullInventoryGrid.pos then
                fullInventoryGrid.pos = _Vector2new(math.max(12, vp.X - fullInventoryGrid.width - 24), fullInventoryGrid.y)
            end
            local max_x = math.max(0, vp.X - fullInventoryGrid.width - 4)
            local max_y = math.max(0, vp.Y - fullInventoryGrid.height - 4)
            fullInventoryGrid.pos = _Vector2new(
                math.clamp(fullInventoryGrid.pos.X, 0, max_x),
                math.clamp(fullInventoryGrid.pos.Y, 0, max_y)
            )
            fullInventoryDragFrame.Position = UDim2.new(0, fullInventoryGrid.pos.X, 0, fullInventoryGrid.pos.Y)
            fullInventoryDragFrame.Size     = UDim2.new(0, fullInventoryGrid.width, 0, fullInventoryGrid.height)

            for i = 1, 54 do
                local col = (i-1) % 6
                local row = math.floor((i-1) / 6)
                local x   = fullInventoryGrid.pos.X + col * 41
                local y   = fullInventoryGrid.pos.Y + row * 40
                fullInventoryIcons[i].Position  = UDim2.new(0, x, 0, y)
                fullInventoryCounts[i].Position = UDim2.new(0, x+13, 0, y+23)
            end
        end


        local inventoryViewerCache = {
            LastVisibility = false,
            LastVisibleFull = false,
            LastTargetInventory = nil,
            LastTargetValueName = nil,
            LastTargetValue = 0,
            CurrentTarget = nil,
            LastTargetSearch = 0,
            LastRender = 0,
            LastFullState = nil,
        }

        local function setInventoryVisibility(visible)
            local show_full = visible and inventory_checker.full
            if inventoryViewerCache.LastVisibility == visible and inventoryViewerCache.LastVisibleFull == show_full then return end
            inventoryViewerCache.LastVisibility = visible
            inventoryViewerCache.LastVisibleFull = show_full
            inventory_checker.hotbarBg.Visible = visible
            for j = 1, 3 do
                inventory_checker.attachHotbarBg[j].Visible = visible
            end
            for i = 1, 12 do
                equippedItemIcons[i].Visible = visible
                attachmentIcons[i].Visible = visible
            end
            for i = 1, 54 do
                fullInventoryIcons[i].Visible = show_full
                fullInventoryCounts[i].Visible = show_full
            end
            fullInventoryDragFrame.Visible = show_full
        end

        local function getInventoryContainer(target)
            if not target then return nil end
            if target:IsA("Player") then
                local folder = ReplicatedStorage:FindFirstChild("Players")
                local player_folder = folder and folder:FindFirstChild(target.Name)
                return player_folder and player_folder:FindFirstChild("Inventory")
            end
            if target:IsA("Model") and target:FindFirstChildOfClass("Humanoid") and target:FindFirstChild("Inventory") then
                return target.Inventory
            end
            local folder = ReplicatedStorage:FindFirstChild("Players")
            local player_folder = folder and folder:FindFirstChild(target.Name)
            return player_folder and player_folder:FindFirstChild("Inventory")
        end

        local function getItemIcon(item_name)
            local ItemsList = ReplicatedStorage:FindFirstChild("ItemsList")
            local ref = ItemsList and ItemsList:FindFirstChild(item_name)
            local props = ref and ref:FindFirstChild("ItemProperties")
            local icon = props and props:FindFirstChild("ItemIcon")
            return icon and icon.Image or blank_icon
        end

        local function renderInventoryViewer(target)
            local inv = getInventoryContainer(target)
            if not inv then return false end
            for i = 1, 12 do
                equippedItemIcons[i].Image = blank_icon
                attachmentIcons[i].Image = blank_icon
            end
            for i = 1, 54 do
                fullInventoryIcons[i].Image = blank_icon
                fullInventoryCounts[i].Text = ""
            end

            local clothing_index = 4
            local weapon_index = 1
            local attach_base = 0
            for _, item in pairs(inv:GetChildren()) do
                local slot = item:GetAttribute("Slot")
                if slot and slot:find("Clothing") then
                    if clothing_index <= 12 then
                        equippedItemIcons[clothing_index].Image = getItemIcon(item.Name)
                        clothing_index = clothing_index + 1
                    end
                elseif item:FindFirstChild("Attachments") then
                    if weapon_index <= 3 then
                        equippedItemIcons[weapon_index].Image = getItemIcon(item.Name)
                        for _, attachment in pairs(item.Attachments:GetChildren()) do
                            local attachment_slot = attachment:GetAttribute("Slot")
                            local attachment_index
                            if attachment_slot == "Magazine" then attachment_index = 1
                            elseif attachment_slot == "Sight" then attachment_index = 2
                            elseif attachment_slot == "Muzzle" then attachment_index = 3
                            elseif attachment_slot == "Extra" then attachment_index = 4 end
                            if attachment_index and attachmentIcons[attach_base + attachment_index] then
                                attachmentIcons[attach_base + attachment_index].Image = getItemIcon(attachment.Name)
                            end
                        end
                        weapon_index = weapon_index + 1
                        attach_base = attach_base + 4
                    end
                end
            end

            if inventory_checker.full then
                local index = 1
                for _, slot in pairs(inv:GetChildren()) do
                    local slot_inv = slot:FindFirstChild("Inventory")
                    if slot_inv and slot.Name ~= "KeyChain" then
                        for _, item in pairs(slot_inv:GetChildren()) do
                            if index > 54 then break end
                            local amount = item:GetAttribute("Amount") or 1
                            fullInventoryIcons[index].Image = getItemIcon(item.Name)
                            fullInventoryCounts[index].Text = amount >= 1000 and (math.floor(amount / 1000) .. "K") or ("x" .. amount)
                            index = index + 1
                        end
                    end
                    if index > 54 then break end
                end
            end
            inventoryViewerCache.LastTargetInventory = target
            return true
        end

        local function estimateInventoryValue(target)
            if inventoryViewerCache.LastTargetValueName == target.Name then
                return inventoryViewerCache.LastTargetValue
            end
            local inv = getInventoryContainer(target)
            local ItemsList = ReplicatedStorage:FindFirstChild("ItemsList")
            local total = 0
            if inv and ItemsList then
                for _, slot in pairs(inv:GetChildren()) do
                    local slot_inv = slot:FindFirstChild("Inventory")
                    if slot_inv then
                        for _, item in pairs(slot_inv:GetChildren()) do
                            local ref = ItemsList:FindFirstChild(item.Name)
                            local props = ref and ref:FindFirstChild("ItemProperties")
                            if props then
                                if item.Name == "Rubles" then
                                    total = total + (item:GetAttribute("Amount") or 1)
                                else
                                    local price = props:GetAttribute("Price") or 1
                                    if price >= 10 then
                                        local item_type = props:GetAttribute("ItemType")
                                        if item_type == "Extra" then price = price * 0.4
                                        elseif item_type == "Ammo" then price = price * (item:GetAttribute("Amount") or 1) * 0.7
                                        elseif item_type == "Clothing" then price = price * 0.35
                                        elseif item_type == "Medical" then price = price * 0.75
                                        elseif item_type == "Barter" then price = price * 0.4 end
                                    end
                                    total = total + price
                                end
                            end
                        end
                    end
                end
            end
            inventoryViewerCache.LastTargetValueName = target.Name
            inventoryViewerCache.LastTargetValue = math.floor(total)
            return inventoryViewerCache.LastTargetValue
        end

        local function findInventoryCheckTarget()
            if silent_aim.target_part and silent_aim.target_part.Parent then
                local player = Players:GetPlayerFromCharacter(silent_aim.target_part.Parent)
                if player then return player end
            end
            local best, best_dist = nil, math.huge
            local center = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            for _, player in ipairs(Players:GetPlayers()) do
                local char = player.Character
                local head = char and char:FindFirstChild("Head")
                local humanoid = char and char:FindFirstChildOfClass("Humanoid")
                if player ~= LocalPlayer and head and humanoid and humanoid.Health > 0 then
                    local screen, onscreen = Camera:WorldToViewportPoint(head.Position)
                    if onscreen and screen.Z > 0 then
                        local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                        if dist < best_dist then
                            best = player
                            best_dist = dist
                        end
                    end
                end
            end
            if inventory_checker.corpse then
                local dropped = workspace:FindFirstChild("DroppedItems")
                if dropped then
                    for _, corpse in ipairs(dropped:GetChildren()) do
                        local head = corpse:FindFirstChild("Head")
                        if corpse:FindFirstChildOfClass("Humanoid") and head and not corpse:FindFirstChild("AttackedBy") then
                            local screen, onscreen = Camera:WorldToViewportPoint(head.Position)
                            if onscreen and screen.Z > 0 then
                                local dist = (Vector2.new(screen.X, screen.Y) - center).Magnitude
                                if dist < best_dist then
                                    best = corpse
                                    best_dist = dist
                                end
                            end
                        end
                    end
                end
            end
            return best
        end

        local function updateGhostInventoryViewer()
            if cheat.utility.is_game_inventory_preview_open and cheat.utility.is_game_inventory_preview_open() then
                setInventoryVisibility(false)
                inventoryViewerTitle.Visible = false
                return
            end
            if not feature_active(inventory_checker.enabled, 'inventorychecker_bind') then
                setInventoryVisibility(false)
                inventoryViewerTitle.Visible = false
                return
            end
            positionInventoryViewer()
            local now = tick()
            local cached_target = inventoryViewerCache.CurrentTarget
            local target_missing = not cached_target or (cached_target:IsA("Model") and not cached_target.Parent)
            if now - inventoryViewerCache.LastTargetSearch > 0.08 or target_missing then
                inventoryViewerCache.LastTargetSearch = now
                inventoryViewerCache.CurrentTarget = findInventoryCheckTarget()
            end
            local target = inventoryViewerCache.CurrentTarget
            local needs_render = target ~= inventoryViewerCache.LastTargetInventory
                or inventoryViewerCache.LastFullState ~= inventory_checker.full
                or now - inventoryViewerCache.LastRender > 0.12

            if not target or (needs_render and not renderInventoryViewer(target)) then
                setInventoryVisibility(false)
                inventoryViewerTitle.Visible = false
                return
            end
            if needs_render then
                inventoryViewerCache.LastRender = now
                inventoryViewerCache.LastFullState = inventory_checker.full
            end
            setInventoryVisibility(true)
            if inventory_checker.target or inventory_checker.value then
                local kind = target:IsA("Model") and " | Corpse " or " | Inventory "
                if inventory_checker.target and inventory_checker.value then
                    inventoryViewerTitle.Text = "Viewing " .. target.Name .. kind .. "| $" .. formatMoney(estimateInventoryValue(target))
                elseif inventory_checker.target then
                    inventoryViewerTitle.Text = "Viewing " .. target.Name .. kind
                else
                    inventoryViewerTitle.Text = "$" .. formatMoney(estimateInventoryValue(target))
                end
                inventoryViewerTitle.TextColor3 = inventory_checker.title_color
                inventoryViewerTitle.Visible = true
            else
                inventoryViewerTitle.Visible = false
            end
        end
        vmpos = function(vm)
            if not vm then return end
            local hrp = vm:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            local changer_enabled = Toggles.viewmodel_changer and Toggles.viewmodel_changer.Value
            local vec = changer_enabled and Vector3.new(cheat.Options.viewmodel_x.Value, cheat.Options.viewmodel_y.Value, cheat.Options.viewmodel_z.Value) or Vector3.zero
            local function apply_joint(name)
                local joint = hrp:FindFirstChild(name)
                if joint and joint:IsA("Motor6D") then
                    local orig = joint:GetAttribute("OriginalC0")
                    if not orig then
                        orig = joint.C0
                        joint:SetAttribute("OriginalC0", orig)
                    end
                    joint.C0 = orig + vec
                end
            end
            apply_joint("LeftUpperArm")
            apply_joint("RightUpperArm")
            apply_joint("ItemRoot")
            apply_joint("Motor6D")
        end
        cheat.utility.restore_viewmodel = function()
            local vm = _FindFirstChildOfClass(Camera, "Model")
            if not vm then return end
            local hrp = vm:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            for _, name in ipairs({"LeftUpperArm", "RightUpperArm", "ItemRoot", "Motor6D"}) do
                local joint = hrp:FindFirstChild(name)
                if joint and joint:IsA("Motor6D") then
                    local orig = joint:GetAttribute("OriginalC0")
                    if orig then
                        joint.C0 = orig
                    end
                end
            end
        end
        cheat._last_vm_item = cheat._last_vm_item or nil
        cheat._last_vm_update = cheat._last_vm_update or 0
        cheat._is_chamming = false
        cheat._chams_originals = cheat._chams_originals or {
            viewmodel = {},
            character = {},
        }
        local function remember_cham_part(scope, part)
            if not (scope and part and (part:IsA("BasePart") or part:IsA("MeshPart"))) then return end
            local bucket = cheat._chams_originals[scope]
            if not bucket then
                bucket = {}
                cheat._chams_originals[scope] = bucket
            end
            if bucket[part] then return end
            local surface = part:FindFirstChildOfClass("SurfaceAppearance")
            bucket[part] = {
                Color = part.Color,
                Material = part.Material,
                Transparency = part.Transparency,
                TextureID = part:IsA("MeshPart") and part.TextureID or nil,
                SurfaceAppearance = surface and surface:Clone() or nil,
            }
        end
        local function remember_cham_clothing(scope, item)
            if not scope or not item then return end
            local bucket = cheat._chams_originals[scope]
            if not bucket then
                bucket = {}
                cheat._chams_originals[scope] = bucket
            end
            if bucket[item] then return end
            if item:IsA("Shirt") then
                bucket[item] = { ShirtTemplate = item.ShirtTemplate }
            elseif item:IsA("Pants") then
                bucket[item] = { PantsTemplate = item.PantsTemplate }
            elseif item:IsA("ShirtGraphic") then
                bucket[item] = { Graphic = item.Graphic }
            end
        end
        local function restore_chams_scope(scope)
            local bucket = cheat._chams_originals and cheat._chams_originals[scope]
            if not bucket then return end
            for object, original in pairs(bucket) do
                pcall(function()
                    if object and object.Parent then
                        if object:IsA("BasePart") or object:IsA("MeshPart") then
                            object.Color = original.Color
                            object.Material = original.Material
                            object.Transparency = original.Transparency
                            if object:IsA("MeshPart") and original.TextureID ~= nil then
                                object.TextureID = original.TextureID
                            end
                            if original.SurfaceAppearance and not object:FindFirstChildOfClass("SurfaceAppearance") then
                                original.SurfaceAppearance:Clone().Parent = object
                            end
                        elseif object:IsA("Shirt") and original.ShirtTemplate ~= nil then
                            object.ShirtTemplate = original.ShirtTemplate
                        elseif object:IsA("Pants") and original.PantsTemplate ~= nil then
                            object.PantsTemplate = original.PantsTemplate
                        elseif object:IsA("ShirtGraphic") and original.Graphic ~= nil then
                            object.Graphic = original.Graphic
                        end
                    end
                end)
                bucket[object] = nil
            end
        end
        cheat.utility.restore_chams = function()
            restore_chams_scope("viewmodel")
            restore_chams_scope("character")
        end
        local function apply_cham_part(scope, part, color, materialName, transparency, clear_texture)
            if not (part and (part:IsA("BasePart") or part:IsA("MeshPart"))) then return end
            remember_cham_part(scope, part)
            part.Material = Enum.Material[materialName] or part.Material
            part.Color = color
            part.Transparency = transparency
            if clear_texture and part:IsA("MeshPart") then part.TextureID = "" end
            local sa = part:FindFirstChildOfClass("SurfaceAppearance")
            if sa then sa:Destroy() end
        end
        local function is_arm_cham_part(part)
            local name = tostring(part and part.Name or ""):lower():gsub("[%s_%-]", "")
            return name == "lefthand"
                or name == "righthand"
                or name == "leftarm"
                or name == "rightarm"
                or name == "leftupperarm"
                or name == "rightupperarm"
                or name == "leftlowerarm"
                or name == "rightlowerarm"
                or name:match("^left.*hand$")
                or name:match("^right.*hand$")
                or name:match("^left.*arm$")
                or name:match("^right.*arm$")
        end
        vmchams = function(force) LPH_JIT_MAX(function()
            if cheat._is_chamming then return end
            local vm = _FindFirstChildOfClass(Camera, "Model")
            if not vm then return end
            local ItemView = _FindFirstChild(vm, "Item")
            if not force and ItemView == cheat._last_vm_item and tick() - cheat._last_vm_update < 0.5 then return end
            cheat._last_vm_item = ItemView
            cheat._last_vm_update = tick()
            cheat._is_chamming = true
            task.spawn(function()
                if not vm.Parent then cheat._is_chamming = false return end
                local guncolor = cheat.Options.gcc.Value
                local gunmaterial = cheat.Options.gcm.Value
                local armcolor = cheat.Options.acc.Value
                local armmaterial = cheat.Options.acm.Value
                if ItemView and Toggles.gm.Value then
                    for _, v in pairs(ItemView:GetDescendants()) do
                        if (v:IsA("MeshPart") or v:IsA("BasePart")) and v.Transparency < 1 and v.Name ~= "Muzzle" and v.Name ~= "SightMark" and v.Name ~= "AimPart" and v.Name ~= "SmokePart" and v.Name ~= "FirePoint" and v.Name ~= "Flash" and v.Name ~= "Flame" then
                            apply_cham_part("viewmodel", v, guncolor, gunmaterial, cheat._gun_chams_transparency, false)
                        end
                    end
                elseif not (Toggles.ac.Value or Toggles.noarms.Value) then
                    restore_chams_scope("viewmodel")
                end
                if Toggles.noarms.Value then
                    for _, vm_item in pairs(vm:GetChildren()) do
                        if vm_item:IsA("MeshPart") then
                            if vm_item.Name:find("Hand") or vm_item.Name:find("Arm") then
                                remember_cham_part("viewmodel", vm_item)
                                vm_item.Transparency = 1
                            end
                        elseif vm_item:IsA("Model") and (_FindFirstChild(vm_item, "LL") or _FindFirstChild(vm_item, "LH")) then
                            for _, shirt_item in pairs(vm_item:GetChildren()) do
                                remember_cham_part("viewmodel", shirt_item)
                                shirt_item.Transparency = 1
                            end
                        end
                    end
                else
                    -- Restore normal transparency if noarms is off
                    for _, vm_item in pairs(vm:GetChildren()) do
                        if vm_item:IsA("MeshPart") then
                            if vm_item.Name:find("Hand") or vm_item.Name:find("Arm") then
                                vm_item.Transparency = 0
                            end
                        elseif vm_item:IsA("Model") and (_FindFirstChild(vm_item, "LL") or _FindFirstChild(vm_item, "LH")) then
                            for _, shirt_item in pairs(vm_item:GetChildren()) do
                                shirt_item.Transparency = 0
                            end
                        end
                    end
                end
                if Toggles.ac.Value and not Toggles.noarms.Value then
                    for _, vm_item in pairs(vm:GetChildren()) do
                    if vm_item:IsA("MeshPart") then
                        if vm_item.Name:find("Hand") or vm_item.Name:find("Arm") then
                                apply_cham_part("viewmodel", vm_item, armcolor, armmaterial, cheat._arm_chams_transparency, false)
                            end
                        elseif vm_item:IsA("Model") and (_FindFirstChild(vm_item, "LL") or _FindFirstChild(vm_item, "LH")) then
                            for _, shirt_item in pairs(vm_item:GetChildren()) do
                                apply_cham_part("viewmodel", shirt_item, armcolor, armmaterial, cheat._arm_chams_transparency, false)
                            end
                        end
                    end
                end
                cheat._is_chamming = false
            end)
        end)() end
        cheat.utility.track_connection(Camera.ChildAdded:Connect(function(child)
            local viewmodel_enabled = (Toggles.viewmodel_changer and Toggles.viewmodel_changer.Value) or Toggles.gm.Value or Toggles.ac.Value or Toggles.noarms.Value
            if not viewmodel_enabled then return end
            task.spawn(function()
                if child:IsA("Model") then
                    child:WaitForChild("HumanoidRootPart", 1)
                    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                    vmpos(child)
                end
            end)
            if child:IsA("Model") then
                vmchams(true)
            end
        end))
        cheat.utility.track_connection(Camera.DescendantAdded:Connect(function()
            if Toggles.gm.Value or Toggles.ac.Value or Toggles.noarms.Value then
                vmchams()
            end
        end))
        cheat._last_character_chams_update = cheat._last_character_chams_update or 0
        cheat.utility.new_heartbeat(function()
            local viewmodel_chams_enabled = Toggles.gm.Value or Toggles.ac.Value or Toggles.noarms.Value
            local character_chams_enabled = Toggles.bc.Value
            local viewmodel_enabled = (Toggles.viewmodel_changer and Toggles.viewmodel_changer.Value) or viewmodel_chams_enabled
            if not (viewmodel_enabled or character_chams_enabled) then
                restore_chams_scope("viewmodel")
                restore_chams_scope("character")
                return
            end

            local vm = _FindFirstChildOfClass(Camera, "Model")
            if vm and viewmodel_enabled then vmpos(vm) end
            
            local char = LocalPlayer.Character
            if char and character_chams_enabled and tick() - cheat._last_character_chams_update > 0.2 then
                cheat._last_character_chams_update = tick()
                local guncolor = cheat.Options.gcc.Value
                local gunmaterial = cheat.Options.gcm.Value
                local armcolor = cheat.Options.acc.Value
                local armmaterial = cheat.Options.acm.Value
                local bodycolor = cheat.Options.bcc.Value
                local bodymaterial = cheat.Options.bcm.Value
                for _, v in pairs(char:GetChildren()) do
                    if Toggles.bc.Value and v:IsA("Shirt") then
                        remember_cham_clothing("character", v)
                        v.ShirtTemplate = ""
                    elseif Toggles.bc.Value and v:IsA("Pants") then
                        remember_cham_clothing("character", v)
                        v.PantsTemplate = ""
                    elseif Toggles.bc.Value and v:IsA("ShirtGraphic") then
                        remember_cham_clothing("character", v)
                        v.Graphic = ""
                    end
                end
                for _, v in pairs(char:GetDescendants()) do
                    if v:IsA("BasePart") or v:IsA("MeshPart") then
                        local is_weapon = v:FindFirstAncestor("Item") or v:FindFirstAncestor("Weapon") or v.Name:find("Gun") or v.Name:find("Handle")
                        if Toggles.bc.Value and not is_arm_cham_part(v) and not is_weapon then
                            if v.Color ~= bodycolor or v.Material ~= Enum.Material[bodymaterial] or (v:IsA("MeshPart") and v.TextureID ~= "") then
                                apply_cham_part("character", v, bodycolor, bodymaterial, cheat._body_chams_transparency, true)
                            end
                        end
                    end
                end
            elseif not character_chams_enabled then
                restore_chams_scope("character")
            end
            if viewmodel_chams_enabled then
                vmchams()
            else
                restore_chams_scope("viewmodel")
            end
        end)
        cheat._screen_effect_original_visible = cheat._screen_effect_original_visible or {}
        cheat._last_screen_effects_lookup = 0
        cheat.utility.apply_no_screen_effects = function(enabled)
            local effects = LocalPlayer.PlayerGui
                and _FindFirstChild(LocalPlayer.PlayerGui, "NoInsetGui")
                and _FindFirstChild(_FindFirstChild(LocalPlayer.PlayerGui, "NoInsetGui"), "MainFrame")
                and _FindFirstChild(_FindFirstChild(_FindFirstChild(LocalPlayer.PlayerGui, "NoInsetGui"), "MainFrame"), "ScreenEffects")
            cheat._cached_screen_effects = effects

            if effects then
                if enabled then
                    for _, name in ipairs({"Visor", "HelmetMask", "Mask", "Flashbang"}) do
                        local child = effects:FindFirstChild(name)
                        if child then
                            if cheat._screen_effect_original_visible[child] == nil then
                                cheat._screen_effect_original_visible[child] = child.Visible
                            end
                            child.Visible = false
                        end
                    end
                    effects.Visible = false
                else
                    effects.Visible = true
                    for child, was_visible in pairs(cheat._screen_effect_original_visible) do
                        if child and child.Parent then
                            child.Visible = was_visible
                        end
                        cheat._screen_effect_original_visible[child] = nil
                    end
                end
            end

            local blur = Lighting:FindFirstChild("InventoryBlur")
            if blur and blur:IsA("BlurEffect") then
                cheat._inventory_blur_original_size = cheat._inventory_blur_original_size or blur.Size
                blur.Size = enabled and 0 or cheat._inventory_blur_original_size
            end

            local static_lcd = Camera:FindFirstChild("ViewModel")
                and Camera.ViewModel:FindFirstChild("Item")
                and Camera.ViewModel.Item:FindFirstChild("Attachments")
                and Camera.ViewModel.Item.Attachments:FindFirstChild("Sight")
                and Camera.ViewModel.Item.Attachments.Sight:FindFirstChild("Reapir")
                and Camera.ViewModel.Item.Attachments.Sight.Reapir:FindFirstChild("Reticle")
                and Camera.ViewModel.Item.Attachments.Sight.Reapir.Reticle:FindFirstChild("PrismScopeGui")
                and Camera.ViewModel.Item.Attachments.Sight.Reapir.Reticle.PrismScopeGui:FindFirstChild("Sight")
                and Camera.ViewModel.Item.Attachments.Sight.Reapir.Reticle.PrismScopeGui.Sight:FindFirstChild("StaticLCD")
            if static_lcd then
                static_lcd.Visible = not enabled
            end
        end

        cheat._noscreenfx_last = false
        cheat.utility.new_renderstepped(LPH_JIT_MAX(function()
            local noscreen_enabled = cheat.Toggles.noscreenfx and cheat.Toggles.noscreenfx.Value
            if noscreen_enabled ~= cheat._noscreenfx_last then
                cheat._last_screen_effects_lookup = tick()
                cheat.utility.apply_no_screen_effects(noscreen_enabled)
                cheat._noscreenfx_last = noscreen_enabled
            elseif noscreen_enabled then
                if tick() - cheat._last_screen_effects_lookup > 0.25 or not (cheat._cached_screen_effects and cheat._cached_screen_effects.Parent) then
                    cheat._last_screen_effects_lookup = tick()
                    cheat.utility.apply_no_screen_effects(noscreen_enabled)
                end
            end
            if inventory_checker.enabled or inventoryViewerTitle.Visible then
                updateGhostInventoryViewer()
            end
        end))
    end
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local mvb = ui.box.move:AddTab('Character')
        local speed_enabled, speed = false, 55
        local omni_sprint = false
        local tp_enabled, tp_dist = false, 10
        local jesus_enabled = false
        local water_part = nil
        local thirdperson_locked_mouse = false
        local thirdperson_was_active = false
        local thirdperson_paused_for_inventory = false
        local function thirdperson_active()
            return feature_active(tp_enabled, 'thirdperson_bind', false, false)
        end
        mvb:AddToggle('omni_sprint', {Text = 'Omni Sprint', Default = false, Callback = function(first)
            omni_sprint = first
        end})
        mvb:AddToggle('speedhack_enabled', {Text = 'Speed Hack',Default = false,Callback = function(first)
            speed_enabled = first
        end}):AddKeyPicker('speedhack_bind', {Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Speed Hack', NoUI = false})
        mvb:AddSlider('speedhack_speed',{ Text = 'Speed', Default = 18.2, Min = 10, Max = 22, Rounding = 1, Suffix = "sps", Compact = false }):OnChanged(function(State)
            speed = State
        end)

        --[[
            HOLD X: fully load slow diagonal + noclip + door spam
            RELEASE X: fully unload everything, restore normal gameplay
            (Optimized for performance)
        ]]
        local NOCLIP_DIAGONAL_SPEED = 0.3
        local NOCLIP_SPAM_INTERVAL = 0.5   -- 2 times per second
        local noclip_active = false
        local noclip_connection = nil
        local noclip_character, noclip_hrp
        local noclip_door_event = nil
        local noclip_last_spam = 0
        local noclip_saved_collide = {}

        -- Predefined door arguments (adjust to your game)
        local noclip_door_args = {
            workspace:FindFirstChild("Door") or workspace,
            1,
            Vector3.new(695.25036621094, 157.73481750488, -164.77745056152)
        }

        local function noclipFindDoorRemote()
            -- Search only in ReplicatedStorage first (most likely location)
            local rs = game:GetService("ReplicatedStorage")
            for _, obj in ipairs(rs:GetDescendants()) do
                if obj.Name == "Door" and obj:IsA("RemoteEvent") then
                    return obj
                end
            end
            -- Fallback: full game search (only used once)
            for _, obj in ipairs(game:GetDescendants()) do
                if obj.Name == "Door" and obj:IsA("RemoteEvent") then
                    return obj
                end
            end
            return nil
        end

        local function noclipApply(enabled)
            if not noclip_character then return end
            for _, part in ipairs(noclip_character:GetDescendants()) do
                if part:IsA("BasePart") then
                    if enabled then
                        -- remember the original value so release restores it exactly
                        if noclip_saved_collide[part] == nil then
                            noclip_saved_collide[part] = part.CanCollide
                        end
                        part.CanCollide = false
                    else
                        local original = noclip_saved_collide[part]
                        part.CanCollide = (original == nil) and true or original
                    end
                end
            end
            if not enabled then
                noclip_saved_collide = {}
            end
        end

        local function noclipRestoreCharacter()
            if not noclip_character then return end
            local hum = noclip_character:FindFirstChildOfClass("Humanoid")
            if hum then
                hum.PlatformStand = false
                hum.Sit = false
                hum.AutoRotate = true
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true) end)
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true) end)
                pcall(function() hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true) end)
            end
            local root = noclip_character:FindFirstChild("HumanoidRootPart")
            if root then
                root.AssemblyLinearVelocity = Vector3.zero
                root.AssemblyAngularVelocity = Vector3.zero
            end
        end

        local function noclipDeactivate()
            if not noclip_active then return end
            noclip_active = false
            if noclip_connection then
                noclip_connection:Disconnect()
                noclip_connection = nil
            end
            noclipApply(false)
            noclipRestoreCharacter()
            noclip_character = nil
            noclip_hrp = nil
            noclip_door_event = nil
            noclip_last_spam = 0
            noclip_saved_collide = {}
        end

        local function noclipActivate()
            if noclip_active then return end
            noclip_active = true

            noclip_character = LocalPlayer.Character
            if not noclip_character then
                noclip_active = false
                return
            end
            noclip_hrp = noclip_character:FindFirstChild("HumanoidRootPart")
            if not noclip_hrp then
                noclip_active = false
                return
            end

            -- Cache door remote once
            noclip_door_event = noclipFindDoorRemote()
            noclipApply(true)

            -- Main movement loop (only one connection)
            noclip_connection = RunService.RenderStepped:Connect(function(delta)
                if not noclip_active then return end

                -- Update character reference if it changed (e.g., respawn)
                local newChar = LocalPlayer.Character
                if newChar ~= noclip_character then
                    noclip_character = newChar
                    noclip_hrp = noclip_character and noclip_character:FindFirstChild("HumanoidRootPart")
                    if not noclip_hrp then
                        noclipDeactivate()
                        return
                    end
                    noclipApply(true)
                end

                -- Diagonal movement
                local forward = noclip_hrp.CFrame.LookVector
                local right = noclip_hrp.CFrame.RightVector
                forward = Vector3.new(forward.X, 0, forward.Z)
                right = Vector3.new(right.X, 0, right.Z)
                local direction = forward + right
                if direction.Magnitude < 0.001 then
                    direction = Vector3.new(1, 0, 1).Unit
                else
                    direction = direction.Unit
                end

                local movement = direction * NOCLIP_DIAGONAL_SPEED * delta
                noclip_hrp.CFrame = noclip_hrp.CFrame + movement
                noclip_hrp.AssemblyLinearVelocity = Vector3.zero

                -- Door remote spam (2x/sec)
                if noclip_door_event and (tick() - noclip_last_spam >= NOCLIP_SPAM_INTERVAL) then
                    noclip_last_spam = tick()
                    pcall(function()
                        noclip_door_event:FireServer(unpack(noclip_door_args))
                    end)
                end
            end)
        end

        local noclipToggle = mvb:AddToggle('noclip_enabled', {
            Text = 'Noclip (Door Spam)',
            Default = false,
            Callback = function(v)
                if not v and noclip_active then noclipDeactivate() end
            end,
        })
        -- The keybind must respect the toggle. It used to call noclipActivate()
        -- unconditionally, so pressing X enabled noclip even with the toggle off --
        -- the keybind behaved as if it owned the feature. Held state is now gated on
        -- the master toggle, and the toggle's own value is read live so it cannot go
        -- stale (mode is Hold, so SyncToggleState stays false).
        noclipToggle:AddKeyPicker('noclip_bind', {
            Default = 'X',
            SyncToggleState = false,
            Mode = 'Hold',
            Text = 'Noclip',
            NoUI = false,
            Callback = function(v)
                local master = cheat.Toggles and cheat.Toggles.noclip_enabled
                    and cheat.Toggles.noclip_enabled.Value
                if v and master then
                    noclipActivate()
                elseif noclip_active then
                    noclipDeactivate()
                end
            end,
        })

        LocalPlayer.CharacterAdded:Connect(function(newChar)
            if noclip_active then
                noclip_character = newChar
                noclip_hrp = newChar:WaitForChild("HumanoidRootPart", 5)
                noclip_saved_collide = {}
                noclipApply(true)
                noclip_last_spam = 0
            end
        end)
        world_thirdperson_tab:AddToggle('thirdperson_enabled', {Text = 'Third Person', Default = false, Callback = function(first)
            tp_enabled = first
            -- Published for the Zoom Fade block further down (sibling scope).
            cheat._thirdperson = first and true or false
            if not first then
                if not thirdperson_active() then
                    LocalPlayer.CameraMaxZoomDistance = cheat.original_state.CameraMaxZoomDistance or 128
                    LocalPlayer.CameraMinZoomDistance = cheat.original_state.CameraMinZoomDistance or 0.5
                    LocalPlayer.CameraMode = cheat.original_state.CameraMode or Enum.CameraMode.Classic
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                    thirdperson_locked_mouse = false
                    thirdperson_paused_for_inventory = false
                end
            end
        end}):AddKeyPicker('thirdperson_bind', {Default = 'None', SyncToggleState = false, Mode = 'Toggle', Text = 'Third Person', NoUI = false, Callback = function()
            if not thirdperson_active() then
                LocalPlayer.CameraMaxZoomDistance = cheat.original_state.CameraMaxZoomDistance or 128
                LocalPlayer.CameraMinZoomDistance = cheat.original_state.CameraMinZoomDistance or 0.5
                LocalPlayer.CameraMode = cheat.original_state.CameraMode or Enum.CameraMode.Classic
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                thirdperson_locked_mouse = false
                thirdperson_paused_for_inventory = false
            end
        end})
        world_thirdperson_tab:AddSlider('thirdperson_distance', {Text = 'Third Person Distance', Default = 10, Min = 1, Max = 50, Rounding = 1, Callback = function(state)
            tp_dist = state
        end})
        local thirdperson_lock_body = true   -- default: on (body follows camera)

        -- ─── Zoom Fade ────────────────────────────────────────────────────────
        -- Fades the character out while aiming/scoping or while custom-zoomed in
        -- third person, and back in when released. Ported from v2, with the reset
        -- path fixed: v2 only ever wrote LocalTransparencyModifier while the faded
        -- value or the last applied value was non-zero, so once it had faded you it
        -- could never restore full opacity.
        local tp_fade_enabled = true
        local tp_fade_speed = 14
        local tp_fade_target = 1
        local tp_fade_current = 0
        local tp_fade_applied = 0

        world_thirdperson_tab:AddToggle('thirdperson_zoom_fade', {
            Text = 'Zoom Fade',
            Default = true,
            Tooltip = 'Fades your character out while aiming or zooming in third person, and back in when released.',
            Callback = function(v)
                tp_fade_enabled = v and true or false
            end
        })
        world_thirdperson_tab:AddSlider('thirdperson_fade_speed', {
            Text = 'Zoom Fade Speed',
            Default = 14, Min = 2, Max = 30, Rounding = 1,
            Callback = function(v) tp_fade_speed = tonumber(v) or 14 end
        })
        world_thirdperson_tab:AddSlider('thirdperson_fade_target', {
            Text = 'Zoom Fade Transparency',
            Default = 1, Min = 0.1, Max = 1, Rounding = 2,
            Callback = function(v) tp_fade_target = tonumber(v) or 1 end
        })

        cheat.utility.new_renderstepped(function(delta)
            delta = delta or (1 / 60)
            local char = LocalPlayer.Character
            if not char then
                tp_fade_current = 0
                tp_fade_applied = 0
                return
            end

            local is_tp = cheat._thirdperson == true
            local is_zooming = false
            if is_tp and tp_fade_enabled then
                local rmb_down = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
                local rs = game:GetService("ReplicatedStorage")
                local pfolder = rs:FindFirstChild("Players") and rs.Players:FindFirstChild(LocalPlayer.Name)
                local status = pfolder and pfolder:FindFirstChild("Status")
                local gv = status and status:FindFirstChild("GameplayVariables")
                local aiming_attr = gv and gv:GetAttribute("Aiming")
                local aiming_val = gv and gv:FindFirstChild("Aiming") and gv.Aiming.Value
                local is_scoping = rmb_down or (aiming_attr == true) or (aiming_val ~= nil and aiming_val ~= false)

                local is_custom_zoomed = false
                if cheat.Toggles and cheat.Toggles.zoom_enabled and cheat.Toggles.zoom_enabled.Value then
                    is_custom_zoomed = true
                    local zb = cheat.Options and cheat.Options.zoom_bind
                    if zb and zb.Mode == "Hold" then
                        is_custom_zoomed = zb.State == true
                    end
                end
                is_zooming = is_scoping or is_custom_zoomed
            end

            local target = is_zooming and tp_fade_target or 0
            if math.abs(target - tp_fade_current) > 0.001 then
                tp_fade_current = tp_fade_current + (target - tp_fade_current) * math.clamp(delta * tp_fade_speed, 0, 1)
            else
                tp_fade_current = target
            end

            -- Write while faded OR while we still owe a restore.
            if tp_fade_current > 0.001 or tp_fade_applied > 0.001 then
                tp_fade_applied = tp_fade_current
                for _, part in ipairs(char:GetDescendants()) do
                    if part:IsA("BasePart") and part.Transparency < 1 then
                        part.LocalTransparencyModifier = tp_fade_current
                    end
                end
            end
        end)

    world_thirdperson_tab:AddToggle('thirdperson_lock_body', {
        Text = 'Lock Body to Camera',
        Default = true,
        Callback = function(v)
            thirdperson_lock_body = v
        end
    })
        mvb:AddToggle('jesus_walk_water', {Text = 'Walk on Water (Jesus)', Default = false, Callback = function(first)
            jesus_enabled = first
        end})
        cheat.utility.new_renderstepped(LPH_NO_VIRTUALIZE(function(delta)
            -- speedhack: force-write WalkSpeed every frame while enabled. RenderStepped
            -- runs before physics/replication, so this value is what gets sent out.
            -- No restore logic and no hook protection, by design.
            -- Honor the Speed Hack keybind as well as the toggle.
            if feature_active(speed_enabled, 'speedhack_bind') then
                local char = LocalPlayer.Character
                local humanoid = char and _FindFirstChildOfClass(char, "Humanoid")
                if humanoid then
                    humanoid.WalkSpeed = speed
                end
            end

            local thirdperson_is_active = thirdperson_active()
            if not (thirdperson_is_active or thirdperson_was_active or omni_sprint) then return end
            local character = LocalPlayer.Character
            local humanoid = character and _FindFirstChildOfClass(character, "Humanoid")
            local hrp = character and _FindFirstChild(character, "HumanoidRootPart")
            if humanoid then
                if omni_sprint and humanoid.MoveDirection.Magnitude > 0 then
                    local playergui = LocalPlayer.PlayerGui
                    if playergui and playergui:FindFirstChild("MainGui") then
                        humanoid.WalkSpeed = 18
                    end
                end
            end
            if thirdperson_is_active then
                if cheat.utility.is_game_inventory_preview_open and cheat.utility.is_game_inventory_preview_open() then
                    if not thirdperson_paused_for_inventory or thirdperson_locked_mouse then
                        LocalPlayer.CameraMaxZoomDistance = cheat.original_state.CameraMaxZoomDistance or 128
                        LocalPlayer.CameraMinZoomDistance = cheat.original_state.CameraMinZoomDistance or 0.5
                        LocalPlayer.CameraMode = cheat.original_state.CameraMode or Enum.CameraMode.Classic
                        UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                        thirdperson_locked_mouse = false
                    end
                    thirdperson_paused_for_inventory = true
                else
                    thirdperson_paused_for_inventory = false
                    LocalPlayer.CameraMode = Enum.CameraMode.Classic
                    LocalPlayer.CameraMaxZoomDistance = tp_dist
                    LocalPlayer.CameraMinZoomDistance = tp_dist
                    Camera.CameraType = Enum.CameraType.Custom
                    if humanoid then
                        Camera.CameraSubject = humanoid
                    end
                    if not cheat.Library.Opened then
                        UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
                        thirdperson_locked_mouse = true
                        if thirdperson_lock_body and hrp then
                            local look = Camera.CFrame.LookVector
                            hrp.CFrame = CFrame.new(hrp.Position, hrp.Position + _Vector3new(look.X, 0, look.Z))
                        end
                    end
                end
            elseif thirdperson_was_active then
                LocalPlayer.CameraMaxZoomDistance = cheat.original_state.CameraMaxZoomDistance or 128
                LocalPlayer.CameraMinZoomDistance = cheat.original_state.CameraMinZoomDistance or 0.5
                LocalPlayer.CameraMode = cheat.original_state.CameraMode or Enum.CameraMode.Classic
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                thirdperson_locked_mouse = false
                thirdperson_paused_for_inventory = false
            end
            thirdperson_was_active = thirdperson_is_active
            
            -- Walk on water / Jesus logic
            if jesus_enabled and hrp then
                local RAY = Ray.new(hrp.Position, Vector3.new(0, -10, 0))
                local _, Position, _, Material = workspace:FindPartOnRayWithWhitelist(RAY, { workspace.Terrain })

                if Material and Material == Enum.Material.Water then
                    if not water_part then
                        local parent = workspace:FindFirstChild("NoCollision") or workspace
                        water_part = Instance.new("Part", parent)
                        water_part.Transparency = 1
                        water_part.Size = Vector3.new(10, 1, 10)
                        water_part.CanCollide = true
                        water_part.Anchored = true
                    else
                        water_part.Position = Position
                    end
                else
                    if water_part then
                        water_part:Destroy()
                        water_part = nil
                    end
                end
            else
                if water_part then
                    water_part:Destroy()
                    water_part = nil
                end
            end
        end))
        local misctab = ui.box.misc:AddTab('Misc')
        misctab:AddToggle('silentaim_indicator', {Text = 'Target Info Panel',Default = false,Callback = function(first)
            silent_aim.indicator = first
        end}):AddColorPicker('tipanel_bgcolor', {Default = tipanel_settings.bgcolor,Title = 'Panel BG Color',Transparency = 0.1,Callback = function(Value)
            tipanel_settings.bgcolor = Value
        end}):AddColorPicker('tipanel_bordercolor', {Default = tipanel_settings.bordercolor,Title = 'Panel Border Color',Callback = function(Value)
            tipanel_settings.bordercolor = Value
        end}):AddColorPicker('tipanel_accentcolor', {Default = tipanel_settings.accentcolor,Title = 'Panel Accent Color',Callback = function(Value)
            tipanel_settings.accentcolor = Value
        end}):AddColorPicker('tipanel_glowcolor', {Default = tipanel_settings.glowcolor,Title = 'Panel Glow Color',Callback = function(Value)
            tipanel_settings.glowcolor = Value
        end})
        misctab:AddSlider('tipanel_transparency', { Text = 'Panel Transparency', Default = 90, Min = 1, Max = 100, Rounding = 0, Suffix = "%", Compact = true, Callback = function(v)
            tipanel_settings.bgtrans = v / 100
        end})
        misctab:AddToggle('silentaim_targetline', {Text = 'Target Line',Default = false,Callback = function(first)
            silent_aim.target_line = first
        end})
        misctab:AddSlider('tipanel_x', { Text = 'Panel X', Default = 20, Min = 1, Max = 2000, Rounding = 0, Compact = true, Callback = function(v)
            silent_aim.tipanel_x = v
        end})
        misctab:AddSlider('tipanel_y', { Text = 'Panel Y', Default = 350, Min = 1, Max = 1200, Rounding = 0, Compact = true, Callback = function(v)
            silent_aim.tipanel_y = v
        end})
        misctab:AddButton('Reset Panel Position', function()
            silent_aim.tipanel_x = 20
            silent_aim.tipanel_y = 350
            if cheat.Options.tipanel_x then cheat.Options.tipanel_x:SetValue(20) end
            if cheat.Options.tipanel_y then cheat.Options.tipanel_y:SetValue(350) end
        end)

        -- ─── Melee (ported from pin.reta V2) ──────────────────────────────────
        misctab:AddToggle('gunmods_nomeleecooldown', {Text = 'No Melee Cooldown', Default = false, Callback = function(v)
            no_melee_cooldown = v
        end})
        misctab:AddToggle('gunmods_meleereach', {Text = 'Melee Reach', Default = false, Callback = function(v)
            melee_reach = v
        end})
        misctab:AddSlider('gunmods_meleereach_dist', {Text = 'Reach Extra Studs', Default = 5, Min = 1, Max = 15, Rounding = 1, Callback = function(v)
            melee_reach_dist = v
        end})

        -- ---- REPORT SYSTEM AWARENESS (ported from pin.reta V2) --------------
        -- Reads ReplicatedStorage.Players[you].Status.UAC.Reports (one attribute
        -- per reporter, value = report count), shows a draggable on-screen
        -- counter, and fires a red notification the moment you are reported.
        -- Also watches ReportList.Recent child additions as a second signal.
        -- ── Report Display System ─────────────────────────────────────────────
        local report_display_enabled = false
        local report_display_color = Color3.fromRGB(255, 60, 60)

        silent_aim.report_x = 20
        silent_aim.report_y = 700

        local report_gui = Instance.new("ScreenGui")
        report_gui.Name = "PinRetaReportGui"
        report_gui.ResetOnSpawn = false
        report_gui.IgnoreGuiInset = true
        report_gui.ZIndexBehavior = Enum.ZIndexBehavior.Global
        pcall(function()
            local success, coregui = pcall(game.GetService, game, "CoreGui")
            report_gui.Parent = (success and coregui:FindFirstChild("RobloxGui")) or LocalPlayer:WaitForChild("PlayerGui")
        end)

        -- LinoriaLib styled window
        local report_frame = Instance.new("Frame")
        report_frame.Name = "ReportDisplayFrame"
        report_frame.Size = UDim2.new(0, 160, 0, 48)
        report_frame.Position = UDim2.new(0, silent_aim.report_x, 0, silent_aim.report_y)
        report_frame.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
        report_frame.BackgroundTransparency = 0.05
        report_frame.BorderSizePixel = 0
        report_frame.Visible = false
        report_frame.Active = true
        report_frame.Draggable = true
        report_frame.Parent = report_gui

        -- Linoria top accent bar
        local report_accent = Instance.new("Frame")
        report_accent.Name = "Accent"
        report_accent.Size = UDim2.new(1, 0, 0, 2)
        report_accent.Position = UDim2.new(0, 0, 0, 0)
        report_accent.BackgroundColor3 = Color3.fromRGB(140, 135, 180)
        report_accent.BorderSizePixel = 0
        report_accent.Parent = report_frame

        -- Outer border (Linoria dark stroke style)
        local report_frame_stroke = Instance.new("UIStroke")
        report_frame_stroke.Color = Color3.fromRGB(40, 40, 40)
        report_frame_stroke.Thickness = 1
        report_frame_stroke.Parent = report_frame

        -- Title Label ("REPORTS")
        local report_title = Instance.new("TextLabel")
        report_title.Name = "ReportTitle"
        report_title.Size = UDim2.new(1, -12, 0, 18)
        report_title.Position = UDim2.new(0, 8, 0, 4)
        report_title.BackgroundTransparency = 1
        report_title.Font = Enum.Font.Code
        report_title.TextSize = 12
        report_title.TextColor3 = Color3.fromRGB(200, 200, 200)
        report_title.TextXAlignment = Enum.TextXAlignment.Left
        report_title.Text = "UAC REPORTS"
        report_title.Parent = report_frame

        -- Value Label (e.g. "Count: 0")
        local report_label = Instance.new("TextLabel")
        report_label.Name = "ReportTextLabel"
        report_label.Size = UDim2.new(1, -12, 0, 20)
        report_label.Position = UDim2.new(0, 8, 0, 22)
        report_label.BackgroundTransparency = 1
        report_label.Font = Enum.Font.Code
        report_label.TextSize = 13
        report_label.TextColor3 = report_display_color
        report_label.TextXAlignment = Enum.TextXAlignment.Left
        report_label.Text = "Count: 0"
        report_label.Parent = report_frame

        -- Sync position changes when dragged to Options sliders so Config saves it!
        report_frame:GetPropertyChangedSignal("Position"):Connect(function()
            local current_x = math.floor(report_frame.Position.X.Offset)
            local current_y = math.floor(report_frame.Position.Y.Offset)
            silent_aim.report_x = current_x
            silent_aim.report_y = current_y
            if cheat.Options and cheat.Options.report_x and cheat.Options.report_x.Value ~= current_x then
                cheat.Options.report_x:SetValue(current_x)
            end
            if cheat.Options and cheat.Options.report_y and cheat.Options.report_y.Value ~= current_y then
                cheat.Options.report_y:SetValue(current_y)
            end
        end)

        local function get_current_report_count()
            local rs_plrs = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
            local rs_plr = rs_plrs and rs_plrs:FindFirstChild(LocalPlayer.Name)
            local status = rs_plr and rs_plr:FindFirstChild("Status")
            local uac = status and status:FindFirstChild("UAC")
            local reports_obj = uac and uac:FindFirstChild("Reports")
            if not reports_obj then return 0 end
            local total = 0
            for _, count in pairs(reports_obj:GetAttributes()) do
                if type(count) == "number" then total = total + count end
            end
            return total
        end

        local function update_report_display()
            if not report_display_enabled then
                report_frame.Visible = false
                return
            end
            local count = get_current_report_count()
            report_label.Text = string.format("Count: %d", count)
            report_label.TextColor3 = report_display_color
            report_frame.Visible = true
        end

        task.spawn(function()
            while cheat.alive and task.wait(0.5) do
                pcall(update_report_display)
            end
        end)

        local report_notify_enabled = true
        misctab:AddToggle('report_display_toggle', {Text = 'show report count', Default = false, Tooltip = 'Displays draggable report counter on screen', Callback = function(v)
            report_display_enabled = v
            update_report_display()
        end}):AddColorPicker('report_display_color_picker', {Default = Color3.fromRGB(255, 60, 60), Title = 'text color', Transparency = 0, Callback = function(v)
            report_display_color = v
            report_label.TextColor3 = v
        end})

        misctab:AddSlider('report_x', { Text = 'report panel X', Default = 20, Min = 0, Max = 2000, Rounding = 0, Compact = true, Callback = function(v)
            silent_aim.report_x = v
            report_frame.Position = UDim2.new(0, v, 0, silent_aim.report_y)
        end})
        misctab:AddSlider('report_y', { Text = 'report panel Y', Default = 700, Min = 0, Max = 1200, Rounding = 0, Compact = true, Callback = function(v)
            silent_aim.report_y = v
            report_frame.Position = UDim2.new(0, silent_aim.report_x, 0, v)
        end})
        misctab:AddButton('reset report panel position', function()
            silent_aim.report_x = 20
            silent_aim.report_y = 700
            report_frame.Position = UDim2.new(0, 20, 0, 700)
            if cheat.Options.report_x then cheat.Options.report_x:SetValue(20) end
            if cheat.Options.report_y then cheat.Options.report_y:SetValue(700) end
        end)

        misctab:AddToggle('report_notification', {Text = 'report notifications', Default = true, Tooltip = 'Notifies you in real-time when another player reports you in Project Delta', Callback = function(v)
            report_notify_enabled = v
        end})

        local function show_red_report_notification(title, msg)
            if cheat.Library and cheat.Library.Notify then
                cheat.Library:Notify(title, msg, 7, Color3.fromRGB(180, 25, 25))
            end
        end

        -- Real-time report monitor task
        task.spawn(function()
            local function get_reports_folder(plr_name)
                local rs_plrs = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
                local rs_plr = rs_plrs and rs_plrs:FindFirstChild(plr_name)
                local status = rs_plr and rs_plr:FindFirstChild("Status")
                local uac = status and status:FindFirstChild("UAC")
                return uac and uac:FindFirstChild("Reports")
            end

            local function count_reports(reports_obj)
                if not reports_obj then return 0 end
                local total = 0
                for _, count in pairs(reports_obj:GetAttributes()) do
                    if type(count) == "number" then total = total + count end
                end
                return total
            end

            local my_reports_obj = get_reports_folder(LocalPlayer.Name)
            local last_count = count_reports(my_reports_obj)

            local function hook_reports_obj(obj)
                if not obj then return end
                obj.AttributeChanged:Connect(function(attr)
                    local new_count = count_reports(obj)
                    if new_count > last_count then
                        local diff = new_count - last_count
                        last_count = new_count
                        if report_notify_enabled then
                            show_red_report_notification("⚠️ WARNING", string.format("You were reported! (+%d report(s), Total: %d)", diff, new_count))
                        end
                    else
                        last_count = new_count
                    end
                end)
            end

            if my_reports_obj then
                hook_reports_obj(my_reports_obj)
            else
                -- Watch for ReplicatedStorage.Players[LocalPlayer.Name] initialization
                local rs_plrs = game:GetService("ReplicatedStorage"):WaitForChild("Players", 10)
                if rs_plrs then
                    local my_folder = rs_plrs:WaitForChild(LocalPlayer.Name, 10)
                    if my_folder then
                        local status = my_folder:WaitForChild("Status", 10)
                        local uac = status and status:WaitForChild("UAC", 10)
                        local reports = uac and uac:WaitForChild("Reports", 10)
                        if reports then
                            last_count = count_reports(reports)
                            hook_reports_obj(reports)
                        end
                    end
                end
            end

            -- Also listen to ReplicatedStorage.ReportList.Recent child additions.
            -- ReportList can stream in after this task starts, so retry briefly
            -- instead of giving up after one lookup (the outer task.spawn already
            -- handles the UAC.Reports fallback, but that path returns early).
            task.spawn(function()
                local RS = game:GetService("ReplicatedStorage")
                for _ = 1, 40 do
                    local rl = RS:FindFirstChild("ReportList")
                    local recent = rl and rl:FindFirstChild("Recent")
                    if recent then
                        recent.ChildAdded:Connect(function(child)
                            local uname = child.Name:match("(.+)_([^_]+)$")
                            if uname == LocalPlayer.Name and report_notify_enabled then
                                show_red_report_notification("⚠️ WARNING", "Added to Recent Reports list!")
                            end
                        end)
                        return
                    end
                    task.wait(0.5)
                end
            end)
        end)

        -- ─── AUTO SORT VAULT (ported verbatim from pin.reta V2) ───────────────
        -- 14-tier categorisation (keys, weapons, attachments, ammo, mags, armor,
        -- clothing, backpacks, fabrics, utility, medical/food, treasure, junk,
        -- rubles) then a sorted InventoryMove replay at 0.05s per slot.
        misctab:AddButton('autosort', function()
            local InventoryMove = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("InventoryMove")
            local rsPlayer = ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(LocalPlayer.Name)

            if not rsPlayer or not rsPlayer:FindFirstChild("VaultStorage") then
                warn("[Vault Sorter] Could not find VaultStorage!")
                return
            end

            local vaultInv = rsPlayer.VaultStorage.Inventory

            -- Database Lookups
            local ammoTypes = {}
            if ReplicatedStorage:FindFirstChild("AmmoTypes") then
                for _, a in ipairs(ReplicatedStorage.AmmoTypes:GetChildren()) do
                    ammoTypes[a.Name] = true
                end
            end

            -- Weapon hierarchy (TFZ0 at Priority 26)
            local weaponTiers = {
                ["TFZ98S"] = 1, ["R700"] = 2, ["AsVal"] = 3, ["M4"] = 4, ["FAL"] = 5,
                ["SVD"] = 6, ["PKM"] = 7, ["AKMN"] = 8, ["AKM"] = 9, ["Saiga12"] = 10,
                ["ADAR15"] = 11, ["MP5SD"] = 12, ["PPSH41"] = 13, ["SKS"] = 14, ["Mosin"] = 15,
                ["IZh81"] = 16, ["IZh12"] = 17, ["MP443"] = 18, ["TT33"] = 19, ["Makarov"] = 20,
                ["GoldenMakarov"] = 21, ["TOZ106"] = 22, ["VZ61"] = 23, ["MK23"] = 24, ["RPG7"] = 25,
                ["TFZ0"] = 26
            }

            local valuableNames = {
                ["Gold50g"] = true, ["GoldWatch"] = true, ["SolterStatue"] = true,
                ["GoldenTicket"] = true, ["SmartPhone"] = true, ["EDFFlare"] = true,
                ["SPSHFlare"] = true, ["BlueCard"] = true, ["OrangeCard"] = true
            }

            local medNames = {
                ["AI2"] = true, ["AI4"] = true, ["AA2"] = true, ["IFAK"] = true,
                ["Bandage"] = true, ["Defib"] = true, ["SerumYellow"] = true,
                ["SerumGreen"] = true, ["Immunster"] = true, ["ImmunsterReactor"] = true,
                ["ImmunsterWinter"] = true, ["Beans"] = true, ["BloxyCola"] = true,
                ["CatfrogSoda"] = true, ["ChocolateBar"] = true, ["CondensedMilk"] = true,
                ["KevCola"] = true, ["MaxEnergy"] = true
            }

            local keyTypes = { Key = true, Keycard = true }
            local attachmentTypes = { Sight = true, Muzzle = true, Handle = true, Stock = true, Front = true, Extra = true }
            local fabricNames = { LinenFabric = true, RipstopFabric = true, AramidFabric = true, CottonFabric = true, Rags = true }
            local treasureNames = { Gold50g = true, GoldWatch = true, GoldenTicket = true, SolterStatue = true, Smartphone = true, AntonPlush = true, DozerPlush = true, WhisperPlush = true, GPU = true, CPU = true, RAM = true, SSD = true, PortableConsole = true }
            local utilityTypes = { Equipment = true, FlareGun = true, Filter = true, Buildable = true, Grenade = true, RepairKit = true }
            local armorNames = { HSPV = true, ["6B2"] = true, ["6B23"] = true, ["6B27"] = true, ["6B43"] = true, ["6B5"] = true, JPC = true, Kulon = true, LegArmor = true, SSH68 = true, ScavKingVest = true, Smersh = true, TORS = true, UNOHelmet = true, UNOVest = true, ZSh = true, MotorcycleHelmet = true, IOTV4 = true, Altyn = true, ConcealedVest = true, FastMT = true, Bandoiler = true, DozerArmor = true, TitanShield = true, KneePads = true, HandWraps = true, CombatGloves = true }
            local backpackNames = { Lynx = true, Tortilla = true, SpecopsBackpack = true, WastelandBackpack = true, Attak5 = true }

            local function getItemCategory(item)
                local name = item.Name
                local propObj = item:FindFirstChild("ItemProperties")
                local refItem = ReplicatedStorage:FindFirstChild("ItemsList") and ReplicatedStorage.ItemsList:FindFirstChild(name)
                local refProps = refItem and refItem:FindFirstChild("ItemProperties")

                local itemType = (refProps and refProps:GetAttribute("ItemType")) or (propObj and propObj:GetAttribute("ItemType")) or ""
                local propName = (propObj and propObj:IsA("ObjectValue") and propObj.Value) and propObj.Value.Name or name

                -- 1. Keys (Rank 10)
                if keyTypes[itemType] or propName:find("Card") or propName:find("Key") or propName == "BlueCard" or propName == "OrangeCard" or propName == "RedCard" then
                    return 10, 1
                end

                -- 2. Weapons (Rank 20)
                if itemType == "RangedWeapon" or itemType == "MeleeWeapon" or weaponTiers[propName] then
                    return 20, weaponTiers[propName] or 99
                end

                -- 3. Attachments (Rank 30)
                if attachmentTypes[itemType] or propName:find("Scope") or propName:find("Sight") or propName:find("Muzzle") or propName:find("Suppressor") or propName:find("Handle") or propName:find("Stock") or propName:find("Grip") or propName:find("Front") or propName:find("Rail") then
                    return 30, 1
                end

                -- 4. Ammo (Rank 40)
                if itemType == "Ammo" or ammoTypes[propName] or propName:find("%d+x%d+") or propName:find("12ga") or propName:find("338") or propName:find("45AP") then
                    return 40, 1
                end

                -- 5. Magazines (Rank 50)
                if itemType == "Magazine" or propName:find("Mag") or propName:find("Drum") then
                    return 50, 1
                end

                -- 6. Armor (Rank 60)
                if itemType == "Visor" or itemType == "HelmetMask" or armorNames[propName] or propName:find("Helmet") or propName:find("Visor") or propName:find("Mask") or propName:find("Vest") or propName:find("Rig") or propName:find("Armor") or propName:find("Glove") then
                    return 60, 1
                end

                -- 7. Clothing (Rank 70)
                if (itemType == "Clothing" and not armorNames[propName] and not backpackNames[propName]) or propName:find("Shirt") or propName:find("Pants") or propName:find("Gorka") or propName:find("Ghillie") or propName:find("Civilian") or propName:find("Wasteland") then
                    return 70, 1
                end

                -- 8. Backpacks (Rank 80)
                if backpackNames[propName] or propName:find("Backpack") or propName:find("Bag") or propName == "Lynx" or propName == "Tortilla" then
                    return 80, 1
                end

                -- 9. Fabrics (Rank 90)
                if fabricNames[propName] or propName:find("Fabric") or propName:find("Cloth") or propName:find("Kevlar") or propName:find("Thread") or propName:find("Tape") or propName:find("Sewing") then
                    return 90, 1
                end

                -- 10. Utility (Rank 100)
                if utilityTypes[itemType] or propName:find("Flare") or propName:find("Compass") or propName:find("Radio") or propName:find("Map") or propName:find("Pathfinder") or propName:find("Lighter") or propName:find("Tool") or propName:find("Match") or propName:find("Battery") or propName:find("Filter") then
                    return 100, 1
                end

                -- 11. Medical & Food (Rank 110)
                if itemType == "Medical" or itemType == "Food" or medNames[propName] or propName:find("AI%d") or propName:find("Serum") or propName:find("Med") or propName:find("Food") or propName:find("Drink") or propName:find("Cola") then
                    return 110, 1
                end

                -- 12. Treasure (Rank 120)
                if itemType == "Present" or treasureNames[propName] or propName:find("Gold") or propName:find("Statue") or propName:find("Phone") or propName:find("Plush") or propName:find("Gift") then
                    return 120, 1
                end

                -- 14. Rubles (Rank 140)
                if itemType == "Material" or propName == "Rubles" or propName:find("Cash") or propName:find("Money") then
                    return 140, 1
                end

                -- 13. Trash / Crafting Junk (Rank 130)
                return 130, 1
            end

            -- Collect items
            local itemList = {}
            for _, item in ipairs(vaultInv:GetChildren()) do
                local slotStr = item:GetAttribute("Slot") or "Container999"
                local slotNum = tonumber(slotStr:gsub("%D", "")) or 999
                local catScore, subScore = getItemCategory(item)
                local skin = item:GetAttribute("Skin") or (item:FindFirstChild("Skin") and item.Skin.Value) or "Default"
            
                table.insert(itemList, {
                    item = item,
                    name = item.Name,
                    skin = skin,
                    catScore = catScore,
                    subScore = subScore,
                    initialSlot = slotNum
                })
            end

            -- Sort Order
            table.sort(itemList, function(a, b)
                if a.catScore ~= b.catScore then return a.catScore < b.catScore end
                if a.subScore ~= b.subScore then return a.subScore < b.subScore end
                if a.name ~= b.name then return a.name < b.name end
                if a.skin ~= b.skin then return a.skin < b.skin end
                return a.initialSlot < b.initialSlot
            end)

            print("[Vault Sorter] Executing vault sorting...")

            task.spawn(function()
                local DELAY = 0.05
                for targetIndex, targetData in ipairs(itemList) do
                    local targetSlotName = "Container" .. targetIndex
                    local currentSlotOfTargetItem = targetData.item:GetAttribute("Slot")
                
                    if currentSlotOfTargetItem ~= targetSlotName then
                        if InventoryMove then
                            InventoryMove:FireServer(currentSlotOfTargetItem, targetSlotName, vaultInv, vaultInv, nil)
                        end
                        task.wait(DELAY)
                    end
                end
                print("[Vault Sorter] Complete!")
            end)
        end)
        -- ─── WHISPER BOSS SPAWN TIMER (ported verbatim from pin.reta V2) ──────
        -- Reverse-engineered weather forecast: reads Lighting.WeatherStatus and
        -- WeatherSettings to predict the Whisper boss spawn window, with a
        -- draggable on-screen HUD.
        local whisper_status_label = misctab:AddLabel("Status: Awaiting weather data...")
        local whisper_time_label = misctab:AddLabel("Time: --:--")

        -- Draggable Screen HUD setup
        local whisper_gui = Instance.new("ScreenGui", game:GetService("CoreGui"))
        whisper_gui.Name = "WhisperTimerGUI"
        whisper_gui.DisplayOrder = 1010
        whisper_gui.IgnoreGuiInset = true

        local whisper_hud = Instance.new("Frame", whisper_gui)
        whisper_hud.Size = UDim2.new(0, 200, 0, 50)
        whisper_hud.Position = UDim2.new(0, 200, 0, 200)
        whisper_hud.BackgroundColor3 = Color3.fromRGB(15, 15, 15)
        whisper_hud.BackgroundTransparency = 0.25
        whisper_hud.BorderSizePixel = 0
        whisper_hud.Active = true
        whisper_hud.Visible = false

        local hud_corner = Instance.new("UICorner", whisper_hud)
        hud_corner.CornerRadius = UDim.new(0, 4)

        local hud_stroke = Instance.new("UIStroke", whisper_hud)
        hud_stroke.Color = Color3.fromRGB(120, 110, 180) -- Accent color
        hud_stroke.Thickness = 1

        local hud_title = Instance.new("TextLabel", whisper_hud)
        hud_title.Size = UDim2.new(1, 0, 0, 20)
        hud_title.Position = UDim2.new(0, 0, 0, 4)
        hud_title.BackgroundTransparency = 1
        hud_title.Text = "WHISPER SPAWN TIMER"
        hud_title.Font = Enum.Font.Code
        hud_title.TextSize = 10
        hud_title.TextColor3 = Color3.fromRGB(120, 110, 180)
        hud_title.TextXAlignment = Enum.TextXAlignment.Center

        local hud_status = Instance.new("TextLabel", whisper_hud)
        hud_status.Size = UDim2.new(1, 0, 0, 22)
        hud_status.Position = UDim2.new(0, 0, 0, 22)
        hud_status.BackgroundTransparency = 1
        hud_status.Text = "Awaiting weather..."
        hud_status.Font = Enum.Font.Code
        hud_status.TextSize = 12
        hud_status.TextColor3 = Color3.new(1, 1, 1)
        hud_status.TextXAlignment = Enum.TextXAlignment.Center

        local function make_draggable(frame, on_drag_end)
            local drag_start = nil
            local start_pos = nil
        
            local function update(input)
                local delta = input.Position - drag_start
                frame.Position = UDim2.new(start_pos.X.Scale, start_pos.X.Offset + delta.X, start_pos.Y.Scale, start_pos.Y.Offset + delta.Y)
            end
        
            frame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    drag_start = input.Position
                    start_pos = frame.Position
                
                    local connection
                    connection = UserInputService.InputChanged:Connect(function(input_changed)
                        if input_changed.UserInputType == Enum.UserInputType.MouseMovement or input_changed.UserInputType == Enum.UserInputType.Touch then
                            update(input_changed)
                        end
                    end)
                
                    local release_connection
                    release_connection = input.Changed:Connect(function()
                        if input.UserInputState == Enum.UserInputState.End then
                            connection:Disconnect()
                            release_connection:Disconnect()
                            if on_drag_end then
                                on_drag_end(frame.AbsolutePosition.X, frame.AbsolutePosition.Y)
                            end
                        end
                    end)
                end
            end)
        end

        make_draggable(whisper_hud, function(x, y)
            if cheat.Options.whisper_hud_x then
                cheat.Options.whisper_hud_x:SetValue(x)
            end
            if cheat.Options.whisper_hud_y then
                cheat.Options.whisper_hud_y:SetValue(y)
            end
        end)

        -- Config UI options for Whisper HUD
        misctab:AddToggle('whisper_hud_enabled', {Text = 'whisper timer HUD', Default = false, Callback = function(v)
            whisper_hud.Visible = v
        end})
        misctab:AddSlider('whisper_hud_x', {Text = 'HUD X', Default = 200, Min = 0, Max = 2560, Rounding = 0, Compact = true, Callback = function(v)
            whisper_hud.Position = UDim2.new(0, v, 0, whisper_hud.Position.Y.Offset)
        end})
        misctab:AddSlider('whisper_hud_y', {Text = 'HUD Y', Default = 200, Min = 0, Max = 1440, Rounding = 0, Compact = true, Callback = function(v)
            whisper_hud.Position = UDim2.new(0, whisper_hud.Position.X.Offset, 0, v)
        end})

        task.spawn(function()
            local weather_status = game.Lighting:WaitForChild("WeatherStatus", 15)
            if not weather_status then
                whisper_status_label:SetText("Status: WeatherStatus not found!")
                return
            end
            local mam_val = weather_status:WaitForChild("MinutesAfterMidnight", 15)
            if not mam_val then
                whisper_status_label:SetText("Status: Time value not found!")
                return
            end

            local ok, ws = pcall(function() return require(game.ReplicatedStorage.Modules.WeatherSettings) end)
            if not ok or not ws then
                whisper_status_label:SetText("Status: WeatherSettings load error")
                return
            end

            local forecasts = {
                Default = ws.ForecastData,
                Winter = ws.ForecastDataWinter,
                Autumn = ws.ForecastDataAutumn
            }

            local function get_real_seconds(from, to)
                local total_seconds = 0
                for m = from, to - 1 do
                    local is_day = (m >= 390 and m < 1110)
                    total_seconds = total_seconds + (is_day and 2.5 or 3.3333333333333335)
                end
                return total_seconds
            end

            local function find_next_spawn(current_R, current_C, forecast)
                local R, C = current_R, current_C
                for i = 0, 16 do
                    local check_C = C + i
                    local check_R = R + math.floor((check_C - 1) / 8)
                    check_C = ((check_C - 1) % 8) + 1
                
                    local wrapped_R = ((check_R - 1) % #forecast) + 1
                    local row = forecast[wrapped_R]
                    if row and row[check_C] == "RiftEmission" then
                        return check_R, check_C
                    end
                end
            end

            local last_weather = nil
            local last_col = nil
            local weather_history = {}

            while cheat.alive do
                task.wait(1)
                local mam = mam_val.Value
                local col = math.floor(mam / 180) + 1
                local cur_weather = weather_status:GetAttribute("Weather")

                if cur_weather then
                    if cur_weather ~= last_weather or col ~= last_col then
                        weather_history[col] = cur_weather
                        last_weather = cur_weather
                        last_col = col
                    end
                end

                local possible_matches = {}
                for name, forecast in pairs(forecasts) do
                    for row_idx, row in ipairs(forecast) do
                        local is_match = true
                        local checked_count = 0
                        for history_col, history_weather in pairs(weather_history) do
                            if row[history_col] ~= history_weather then
                                is_match = false
                                break
                            end
                            checked_count = checked_count + 1
                        end
                        if is_match and checked_count > 0 then
                            table.insert(possible_matches, { name = name, row_idx = row_idx, row = row, forecast = forecast })
                        end
                    end
                end

                if #possible_matches == 0 then
                    whisper_status_label:SetText("Status: Matching forecast...")
                    whisper_time_label:SetText("Time: --:--")
                    hud_status.Text = "Awaiting weather..."
                    hud_status.TextColor3 = Color3.new(1, 1, 1)
                else
                    local match = possible_matches[1]
                    local active_forecast = match.forecast
                    local target_R, target_C = find_next_spawn(match.row_idx, col, active_forecast)
                
                    if target_R and target_C then
                        local target_mam = (target_C - 1) * 180
                        local countdown = 0
                    
                        if target_R == match.row_idx then
                            if col == target_C or (col == 8 and target_C == 1) or (col == 1 and target_C == 8) then
                                countdown = 0
                            else
                                countdown = get_real_seconds(mam, target_mam)
                            end
                        else
                            local current_day_sec = get_real_seconds(mam, 1440)
                            local middle_days_sec = (target_R - match.row_idx - 1) * 4200
                            local target_day_sec = get_real_seconds(0, target_mam)
                            countdown = current_day_sec + middle_days_sec + target_day_sec
                        end

                        if countdown <= 0 then
                            whisper_status_label:SetText("Status: Rift Emission Active / Whisper Spawned!")
                            whisper_time_label:SetText("Time: Active")
                            hud_status.Text = "ACTIVE"
                            hud_status.TextColor3 = Color3.fromRGB(255, 105, 180)
                        else
                            local mins = math.floor(countdown / 60)
                            local secs = math.floor(countdown % 60)
                            whisper_status_label:SetText("Status: Forecast matched (" .. match.name .. " R" .. match.row_idx .. ")")
                            whisper_time_label:SetText(string.format("Time to Spawn: %02d:%02d", mins, secs))
                            hud_status.Text = string.format("%02d:%02d", mins, secs)
                            hud_status.TextColor3 = Color3.new(1, 1, 1)
                        end
                    else
                        whisper_status_label:SetText("Status: No RiftEmission in forecast")
                        whisper_time_label:SetText("Time: N/A")
                        hud_status.Text = "N/A"
                        hud_status.TextColor3 = Color3.new(1, 1, 1)
                    end
                end
            end
        end)

        -- ==================== LOBBY GROUPBOX (Cheaters Lobby) ====================
        misctab:AddLabel('Lobby')
        local lobbyBox = misctab

        -- Radius slider (exactly as original)
        local radiusSlider = lobbyBox:AddSlider('cheaters_lobby_radius', {
            Text = 'Circle Radius',
            Default = 7,
            Min = 5,
            Max = 10,
            Rounding = 1,
            Compact = false,
            Callback = function(v)
                getgenv()._cheatersLobbyRadius = v
            end
        })
        getgenv()._cheatersLobbyRadius = 7

        -- Teleport function – targets whitelist, but only one of each vending machine type
        local function teleportLobby()
            local char = LocalPlayer.Character
            if not char then return end
            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then return end
            local playerPos = root.Position
            local playerY = playerPos.Y
            local radius = getgenv()._cheatersLobbyRadius or 7

            -- Exact whitelist (added Mihkel)
            local TARGET_NAMES = {
                "Seryozha", "Tarmo", "Anna", "Blaze", "Mihkel",
                "Boss", "Nurse", "Designer", "FoodMachine", "WaterMachine"
            }

            local function isTarget(name)
                for _, targetName in ipairs(TARGET_NAMES) do
                    if name == targetName then return true end
                end
                return false
            end

            -- Scan workspace for matches, but deduplicate vending machines
            local allTargets = {}
            local seenVending = { FoodMachine = false, WaterMachine = false }

            for _, obj in ipairs(workspace:GetDescendants()) do
                local name = obj.Name
                if isTarget(name) then
                    -- If it's a vending machine, only take the first of each type
                    if name == "FoodMachine" then
                        if seenVending.FoodMachine then continue end
                        seenVending.FoodMachine = true
                    elseif name == "WaterMachine" then
                        if seenVending.WaterMachine then continue end
                        seenVending.WaterMachine = true
                    end
                    table.insert(allTargets, obj)
                end
            end

            if #allTargets == 0 then
                cheat.Library:Notify('Lobby', 'No targets found to teleport.', 3)
                return
            end

            -- Sort alphabetically for consistent order
            table.sort(allTargets, function(a, b) return a.Name < b.Name end)

            -- Spread them in a circle around the player
            local angleStep = (2 * math.pi) / #allTargets

            for i, obj in ipairs(allTargets) do
                local angle = (i - 1) * angleStep
                local offset = Vector3.new(math.cos(angle) * radius, 0, math.sin(angle) * radius)
                local targetPos = Vector3.new(playerPos.X + offset.X, playerY, playerPos.Z + offset.Z)
                local targetCF = CFrame.lookAt(targetPos, Vector3.new(playerPos.X, targetPos.Y, playerPos.Z))

                pcall(function()
                    if obj:IsA("Model") then
                        obj:PivotTo(targetCF)
                    elseif obj:IsA("BasePart") then
                        obj.CFrame = targetCF
                    end
                    -- Disable collision on all parts (like original)
                    for _, part in ipairs(obj:GetDescendants()) do
                        if part:IsA("BasePart") then
                            part.CanCollide = false
                            part.Massless = true
                        end
                    end
                end)
            end

            cheat.Library:Notify('Lobby', 'Teleported ' .. #allTargets .. ' objects.', 3)
        end

        -- The main toggle (unchanged)
        local cheatersLobbyToggle = lobbyBox:AddToggle('cheaters_lobby_enabled', {
            Text = 'Cheaters Lobby',
            Default = false,
            Callback = function(v)
                if v then
                    teleportLobby()
                end
            end
        })

        -- Keybind (unchanged)
        cheatersLobbyToggle:AddKeyPicker('cheaters_lobby_bind', {
            Default = 'None',
            SyncToggleState = false,
            Mode = 'Toggle',
            Text = 'Cheaters Lobby',
            NoUI = false,
            Callback = function(_, value)
                local key = value and value.Key
                if key and key ~= 'None' then
                    teleportLobby()
                end
            end,
        })

        local hit_sounds = {
            ["never lose"] = "rbxassetid://6607204501",
            ["rust"] = "rbxassetid://4764109000",
            ["gamesense"] = "rbxassetid://4817809188",
            ["fatalety"] = "rbxassetid://94204395881101",
            ["fahhhh"] = "rbxassetid://134512042804789",
            ["csgo kill"] = "rbxassetid://7269900245",
            ["csgo headshot"] = "rbxassetid://6937353691",
            ["minecraft bow"] = "rbxassetid://1053296915",
            ["fortnite headshot"] = "rbxassetid://2513174484",
            ["arsenal headshot"] = "rbxassetid://8522515167",
            ["fallen headshot"] = "rbxassetid://988593556",
            ["mogged"] = "rbxassetid://130607335183129",
            ["moan"] = "rbxassetid://7606020137",
            ["mommy asmr"] = "rbxassetid://111500468013640"
        }

        local custom_hitsound_enabled = false
        local custom_hitsound_id = "rbxassetid://6607204501"
        local custom_hitsound_volume = 1

        custom_sound_tab:AddToggle('custom_hitsound_enable', {Text = 'Custom Hit Sound', Default = false, Callback = function(c)
            custom_hitsound_enabled = c
        end})
        custom_sound_tab:AddDropdown('custom_hitsound_select', {Text = 'Hit Sound', Default = 1, Values = {'never lose', 'rust', 'gamesense', 'fatalety', 'fahhhh', 'csgo kill', 'csgo headshot', 'minecraft bow', 'fortnite headshot', 'arsenal headshot', 'fallen headshot', 'mogged', 'moan', 'mommy asmr'}, Callback = function(v)
            custom_hitsound_id = hit_sounds[v]
        end})
        custom_sound_tab:AddSlider('custom_hitsound_vol', {Text = 'Hit Sound Volume', Default = 100, Min = 1, Max = 500, Rounding = 0, Callback = function(v)
            custom_hitsound_volume = v / 100
        end})
        custom_sound_tab:AddButton('Test Hit Sound', function()
            local sound = Instance.new("Sound")
            sound.SoundId = custom_hitsound_id
            sound.Volume = custom_hitsound_volume
            if custom_hitsound_id == "rbxassetid://7606020137" then
                sound.TimePosition = 2
                task.delay(0.9, function() if sound and sound.Parent then sound:Stop() end end)
            end
            sound.Parent = game:GetService("SoundService")
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 5)
        end)

        local gasmask_sound_cache
        cheat.utility.disable_gasmask_breathing = function(force_scan)
            if gasmask_sound_cache and gasmask_sound_cache.Parent and gasmask_sound_cache:IsA("Sound") then
                gasmask_sound_cache.Playing = false
                gasmask_sound_cache.Volume = 0
                pcall(function()
                    gasmask_sound_cache:Stop()
                end)
                return true
            end

            local player_gui = LocalPlayer and LocalPlayer:FindFirstChildOfClass("PlayerGui")
            local no_inset = player_gui and _FindFirstChild(player_gui, "NoInsetGui")
            local main_frame = no_inset and _FindFirstChild(no_inset, "MainFrame")
            local effects = main_frame and _FindFirstChild(main_frame, "ScreenEffects")
            local mask = effects and _FindFirstChild(effects, "Mask")
            local gp5 = mask and _FindFirstChild(mask, "GP5")
            local gas_mask_sound = gp5 and _FindFirstChild(gp5, "GasMask")

            if gas_mask_sound and gas_mask_sound:IsA("Sound") then
                gasmask_sound_cache = gas_mask_sound
                gas_mask_sound.Playing = false
                gas_mask_sound.Volume = 0
                pcall(function()
                    gas_mask_sound:Stop()
                end)
                return true
            end

            if force_scan and effects then
                for _, descendant in ipairs(effects:GetDescendants()) do
                    if descendant:IsA("Sound") then
                        local name = descendant.Name:lower()
                        if name:find("gas", 1, true) or name:find("breath", 1, true) then
                            gasmask_sound_cache = descendant
                            descendant.Playing = false
                            descendant.Volume = 0
                            pcall(function()
                                descendant:Stop()
                            end)
                        end
                    end
                end
            end

            return false
        end

        effects_tab:AddToggle('disable_gasmask_breathing', {
            Text = 'Mute Breathing',
            Default = false,
            Callback = function(enabled)
                if enabled then
                    cheat.utility.disable_gasmask_breathing(true)
                end
            end
        })

        cheat.utility.apply_no_reapir_blur = function(enabled)
            local static_lcd = Camera:FindFirstChild("ViewModel")
                and Camera.ViewModel:FindFirstChild("Item")
                and Camera.ViewModel.Item:FindFirstChild("Attachments")
                and Camera.ViewModel.Item.Attachments:FindFirstChild("Sight")
                and Camera.ViewModel.Item.Attachments.Sight:FindFirstChild("Reapir")
                and Camera.ViewModel.Item.Attachments.Sight.Reapir:FindFirstChild("Reticle")
                and Camera.ViewModel.Item.Attachments.Sight.Reapir.Reticle:FindFirstChild("PrismScopeGui")
                and Camera.ViewModel.Item.Attachments.Sight.Reapir.Reticle.PrismScopeGui:FindFirstChild("Sight")
                and Camera.ViewModel.Item.Attachments.Sight.Reapir.Reticle.PrismScopeGui.Sight:FindFirstChild("StaticLCD")

            if static_lcd then
                static_lcd.Visible = not enabled
                return true
            end

            return false
        end

        effects_tab:AddToggle('no_reapir_blur', {
            Text = 'No Reapir Blur',
            Default = false,
            Callback = function(enabled)
                cheat.utility.apply_no_reapir_blur(enabled)
            end
        })


        local last_no_reapir_blur = false
        local last_no_reapir_blur_tick = 0
        local last_gasmask_breathing_tick = 0
        cheat.utility.new_heartbeat(function()
            local now = tick()
            local disable_gasmask = cheat.Toggles.disable_gasmask_breathing and cheat.Toggles.disable_gasmask_breathing.Value
            if disable_gasmask and now - last_gasmask_breathing_tick > 0.25 then
                last_gasmask_breathing_tick = now
                cheat.utility.disable_gasmask_breathing(not (gasmask_sound_cache and gasmask_sound_cache.Parent))
            end
            local no_reapir_blur = cheat.Toggles.no_reapir_blur and cheat.Toggles.no_reapir_blur.Value
            if no_reapir_blur ~= last_no_reapir_blur or (no_reapir_blur and now - last_no_reapir_blur_tick > 0.2) then
                last_no_reapir_blur_tick = now
                last_no_reapir_blur = no_reapir_blur
                cheat.utility.apply_no_reapir_blur(no_reapir_blur)
            end
        end)

        local custom_gunsound_enabled = false
        local custom_gunsound_id = "rbxassetid://3060494212"
        local custom_gunsound_volume = 1
        
        local gun_sounds = {
            ["minecraft bow"] = "rbxassetid://3442683707",
            ["oof"] = "rbxassetid://3060494212",
            ["fart"] = "rbxassetid://3068648094",
            ["hee hee"] = "rbxassetid://3048623108",
            ["this is sparta"] = "rbxassetid://130781067",
            ["godzilla"] = "rbxassetid://130783046",
            ["roger that"] = "rbxassetid://135308704",
            ["fallen pkm"] = "rbxassetid://4803858563"
        }

        custom_sound_tab:AddToggle('custom_gunsound_enable', {Text = 'Custom Gun Sound', Default = false, Callback = function(c)
            custom_gunsound_enabled = c
        end})
        custom_sound_tab:AddDropdown('custom_gunsound_select', {Text = 'Gun Sound', Default = 1, Values = {'minecraft bow', 'oof', 'fart', 'hee hee', 'this is sparta', 'godzilla', 'roger that', 'fallen pkm'}, Callback = function(v)
            custom_gunsound_id = gun_sounds[v]
        end})
        custom_sound_tab:AddSlider('custom_gunsound_vol', {Text = 'Gun Sound Volume', Default = 100, Min = 1, Max = 500, Rounding = 0, Callback = function(v)
            custom_gunsound_volume = v / 100
        end})
        custom_sound_tab:AddButton('Test Gun Sound', function()
            local sound = Instance.new("Sound")
            sound.SoundId = custom_gunsound_id
            sound.Volume = custom_gunsound_volume
            if custom_gunsound_id == "rbxassetid://7606020137" then
                sound.TimePosition = 2
                task.delay(0.9, function() if sound and sound.Parent then sound:Stop() end end)
            end
            sound.Parent = game:GetService("SoundService")
            sound:Play()
            game:GetService("Debris"):AddItem(sound, 5)
        end)

        local gun_sounds_volume = 100
        local hitmarker_sounds_volume = 100

        local gun_sound_names = {
            ["FireSound"] = true,
            ["FireFarSound"] = true,
            ["FireSoundSupressed"] = true,
        }

        local function sound_features_active()
            -- `last_hitmarker_tick` is set from this scan, and Damage Numbers needs it to
            -- know a hit was ours. Without damagenumbers_enabled here the scan never ran
            -- when only Damage Numbers was on, so hitmarker_recent was always nil and no
            -- number was ever attributed to us.
            return custom_hitsound_enabled
                or custom_gunsound_enabled
                or cheat.hitlogs_enabled
                or cheat.damagenumbers_enabled
                or gun_sounds_volume < 100
                or hitmarker_sounds_volume < 100
        end

        -- the 4 impact sounds we intercept for custom hitsound
        local hitsound_ids = {
            ["rbxassetid://4585382589"] = true,
            ["rbxassetid://4585351098"] = true,
            ["rbxassetid://4585382046"] = true,
            ["rbxassetid://4585364605"] = true,
        }

        -- all hitmarker sounds (for the volume slider)
        local hitmarker_sound_ids = {
            ["rbxassetid://4585382589"] = true,
            ["rbxassetid://4585351098"] = true,
            ["rbxassetid://4585382046"] = true,
            ["rbxassetid://4585364605"] = true,
            ["rbxassetid://9120454415"] = true,
            ["rbxassetid://4504226333"] = true,
            ["rbxassetid://6668102812"] = true,
            ["rbxassetid://9119166195"] = true,
            ["rbxassetid://4581728529"] = true,
        }

        local function check_sound_volume(sound)
            if not sound_features_active() then return end
            if not sound:IsA("Sound") then return end
            local soundid = sound.SoundId
            local is_impact = hitsound_ids[soundid]
            local is_hit = hitmarker_sound_ids[soundid]
            local is_gun = gun_sound_names[sound.Name]
            
            if is_hit then
                cheat.utility.last_hitmarker_tick = tick()
                if not is_impact and cheat.hitlogs_enabled and #cheat.hitlogs.pending > 0 then
                    local valid_shot = table.remove(cheat.hitlogs.pending, 1)
                    local str = string.format("%s hit %s on %dm", valid_shot.name, valid_shot.part, valid_shot.dist)
                    
                    local bg = cheat.utility.new_drawing("Square", {
                        Size = _Vector2new(0, 0), Position = _Vector2new(-300, cheat.hitlogs_y),
                        Color = Color3.fromRGB(20, 20, 20), Filled = true, Transparency = 1,
                        Visible = true, ZIndex = 98
                    })
                    local line = cheat.utility.new_drawing("Square", {
                        Size = _Vector2new(3, 0), Position = _Vector2new(-300, cheat.hitlogs_y),
                        Color = cheat.hitlogs_valid_color, Filled = true, Transparency = 1,
                        Visible = true, ZIndex = 99
                    })
                    local text = cheat.utility.new_drawing("Text", {
                        Text = str, Size = cheat.hitlogs_size, Font = cheat.hitlogs_font,
                        Center = false, Outline = true, Color = Color3.new(1, 1, 1),
                        Position = _Vector2new(-300, cheat.hitlogs_y), Visible = true, ZIndex = 100
                    })
                    table.insert(cheat.hitlogs.active, 1, {
                        drawing = text, bg = bg, line = line, str = str, spawn_tick = os.clock(),
                        target_y = cheat.hitlogs_y, current_x = -300
                    })
                end
            end

            -- If custom hitsound intercepts it, we do NOT want this volume scaler touching it.
            if custom_hitsound_enabled and is_impact then
                return -- Ignore impact sounds from the volume scaler if custom hitsound is taking them over
            end
            
            -- If custom gunsound intercepts it, we do NOT want this volume scaler touching it.
            if custom_gunsound_enabled and is_gun then
                sound.SoundId = custom_gunsound_id
                sound.Volume = custom_gunsound_volume
                if custom_gunsound_id == "rbxassetid://7606020137" then
                    sound.TimePosition = 2
                    task.delay(0.9, function() if sound and sound.Parent then sound:Stop() end end)
                end
                return
            end

            -- volume scaling for gun and hitmarker sounds
            if is_hit or is_gun then
                if not sound:GetAttribute("OriginalVolume") then
                    sound:SetAttribute("OriginalVolume", sound.Volume)
                end
                local vol = is_hit and hitmarker_sounds_volume or gun_sounds_volume
                sound.Volume = sound:GetAttribute("OriginalVolume") * (vol / 100)
                cheat.utility.track_connection(sound:GetPropertyChangedSignal("Volume"):Connect(function()
                    local orig_vol = sound:GetAttribute("OriginalVolume")
                    if not orig_vol then return end
                    
                    local new_vol = sound.Volume
                    local current_target_vol = is_hit and hitmarker_sounds_volume or gun_sounds_volume
                    local expected_vol = orig_vol * (current_target_vol / 100)
                    if math.abs(new_vol - expected_vol) > 0.01 then
                        sound:SetAttribute("OriginalVolume", new_vol)
                        sound.Volume = new_vol * (current_target_vol / 100)
                    end
                end))
            end
        end

        -- Unconditional, matching pin.reta V2. The gate made this handler miss hitmarker
        -- sounds whenever the only enabled feature was Damage Numbers.
        cheat.utility.track_connection(game.DescendantAdded:Connect(check_sound_volume))

        -- V2 also sweeps the existing world once at load: hitmarker sounds that were
        -- already parented (or whose SoundId was assigned after parenting) are never
        -- seen by DescendantAdded, and without them last_hitmarker_tick stays unset.
        task.spawn(function()
            local processed = 0
            for _, child in ipairs(game:GetDescendants()) do
                if child:IsA("Sound") then
                    pcall(check_sound_volume, child)
                end
                processed = processed + 1
                if processed % 400 == 0 then
                    task.wait()
                end
            end
        end)

        custom_sound_tab:AddSlider('gun_sounds_volume', {Text = 'Gun Sounds Volume', Default = 100, Min = 1, Max = 100, Rounding = 0, Callback = function(v)
            gun_sounds_volume = v
            if v < 100 then
                task.spawn(function()
                    local processed = 0
                    local stack = {game}
                    while #stack > 0 do
                        local parent = table.remove(stack)
                        for _, child in ipairs(parent:GetChildren()) do
                            stack[#stack + 1] = child
                            if gun_sounds_volume >= 100 then return end
                            if child:IsA("Sound") and gun_sound_names[child.Name] then
                                check_sound_volume(child)
                            end
                            processed = processed + 1
                            if processed % 200 == 0 then
                                task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
                            end
                        end
                    end
                end)
            end
        end})
        custom_sound_tab:AddSlider('hitmarker_sounds_volume', {Text = 'Hitmarker Volume', Default = 100, Min = 1, Max = 100, Rounding = 0, Callback = function(v)
            hitmarker_sounds_volume = v
        end})
        
        local skins_tab = settings_skinchanger_box
        local skinchanger_enabled = false
        local unlock_all_skins_enabled = false
        local cached_function_library_extension
        local function get_function_library_extension()
            if cached_function_library_extension then
                return cached_function_library_extension
            end
            local modules = ReplicatedStorage:FindFirstChild("Modules")
            local extension = modules and modules:FindFirstChild("FunctionLibraryExtension")
            if not extension then
                return nil
            end
            cached_function_library_extension = require(extension)
            return cached_function_library_extension
        end
        skins_tab:AddToggle('skinchanger_enabled', { Text = 'Skin Changer', Default = false, Callback = function(v)
            skinchanger_enabled = v
        end})
        skins_tab:AddToggle('unlock_all_skins', { Text = 'Unlock All Skins', Default = false, Callback = function(v)
            unlock_all_skins_enabled = v
        end})

        -- Knife Changer (ported from pin.reta): swaps the melee inventory
        -- reference to the chosen ItemsList entry and overlays the model in
        -- the viewmodel. Scoped in its own block to keep locals out of the
        -- enclosing function's register budget.
        do
            local knife_changer_enabled = false
            cheat.selected_melee_skin = "None"
            cheat._original_melee_refs = cheat._original_melee_refs or {}

            local known_skin_names = {
                Karambit = true, ButterflyKnife = true, IceAxe = true, PlasmaNinjato = true,
                Greatsword = true, Longsword = true, Cutlass = true, IceDagger = true,
                M9Fade = true, M9XR7 = true, AnarchyTomahawk = true, FlipKnifeShark = true,
                Kukri = true, Scythe = true, GoldenDV2 = true,
            }

            local function get_viewmodel_item()
                local camera = workspace.CurrentCamera
                local viewmodel = camera and (camera:FindFirstChild("ViewModel") or camera:FindFirstChildOfClass("Model"))
                return viewmodel and viewmodel:FindFirstChild("Item")
            end

            local function is_holding_melee()
                local pfolder = ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(LocalPlayer.Name)
                local status = pfolder and pfolder:FindFirstChild("Status")
                local gv = status and status:FindFirstChild("GameplayVariables")

                local eq_slot = gv and gv:FindFirstChild("EquippedSlot")
                if eq_slot and eq_slot.Value then
                    local sname = tostring(eq_slot.Value):lower()
                    if sname:find("back") or sname:find("hip") or sname:find("hotbar")
                        or sname:find("primary") or sname:find("secondary") or sname:find("equipment") then
                        return false
                    end
                    if sname:find("melee") then
                        return true
                    end
                end

                local eq_tool = gv and gv:FindFirstChild("EquippedTool") and gv.EquippedTool.Value
                if eq_tool then
                    local item_ref = ReplicatedStorage:FindFirstChild("ItemsList") and ReplicatedStorage.ItemsList:FindFirstChild(eq_tool.Name)
                    local props = item_ref and item_ref:FindFirstChild("ItemProperties")
                    local itype = tostring(props and props:GetAttribute("ItemType") or ""):lower()
                    local islot = tostring(props and props:GetAttribute("Slot") or ""):lower()
                    if itype:find("ranged") or islot:find("back") or islot:find("hip")
                        or islot:find("primary") or islot:find("secondary") or islot:find("hotbar") then
                        return false
                    end
                    if itype:find("melee") or islot:find("melee") then
                        return true
                    end
                end

                local item = get_viewmodel_item()
                if not item then return false end
                for _, desc in ipairs(item:GetDescendants()) do
                    local name = desc.Name:lower()
                    if name:find("receiver") or name:find("barrel") or name:find("mag")
                        or name:find("slide") or name:find("stock") or name:find("sight")
                        or name:find("muzzle") or name:find("handguard") or name:find("picatinny")
                        or name:find("bolt") then
                        return false
                    end
                end
                return true
            end

            local function apply_native_melee_skin(skin_name)
                local pfolder = ReplicatedStorage:FindFirstChild("Players") and ReplicatedStorage.Players:FindFirstChild(LocalPlayer.Name)
                local inv = pfolder and pfolder:FindFirstChild("Inventory")
                if not inv then return end

                local items_list = ReplicatedStorage:FindFirstChild("ItemsList")
                local target_item = nil
                if skin_name and skin_name ~= "None" and items_list then
                    target_item = items_list:FindFirstChild(skin_name)
                end

                for _, item in ipairs(inv:GetChildren()) do
                    if item:IsA("ObjectValue") then
                        if not cheat._original_melee_refs[item.Name] then
                            cheat._original_melee_refs[item.Name] = item.Value
                        end

                        local orig_ref = cheat._original_melee_refs[item.Name]
                        local orig_name = orig_ref and orig_ref.Name or ""
                        local lower_name = orig_name:lower()
                        local prop = orig_ref and orig_ref:FindFirstChild("ItemProperties")
                        local slot_type = prop and prop:FindFirstChild("SlotType") and prop.SlotType.Value or ""
                        local is_melee = slot_type == "Melee"
                            or lower_name:find("knife") or lower_name:find("cleaver")
                            or lower_name:find("axe") or lower_name:find("crowbar")
                            or lower_name:find("karambit") or orig_name == "DV2"

                        if is_melee then
                            if target_item then
                                pcall(function() item.Value = target_item end)
                            elseif orig_ref then
                                pcall(function() item.Value = orig_ref end)
                            end
                        end
                    end
                end
            end

            local function clear_melee_overlay()
                local item = get_viewmodel_item()
                if not item then return end
                for _, child in ipairs(item:GetChildren()) do
                    if child:IsA("Model") and known_skin_names[child.Name] then
                        child:Destroy()
                    end
                end
            end

            skins_tab:AddToggle('knife_changer_enabled', { Text = 'Knife Changer', Default = false, Callback = function(v)
                knife_changer_enabled = v
                if v then
                    apply_native_melee_skin(cheat.selected_melee_skin)
                else
                    apply_native_melee_skin("None")
                    clear_melee_overlay()
                end
            end})
            skins_tab:AddDropdown('melee_skin_swapper', {
                Text = 'Melee Skin',
                Values = {
                    'None', 'Karambit', 'ButterflyKnife', 'IceAxe', 'PlasmaNinjato',
                    'Greatsword', 'Longsword', 'Cutlass', 'IceDagger', 'M9Fade',
                    'M9XR7', 'AnarchyTomahawk', 'FlipKnifeShark', 'Kukri', 'Scythe', 'GoldenDV2'
                },
                Default = 1,
                Multi = false,
                Callback = function(v)
                    cheat.selected_melee_skin = v
                    if knife_changer_enabled then
                        clear_melee_overlay()
                        apply_native_melee_skin(v)
                    end
                end
            })

            local last_vm_mesh_update = 0
            cheat.utility.new_renderstepped(function()
                if not knife_changer_enabled then return end
                local now = os.clock()
                if now - last_vm_mesh_update < 0.2 then return end
                last_vm_mesh_update = now

                local skin_name = cheat.selected_melee_skin
                local item = get_viewmodel_item()
                local item_root = item and item:FindFirstChild("ItemRoot")

                if not is_holding_melee() then
                    clear_melee_overlay()
                    return
                end
                if not skin_name or skin_name == "None" then return end
                if not (item and item_root and item_root:IsA("BasePart")) then return end

                -- Hide the default knife parts
                for _, child in ipairs(item:GetChildren()) do
                    if child:IsA("BasePart") and child.Name ~= skin_name then
                        child.Transparency = 1
                    end
                end

                local skin_container = item:FindFirstChild(skin_name)
                if not skin_container then
                    local models = ReplicatedStorage:FindFirstChild("ItemsListModels")
                    local template = models and models:FindFirstChild(skin_name)
                    if template then
                        local clone = template:Clone()
                        clone.Name = skin_name
                        local clone_root = clone:FindFirstChild("ItemRoot")
                        if clone_root and clone_root:IsA("BasePart") then
                            pcall(function() clone:PivotTo(item_root.CFrame) end)
                            local vm_weld = Instance.new("WeldConstraint")
                            vm_weld.Name = "SkinToVMWeld"
                            vm_weld.Part0 = clone_root
                            vm_weld.Part1 = item_root
                            vm_weld.Parent = clone_root
                        end
                        clone.Parent = item
                        skin_container = clone
                    end
                end

                if skin_container then
                    for _, desc in ipairs(skin_container:GetDescendants()) do
                        if desc:IsA("BasePart") then
                            desc.Transparency = desc.Name == "ItemRoot" and 1 or 0
                        end
                    end
                end
            end)
        end
        
        task.spawn(function()
            pcall(function()
                local fl = get_function_library_extension()
                if fl and fl.UpdateSkin then
                    local old_UpdateSkin = fl.UpdateSkin
                    fl.UpdateSkin = function(self, p140, p141, p142)
                        if p140 and typeof(p140) == "Instance" and p140:IsA("ObjectValue") then
                            local forced = p140:GetAttribute("Skin")
                            if forced ~= nil then
                                p142 = (forced == "" and nil or forced)
                            end
                        end
                        return old_UpdateSkin(self, p140, p141, p142)
                    end
                    
                    if fl.FindDeepAncestor then
                        fl.FindDeepAncestor = function(self, p92, p93, p94)
                            local v95 = 0
                            if not p92 or typeof(p92) ~= "Instance" then return p92 end
                            while p92 and p92.Parent and p92.Parent.ClassName == p93 do
                                if p92.Parent.Parent and p92.Parent.Parent.Parent and p92.Parent.Parent.Parent.Name == "Attachments" then
                                    p92 = p92.Parent.Parent.Parent
                                else
                                    p92 = p92.Parent
                                end
                                v95 = v95 + 1
                                if p94 and typeof(p94) == "table" and p94.SearchForInteraction then
                                    if p92:GetAttribute(p94.SearchForInteraction) then break end
                                end
                                if v95 > 10 or p92:FindFirstChild("DeepAncestorBreak") or p92:FindFirstChild("Moving") then
                                    break
                                end
                            end
                            return p92
                        end
                    end
                end
            end)
        end)
        
        task.spawn(function()
            local rep = ReplicatedStorage
            while task.wait(2) do
                if skinchanger_enabled or unlock_all_skins_enabled then
                    pcall(function()
                        local p_purchases = rep:FindFirstChild("Players") and rep.Players:FindFirstChild(LocalPlayer.Name) and rep.Players[LocalPlayer.Name]:FindFirstChild("Status") and rep.Players[LocalPlayer.Name].Status:FindFirstChild("Purchases")
                        if p_purchases then
                            if not p_purchases:FindFirstChild("Skins") then
                                local s = Instance.new("Folder")
                                s.Name = "Skins"
                                s.Parent = p_purchases
                            end
                            local p_skins = p_purchases.Skins

                            local function unlock_from(folder_name)
                                local f = rep:FindFirstChild(folder_name)
                                if f then
                                    for _, weapon_skins in pairs(f:GetChildren()) do
                                        local p_weapon = p_skins:FindFirstChild(weapon_skins.Name)
                                        if not p_weapon then
                                            p_weapon = Instance.new("Folder")
                                            p_weapon.Name = weapon_skins.Name
                                            p_weapon.Parent = p_skins
                                        end
                                        for _, skin in pairs(weapon_skins:GetChildren()) do
                                            if not p_weapon:FindFirstChild(skin.Name) then
                                                local mock = Instance.new("Folder")
                                                mock.Name = skin.Name
                                                mock.Parent = p_weapon
                                            end
                                        end
                                    end
                                end
                            end
                            unlock_from("skins")
                            unlock_from("skin packs")
                            unlock_from("Skin Packs")
                            unlock_from("Skins")
                        end
                    end)
                end
            end
        end)
        
        task.spawn(function()
            local rep = ReplicatedStorage
            while task.wait(0.25) do
                pcall(function()
                    if not skinchanger_enabled then
                        task.wait(0.4)
                        return
                    end

                    local weapon_name = get_local_weapon()
                    if not weapon_name or weapon_name == "None" then
                        return
                    end

                    local p_inv = rep:FindFirstChild("Players") and rep.Players:FindFirstChild(LocalPlayer.Name) and rep.Players[LocalPlayer.Name]:FindFirstChild("Inventory")
                    if not p_inv then return end

                    local target_item
                    for _, item in ipairs(p_inv:GetChildren()) do
                        if item:IsA("ObjectValue") and item.Value and item.Value.Name == weapon_name then
                            target_item = item
                            break
                        end
                    end
                    if not target_item then return end

                    local forced_skin = target_item:GetAttribute("SpoofedSkin")
                    if forced_skin == nil then
                        if target_item:GetAttribute("Skin") ~= nil then
                            target_item:SetAttribute("Skin", nil)
                        end
                        return
                    end

                    local target_skin = (forced_skin == "" and nil or forced_skin)
                    if target_item:GetAttribute("Skin") ~= target_skin then
                        target_item:SetAttribute("Skin", target_skin)
                    end

                    if target_skin then
                        local fl = get_function_library_extension()
                        if not fl then return end
                        local function paint_model(parent)
                            if not parent then return end
                            local w_model = parent:FindFirstChild(weapon_name)
                            if w_model and w_model:IsA("Model") and w_model:GetAttribute("SpoofSkinApplied") ~= target_skin then
                                pcall(function()
                                    fl:UpdateSkin(target_item, w_model, target_skin)
                                    w_model:SetAttribute("SpoofSkinApplied", target_skin)
                                end)
                            end
                        end

                        paint_model(LocalPlayer.Character)
                        local cam = workspace.CurrentCamera
                        if cam then
                            for _, child in ipairs(cam:GetChildren()) do
                                if child:GetAttribute("Temp") or child.Name == LocalPlayer.Name then
                                    paint_model(child)
                                end
                            end
                        end
                    end
                end)
            end
        end)
        local player_gui = LocalPlayer:FindFirstChild("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
        cheat.utility.track_connection(player_gui.ChildAdded:Connect(function(child)
            if child.Name == "MainGui" then
                cheat.utility.track_connection(child.ChildAdded:Connect(function(sound)
                    if sound:IsA("Sound") and custom_hitsound_enabled then
                        if sound.SoundId == "rbxassetid://4585382589" or sound.SoundId == "rbxassetid://4585351098" or sound.SoundId == "rbxassetid://4585382046" or sound.SoundId == "rbxassetid://4585364605" then
                            sound.SoundId = custom_hitsound_id
                            sound.Volume = custom_hitsound_volume
                            if custom_hitsound_id == "rbxassetid://7606020137" then
                                sound.TimePosition = 2
                                task.delay(0.9, function() if sound and sound.Parent then sound:Stop() end end)
                            end
                        end
                    end
                end))
            end
        end))

        local main_gui = player_gui:FindFirstChild("MainGui")
        if main_gui then
            cheat.utility.track_connection(main_gui.ChildAdded:Connect(function(sound)
                if sound:IsA("Sound") and custom_hitsound_enabled then
                    if sound.SoundId == "rbxassetid://4585382589" or sound.SoundId == "rbxassetid://4585351098" or sound.SoundId == "rbxassetid://4585382046" or sound.SoundId == "rbxassetid://4585364605" then
                        sound.SoundId = custom_hitsound_id
                        sound.Volume = custom_hitsound_volume
                        if custom_hitsound_id == "rbxassetid://7606020137" then
                            sound.TimePosition = 2
                            task.delay(0.9, function() if sound and sound.Parent then sound:Stop() end end)
                        end
                    end
                end
            end))
        end
    end
    -- --- DESYNC (ported verbatim from pin.reta V2) ------------------------
    -- Full desync suite: offset/rotation spoofing, random position+rotation,
    -- velocity desync, look-vector spoof, peek blink, plus the visual ghost
    -- clone that mirrors your real position with a neon BoxHandleAdornment.
    -- CUSTOM DESYNC TAB (Next to CHARACTER tab in the left box)
    local dsync_tab = ui.box.move:AddTab('DESYNC')

    -- Flyhack lives in the Movement Extras box (move_extra), directly under
    -- the Movement Extras tab. It used to sit in the left box beside DESYNC.
    -- The DESYNC section continues below.
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end

    local desync_enabled = false
    local desync_visualize = false
    local desync_x_offset = 0
    local desync_y_offset = 0
    local desync_z_offset = 0
    local desync_x_rotate = 0
    local desync_y_rotate = 0
    local desync_z_rotate = 0
    local desync_random_rotation = false
    local desync_random_position = false
    local desync_random_position_range = 5
    local desync_velocity = false
    local desync_velocity_x = 0
    local desync_velocity_y = 0
    local desync_velocity_z = 0


    local desync_visualize_color = Color3.fromRGB(255, 255, 255)
    local desync_transparency = 0.5

    dsync_tab:AddToggle('desync_enabled', {Text = 'desync enabled', Default = false, Callback = function(v)
        desync_enabled = v
    end}):AddKeyPicker('desync_enabled_key', {Default = 'B', SyncToggleState = true, Mode = 'Toggle', Text = 'desync enabled', NoUI = false})

    dsync_tab:AddToggle('desync_visualize', {Text = 'visualize character', Default = false, Callback = function(v)
        desync_visualize = v
    end}):AddColorPicker('desync_visualize_color', {Default = Color3.fromRGB(255, 255, 255), Title = 'color', Transparency = 0.5, Callback = function(color, alpha)
        desync_visualize_color = color
        -- The standalone transparency slider was removed; the colour picker's own
        -- alpha slider now drives the ghost cham fade.
        if alpha ~= nil then desync_transparency = alpha end
    end})

    dsync_tab:AddSlider('desync_x_offset', {Text = 'X offset', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v)
        desync_x_offset = v
    end})
    dsync_tab:AddSlider('desync_y_offset', {Text = 'Y offset', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v)
        desync_y_offset = v
    end})
    dsync_tab:AddSlider('desync_z_offset', {Text = 'Z offset', Default = 0, Min = -10, Max = 10, Rounding = 1, Callback = function(v)
        desync_z_offset = v
    end})

    dsync_tab:AddSlider('desync_x_rotate', {Text = 'X rotate', Default = 0, Min = 0, Max = 20, Rounding = 1, Callback = function(v)
        desync_x_rotate = math.rad(v * 18)
    end})
    dsync_tab:AddSlider('desync_y_rotate', {Text = 'Y rotate', Default = 0, Min = 0, Max = 20, Rounding = 1, Callback = function(v)
        desync_y_rotate = math.rad(v * 18)
    end})
    dsync_tab:AddSlider('desync_z_rotate', {Text = 'Z rotate', Default = 0, Min = 0, Max = 20, Rounding = 1, Callback = function(v)
        desync_z_rotate = math.rad(v * 18)
    end})

    dsync_tab:AddToggle('desync_random_rotation', {Text = 'random rotation', Default = false, Callback = function(v)
        desync_random_rotation = v
    end})
    dsync_tab:AddToggle('desync_random_position', {Text = 'random position', Default = false, Callback = function(v)
        desync_random_position = v
    end})
    dsync_tab:AddSlider('desync_random_range', {Text = 'random range', Default = 5, Min = 0, Max = 25, Rounding = 1, Callback = function(v)
        desync_random_position_range = v
    end})

    dsync_tab:AddToggle('desync_velocity', {Text = 'velocity desync', Default = false, Callback = function(v)
        desync_velocity = v
    end})
    dsync_tab:AddSlider('desync_velocity_x', {Text = 'velocity X', Default = 0, Min = -16384, Max = 16384, Rounding = 0, Callback = function(v)
        desync_velocity_x = v
    end})
    dsync_tab:AddSlider('desync_velocity_y', {Text = 'velocity Y', Default = 0, Min = -16384, Max = 16384, Rounding = 0, Callback = function(v)
        desync_velocity_y = v
    end})
    dsync_tab:AddSlider('desync_velocity_z', {Text = 'velocity Z', Default = 0, Min = -16384, Max = 16384, Rounding = 0, Callback = function(v)
        desync_velocity_z = v
    end})

    local look_vector_spoof_enabled = false
    local look_vector_spoof_mode = 'Up' -- 'Up', 'Down', 'Straight', 'Custom'
    local look_vector_spoof_pitch = 89 -- pitch angle in degrees (-89 to 89)

    -- Look vector spoof lives in the Anti Aim tab (player_anti_aim_tab, created near the
    -- top of the chunk and still in scope here). The toggle/mode/pitch locals it writes
    -- are read by the desync application code below, so only the parent tab changes.
    player_anti_aim_tab:AddToggle('look_vector_spoof_enabled', {Text = 'Look Vector Spoof', Default = false, Callback = function(v)
        look_vector_spoof_enabled = v
    end})
    player_anti_aim_tab:AddDropdown('look_vector_spoof_mode', {Text = 'Look Vector Mode', Default = 1, Values = {'Up', 'Down', 'Straight', 'Custom'}, Callback = function(v)
        look_vector_spoof_mode = v
    end})
    player_anti_aim_tab:AddSlider('look_vector_spoof_pitch', {Text = 'Custom Pitch Angle', Default = 89, Min = -89, Max = 89, Rounding = 0, Suffix = '°', Callback = function(v)
        look_vector_spoof_pitch = v
    end})

    local replicated_hrp_cframe = nil
    local old_cframe = nil
    local old_velocity = nil

    cheat.utility.track_connection(RunService.Heartbeat:Connect(function()
        replicated_hrp_cframe = nil

        local char = LocalPlayer.Character
        if not char then return end
        local hum = char:FindFirstChildOfClass("Humanoid")
        local hrp = char:FindFirstChild("HumanoidRootPart")

        if not (hum and hrp) then return end

        if not feature_active(desync_enabled, 'desync_enabled_key') and not desync_turned_on then
            replicated_hrp_cframe = nil
            cheat.real_CFrame = nil
            if look_vector_spoof_enabled then
                local pitch_val = 0
                if look_vector_spoof_mode == 'Up' then
                    pitch_val = 1
                elseif look_vector_spoof_mode == 'Down' then
                    pitch_val = -1
                elseif look_vector_spoof_mode == 'Straight' then
                    pitch_val = 0
                elseif look_vector_spoof_mode == 'Custom' then
                    pitch_val = math.clamp(look_vector_spoof_pitch / 89, -1, 1)
                end

                local updatetilt_remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("UpdateTilt")
                if updatetilt_remote then
                    updatetilt_remote:FireServer(pitch_val, 0)
                end
            end
            return
        end

        if cheat.is_dead_or_respawning or (cheat.is_flying_or_tp and cheat.is_flying_or_tp()) then return end

        old_cframe = hrp.CFrame
        cheat.real_CFrame = forced_cframe or old_cframe
        old_velocity = hrp.AssemblyLinearVelocity

        local hrp_offset = CFrame.new(
            desync_x_offset,
            desync_y_offset,
            desync_z_offset
        ) * CFrame.Angles(
            desync_x_rotate,
            desync_y_rotate,
            desync_z_rotate
        )

        if desync_random_position then
            hrp_offset = hrp_offset + (
                CFrame.Angles(
                    (math.random() - math.random()) * 2 * math.pi,
                    (math.random() - math.random()) * 2 * math.pi,
                    (math.random() - math.random()) * 2 * math.pi
                ) * CFrame.new(0, 0, -desync_random_position_range)
            ).Position
        end

        if desync_random_rotation then
            hrp_offset = hrp_offset * CFrame.Angles(
                (math.random() - math.random()) * 2 * math.pi,
                (math.random() - math.random()) * 2 * math.pi,
                (math.random() - math.random()) * 2 * math.pi
            )
        end

        replicated_hrp_cframe = forced_cframe or (old_cframe * hrp_offset)

        hrp.CFrame = replicated_hrp_cframe

        if look_vector_spoof_enabled then
            local pitch_val = 0
            if look_vector_spoof_mode == 'Up' then
                pitch_val = 1
            elseif look_vector_spoof_mode == 'Down' then
                pitch_val = -1
            elseif look_vector_spoof_mode == 'Straight' then
                pitch_val = 0
            elseif look_vector_spoof_mode == 'Custom' then
                pitch_val = math.clamp(look_vector_spoof_pitch / 89, -1, 1)
            end

            local updatetilt_remote = ReplicatedStorage:FindFirstChild("Remotes") and ReplicatedStorage.Remotes:FindFirstChild("UpdateTilt")
            if updatetilt_remote then
                updatetilt_remote:FireServer(pitch_val, 0)
            end
        end

        if desync_velocity then
            hrp.AssemblyLinearVelocity = Vector3.new(
                desync_velocity_x,
                desync_velocity_y,
                desync_velocity_z
            )
        end

        RunService.RenderStepped:Wait()
        cheat.real_CFrame = nil
        if not hrp then return end

        hrp.CFrame = old_cframe
        if desync_velocity then
            hrp.AssemblyLinearVelocity = old_velocity
        end
    end))


    local desync_ghost_model = Instance.new("Model")
    desync_ghost_model.Name = "PinReta_DesyncGhost"
    desync_ghost_model.Parent = workspace.Terrain

    local ghost_parts = {}
    local ghost_chams = {}
    local last_ghost_char = nil

    local function clear_ghost_parts()
        for _, cham_obj in pairs(ghost_chams) do
            if cham_obj and cham_obj.Parent then
                pcall(function() cham_obj:Destroy() end)
            end
        end
        table.clear(ghost_chams)
        for _, clone_p in pairs(ghost_parts) do
            if clone_p and clone_p.Parent then
                pcall(function() clone_p:Destroy() end)
            end
        end
        table.clear(ghost_parts)
        last_ghost_char = nil
    end

    local function is_desync_body_part(name)
        return name == "Head" or name:find("Torso") ~= nil or name:find("Leg") ~= nil or name:find("Arm") ~= nil
    end

    local function rebuild_ghost_model(character)
        clear_ghost_parts()
        if not character then return end
        last_ghost_char = character

        for _, part in ipairs(character:GetChildren()) do
            if part:IsA("BasePart") and is_desync_body_part(part.Name) and part.Name ~= "HumanoidRootPart" then
                local clone_p = part:Clone()
                clone_p.Anchored = true
                clone_p.CanCollide = false
                clone_p.CanTouch = false
                clone_p.CanQuery = false
                clone_p.CastShadow = false
                clone_p.Transparency = 1 -- Fully transparent base part; Swim BoxHandleAdornment provides neon glow
                
                -- Clear non-mesh descendants
                for _, sub in ipairs(clone_p:GetChildren()) do
                    if not sub:IsA("SpecialMesh") then
                        sub:Destroy()
                    end
                end
                clone_p.Parent = desync_ghost_model
                ghost_parts[part] = clone_p

                -- Swim neon BoxHandleAdornment cham (same exact size and proportion as enemy chams)
                local cham_obj = Instance.new("BoxHandleAdornment")
                cham_obj.Name = "SwimDesyncCham_" .. part.Name
                cham_obj.Parent = desync_ghost_model
                cham_obj.Size = part.Size * 0.95
                cham_obj.Adornee = clone_p
                cham_obj.Shading = Enum.AdornShading.XRayShaded
                cham_obj.ZIndex = 5
                cham_obj.AlwaysOnTop = true
                ghost_chams[part] = cham_obj
            end
        end
    end

    cheat.utility.track_connection(LocalPlayer.CharacterRemoving:Connect(function()
        clear_ghost_parts()
    end))

    -- Non-blocking: "Players" is server-created; waiting for it here would stall the
    -- whole script when the game is still loading. The consumers below are guarded.
    local _rep_players_desync = ReplicatedStorage:FindFirstChild("Players")

    cheat.utility.new_renderstepped(function()
        if not desync_visualize then
            for _, cham_obj in pairs(ghost_chams) do
                if cham_obj and cham_obj.Adornee then
                    cham_obj.Adornee = nil
                end
            end
            return
        end

        local character = LocalPlayer.Character
        if not character or not character.Parent then
            clear_ghost_parts()
            return
        end

        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        if character ~= last_ghost_char then
            rebuild_ghost_model(character)
        end

        local upper_body_parts = {
            ["UpperTorso"] = true,
            ["Head"] = true,
            ["LeftUpperArm"] = true,
            ["LeftLowerArm"] = true,
            ["LeftHand"] = true,
            ["RightUpperArm"] = true,
            ["RightLowerArm"] = true,
            ["RightHand"] = true,
            ["Torso"] = true,
            ["Left Arm"] = true,
            ["Right Arm"] = true,
        }

        -- Calculate active desync offset and rotation
        local root_cf = hrp.CFrame
        local hrp_offset = CFrame.identity
        if feature_active(desync_enabled, 'desync_enabled_key') then
            hrp_offset = CFrame.new(
                desync_x_offset,
                desync_y_offset,
                desync_z_offset
            ) * CFrame.Angles(
                desync_x_rotate,
                desync_y_rotate,
                desync_z_rotate
            )

            if desync_random_position then
                hrp_offset = hrp_offset + (
                    CFrame.Angles(
                        (math.random() - math.random()) * 2 * math.pi,
                        (math.random() - math.random()) * 2 * math.pi,
                        (math.random() - math.random()) * 2 * math.pi
                    ) * CFrame.new(0, 0, -desync_random_position_range)
                ).Position
            end

            if desync_random_rotation then
                hrp_offset = hrp_offset * CFrame.Angles(
                    (math.random() - math.random()) * 2 * math.pi,
                    (math.random() - math.random()) * 2 * math.pi,
                    (math.random() - math.random()) * 2 * math.pi
                )
            end
        end

        -- Query verified UAC position (same as resolve_desync)
        local p_folder = _rep_players_desync and _rep_players_desync:FindFirstChild(LocalPlayer.Name)
        local status = p_folder and p_folder:FindFirstChild("Status")
        local uac = status and status:FindFirstChild("UAC")
        local lastpos = uac and uac:GetAttribute("LastVerifiedPos")

        local desync_root_cf
        if feature_active(desync_enabled, 'desync_enabled_key') then
            if lastpos and typeof(lastpos) == "Vector3" then
                desync_root_cf = CFrame.new(lastpos) * (root_cf * hrp_offset).Rotation
            else
                desync_root_cf = root_cf * hrp_offset
            end
        else
            if lastpos and typeof(lastpos) == "Vector3" then
                desync_root_cf = CFrame.new(lastpos) * root_cf.Rotation
            else
                desync_root_cf = root_cf
            end
        end

        local delta_cf = desync_root_cf * root_cf:Inverse()

        -- Calculate active look vector pitch tilt
        local tilt_angle = 0
        if look_vector_spoof_enabled then
            if look_vector_spoof_mode == 'Up' then
                tilt_angle = math.rad(89)
            elseif look_vector_spoof_mode == 'Down' then
                tilt_angle = math.rad(-89)
            elseif look_vector_spoof_mode == 'Straight' then
                tilt_angle = 0
            elseif look_vector_spoof_mode == 'Custom' then
                tilt_angle = math.rad(look_vector_spoof_pitch)
            end
        end

        -- First person visibility: hide completely if desync is disabled; if desync is enabled, fade/hide if closer than 3 studs
        local is_thirdperson = globals.thirdperson == true
        local dist_to_ghost = (desync_root_cf.Position - root_cf.Position).Magnitude
        local fade_ratio = 1
        if not is_thirdperson then
            if not feature_active(desync_enabled, 'desync_enabled_key') then
                fade_ratio = 0
            elseif dist_to_ghost < 3 then
                fade_ratio = math.clamp((dist_to_ghost - 0.5) / 2.5, 0, 1)
            end
        end

        if fade_ratio <= 0.001 then
            for _, cham_obj in pairs(ghost_chams) do
                if cham_obj and cham_obj.Adornee then
                    cham_obj.Adornee = nil
                end
            end
            return
        end

        local base_color = desync_visualize_color or Color3.fromRGB(255, 255, 255)
        local base_transp = desync_transparency or 0.5
        local transp = 1 - ((1 - base_transp) * fade_ratio)

        -- Apply delta CFrame + Waist tilt to each body part
        local waist_part = character:FindFirstChild("UpperTorso") or character:FindFirstChild("Torso") or hrp
        local waist_cf = waist_part.CFrame
        local tilt_rot = CFrame.Angles(tilt_angle, 0, 0)

        local count = 0
        for orig_part, clone_part in pairs(ghost_parts) do
            if orig_part and orig_part.Parent and clone_part and clone_part.Parent then
                count = count + 1
                
                local part_cf
                if tilt_angle ~= 0 and (upper_body_parts[orig_part.Name] or (orig_part.Parent and orig_part.Parent:IsA("Accessory"))) then
                    local local_to_waist = waist_cf:ToObjectSpace(orig_part.CFrame)
                    local tilted_cf = waist_cf * tilt_rot * local_to_waist
                    part_cf = delta_cf * tilted_cf
                else
                    part_cf = delta_cf * orig_part.CFrame
                end

                clone_part.CFrame = part_cf
                
                local cham_obj = ghost_chams[orig_part]
                if cham_obj and cham_obj.Parent then
                    cham_obj.Adornee = clone_part
                    cham_obj.Color3 = base_color
                    cham_obj.Transparency = transp
                    cham_obj.Size = orig_part.Size * 0.95
                end
            end
        end

        if count == 0 then
            rebuild_ghost_model(character)
        end
    end)

    -- --- GRENADE TRAJECTORY SOLVER (ported verbatim from pin.reta V2) ----------
    -- 3D neon trajectory preview with bounces, a blast-radius ring plus impact
    -- sphere, per-target line-up arcs (Auto/Flat/High) and auto-throw that aims
    -- and fires the grenade along the solved arc.
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
            -- ── 3D Grenade Trajectory & Neon Blast Range Ring System ──────────────────
        -- A wrapped tab has no AddTab (only tabboxes/groupboxes do), so the grenade
        -- controls cannot nest inside Effects. They go on a sibling tab created from
        -- the box table directly -- reached via `ui` rather than the `effects_tab`
        -- local, which is declared far enough up the chunk that it may have been
        -- pushed out of the 200-local register limit by the time execution gets here.
        local grenade_tab = ui.box.misc_sounds:AddTab('Grenade')
            local MAX_GRENADE_PARTS = 120
            local traj_folder = Instance.new("Folder")
        traj_folder.Name = "Grenade3DVisuals"
        pcall(function() traj_folder.Parent = workspace.Terrain end)

        local grenade_3d_parts = {}
        for i = 1, MAX_GRENADE_PARTS do
            local p = Instance.new("Part")
            p.Name = "TrajSeg"
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = Enum.Material.Neon
            p.Transparency = 1
            p.Size = Vector3.new(0.1, 0.1, 1)
            p.Parent = traj_folder
            grenade_3d_parts[i] = p
        end

        local impact_ball_adornment = Instance.new("SphereHandleAdornment")
        impact_ball_adornment.Name = "ImpactBallAdornment"
        impact_ball_adornment.Adornee = workspace.Terrain
        impact_ball_adornment.AlwaysOnTop = true
        impact_ball_adornment.ZIndex = 6
        impact_ball_adornment.Radius = 0.55
        impact_ball_adornment.Transparency = 0.05
        impact_ball_adornment.Visible = false
        impact_ball_adornment.Parent = traj_folder

        local blast_ring_adornment = Instance.new("CylinderHandleAdornment")
        blast_ring_adornment.Name = "BlastRingAdornment"
        blast_ring_adornment.Adornee = workspace.Terrain
        blast_ring_adornment.AlwaysOnTop = true
        blast_ring_adornment.ZIndex = 5
        blast_ring_adornment.Height = 0.08
        blast_ring_adornment.Transparency = 0.05
        blast_ring_adornment.Visible = false
        blast_ring_adornment.Parent = traj_folder

        local blast_fill_adornment = Instance.new("CylinderHandleAdornment")
        blast_fill_adornment.Name = "BlastFillAdornment"
        blast_fill_adornment.Adornee = workspace.Terrain
        blast_fill_adornment.AlwaysOnTop = true
        blast_fill_adornment.ZIndex = 4
        blast_fill_adornment.Height = 0.04
        blast_fill_adornment.Transparency = 0.78
        blast_fill_adornment.Visible = false
        blast_fill_adornment.Parent = traj_folder

        local traj_highlight = Instance.new("Highlight")
        traj_highlight.Name = "TrajHighlight"
        traj_highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
        traj_highlight.FillTransparency = 0.1
        traj_highlight.OutlineTransparency = 1
        traj_highlight.Adornee = traj_folder
        traj_highlight.Parent = traj_folder

        local grenade_impact_text = cheat.utility.new_drawing("Text", {
            Text = "",
            Size = 13,
            Font = 2,
            Center = true,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Color = Color3.fromRGB(255, 255, 255),
            Transparency = 1,
            Visible = false,
            ZIndex = 82
        })

        local MAX_TARGET_PARTS = 80
        local target_traj_parts = {}
        for i = 1, MAX_TARGET_PARTS do
            local p = Instance.new("Part")
            p.Name = "TargetTrajSeg"
            p.Anchored = true
            p.CanCollide = false
            p.CanTouch = false
            p.CanQuery = false
            p.CastShadow = false
            p.Material = Enum.Material.Neon
            p.Transparency = 1
            p.Size = Vector3.new(0.09, 0.09, 1)
            p.Parent = traj_folder
            target_traj_parts[i] = p
        end

        local target_aim_circle = cheat.utility.new_drawing("Circle", {
            Radius = 7,
            Thickness = 1.5,
            Filled = false,
            Color = cheat.grenade_target_color or Color3.fromRGB(80, 220, 255),
            Transparency = 1,
            Visible = false,
            ZIndex = 85
        })

        local target_aim_dot = cheat.utility.new_drawing("Circle", {
            Radius = 2,
            Thickness = 1,
            Filled = true,
            Color = cheat.grenade_target_color or Color3.fromRGB(80, 220, 255),
            Transparency = 1,
            Visible = false,
            ZIndex = 86
        })

        local target_aim_text = cheat.utility.new_drawing("Text", {
            Text = "",
            Size = 13,
            Font = 2,
            Center = true,
            Outline = true,
            OutlineColor = Color3.new(0, 0, 0),
            Color = Color3.fromRGB(80, 220, 255),
            Transparency = 1,
            Visible = false,
            ZIndex = 87
        })

        local function hide_grenade_trajectory()
            for i = 1, MAX_GRENADE_PARTS do
                grenade_3d_parts[i].Transparency = 1
            end
            for i = 1, MAX_TARGET_PARTS do
                target_traj_parts[i].Transparency = 1
            end
            impact_ball_adornment.Visible = false
            blast_ring_adornment.Visible = false
            blast_fill_adornment.Visible = false
            grenade_impact_text.Visible = false
            target_aim_circle.Visible = false
            target_aim_dot.Visible = false
            target_aim_text.Visible = false
        end

        local grenade_ray_params = RaycastParams.new()
        grenade_ray_params.FilterType = Enum.RaycastFilterType.Exclude
        grenade_ray_params.IgnoreWater = false
        grenade_ray_params.CollisionGroup = "WeaponRay"

        local GRENADE_PROFILES = {
            ["F1"] = {
                name = "F1",
                overhand_speed = 92,
                underhand_speed = 40,
                fuse_time = 3.0,
                is_impact = false,
                radius = 8.5,
                bounciness = 0.30
            },
            ["RGD5"] = {
                name = "RGD-5",
                overhand_speed = 108,
                underhand_speed = 46,
                fuse_time = 3.0,
                is_impact = false,
                radius = 8.5,
                bounciness = 0.38
            },
            ["RGO"] = {
                name = "RGO",
                overhand_speed = 98,
                underhand_speed = 42,
                fuse_time = 3.2,
                is_impact = true,
                radius = 17.0,
                bounciness = 0.25
            },
            ["M84"] = {
                name = "M84 Flashbang",
                overhand_speed = 116,
                underhand_speed = 50,
                fuse_time = 1.2,
                is_impact = false,
                radius = 4.5,
                bounciness = 0.45
            },
            ["Snowball"] = {
                name = "Snowball",
                overhand_speed = 122,
                underhand_speed = 54,
                fuse_time = 2.5,
                is_impact = true,
                radius = 3.0,
                bounciness = 0.05
            }
        }

        local function get_held_grenade_info()
            local rs_plrs = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
            local rs_plr = rs_plrs and rs_plrs:FindFirstChild(LocalPlayer.Name)
            local gv = rs_plr and rs_plr:FindFirstChild("Status") and rs_plr.Status:FindFirstChild("GameplayVariables")
            local eq_tool = gv and gv:FindFirstChild("EquippedTool") and gv.EquippedTool.Value
            if not eq_tool then return nil end

            local item_props = eq_tool:IsA("ObjectValue") and eq_tool.Value and (eq_tool.Value:FindFirstChild("ItemProperties") or eq_tool.Value) or (eq_tool:FindFirstChild("ItemProperties") or eq_tool)
            local item_type = item_props and (item_props:GetAttribute("ItemType") or item_props:GetAttribute("SlotType"))
            local tool_name = eq_tool.Name

            if GRENADE_PROFILES[tool_name] then
                local p = GRENADE_PROFILES[tool_name]
                return {
                    name = p.name or tool_name,
                    fuse = p.fuse_time,
                    is_rgo = p.is_impact,
                    radius = p.radius,
                    overhand_speed = p.overhand_speed,
                    underhand_speed = p.underhand_speed,
                    bounciness = p.bounciness
                }
            elseif item_type == "Grenade" or string.find(string.lower(tool_name), "grenade") or string.find(string.lower(tool_name), "f1") or string.find(string.lower(tool_name), "rgd") or string.find(string.lower(tool_name), "rgo") or string.find(string.lower(tool_name), "m84") then
                local desc = item_props and item_props:GetAttribute("Description") or ""
                local fuse_parsed = 3.0
                local match_fuse = string.match(desc, "Fuze length is set to%s*(%d+%.?%d*)%s*sec")
                if match_fuse then
                    fuse_parsed = tonumber(match_fuse) or 3.0
                end
                local is_impact = string.find(string.lower(desc), "impact") ~= nil
                local rad = 8.5
                local match_rad = string.match(desc, "fatality radius of around%s*(%d+%.?%d*)%s*metre")
                if match_rad then
                    rad = (tonumber(match_rad) or 3) * 2.83
                end
                return {
                    name = item_props and item_props:GetAttribute("ItemName") or tool_name,
                    fuse = fuse_parsed,
                    is_rgo = is_impact,
                    radius = rad,
                    overhand_speed = 100,
                    underhand_speed = 44,
                    bounciness = 0.35
                }
            end
            return nil
        end

        local function simulate_trajectory_path(start_pos, start_vel, max_time_limit, max_bounce_limit, bounciness_val, is_impact_val)
            local dt = 0.035
            local elapsed = 0
            local c_pos = start_pos
            local c_vel = start_vel
            local c_bounces = 0
            local gravity = Vector3.new(0, -(workspace.Gravity or 80), 0)
            local pts = { c_pos }
            local last_norm = Vector3.new(0, 1, 0)

            while elapsed < max_time_limit and c_bounces <= max_bounce_limit and #pts < MAX_GRENADE_PARTS do
                local next_pos = c_pos + (c_vel * dt) + (0.5 * gravity * dt * dt)
                local next_vel = (c_vel + (gravity * dt)) * 0.995
                local ray_dir = next_pos - c_pos
                if ray_dir.Magnitude < 0.01 then break end

                local ray_res = workspace:Raycast(c_pos, ray_dir, grenade_ray_params)
                if ray_res then
                    local hit_pos = ray_res.Position
                    local normal = ray_res.Normal
                    last_norm = normal
                    table.insert(pts, hit_pos)

                    if is_impact_val then break end

                    local mat_name = ray_res.Material and ray_res.Material.Name or "Default"
                    local mat_restitution_mult = 1.0
                    local mat_friction = 0.75
                    if mat_name == "Grass" or mat_name == "Ground" or mat_name == "Mud" or mat_name == "Sand" or mat_name == "Terrain" then
                        mat_restitution_mult = 0.70
                        mat_friction = 0.50
                    elseif mat_name == "Metal" or mat_name == "DiamondPlate" or mat_name == "CorrodedMetal" then
                        mat_restitution_mult = 1.15
                        mat_friction = 0.85
                    elseif mat_name == "Wood" or mat_name == "WoodPlanks" then
                        mat_restitution_mult = 0.90
                        mat_friction = 0.65
                    end
                    local effective_bounciness = bounciness_val * mat_restitution_mult

                    local dot = c_vel:Dot(normal)
                    if dot < 0 then
                        local perp = normal * dot
                        local tang = c_vel - perp
                        c_vel = (tang * mat_friction) - (perp * effective_bounciness)
                    end

                    c_bounces = c_bounces + 1
                    if c_vel.Magnitude < 6 or (normal.Y > 0.5 and math.abs(dot) < 4 and c_vel.Magnitude < 10) then
                        break
                    end
                    c_pos = hit_pos + (normal * 0.08)
                else
                    c_pos = next_pos
                    c_vel = next_vel
                    table.insert(pts, c_pos)
                end
                elapsed = elapsed + dt
            end
            return pts, last_norm
        end

        local function get_closest_enemy_target()
            if silent_aim and silent_aim.target_part and silent_aim.target_part.Parent then
                local model = silent_aim.target_part:FindFirstAncestorOfClass("Model")
                local hum = model and model:FindFirstChildOfClass("Humanoid")
                if hum and hum.Health > 0 then
                    return silent_aim.target_part, (model and model.Name or "Target")
                end
            end

            local cam_cf = Camera.CFrame
            local cam_pos = cam_cf.Position
            local mouse_x, mouse_y = Mouse.X, Mouse.Y
            local inset_y = GuiInset.Y

            local best_part = nil
            local best_name = "Target"
            local best_dist = math.huge

            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer and plr.Character then
                    local char = plr.Character
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    local hrp = char:FindFirstChild("HumanoidRootPart") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("Head")
                    if hum and hum.Health > 0 and hrp then
                        local s_pos, onscreen = _WorldToViewportPoint(Camera, hrp.Position)
                        local dx = s_pos.X - mouse_x
                        local dy = (s_pos.Y - inset_y) - mouse_y
                        local screen_dist = math.sqrt(dx * dx + dy * dy)
                        local world_dist = (cam_pos - hrp.Position).Magnitude

                        if world_dist < 600 then
                            local score = screen_dist + (world_dist * 0.4)
                            if score < best_dist then
                                best_dist = score
                                best_part = hrp
                                best_name = plr.Name
                            end
                        end
                    end
                end
            end

            return best_part, best_name
        end

        local function evaluate_trajectory(start_pos, start_vel, max_time, bounciness, is_rgo, target_pos)
            local dt = 0.038
            local elapsed = 0
            local c_pos = start_pos
            local c_vel = start_vel
            local c_bounces = 0
            local gravity = Vector3.new(0, -(workspace.Gravity or 80), 0)
            local min_dist_to_target = (c_pos - target_pos).Magnitude
            local early_wall_hit = false
            local final_pos = c_pos

            while elapsed < max_time and c_bounces <= 3 do
                local next_pos = c_pos + (c_vel * dt) + (0.5 * gravity * dt * dt)
                local next_vel = (c_vel + (gravity * dt)) * 0.995
                local ray_dir = next_pos - c_pos
                if ray_dir.Magnitude < 0.01 then break end

                local ray_res = workspace:Raycast(c_pos, ray_dir, grenade_ray_params)
                if ray_res then
                    local hit_pos = ray_res.Position
                    local normal = ray_res.Normal
                    final_pos = hit_pos

                    -- Detect hitting cover/walls directly in front of the thrower (< 6 studs)
                    if (hit_pos - start_pos).Magnitude < 6 and normal.Y < 0.5 then
                        early_wall_hit = true
                    end

                    local d_target = (hit_pos - target_pos).Magnitude
                    if d_target < min_dist_to_target then
                        min_dist_to_target = d_target
                    end

                    if is_rgo then break end

                    local dot = c_vel:Dot(normal)
                    if dot < 0 then
                        local perp = normal * dot
                        local tang = c_vel - perp
                        c_vel = (tang * 0.70) - (perp * (bounciness * 0.8))
                    end

                    c_bounces = c_bounces + 1
                    if c_vel.Magnitude < 6 or (normal.Y > 0.5 and math.abs(dot) < 4 and c_vel.Magnitude < 10) then
                        break
                    end
                    c_pos = hit_pos + (normal * 0.08)
                else
                    c_pos = next_pos
                    c_vel = next_vel
                    final_pos = c_pos
                    local d_target = (c_pos - target_pos).Magnitude
                    if d_target < min_dist_to_target then
                        min_dist_to_target = d_target
                    end
                end
                elapsed = elapsed + dt
            end

            local final_dist = (final_pos - target_pos).Magnitude
            return final_dist, min_dist_to_target, early_wall_hit, elapsed
        end

        local function solve_best_trajectory(origin, target_pos, v0, char_vel, max_time, bounciness, is_rgo, arc_mode)
            local diff = target_pos - origin
            local diff_xz = Vector3.new(diff.X, 0, diff.Z)
            local d = diff_xz.Magnitude
            if d <= 0.5 then return nil, 0 end

            local u_xz = diff_xz / d
            local g = workspace.Gravity or 80
            local v0_sq = v0 * v0
            local h = diff.Y

            -- Generate smart candidate angles (in degrees)
            local candidate_angles = {}

            -- Analytical base solutions
            local disc = (v0_sq * v0_sq) - (g * (g * d * d + 2 * h * v0_sq))
            if disc >= 0 then
                local sqrt_disc = math.sqrt(disc)
                local theta_low = math.deg(math.atan((v0_sq - sqrt_disc) / (g * d)))
                local theta_high = math.deg(math.atan((v0_sq + sqrt_disc) / (g * d)))
                table.insert(candidate_angles, theta_low)
                table.insert(candidate_angles, theta_high)
                -- Drag-compensation variations
                table.insert(candidate_angles, theta_low + 1.5)
                table.insert(candidate_angles, theta_low + 3.0)
                table.insert(candidate_angles, theta_high + 2.0)
                table.insert(candidate_angles, theta_high - 2.0)
            end

            -- Grid search angles based on selected arc mode
            local min_ang, max_ang, step_ang = -10, 75, 2.5
            if arc_mode == "Low Arc (Direct)" or arc_mode == 2 then
                min_ang, max_ang, step_ang = -10, 38, 2
            elseif arc_mode == "High Arc (Mortar Lob)" or arc_mode == 3 then
                min_ang, max_ang, step_ang = 38, 75, 2
            elseif arc_mode == "Airburst (Fuse Timed)" or arc_mode == 4 then
                min_ang, max_ang, step_ang = 5, 75, 3
            end

            for ang = min_ang, max_ang, step_ang do
                table.insert(candidate_angles, ang)
            end

            local best_aim_dir = nil
            local best_score = math.huge
            local best_final_dist = math.huge

            for _, ang_deg in ipairs(candidate_angles) do
                local theta_rad = math.rad(ang_deg)
                local d_aim = (u_xz * math.cos(theta_rad)) + (Vector3.new(0, 1, 0) * math.sin(theta_rad))

                -- Velocity momentum compensation
                local v_desired = d_aim * v0
                local v_aim_comp = v_desired - (char_vel * 0.45)
                local aim_unit = v_aim_comp.Magnitude > 0.001 and v_aim_comp.Unit or d_aim
                local v_sim = (aim_unit * v0) + (char_vel * 0.45)

                local final_dist, min_dist, early_wall, flight_time = evaluate_trajectory(origin, v_sim, max_time, bounciness, is_rgo, target_pos)

                -- Score evaluation
                local score = final_dist
                if early_wall then
                    score = score + 600 -- heavy penalty for hitting cover directly in front of player
                end

                if arc_mode == "Airburst (Fuse Timed)" or arc_mode == 4 then
                    local fuse_diff = math.abs(flight_time - max_time)
                    score = (min_dist * 2.5) + (fuse_diff * 8)
                elseif arc_mode == "Low Arc (Direct)" or arc_mode == 2 then
                    score = score + (flight_time * 1.5)
                elseif arc_mode == "High Arc (Mortar Lob)" or arc_mode == 3 then
                    score = score + (math.abs(ang_deg - 55) * 0.08)
                else -- Auto (Best Lineup)
                    score = score + (flight_time * 0.4)
                end

                if score < best_score then
                    best_score = score
                    best_aim_dir = aim_unit
                    best_final_dist = final_dist
                end
            end

            return best_aim_dir, best_final_dist
        end

        function cheat.get_grenade_aim_direction(is_overhand)
            local grenade_info = get_held_grenade_info()
            if not grenade_info then return nil end

            local t_part, _ = get_closest_enemy_target()
            if not t_part then return nil end

            local cam_cf = Camera.CFrame
            local est_pos = nil
            pcall(function()
                local fle = require(game:GetService("ReplicatedStorage").Modules.FunctionLibraryExtension)
                if fle and fle.GetEstimatedCameraPosition then
                    est_pos = fle:GetEstimatedCameraPosition(LocalPlayer)
                end
            end)
            local origin = (est_pos or cam_cf.Position) + (cam_cf.LookVector * 1.3)
            local target_pos = t_part.Position - Vector3.new(0, 1.2, 0)
            local char = LocalPlayer.Character
            local char_vel = (char and char.PrimaryPart and char.PrimaryPart.AssemblyLinearVelocity) or Vector3.zero
            local v0 = is_overhand and (grenade_info.overhand_speed or 105) or (grenade_info.underhand_speed or 45)
            local arc_mode = cheat.grenade_target_arc or 1

            local best_aim_dir, _ = solve_best_trajectory(origin, target_pos, v0, char_vel, grenade_info.fuse or 3.0, grenade_info.bounciness or 0.35, grenade_info.is_rgo, arc_mode)
            return best_aim_dir
        end

        cheat.utility.new_renderstepped(function()
            local pred_enabled = cheat.grenade_predict_enabled or (cheat.Toggles and cheat.Toggles.grenade_predict and cheat.Toggles.grenade_predict.Value)
            local target_enabled = cheat.grenade_target_lineup or (cheat.Toggles and cheat.Toggles.grenade_target_lineup and cheat.Toggles.grenade_target_lineup.Value)

            if not (pred_enabled or target_enabled) then
                hide_grenade_trajectory()
                return
            end

            local grenade_info = get_held_grenade_info()
            if not grenade_info then
                hide_grenade_trajectory()
                return
            end

            local char = LocalPlayer.Character
            if not (char and Camera) then
                hide_grenade_trajectory()
                return
            end

            local is_underhand = UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
            local throw_speed = is_underhand and (grenade_info.underhand_speed or 45) or (grenade_info.overhand_speed or 105)

            local cam_cf = Camera.CFrame
            local est_pos = nil
            pcall(function()
                local fle = require(game:GetService("ReplicatedStorage").Modules.FunctionLibraryExtension)
                if fle and fle.GetEstimatedCameraPosition then
                    est_pos = fle:GetEstimatedCameraPosition(LocalPlayer)
                end
            end)
            local origin_base = est_pos or cam_cf.Position
            local origin = origin_base + (cam_cf.LookVector * 1.3)
            local char_vel = (char.PrimaryPart and char.PrimaryPart.AssemblyLinearVelocity) or Vector3.zero
            local vel = (cam_cf.LookVector * throw_speed) + (char_vel * 0.45)

            local filter_list = { char, Camera, workspace.NoCollision, traj_folder }
            pcall(function()
                local ignorelist = require(game:GetService("ReplicatedStorage").Modules.UniversalTables).ReturnTable("GlobalIgnoreListProjectile")
                for _, inst in ipairs(ignorelist) do
                    table.insert(filter_list, inst)
                end
            end)
            grenade_ray_params.FilterDescendantsInstances = filter_list

            local max_time = grenade_info.fuse or 3.0
            local max_bounces = cheat.grenade_predict_bounce_count or 3
            local bounciness = grenade_info.bounciness or 0.35

            -- ── 1. Real-Time Thrown Trajectory ────────────────────────────────────────
            if pred_enabled then
                local points, last_normal = simulate_trajectory_path(origin, vel, max_time, max_bounces, bounciness, grenade_info.is_rgo)
                local line_color = cheat.grenade_predict_color or Color3.fromRGB(255, 80, 80)
                local impact_color = cheat.grenade_predict_impact_color or Color3.fromRGB(255, 200, 50)
                local line_idx = 1

                for i = 1, #points - 1 do
                    if line_idx > MAX_GRENADE_PARTS then break end
                    local p1, p2 = points[i], points[i + 1]
                    local dist = (p2 - p1).Magnitude
                    if dist > 0.001 then
                        local p = grenade_3d_parts[line_idx]
                        p.Size = Vector3.new(0.12, 0.12, dist)
                        p.CFrame = CFrame.lookAt((p1 + p2) * 0.5, p2)
                        p.Color = line_color
                        p.Transparency = 0.1
                        line_idx = line_idx + 1
                    end
                end

                for i = line_idx, MAX_GRENADE_PARTS do
                    grenade_3d_parts[i].Transparency = 1
                end

                local final_pt = points[#points]
                if final_pt then
                    local radius = grenade_info.radius or 8.5
                    local n = (last_normal and last_normal.Magnitude > 0.01) and last_normal.Unit or Vector3.new(0, 1, 0)
                    local right
                    if math.abs(n.Y) > 0.95 then
                        right = Vector3.new(1, 0, 0)
                    else
                        right = n:Cross(Vector3.new(0, 1, 0)).Unit
                    end
                    local up = n:Cross(right).Unit

                    -- Center impact ball (visible through walls)
                    impact_ball_adornment.CFrame = CFrame.new(final_pt + (n * 0.55))
                    impact_ball_adornment.Color3 = impact_color
                    impact_ball_adornment.Visible = true

                    -- Outer neon blast range ring (horizontal flat on ground, visible through walls)
                    blast_ring_adornment.Radius = radius
                    blast_ring_adornment.InnerRadius = math.max(0, radius - 0.45)
                    blast_ring_adornment.Color3 = impact_color
                    blast_ring_adornment.CFrame = CFrame.fromMatrix(final_pt + (n * 0.08), right, up, n)
                    blast_ring_adornment.Visible = true

                    -- Inner soft blast area fill (horizontal flat on ground, visible through walls)
                    blast_fill_adornment.Radius = radius
                    blast_fill_adornment.InnerRadius = 0
                    blast_fill_adornment.Color3 = impact_color
                    blast_fill_adornment.CFrame = CFrame.fromMatrix(final_pt + (n * 0.06), right, up, n)
                    blast_fill_adornment.Visible = true

                    traj_highlight.FillColor = line_color
                    traj_highlight.OutlineColor = line_color
                    traj_highlight.Enabled = true

                    local s_end, on_end = _WorldToViewportPoint(Camera, final_pt)
                    if on_end and s_end.Z > 0 then
                        local dist = math.floor((final_pt - cam_cf.Position).Magnitude / 2.8)
                        grenade_impact_text.Position = _Vector2new(s_end.X, s_end.Y - 20)
                        local fuse_str = grenade_info.is_rgo and "Impact" or string.format("%.1fs", grenade_info.fuse or 3.0)
                        grenade_impact_text.Text = string.format("%s [%s | Lethal: %.1fm | %dm]", grenade_info.name, fuse_str, radius / 2.8, dist)
                        grenade_impact_text.Color = impact_color
                        grenade_impact_text.Visible = true
                    else
                        grenade_impact_text.Visible = false
                    end
                else
                    impact_ball_adornment.Visible = false
                    blast_ring_adornment.Visible = false
                    blast_fill_adornment.Visible = false
                    grenade_impact_text.Visible = false
                end
            else
                for i = 1, MAX_GRENADE_PARTS do grenade_3d_parts[i].Transparency = 1 end
                impact_ball_adornment.Visible = false
                blast_ring_adornment.Visible = false
                blast_fill_adornment.Visible = false
                grenade_impact_text.Visible = false
            end

            -- ── 2. Target Lineup Trajectory & Aim Guide ──────────────────────────────
            if target_enabled then
                local t_part, t_name = get_closest_enemy_target()
                if t_part then
                    local target_pos = t_part.Position - Vector3.new(0, 1.2, 0)
                    local diff = target_pos - origin
                    local diff_xz = Vector3.new(diff.X, 0, diff.Z)
                    local d = diff_xz.Magnitude
                    local arc_mode = cheat.grenade_target_arc or 1

                    if d > 1 then
                        local best_aim_dir, best_err = solve_best_trajectory(origin, target_pos, throw_speed, char_vel, max_time, bounciness, grenade_info.is_rgo, arc_mode)

                        if best_aim_dir then
                            local t_vel = (best_aim_dir * throw_speed) + (char_vel * 0.45)
                            local t_points = simulate_trajectory_path(origin, t_vel, max_time, max_bounces, bounciness, grenade_info.is_rgo)
                            local t_color = cheat.grenade_target_color or Color3.fromRGB(80, 220, 255)
                            local t_idx = 1

                            for i = 1, #t_points - 1 do
                                if t_idx > MAX_TARGET_PARTS then break end
                                local tp1, tp2 = t_points[i], t_points[i + 1]
                                local t_dist = (tp2 - tp1).Magnitude
                                if t_dist > 0.001 then
                                    local tp = target_traj_parts[t_idx]
                                    tp.Size = Vector3.new(0.09, 0.09, t_dist)
                                    tp.CFrame = CFrame.lookAt((tp1 + tp2) * 0.5, tp2)
                                    tp.Color = t_color
                                    tp.Transparency = 0.15
                                    t_idx = t_idx + 1
                                end
                            end

                            for i = t_idx, MAX_TARGET_PARTS do
                                target_traj_parts[i].Transparency = 1
                            end

                            -- 2D Crosshair Aim Guide on screen
                            local guide_world = cam_cf.Position + (best_aim_dir * 100)
                            local s_guide, on_guide = _WorldToViewportPoint(Camera, guide_world)
                            if on_guide and s_guide.Z > 0 then
                                target_aim_circle.Position = _Vector2new(s_guide.X, s_guide.Y)
                                target_aim_circle.Color = t_color
                                target_aim_circle.Visible = true

                                target_aim_dot.Position = _Vector2new(s_guide.X, s_guide.Y)
                                target_aim_dot.Color = t_color
                                target_aim_dot.Visible = true

                                local dist_m = math.floor(d / 2.8)
                                local err_m = math.floor(best_err / 2.8 * 10) / 10
                                local is_hit = best_err < (grenade_info.radius or 8.5)
                                local arc_name = (arc_mode == 2 or arc_mode == "Low Arc (Direct)") and "LOW" or (arc_mode == 3 or arc_mode == "High Arc (Mortar Lob)") and "HIGH" or (arc_mode == 4 or arc_mode == "Airburst (Fuse Timed)") and "AIRBURST" or "AUTO"
                                local status_str = is_hit and string.format("[AIM HERE] %s (%dm | %s | Err: %.1fm)", t_name, dist_m, arc_name, err_m) or string.format("[OUT OF REACH] %s (%dm | Err: %.1fm)", t_name, dist_m, err_m)
                                target_aim_text.Position = _Vector2new(s_guide.X, s_guide.Y - 18)
                                target_aim_text.Text = status_str
                                target_aim_text.Color = is_hit and t_color or Color3.fromRGB(255, 120, 80)
                                target_aim_text.Visible = true
                            else
                                target_aim_circle.Visible = false
                                target_aim_dot.Visible = false
                                target_aim_text.Visible = false
                            end
                        else
                            for i = 1, MAX_TARGET_PARTS do target_traj_parts[i].Transparency = 1 end
                            target_aim_circle.Visible = false
                            target_aim_dot.Visible = false
                            target_aim_text.Visible = false
                        end
                    else
                        for i = 1, MAX_TARGET_PARTS do target_traj_parts[i].Transparency = 1 end
                        target_aim_circle.Visible = false
                        target_aim_dot.Visible = false
                        target_aim_text.Visible = false
                    end
                else
                    for i = 1, MAX_TARGET_PARTS do target_traj_parts[i].Transparency = 1 end
                    target_aim_circle.Visible = false
                    target_aim_dot.Visible = false
                    target_aim_text.Visible = false
                end
            else
                for i = 1, MAX_TARGET_PARTS do target_traj_parts[i].Transparency = 1 end
                target_aim_circle.Visible = false
                target_aim_dot.Visible = false
                target_aim_text.Visible = false
            end
        end)

        grenade_tab:AddToggle('grenade_predict', { Text = 'Predict Trajectory', Default = false, Tooltip = 'Renders real-time 3D neon trajectory beam, bounces, and 3D blast range ring when holding a grenade', Callback = function(v)
            cheat.grenade_predict_enabled = v
        end}):AddColorPicker('grenade_predict_color', { Default = Color3.fromRGB(255, 80, 80), Title = '3D beam color', Transparency = 0, Callback = function(v)
            cheat.grenade_predict_color = v
        end}):AddColorPicker('grenade_predict_impact_color', { Default = Color3.fromRGB(255, 200, 50), Title = 'neon ring color', Transparency = 0, Callback = function(v)
            cheat.grenade_predict_impact_color = v
        end})
        grenade_tab:AddSlider('grenade_predict_bounces', { Text = 'grenade bounces', Default = 3, Min = 1, Max = 10, Rounding = 0, Compact = true, Callback = function(v)
            cheat.grenade_predict_bounce_count = v
        end})
        grenade_tab:AddToggle('grenade_target_lineup', { Text = 'Target Lineup', Default = false, Tooltip = 'Calculates and shows the optimal throw trajectory arc and aim guide to hit the targeted player', Callback = function(v)
            cheat.grenade_target_lineup = v
        end}):AddColorPicker('grenade_target_color', { Default = Color3.fromRGB(80, 220, 255), Title = 'lineup arc color', Transparency = 0, Callback = function(v)
            cheat.grenade_target_color = v
        end})
        grenade_tab:AddDropdown('grenade_target_arc', { Text = 'target arc mode', Default = 1, Values = { 'Auto (Best Lineup)', 'Low Arc (Direct)', 'High Arc (Mortar Lob)', 'Airburst (Fuse Timed)' }, Callback = function(v)
            if v == 'Low Arc (Direct)' or v == 2 then
                cheat.grenade_target_arc = 2
            elseif v == 'High Arc (Mortar Lob)' or v == 3 then
                cheat.grenade_target_arc = 3
            elseif v == 'Airburst (Fuse Timed)' or v == 4 then
                cheat.grenade_target_arc = 4
            else
                cheat.grenade_target_arc = 1
            end
        end})
        grenade_tab:AddToggle('grenade_auto_aim', { Text = 'Auto Throw', Default = false, Tooltip = 'Automatically launches thrown grenades along the optimal trajectory arc to hit the targeted player', Callback = function(v)
            cheat.grenade_auto_aim = v
        end})
    end

    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        cheat.utility.new_heartbeat(LPH_JIT_MAX(function(delta)
            if not enabled then return end
            local character = LocalPlayer.Character
            local hrp = character and _FindFirstChild(character, "HumanoidRootPart")
            if hrp then
                local cameralook = Camera.CFrame.LookVector
                cameralook = _Vector3new(cameralook.X, 0, cameralook.Z)
                local direction = Vector3.zero
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.W) and direction + cameralook or direction;
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.S) and direction - cameralook or direction;
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.D) and direction + _Vector3new(- cameralook.Z, 0, cameralook.X) or direction;
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.A) and direction + _Vector3new(cameralook.Z, 0, - cameralook.X) or direction;
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.Space) and direction + Vector3.yAxis or direction;
                direction = _IsKeyDown(UserInputService, Enum.KeyCode.LeftControl) and direction - Vector3.yAxis or direction;
                if direction ~= Vector3.zero then
                    direction = direction.Unit
                end
                local current_cf = hrp.CFrame
                if cheat.real_CFrame then current_cf = cheat.real_CFrame end
                local new_cf = current_cf + _Vector3new(1, 0, 1) * (direction * delta * speed) + Vector3.yAxis * (direction * delta * yspeed)
                hrp.CFrame = new_cf
                if cheat.real_CFrame then cheat.real_CFrame = new_cf end
                for _, part in character:GetDescendants() do
                    if part:IsA("BasePart") then part.AssemblyLinearVelocity = Vector3.zero end
                end
            end
        end))
    end

    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local game_TweenService = game:GetService("TweenService")
        local _firing_rapidly = false
        cheat.is_dead_or_respawning = false
        cheat.last_fly_or_tp_time = 0
        cheat.is_flying_or_tp = function()
            if not cheat.Toggles then return false end
            local tp_active = cheat.Toggles.tpkill_enabled and feature_active(cheat.Toggles.tpkill_enabled.Value, 'tpkill_key')
            local fly_active = cheat.Toggles.flyhack_enabled and feature_active(cheat.Toggles.flyhack_enabled.Value, 'flyhack_bind')
            if tp_active or fly_active then
                cheat.last_fly_or_tp_time = tick()
                cheat.real_CFrame = nil
                return true
            elseif cheat.last_fly_or_tp_time > 0 and (tick() - cheat.last_fly_or_tp_time < 1.2) then
                cheat.real_CFrame = nil
                return true
            end
            return false
        end
        
        local __index; __index = hookmetamethod(game, "__index", newcclosure(LPH_NO_VIRTUALIZE(function(self, k)
            if checkcaller() then return __index(self, k) end
            
            if k == "Trail" and typeof(self) == "Instance" and self.Name == "VisualTracer" then
                local real_trail = self:FindFirstChild("Trail")
                if real_trail then return real_trail end
                return Instance.new("Trail")
            end
            
            if k == "Handle" and typeof(self) == "Instance" and self:IsA("Accessory") then
                local handle = self:FindFirstChild("Handle")
                if handle then return handle end
                local dummy = Instance.new("Part")
                dummy.Name = "Handle"
                dummy.Transparency = 1
                return dummy
            end
            
            if (k == "CFrame" or k == "Position") and cheat.desync_active and cheat.real_CFrame and not cheat.is_dead_or_respawning and not cheat.is_flying_or_tp() then
                local char = LocalPlayer.Character
                if char and typeof(self) == "Instance" and self == char:FindFirstChild("HumanoidRootPart") then
                    if k == "CFrame" then return cheat.real_CFrame end
                    if k == "Position" then return cheat.real_CFrame.Position end
                end
            end
            return __index(self, k)
        end)))
        local __newindex; __newindex = hookmetamethod(game, "__newindex", newcclosure(LPH_NO_VIRTUALIZE(function(self, k, v)
            if checkcaller() then return __newindex(self, k, v) end
            if self == Lighting then
                if k == "ClockTime" and globals.EnableTime then return end
                if k == "GlobalShadows" and globals.noshadows then return end
                if k == "Ambient" and globals.gradientenabled then return end
                if k == "OutdoorAmbient" and globals.gradientenabled then return end
                if k == "ExposureCompensation" or k == "Brightness" then return end
            end
            if self == Camera then
                if k == "FieldOfView" and (globals.fov_enabled or globals.zoom_enabled) then
                    return
                end
            end
            return __newindex(self, k, v)
        end)))
        local __namecall; __namecall = hookmetamethod(game, "__namecall", newcclosure(function(self, ...)
            -- Capture varargs once, immediately, before any nested closure touches them
            local args = { ... }
            local argCount = select("#", ...)

            -- Caller check AFTER capture so we can safely forward args
            if checkcaller() then
                return __namecall(self, unpack(args, 1, argCount))
            end

            local method = getnamecallmethod()
            local methodstr = tostring(method)

            -- Fast early-out: if the method can't possibly be handled, forward immediately
            if methodstr ~= "Raycast"
                and methodstr ~= "GetAttribute"
                and methodstr ~= "Play"
                and methodstr ~= "InvokeServer"
                and methodstr ~= "invokeServer"
                and methodstr ~= "FireServer"
                and methodstr ~= "fireServer"
                and methodstr ~= "Create" then
                setnamecallmethod(methodstr)
                return __namecall(self, unpack(args, 1, argCount))
            end

            -- ═══════════════════════════════════════════════════════════════════
            --  Remote invocations (InvokeServer / FireServer)
            -- ═══════════════════════════════════════════════════════════════════
            if methodstr == "InvokeServer" or methodstr == "invokeServer"
                or methodstr == "FireServer" or methodstr == "fireServer" then

                local success, rname = pcall(function() return self.Name end)

                -- ── Anti Drown: swallow the client's Drowning FireServer ───────
                -- Handled here rather than with a second hookmetamethod call,
                -- because re-hooking __namecall would replace this whole hook and
                -- kill silent aim / Raycast interception.
                if success and rname == "Drowning" and cheat._anti_drown then
                    return nil
                end

                -- ── ChangeSkin: tag spoofed skin ───────────────────────────────
                if success and rname == "ChangeSkin" then
                    local weaponObj = args[1]
                    local skinName = args[2]
                    if weaponObj then
                        if tostring(skinName) == "Default" then
                            pcall(function() weaponObj:SetAttribute("SpoofedSkin", "") end)
                        else
                            pcall(function() weaponObj:SetAttribute("SpoofedSkin", tostring(skinName)) end)
                        end
                        return true
                    end
                end

                -- ── ServerProjectile: Auto Throw grenade aim (ported from pin.reta V2) ──
                -- A defines the toggle and cheat.get_grenade_aim_direction but never
                -- consumed it, so Auto Throw could never fire. V2 rewrites the throw
                -- direction here when the remote carries a Vector3 arg.
                if success and rname == "ServerProjectile" and typeof(args[1]) == "Vector3" then
                    local auto_aim_enabled = cheat.grenade_auto_aim
                        or (cheat.Toggles and cheat.Toggles.grenade_auto_aim and cheat.Toggles.grenade_auto_aim.Value)
                    if auto_aim_enabled and cheat.get_grenade_aim_direction then
                        local is_overhand = args[2] == true
                        local auto_dir = cheat.get_grenade_aim_direction(is_overhand)
                        if auto_dir then
                            args[1] = auto_dir
                            setnamecallmethod(methodstr)
                            return __namecall(self, unpack(args, 1, argCount))
                        end
                    end
                end

                -- ── ProjectileInflict: "new" method seed timing + validation override + hitlogs ──
                if success and rname == "ProjectileInflict" then
                    if silent_aim_shot_active() and silent_aim.method == "new" and args[3] then
                        local info = cheat._sa_bullet_infos[args[3]]
                        if info then
                            args[4] = info[2] + 5
                            cheat._sa_bullet_infos[args[3]] = nil
                        end
                    end

                    if silent_aim_shot_active()
                        and silent_aim.instant
                        and silent_aim.instant_method == "validation override"
                        and silent_aim.target_part
                        and silent_aim.target_part.Parent
                    then
                        args[1] = silent_aim.target_part
                        args.n = math.max(args.n or 1, 1)
                    end

                    if cheat.hitlogs_enabled and args[1] and typeof(args[1]) == "Instance" then
                        local target_part = args[1]
                        local target_char = target_part.Parent
                        local target_name = target_char and target_char.Name or "Unknown"
                        local hum = target_char and target_char:FindFirstChild("Humanoid")
                        if target_name ~= "Unknown" and hum and Camera then
                            local dist = math.floor((target_part.Position - Camera.CFrame.p).Magnitude / 2.8)
                            table.insert(cheat.hitlogs.pending, {
                                name = target_name,
                                part = target_part.Name,
                                dist = dist,
                                tick = os.clock()
                            })
                        end
                    end
                end

                -- ── FireProjectile: "new" method seed capture + silent aim spoofing ──
                if success and rname == "FireProjectile" then
                    if silent_aim then
                        silent_aim._exact_fire_tick = tick()
                        -- Hitscan arms its one-frame teleport window here too, so a
                        -- manual shot gets the same spoofed origin as an autoshot.
                        if silent_aim.hitscanning then
                            silent_aim._hitscan_fire_tick = silent_aim._exact_fire_tick
                        end
                    end

                    if silent_aim_shot_active() and silent_aim.method == "new" then
                        local seed = args[2]
                        local timing = args[3]
                        if seed then
                            cheat._sa_bullet_infos[seed] = { args[1], timing, args[3] }
                        end
                    end

                    local is_empty = false
                    local weapon_name = get_local_weapon and get_local_weapon() or "None"
                    if weapon_name ~= "None" then
                        local rpplrs = ReplicatedStorage:FindFirstChild("Players")
                        local rpinv = rpplrs and rpplrs:FindFirstChild(LocalPlayer.Name) and rpplrs[LocalPlayer.Name]:FindFirstChild("Inventory")
                        local inv_weapon = rpinv and rpinv:FindFirstChild(weapon_name)
                        if inv_weapon and inv_weapon:FindFirstChild("SettingsModule") then
                            local magazine = _FindFirstChild(inv_weapon, "Attachments") and _FindFirstChild(inv_weapon.Attachments, "Magazine") and inv_weapon.Attachments.Magazine:FindFirstChildOfClass("StringValue")
                            local loadedammo = magazine and magazine:FindFirstChild("ItemProperties") and magazine.ItemProperties:FindFirstChild("LoadedAmmo")
                            local ammo_count = 0
                            if loadedammo then
                                if loadedammo:IsA("Folder") then
                                    ammo_count = #loadedammo:GetChildren()
                                else
                                    ammo_count = loadedammo:GetAttribute("LoadedAmmo") or loadedammo:GetAttribute("Ammo") or 0
                                end
                            end
                            if not magazine or ammo_count <= 0 then
                                is_empty = true
                            end
                        end
                    end
                    if is_empty then
                        return
                    end

                    local real_orig = Camera.CFrame.p
                    local origin_spoofed = false

                    if silent_aim.corner_shoot and silent_aim.manipulated_origin then
                        real_orig = silent_aim.manipulated_origin
                        origin_spoofed = true
                    elseif cheat.freecam_enabled then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("Head") then
                            real_orig = char.Head.Position
                            origin_spoofed = true
                        end
                    end

                    if origin_spoofed and cheat.freecam_enabled then
                        local hit_pos = Mouse.Hit.Position
                        args[1] = (hit_pos - real_orig).Unit
                    end

                    -- "instant hit" method only: back-date the projectile timestamp.
                    -- Gated on instant_method so choosing "Silent force-hit" or
                    -- "validation override" does not also drag the timing, which
                    -- would stack two force-hit methods at once. (Matches pin.reta V2.)
                    if not _firing_rapidly and (silent_aim_active() or rage_bot_active()) and silent_aim.instant
                        and silent_aim.instant_method == "instant hit" and silent_aim.target_part then
                        local dist = (silent_aim.target_part.Position - real_orig).Magnitude
                        args[3] = tick() - (dist / 1000)
                    end

                    setnamecallmethod(methodstr)
                    return __namecall(self, unpack(args, 1, argCount))
                end
            end

            -- ═══════════════════════════════════════════════════════════════════
            --  TweenService:Create FieldOfView spoof
            -- ═══════════════════════════════════════════════════════════════════
            if methodstr == "Create" then
                if not (self == game_TweenService and (globals.fov_enabled or globals.zoom_enabled)) then
                    setnamecallmethod(methodstr)
                    return __namecall(self, unpack(args, 1, argCount))
                end
                if args[1] == Camera and rawget(args[3], "FieldOfView") then
                    args[3] = {}
                    setnamecallmethod(methodstr)
                    return __namecall(self, unpack(args, 1, argCount))
                end
                setnamecallmethod(methodstr)
                return __namecall(self, unpack(args, 1, argCount))
            end

            -- ═══════════════════════════════════════════════════════════════════
            --  Sound:Play volume scaling
            -- ═══════════════════════════════════════════════════════════════════
            if methodstr == "Play" then
                if not ((cheat._gun_sounds_volume and cheat._gun_sounds_volume() < 100) or (cheat._hitmarker_sounds_volume and cheat._hitmarker_sounds_volume() < 100)) then
                    setnamecallmethod(methodstr)
                    return __namecall(self, unpack(args, 1, argCount))
                end
                if typeof(self) == "Instance" and self.ClassName == "Sound" then
                    local sname = self.Name
                    local gun_vol = cheat._gun_sounds_volume and cheat._gun_sounds_volume() or 100
                    if gun_vol < 100 then
                        if sname == "FireSound" or sname == "FireFarSound" or sname == "FireSoundSupressed" then
                            if gun_vol == 0 then return end
                            if not self:GetAttribute("OriginalVolume") then
                                self:SetAttribute("OriginalVolume", self.Volume)
                            end
                            self.Volume = self:GetAttribute("OriginalVolume") * (gun_vol / 100)
                        end
                    end
                    local hit_vol = cheat._hitmarker_sounds_volume and cheat._hitmarker_sounds_volume() or 100
                    if hit_vol < 100 then
                        if sname == "Helmet" or sname == "BodyArmor" or sname == "Bodyshot" or sname == "Headshot" or sname == "Kill" or sname == "BarbedWire" or sname == "Vehicle" or sname == "Burn" or self.SoundId == "rbxassetid://4581728529" then
                            if hit_vol == 0 then return end
                            if not self:GetAttribute("OriginalVolume") then
                                self:SetAttribute("OriginalVolume", self.Volume)
                            end
                            self.Volume = self:GetAttribute("OriginalVolume") * (hit_vol / 100)
                        end
                    end
                end
                setnamecallmethod(methodstr)
                return __namecall(self, unpack(args, 1, argCount))
            end

            -- ═══════════════════════════════════════════════════════════════════
            --  GetAttribute: nospread / projectile drop / drag spoof
            -- ═══════════════════════════════════════════════════════════════════
            if methodstr == "GetAttribute" then
                if not (silent_aim and (silent_aim.nospread or silent_aim_active())) then
                    setnamecallmethod(methodstr)
                    return __namecall(self, unpack(args, 1, argCount))
                end
                local attribute = args[1]
                if silent_aim.nospread and attribute == "AccuracyDeviation" then
                    return 0
                end
                if silent_aim_active() then
                    if attribute == "ProjectileDrop" then return 0 end
                    if attribute == "Drag" then return 0 end
                end
                setnamecallmethod(methodstr)
                return __namecall(self, unpack(args, 1, argCount))
            end

            -- ═══════════════════════════════════════════════════════════════════
            --  Raycast: silent aim redirect / freecam origin spoof
            -- ═══════════════════════════════════════════════════════════════════
            if methodstr == "Raycast" then
                if not (cheat.freecam_enabled or (silent_aim and silent_aim.target_part and silent_aim_shot_active())) then
                    setnamecallmethod(methodstr)
                    return __namecall(self, unpack(args, 1, argCount))
                end

                local origin = args[1]
                if typeof(origin) == "Vector3" then
                    if cheat.freecam_enabled then
                        local char = LocalPlayer.Character
                        if char and char:FindFirstChild("Head") then
                            origin = char.Head.Position
                            args[1] = origin
                        end
                    end

                    if silent_aim_shot_active() and silent_aim.target_part then
                        local hitpart = silent_aim.target_part
                        if hitpart and hitpart.Parent then
                            if silent_aim.method == "new" then
                                -- Only intercept the Bullet module's own raycast (swim stack check)
                                if not debug.traceback():find("Bullet") then
                                    setnamecallmethod(methodstr)
                                    return __namecall(self, unpack(args, 1, argCount))
                                end
                                if has_silent_aim_origin() and not silent_aim.rage_bot_active then
                                    origin = silent_aim.manipulated_origin
                                    args[1] = origin
                                end
                                local force_collision = silent_aim.magic_bullet
                                    or (silent_aim.instant and silent_aim.instant_method == "Silent force-hit")
                                local can_force_collision = silent_aim.testwallbang
                                    or silent_aim.isvisible
                                    or silent_aim.manipulated_origin ~= nil
                                if force_collision and can_force_collision then
                                    local direction = hitpart.Position - origin
                                    return {
                                        Instance = hitpart,
                                        Position = hitpart.Position,
                                        Normal = direction.Unit * -1,
                                        Material = hitpart.Material,
                                        Distance = direction.Magnitude
                                    }
                                end
                                args[2] = hitpart.Position - origin
                                setnamecallmethod(methodstr)
                                return __namecall(self, unpack(args, 1, argCount))
                            else
                                if has_silent_aim_origin() and not silent_aim.rage_bot_active then
                                    origin = silent_aim.manipulated_origin
                                    args[1] = origin
                                end
                                local direction = hitpart.Position - origin
                                args[2] = direction
                                return {
                                    Instance = hitpart,
                                    Position = hitpart.Position,
                                    Normal = direction.Unit * -1,
                                    Material = hitpart.Material,
                                    Distance = direction.Magnitude
                                }
                            end
                        end
                    end
                end

                setnamecallmethod(methodstr)
                return __namecall(self, unpack(args, 1, argCount))
            end

            -- Fallback (should never be reached due to early-out above)
            setnamecallmethod(methodstr)
            return __namecall(self, unpack(args, 1, argCount))
        end))

        -- Register the metamethod hooks so cheat.utility.unload() can restore them.
        -- The unload loop already supports this {instance, metamethod, func} shape,
        -- but these three were never recorded -- so unloading left __index /
        -- __newindex / __namecall hooked on `game` after the script was removed.
        cheat.hooks.__index = { instance = game, metamethod = "__index", func = __index }
        cheat.hooks.__newindex = { instance = game, metamethod = "__newindex", func = __newindex }
        cheat.hooks.__namecall = { instance = game, metamethod = "__namecall", func = __namecall }

    end
    -- Script controls are added in the Settings tab after the config/theme managers initialize.

    -- â”€â”€â”€ ANTI-AIM TAB â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local aa = player_anti_aim_tab

        local aa_enabled = false
        local aa_modes = { "Flip" }
        local aa_spin_yaw = 0
        local aa_animation_track = nil
        local aa_animation_mode = nil
        local aa_original_hip_height = 0
        local aa_flip_applied = false
        local aa_flip_connection = nil
        local aa_spin_connection = nil

        local function aa_has_mode(mode)
            if type(aa_modes) == "table" then
                for _, selected in ipairs(aa_modes) do
                    if selected == mode then
                        return true
                    end
                end
            end
            return aa_modes == mode
        end

        local function aa_has_real_mode()
            if type(aa_modes) == "table" then
                for _, selected in ipairs(aa_modes) do
                    if selected == "Flip" or selected == "Spin" then
                        return true
                    end
                end
                return false
            end
            return aa_modes == "Flip" or aa_modes == "Spin"
        end

        local function bend_aa_limbs(char, enabled)
            if not char then return end
            local leg_angle = enabled and math.rad(15) or 0
            for _, name in ipairs({"LeftHip", "LeftKnee", "RightHip", "RightKnee"}) do
                local joint = char:FindFirstChild(name, true)
                if joint and joint:IsA("Motor6D") then
                    joint.Transform = CFrame.Angles(leg_angle, 0, 0)
                end
            end

            local arm_angle = enabled and math.rad(90) or 0
            for _, name in ipairs({"LeftShoulder", "RightShoulder"}) do
                local joint = char:FindFirstChild(name, true)
                if joint and joint:IsA("Motor6D") then
                    joint.Transform = CFrame.Angles(-arm_angle, 0, 0)
                end
            end
        end

        local function set_aa_soft_collision(char, enabled)
            if not char then return end
            local head = char:FindFirstChild("Head")
            if head then
                head.CanCollide = not enabled
            end
            for _, part in pairs(char:GetChildren()) do
                if part:IsA("Accessory") then
                    local handle = part:FindFirstChild("Handle")
                    if handle then
                        handle.CanCollide = not enabled
                        handle.Massless = enabled
                    end
                elseif part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                    part.CanCollide = not enabled
                    part.Massless = enabled
                end
            end
        end

        local function apply_flip_state(char, hum, enabled)
            if enabled then
                if not (char and hum) then return end
                local hrp = char:FindFirstChild("HumanoidRootPart")
                local head = char:FindFirstChild("Head")
                if not (hrp and head) then return end
                if aa_original_hip_height == 0 then
                    aa_original_hip_height = hum.HipHeight
                end
                hum.HipHeight = -2.5
                hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, false)
                hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, false)
                bend_aa_limbs(char, true)
                set_aa_soft_collision(char, true)
                if not aa_flip_connection then
                    aa_flip_connection = cheat.utility.track_connection(RunService.Stepped:Connect(function(_, delta)
                        local aa_active = feature_active(aa_enabled, 'aa_bind')
                        if not aa_active or not aa_has_mode("Flip") or not char.Parent then
                            if aa_flip_connection then
                                aa_flip_connection:Disconnect()
                                aa_flip_connection = nil
                            end
                            return
                        end

                        local current_hrp = char:FindFirstChild("HumanoidRootPart")
                        local current_head = char:FindFirstChild("Head")
                        local current_hum = char:FindFirstChildOfClass("Humanoid")
                        if not (current_hrp and current_head and current_hum) then return end

                        local cam_look = Camera.CFrame.LookVector
                        local flat_look = Vector3.new(cam_look.X, 0, cam_look.Z)
                        if flat_look.Magnitude < 0.001 then return end
                        flat_look = flat_look.Unit

                        local yaw = math.atan2(-flat_look.X, -flat_look.Z)
                        if aa_has_mode("Spin") then
                            aa_spin_yaw = aa_spin_yaw + math.rad(5)
                            yaw = yaw + aa_spin_yaw
                        end
                        current_hrp.CFrame = CFrame.new(current_hrp.Position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(math.rad(180), 0, 0)
                        current_hrp.AssemblyAngularVelocity = Vector3.zero
                        current_head.CanCollide = false
                        set_aa_soft_collision(char, true)

                        local state = current_hum:GetState()
                        if state == Enum.HumanoidStateType.FallingDown or state == Enum.HumanoidStateType.Freefall then
                            current_hum:ChangeState(Enum.HumanoidStateType.Running)
                        end
                    end))
                end
                aa_flip_applied = true
                return
            end

            if aa_flip_connection then
                aa_flip_connection:Disconnect()
                aa_flip_connection = nil
            end

            if not aa_flip_applied then
                return
            end

            local current_char = char or LocalPlayer.Character
            local current_hum = hum or (current_char and current_char:FindFirstChildOfClass("Humanoid"))
            if current_hum then
                current_hum.HipHeight = aa_original_hip_height ~= 0 and aa_original_hip_height or 2
                current_hum:SetStateEnabled(Enum.HumanoidStateType.GettingUp, true)
                current_hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                current_hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                current_hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            bend_aa_limbs(current_char, false)
            set_aa_soft_collision(current_char, false)
            if current_char then
                for _, part in pairs(current_char:GetChildren()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = true
                        part.Massless = false
                    end
                end
            end
            aa_flip_applied = false
        end

        local function apply_spin_state(char, enabled)
            if enabled then
                if aa_spin_connection then
                    return
                end
                aa_spin_connection = cheat.utility.track_connection(RunService.Stepped:Connect(function()
                    local aa_active = feature_active(aa_enabled, 'aa_bind')
                    if not aa_active or not aa_has_mode("Spin") or aa_has_mode("Flip") then
                        if aa_spin_connection then
                            aa_spin_connection:Disconnect()
                            aa_spin_connection = nil
                        end
                        return
                    end

                    local current_char = LocalPlayer.Character
                    local hrp = current_char and current_char:FindFirstChild("HumanoidRootPart")
                    if not (hrp and current_char.Parent) then return end
                    hrp.CFrame = hrp.CFrame * CFrame.Angles(0, math.rad(5), 0)
                    hrp.AssemblyAngularVelocity = Vector3.zero
                end))
                return
            end

            if aa_spin_connection then
                aa_spin_connection:Disconnect()
                aa_spin_connection = nil
            end
        end

        local function stop_aa_animation()
            if aa_animation_track then
                pcall(function()
                    aa_animation_track:Stop(0.1)
                    aa_animation_track:Destroy()
                end)
                aa_animation_track = nil
            end
            aa_animation_mode = nil
        end

        local function play_aa_animation(mode)
            if aa_animation_track and aa_animation_mode == mode and aa_animation_track.IsPlaying then
                return
            end

            stop_aa_animation()

            local character = LocalPlayer.Character
            local humanoid = character and character:FindFirstChildOfClass("Humanoid")
            if not humanoid then
                warn("[GHOST_HOOK AA] Humanoid not found for animation")
                return
            end

            local animator = humanoid:FindFirstChildOfClass("Animator")
            if not animator then
                animator = Instance.new("Animator")
                animator.Parent = humanoid
                print("[GHOST_HOOK AA] Animator created")
            end

            local animation = Instance.new("Animation")
            animation.AnimationId = "rbxassetid://129527357489083"

            local ok, track = pcall(function()
                return animator:LoadAnimation(animation)
            end)
            animation:Destroy()

            if not ok or not track then
                warn("[GHOST_HOOK AA] Failed to load animation track")
                return
            end

            track.Looped = true
            track.Priority = Enum.AnimationPriority.Action
            track:Play(0.1)

            aa_animation_track = track
            aa_animation_mode = mode

            task.delay(0.15, function()
                if aa_animation_track == track and not track.IsPlaying then
                    warn("[GHOST_HOOK AA] Animation track loaded but is not playing")
                end
            end)
        end

        aa:AddToggle('aa_enabled', {Text = 'Anti Aim', Default = false, Callback = function(v)
            aa_enabled = v
            if not v and LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") then
                stop_aa_animation()
                apply_flip_state(LocalPlayer.Character, LocalPlayer.Character:FindFirstChildOfClass("Humanoid"), false)
                apply_spin_state(nil, false)
                LocalPlayer.Character.Humanoid.AutoRotate = true
                cheat.real_CFrame = nil
                cheat.desync_active = false
            end
        end}):AddKeyPicker('aa_bind', {Default = 'F', SyncToggleState = true, Mode = 'Toggle', Text = 'Anti Aim', NoUI = false})
        
        aa:AddDropdown('aa_mode', {Text = 'Anti Aim Mode', Default = {"Flip"}, Values = {"Flip", "Spin"}, Multi = true, Callback = function(v)
            aa_modes = type(v) == "table" and v or { v }
        end})

        -- Fake Lag Desync and the Server Position visualiser were removed with the
        -- tab. The AA desync CFrame-restore below still reads this flag, so it stays
        -- a plain local (permanently off) instead of being deleted outright.
        local fake_lag_enabled = false

        local aa_custom_offset = false
        player_fake_lag_tab:AddToggle('aa_custom_offset', {Text = 'Position Offset', Default = false, Callback = function(v)
            aa_custom_offset = v
        end})
        
        local aa_custom_offset_radius = 5
        player_fake_lag_tab:AddSlider('aa_custom_offset_radius', {Text = 'Offset Radius', Default = 5, Min = 1, Max = 5, Rounding = 1, Callback = function(v)
            aa_custom_offset_radius = v
        end})

        -- UG Resolver (hold X)
        local ug_resolver_enabled = false
        local ug_resolver_holding = false
        local ug_resolver_depth = 30
        player_fake_lag_tab:AddToggle('ug_resolver', {Text = 'UG Resolver (Hold X)', Default = false, Callback = function(v)
            ug_resolver_enabled = v
            if not v then ug_resolver_holding = false end
        end})
        player_fake_lag_tab:AddSlider('ug_resolver_depth', {Text = 'UG Resolver Depth', Default = 30, Min = 5, Max = 100, Rounding = 0, Callback = function(v)
            ug_resolver_depth = v
        end})

        -- ─── Anti Drown (ported from pin.reta V2) ─────────────────────────────
        -- Two layers: the Drowning FireServer is swallowed inside the main
        -- __namecall hook (see the Anti Drown early-out there), and this
        -- Heartbeat keeps forcing GameplayVariables.Drowning back to false so the
        -- drown state never latches locally.
        -- Shared via `cheat`: the __namecall hook that swallows the Drowning remote
        -- sits in a *sibling* block, so a local here was never visible to it
        -- (same scope trap as peek_blink / auto_refill_mag).
        player_fake_lag_tab:AddToggle('anti_drown', {Text = 'Anti Drown', Default = false, Callback = function(v)
            cheat._anti_drown = v and true or false
        end})

        -- Heartbeat attribute reset.
        cheat.utility.new_heartbeat(function()
            if not cheat._anti_drown then return end
            local rs_players = game:GetService("ReplicatedStorage"):FindFirstChild("Players")
            local rs_player = rs_players and rs_players:FindFirstChild(LocalPlayer.Name)
            local status = rs_player and rs_player:FindFirstChild("Status")
            local gameplay = status and status:FindFirstChild("GameplayVariables")
            if gameplay and gameplay:GetAttribute("Drowning") ~= false then
                pcall(function() gameplay:SetAttribute("Drowning", false) end)
            end
        end)

        local function UGRESOLVER()
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end
            
            -- Store the current velocity to prevent momentum building up (which triggers fall damage on return)
            local originalCF = hrp.CFrame
            local originalVel = hrp.AssemblyLinearVelocity
            
            hrp.CFrame = originalCF * CFrame.new(0, -ug_resolver_depth, 0)
            hrp.AssemblyLinearVelocity = Vector3.zero
            
            task.delay(0.10, function()
                if hrp and hrp.Parent then
                    hrp.CFrame = originalCF
                    -- Kill any downward velocity that built up while underground
                    hrp.AssemblyLinearVelocity = Vector3.new(originalVel.X, 0, originalVel.Z)
                end
            end)
        end

        -- Desync State
        cheat.real_CFrame = nil
        local current_jitter_offset = Vector3.zero
        local target_jitter_offset = Vector3.zero
        local fake_lag_CFrame = nil
        local last_fake_lag_time = 0
        local server_pos_cham = nil
        cheat.desync_active = false

        local function restore_antiaim_rotation()
            stop_aa_animation()
            apply_flip_state(nil, nil, false)
            apply_spin_state(nil, false)
            cheat.desync_active = false
            cheat.real_CFrame = nil
            fake_lag_CFrame = nil

            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if hum then
                pcall(function()
                    hum.AutoRotate = true
                    hum:SetStateEnabled(Enum.HumanoidStateType.FallingDown, true)
                    hum:SetStateEnabled(Enum.HumanoidStateType.Ragdoll, true)
                end)
            end
        end
        
        if LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("Humanoid") and LocalPlayer.Character.Humanoid.Health <= 0 then
            cheat.is_dead_or_respawning = true
        end
        
        cheat.utility.track_connection(LocalPlayer.CharacterAdded:Connect(function()
            cheat.is_dead_or_respawning = true
            task.delay(0.5, function()
                cheat.is_dead_or_respawning = false
            end)
        end))

        -- Restore CFrame before physics so local client acts completely normal physically
        cheat.utility.track_connection(RunService.Stepped:Connect(function()
            local aa_active = feature_active(aa_enabled, 'aa_bind')
            -- Fake Lag Desync was removed with its tab, so the desync
            -- CFrame-restore is now gated on anti-aim alone.
            if not aa_active or cheat.is_dead_or_respawning then
                restore_antiaim_rotation()
                return
            end
            if cheat.is_flying_or_tp() then
                if aa_active and aa_has_mode("Flip") then
                    return
                end
                restore_antiaim_rotation()
                return
            end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and cheat.real_CFrame then
                local linVel = hrp.AssemblyLinearVelocity
                local angVel = hrp.AssemblyAngularVelocity
                hrp.CFrame = cheat.real_CFrame
                hrp.AssemblyLinearVelocity = linVel
                hrp.AssemblyAngularVelocity = angVel
            end
        end))

        -- Restore CFrame before camera so no visual stutter
        RunService:BindToRenderStep("AADesyncRestore", 0, function()
            local aa_active = feature_active(aa_enabled, 'aa_bind')
            -- Fake Lag Desync was removed with its tab, so the desync
            -- CFrame-restore is now gated on anti-aim alone.
            if not aa_active or cheat.is_dead_or_respawning then
                restore_antiaim_rotation()
                return
            end
            if cheat.is_flying_or_tp() then
                if aa_active and aa_has_mode("Flip") then
                    return
                end
                restore_antiaim_rotation()
                return
            end
            local char = LocalPlayer.Character
            if not char then return end
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp and cheat.real_CFrame then
                local linVel = hrp.AssemblyLinearVelocity
                local angVel = hrp.AssemblyAngularVelocity
                hrp.CFrame = cheat.real_CFrame
                hrp.AssemblyLinearVelocity = linVel
                hrp.AssemblyAngularVelocity = angVel
            end
        end)

        -- Heartbeat: Anti-Aim (server-facing rotation spoof)
        cheat.utility.new_heartbeat(function(delta)
            local aa_active = feature_active(aa_enabled, 'aa_bind')
            if not aa_active or not aa_has_real_mode() or cheat.is_dead_or_respawning then
                stop_aa_animation()
                apply_flip_state(nil, nil, false)
                apply_spin_state(nil, false)
                if not fake_lag_enabled then
                    cheat.real_CFrame = nil
                    cheat.desync_active = false
                end
                return
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not (hrp and hum) then return end

            hum.AutoRotate = false
            cheat.desync_active = true
            play_aa_animation("AntiAim")

            local flip_selected = aa_has_mode("Flip")
            apply_flip_state(char, hum, flip_selected)
            apply_spin_state(char, aa_has_mode("Spin") and not flip_selected)
            if flip_selected then
                cheat.real_CFrame = nil
                return
            end

            if aa_has_mode("Spin") then
                cheat.real_CFrame = nil
                return
            end

            cheat.real_CFrame = nil
        end)

        -- Input handlers for UG Resolver (X)
        cheat.utility.track_connection(UserInputService.InputBegan:Connect(function(input, gp)
            if gp then return end
            if input.KeyCode == Enum.KeyCode.X and ug_resolver_enabled then
                ug_resolver_holding = true
                task.spawn(function()
                    while ug_resolver_holding and ug_resolver_enabled do
                        UGRESOLVER()
                        task.wait(0.12)
                    end
                end)
            end
        end))
        
        cheat.utility.track_connection(UserInputService.InputEnded:Connect(function(input)
            if input.KeyCode == Enum.KeyCode.X then
                ug_resolver_holding = false
            end
        end))
    end

    -- â”€â”€â”€ COMBAT EXTRAS â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local combat_extras = ui.box.move_extra:AddTab('TP Kill')

        local tpkill_enabled = false
        local tpkill_height = 200
        local tpkill_start_time = 0
        local tpkill_last_used = 0
        local tpkill_original_cf = nil
        local current_tp_target = nil
        local fake_platform = nil
        local tpkill_display_progress = 1
        local tpkill_master_enabled = false

        local tpkill_color1 = Color3.fromRGB(128, 0, 128) -- Purple
        local tpkill_color2 = Color3.fromRGB(0, 0, 139)   -- Dark Blue

        local function setTPKillActive(v)
            v = v and true or false
            if tpkill_enabled == v then return end
            tpkill_enabled = v

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if v then
                -- Cooldown check
                if tick() - tpkill_last_used < 5 then
                    tpkill_enabled = false
                    if cheat.Toggles.tpkill_enabled then cheat.Toggles.tpkill_enabled:SetValue(false) end
                    cheat.Library:Notify("TP Kill", "On cooldown!")
                    return
                end

                -- Use silent aim target if available AT ACTIVATION
                local target_part = silent_aim and silent_aim.target_part
                if not target_part then
                    target_part = get_closest_target(
                        silent_aim.fov, silent_aim.fov_size, silent_aim.part,
                        silent_aim.target_npc, false, silent_aim.rage_max_dist,
                        silent_aim.target_heli
                    )
                end
                if target_part then
                    current_tp_target = target_part
                    tpkill_original_cf = hrp.CFrame
                    tpkill_start_time = tick()

                    -- Invisible fake platform so the server believes we are grounded
                    fake_platform = Instance.new("Part")
                    fake_platform.Size = Vector3.new(10, 1, 10)
                    fake_platform.Anchored = true
                    fake_platform.CanCollide = true
                    fake_platform.Transparency = 1
                    fake_platform.Name = "TPKillPlatform"
                    fake_platform.Parent = char

                    -- Add to the projectile ignore list so our own bullets pass through it
                    pcall(function()
                        local il = require(ReplicatedStorage.Modules.UniversalTables).ReturnTable("GlobalIgnoreListProjectile")
                        if il then table.insert(il, fake_platform) end
                    end)

                    local new_pos = current_tp_target.Position + Vector3.new(0, tpkill_height, 0)
                    hrp.CFrame = CFrame.new(new_pos) * hrp.CFrame.Rotation
                    -- Hold fire until the server has verified this position.
                    pcall(function()
                        if cheat.tpkill then cheat.tpkill.arm(new_pos) end
                    end)
                    cheat.Library:Notify("TP Kill", "Teleported above targeted enemy")
                else
                    current_tp_target = nil
                    tpkill_enabled = false
                    if cheat.Toggles.tpkill_enabled then cheat.Toggles.tpkill_enabled:SetValue(false) end
                    cheat.Library:Notify("TP Kill", "No silent aim target found in FOV")
                end
            else
                -- Only start the cooldown if we actually teleported
                if tpkill_original_cf then tpkill_last_used = tick() end

                if tpkill_original_cf and hrp then
                    hrp.CFrame = tpkill_original_cf + Vector3.new(0, 2, 0)
                    if cheat.real_CFrame then cheat.real_CFrame = hrp.CFrame end
                    tpkill_original_cf = nil
                    pcall(function()
                        if cheat.tpkill then cheat.tpkill.clear() end
                    end)
                    current_tp_target = nil
                    cheat.Library:Notify("TP Kill", "Returned to original position")

                    if fake_platform then
                        fake_platform:Destroy()
                        fake_platform = nil
                    end

                    -- Force Landed so no fall damage is pending
                    local hum = char and char:FindFirstChildOfClass("Humanoid")
                    local root = char and char:FindFirstChild("HumanoidRootPart")
                    if root then root.AssemblyLinearVelocity = Vector3.new(0, 0, 0) end
                    if hum then hum:ChangeState(Enum.HumanoidStateType.Landed) end
                end
            end
        end

        -- Called by cheat.tpkill.update once the round is away, so the teleport ends
        -- itself instead of lasting until the toggle is switched off by hand. Goes
        -- through the toggle so the UI state stays in sync with tpkill_enabled.
        cheat._tpkill_force_off = function()
            if cheat.Toggles and cheat.Toggles.tpkill_enabled then
                cheat.Toggles.tpkill_enabled:SetValue(false)
            else
                setTPKillActive(false)
            end
        end

        local tpkill_tog = combat_extras:AddToggle('tpkill_enabled', {Text = 'TP Kill', Default = false, Callback = function(v)
            tpkill_master_enabled = v
            setTPKillActive(feature_active(tpkill_master_enabled, 'tpkill_key'))
        end})
        tpkill_tog:AddKeyPicker('tpkill_key', {Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'TP Kill', NoUI = false, Callback = function()
            setTPKillActive(feature_active(tpkill_master_enabled, 'tpkill_key'))
        end})

        combat_extras:AddSlider('tpkill_height', {Text = 'Height Offset', Default = 200, Min = 5, Max = 300, Rounding = 0, Callback = function(v)
            tpkill_height = v
            if tpkill_enabled then
                local char = LocalPlayer.Character
                local hrp = char and char:FindFirstChild("HumanoidRootPart")
                if hrp and current_tp_target and current_tp_target.Parent then
                    local new_pos = current_tp_target.Position + Vector3.new(0, tpkill_height, 0)
                    hrp.CFrame = CFrame.new(new_pos) * hrp.CFrame.Rotation
                end
            end
        end})

        local tpkill_glow_size = 5
        local tpkill_glow_color = tipanel_settings.glowcolor
        combat_extras:AddSlider('tpkill_glow_size', {Text = 'Neon Glow Size', Default = 5, Min = 1, Max = 15, Rounding = 0, Callback = function(v)
            tpkill_glow_size = v
        end})

        local tpkill_show_bar = true
        combat_extras:AddToggle('tpkill_show_bar', {Text = 'Show Charge Bar', Default = true, Callback = function(v)
            tpkill_show_bar = v
        end})

        local tpkill_autolook = false
        combat_extras:AddToggle('tpkill_autolook', {Text = 'Auto Look at Target', Default = false, Callback = function(v)
            tpkill_autolook = v
        end})

        local tpkill_autotbot = false
        combat_extras:AddToggle('tpkill_autotbot', {Text = 'Auto Triggerbot', Default = false, Callback = function(v)
            tpkill_autotbot = v
        end})

        -- Auto Look processing
        RunService:BindToRenderStep("TPKillAutoLook", 201, function()
            if tpkill_enabled and current_tp_target and current_tp_target.Parent then
                if tpkill_autolook then
                    workspace.CurrentCamera.CFrame = CFrame.new(workspace.CurrentCamera.CFrame.Position, current_tp_target.Position)
                end
            end
        end)

        -- Glowing edges via the Drawing API
        local tpkill_bar_glow = {}
        for i = 1, 6 do
            tpkill_bar_glow[i] = cheat.utility.new_drawing("Square", {})
            tpkill_bar_glow[i].Filled = false
            tpkill_bar_glow[i].Color = tipanel_settings.glowcolor
            tpkill_bar_glow[i].Thickness = i
            tpkill_bar_glow[i].Transparency = 0.2 - (i * 0.03)
            tpkill_bar_glow[i].ZIndex = 0
            tpkill_bar_glow[i].Visible = false
        end

        local tpkill_bar_bg = cheat.utility.new_drawing("Square", {})
        tpkill_bar_bg.Thickness = 1
        tpkill_bar_bg.Filled = false
        tpkill_bar_bg.Color = Color3.new(0, 0, 0)
        tpkill_bar_bg.ZIndex = 2
        tpkill_bar_bg.Visible = false

        -- Gradient charge bar
        local tpk_gui = Instance.new("ScreenGui")
        tpk_gui.Name = "TPKillBarGUI"
        tpk_gui.DisplayOrder = 1000
        tpk_gui.IgnoreGuiInset = true
        pcall(function()
            tpk_gui.Parent = (gethui and gethui()) or game:GetService("CoreGui")
        end)

        local tpk_clip = Instance.new("Frame", tpk_gui)
        tpk_clip.ClipsDescendants = true
        tpk_clip.BackgroundTransparency = 1
        tpk_clip.BorderSizePixel = 0
        tpk_clip.Visible = false

        local tpk_fill = Instance.new("Frame", tpk_clip)
        tpk_fill.BorderSizePixel = 0
        tpk_fill.BackgroundColor3 = Color3.new(1, 1, 1)

        local tpk_grad = Instance.new("UIGradient", tpk_fill)
        tpk_grad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, tpkill_color2),
            ColorSequenceKeypoint.new(1, tpkill_color1)
        })
        local tpk_grad_color1, tpk_grad_color2 = tpkill_color1, tpkill_color2

        -- Heartbeat: charge bar rendering + fly-bypass position pinning
        cheat.utility.new_heartbeat(function(delta)
            local now = tick()
            local is_active = tpkill_enabled
            local time_since_used = now - tpkill_last_used

            local progress = 1
            if is_active then
                progress = math.clamp(1 - ((now - tpkill_start_time) / 5), 0, 1)
            elseif tpkill_last_used > 0 then
                progress = math.clamp(time_since_used / 5, 0, 1)
            end

            local frame_delta = math.clamp(tonumber(delta) or 0, 0, 0.1)
            local smooth_alpha = 1 - math.exp(-16 * frame_delta)
            tpkill_display_progress += (progress - tpkill_display_progress) * smooth_alpha
            if math.abs(progress - tpkill_display_progress) < 0.0005 then
                tpkill_display_progress = progress
            end

            if tpkill_show_bar then
                local viewport = Camera.ViewportSize
                local center = Vector2.new(viewport.X / 2, viewport.Y / 2)
                local bar_width = 100
                local bar_height = 6
                local bar_pos = center + Vector2.new(-bar_width / 2, 20)

                for i = 1, 6 do
                    local th = (i / 6) * tpkill_glow_size
                    local tr = 0.3 - (i * 0.04)
                    tpkill_bar_glow[i].Visible = true
                    tpkill_bar_glow[i].Color = tpkill_glow_color
                    tpkill_bar_glow[i].Thickness = math.max(1, th)
                    tpkill_bar_glow[i].Transparency = tr
                    tpkill_bar_glow[i].Size = Vector2.new(bar_width, bar_height) + Vector2.new(th * 2, th * 2)
                    tpkill_bar_glow[i].Position = bar_pos - Vector2.new(th, th)
                end

                tpkill_bar_bg.Visible = true
                tpkill_bar_bg.Size = Vector2.new(bar_width, bar_height)
                tpkill_bar_bg.Position = bar_pos

                tpk_clip.Visible = true
                tpk_clip.Size = UDim2.new(0, bar_width * tpkill_display_progress, 0, bar_height)
                tpk_clip.Position = UDim2.new(0, bar_pos.X, 0, bar_pos.Y)
                tpk_fill.Size = UDim2.new(0, bar_width, 0, bar_height)

                if tpk_grad_color1 ~= tpkill_color1 or tpk_grad_color2 ~= tpkill_color2 then
                    tpk_grad_color1, tpk_grad_color2 = tpkill_color1, tpkill_color2
                    tpk_grad.Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, tpkill_color2),
                        ColorSequenceKeypoint.new(1, tpkill_color1)
                    })
                end
            else
                for i = 1, 6 do tpkill_bar_glow[i].Visible = false end
                tpkill_bar_bg.Visible = false
                tpk_clip.Visible = false
            end

            if not tpkill_enabled then return end

            -- Automatic 5s timeout
            if now - tpkill_start_time >= 5 then
                if cheat.Toggles.tpkill_enabled then cheat.Toggles.tpkill_enabled:SetValue(false) end
                return
            end

            local char = LocalPlayer.Character
            local hrp = char and char:FindFirstChild("HumanoidRootPart")
            if not hrp then return end

            if current_tp_target and current_tp_target.Parent then
                -- Continuously force position to fight rubberbanding, but keep our
                -- rotation free so we can still aim while teleported.
                local frozen_pos = current_tp_target.Position + Vector3.new(0, tpkill_height, 0)
                hrp.CFrame = CFrame.new(frozen_pos) * hrp.CFrame.Rotation

                if fake_platform then
                    fake_platform.CFrame = CFrame.new(frozen_pos - Vector3.new(0, 3.5, 0))
                end
            end
        end)
    end

    -- â”€â”€â”€ MISC EXTRAS: Bunny Hop + No Fall Damage (misc tab) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local misctab_mv = ui.box.move_extra:AddTab('Movement Extras')

        -- Bunny Hop
        local bunnyhop_enabled = false
        local bunnyhop_active = false
        local last_jump_time = 0
        local bunnyhop_power = 22
        misctab_mv:AddToggle('bunnyhop_enabled', {Text = 'Bunny Hop', Default = false, Callback = function(v)
            bunnyhop_enabled = v
        end}):AddKeyPicker('bunnyhop_key', {Default = 'None', Mode = 'Hold', Text = 'Bunny Hop', NoUI = false, Callback = function(v)
            bunnyhop_active = v
        end})
        misctab_mv:AddSlider('bunnyhop_power', {Text = 'Jump Power', Default = 22, Min = 1, Max = 28, Rounding = 0, Callback = function(v)
            bunnyhop_power = v
        end})

        -- No Fall Damage
        local no_fall = false
        misctab_mv:AddToggle('no_fall', {Text = 'No Fall Damage', Default = false, Callback = function(v)
            no_fall = v
        end})

        -- ─── Car Speedhack ─────────────────────────────────────────────────────
        -- While seated in a VehicleSeat, overrides the driven part's velocity with
        -- your current heading multiplied by the slider. The part is the biggest
        -- non-massless, non-anchored BasePart in the vehicle's assembly (the massless
        -- decorative parts do not drive anything). Re-resolved on every re-seat.
        local car_speed_enabled = false
        local car_speed_mult = 3
        local car_state = { hum = nil, seat = nil, part = nil }

        local function car_resolve(hum)
            local seat = hum and hum.SeatPart
            if not seat or not seat:IsA("VehicleSeat") then return nil, nil end
            local model = seat:FindFirstAncestorOfClass("Model")
            if not model then return nil, nil end
            local best, bestvol
            local root = model.PrimaryPart or seat
            -- Prefer the assembly root so the velocity write is not fought by welds.
            pcall(function()
                local asm = root.AssemblyRootPart
                if asm and not asm.Anchored then best = asm; bestvol = math.huge end
            end)
            for _, d in ipairs(model:GetDescendants()) do
                if d:IsA("BasePart") and not d.Anchored and not d.Massless then
                    local sz = d.Size
                    local vol = sz.X * sz.Y * sz.Z
                    if vol > (bestvol or 0) then best = d; bestvol = vol end
                end
            end
            return seat, best
        end

        misctab_mv:AddToggle('carspeedhack_enabled', {Text = 'Car Speedhack', Default = false, Callback = function(v)
            car_speed_enabled = v and true or false
            if not car_speed_enabled then car_state = { hum = nil, seat = nil, part = nil } end
        end})
        misctab_mv:AddSlider('carspeedhack_mult', {Text = 'Car Speed Multiplier', Default = 3, Min = 1, Max = 10, Rounding = 1, Callback = function(v)
            car_speed_mult = v
        end})

        cheat.utility.new_heartbeat(function()
            if not car_speed_enabled then return end
            local char = LocalPlayer.Character
            local hum = char and char:FindFirstChildOfClass("Humanoid")
            if not hum then car_state = { hum = nil, seat = nil, part = nil } return end

            local seat = hum.SeatPart
            if not seat or not seat:IsA("VehicleSeat") then
                car_state = { hum = nil, seat = nil, part = nil }
                return
            end
            -- Re-resolve when we board a different seat (or the part disappeared).
            if car_state.hum ~= hum or car_state.seat ~= seat
                or not car_state.part or not car_state.part.Parent then
                local s, p = car_resolve(hum)
                car_state = { hum = hum, seat = s, part = p }
            end
            local part = car_state.part
            if not part or not part.Parent then return end

            local vel = part.AssemblyLinearVelocity
            local flat = Vector3.new(vel.X, 0, vel.Z)
            local speed = flat.Magnitude
            local mult = math.clamp(tonumber(car_speed_mult) or 3, 1, 10)
            -- Only boost to a sane cap: an unbounded multiplier reliably gets you
            -- flung or rubber-banded by the server.
            local MAX_CAR_SPEED = 320
            if speed > 0.5 and speed * mult > speed and speed < MAX_CAR_SPEED then
                local target = math.min(speed * mult, MAX_CAR_SPEED)
                local dir = flat.Unit
                part.AssemblyLinearVelocity = Vector3.new(
                    dir.X * target,
                    vel.Y,
                    dir.Z * target
                )
            end
        end)

        -- Underworld Walk
        local underworld_enabled = false
        local underworld_running = false
        local underworld_move_connection
        local underworld_jump_connection
        local underworld_camera_connection
        local underworld_mouse_connection
        local underworld_lock_connection
        local underworld_target
        local underworld_align_pos
        local underworld_align_ori
        local underworld_att0
        local underworld_att1
        local underworld_camera_yaw = 0
        local underworld_camera_pitch = 0
        local underworld_min_pitch = math.rad(-85)
        local underworld_max_pitch = math.rad(85)

        local function setUnderworldCollision(char, enabled)
            if not char then return end
            for _, part in ipairs(char:GetDescendants()) do
                if part:IsA("BasePart") then
                    if enabled then
                        part.CanCollide = part.Name == "LeftHand" or part.Name == "RightHand" or part.Name == "Head"
                    else
                        part.CanCollide = true
                    end
                end
            end
        end

        local function disableUnderworldWalk()
            if underworld_move_connection then underworld_move_connection:Disconnect() underworld_move_connection = nil end
            if underworld_jump_connection then underworld_jump_connection:Disconnect() underworld_jump_connection = nil end
            if underworld_camera_connection then underworld_camera_connection:Disconnect() underworld_camera_connection = nil end
            if underworld_mouse_connection then underworld_mouse_connection:Disconnect() underworld_mouse_connection = nil end
            if underworld_lock_connection then underworld_lock_connection:Disconnect() underworld_lock_connection = nil end
            if underworld_align_pos then underworld_align_pos:Destroy() underworld_align_pos = nil end
            if underworld_align_ori then underworld_align_ori:Destroy() underworld_align_ori = nil end
            if underworld_att0 then underworld_att0:Destroy() underworld_att0 = nil end
            if underworld_att1 then underworld_att1:Destroy() underworld_att1 = nil end
            if underworld_target then underworld_target:Destroy() underworld_target = nil end

            UserInputService.MouseBehavior = Enum.MouseBehavior.Default
            if workspace.CurrentCamera then
                workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
            end

            local char = LocalPlayer.Character
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if root then
                root.Velocity = Vector3.zero
                root.RotVelocity = Vector3.zero
                root.Anchored = true
            end
            if hum then
                hum.PlatformStand = false
                hum.AutoRotate = true
                hum:ChangeState(Enum.HumanoidStateType.GettingUp)
            end
            task.defer(function()
                if root and root.Parent then
                    root.Anchored = false
                end
            end)
            if char and char.Parent then
                setUnderworldCollision(char, false)
                char:SetAttribute("UnderworldWalkActive", false)
            end
            underworld_running = false
        end

        local function enableUnderworldWalk()
            if underworld_running then return end

            local char = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local root = char and char:FindFirstChild("HumanoidRootPart")
            local hum = char and char:FindFirstChild("Humanoid")
            if not char or not root or not hum then return end

            root.Velocity = Vector3.zero
            root.RotVelocity = Vector3.zero
            root.Anchored = false
            hum.PlatformStand = true
            hum.AutoRotate = false
            setUnderworldCollision(char, true)

            local upperTorso = char:FindFirstChild("UpperTorso")
            if upperTorso then
                for _, joint in ipairs(upperTorso:GetChildren()) do
                    if joint:IsA("Motor6D") and (joint.Name == "RightShoulder" or joint.Name == "LeftShoulder") then
                        joint.C0 = joint.C0 * CFrame.Angles(0, 0, math.rad(160))
                    end
                end
            end

            char:SetAttribute("UnderworldWalkActive", true)

            underworld_target = Instance.new("Part")
            underworld_target.Name = "GhostHookUnderworldTarget"
            underworld_target.Size = Vector3.new(1, 1, 1)
            underworld_target.Transparency = 1
            underworld_target.CanCollide = false
            underworld_target.Anchored = true
            underworld_target.Position = root.Position - Vector3.new(0, 1, 0)
            underworld_target.Parent = workspace

            underworld_att0 = Instance.new("Attachment")
            underworld_att0.Parent = root
            underworld_att1 = Instance.new("Attachment")
            underworld_att1.Parent = underworld_target

            underworld_align_pos = Instance.new("AlignPosition")
            underworld_align_pos.Attachment0 = underworld_att0
            underworld_align_pos.Attachment1 = underworld_att1
            underworld_align_pos.RigidityEnabled = true
            underworld_align_pos.MaxForce = 4000
            underworld_align_pos.Responsiveness = 0.25
            underworld_align_pos.Parent = root

            underworld_align_ori = Instance.new("AlignOrientation")
            underworld_align_ori.Attachment0 = underworld_att0
            underworld_align_ori.Attachment1 = underworld_att1
            underworld_align_ori.RigidityEnabled = true
            underworld_align_ori.MaxTorque = 4000
            underworld_align_ori.Responsiveness = 0.25
            underworld_align_ori.PrimaryAxisOnly = false
            underworld_align_ori.Parent = root

            local raycastParams = RaycastParams.new()
            raycastParams.FilterDescendantsInstances = { char, underworld_target }
            raycastParams.FilterType = Enum.RaycastFilterType.Exclude

            local isJumping = false
            local jumpElapsed = 0
            local jumpHeight = 3
            local jumpDuration = 0.5
            local fixedYRot = 0

            underworld_jump_connection = UserInputService.JumpRequest:Connect(function()
                if not isJumping and char and char:GetAttribute("UnderworldWalkActive") then
                    isJumping = true
                    jumpElapsed = 0
                end
            end)

            underworld_move_connection = RunService.Heartbeat:Connect(function(dt)
                if not char or not char.Parent or not root.Parent or not char:GetAttribute("UnderworldWalkActive") then
                    return
                end

                root.RotVelocity = Vector3.zero
                root.Velocity = Vector3.new(root.Velocity.X, 0, root.Velocity.Z)

                local moveDir = hum.MoveDirection
                if moveDir.Magnitude < 0.1 then moveDir = Vector3.zero end
                local speed = hum.WalkSpeed or 16
                local currentPos = underworld_target.Position
                local floorResult = workspace:Raycast(currentPos + Vector3.new(0, 5, 0), Vector3.new(0, -20, 0), raycastParams)
                local floorY = floorResult and floorResult.Position.Y or currentPos.Y
                local targetYOffset = -1

                if isJumping then
                    jumpElapsed = jumpElapsed + dt
                    local progress = jumpElapsed / jumpDuration
                    if progress >= 1 then
                        isJumping = false
                    else
                        targetYOffset = -1 + jumpHeight * math.sin(progress * math.pi)
                    end
                end

                underworld_target.CFrame = CFrame.new(
                    currentPos.X + moveDir.X * speed * dt,
                    floorY + targetYOffset,
                    currentPos.Z + moveDir.Z * speed * dt
                ) * CFrame.Angles(-math.pi / 2, fixedYRot, 0)
            end)

            UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
            underworld_lock_connection = UserInputService.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton2 then
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                end
            end)

            underworld_mouse_connection = UserInputService.InputChanged:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseMovement then
                    local delta = input.Delta
                    local sensitivity = 0.008
                    underworld_camera_yaw = underworld_camera_yaw + delta.X * sensitivity
                    underworld_camera_pitch = math.clamp(underworld_camera_pitch - delta.Y * sensitivity, underworld_min_pitch, underworld_max_pitch)
                end
            end)

            underworld_camera_connection = RunService.RenderStepped:Connect(function()
                if not char or not char.Parent then return end
                local liveRoot = char:FindFirstChild("HumanoidRootPart")
                local camera = workspace.CurrentCamera
                if not liveRoot or not camera then return end

                local headPos = liveRoot.Position + Vector3.new(0, 5.5, 0)
                local direction = Vector3.new(
                    math.cos(underworld_camera_yaw) * math.cos(underworld_camera_pitch),
                    math.sin(underworld_camera_pitch),
                    math.sin(underworld_camera_yaw) * math.cos(underworld_camera_pitch)
                )
                camera.CameraType = Enum.CameraType.Scriptable
                camera.CFrame = CFrame.lookAt(headPos, headPos + direction * 100)
            end)

            underworld_running = true
        end

        misctab_mv:AddToggle('underworld_walk', {Text = 'Underworld Walk', Default = false, Callback = function(v)
            underworld_enabled = v
            if not v then
                disableUnderworldWalk()
            end
        end}):AddKeyPicker('underworld_walk_key', {Default = 'None', SyncToggleState = true, Mode = 'Toggle', Text = 'Underworld Walk', NoUI = false})

        LocalPlayer.CharacterAdded:Connect(function()
            if underworld_running then
                disableUnderworldWalk()
                task.defer(function()
                    if feature_active(underworld_enabled, 'underworld_walk_key') then
                        enableUnderworldWalk()
                    end
                end)
            end
        end)

        -- Bunny hop heartbeat
        cheat.utility.new_heartbeat(function(delta)
            if not feature_active(bunnyhop_enabled, 'bunnyhop_key') then return end
            local now = tick()
            if now - last_jump_time < 0.5 then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            if hum and hum:GetState() ~= Enum.HumanoidStateType.Freefall then
                local hrp = char:FindFirstChild("HumanoidRootPart")
                if hrp then
                    hrp.Velocity = Vector3.new(0, bunnyhop_power, 0)
                    last_jump_time = now
                end
            end
        end)

        -- No fall damage heartbeat
        cheat.utility.new_heartbeat(function(delta)
            if not no_fall then return end
            local char = LocalPlayer.Character
            if not char then return end
            local hum = char:FindFirstChild("Humanoid")
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hum and hrp then
                if hum:GetState() == Enum.HumanoidStateType.Freefall then
                    if hrp.AssemblyLinearVelocity.Y < -12.5 then
                        hum:ChangeState(Enum.HumanoidStateType.Landed)
                    end
                end
            end
        end)

        cheat.utility.new_heartbeat(function()
            if feature_active(underworld_enabled, 'underworld_walk_key') then
                enableUnderworldWalk()
            elseif underworld_running then
                disableUnderworldWalk()
            end
        end)
    end
    do
        local fmvb = ui.box.move_extra:AddTab('Flyhack')
        local fly_enabled, fly_speed, fly_yspeed = false, 10, 10

        fmvb:AddToggle('flyhack_enabled', {
            Text = 'Flyhack',
            Default = false,
            Callback = function(first)
                fly_enabled = first
            end
        }):AddKeyPicker('flyhack_bind', {
            Default = 'None',
            SyncToggleState = true,
            Mode = 'Toggle',
            Text = 'Flyhack',
            NoUI = false
        })

        fmvb:AddSlider('flyhack_speed', {
            Text = 'Fly Speed',
            Default = 10,
            Min = 1,
            Max = 50,
            Rounding = 0,
            Suffix = "sps",
            Compact = false
        }):OnChanged(function(State)
            fly_speed = State
        end)

        fmvb:AddSlider('flyhack_y_speed', {
            Text = 'Vertical Speed',
            Default = 10,
            Min = 1,
            Max = 50,
            Rounding = 0,
            Suffix = "sps",
            Compact = false
        }):OnChanged(function(State)
            fly_yspeed = State
        end)

        -- â”€â”€â”€ MAIN FLIGHT LOOP (bypass removed) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
        cheat.utility.new_heartbeat(LPH_JIT_MAX(function(delta)
            if feature_active(fly_enabled, 'flyhack_bind') then
                local character = LocalPlayer.Character
                local hrp = character and _FindFirstChild(character, "HumanoidRootPart")
                if hrp then
                    local cameralook = Camera.CFrame.LookVector
                    cameralook = _Vector3new(cameralook.X, 0, cameralook.Z)

                    local direction = Vector3.zero
                    direction = _IsKeyDown(UserInputService, Enum.KeyCode.W) and direction + cameralook or direction
                    direction = _IsKeyDown(UserInputService, Enum.KeyCode.S) and direction - cameralook or direction
                    direction = _IsKeyDown(UserInputService, Enum.KeyCode.D) and direction + _Vector3new(-cameralook.Z, 0, cameralook.X) or direction
                    direction = _IsKeyDown(UserInputService, Enum.KeyCode.A) and direction + _Vector3new(cameralook.Z, 0, -cameralook.X) or direction
                    direction = _IsKeyDown(UserInputService, Enum.KeyCode.Space) and direction + Vector3.yAxis or direction
                    direction = _IsKeyDown(UserInputService, Enum.KeyCode.LeftControl) and direction - Vector3.yAxis or direction

                    if direction ~= Vector3.zero then
                        direction = direction.Unit
                    end

                    local current_cf = hrp.CFrame
                    if cheat.real_CFrame then current_cf = cheat.real_CFrame end

                    local new_cf = current_cf
                        + _Vector3new(1, 0, 1) * (direction * delta * fly_speed)
                        + Vector3.yAxis * (direction * delta * fly_yspeed)

                    hrp.CFrame = new_cf
                    if cheat.real_CFrame then cheat.real_CFrame = new_cf end

                    for _, part in character:GetDescendants() do
                        if part:IsA("BasePart") then
                            part.AssemblyLinearVelocity = Vector3.zero
                        end
                    end
                end
            end
        end))
    end

    -- â”€â”€â”€ MOD DETECTOR (in misc tab) â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local misctab2 = ui.box.detection
        local mod_detector = false
        local cheat_detector = false
        local mod_warnings = {}
        local mod_alerted = {}
        local cheater_alerted = {}

        misctab2:AddToggle('mod_detector', {Text = 'Mod Detector', Default = false, Callback = function(v)
            mod_detector = v
            if v then cheat.Library:Notify('Mod Detector', 'Mod Detector enabled') end
        end})
        misctab2:AddToggle('cheat_detector', {Text = 'Cheater Detector (Mod Detector)', Default = false, Callback = function(v)
            cheat_detector = v
            if v then cheat.Library:Notify('Cheater Detector', 'Cheater Detector enabled') end
        end})

        local function check_cheater(plr)
            if plr == LocalPlayer then return end
            if not cheat_detector then return end
            if cheater_alerted[plr.Name] then return end
            local rs_plr = ReplicatedStorage:FindFirstChild("Players") and
                ReplicatedStorage.Players:FindFirstChild(plr.Name)
            if not rs_plr then return end
            local status = rs_plr:FindFirstChild("Status")
            if not status then return end
            local journey = status:FindFirstChild("Journey")
            if not journey then return end
            local wipe = journey:FindFirstChild("WipeStatistics")
            if not wipe then return end
            local deaths = wipe:GetAttribute("Deaths") or 0
            if deaths == 0 then deaths = 1 end
            local kills = wipe:GetAttribute("Kills") or 0
            if kills == 0 then kills = 1 end
            local kdr = math.floor(kills / deaths * 10) / 10
            if kills >= 15 and kdr >= 5 then
                cheater_alerted[plr.Name] = true
                cheat.Library:Notify('Cheater Detector (KDR: '..kdr..')', plr.Name..' suspected cheater!')
            end
            local report = (ReplicatedStorage:FindFirstChild("ReportList"))
            if report then
                local entry = report:FindFirstChild("MostWanted") and report.MostWanted:FindFirstChild(plr.Name)
                    or report:FindFirstChild("Recent") and report.Recent:FindFirstChild(plr.Name)
                if entry then
                    local flags = entry:GetAttribute("TotalFlags") or 0
                    local hsr = entry:GetAttribute("HSR") or 0
                    local age = entry:GetAttribute("Age") or 0
                    if kills >= 15 and hsr >= 95 then
                        cheater_alerted[plr.Name] = true
                        cheat.Library:Notify('Cheater Detector (B)', plr.Name..' suspected cheater!')
                    end
                    if flags >= 75 and age <= 50 then
                        cheater_alerted[plr.Name] = true
                        cheat.Library:Notify('Cheater Detector (C)', plr.Name..' suspected cheater!')
                    end
                end
            end
        end

        local function run_mod_detector()
            if not mod_detector then return end
            for _, plr in ipairs(Players:GetPlayers()) do
                if plr ~= LocalPlayer then
                    check_cheater(plr)
                    if plr.Character then
                        -- Method A: high premium level = likely mod/admin
                        if not mod_warnings[plr.Name] then mod_warnings[plr.Name] = 0 end
                        if mod_warnings[plr.Name] < 5 and not mod_alerted[plr.Name] then
                            local rs_plr = ReplicatedStorage:FindFirstChild("Players") and
                                ReplicatedStorage.Players:FindFirstChild(plr.Name)
                            if rs_plr then
                                local status = rs_plr:FindFirstChild("Status")
                                if status and status:FindFirstChild("GameplayVariables") and
                                    status.GameplayVariables:GetAttribute("PremiumLevel") and
                                    status.GameplayVariables:GetAttribute("PremiumLevel") >= 4 then
                                    mod_warnings[plr.Name] = mod_warnings[plr.Name] + 1
                                    cheat.Library:Notify('Mod Detector (A)', 'Mod detected: '..plr.Name)
                                end
                            end
                            -- Method B: invisible body parts
                            for _, part in pairs(plr.Character:GetChildren()) do
                                local bodyParts = {Head=true,LeftFoot=true,LeftHand=true,LeftLowerArm=true,
                                    LeftLowerLeg=true,LeftUpperArm=true,LeftUpperLeg=true,LowerTorso=true,
                                    RightFoot=true,RightHand=true,RightLowerArm=true,RightUpperArm=true,
                                    RightUpperLeg=true,UpperTorso=true}
                                if bodyParts[part.Name] and part:IsA("BasePart") and part.Transparency >= 1 then
                                    mod_warnings[plr.Name] = mod_warnings[plr.Name] + 1
                                    cheat.Library:Notify('Mod Detector (B)', 'Mod detected (invis): '..plr.Name)
                                    mod_alerted[plr.Name] = true
                                    break
                                end
                            end
                        end
                    end
                end
            end
        end

        -- Run mod detector every 3 seconds
        task.spawn(function()
            while true do
                task.wait(3)
                pcall(run_mod_detector)
            end
        end)
    end

    -- â”€â”€â”€ FREECAM â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€
    -- Yield one frame so the loading screen keeps animating while the next
    -- section builds, instead of the whole UI being constructed in a single
    -- uninterrupted chunk (which reads as a freeze).
    task.wait()
    do local _t = os.clock()
        print(string.format("[LOAD] +%.3fs  since_last=%.3fs", _t - (_G.__ghostLoadStart or _t), _t - (_G.__ghostLoadMark or _t)))
        _G.__ghostLoadMark = _t end
    do
        local freecam_tab = world_freecam_tab
        cheat.freecam_enabled = false
        local freecam_show_distance = false
        local freecam_speed = 50
        local freecam_cf = nil
        local freecam_part = nil
        local freecam_ghost = nil
        local freecam_ghost_label = nil
        local pitch, yaw = 0, 0
        local freecam_master_enabled = false
        
        freecam_tab:AddToggle('freecam_show_distance', {Text = 'Show Distance ESP', Default = false, Callback = function(v)
            freecam_show_distance = v
        end})
        
        freecam_tab:AddToggle('freecam_vis_original', {Text = 'Vis Check From Real Character', Default = false})
        
        local function setFreecamActive(v)
            v = v and true or false
            if cheat.freecam_enabled == v then return end

            cheat.freecam_enabled = v
            if v then
                freecam_cf = workspace.CurrentCamera.CFrame
                pitch, yaw = freecam_cf:ToOrientation()
                workspace.CurrentCamera.CameraType = Enum.CameraType.Scriptable
                
                if not freecam_part then
                    freecam_part = Instance.new("Part")
                    freecam_part.Anchored = true
                    freecam_part.CanCollide = false
                    freecam_part.Transparency = 1
                    freecam_part.Name = "FreecamFocus"
                    freecam_part.Parent = workspace.Terrain
                end
                pcall(function() LocalPlayer.ReplicationFocus = freecam_part end)
                
                local char = LocalPlayer.Character
                if char then
                    local oldArchivable = char.Archivable
                    char.Archivable = true
                    freecam_ghost = char:Clone()
                    char.Archivable = oldArchivable
                    
                    if freecam_ghost then
                        freecam_ghost.Name = "FreecamGhost_ESP_IGNORE"
                        
                        local hl = Instance.new("Highlight")
                        local es_enemy = cheat.EspLibrary.settings.enemy
                        local ghost_cham_color = es_enemy.cham_color or Color3.new(1, 1, 1)
                        local ghost_cham_transparency = es_enemy.cham_transparency or 0.5
                        hl.FillColor = ghost_cham_color
                        hl.OutlineColor = ghost_cham_color
                        hl.FillTransparency = ghost_cham_transparency
                        hl.OutlineTransparency = math.clamp(ghost_cham_transparency * 0.5, 0, 1)
                        hl.DepthMode = es_enemy.chams_visible and not es_enemy.chams_hidden and Enum.HighlightDepthMode.Occluded or Enum.HighlightDepthMode.AlwaysOnTop
                        hl.Parent = freecam_ghost
                        
                        for _, desc in pairs(freecam_ghost:GetDescendants()) do
                            if desc:IsA("BasePart") then
                                desc.Material = Enum.Material.Neon
                                desc.Color = ghost_cham_color
                                desc.Transparency = ghost_cham_transparency
                                local sa = desc:FindFirstChildOfClass("SurfaceAppearance")
                                if sa then sa:Destroy() end
                                
                                desc.CanCollide = false
                                desc.CanTouch = false
                                desc.CanQuery = false
                                desc.Massless = true
                                desc.Anchored = true
                            elseif desc:IsA("Decal") or desc:IsA("Texture") or desc:IsA("Clothing") or desc:IsA("Accessory") or desc:IsA("Script") or desc:IsA("LocalScript") then
                                desc:Destroy()
                            end
                        end
                        
                        local humanoid = freecam_ghost:FindFirstChildOfClass("Humanoid")
                        if humanoid then humanoid:Destroy() end
                        
                        local hrp = freecam_ghost:FindFirstChild("HumanoidRootPart")
                        if hrp then
                            local text = cheat.utility.new_drawing("Text", {
                                Center = true,
                                Font = cheat.EspLibrary.main_settings.textFont,
                                Color = cheat.EspLibrary.settings.corpse.color or Color3.fromRGB(255, 255, 255),
                                Outline = true,
                                Size = cheat.EspLibrary.main_settings.textSize,
                                Visible = false,
                            })
                            freecam_ghost_label = text
                        end
                        
                        freecam_ghost.Parent = workspace.Terrain
                        local real_hrp = char:FindFirstChild("HumanoidRootPart")
                        if real_hrp then
                            freecam_ghost:PivotTo(real_hrp.CFrame)
                        end
                    end
                end
            else
                workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
                UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                pcall(function() LocalPlayer.ReplicationFocus = nil end)
                if freecam_part then freecam_part:Destroy(); freecam_part = nil end
                if freecam_ghost_label then freecam_ghost_label:Remove(); freecam_ghost_label = nil end
                if freecam_ghost then freecam_ghost:Destroy(); freecam_ghost = nil end
            end
        end
        
        freecam_tab:AddToggle('freecam_enabled', {Text = 'Freecam', Default = false, Callback = function(v)
            freecam_master_enabled = v
            setFreecamActive(feature_active(freecam_master_enabled, 'freecam_bind'))
        end}):AddKeyPicker('freecam_bind', {Default = 'None', SyncToggleState = false, Mode = 'Toggle', Text = 'Freecam', NoUI = false, Callback = function()
            setFreecamActive(feature_active(freecam_master_enabled, 'freecam_bind'))
        end})
        
        freecam_tab:AddSlider('freecam_speed', {Text = 'Freecam Speed', Default = 50, Min = 10, Max = 575, Rounding = 0, Callback = function(v)
            freecam_speed = v
        end})
        
        local last_stream_req = 0
        cheat.utility.track_connection(RunService.RenderStepped:Connect(function(dt)
            if cheat.freecam_enabled then
                local cam = workspace.CurrentCamera
                
                if UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2) then
                    UserInputService.MouseBehavior = Enum.MouseBehavior.LockCurrentPosition
                    local delta = UserInputService:GetMouseDelta()
                    pitch = math.clamp(pitch - delta.Y * 0.005, -math.pi/2 + 0.01, math.pi/2 - 0.01)
                    yaw = yaw - delta.X * 0.005
                else
                    UserInputService.MouseBehavior = Enum.MouseBehavior.Default
                end
                
                local moveVector = Vector3.zero
                if UserInputService:IsKeyDown(Enum.KeyCode.W) then moveVector = moveVector + Vector3.new(0, 0, 1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.S) then moveVector = moveVector + Vector3.new(0, 0, -1) end
                if UserInputService:IsKeyDown(Enum.KeyCode.A) then moveVector = moveVector + Vector3.new(-1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.D) then moveVector = moveVector + Vector3.new(1, 0, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.E) or UserInputService:IsKeyDown(Enum.KeyCode.Space) then moveVector = moveVector + Vector3.new(0, 1, 0) end
                if UserInputService:IsKeyDown(Enum.KeyCode.Q) or UserInputService:IsKeyDown(Enum.KeyCode.LeftControl) then moveVector = moveVector + Vector3.new(0, -1, 0) end
                
                freecam_cf = CFrame.new(freecam_cf.Position) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(pitch, 0, 0)
                
                if moveVector.Magnitude > 0 then
                    moveVector = moveVector.Unit
                    freecam_cf = freecam_cf + (freecam_cf.RightVector * moveVector.X + freecam_cf.UpVector * moveVector.Y + freecam_cf.LookVector * moveVector.Z) * (freecam_speed * dt)
                end
                
                cam.CFrame = freecam_cf
                if freecam_part then
                    freecam_part.CFrame = freecam_cf
                    pcall(function() LocalPlayer.ReplicationFocus = freecam_part end)
                    if tick() - last_stream_req > 1 then
                        last_stream_req = tick()
                        task.spawn(function()
                            pcall(function() LocalPlayer:RequestStreamAroundAsync(freecam_cf.Position) end)
                        end)
                    end
                end
                
                if freecam_ghost_label then
                    local char = LocalPlayer.Character
                    local hrp = char and char:FindFirstChild("HumanoidRootPart")
                    if hrp and freecam_show_distance then
                        local dist = math.floor((hrp.Position - freecam_cf.Position).Magnitude)
                        freecam_ghost_label.Text = "[" .. dist .. "m]"
                        freecam_ghost_label.Font = cheat.EspLibrary.main_settings.textFont
                        freecam_ghost_label.Size = cheat.EspLibrary.main_settings.textSize
                        
                        local pos, onScreen = workspace.CurrentCamera:WorldToViewportPoint(hrp.Position)
                        if onScreen then
                            freecam_ghost_label.Position = Vector2.new(pos.X, pos.Y)
                            freecam_ghost_label.Visible = true
                        else
                            freecam_ghost_label.Visible = false
                        end
                    else
                        freecam_ghost_label.Visible = false
                    end
                end
                
                local char = LocalPlayer.Character
                if char then
                    local root = char:FindFirstChild("HumanoidRootPart")
                    if root then
                        root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
                    end
                    local hum = char:FindFirstChildOfClass("Humanoid")
                    if hum then
                        hum:Move(Vector3.zero, false)
                    end
                end
            end
        end))
    end

    cheat.utility.new_renderstepped(function()
        if not cheat.hitlogs_enabled then
            if #cheat.hitlogs.active == 0 and #cheat.hitlogs.pending == 0 then
                return
            end
            for _, log in ipairs(cheat.hitlogs.active) do
                if log.drawing then log.drawing:Remove() end
                if log.bg then log.bg:Remove() end
                if log.line then log.line:Remove() end
            end
            cheat.hitlogs.active = {}
            cheat.hitlogs.pending = {}
            return
        end

        local current_time = os.clock()
        for i = #cheat.hitlogs.pending, 1, -1 do
            local pending = cheat.hitlogs.pending[i]
            if current_time - pending.tick > 0.4 then
                local str = string.format("%s hit %s on %dm", pending.name, pending.part, pending.dist)
                
                local bg = cheat.utility.new_drawing("Square", {
                    Size = _Vector2new(0, 0), Position = _Vector2new(-300, cheat.hitlogs_y),
                    Color = Color3.fromRGB(20, 20, 20), Filled = true, Transparency = 1,
                    Visible = true, ZIndex = 98
                })
                local line = cheat.utility.new_drawing("Square", {
                    Size = _Vector2new(3, 0), Position = _Vector2new(-300, cheat.hitlogs_y),
                    Color = cheat.hitlogs_invalid_color, Filled = true, Transparency = 1,
                    Visible = true, ZIndex = 99
                })
                local text = cheat.utility.new_drawing("Text", {
                    Text = str, Size = cheat.hitlogs_size, Font = cheat.hitlogs_font,
                    Center = false, Outline = true, Color = Color3.new(1, 1, 1),
                    Position = _Vector2new(-300, cheat.hitlogs_y), Visible = true, ZIndex = 100
                })
                table.insert(cheat.hitlogs.active, 1, {
                    drawing = text, bg = bg, line = line, str = str, spawn_tick = current_time,
                    target_y = cheat.hitlogs_y, current_x = -300
                })
                table.remove(cheat.hitlogs.pending, i)
            end
        end

        local base_y = cheat.hitlogs_y
        for i = #cheat.hitlogs.active, 1, -1 do
            local log = cheat.hitlogs.active[i]
            local age = current_time - log.spawn_tick
            if age > 5 then
                if log.drawing then log.drawing:Remove() end
                if log.bg then log.bg:Remove() end
                if log.line then log.line:Remove() end
                table.remove(cheat.hitlogs.active, i)
            else
                if log.current_x < 20 then
                    log.current_x = log.current_x + (20 - log.current_x) * 0.15
                end
                
                local text_bounds = log.drawing.TextBounds
                local box_height = text_bounds.Y + 8
                local box_width = text_bounds.X + 16
                
                log.target_y = base_y + ((i - 1) * (box_height + 4))
                local current_y = log.drawing.Position.Y
                local new_y = current_y + (log.target_y - current_y) * 0.2
                local alpha = 1
                if age > 4 then alpha = 1 - (age - 4) end
                
                log.drawing.Position = _Vector2new(log.current_x + 8, new_y + 4)
                log.drawing.Transparency = alpha
                log.drawing.Size = cheat.hitlogs_size
                log.drawing.Font = cheat.hitlogs_font
                
                log.bg.Position = _Vector2new(log.current_x, new_y)
                log.bg.Size = _Vector2new(box_width, box_height)
                log.bg.Transparency = alpha
                
                log.line.Position = _Vector2new(log.current_x, new_y)
                log.line.Size = _Vector2new(3, box_height)
                log.line.Transparency = alpha
            end
        end
    end)

    cheat.ThemeManager:SetOptionsTEMP(cheat.Options, cheat.Toggles)
    cheat.SaveManager:SetOptionsTEMP(cheat.Options, cheat.Toggles)
    cheat.ThemeManager:SetLibrary(cheat.Library)
    cheat.SaveManager:SetLibrary(cheat.Library)
    cheat.SaveManager:IgnoreThemeSettings()
    cheat.ThemeManager:SetFolder('GHOST_HOOK')
    cheat.SaveManager:SetFolder('GHOST_HOOK')
    local settings_config_name = "Default"
    local function normalize_config_name(name)
        name = tostring(name or ""):gsub("^%s+", ""):gsub("%s+$", "")
        return name ~= "" and name or "Default"
    end
    local function write_autoload_config(name)
        if writefile then
            local normalized = normalize_config_name(name)
            writefile(cheat.SaveManager.Folder .. "/settings/autoload.txt", normalized)
            writefile("AutoLoadConfig", normalized)
        end
    end
    local function get_settings_config_names()
        local names = {"Default"}
        local seen = {Default = true}
        if cheat.SaveManager and cheat.SaveManager.RefreshConfigList then
            for _, name in ipairs(cheat.SaveManager:RefreshConfigList() or {}) do
                local normalized = normalize_config_name(name)
                if not seen[normalized] then
                    seen[normalized] = true
                    table.insert(names, normalized)
                end
            end
        end
        table.sort(names, function(a, b)
            if a == "Default" then return true end
            if b == "Default" then return false end
            return a:lower() < b:lower()
        end)
        return names
    end
    local settings_config_dropdown_name = "Default"
    local settings_config_dropdown = ui.box.config:AddDropdown('SaveManager_ConfigDropdown', {
        Text = 'Select Config',
        Default = settings_config_dropdown_name,
        Values = get_settings_config_names(),
        Callback = function(value)
            settings_config_dropdown_name = normalize_config_name(value)
        end,
    })
    local settings_config_input = ui.box.config:AddInput('SaveManager_ConfigName', {
        Text = 'Enter Config Name',
        Default = settings_config_name,
        ClearTextOnFocus = true,
        Callback = function(value)
            local raw_value = tostring(value or "")
            if raw_value:gsub("%s+", "") == "" then
                return
            end
            settings_config_name = normalize_config_name(raw_value)
        end,
    })
    local function get_settings_config_action_name()
        settings_config_name = normalize_config_name(settings_config_name)
        return settings_config_name
    end
    local function get_settings_config_dropdown_name()
        return normalize_config_name(settings_config_dropdown_name)
    end
    local settings_config_names_cache
    local settings_config_names_cache_tick = 0
    local function refresh_settings_config_dropdown(force)
        local now = tick()
        local names
        if not force and settings_config_names_cache and now - settings_config_names_cache_tick < 1 then
            names = settings_config_names_cache
        else
            names = get_settings_config_names()
            settings_config_names_cache = names
            settings_config_names_cache_tick = now
        end
        local selected = normalize_config_name(settings_config_dropdown_name)
        local found = false
        for _, name in ipairs(names) do
            if name == selected then
                found = true
                break
            end
        end
        if not found and selected ~= "Default" then
            table.insert(names, selected)
            table.sort(names, function(a, b)
                if a == "Default" then return true end
                if b == "Default" then return false end
                return a:lower() < b:lower()
            end)
            found = true
        end
        if not found then
            selected = "Default"
        end
        settings_config_dropdown_name = selected
        if settings_config_dropdown and settings_config_dropdown.SetValues then
            settings_config_dropdown:SetValues(names)
        elseif settings_config_dropdown and settings_config_dropdown.ClearOptions and settings_config_dropdown.InsertOptions then
            settings_config_dropdown:ClearOptions()
            settings_config_dropdown:InsertOptions(names)
        end
        if settings_config_dropdown and settings_config_dropdown.SetValue then
            settings_config_dropdown:SetValue(settings_config_dropdown_name, true)
        end
        return names
    end
    ui.box.config:AddButton('Refresh Config List', function()
        refresh_settings_config_dropdown(true)
        cheat.Library:Notify('GHOST_HOOK | Configs', 'Config List Refreshed', 3)
    end)
    ui.box.config:AddButton('Save Config', function()
        settings_config_name = get_settings_config_action_name()
        write_autoload_config(settings_config_name)
        local ok, err = cheat.SaveManager:Save(settings_config_name)
        if ok then
            settings_config_dropdown_name = settings_config_name
            refresh_settings_config_dropdown(true)
            cheat.Library:Notify('GHOST_HOOK | Configs', 'Config Named: ' .. settings_config_name .. ' Was Saved', 5)
        else
            cheat.Library:Notify('GHOST_HOOK | Configs', 'Failed To Save Config: ' .. tostring(err), 5)
        end
    end)
    ui.box.config:AddButton('Load Config', function()
        local loading = get_settings_config_dropdown_name()
        write_autoload_config(loading)
        local ok, err = cheat.SaveManager:Load(loading)
        if ok then
            cheat.Library:Notify('GHOST_HOOK | Configs', 'Config Named: ' .. loading .. ' Was Loaded', 5)
        else
            cheat.Library:Notify('GHOST_HOOK | Configs', 'Failed To Load Config: ' .. tostring(err), 5)
        end
    end)
    ui.box.config:AddButton('<font color="#ff4b4b">Delete Config</font>', function()
        local deleting = get_settings_config_dropdown_name()
        local ok, err = cheat.SaveManager:Delete(deleting)
        if ok then
            settings_config_dropdown_name = "Default"
            local loaded_default, default_err = cheat.SaveManager:Load(settings_config_dropdown_name)
            if loaded_default then
                write_autoload_config(settings_config_dropdown_name)
            end
            refresh_settings_config_dropdown(true)
            if loaded_default then
                cheat.Library:Notify('GHOST_HOOK | Configs', 'Config Named: ' .. deleting .. ' Was Deleted, Loaded Default', 5)
            else
                cheat.Library:Notify('GHOST_HOOK | Configs', 'Config Deleted, Failed To Load Default: ' .. tostring(default_err), 5)
            end
        else
            cheat.Library:Notify('GHOST_HOOK | Configs', 'Failed To Delete Config: ' .. tostring(err), 5)
        end
    end)
    ui.box.script:AddButton('Unload - Will Lag Once', function()
        task.defer(function()
            cheat.utility.unload()
        end)
    end)

    local settings_selected_npc = 'Mihkel'
    ui.box.npc:AddDropdown('settings_npc_select', {
        Text = 'NPC - Only In Lobby',
        Default = 'Mihkel',
        Values = {'Mihkel', 'Seryozha', 'Tarmo', 'Nurse', 'Blaze', 'Boss', 'Designer', 'Anna'},
        Callback = function(value)
            settings_selected_npc = value
        end,
    })
    local function find_lobby_npc(name)
        local target_name = tostring(name or ""):lower()
        local direct = workspace:FindFirstChild(name)
        if direct then
            return direct
        end

        local stack = {workspace}
        while #stack > 0 do
            local parent = table.remove(stack)
            for _, object in ipairs(parent:GetChildren()) do
                if object.Name:lower() == target_name and (object:IsA("Model") or object:IsA("Folder")) then
                    return object
                end
                stack[#stack + 1] = object
            end
        end
    end

    local function get_npc_root(npc)
        if not npc then return nil end
        return npc:FindFirstChild("HumanoidRootPart", true)
            or npc:FindFirstChild("RootPart", true)
            or npc.PrimaryPart
            or npc:FindFirstChildWhichIsA("BasePart", true)
    end

    ui.box.npc:AddButton('Teleport Npc To You', function()
        local npc = find_lobby_npc(settings_selected_npc)
        local npc_root = get_npc_root(npc)
        local character = LocalPlayer.Character
        local root = character and character:FindFirstChild('HumanoidRootPart')
        if npc_root and root then
            if npc and npc:IsA("Model") then
                npc:PivotTo(root.CFrame)
            else
                npc_root.CFrame = root.CFrame
            end
        elseif cheat.Library and cheat.Library.Notify then
            cheat.Library:Notify('NPC', tostring(settings_selected_npc) .. ' NPC or player root not found', 3)
        end
    end)

    ui.box.themes:AddToggle('ThemeManager_CustomTheme', {
        Text = 'Custom Theme (Beta)',
        Default = false,
        Callback = function(value)
            if cheat.Library and cheat.Library._ghostMenu and cheat.Library._ghostMenu.SetThemeAccent then
                cheat.Library._ghostMenu.SetThemeAccent(value, cheat.Options.ThemeManager_CustomThemeColor and cheat.Options.ThemeManager_CustomThemeColor.Value or Color3.fromRGB(103, 182, 254))
            end
        end
    }):AddColorPicker('ThemeManager_CustomThemeColor', {
        Default = Color3.fromRGB(103, 182, 254),
        Title = 'Accent Color',
        Callback = function(color)
            if cheat.Library and cheat.Library._ghostMenu and cheat.Library._ghostMenu.SetThemeAccent then
                cheat.Library._ghostMenu.SetThemeAccent(cheat.Toggles.ThemeManager_CustomTheme and cheat.Toggles.ThemeManager_CustomTheme.Value, color)
            end
        end
    })

    local function get_player_gui()
        return LocalPlayer:FindFirstChildOfClass("PlayerGui") or LocalPlayer:WaitForChild("PlayerGui")
    end

    local hide_server_info_connection
    ui.box.client:AddToggle('client_hide_server_info', {
        Text = 'Hide Server Info',
        Default = false,
        Callback = function(value)
            local player_gui = get_player_gui()
            local function apply(gui)
                local frame = gui and gui:FindFirstChild('Frame')
                local server_info = frame and frame:FindFirstChild('serverInfo')
                if server_info then
                    server_info.Visible = not value
                end
            end

            apply(player_gui and player_gui:FindFirstChild('ServerInfo'))
            if value and not hide_server_info_connection then
                hide_server_info_connection = cheat.utility.track_connection(player_gui.ChildAdded:Connect(function(child)
                    if child.Name == 'ServerInfo' then
                        task.defer(function()
                            apply(child)
                        end)
                    end
                end))
            elseif not value and hide_server_info_connection then
                hide_server_info_connection:Disconnect()
                cheat.connections.generic[hide_server_info_connection] = nil
                hide_server_info_connection = nil
            end
        end,
    })

    local hide_name_chat_connection
    local hide_name_chat_wait_connection
    local function scrub_chat_name(chat_gui, hide)
        local main_frame = chat_gui and chat_gui:FindFirstChild('MainFrame')
        local chat_box = main_frame and main_frame:FindFirstChild('ChatBox')
        local chat_window = chat_box and chat_box:FindFirstChild('ChatWindow')
        if not chat_window then return nil end

        local function scrub_label(label)
            if label:IsA('TextLabel') and label:FindFirstChild('Message') then
                local message = label.Message
                if hide and message.Text:find(LocalPlayer.Name) then
                    message.Text = message.Text:gsub(LocalPlayer.Name, 'Hidden')
                elseif not hide and message.Text:find('Hidden') then
                    message.Text = message.Text:gsub('Hidden', LocalPlayer.Name)
                end
            end
        end

        for _, child in pairs(chat_window:GetChildren()) do
            scrub_label(child)
        end

        return chat_window, scrub_label
    end

    ui.box.client:AddToggle('client_hide_name_chat', {
        Text = 'Hide Name In Chat',
        Default = false,
        Callback = function(value)
            local player_gui = get_player_gui()
            if hide_name_chat_connection then
                hide_name_chat_connection:Disconnect()
                cheat.connections.generic[hide_name_chat_connection] = nil
                hide_name_chat_connection = nil
            end
            if hide_name_chat_wait_connection then
                hide_name_chat_wait_connection:Disconnect()
                cheat.connections.generic[hide_name_chat_wait_connection] = nil
                hide_name_chat_wait_connection = nil
            end

            local function attach(chat_gui)
                local chat_window, scrub_label = scrub_chat_name(chat_gui, value)
                if value and chat_window and scrub_label then
                    hide_name_chat_connection = cheat.utility.track_connection(chat_window.ChildAdded:Connect(function(child)
                        if cheat.Toggles.client_hide_name_chat and cheat.Toggles.client_hide_name_chat.Value then
                            task.defer(function()
                                scrub_label(child)
                            end)
                        end
                    end))
                end
            end

            local chat_gui = player_gui and player_gui:FindFirstChild('ChatV3')
            if chat_gui then
                attach(chat_gui)
            elseif value and player_gui then
                hide_name_chat_wait_connection = cheat.utility.track_connection(player_gui.ChildAdded:Connect(function(child)
                    if child.Name == 'ChatV3' and cheat.Toggles.client_hide_name_chat and cheat.Toggles.client_hide_name_chat.Value then
                        attach(child)
                        if hide_name_chat_wait_connection then
                            hide_name_chat_wait_connection:Disconnect()
                            cheat.connections.generic[hide_name_chat_wait_connection] = nil
                            hide_name_chat_wait_connection = nil
                        end
                    end
                end))
            end
        end,
    })
    ui.box.client:AddButton('Rejoin server', function()
        local job_id = game.JobId
        local place_id = game.PlaceId
        if job_id and place_id and job_id ~= "" then
            game:GetService('TeleportService'):TeleportToPlaceInstance(place_id, job_id, LocalPlayer)
        end
    end)

    ui.box.keybinds:AddToggle('keybindshoww', {
        Text = 'KeyBind Indicator',
        Default = false,
        Callback = function(first)
            cheat.keybind_indicator_enabled = first and true or false
            if cheat.Library and cheat.Library.KeybindFrame then
                cheat.Library.KeybindFrame.Visible = cheat.keybind_indicator_enabled
            end
            cheat.utility.create_keybind_indicator()
        end
    })
    ui.box.keybinds:AddKeybind('menu_toggle_key', {
        Text = 'Toggle Menu Key',
        Default = 'RightControl',
        Callback = function(value)
            if cheat.Library and cheat.Library.SetToggleKey then
                cheat.Library:SetToggleKey(value)
            end
        end
    })

    local has_pinreta_autoload = isfile and isfile(cheat.SaveManager.Folder .. "/settings/autoload.txt")
    local has_ghost_autoload = isfile and isfile("AutoLoadConfig")
    local has_default_config = isfile and isfile(cheat.SaveManager.Folder .. "/settings/Default.json")
    -- First execution, or the baseline is missing: create it and make it the autoload.
    -- Everything is forced off first so the baseline really is all-off instead of a
    -- snapshot of whatever the freshly built UI had already defaulted on.
    if isfile and not has_default_config then
        for _, object in pairs(cheat.Toggles or {}) do
            if object and object.SetValue then
                pcall(function() object:SetValue(false) end)
            end
        end
        for _, object in pairs(cheat.Options or {}) do
            local v = object and object.Value
            if type(v) == "table" and v.Active ~= nil and object.Mode ~= "Always" then
                pcall(function() object:SetValue(false) end)
            end
        end
        local ok, err = cheat.SaveManager:Save('Default')
        if ok then
            -- point autoload at the baseline if nothing already points somewhere
            if not has_pinreta_autoload and not has_ghost_autoload then
                write_autoload_config('Default')
            end
        elseif cheat.Library and cheat.Library.Notify then
            cheat.Library:Notify('GHOST_HOOK | Configs', 'Failed To Create Default Config: ' .. tostring(err), 5)
        end
    end
    refresh_settings_config_dropdown(true)
    task.spawn(function()
        task.wait(1.5)
        refresh_settings_config_dropdown(true)
    end)
    cheat.EspLibrary.load()
    cheat.ui_ready = true
    -- Autoload used to run BEFORE EspLibrary.load() and ui_ready, so the whole UI
    -- build, the ESP library and the saved config all landed in one synchronous
    -- block -- the long freeze. Running it after ui_ready lets the loading screen
    -- finish first; the config still applies at startup, just as its own step.
    task.spawn(function()
        task.wait(0.2)
        pcall(function() cheat.SaveManager:LoadAutoloadConfig() end)
    end)
    -- Release binds on timers: the menu library can activate keybinds while it builds,
    -- which is what left binded features switched on before any key was pressed.
    task.spawn(function()
        for _, step in ipairs({ 0.5, 1.0, 1.5, 3.0 }) do
            task.wait(step)
            pcall(cheat.release_all_binds)
        end
    end)
    if cheat.loading_finished and cheat.Library and cheat.Library.SetOpen and not cheat.unloaded then
        pcall(cheat.release_all_binds)
        cheat.Library:SetOpen(true)
        pcall(cheat.release_all_binds)
    end

    task.spawn(function()
        for _, v in getconnections(game.ReplicatedStorage.Remotes.NotificationMessage.OnClientEvent) do
            if not v.Function then return end
            for i=1,5 do task.spawn(function()v.Function("WELCOME TO GHOST_HOOK!!!!!", 5, i)end) task.wait(1) end
        end
    end)
