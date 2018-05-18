local MAJOR, MINOR = "LibSlashCommander", 4
local lib = LibStub:NewLibrary(MAJOR, MINOR)

if not lib then
    return -- already loaded and no upgrade necessary
end

lib.loadedFiles = {}
function lib:AddFile(file, version, callback)
    if(not lib.loadedFiles[file] or version > lib.loadedFiles[file]) then
        callback(lib)
        lib.loadedFiles[file] = version
    end
end

function lib:Register(aliases, callback, description)
    local command = lib.Command:New()
    if(callback) then
        command:SetCallback(callback)
    end
    if(description) then
        command:SetDescription(description)
    end

    if(aliases) then
        if(type(aliases) == "table") then
            for i=1, #aliases do
                command:AddAlias(aliases[i])
            end
        else
            command:AddAlias(aliases)
        end
    end

    lib.globalCommand:RegisterSubCommand(command)
    return command
end

function lib:Unregister(command)
    lib.globalCommand:UnregisterSubCommand(command)
end

local function RunAutoCompletion(self, command, text)
    self.ignoreTextEntryChangedEvent = true
    lib.currentCommand = command
    self.textEntry:AutoCompleteTarget(text)
    self.ignoreTextEntryChangedEvent = false
end

local function GetCurrentCommandAndToken(command, input)
    local alias, newInput = input:match("(.-)%s+(.-)$")
    if(not alias or not lib.IsCommand(command)) then return command, input end
    local subCommand = command:GetSubCommandByAlias(alias)
    if(not subCommand) then return command, input end
    if(not newInput) then return subCommand, "" end
    return GetCurrentCommandAndToken(subCommand, newInput)
end

local function Sanitize(value)
    return value:gsub("[-*+?^$().[%]%%]", "%%%0") -- escape meta characters
end

local function OnTextEntryChanged(self, text)
    if(self.ignoreTextEntryChangedEvent or not lib.globalCommand:ShouldAutoComplete(text)) then return end
    lib.currentCommand = nil

    local command, token = GetCurrentCommandAndToken(lib.globalCommand, text)
    if(not command or not lib.IsCommand(command)) then return end

    lib.lastInput = text:match(string.format("(.+)%%s+%s$", Sanitize(token)))
    if(command:ShouldAutoComplete(token)) then
        RunAutoCompletion(self, command, token)
        return true
    end
end

local function OnSetChannel()
    CHAT_SYSTEM.textEntry:CloseAutoComplete()
end

local function OnAutoCompleteEntrySelected(self, text)
    local command = lib.hasCustomResults
    if(command) then
        text = command:GetAutoCompleteResultFromDisplayText(text)
        if(lib.lastInput) then
            text = string.format("%s %s", lib.lastInput, text)
            lib.lastInput = nil
        else
            text = string.format("%s ", text)
        end
        StartChatInput(text)
        return true
    end
end

local function GetTopMatches(command, text)
    local results = command:GetAutoCompleteResults(text)
    local topResults = GetTopMatchesByLevenshteinSubStringScore(results, text, 1, lib.maxResults)
    if topResults then
        return unpack(topResults)
    end
end

local function GetAutoCompletionResults(original, self, text)
    local command = lib.currentCommand
    if(command) then
        lib.hasCustomResults = command
        return GetTopMatches(command, text)
    else
        lib.hasCustomResults = nil
        return original(self, text)
    end
end

local function GetDescriptionText(alias)
    local description = lib.descriptions[alias]
    if(lib.IsCallable(description)) then
        return description()
    end
    return description
end

function lib:FormatLabel(alias, description, type)
    local color = lib.typeColor[type or lib.COMMAND_TYPE_ADDON] or ""
    if(description) then
        return string.format("%s%s|caaaaaa - %s", color, alias, description)
    end
    return string.format("%s%s", color, alias)
end

function lib:GenerateLabel(alias, description)
    if(not description) then description = GetDescriptionText(alias) end
    return lib:FormatLabel(alias, description, lib.types[alias])
end

local function Unload()
    CHAT_SYSTEM.OnTextEntryChanged = lib.oldOnTextEntryChanged
    CHAT_SYSTEM.SetChannel = lib.oldSetChannel
    CHAT_SYSTEM.OnAutoCompleteEntrySelected = lib.oldOnAutoCompleteEntrySelected
    CHAT_SYSTEM.textEntry.autoComplete.GetAutoCompletionResults = lib.oldGetAutoCompletionResults
    lib.globalCommand = nil
end

