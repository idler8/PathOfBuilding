local basePath = (GetUserPath()) .. "/Path of Building/"
local function logUser(text)
    local file = io.open(basePath .. '/debug.log', "a")
    io.output(file)
    io.write(text .. "\n")
    io.close(file)
end
local function getFile(URL)
    local page = ""
    local easy = common.curl.easy()
    easy:setopt_url(URL);
    easy:setopt(common.curl.OPT_SSL_VERIFYPEER, false)
    easy:setopt_writefunction(function(data)
        page = page .. data
        return true
    end)
    easy:perform()
    easy:close()
    return #page > 0 and page
end
local function GetLuaJson(jsonFilePath, url, match)
    local page
    local jsonFile = io.open(jsonFilePath, "r")
    if not jsonFile then
        page = getFile(url)
    else
        page = jsonFile:read("*a")
        jsonFile:close()
    end
    if match then
        local treeData = page:match(match)
        if treeData then
            return "local tree=" .. jsonToLua(treeData) .. " return tree"
        end
    end
    return "return " .. jsonToLua(page)
end
function GetCacheLuaJson(dirPath, luaFileName, jsonOnline, match)
    local dirRoot = "TreeData";
    local dirVersion = dirRoot
    if dirPath then
        dirVersion = dirVersion .. "/" .. dirPath
    end
    local luaFilePath = dirVersion .. "/" .. luaFileName
    local jsonFilePath = luaFilePath .. '.json'
    MakeDir(dirVersion)
    MakeDir(basePath .. dirVersion)
    ConPrintf("Loading json data for path '%s'...", luaFilePath)
    local treeText
    local treeFile = io.open(luaFilePath, "r")
    luaFilePath = basePath .. luaFilePath
    if not treeFile then
        treeFile = io.open(luaFilePath, "r")
    end
    if not treeFile then
        ConPrintf("Downloading passive tree data...")
        treeText = GetLuaJson(jsonFilePath, jsonOnline, match)
        treeFile = io.open(luaFilePath, "w")
        treeFile:write(treeText)
        treeFile:close()
    else
        treeText = treeFile:read("*a")
        treeFile:close()
    end
    return load(treeText)()
end

