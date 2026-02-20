-- Classless Spellbook Extra Tabs v3.0 – functional beyond 8 tabs
ClasslessSpellbookTabs = {}
ClasslessSpellbookTabs.version = "3.0"
ClasslessSpellbookTabs.hooked = false
ClasslessSpellbookTabs.extraFrames = {}

-- Configuration
local MAX_DEFAULT_TABS = 8
local MAX_EXTRA_TABS = 30
local EXTRA_COLUMN_X_OFFSET = 40
local EXTRA_COLUMN_Y_OFFSET = -80
local TAB_Y_GAP = -18
local ICON_SIZE = 36
local ICON_PADDING = 6
local ICONS_PER_ROW = 8

-- Hide all extra content frames
local function HideAllExtraFrames()
    for _, f in pairs(ClasslessSpellbookTabs.extraFrames) do
        f:Hide()
    end
end

-- Tab tooltips
local function Tab_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetText(self.tooltip, 1,1,1)
    GameTooltip:Show()
end
local function Tab_OnLeave(self)
    GameTooltip:Hide()
end

-- Spell tooltips
local function Spell_OnEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
    GameTooltip:SetSpellByID(self.spellID)
end
local function Spell_OnLeave(self)
    GameTooltip:Hide()
end

-- Populate extra tab content with actual spells
local function PopulateExtraTabContent(frame, tabIndex)
    frame:Hide()
    frame:EnableMouse(true)
    if frame.created then return end
    frame.created = true

    local scrollFrame = CreateFrame("ScrollFrame", nil, frame, "UIPanelScrollFrameTemplate")
    scrollFrame:SetAllPoints()
    frame.scrollFrame = scrollFrame

    local content = CreateFrame("Frame", nil, scrollFrame)
    content:SetSize(frame:GetWidth(), frame:GetHeight())
    scrollFrame:SetScrollChild(content)

    local _, numSpells, offset = GetSpellTabInfo(tabIndex)
    offset = offset or 0
    numSpells = numSpells or 0

    for i = 1, numSpells do
        local spellName, _, spellID = GetSpellBookItemName(i + offset - 1, "spell")
        if spellName then
            local btn = CreateFrame("Button", nil, content)
            btn:SetSize(ICON_SIZE, ICON_SIZE)

            local row = math.floor((i-1)/ICONS_PER_ROW)
            local col = (i-1) % ICONS_PER_ROW
            btn:SetPoint("TOPLEFT", col*(ICON_SIZE + ICON_PADDING), -row*(ICON_SIZE + ICON_PADDING))

            local texture = GetSpellBookItemTexture(i + offset - 1, "spell")
            btn.texture = btn:CreateTexture(nil, "BACKGROUND")
            btn.texture:SetAllPoints()
            btn.texture:SetTexture(texture)

            btn.spellID = spellID
            btn:SetScript("OnEnter", Spell_OnEnter)
            btn:SetScript("OnLeave", Spell_OnLeave)
            btn:SetScript("OnClick", function()
                CastSpellByID(spellID)
            end)
        end
    end
end

-- Main tab update function
local function Classless_UpdateTabs()
    if not SpellBookFrame:IsShown() then return end

    local numSkillLines = GetNumSpellTabs()
    local selected = SpellBookFrame.selectedSkillLine or 1

    -- Hide all extra tabs first
    for i = MAX_DEFAULT_TABS + 1, MAX_EXTRA_TABS do
        local tab = _G["SpellBookSkillLineTab" .. i]
        if tab then tab:Hide() end
        if ClasslessSpellbookTabs.extraFrames[i] then
            ClasslessSpellbookTabs.extraFrames[i]:Hide()
        end
    end

    -- Create/show extra tabs
    if numSkillLines > MAX_DEFAULT_TABS then
        for i = MAX_DEFAULT_TABS + 1, numSkillLines do
            local tab = _G["SpellBookSkillLineTab" .. i]
            if not tab then
                tab = CreateFrame("CheckButton", "SpellBookSkillLineTab" .. i, SpellBookFrame, "SpellBookSkillLineTabTemplate")
                tab:SetID(i)
                tab:SetFrameLevel(10)
                tab:SetScript("OnEnter", Tab_OnEnter)
                tab:SetScript("OnLeave", Tab_OnLeave)
            end

            local name, texture = GetSpellTabInfo(i)
            if texture and name then
                tab:SetNormalTexture(texture)
                tab.tooltip = name
                tab:SetChecked(i == selected)

                -- Extra content frame
                local frame = ClasslessSpellbookTabs.extraFrames[i]
                if not frame then
                    frame = CreateFrame("Frame", "SpellBookExtraTabContent"..i, SpellBookFrame)
                    frame:SetSize(SpellBookFrame:GetWidth() - 40, SpellBookFrame:GetHeight() - 80)
                    frame:SetPoint("TOPLEFT", SpellBookFrame, "TOPLEFT", 20, -60)
                    frame:Hide()
                    ClasslessSpellbookTabs.extraFrames[i] = frame
                end

                -- OnClick shows our custom frame instead of Blizzard page
                tab:SetScript("OnClick", function(self)
                    HideAllExtraFrames()
                    frame:Show()
                    PopulateExtraTabContent(frame, i)

                    -- Highlight
                    for j = MAX_DEFAULT_TABS + 1, numSkillLines do
                        local t = _G["SpellBookSkillLineTab" .. j]
                        if t then t:SetChecked(t == self) end
                    end
                end)

                -- Anchor extra tabs
                tab:ClearAllPoints()
                if i == MAX_DEFAULT_TABS + 1 then
                    tab:SetPoint("TOPRIGHT", SpellBookFrame, "TOPRIGHT", EXTRA_COLUMN_X_OFFSET, EXTRA_COLUMN_Y_OFFSET)
                else
                    local prevTab = _G["SpellBookSkillLineTab" .. (i - 1)]
                    if prevTab then
                        tab:SetPoint("TOPLEFT", prevTab, "BOTTOMLEFT", 0, TAB_Y_GAP)
                    end
                end

                tab:Show()
            end
        end
    end
end

-- Hook SpellBookFrame_Update
local function InitHook()
    if ClasslessSpellbookTabs.hooked then return end
    if SpellBookFrame_Update then
        hooksecurefunc("SpellBookFrame_Update", Classless_UpdateTabs)
        ClasslessSpellbookTabs.hooked = true
        C_Timer.After(0.1, Classless_UpdateTabs)
        print("|cff00ff00[Classless Tabs]|r Hooked successfully (v3.0)")
    else
        print("|cffff0000[Classless Tabs]|r ERROR: SpellBookFrame_Update missing!")
    end
end

-- PLAYER_LOGIN
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        InitHook()
    end
end)