local function Load()
    lib.oldOnTextEntryChanged = CHAT_SYSTEM.OnTextEntryChanged
    lib.oldSetChannel = CHAT_SYSTEM.SetChannel
    lib.oldOnAutoCompleteEntrySelected = CHAT_SYSTEM.OnAutoCompleteEntrySelected
    lib.oldGetAutoCompletionResults = CHAT_SYSTEM.textEntry.autoComplete.GetAutoCompletionResults

    ZO_PreHook(CHAT_SYSTEM, "OnTextEntryChanged", OnTextEntryChanged)
    ZO_PreHook(CHAT_SYSTEM, "SetChannel", OnSetChannel)
    ZO_PreHook(CHAT_SYSTEM, "OnAutoCompleteEntrySelected", OnAutoCompleteEntrySelected)
    lib.WrapFunction(CHAT_SYSTEM.textEntry.autoComplete, "GetAutoCompletionResults", GetAutoCompletionResults)

    lib.globalCommand = lib.Command:New()
    lib.globalCommand.subCommandAliases = setmetatable({}, {
        __index = function(_, key)
            key = zo_strlower(key)
            return SLASH_COMMANDS[key] or CHAT_SYSTEM.switchLookup[key]
        end,
        __newindex = function(_, key, value)
            SLASH_COMMANDS[key] = value
        end
    })
    lib.globalCommand:SetAutoComplete(lib.AutoCompleteSlashCommandsProvider:New())

    lib.Unload = Unload
end

lib.GetCurrentCommandAndToken = GetCurrentCommandAndToken
lib.Init = function()
    lib.Init = function() end
    if(lib.Unload) then lib.Unload() end
    Load()
end

lib:AddFile("util.lua", 1, function(lib)
    lib.ERROR_INVALID_TYPE = "Invalid argument type"
    lib.ERROR_HAS_NO_PARENT = "Command does not have a parent"
    lib.ERROR_ALREADY_HAS_PARENT = "Command already has a parent"
    lib.ERROR_CIRCULAR_HIERARCHY = "Circular hierarchy detected"
    lib.ERROR_AUTOCOMPLETE_NOT_ACTIVE = "Tried to get autocomplete results while it's disabled"
    lib.ERROR_AUTOCOMPLETE_RESULT_NOT_VALID = "Autocomplete provider returned invalid result type"
    lib.ERROR_CALLED_WITHOUT_CALLBACK = "Tried to call command while no callback is set"
    lib.WARNING_ALREADY_HAS_ALIAS = "Warning: Overwriting existing command alias '%s'"

    function lib.Log(message, ...)
        df("[LibSlashCommander] %s", message:format(...))
    end

    function lib.IsCallable(func)
        return type(func) == "function" or type((getmetatable(func) or {}).__call) == "function"
    end

    function lib.HasBaseClass(baseClass, object)
        object = getmetatable(object)
        while object ~= nil do
            if(object.__index == baseClass) then return true end
            object = getmetatable(object)
        end
        return false
    end

    function lib.AssertIsType(value, typeNameClassOrValidator, errorMessage)
        local check = type(typeNameClassOrValidator)
        local valid = false
        if(check == "string") then
            valid = (type(value) == typeNameClassOrValidator)
        elseif(check == "function") then
            valid = typeNameClassOrValidator(value)
        else
            valid = lib.HasBaseClass(typeNameClassOrValidator, value)
        end
        assert(valid, errorMessage or lib.ERROR_INVALID_TYPE)
    end

    function lib.WrapFunction(object, functionName, wrapper)
        if(type(object) == "string") then
            wrapper = functionName
            functionName = object
            object = _G
        end
        local originalFunction = object[functionName]
        object[functionName] = function(...) return wrapper(originalFunction, ...) end
    end
end)

