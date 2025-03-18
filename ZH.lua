-- Frame and Events Setup
local addonFrame = CreateFrame("Frame")
addonFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
addonFrame:RegisterEvent("PLAYER_LOGIN")
addonFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

-- Localization Definitions
local translations = {
    enUS = {
        ACTIVE = "Heroism feature is",
        MODE_SET_TO = "Announcement mode is set to",
        STATUS_INFO = "Heroism Status:",
        READY_MESSAGE = "is ready to use again!",
        HASTE_15_MSG = "granted +15% haste to the group!",
        HASTE_30_MSG = "granted +30% haste to the group!",
        EXPIRED_MSG = "The effect has ended. It will be available again in 10 minutes!",
        NOTIFY_TOGGLE = "Heroism expiration notification is",
        ANNOUNCE_MODE = "Announcement mode:",
        HELP_COMMANDS = "Available Commands",
        ABILITY_USED = "activated:",
        SPELL_CAST = "cast:",
        LOAD_COMPLETE = "Heroism Addon Loaded",
        ENABLED = "ENABLED",
        DISABLED = "DISABLED",
        SELF_MODE = "SELF",
        SOURCE = "source",
        PET_ABILITY = "Heroism triggered by pet",
        RAID_WARNING_MODE = "RAID WARNING",
        TEST_MESSAGE = "The addon works correctly!",
    },
    ruRU = {
        ACTIVE = "Функция Героизма",
        MODE_SET_TO = "Режим оповещения установлен на",
        STATUS_INFO = "Состояние Героизма:",
        READY_MESSAGE = "готов снова к использованию!",
        HASTE_15_MSG = "дал +15% скорости группе!",
        HASTE_30_MSG = "дал +30% скорости группе!",
        EXPIRED_MSG = "эффект закончился. Будет доступен через 10 минут!",
        NOTIFY_TOGGLE = "Уведомление о завершении действия Героизма",
        ANNOUNCE_MODE = "Режим оповещения:",
        HELP_COMMANDS = "Доступные команды",
        ABILITY_USED = "активирован:",
        SPELL_CAST = "применён:",
        LOAD_COMPLETE = "Аддон Героизм Загружен",
        ENABLED = "ВКЛЮЧЕН",
        DISABLED = "ВЫКЛЮЧЕН",
        SELF_MODE = "СЕБЕ",
        SOURCE = "источник",
        PET_ABILITY = "Героизм активирован питомцем",
        RAID_WARNING_MODE = "Оповещение Рейда",
        TEST_MESSAGE = "Аддон работает корректно!",
    },
    deDE = {
        ACTIVE = "Die Heldenhaft-Funktion ist",
        MODE_SET_TO = "Der Ankündigungsmodus ist eingestellt auf",
        STATUS_INFO = "Heldenhaft-Status:",
        READY_MESSAGE = "ist wieder einsatzbereit!",
        HASTE_15_MSG = "hat der Gruppe +15% Tempo gewährt!",
        HASTE_30_MSG = "hat der Gruppe +30% Tempo gewährt!",
        EXPIRED_MSG = "Der Effekt ist beendet. Er wird in 10 Minuten wieder verfügbar sein!",
        NOTIFY_TOGGLE = "Die Benachrichtigung über das Ablaufen von Heldenhaft ist",
        ANNOUNCE_MODE = "Ankündigungsmodus:",
        HELP_COMMANDS = "Verfügbare Befehle",
        ABILITY_USED = "aktiviert:",
        SPELL_CAST = "gezaubert:",
        LOAD_COMPLETE = "Heldenhaft-Addon geladen",
        ENABLED = "AKTIVIERT",
        DISABLED = "DEAKTIVIERT",
        SELF_MODE = "SELBST",
        SOURCE = "Quelle",
        PET_ABILITY = "Heldenhaft durch Begleiter ausgelöst",
        RAID_WARNING_MODE = "SCHLACHTZUGSWARNUNG",
        TEST_MESSAGE = "Das Addon funktioniert korrekt!",
    }
}

-- Localization Handling
local clientLocale = GetLocale()
local lang = translations[clientLocale] or translations["enUS"]

-- Saved Variables
HeroismConfig = HeroismConfig or { active = false, mode = "SELF", notifyExpiration = true }

-- Utility Functions
local function outputMessage(msg)
    if not HeroismConfig.active then return end -- Only display messages when "ENABLED"
    local channel = HeroismConfig.mode
    if channel == "SELF" then
        print(msg)
    elseif channel == "TEST" then
        print("[Test Mode] " .. msg)
    else
        if IsInRaid(LE_PARTY_CATEGORY_HOME) then
            channel = "RAID"
        elseif IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
            channel = "INSTANCE_CHAT"
        elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
            channel = "PARTY"
        end
        SendChatMessage(msg, channel)
    end
end

