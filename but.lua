local addonName, addon = ...
-- Localization table
local L = {
    ["enUS"] = {
        ["addonName"] = "Zamesto TV: Hero",
        ["tooltipText"] = "Click to open options",
    },
    ["ruRU"] = {
        ["addonName"] = "Zamesto TV: Героизм",
        ["tooltipText"] = "Нажмите, чтобы открыть настройки",
    },
    ["deDE"] = {
        ["addonName"] = "Zamesto TV: Heldentum",
        ["tooltipText"] = "Klicken, um die Optionen zu öffnen",
    },
}

-- Main Addon SavedVariable Table
TestAddonSettingsData = TestAddonSettingsData or {}

-- Minimap Icon SavedVariable Table
TestAddonSettingsData_MinimapIcon = TestAddonSettingsData_MinimapIcon or {}

-- Initialise Minimap Icon values
-- Use settings panel to allow player to change these
-- When you move the minimap icon around the minimap the ldb library updates the respective MinimapIcon saved variable table
-- The MinimapIcon Saved Variable Data has to be its own table, not a sub table
TestAddonSettingsData_MinimapIcon.hide = false
TestAddonSettingsData_MinimapIcon.lock = false
TestAddonSettingsData_MinimapIcon.minimapPos = 120
TestAddonSettingsData_MinimapIcon.radius = 80

-- Make sure library exists
local ldb = LibStub:GetLibrary("LibDataBroker-1.1", true)
if not ldb then return end

-- Create Plugin
local plugin = ldb:NewDataObject(L[GetLocale()].addonName, {
    type = "data source",
    text = L[GetLocale()].addonName,
    icon = "Interface\\AddOns\\ZamestoTV_Heroism\\Icons\\hero", -- Replace with path to your icon
})

-- Handle OnClick functionality
function plugin.OnClick(self, button)
    if button == "LeftButton" then
        Settings.OpenToCategory(addon.category:GetID()) -- Open or close the options panel
    end
end

-- Handle OnTooltipShow functionality
function plugin.OnTooltipShow(tooltip)
    tooltip:SetText(L[GetLocale()].addonName)
    tooltip:AddLine(L[GetLocale()].tooltipText)
    tooltip:Show()
end

-- Initialise Minimap Icon on Player Login
local f = CreateFrame("Frame")
f:SetScript("OnEvent", function()
    local icon = LibStub("LibDBIcon-1.0", true)
    if not icon then return end
    icon:Register(L[GetLocale()].addonName, plugin, TestAddonSettingsData_MinimapIcon)
end)
f:RegisterEvent("PLAYER_LOGIN")