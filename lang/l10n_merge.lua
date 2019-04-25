-- If current language has a file in lang/XX.lua , then load its strings
-- on top of EN strings. Leaves untouched EN strings intact (such as any
-- slash command or shortened string that aren't currently translated).
function WritWorthy.L10N_Merge()
    if WritWorthy.STR_L10N then
        for k,v in pairs(WritWorthy.STR_L10N) do
            WritWorthy.STR[k] = v
        end
    end

    if WritWorthy.SHORTEN_L10N then
        for k,v in pairs(WritWorthy.SHORTEN_L10N) do
            WritWorthy.SHORTEN[k] = v
        end
    end
end
WritWorthy.L10N_Merge()
