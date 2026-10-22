local P = pfQuestPartyBots
local installed = false
-- Mirror pfQuest's title-keyed expansion default without changing its source.
-- Objective visibility alone is insufficient: pfQuest auto-shows partial progress.
local expanded, partyExpanded = {}, {}
local function Expanded(button)
  if expanded[button.title] == nil then
    expanded[button.title] = pfQuest_config["trackerexpand"] == "1"
  end
  return expanded[button.title]
end
local function Font() return (pfUI and pfUI.font_default) or STANDARD_TEXT_FONT or "Fonts\\FRIZQT__.TTF" end

function P.ObjectiveLabel(objective)
  local db = pfDB or {}
  local entry = math.abs(objective.entry)
  if objective.kind == "I" then
    local name = GetItemInfo and GetItemInfo(entry)
    return name or (db.items and db.items.loc and db.items.loc[entry]) or ("Item " .. entry)
  elseif objective.kind == "K" then
    return (db.units and db.units.loc and db.units.loc[entry]) or ("Creature " .. entry)
  elseif objective.kind == "G" then
    return (db.objects and db.objects.loc and db.objects.loc[entry]) or ("Object " .. entry)
  elseif objective.kind == "E" then return "Event / exploration"
  else return "Money (copper)" end
end

function P.AddTooltip(id)
  GameTooltip:AddLine(" ")
  GameTooltip:AddLine("Party quest progress", 0.2, 1, 0.7)
  for _, member in ipairs(P.roster) do
    local label, record, stale = P.Status(member.name, id)
    local state = record and P.labels[record.state] or label
    GameTooltip:AddLine(member.name .. ": " .. state .. (stale and " (stale / unavailable)" or ""), 1, 1, 1)
    if P.errors[member.name] then GameTooltip:AddLine("  " .. P.errors[member.name], 0.8, 0.7, 0.4) end
    if record then
      for _, objective in ipairs(record.objectives) do
        GameTooltip:AddLine("  " .. P.ObjectiveLabel(objective) .. ": " .. objective.current .. "/" .. objective.required, 0.8, 0.8, 0.8)
      end
    end
    local snapshot = P.snapshots[member.name]
    if snapshot and snapshot.received then
      GameTooltip:AddLine("  Updated " .. date("%H:%M:%S", snapshot.received), 0.55, 0.55, 0.55)
    end
  end
  GameTooltip:AddLine("Not in log does not establish a turn-in. * marks stale data.", 0.7, 0.7, 0.7, true)
  GameTooltip:Show()
end

function P.ShowQuestTooltip(row)
  GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
  GameTooltip:SetText(row.questTitle .. " (" .. row.questId .. ")")
  -- Bot-only quests have no native quest-log entry to provide this text.
  -- Reuse pfQuest's localized instructions for the exact quest ID/stage.
  local quest = pfDB and pfDB.quests and pfDB.quests.loc and pfDB.quests.loc[row.questId]
  local text = quest and quest.O
  if type(text) == "string" and text ~= "" then
    if pfDatabase and type(pfDatabase.FormatQuestText) == "function" then
      text = pfDatabase:FormatQuestText(text)
    else
      text = string.gsub(text, "%$[Bb]", "\n")
    end
    GameTooltip:AddLine(text, 1, 1, 0.9, true)
  else
    GameTooltip:AddLine("Quest instructions unavailable in pfQuest.", 0.7, 0.7, 0.7, true)
  end
  P.AddTooltip(row.questId)
end

local function Short(name, id)
  local label, record, stale = P.Status(name, id)
  local color = stale and "|cffaaaaaa" or (record and record.state == "C" and "|cff66ff66" or
    record and record.state == "F" and "|cffff7777" or "|cffe0d090")
  return color .. name .. ": " .. label .. (stale and "*" or "") .. "|r"
end

function P.CompactLines(id)
  local lines, line = {}, ""
  for index, member in ipairs(P.roster) do
    -- Keep raid tracking compact; the Party panel and tooltip contain the full roster.
    if index > 4 then break end
    line = line .. (line == "" and "" or "   ") .. Short(member.name, id)
    if math.mod(index, 2) == 0 then table.insert(lines, line); line = "" end
  end
  if line ~= "" then table.insert(lines, line) end
  return lines
end

