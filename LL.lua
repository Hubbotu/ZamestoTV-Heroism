local addonName, addon = ...
local L = {}

-- Nested localization table for easy expansion to other languages
local localizations = {
    enUS = {
        ["Turn On"] = "Turn On",
        ["Turn Off"] = "Turn Off",
        ["Yell"] = "Yell",			
        ["Group"] = "Group",
        ["Say"] = "Say",
        ["Self"] = "Self",
        ["Raid warning"] = "Raid warning",			
        ["Test"] = "Test"		
    },
    ruRU = {
        ["Turn On"] = "Включить",
        ["Turn Off"] = "Выключить",
        ["Yell"] = "Крик",			
        ["Group"] = "Группа",
        ["Say"] = "Сказать",
        ["Self"] = "Себе",
        ["Raid warning"] = "Объявление рейда",		
        ["Test"] = "Тест"	
    },
    deDE = {
        ["Turn On"] = "Einschalten",
        ["Turn Off"] = "Ausschalten",
        ["Yell"] = "Schreien",			
        ["Group"] = "Gruppe",
        ["Say"] = "Sagen",
        ["Self"] = "Selbst",
        ["Raid warning"] = "Schlachtzugswarnung",		
        ["Test"] = "Testen"	
    }
}

-- Function to get localizations based on current locale
local function L(key)
    local locale = GetLocale()
    return localizations[locale] and localizations[locale][key] or localizations["enUS"][key]
end

-- Create the options panel using the new Settings API
local panel = CreateFrame("Frame", nil, UIParent)
panel.name = "Zamesto TV: Heroism"
panel.buttons = {}

local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
title:SetPoint("TOP", 0, -16)
title:SetText("Zamesto TV: Heroism")

-- Function to create buttons
local function CreateButton(textKey, descEn, descRu, descDe, command, yOffset)
    local button = CreateFrame("Button", nil, panel, "UIPanelButtonTemplate")
    button:SetText(L(textKey))
    button:SetSize(120, 25)
    button:SetPoint("TOPLEFT", 20, yOffset)

    button:SetScript("OnClick", function()
        if ChatFrame1EditBox then
            ChatFrame1EditBox:SetText(command)
            ChatEdit_SendText(ChatFrame1EditBox)
        else
            print("Error: ChatFrame1EditBox not available.")
        end
    end)

    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        local locale = GetLocale()
        if locale == "ruRU" then
            GameTooltip:SetText(descRu)
        elseif locale == "deDE" then
            GameTooltip:SetText(descDe)
        else
            GameTooltip:SetText(descEn)
        end
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)

    table.insert(panel.buttons, button)
end

-- Add buttons to the panel
addon.category = Settings.RegisterCanvasLayoutCategory(panel, panel.name)
Settings.RegisterAddOnCategory(addon.category)
local buttonOffset = -50
CreateButton("Turn On", "Turn on feature.", "Включить функцию.", "Funktion einschalten.", "/hero on", buttonOffset)
CreateButton("Turn Off", "Turn off feature.", "Выключить функцию.", "Funktion ausschalten.", "/hero off", buttonOffset - 30)
CreateButton("Yell", "Send message to yell.", "Отправить сообщение в крик.", "Nachricht ins Schreien senden.", "/hero yell", buttonOffset - 60)
CreateButton("Group", "Send message to group.", "Отправить сообщение в группу.", "Nachricht an die Gruppe senden.", "/hero group", buttonOffset - 90)
CreateButton("Say", "Send message to nearby players.", "Отправить сообщение ближайшим игрокам.", "Nachricht an nahe Spieler senden.", "/hero say", buttonOffset - 120)
CreateButton("Self", "Send message to yourself.", "Отправить сообщение самому себе.", "Nachricht an dich selbst senden.", "/hero self", buttonOffset - 150)
CreateButton("Raid warning", "Send message to Raid warning.", "Отправить сообщение в объявление рейда.", "Nachricht an die Schlachtzugswarnung senden.", "/hero rw", buttonOffset - 180)
CreateButton("Test", "Test command.", "Тестовая команда.", "Testbefehl.", "/hero test", buttonOffset - 210)