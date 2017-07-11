-- character does not know Ancient Orc Staves

[36] =
{
    [1] = "Consume to start quest:\nCraft a Ruby Ash Lightning Staff; Quality: Epic; Trait: Training; Set: Night Mother's Gaze; Style: Ancient Orc",
    [2] = "|H0:item:119681:6:1:0:0:0:74:192:4:51:6:22:0:0:0:0:0:0:0:0:55125|h|h",
    [3] = "smithing",
    [4] = "request_item:74 Ruby Ash Lightning Staff",
    [5] = "set_bonus:51",
    [6] =
    {
        ["trait_ct"] = 6,
        ["name"] = "Night Mother's Gaze",
        ["dol_set_index"] = 14,
    },
    [7] = "trait:6",
    [8] =
    {
        ["mat_name"] = "carnelian",
        ["trait_index"] = 6,
        ["trait_name"] = "training",
    },
    [9] = "motif:22",
    [10] =
    {
        ["mat_name"] = "cassiterite",
        ["motif_name"] = "Ancient Orc",
        ["pages_id"] = 1341,
    },
    [11] = "improve:4",
    [12] =
    {
        ["purple_mat_ct"] = 4,
        ["gold_mat_ct"] = 0,
        ["green_mat_ct"] = 2,
        ["name"] = "Epic",
        ["blue_mat_ct"] = 3,
        ["index"] = 4,
    },
 -> [13] = "motif book IsSmithingStyleKnown(22+1) = false",
 -> [14] = "motif page GetAchievementCriterion(pages_id=1341, req.page=13) = 0",
 -> [15] = "pages known:0 0 0 0 0 0 0 0 0 0 0 0 0 0",
 -> [16] = "is_known:false name:motif Ancient Orc lack_msg:Motif Ancient Orc not known",
    [17] = "GetSmithingResearchLineInfo(skill=6, line=4) = lightning staff",
    [18] = "GetSmithingResearchLineTraitInfo(skill=6, line=4, trait=6) = true",
    [19] = "is_known:true name:trait training lightning staff lack_msg:Trait training lightning staff not known",
    [20] = "known traits for GSRLTI(skill=6, line=4, trait_index=?):1 1 1 1 1 1 1 1 0",
    [21] = "is_known:true name:6 traits for set bonus lack_msg:8 of 6 traits required for set Night Mother's Gaze",
},


-- character knows Ancient Orc Staves

[48] =
{
    [1] = "Consume to start quest:\nCraft a Ruby Ash Lightning Staff; Quality: Epic; Trait: Training; Set: Night Mother's Gaze; Style: Ancient Orc",
    [2] = "|H0:item:119681:6:1:0:0:0:74:192:4:51:6:22:0:0:0:0:0:0:0:0:55125|h|h",
    [3] = "smithing",
    [4] = "request_item:74 Ruby Ash Lightning Staff",
    [5] = "set_bonus:51",
    [6] =
    {
        ["trait_ct"] = 6,
        ["name"] = "Night Mother's Gaze",
        ["dol_set_index"] = 14,
    },
    [7] = "trait:6",
    [8] =
    {
        ["mat_name"] = "carnelian",
        ["trait_index"] = 6,
        ["trait_name"] = "training",
    },
    [9] = "motif:22",
    [10] =
    {
        ["mat_name"] = "cassiterite",
        ["motif_name"] = "Ancient Orc",
        ["pages_id"] = 1341,
    },
    [11] = "improve:4",
    [12] =
    {
        ["purple_mat_ct"] = 4,
        ["blue_mat_ct"] = 3,
        ["green_mat_ct"] = 2,
        ["name"] = "Epic",
        ["gold_mat_ct"] = 0,
        ["index"] = 4,
    },
 -> [13] = "motif book IsSmithingStyleKnown(22+1) = true",
 -> [14] = "is_known:true name:motif Ancient Orc lack_msg:Motif Ancient Orc not known",
    [15] = "GetSmithingResearchLineInfo(skill=6, line=4) = lightning staff",
    [16] = "GetSmithingResearchLineTraitInfo(skill=6, line=4, trait=6) = true",
    [17] = "is_known:true name:trait training lightning staff lack_msg:Trait training lightning staff not known",
    [18] = "known traits for GSRLTI(skill=6, line=4, trait_index=?):1 1 1 1 1 1 1 1 1",
    [19] = "is_known:true name:6 traits for set bonus lack_msg:9 of 6 traits required for set Night Mother's Gaze",
},

-- learn Ancient Orc Daggers + Staves

[66] =
{
    [1] = "Consume to start quest:\nCraft a Ruby Ash Lightning Staff; Quality: Epic; Trait: Training; Set: Night Mother's Gaze; Style: Ancient Orc",
    [2] = "|H0:item:119681:6:1:0:0:0:74:192:4:51:6:22:0:0:0:0:0:0:0:0:55125|h|h",
    [3] = "smithing",
    [4] = "request_item:74 Ruby Ash Lightning Staff",
    [5] = "set_bonus:51",
    [6] =
    {
        ["dol_set_index"] = 14,
        ["name"] = "Night Mother's Gaze",
        ["trait_ct"] = 6,
    },
    [7] = "trait:6",
    [8] =
    {
        ["trait_name"] = "training",
        ["mat_name"] = "carnelian",
        ["trait_index"] = 6,
    },
    [9] = "motif:22",
    [10] =
    {
        ["mat_name"] = "cassiterite",
        ["pages_id"] = 1341,
        ["motif_name"] = "Ancient Orc",
    },
    [11] = "improve:4",
    [12] =
    {
        ["blue_mat_ct"] = 3,
        ["green_mat_ct"] = 2,
        ["index"] = 4,
        ["name"] = "Epic",
        ["purple_mat_ct"] = 4,
        ["gold_mat_ct"] = 0,
    },
 -> [13] = "motif book IsSmithingStyleKnown(22+1) = false",
 -> [14] = "motif page GetAchievementCriterion(pages_id=1341, req.page=13) = 1",
 -> [15] = "pages known:0 0 0 0 0 1 0 0 0 0 0 0 1 0",
 -> [16] = "is_known:true name:motif Ancient Orc lack_msg:Motif Ancient Orc not known",
    [17] = "GetSmithingResearchLineInfo(skill=6, line=4) = lightning staff",
    [18] = "GetSmithingResearchLineTraitInfo(skill=6, line=4, trait=6) = true",
    [19] = "is_known:true name:trait training lightning staff lack_msg:Trait training lightning staff not known",
    [20] = "known traits for GSRLTI(skill=6, line=4, trait_index=?):1 1 1 1 1 1 1 1 0",
    [21] = "is_known:true name:6 traits for set bonus lack_msg:8 of 6 traits required for set Night Mother's Gaze",
},