local function Append(button)
  button.partyBotLines = button.partyBotLines or {}
  for _, line in ipairs(button.partyBotLines) do line:Hide() end
  local tracker = pfQuest and pfQuest.tracker
  if not tracker or tracker.mode ~= "QUEST_TRACKING" or button.empty or not button.title or button:GetHeight() == 0 then return end
  local id = P.QuestId(button.questid, pfQuest.questlog and pfQuest.questlog[button.questid])
  if not id or not Expanded(button) then return end
  local base, size = button:GetHeight(), math.max(9, (tonumber(pfQuest_config.trackerfontsize) or 12) - 2)
  local lines = P.CompactLines(id)
  for index, text in ipairs(lines) do
    local line = button.partyBotLines[index]
    if not line then line = button:CreateFontString(nil, "OVERLAY", "GameFontNormal"); button.partyBotLines[index] = line end
    line:SetFont(Font(), size)
    line:SetJustifyH("LEFT")
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", button, "TOPLEFT", 20, -base - (index - 1) * (size + 3))
    line:SetPoint("TOPRIGHT", button, "TOPRIGHT", -6, -base - (index - 1) * (size + 3))
    line:SetText(text)
    line:Show()
  end
  button:SetHeight(base + table.getn(lines) * (size + 3) + (table.getn(lines) > 0 and 2 or 0))
end

local footer, nativeHeight
local partyPage, pageSize = 1, 6

-- pfQuest can filter personal quests by zone/watch state. Include everything
-- absent from its visible rows, not just quests absent from the player's log.
function P.OtherTrackerQuests()
  local visible, quests = {}, {}
  for _, button in pairs(pfQuest.tracker.buttons) do
    if not button.empty and button.title and button:GetHeight() > 0 then
      local id = P.QuestId(button.questid, pfQuest.questlog and pfQuest.questlog[button.questid])
      if id then visible[id] = true end
    end
  end
  for _, quest in ipairs(P.ActiveQuests()) do
    if not visible[quest.id] then table.insert(quests, quest) end
  end
  return quests
end

local function UpdateFooter()
  local tracker = pfQuest and pfQuest.tracker
  if not footer or not P.ActiveQuests then return end
  footer:Hide()
  if tracker.mode ~= "QUEST_TRACKING" or table.getn(P.roster) == 0 then
    if nativeHeight then tracker:SetHeight(nativeHeight) end
    return
  end
  footer:Show()
  footer.rows = footer.rows or {}
  for _, row in ipairs(footer.rows) do row:Hide() end
  local playerIds = {}
  for _, id in ipairs(P.PlayerQuestIds()) do playerIds[id] = true end
  local quests = P.OtherTrackerQuests()
  local count = table.getn(quests)
  local pages = math.max(1, math.ceil(count / pageSize))
  partyPage = math.max(1, math.min(partyPage, pages))
  local first = (partyPage - 1) * pageSize + 1
  footer.earlier:Hide(); footer.later:Hide(); footer.info:Hide()
  local shown, offset = 0, 27
  if count > 0 then
    footer.info:SetText("Other party quests: " .. first .. "-" .. math.min(count, first + pageSize - 1) .. " of " .. count)
    footer.info:Show()
    offset = 45
    if partyPage > 1 then footer.earlier:Show() end
    if partyPage < pages then footer.later:Show() end
  end
  for index = first, math.min(count, first + pageSize - 1) do
    local quest = quests[index]
    shown = shown + 1
    local row = footer.rows[shown]
    if not row then
      row = CreateFrame("Button", nil, footer)
      row.title = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      row.title:SetFont(Font(), 11); row.title:SetJustifyH("LEFT")
      row.title:SetPoint("TOPLEFT", row, "TOPLEFT", 2, 0)
      row.title:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, 0)
      row.progress = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
      row.progress:SetFont(Font(), 10); row.progress:SetJustifyH("LEFT")
      row.progress:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -16)
      row.progress:SetPoint("TOPRIGHT", row, "TOPRIGHT", -2, -16)
      row:SetScript("OnEnter", function() P.ShowQuestTooltip(this) end)
      row:SetScript("OnLeave", function() GameTooltip:Hide() end)
      row:SetScript("OnClick", function()
        partyExpanded[this.questId] = not partyExpanded[this.questId]
        UpdateFooter()
      end)
      footer.rows[shown] = row
    end
    row.questId, row.questTitle = quest.id, quest.title
    row:ClearAllPoints(); row:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, -offset)
    row:SetWidth(300)
    row.title:SetText((playerIds[quest.id] and "[You] " or "[Party] ") .. "[" .. quest.level .. "] " .. quest.title)
    row.progress:Hide()
    row:SetHeight(20)
    if partyExpanded[quest.id] then
      local lines = P.CompactLines(quest.id)
      row.progress:SetText(table.concat(lines, "\n"))
      row.progress:Show()
      row:SetHeight(18 + table.getn(lines) * 13)
    end
    row:Show(); offset = offset + row:GetHeight() + 2
  end
  footer:SetHeight(offset)
  footer:ClearAllPoints()
  footer:SetPoint("TOPLEFT", tracker, "TOPLEFT", 0, -(nativeHeight or tracker:GetHeight()) - 3)
  tracker:SetWidth(math.max(tracker:GetWidth(), 300))
  if nativeHeight then tracker:SetHeight(nativeHeight + 3 + offset) end
