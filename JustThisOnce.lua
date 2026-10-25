local CONFIG = {
    TITLE       = "Bluu",

    SERVICE     = "YattasCrazyGui",
    PROVIDER    = "Yatta",
    IDENTIFIER  = "1142688",
    SCRIPT_ID   = "b80c6ae9f9eb199a8e9bfe8711e8a3c8d06e4d437098a81b2ebfa4b927446ead",

    SAVE_KEY    = true,
    KEY_FILE    = "YCGKEY.txt",
    CHECK_FIRST = true,

    DISCORD_NAME = "fishadopter",
    DISCORD_ID   = "1495626421132070984",
}
CONFIG.DISCORD_LINK = "https://discord.com/users/" .. CONFIG.DISCORD_ID

local genv = (type(getgenv) == "function" and getgenv()) or _G

if genv.YattaKeyUI and genv.YattaKeyUI.Destroy then
    pcall(function() genv.YattaKeyUI:Destroy() end)
end
genv.YattaKeyUI = nil

local function sysNotify(text)
    pcall(function()
        game:GetService("StarterGui"):SetCore("SendNotification", { Title = CONFIG.TITLE, Text = tostring(text), Duration = 8 })
    end)
end

local function canFile()
    return type(isfile) == "function" and type(readfile) == "function" and type(writefile) == "function"
end
local function trim(s)
    return (string.match(tostring(s or ""), "^%s*(.-)%s*$"))
end
local function readSavedKey()
    if not (CONFIG.SAVE_KEY and canFile()) then return nil end
    local okE, exists = pcall(isfile, CONFIG.KEY_FILE)
    if not (okE and exists) then return nil end
    local okR, data = pcall(readfile, CONFIG.KEY_FILE)
    if not (okR and type(data) == "string") then return nil end
    data = trim(data)
    return data ~= "" and data or nil
end
local function writeSavedKey(key)
    if CONFIG.SAVE_KEY and canFile() then pcall(writefile, CONFIG.KEY_FILE, key or "") end
end

local REASONS = {
    KEY_INVALID       = "That key was not found. Make sure you copied all of it.",
    KEY_EXPIRED       = "That key has expired. Press Get Key for a new one.",
    KEY_INVALIDATED   = "That key was disabled. Press Get Key for a new one.",
    SERVICE_NOT_FOUND = "The key service is not set up correctly (service not found).",
    SERVICE_MISMATCH  = "That key belongs to a different script.",
}
local function reasonText(result)
    local code = type(result) == "table" and result.error or nil
    if code and REASONS[code] then return REASONS[code] end
    if code then return "Key rejected: " .. tostring(code) end
    return "Key rejected."
end

local okJ, Junkie = pcall(function()
    return loadstring(game:HttpGet("https://jnkie.com/sdk/library.lua"))()
end)
if not okJ or type(Junkie) ~= "table" then
    warn("Could not load the Junkie SDK: " .. tostring(Junkie))
    sysNotify("Could not load the key service. Check your internet and re-run.")
    return
end
Junkie.service    = CONFIG.SERVICE
Junkie.identifier = CONFIG.IDENTIFIER
Junkie.provider   = CONFIG.PROVIDER
Junkie.script_id  = CONFIG.SCRIPT_ID

local function verify(key)
    if not CONFIG.CHECK_FIRST then return true end
    local ok, result = pcall(Junkie.check_key, key)
    if not ok then
        return false, "Could not reach the key server. Try again in a moment.", true
    end
    if type(result) ~= "table" or not result.valid then
        return false, reasonText(result), false
    end
    return true
end

local function runScript(key)
    genv.SCRIPT_KEY = key
    local ok, err = pcall(Junkie.load_script)
    if not ok then warn("load script failed: " .. tostring(err)) end
end

local startupNote = nil
local saved = readSavedKey()
if saved then
    local ok, why, networkError = verify(saved)
    if ok then
        runScript(saved)
        return
    end
    if networkError then
        startupNote = why
    else
        writeSavedKey("")
        startupNote = why
    end
end

local okR, Rayfield = pcall(function()
    return loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
end)
if not okR or type(Rayfield) ~= "table" then
    warn("Could not load Rayfield: " .. tostring(Rayfield))
    sysNotify("Could not load the key window (UI library). Check your internet and re-run.")
    return
end
genv.YattaKeyUI = Rayfield

