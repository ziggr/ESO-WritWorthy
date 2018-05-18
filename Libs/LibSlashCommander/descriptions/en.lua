LibStub("LibSlashCommander"):AddFile("descriptions/en.lua", 1, function(lib)
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
