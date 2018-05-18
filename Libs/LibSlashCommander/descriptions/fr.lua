LibStub("LibSlashCommander"):AddFile("descriptions/fr.lua", 1, function(lib) -- by Ayantir
    local descriptions = {
        [GetString(SI_SLASH_SCRIPT)] = "Exécute la commande Lua spécifiée",
        [GetString(SI_SLASH_CHATLOG)] = "(Dés)active l'enregistrement du Chat",
        [GetString(SI_SLASH_GROUP_INVITE)] = "Invite la personne spécifiée dans le groupe",
        [GetString(SI_SLASH_JUMP_TO_LEADER)] = "Voyage vers le chef de groupe",
        [GetString(SI_SLASH_JUMP_TO_GROUP_MEMBER)] = "Voyage vers le membre du groupe spécifié",
        [GetString(SI_SLASH_JUMP_TO_FRIEND)] = "Voyage vers l'ami spécifié",
        [GetString(SI_SLASH_JUMP_TO_GUILD_MEMBER)] = "Voyage vers le membre de guilde spécifié",
        [GetString(SI_SLASH_RELOADUI)] = "Recharge l'UI",
        [GetString(SI_SLASH_PLAYED_TIME)] = "Affiche le temps joué pour ce personnage",
        [GetString(SI_SLASH_READY_CHECK)] = "Vérifie si les membres du groupe sont prêts",
        [GetString(SI_SLASH_DUEL_INVITE)] = "Invitation au duel à la personne spécifiée",
        [GetString(SI_SLASH_LOGOUT)] = "Déconnexion à la sélection de personnages",
        [GetString(SI_SLASH_CAMP)] = "Déconnexion à la sélection de personnages",
        [GetString(SI_SLASH_QUIT)] = "Quitte le jeu",
        [GetString(SI_SLASH_FPS)] = "Active/Désactive l'affichage des FPS",
        [GetString(SI_SLASH_LATENCY)] = "Active/Désactive l'affichage de la latence",
        [GetString(SI_SLASH_STUCK)] = "Affiche le panneau pour les personnages bloqués",
        [GetString(SI_SLASH_REPORT_BUG)] = "Affiche le panneau de soumission de bug",
        [GetString(SI_SLASH_REPORT_FEEDBACK)] = "Affiche le panneau de soumission de retour",
        [GetString(SI_SLASH_REPORT_HELP)] = "Affiche l'aide",
        [GetString(SI_SLASH_REPORT_CHAT)] = "Affiche le panneau de signalement de joueur",
    }
    ZO_ShallowTableCopy(descriptions, lib.descriptions)
end)