local function init(language)
    local function translate(key)
        return language[key] or key
    end
    local function transfer(text)
        local prefix = "";
        local suffix = "";
        if string.sub(text, -3, -1) == "..." then
            text = string.sub(text, 1, -4)
        end
        if string.sub(text, -1, -1) == ":" then
            text = string.sub(text, 1, -2)
            suffix = ":" .. suffix
        end
        if string.sub(text, -2, -1) == "^7" then
            text = string.sub(text, 1, -3)
            suffix = "^7" .. suffix
        end
        if string.find(text, "^%^%d") then
            prefix = prefix .. string.sub(text, 1, 2)
            text = string.sub(text, 3)
        end
        if string.find(text, "^%^x%x%x%x%x%x%x") then
            prefix = prefix .. string.sub(text, 1, 8)
            text = string.sub(text, 9)
        end
        if string.sub(text, 1, 1) == "^" then
            prefix = prefix .. string.sub(text, 1, 2)
            text = string.sub(text, 3)
        end
        -- TODO Vaal ** (xx) => Vaal xx
        if string.sub(text, 1, string.len("Current build")) == "Current build" then
            prefix = translate("Current build")
            suffix = string.sub(text, string.len("Current build:") + 3)
            text = "："
            if suffix == "Unnamed build" then
                suffix = translate(suffix)
            end
        end
        return prefix .. translate(text) .. suffix
    end
    local function itemTransfer(text)
        -- TODO simple Transfer
        if string.sub(text, -3, -1) ~= "..." then
            local noDot = (string.gsub(text, ",", ""))
            local allTransfer = transfer(noDot)
            if allTransfer ~= noDot then
                return allTransfer
            end
        end
        text = (string.gsub(text, "[^^](%^x?%x+)", ",%1"))
        text = (string.gsub(text, "%s*%b()", ",%1"))
        text = (string.gsub(text, ",%s*", ","))
        text = (string.gsub(text, "[^,]+", transfer))
        return (string.gsub(text, ",+", " "))
    end
    local function replace(text)
        local f3 = debug.getinfo(3);
        if f3 then
            if f3.source == '@Modules/Main.lua' then
                -- return transfer(text)
            elseif f3.source == '@Modules/Build.lua' then
                return transfer(text)
            elseif f3.source == '@Classes/TextListControl.lua' then
                return transfer(text)
            elseif f3.source == '@Classes/ItemSlotControl.lua' then
                return transfer(text)
            elseif f3.source == '@Classes/ListControl.lua' then
                if f3.currentline == 179 then
                    return transfer(text)
                elseif f3.currentline == 273 then
                    local f4 = debug.getinfo(4)
                    if f4 and f4.source == "@Classes/ItemDBControl.lua" and f4.currentline == 303 then
                        return itemTransfer(text)
                    end
                    local f5 = debug.getinfo(5)
                    if f5 and f5.source == "@Classes/ItemsTab.lua" and f5.currentline == 1216 then
                        return itemTransfer(text)
                    end
                elseif f3.currentline == 276 then
                    return itemTransfer(text)
                end
            elseif f3.source == '@Classes/SectionControl.lua' then
                return transfer(text)
            elseif f3.source == '@Classes/CalcSectionControl.lua' then
                return transfer(text)
            elseif f3.source == '@Classes/GemSelectControl.lua' then
                if f3.currentline == 463 then
                    return transfer(text)
                end
            elseif f3.source == '@Classes/PopupDialog.lua' then
                return transfer(text)
            elseif f3.source == '@Classes/DropDownControl.lua' then
                local f4 = debug.getinfo(4)
                if f4 and f4.source == '@Classes/ItemSlotControl.lua' and f4.currentline == 125 then
                    return itemTransfer(text)
                end
                local f5 = debug.getinfo(5)
                if f5 and f5.source == '@Classes/SkillsTab.lua' and f5.currentline == 546 then
                    return itemTransfer(text)
                end
                if f5 and f5.source == '@Modules/Build.lua' and f5.currentline == 1090 then
                    return itemTransfer(text)
                end
                return transfer(text)
            elseif f3.source == '@Classes/CheckBoxControl.lua' then
                return transfer(text)
            elseif f3.source == '@Classes/LabelControl.lua' then
                return transfer(text)
            elseif f3.source == '@Classes/ButtonControl.lua' then
                local f5 = debug.getinfo(5)
                if f5 and f5.source ~= '@Classes/PathControl.lua' then
                    return transfer(text)
                end
            elseif f3.source == '@Classes/EditControl.lua' then
                if f3.currentline == 273 or f3.currentline == 275 or f3.currentline == 295 then
                    return transfer(text)
                end
            elseif f3.source == '@Classes/Tooltip.lua' then
                local fromSource = debug.getinfo(4)
                if fromSource.source == '@Classes/PassiveTreeView.lua' then
                    return transfer(text)
                end
            end
        end
        return text
        -- return text, f3
    end
    local function SetPassiveLanguage(defTree, theTree)
        for k, v in pairs(defTree.nodes) do
            local t = theTree.nodes[k]
            if v and t then
                if v.name and t.name then
                    language[v.name] = t.name
                end
                if v.stats then
                    for i, v in ipairs(v.stats) do
                        local vline = string.gmatch(v, "([^\n]*)\n?")
                        local tline = string.gmatch(t.stats[i], "([^\n]*)\n?")
                        for v in vline do
                            language[v] = tline()
                        end
                    end
                end
                if v.masteryEffects then
                    for i1, v in ipairs(v.masteryEffects) do
                        for i2, v in ipairs(v.stats) do
                            local vline = string.gmatch(v, "([^\n]*)\n?")
                            local tline = string.gmatch(t.masteryEffects[i1].stats[i2], "([^\n]*)\n?")
                            for v in vline do
                                language[v] = tline()
                            end
                        end
                    end
                end
            end
        end
    end
    local function SetItemLanguage(defTree, theTree)
        for k, v in pairs(defTree.result) do
            local t = theTree.result[k]
            if t.label and v.label then
                language[v.label] = t.label
            end
            for i, v in ipairs(v.entries) do
                if t.entries[i] then
                    if v.text and t.entries[i].text then
                        language[v.text] = t.entries[i].text
                    end
                    if v.name and t.entries[i].name then
                        language[v.name] = t.entries[i].name
                    end
                    if v.type and t.entries[i].type then
                        language[v.type] = t.entries[i].type
                    end
                end

            end
        end
    end

    return {
        logUser = logUser,
        replace = replace,
        transfer = transfer,
        itemTransfer = itemTransfer,
        SetPassiveLanguage = SetPassiveLanguage,
        SetItemLanguage = SetItemLanguage
    }
end

return init
