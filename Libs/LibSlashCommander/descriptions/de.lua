LibStub("LibSlashCommander"):AddFile("descriptions/de.lua", 1, function(lib)
    local descriptions = {
        [GetString(SI_SLASH_SCRIPT)] = "Führt den angegebenen Text als Lua Code aus",
        [GetString(SI_SLASH_CHATLOG)] = "Schaltet das Nachrichtenprotokoll ein und aus",
        [GetString(SI_SLASH_GROUP_INVITE)] = "Lädt den angegebenen Namen in die Gruppe ein",
        [GetString(SI_SLASH_JUMP_TO_LEADER)] = "Reist zum Gruppenleiter",
        [GetString(SI_SLASH_JUMP_TO_GROUP_MEMBER)] = "Reist zum genannten Gruppenm.",
        [GetString(SI_SLASH_JUMP_TO_FRIEND)] = "Reist zum genannten Freund",
        [GetString(SI_SLASH_JUMP_TO_GUILD_MEMBER)] = "Reist zum genannten Gildenmitglied",
        [GetString(SI_SLASH_RELOADUI)] = "Lädt das Benutzerinterface neu",
        [GetString(SI_SLASH_PLAYED_TIME)] = "Zeigt die gespielte Zeit auf diesem Charakter",
        [GetString(SI_SLASH_READY_CHECK)] = "Startet den Bereitschaftscheck in der Gruppe",
        [GetString(SI_SLASH_DUEL_INVITE)] = "Fordert den angegebenen Spieler zu einem Duell",
        [GetString(SI_SLASH_LOGOUT)] = "Kehrt zur Charakterauswahl zurück",
        [GetString(SI_SLASH_CAMP)] = "Kehrt zur Charakterauswahl zurück",
        [GetString(SI_SLASH_QUIT)] = "Beendet das Spiel",
        [GetString(SI_SLASH_FPS)] = "Schaltet die FPS-Anzeige um",
        [GetString(SI_SLASH_LATENCY)] = "Schaltet die Latenzanzeige um",
        [GetString(SI_SLASH_STUCK)] = "Öffnet die Hilfe für feststeckende Spieler",
        [GetString(SI_SLASH_REPORT_BUG)] = "Öffnet das Formular zum Fehler melden",
        [GetString(SI_SLASH_REPORT_FEEDBACK)] = "Öffnet das Formular für Feedback",
        [GetString(SI_SLASH_REPORT_HELP)] = "Öffnet die Hilfe",
        [GetString(SI_SLASH_REPORT_CHAT)] = "Öffnet das Formular zum Spieler melden",
    }
    ZO_ShallowTableCopy(descriptions, lib.descriptions)
end)