end

function P.RefreshTracker()
  if not installed then return end
  local tracker = pfQuest.tracker
  for _, button in pairs(tracker.buttons) do tracker.ButtonEvent(button) end
  tracker.DoLayout()
end

local function Install()
  if installed or not pfQuest or not pfQuest.tracker then return end
  local tracker = pfQuest.tracker
  if type(tracker.ButtonEvent) ~= "function" or type(tracker.ButtonEnter) ~= "function" or type(tracker.ButtonClick) ~= "function" or type(tracker.DoLayout) ~= "function" then
    if DEFAULT_CHAT_FRAME then DEFAULT_CHAT_FRAME:AddMessage("pfQuest Party Bots: this pfQuest tracker version is unsupported. Use /pfqb for the comparison.") end
    return
  end
  installed = true
  local oldEvent, oldEnter, oldClick, oldLayout = tracker.ButtonEvent, tracker.ButtonEnter, tracker.ButtonClick, tracker.DoLayout
  tracker.ButtonEvent = function(button)
    local target = button or this
    oldEvent(button)
    Append(target)
  end
  tracker.ButtonClick = function()
    local target = this
    local toggle = tracker.mode == "QUEST_TRACKING" and target and target.title and
      arg1 ~= "RightButton" and not IsShiftKeyDown() and not IsControlKeyDown()
    if toggle then expanded[target.title] = not Expanded(target) end
    oldClick()
    if toggle then tracker.DoLayout() end
  end
  tracker.ButtonEnter = function()
    oldEnter()
    if tracker.mode == "QUEST_TRACKING" and this.questid then
      P.AddTooltip(P.QuestId(this.questid, pfQuest.questlog and pfQuest.questlog[this.questid]))
    end
  end
  tracker.DoLayout = function()
    oldLayout()
    nativeHeight = tracker:GetHeight()
    if tracker.mode == "QUEST_TRACKING" then
      for _, quest in pairs(tracker.buttons) do
        for _, line in ipairs(quest.partyBotLines or {}) do
          if line:IsShown() then tracker:SetWidth(math.max(tracker:GetWidth(), 300)) end
        end
      end
    end
    UpdateFooter()
  end
  for _, button in pairs(tracker.buttons) do
    button:SetScript("OnEvent", tracker.ButtonEvent); button:SetScript("OnEnter", tracker.ButtonEnter)
    button:SetScript("OnClick", tracker.ButtonClick)
  end
  footer = CreateFrame("Frame", "pfQuestPartyBotsFooter", tracker)
  footer:SetPoint("TOPLEFT", tracker, "BOTTOMLEFT", 0, -3); footer:SetWidth(300); footer:SetHeight(27)
  local button = CreateFrame("Button", "pfQuestPartyBotsTrackerButton", footer, "UIPanelButtonTemplate")
  button:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, 0); button:SetWidth(120); button:SetHeight(22)
  button:SetText("Party quests")
  button:SetScript("OnClick", function() if P.TogglePanel then P.TogglePanel() end end)
  footer.info = footer:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  footer.info:SetFont(Font(), 10); footer.info:SetJustifyH("LEFT")
  footer.info:SetPoint("TOPLEFT", footer, "TOPLEFT", 2, -28)
  footer.earlier = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  footer.earlier:SetPoint("TOPLEFT", footer, "TOPLEFT", 126, 0)
  footer.earlier:SetWidth(82); footer.earlier:SetHeight(22); footer.earlier:SetText("Earlier")
  footer.earlier:SetScript("OnClick", function() partyPage = partyPage - 1; UpdateFooter() end)
  footer.later = CreateFrame("Button", nil, footer, "UIPanelButtonTemplate")
  footer.later:SetPoint("TOPLEFT", footer, "TOPLEFT", 212, 0)
  footer.later:SetWidth(82); footer.later:SetHeight(22); footer.later:SetText("Later")
  footer.later:SetScript("OnClick", function() partyPage = partyPage + 1; UpdateFooter() end)
  table.insert(P.listeners, P.RefreshTracker)
  P.RefreshTracker()
end
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", Install)