-- Command Processing
local function processCommand(cmd)
    cmd = string.upper(cmd)
    if cmd == "ON" or cmd == "OFF" then
        HeroismConfig.active = (cmd == "ON")
        if HeroismConfig.active then
            addonFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        else
            addonFrame:UnregisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
        print(lang.ACTIVE .. " |cff00ff00" .. (HeroismConfig.active and lang.ENABLED or lang.DISABLED) .. "|r.")

    elseif cmd == "SELF" or cmd == "GROUP" or cmd == "SAY" or cmd == "YELL" then
        HeroismConfig.mode = cmd
        print(lang.MODE_SET_TO .. " |cffffd700" .. HeroismConfig.mode .. "|r.")

    elseif cmd == "RAIDWARNING" then
        HeroismConfig.mode = "RAID WARNING"
        print(lang.MODE_SET_TO .. " |cffffd700" .. lang.RAID_WARNING_MODE .. "|r.")

    elseif cmd == "TEST" then
        outputMessage("[Test] {rt1} " .. lang.TEST_MESSAGE)

    elseif cmd == "TOGGLE" then
        HeroismConfig.notifyExpiration = not HeroismConfig.notifyExpiration
        print(lang.NOTIFY_TOGGLE .. " " .. (HeroismConfig.notifyExpiration and lang.ENABLED or lang.DISABLED) .. ".")

    else
        print(lang.STATUS_INFO .. " |cff00ff00" .. (HeroismConfig.active and lang.ENABLED or lang.DISABLED) .. "|r, " .. lang.ANNOUNCE_MODE .. " |cff00ff00" .. HeroismConfig.mode .. "|r.")
        print(lang.HELP_COMMANDS .. ": /hero on, off, self, group, say, yell, raidwarning, test, toggle")
    end
end

SlashCmdList["HEROISM"] = processCommand
SLASH_HEROISM1 = "/hero"

-- Haste Triggers
local hasteItems = { [381301] = true, [444257] = true }
local heroismSpells = { [2825] = true, [32182] = true, [264667] = true, [292686] = true, [80353] = true, [390386] = true }

local activeCooldowns = {}
local expiredCooldowns = {}

-- Cooldown Handler
local function beginCooldown(spellID, spellName)
    if activeCooldowns[spellID] or not HeroismConfig.notifyExpiration then return end
    activeCooldowns[spellID] = true
    C_Timer.After(600, function()
        activeCooldowns[spellID] = nil
        outputMessage("{rt1} Heroism: " .. spellName .. " " .. lang.READY_MESSAGE .. " {rt1}")
    end)
end

-- Pet Owner Resolver
local function resolvePetOwner(petGUID)
    local groupType = IsInRaid() and "raid" or "party"
    for i = 1, GetNumGroupMembers() do
        local unit = groupType .. i
        if UnitGUID(unit .. "pet") == petGUID then
            return UnitName(unit .. "pet"), UnitName(unit)
        end
    end
    return nil, nil
end

-- Event Handling
addonFrame:SetScript("OnEvent", function(_, event, ...)
    if event == "PLAYER_LOGIN" then
        if HeroismConfig.active then
            addonFrame:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
        end
        print(lang.LOAD_COMPLETE .. ". " .. lang.STATUS_INFO .. " " .. (HeroismConfig.active and lang.ENABLED or lang.DISABLED) .. ". " .. lang.ANNOUNCE_MODE .. " " .. HeroismConfig.mode)

    elseif event == "PLAYER_ENTERING_WORLD" then
        activeCooldowns = {}
        expiredCooldowns = {}

    elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
        local _, logType, _, sourceGUID, sourceName, _, _, _, _, _, _, spellID = CombatLogGetCurrentEventInfo()
        local groupSize = GetNumGroupMembers()

        local spellLink = C_Spell.GetSpellLink(spellID)
        local isGroupMember = groupSize > 0 and UnitInParty(sourceName)
        local isSolo = groupSize == 0 and UnitName("player") == sourceName

        if logType == "SPELL_CAST_SUCCESS" then
            if hasteItems[spellID] and (isGroupMember or isSolo) then
                outputMessage("{rt6} Heroism: [" .. UnitClass(sourceName) .. "] " .. sourceName .. " " .. lang.ABILITY_USED .. " " .. spellLink .. " " .. lang.HASTE_15_MSG .. " {rt6}")
                beginCooldown(spellID, spellLink)

            elseif heroismSpells[spellID] and (isGroupMember or isSolo) then
                outputMessage("{rt7} Heroism: [" .. UnitClass(sourceName) .. "] " .. sourceName .. " " .. lang.SPELL_CAST .. " " .. spellLink .. " " .. lang.HASTE_30_MSG .. " {rt7}")
                beginCooldown(spellID, spellLink)
            end

            if heroismSpells[spellID] and string.match(sourceGUID, "Pet") then
                local petName, ownerName = resolvePetOwner(sourceGUID)
                if petName and ownerName then
                    outputMessage("{rt7} " .. lang.PET_ABILITY .. ": [" .. petName .. "] " .. lang.SOURCE .. " " .. ownerName .. " " .. lang.SPELL_CAST .. " " .. spellLink .. " " .. lang.HASTE_30_MSG .. " {rt7}")
                    beginCooldown(spellID, spellLink)
                end
            end

        elseif logType == "SPELL_AURA_REMOVED" then
            if heroismSpells[spellID] and HeroismConfig.notifyExpiration and not expiredCooldowns[spellID] then
                expiredCooldowns[spellID] = true
                outputMessage("{rt8} Heroism: " .. spellLink .. " " .. lang.EXPIRED_MSG .. " {rt8}")
                C_Timer.After(600, function()
                    expiredCooldowns[spellID] = nil
                end)
            end
        end
    end
end)