local function notify(title, content, duration)
    pcall(function()
        Rayfield:Notify({ Title = title, Content = content, Duration = duration or 5 })
    end)
end

local okUI, errUI = xpcall(function()
local Window = Rayfield:CreateWindow({
    Name            = CONFIG.TITLE .. " | Key System",
    LoadingTitle    = CONFIG.TITLE,
    LoadingSubtitle = "key system",
    ConfigurationSaving = { Enabled = false },
    Discord         = { Enabled = false },
    KeySystem       = false,
})
local Tab = Window:CreateTab("Key", "key")

if startupNote then
    task.defer(function() notify("Saved key not used", startupNote, 6) end)
end

Tab:CreateSection("Get access")
Tab:CreateParagraph({
    Title   = "How it works",
    Content = "1) Press Get Key (the link is copied).\n2) Finish the steps in your browser.\n3) Paste the key below and press Verify Key. \n4) I'm sorry that the script now has a key system. I need money to help my family.\n5) If you want a lifetime key, click \"Purchase Key (Discord DMs)\"; it will give you a link you need to paste on a website. You must have a Discord account, and you need 400 Robux minimum to purchase a lifetime key, or you can use another payment method (real money). Note that I do not accept in-game gifting for keys.",
})

local busyLink = false
Tab:CreateButton({
    Name = "Get Key",
    Callback = function()
        if busyLink then return end
        busyLink = true
        task.spawn(function()
            local ok, link, err = pcall(Junkie.get_key_link)
            busyLink = false
            if not ok then
                notify("Could not get a link", "Try again in a moment.", 5)
                return
            end
            if not link then
                notify("Key link unavailable", tostring(err or "unknown error"), 6)
                return
            end
            local setclip = setclipboard or toclipboard or set_clipboard
            local copied = false
            if type(setclip) == "function" then copied = pcall(setclip, link) end
            if copied then
                notify("Link copied!", "paste in your browser.", 6)
            else
                notify("Your key link", tostring(link), 15)
                print("[YattaKey] Key link: " .. tostring(link))
            end
        end)
    end,
})

local keyBuffer = ""
local keyInput = Tab:CreateInput({
    Name                     = "Your key",
    CurrentValue             = "",
    PlaceholderText          = "Paste your key here",
    RemoveTextAfterFocusLost = false,
    Flag                     = "KeyInput",
    Callback                 = function(text) keyBuffer = tostring(text or "") end,
})

local busy = false
Tab:CreateButton({
    Name = "Verify Key",
    Callback = function()
        if busy then return end
        local key = trim((keyInput and keyInput.CurrentValue) or keyBuffer)
        if key == "" then
            notify("No key entered", "Paste your key into the box first.", 4)
            return
        end
        busy = true
        task.spawn(function()
            local ok, why = verify(key)
            if not ok then
                busy = false
                notify("Key rejected", why or "Invalid key.", 6)
                return
            end
            writeSavedKey(key)
            notify("Key accepted", "Loading " .. CONFIG.TITLE .. "...", 3)
            task.wait(0.8)
            pcall(function() Rayfield:Destroy() end)
            genv.YattaKeyUI = nil
            runScript(key)
        end)
    end,
})

Tab:CreateSection("Purchase Key")
Tab:CreateButton({
    Name = "Purchase Key (Discord DMs)",
    Callback = function()
        local setclip = setclipboard or toclipboard or set_clipboard
        local copied = false
        if type(setclip) == "function" then copied = pcall(setclip, CONFIG.DISCORD_LINK) end
        if copied then
            notify("Discord link copied", "Open it in your browser and DM " .. CONFIG.DISCORD_NAME .. " to purchase a key.", 7)
        else
            notify("Purchase a key", "DM " .. CONFIG.DISCORD_NAME .. " on Discord: " .. CONFIG.DISCORD_LINK, 15)
            print("[YattaKey] Discord: " .. CONFIG.DISCORD_LINK)
        end
    end,
})

Tab:CreateSection("Other")
Tab:CreateButton({
    Name = "Close script",
    Callback = function()
        pcall(function() Rayfield:Destroy() end)
        genv.YattaKeyUI = nil
    end,
})
end, function(e) return debug.traceback(tostring(e), 2) end)
if not okUI then
    warn("Key window failed:\n" .. tostring(errUI))
    sysNotify("Key window failed to open. See console (F9).")
end