lib:AddFile("providers/AutoCompleteProvider.lua", 1, function(lib)
    if(not lib.AutoCompleteProvider) then lib.AutoCompleteProvider = ZO_Object:Subclass() end
    local AutoCompleteProvider = lib.AutoCompleteProvider

    function lib.IsAutoCompleteProvider(provider)
        return lib.HasBaseClass(AutoCompleteProvider, provider)
    end

    function AutoCompleteProvider:New(...)
        local obj = ZO_Object.New(self)
        obj:Initialize(...)
        return obj
    end

    function AutoCompleteProvider:Initialize(data)
        local results = {}
        if(type(data) == "table") then
            for i = 1, #data do
                results[zo_strlower(data[i])] = data[i]
            end
        end
        self.results = results
        self.lookup = {}
    end

    function AutoCompleteProvider:SetPrefix(prefix)
        if(not prefix) then
            self.prefix = nil
        else
            lib.AssertIsType(prefix, "string")
            self.prefix = prefix
        end
    end

    --- used to filter tokens before autocompletion starts
    --- e.g. return false when the passed token does not start with '/' to wait for actual slash commands
    function AutoCompleteProvider:CanComplete(token)
        return not self.prefix or (token:sub(1, #self.prefix) == self.prefix)
    end

    --- returns a table which gets passed to GetTopMatchesByLevenshteinSubStringScore
    --- The table requires string keys which are used for comparison and string values which are used as labels in the result box
    --- Due to the way ZOS implemented the autocompletion, the label is also used as result which shows up in the chat input field.
    --- when the label contains some extra info which should not show up when selected, this method needs to setup a lookup table which is then used by GetResultFromLabel.
    function AutoCompleteProvider:GetResultList()
        return self.results
    end

    --- returns the final string that shows up in the chat box. If no lookup table is available, it will just return the label
    --- the lookup table should be generated and set together with the return value for GetResultList to avoid mismatches.
    function AutoCompleteProvider:GetResultFromLabel(label)
        return self.lookup[label] or label
    end
end)

lib:AddFile("providers/AutoCompleteSlashCommandsProvider.lua", 2, function(lib)
    local AutoCompleteProvider = lib.AutoCompleteProvider

    if(not lib.AutoCompleteSlashCommandsProvider) then lib.AutoCompleteSlashCommandsProvider = AutoCompleteProvider:Subclass() end
    local AutoCompleteSlashCommandsProvider = lib.AutoCompleteSlashCommandsProvider

    function lib.IsAutoCompleteSlashCommandsProvider(provider)
        return lib.HasBaseClass(AutoCompleteSlashCommandsProvider, provider)
    end

    function AutoCompleteSlashCommandsProvider:New()
        local provider = AutoCompleteProvider.New(self)
        provider:SetPrefix("/")
        return provider
    end

    local function AddCommand(results, lookup, alias, description)
        local label = lib:GenerateLabel(alias, description)
        if(label ~= alias) then
            lookup[label] = alias
        end
        results[zo_strlower(alias)] = label
    end

    function AutoCompleteSlashCommandsProvider:GetResultList()
        local results = {}
        local lookup = {}
        for alias, command in pairs(SLASH_COMMANDS) do
            local description
            if(lib.IsCommand(command)) then
                description = command:GetDescription()
            end
            AddCommand(results, lookup, alias, description)
        end
        for alias in pairs(CHAT_SYSTEM.switchLookup) do
            AddCommand(results, lookup, alias)
        end
        self.lookup = lookup
        return results
    end
end)

lib:AddFile("providers/AutoCompleteSubCommandsProvider.lua", 1, function(lib)
    local AutoCompleteProvider = lib.AutoCompleteProvider

    if(not lib.AutoCompleteSubCommandsProvider) then lib.AutoCompleteSubCommandsProvider = AutoCompleteProvider:Subclass() end
    local AutoCompleteSubCommandsProvider = lib.AutoCompleteSubCommandsProvider

    function lib.IsAutoCompleteSubCommandsProvider(provider)
        return lib.HasBaseClass(AutoCompleteSubCommandsProvider, provider)
    end

    function AutoCompleteSubCommandsProvider:New(command)
        lib.AssertIsType(command, lib.IsCommand)
        local provider = AutoCompleteProvider.New(self)
        provider.command = command
        return provider
    end

    function AutoCompleteSubCommandsProvider:FormatLabel(alias, description)
        if(description) then
            return string.format("%s|caaaaaa - %s", alias, description)
        end
        return alias
    end

    function AutoCompleteSubCommandsProvider:GetResultList()
        local results = {}
        local lookup = {}
        for alias, subCommand in pairs(self.command.subCommandAliases) do
            local label = self:FormatLabel(alias, subCommand:GetDescription(alias))
            if(label ~= alias) then
                lookup[label] = alias
            end
            results[zo_strlower(alias)] = label
        end
        self.lookup = lookup
        return results
    end
end)

lib:AddFile("descriptions/en.lua", 1, function(lib)
    lib.descriptions = {
        [GetString(SI_SLASH_SCRIPT)] = "Executes the specified text as Lua code",
        [GetString(SI_SLASH_CHATLOG)] = "Toggles the chat log on or off",
        [GetString(SI_SLASH_GROUP_INVITE)] = "Invites the specified name to the group",
        [GetString(SI_SLASH_JUMP_TO_LEADER)] = "Travels to the group leader",
        [GetString(SI_SLASH_JUMP_TO_GROUP_MEMBER)] = "Travels to the specified grp. member",
        [GetString(SI_SLASH_JUMP_TO_FRIEND)] = "Travels to the specified friend",
        [GetString(SI_SLASH_JUMP_TO_GUILD_MEMBER)] = "Travels to the specified guild member",
        [GetString(SI_SLASH_RELOADUI)] = "Reloads the user interface",
        [GetString(SI_SLASH_PLAYED_TIME)] = "Shows the time played on this character",
        [GetString(SI_SLASH_READY_CHECK)] = "Initiates a ready check while grouped",
        [GetString(SI_SLASH_DUEL_INVITE)] = "Challenges the specified player to a duel",
        [GetString(SI_SLASH_LOGOUT)] = "Returns to the character selection",
        [GetString(SI_SLASH_CAMP)] = "Returns to the character selection",
        [GetString(SI_SLASH_QUIT)] = "Closes the game",
        [GetString(SI_SLASH_FPS)] = "Toggles the FPS display",
        [GetString(SI_SLASH_LATENCY)] = "Toggles the latency display",
        [GetString(SI_SLASH_STUCK)] = "Opens the help screen for stuck characters",
        [GetString(SI_SLASH_REPORT_BUG)] = "Opens the bug report screen",
        [GetString(SI_SLASH_REPORT_FEEDBACK)] = "Opens the feedback report screen",
        [GetString(SI_SLASH_REPORT_HELP)] = "Opens the help screen",
        [GetString(SI_SLASH_REPORT_CHAT)] = "Opens the report player screen",
    }

    -- emote and chat switch descriptions are assigned in types.lua
end)

lib:AddFile("descriptions/types.lua", 1, function(lib)
    lib.COMMAND_TYPE_BUILT_IN = 1
    lib.COMMAND_TYPE_CHAT_SWITCH = 2
    lib.COMMAND_TYPE_EMOTE = 3
    lib.COMMAND_TYPE_ADDON = 4

    lib.typeColor = {
        [lib.COMMAND_TYPE_BUILT_IN] = "|c87C180",
        [lib.COMMAND_TYPE_CHAT_SWITCH] = "|cD8D891",
        [lib.COMMAND_TYPE_EMOTE] = "|c88A1CC",
        [lib.COMMAND_TYPE_ADDON] = "|cEC9746",
    }

    lib.types = {}

    for slashName in pairs(lib.descriptions) do
        lib.types[slashName] = lib.COMMAND_TYPE_BUILT_IN
    end

    for i = 1, GetNumEmotes() do
        local slashName, _, _, displayName = GetEmoteInfo(i)
        lib.types[slashName] = lib.COMMAND_TYPE_EMOTE
        lib.descriptions[slashName] = displayName
    end

    for slashName, data in pairs(CHAT_SYSTEM.switchLookup) do
        if(type(slashName) == "string") then
            lib.types[slashName] = lib.COMMAND_TYPE_CHAT_SWITCH
            if(data.dynamicName) then
                lib.descriptions[slashName] = function()
                    return GetDynamicChatChannelName(data.id)
                end
            else
                lib.descriptions[slashName] = data.name
            end
        end
    end
end)

lib:AddFile("Command.lua", 1, function(lib)
    if(not lib.Command) then lib.Command = ZO_Object:Subclass() end
    local Command = lib.Command
    local AutoCompleteProvider = lib.AutoCompleteProvider
    local AutoCompleteSubCommandsProvider = lib.AutoCompleteSubCommandsProvider
    local AssertIsType = lib.AssertIsType

    function lib.IsCommand(command)
        return lib.HasBaseClass(Command, command)
    end

    function Command:New(...)
        local obj = ZO_Object.New(self)
        obj:Initialize(...)
        return obj
    end

    function Command:Initialize()
        self.callback = nil

        -- make the table callable
        local meta = getmetatable(self)
        meta.__call = function(self, input)
            if(type(input) == "string" and next(self.subCommandAliases)) then
                local alias, newInput = input:match("(.-)%s+(.-)$")
                if(not alias) then alias = input end
                local subCommand = self.subCommandAliases[alias]
                if(subCommand) then
                    subCommand(newInput)
                    return
                end
            end
            if(self.callback) then
                self.callback(input)
            else
                error(lib.ERROR_CALLED_WITHOUT_CALLBACK)
            end
        end

        self.aliases = {}
        self.subCommands = {}
        self.subCommandAliases = {}
        self.autocomplete = nil
    end

    function Command:SetDescription(description)
        if(description) then
            AssertIsType(description, "string")
        end
        self.description = description
    end

    function Command:GetDescription(alias)
        return self.description
    end

    function Command:SetCallback(callback)
        if(callback ~= nil) then
            AssertIsType(callback, lib.IsCallable)
        end
        self.callback = callback
    end

    function Command:GetCallback(callback)
        return self.callback
    end

    function Command:AddAlias(alias)
        AssertIsType(alias, "string")
        self.aliases[alias] = self
        if(self.parent ~= nil) then
            self.parent:RegisterSubCommandAlias(alias, self)
        end
    end

    function Command:HasAlias(alias)
        if(self.aliases[alias]) then
            return true
        end
        return false
    end

    function Command:RemoveAlias(alias)
        self.aliases[alias] = nil
        if(self.parent ~= nil) then
            self.parent:UnregisterSubCommandAlias(alias)
        end
    end

    function Command:HasAncestor(parent)
        while parent ~= nil do
            if(parent == self) then return true end
            parent = parent.parent
        end
        return false
    end

    function Command:SetParentCommand(command)
        if(command == nil) then
            assert(self.parent, lib.ERROR_HAS_NO_PARENT)
            for alias in pairs(self.aliases) do
                self.parent:UnregisterSubCommandAlias(alias)
            end
            self.parent = nil
        else
            assert(not self.parent, lib.ERROR_ALREADY_HAS_PARENT)
            AssertIsType(command, Command)
            assert(not self:HasAncestor(command), lib.ERROR_CIRCULAR_HIERARCHY)
            self.parent = command
            for alias in pairs(self.aliases) do
                self.parent:RegisterSubCommandAlias(alias, self)
            end
        end
    end

    function Command:RegisterSubCommand(command)
        if(command == nil) then
            command = Command:New()
        end
        AssertIsType(command, Command)
        command:SetParentCommand(self)
        self.subCommands[command] = command
        if(not self.autocomplete) then
            self:SetAutoComplete(true)
        end
        return command
    end

    function Command:HasSubCommand(command)
        if(self.subCommands[command]) then
            return true
        end
        return false
    end

    function Command:UnregisterSubCommand(command)
        command:SetParentCommand(nil)
        self.subCommands[command] = nil
        if(lib.IsAutoCompleteSubCommandsProvider(self.autocomplete) and not next(self.subCommands)) then
            self:SetAutoComplete(false)
        end
    end

    function Command:RegisterSubCommandAlias(alias, command)
        AssertIsType(alias, "string")
        AssertIsType(command, Command)
        if(self.subCommandAliases[alias]) then
            lib.Log(lib.WARNING_ALREADY_HAS_ALIAS, alias)
        end
        self.subCommandAliases[alias] = command
    end

    function Command:HasSubCommandAlias(alias)
        if(self.subCommandAliases[alias]) then
            return true
        end
        return false
    end

    function Command:GetSubCommandByAlias(alias)
        return self.subCommandAliases[alias]
    end

    function Command:UnregisterSubCommandAlias(alias)
        self.subCommandAliases[alias] = nil
    end

    function Command:SetAutoComplete(provider)
        if(provider == nil or provider == false) then
            self.autocomplete = nil
        elseif(provider == true) then
            self.autocomplete = AutoCompleteSubCommandsProvider:New(self)
        elseif(lib.IsAutoCompleteProvider(provider)) then
            self.autocomplete = provider
        elseif(type(provider) == "table") then
            self.autocomplete = AutoCompleteProvider:New(provider)
        else
            error(lib.ERROR_INVALID_TYPE)
        end
        return self.autocomplete
    end

    function Command:ShouldAutoComplete(token)
        if(self.autocomplete and self.autocomplete:CanComplete(token)) then
            return true
        end
        return false
    end

    function Command:GetAutoCompleteResults()
        assert(self.autocomplete ~= nil, lib.ERROR_AUTOCOMPLETE_NOT_ACTIVE)
        local results = self.autocomplete:GetResultList()
        AssertIsType(results, "table", lib.ERROR_AUTOCOMPLETE_RESULT_NOT_VALID)
        return results
    end

    function Command:GetAutoCompleteResultFromDisplayText(label)
        assert(self.autocomplete ~= nil, lib.ERROR_AUTOCOMPLETE_NOT_ACTIVE)
        AssertIsType(label, "string")
        local result = self.autocomplete:GetResultFromLabel(label)
        AssertIsType(result, "string", lib.ERROR_AUTOCOMPLETE_RESULT_NOT_VALID)
        return result
    end
end)

lib.Init()

