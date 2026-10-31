---@class BetterBags: AceAddon
local BetterBags = LibStub('AceAddon-3.0'):GetAddon("BetterBags")

-- BetterBags Next's themes (BetterBags 0.8 and later). An older BetterBags has no SonataNext: only the classic theme.
---@class SonataNext: AceModule
local sonataNext = BetterBags:GetModule('SonataNext', true)
if sonataNext == nil then return end

-- The classic bag, drawn on BetterBags Next's panels: the same art as the classic bags' theme (theme.lua), cut into the
-- pieces Next draws (source/next_pieces.py writes images/next): the header (the portrait in its gold ring, the title bar,
-- the close button's plate) across the body's top, the side borders down its sides, the money bar along its bottom and
-- the stone between them. Next draws a theme for the backpack, whose inner side (away from its screen edge) is on the
-- left; the bank, the vendor and the guild bank show it mirrored. Everything else (the settings window, the controls, the
-- menus, the dialogs) is BetterBags' Plain theme: the game's own look, as the classic theme keeps BetterBags' Blizzard
-- look for its other windows. Every number is a pixel of the art, as in theme.lua.
local IMAGES = "Interface\\AddOns\\BetterBags_WoWClassic_Theme\\images\\"
local NEXT = IMAGES .. "next\\"

-- The header is 44 tall from 4 above the body's top (its gold ring reaches above the window) to 40 below it; the money bar
-- is 33 tall along the bottom (the art's 23 and the 10 theme.lua adds, so the money fits in it); the borders are 3 wide on
-- each side, as the header and the money bar end.
local HEADER, HEADER_ABOVE = 44, 4
local HEADER_BOTTOM = HEADER - HEADER_ABOVE
-- The header's stone fades out over its last 14 rows (source/seams.py), so the fill starts under them and the two
-- grains blend rather than meet in a line (seen in game).
local FILL_UNDER_HEADER = 14
local FOOTER = 33
local INNER_EDGE, OUTER_EDGE = 3, 3
-- The ring hangs 7 past the inner border (art x 67 against 74), the plate's 29 are the header's last.
local RING_OUT, LEFT_CAP, RIGHT_CAP = 7, 47, 29
local FOOTER_LEFT, FOOTER_RIGHT = 22, 51

local ORNAMENTS = {
  -- The side borders, between the header and the money bar: 16 rows of the art repeating.
  { Point = "INNER", Texture = NEXT .. "edge_left.png", TexCoords = { 0, INNER_EDGE / 8, 0, 1 }, Tile = 16,
    Width = INNER_EDGE, Start = HEADER_BOTTOM, End = FOOTER, Color = "White" },
  { Point = "OUTER", Texture = NEXT .. "edge_right.png", TexCoords = { 0, OUTER_EDGE / 8, 0, 1 }, Tile = 16,
    Width = OUTER_EDGE, Start = HEADER_BOTTOM, End = FOOTER, Color = "White" },
  -- The header: its middle (the title bar) repeating between its two ends.
  { Point = "TOP", Texture = NEXT .. "header_middle.png", TexCoords = { 0, 1, 0, HEADER / 64 }, Tile = 256,
    Height = HEADER, Y = -HEADER_ABOVE, Start = LEFT_CAP - RING_OUT, End = RIGHT_CAP, Color = "White" },
  { Point = "TOPINNER", Texture = NEXT .. "header_left.png", TexCoords = { 0, LEFT_CAP / 64, 0, HEADER / 64 },
    Width = LEFT_CAP, Height = HEADER, X = -RING_OUT, Y = -HEADER_ABOVE, Color = "White", SubLevel = 1 },
  { Point = "TOPOUTER", Texture = NEXT .. "header_right.png", TexCoords = { 0, RIGHT_CAP / 32, 0, HEADER / 64 },
    Width = RIGHT_CAP, Height = HEADER, Y = -HEADER_ABOVE, Color = "White", SubLevel = 1 },
  -- The money bar: its middle repeating between its gold caps.
  { Point = "BOTTOM", Texture = NEXT .. "footer_middle.png", TexCoords = { 0, 1, 0, FOOTER / 64 }, Tile = 256,
    Height = FOOTER, Start = FOOTER_LEFT, End = FOOTER_RIGHT, Color = "White" },
  { Point = "BOTTOMINNER", Texture = NEXT .. "footer_left.png", TexCoords = { 0, FOOTER_LEFT / 32, 0, FOOTER / 64 },
    Width = FOOTER_LEFT, Height = FOOTER, Color = "White", SubLevel = 1 },
  { Point = "BOTTOMOUTER", Texture = NEXT .. "footer_right.png", TexCoords = { 0, FOOTER_RIGHT / 64, 0, FOOTER / 64 },
    Width = FOOTER_RIGHT, Height = FOOTER, Color = "White", SubLevel = 1 },
}

-- The classic close button, 32 square, over the plate: its art centered on Plain's 24-square header button, 2 right of
-- the corner and 1 above it (Pinned takes the game's offsets: right and up; seen in game). Atlas = false drops the red
-- button Plain draws on retail.
local CLOSE = {
  Texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Up", Atlas = false, Glyph = false, Scale = 32 / 24,
  Pushed = { Texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Down", Atlas = false },
  Disabled = { Texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled", Atlas = false },
  Highlight = { Texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", Atlas = false, BlendMode = "ADD" },
}

-- Two buttons out of the bag button's menu at the end of the search bar, as the classic theme's (theme.lua), each its art
-- at 28 across centered on a 24-square header button, their middles on the search bar's (SearchTop + SearchHeight / 2):
--   Show Blizzard Bags (the backpack's bagsButton), pinned 8 in from the outer side: the game's backpack button on its
--   bag bar (bag-main, bag-main-highlight added under the pointer; every client has them).
--   Left of it, its art PINS_GAP from the first's, the sort button: the game's own Clean Up Bags button
--   (ContainerFrame.xml, BagItemAutoSortButton: bags-button-autosort-up and -down, 28 x 26, ButtonHilight-Square added
--   under the pointer).
-- The search bar ends 4 before them. Pinned buttons leave the menu; a pin along the top also keeps the title clear of
-- it, so the name would sit left of the middle: the title's room leaves them out (at the end).
local PINS_GAP = 2
local FIRST_X, PINS_Y = -8, -(HEADER_BOTTOM + 2 + 10 - 12)
local SECOND_X = FIRST_X - 24 - 2 - PINS_GAP - 2
local BAGS = {
  Atlas = "bag-main", Glyph = false, Scale = 28 / 24,
  Highlight = { Atlas = "bag-main-highlight", BlendMode = "ADD" },
}
local SORT = {
  Atlas = "bags-button-autosort-up", Glyph = false, Scale = 28 / 24,
  Pushed = { Atlas = "bags-button-autosort-down" },
  Highlight = { Texture = "Interface\\Buttons\\ButtonHilight-Square", BlendMode = "ADD" },
}
local SEARCH_RIGHT = -SECOND_X + 24 + 2 + 4
-- The buttons pinned on the search bar's row, below the title (see the title's room, at the end).
local SEARCH_ROW_PINS = { sortButton = true, bagsButton = true }

-- The bag button (the header's actions in its menu, as Plain keeps them) over the portrait, as the classic theme's menu
-- button covers it (theme.lua: 40 square, 6 out and 2 above the corner): the art's backpack shows through it, the
-- minimap's round highlight over it under the pointer. On the vendor, the vendor's portrait in the ring.
local PORTRAIT = { Left = 3, Right = 3, Top = 3, Bottom = 3 }
local PORTRAIT_MASK = { Texture = "Interface\\CharacterFrame\\TempPortraitAlphaMask" }
local BAG_BUTTON = {
  Point = "TOPINNER", X = -6, Y = -2, Width = 40, Height = 40,
  Layers = { { Color = { 0, 0, 0, 0 } } },
  Highlight = { Texture = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", TexCoords = { 0, 1, 0, 1 },
    BlendMode = "ADD", Inset = { Left = 0, Right = 0, Top = 0, Bottom = 0 } },
  Panels = { Vendor = { Layers = {
    { Color = { 0, 0, 0, 1 }, Inset = PORTRAIT, Mask = PORTRAIT_MASK },
    { Unit = "npc", Inset = PORTRAIT, Mask = PORTRAIT_MASK },
  } } },
}

-- The group tabs, as the classic character sheet's (source/next_tabs.py): its bevelled tabs turned on their side, rounded
-- on their outer side, open toward the bag; darker until chosen, lit gold under the pointer. Next stretches a tab's art
-- over the tab, so every tab is 100 x 30 (Layout) and the art is drawn at twice that (200 x 60 of a 256 x 64 file).
-- Plain lights its tabs with the settings list's art (an Atlas, which would win over this Texture): WoWClassicBase drops it
-- (false removes an inherited table) so the highlight here starts from nothing.
local TAB_ART = { 0, 200 / 256, 0, 60 / 64 }
local TABS = {
  Fill = { Texture = NEXT .. "tab_inactive.png", TexCoords = TAB_ART, Color = "White", Alpha = 1 },
  SelectedFill = { Texture = NEXT .. "tab_active.png", TexCoords = TAB_ART, Color = "White", Alpha = 1 },
  Highlight = { Texture = NEXT .. "tab_highlight.png", TexCoords = TAB_ART, BlendMode = "ADD",
    Color = { 1, 0.82, 0, 1 }, Alpha = 0.15 },
  SelectedHighlight = false,
}

-- Plain without what WoW Classic draws from nothing: its tabs' highlights.
sonataNext:RegisterTheme({
  Name = "WoWClassicBase",
  DisplayName = "WoW Classic",
  Description = "Plain without its tabs' highlights, for the WoW Classic theme.",
  Hidden = true,
  Parent = "Plain",
  Tabs = { Highlight = false, SelectedHighlight = false },
})

sonataNext:RegisterTheme({
  Name = "WoWClassic",
  DisplayName = "WoW Classic",
  Description = "The classic World of Warcraft bags.",
  Parent = "WoWClassicBase",

  -- The bag's name in the title bar, as the classic bag wrote it.
  Fonts = {
    Title = { Copy = "GameFontHighlight", Size = false },
  },

  Layout = {
    -- The name 4 below the window's top (art y 10), the search box under the header, the content under it.
    TitleTop = 4,
    -- The items 10 nearer the borders than Plain's 18, about level with the search box (Search.Inset's 20; seen in game).
    -- Pad is on both sides, and the currencies (and the free slots' text) start Pad and TitleInset in: Plain's 20 keeps
    -- them where they were seen best. The title, after the bag button, uses neither.
    Pad = 8,
    TitleInset = 20,
    SearchTop = HEADER_BOTTOM + 2,
    SearchHeight = 20,
    ContentTop = HEADER_BOTTOM + 26,
    -- The currencies (and the gold, which BetterBags places from the same value) 2 lower in the money bar than Plain's
    -- 12 (seen in game).
    FooterMoney = 10,
    -- The content scrolls down to the money bar's top edge (Default's 40 left a strip of stone above it; seen in game).
    Footer = FOOTER,
    TabHeight = 30,
    TabMinWidth = 100,
    TabMaxWidth = 100,
    -- Classic tabs do not slide out under the pointer (asked); the gold light shows it.
    TabHover = 0,
  },

  -- The stone between the borders, the header and the money bar; no Blizzard frame over it.
  Panel = {
    Fill = { Texture = IMAGES .. "stone.png", HorizTile = true, VertTile = true, Color = "White", Alpha = 1,
      Inset = { Left = INNER_EDGE, Right = OUTER_EDGE, Top = HEADER_BOTTOM - FILL_UNDER_HEADER, Bottom = FOOTER } },
    Frame = false,
    Ornaments = ORNAMENTS,
  },

  Tabs = TABS,

  Search = { Inset = { Right = SEARCH_RIGHT } },

  Header = {
    Buttons = {
      Pinned = {
        closeButton = { Point = "TOPOUTER", X = 2, Y = 1 },
        bagsButton = { Point = "TOPOUTER", X = FIRST_X, Y = PINS_Y },
        sortButton = { Point = "TOPOUTER", X = SECOND_X, Y = PINS_Y },
      },
      Icons = { closeButton = CLOSE, sortButton = SORT, bagsButton = BAGS },
      Menu = BAG_BUTTON,
    },
  },
})

-- The gold, which no theme key reaches (BetterBags Next places and lays it out itself), set right after BetterBags does,
-- while this theme is in use, on whole pixels (seen in game):
--   The gold sits 2 above the currencies in the money bar: BetterBags places both from Layout.FooterMoney (the gold's
--   frame and the currency strip's bottom, next/panel.lua styleFooter and next/currencystrip.lua), and the gold draws
--   higher inside its frame. The frame is moved GOLD_DROP down.
--   Each amount sits against its coin, a little above its middle (next/coins.lua lays them out with fixed numbers). Each
--   is moved GOLD_TEXT_GAP away from its coin and GOLD_TEXT_DROP down, its coin's button made as much wider so the
--   amounts keep their room. BetterBags lays the coins out again on every update (NextCoins' Place and the Update it
--   wraps), so both are wrapped once per money frame.
-- KEEP WATCH on BetterBags releases: this hooks BetterBags Next's internals (NextPanel's proto.styleFooter, the panel's
-- moneyFrame, and the Place and Update NextCoins:Fit gives it, with its copperButton, silverButton and goldButton). If they
-- are renamed it silently does nothing; if BetterBags adds theme keys for the gold or aligns it itself, remove this and
-- use those instead.
local GOLD_DROP = 2
local GOLD_TEXT_GAP, GOLD_TEXT_DROP = 3, 1
local nextPanel = BetterBags:GetModule('NextPanel', true)
local pixel = BetterBags:GetModule('NextPixel', true)

---@return boolean
local function active()
  return sonataNext:GetCurrentThemeKey() == "WoWClassic"
end

-- spaceCoins moves each amount away from its coin and down, after NextCoins laid them out.
local function spaceCoins(money)
  if not active() then return end
  for _, button in ipairs({ money.copperButton, money.silverButton, money.goldButton }) do
    local text = button and button:GetFontString()
    local point, relativeTo, relativePoint, x, y
    if text ~= nil then
      point, relativeTo, relativePoint, x, y = text:GetPoint(1)
    end
    if point ~= nil then
      local gap = pixel:Snap(button, GOLD_TEXT_GAP)
      text:SetPoint(point, relativeTo, relativePoint, x - gap, y - pixel:Snap(button, GOLD_TEXT_DROP))
      button:SetWidth(button:GetWidth() + gap)
    end
  end
end

-- wrapCoins makes NextCoins' layout space the coins every time it runs.
local function wrapCoins(money)
  if money.wowClassicSpaced or money.Place == nil or money.Update == nil then return end
  money.wowClassicSpaced = true
  local place, update = money.Place, money.Update
  money.Place = function(...)
    place(...)
    spaceCoins(money)
  end
  money.Update = function(...)
    update(...)
    spaceCoins(money)
  end
  -- The layout styleFooter just ran was not wrapped yet.
  spaceCoins(money)
end

if nextPanel ~= nil and pixel ~= nil and nextPanel.proto ~= nil and nextPanel.proto.styleFooter ~= nil then
  hooksecurefunc(nextPanel.proto, "styleFooter", function(panel)
    local money = panel.moneyFrame
    if money == nil then return end
    wrapCoins(money)
    if not active() then return end
    local frame = money.frame
    local point, relativeTo, relativePoint, x, y = frame:GetPoint(1)
    if point == nil then return end
    frame:SetPoint(point, relativeTo, relativePoint, x, y - pixel:Snap(frame, GOLD_DROP))
  end)
end

-- WoW Classic's bags are always small (asked): the classic bag was a window you moved anywhere, not a column on the
-- screen's edge. While it is the Next theme in use, every Next panel is small (BetterBags' own Small Bags setting, the
-- one its size button switches) and the size button is hidden (so it leaves the bag button's menu: the menu lists the
-- header buttons shown). Leaving it gives the size button back, and full-size bags if this theme made them small
-- (BetterBags_WoWClassic_ThemeDB.forcedSmall, kept across sessions), not if the player had them small already. A preview
-- on the Appearance page counts as using it, and putting the saved theme back as leaving it.
-- KEEP WATCH on BetterBags releases: this uses BetterBags Next's internals (NextPanel:SetSize, the Database's
-- GetNextSize, the backpack's sizeButton and LayoutHeader, the sonata/NextThemeChanged and bags/DesignChanged messages).
-- If BetterBags lets a theme choose the size, use that instead.
local database = BetterBags:GetModule('Database', true)
local events = BetterBags:GetModule('Events', true)
local context = BetterBags:GetModule('Context', true)

local function saved()
  BetterBags_WoWClassic_ThemeDB = BetterBags_WoWClassic_ThemeDB or {}
  return BetterBags_WoWClassic_ThemeDB
end

local function keepSmall(ctx)
  local bag = BetterBags.Bags and BetterBags.Bags.Backpack
  local button = bag and bag.sizeButton
  if button == nil or nextPanel == nil or database == nil then return end
  local db = saved()
  if active() then
    if database:GetNextSize() ~= "small" then
      db.forcedSmall = true
      nextPanel:SetSize(ctx, "small")
    end
    button:Hide()
  else
    if db.forcedSmall then
      db.forcedSmall = nil
      nextPanel:SetSize(ctx, "full")
    end
    button:Show()
  end
  if bag.LayoutHeader ~= nil then
    bag:LayoutHeader()
  end
end

if events ~= nil and context ~= nil and database ~= nil and database.GetNextSize ~= nil and nextPanel ~= nil
  and nextPanel.SetSize ~= nil then
  events:RegisterMessage('sonata/NextThemeChanged', keepSmall)
  events:RegisterMessage('bags/DesignChanged', keepSmall)
  -- The theme was applied as it registered, above, before this addon's saved variables were loaded: keep it small once
  -- they are.
  local loader = CreateFrame("Frame")
  loader:RegisterEvent("ADDON_LOADED")
  loader:SetScript("OnEvent", function(self, _, name)
    if name ~= "BetterBags_WoWClassic_Theme" then return end
    self:UnregisterEvent("ADDON_LOADED")
    keepSmall(context:New('WoWClassic_KeepSmall'))
  end)
end

-- The title keeps clear of the buttons pinned along the top (NextPanel's pinnedRoom), the sort and Show Blizzard Bags
-- buttons too, though they sit on the search bar's row, below it: the name sat left of the middle. While this theme is
-- in use, the title's room counts only the other pins (the close button), all at the top outer corner: as BetterBags
-- counts one there, the header button's size less its offset toward the outer side.
-- KEEP WATCH on BetterBags releases: this replaces a method of BetterBags Next's (NextPanel's proto.pinnedRoom, with the
-- panel's headerButtons and their key, and NextStyle's HEADER_BUTTON and Theme). If it changes, the name may sit left of
-- the middle again; if BetterBags leaves out pins below the title itself, remove this.
local nextStyle = BetterBags:GetModule('NextStyle', true)
if nextPanel ~= nil and nextStyle ~= nil and nextPanel.proto ~= nil and nextPanel.proto.pinnedRoom ~= nil then
  local pinnedRoom = nextPanel.proto.pinnedRoom
  nextPanel.proto.pinnedRoom = function(panel)
    if not active() then return pinnedRoom(panel) end
    local pinned = nextStyle.Theme.Header.Buttons.Pinned or {}
    local room = 0
    for _, button in ipairs(panel.headerButtons or {}) do
      local pin = pinned[button.key]
      if pin ~= nil and button:IsShown() and not SEARCH_ROW_PINS[button.key] then
        if pin.Point ~= "TOPOUTER" then return pinnedRoom(panel) end
        room = math.max(room, nextStyle.HEADER_BUTTON - (pin.X or 0))
      end
    end
    return room
  end
end
