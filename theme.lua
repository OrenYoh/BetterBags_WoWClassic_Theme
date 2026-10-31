---@class BetterBags: AceAddon
local BetterBags = LibStub('AceAddon-3.0'):GetAddon("BetterBags")
assert(BetterBags, "BetterBags_WoWClassic_Theme requires BetterBags")

---@class Sonata: AceModule
local sonata = BetterBags:GetModule('Sonata')

-- The classic bag window, drawn with the game's own art: UI-BackpackBackground.blp is the
-- backpack of the pre-Dragonflight UI (and of every Classic client), 256x256, still shipped on
-- retail. Its slots are baked in, so the bag is cut into pieces that stretch around any size:
-- the header (portrait, title bar, close button plate), the side borders, the stone fill and the
-- money bar at the bottom. Every number below is a pixel of that file.
local BACKPACK = "Interface\\ContainerFrame\\UI-BackpackBackground"

-- The window's edges in the art: the frame's border runs from x 74 to 251, its title bar starts
-- at y 6 and its bottom edge ends at y 250. The portrait ring hangs outside it (from x 67, y 2).
local LEFT, RIGHT, TOP, BOTTOM = 74, 251, 6, 250

---@param x0 number
---@param x1 number
---@param y0 number
---@param y1 number
---@return number[]
local function coords(x0, x1, y0, y1)
  return { x0 / 256, x1 / 256, y0 / 256, y1 / 256 }
end

-- Pieces are tiled, never stretched, so the stone keeps its grain at any size. A 1-pixel edge
-- on a piece's plain sides is only there so the whole piece tiles.
local ONE = { Left = 1, Right = 1, Top = 1, Bottom = 1 }

-- The header ends 40 below the window's top (art y 46). The money bar (art y 227 to 250) is 10
-- taller than in the art, so the currencies and money fit inside it; images/footer.png is made
-- that tall (GROWTH in source/footer_tile.py, which must match). The borders and the stone fill
-- the space between.
local HEADER_BOTTOM = -(46 - TOP)
-- The header's stone fades out over its last 14 rows (source/seams.py), so the fill starts under them and the two
-- grains blend rather than meet in a line (seen in game).
local FILL_UNDER_HEADER = 14
local FOOTER_GROWTH = 10
local FOOTER_TOP = BOTTOM - 227 + FOOTER_GROWTH
-- Inside the bar's gold lines: from art y 231 down to 243, plus the growth; raised 2 to look
-- centered (seen in game).
local MONEY_BOTTOM = BOTTOM - 243 + 2
local MONEY_HEIGHT = 243 - 231 + FOOTER_GROWTH

local TEXTURES = {
  {
    -- The portrait (the backpack in its gold ring), the title bar and the close button's plate.
    -- The ring and the plate are its margins, copied from the art; between them the title bar
    -- and the stone under it repeat, a 256 wide middle made seamless (source/header_tile.py).
    -- The header is the top left 332x44 of a 512x64 file.
    Name = "Header",
    Texture = "Interface\\AddOns\\BetterBags_WoWClassic_Theme\\images\\header.png",
    TexCoords = { 0, 332 / 512, 0, 44 / 64 },
    SliceMode = "Tiled",
    SliceMargins = { Left = 47, Right = 29, Top = 1, Bottom = 1 },
    Layer = "BORDER",
    Points = {
      { Point = "TOPLEFT", X = 67 - LEFT, Y = TOP - 2 },
      { Point = "TOPRIGHT", Y = TOP - 2 },
    },
    Size = { Height = 44 },
  },
  {
    -- The classic art has no plain stone large enough to repeat without showing, so the fill is a
    -- seamless 256x256 tile made from the art's own stone (source/stone_tile.py).
    Name = "Fill",
    Texture = "Interface\\AddOns\\BetterBags_WoWClassic_Theme\\images\\stone.png",
    HorizTile = true,
    VertTile = true,
    Layer = "BACKGROUND",
    Points = {
      { Point = "TOPLEFT", X = 80 - LEFT, Y = HEADER_BOTTOM + FILL_UNDER_HEADER },
      { Point = "BOTTOMRIGHT", X = 244 - RIGHT, Y = FOOTER_TOP },
    },
  },
  {
    Name = "LeftEdge",
    Texture = BACKPACK,
    TexCoords = coords(LEFT, 80, 47, 61),
    SliceMode = "Tiled",
    SliceMargins = ONE,
    Layer = "BORDER",
    Points = {
      { Point = "TOPLEFT", Y = HEADER_BOTTOM },
      { Point = "BOTTOMLEFT", Y = FOOTER_TOP },
    },
    Size = { Width = 80 - LEFT },
  },
  {
    Name = "RightEdge",
    Texture = BACKPACK,
    TexCoords = coords(244, RIGHT, 47, 61),
    SliceMode = "Tiled",
    SliceMargins = ONE,
    Layer = "BORDER",
    Points = {
      { Point = "TOPRIGHT", Y = HEADER_BOTTOM },
      { Point = "BOTTOMRIGHT", Y = FOOTER_TOP },
    },
    Size = { Width = RIGHT - 244 },
  },
  {
    -- The money bar and the bottom edge. The bar's ends are its margins, copied from the art: its
    -- gold caps, and on the right the shadow it darkens into; between them a 256 wide middle made
    -- seamless repeats (source/footer_tile.py). The bar is the top left 329 x FOOTER_TOP of a
    -- 512x64 file.
    Name = "Footer",
    Texture = "Interface\\AddOns\\BetterBags_WoWClassic_Theme\\images\\footer.png",
    TexCoords = { 0, 329 / 512, 0, FOOTER_TOP / 64 },
    SliceMode = "Tiled",
    SliceMargins = { Left = 22, Right = 51, Top = 1, Bottom = 1 },
    Layer = "BORDER",
    Points = {
      { Point = "BOTTOMLEFT" },
      { Point = "BOTTOMRIGHT" },
    },
    Size = { Height = FOOTER_TOP },
  },
}

-- The buttons at the end of the search bar: 28 square, SORT_GAP apart, the first 9 in from the window's right edge
-- (inside its 7-wide border).
local SORT_SIZE, SORT_RIGHT, SORT_GAP = 28, -9, 2
local HIGHLIGHT = { Texture = "Interface\\Buttons\\ButtonHilight-Square", BlendMode = "ADD",
  Inset = { Left = 2, Right = 2, Top = 2, Bottom = 3 } }

-- The bag's name, centered in the title bar (art x 110 to 226), at the height the classic bag's
-- name sat (art y 10).
local TITLE = {
  Font = { Object = "GameFontHighlight" },
  Points = {
    { Point = "TOPLEFT", X = 110 - LEFT, Y = -(10 - TOP) },
    { Point = "TOPRIGHT", X = 226 - RIGHT, Y = -(10 - TOP) },
  },
  Height = 12,
  Justify = "CENTER",
}

-- The classic close button, at the frame's top right (0, -1) as on the old bags, over the plate.
local CLOSE = {
  Template = "UIPanelCloseButton",
  Size = 32,
  Points = { { Point = "TOPRIGHT", X = 256 - RIGHT, Y = TOP - 1 } },
  Normal = { Texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Up" },
  Pushed = { Texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Down" },
  Highlight = { Texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight", BlendMode = "ADD" },
  Disabled = { Texture = "Interface\\Buttons\\UI-Panel-MinimizeButton-Disabled" },
}

sonata:RegisterTheme({
  Name = "WoWClassic",
  DisplayName = "WoW Classic",
  Description = "The classic World of Warcraft bags.",
  -- Every other window (settings, dialogs, the bag slots) keeps BetterBags' Blizzard look.
  Parent = "Default",
  Windows = {
    Bag = {
      Template = false,
      Textures = TEXTURES,
      Title = TITLE,
      CloseButton = CLOSE,
      -- Inside the borders (6 on the left, 7 on the right) with the same room on both sides,
      -- below the header and above the money bar.
      Insets = { Left = 8, Right = 9, Top = -HEADER_BOTTOM + 2, Bottom = 2 },
      Layout = {
        Search = {
          Points = {
            -- Lined up with the items, as they sit in a bag snapped to its content (seen in game).
            { Point = "TOPLEFT", X = 32, Y = HEADER_BOTTOM },
            -- Ending 4 before the sort button.
            { Point = "BOTTOMRIGHT", RelativePoint = "TOPRIGHT", X = SORT_RIGHT - 2 * SORT_SIZE - SORT_GAP - 4,
              Y = HEADER_BOTTOM - 20 },
          },
          Reserve = 24,
        },
        -- At the end of the search bar, 28 square, their middles on the search bar's, right to left (Row, below):
        -- Show Bags (the menu's), drawn as the game's backpack button on its bag bar (bag-main, its bag-main-highlight
        -- added under the pointer; every client has them), darker while pressed; then the game's own Clean Up Bags
        -- button (ContainerFrame.xml, BagItemAutoSortButton: bags-button-autosort-up and -down, ButtonHilight-Square
        -- added under the pointer at 24 x 23), which sorts as the menu button's right click does.
        Actions = {
          Points = { { Point = "TOPRIGHT", X = SORT_RIGHT, Y = HEADER_BOTTOM - 10 + SORT_SIZE / 2 } },
          Size = SORT_SIZE,
          Spacing = SORT_GAP,
          Row = true,
          Buttons = {
            {
              Action = "ShowBags",
              Normal = { Atlas = "bag-main" },
              Pushed = { Atlas = "bag-main", VertexColor = { 0.6, 0.6, 0.6, 1 } },
              Highlight = { Atlas = "bag-main-highlight", BlendMode = "ADD" },
            },
            {
              Action = "Sort",
              Normal = { Atlas = "bags-button-autosort-up" },
              Pushed = { Atlas = "bags-button-autosort-down" },
              Highlight = HIGHLIGHT,
            },
          },
        },
        -- The money and currencies sit inside the money bar.
        Footer = { Left = 12, Right = 12, Bottom = MONEY_BOTTOM, Height = MONEY_HEIGHT, Reserve = FOOTER_TOP },
        -- The tab bar hangs from the bag's bottom edge (BetterBags' default tucks it 2 into the
        -- window).
        Tabs = { Offset = { X = 0, Y = 0 } },
        -- The menu button covers the portrait, whose backpack is part of the art.
        MenuButton = { Points = { { Point = "TOPLEFT", X = 68 - LEFT, Y = TOP - 4 } } },
      },
    },
  },
  Elements = {
    BagButton = {
      Size = 40,
      Portrait = false,
      Highlight = {
        Texture = "Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight",
        BlendMode = "ADD",
        Width = 40,
        Height = 40,
      },
    },
  },
})

-- The portrait shows the bag in the first bag slot, as each classic bag window showed its own
-- bag. The art's backpack stays underneath, and shows while that slot is empty. The icon sits on
-- BetterBags' menu button (above the window), inside the gold ring, under the button's hover.
local events = BetterBags:GetModule('Events')
local PORTRAIT_BAG = Enum.BagIndex and Enum.BagIndex.Bag_1 or 1
local PORTRAIT_SIZE = 34

---@return string|number|nil
local function firstBagIcon()
  local toInventory = C_Container and C_Container.ContainerIDToInventoryID or ContainerIDToInventoryID
  local slot = toInventory and toInventory(PORTRAIT_BAG)
  return slot and GetInventoryItemTexture("player", slot)
end

---@param button Button
---@return Texture
local function portraitOf(button)
  if button.wowClassicPortrait == nil then
    local icon = button:CreateTexture(nil, "OVERLAY", nil, 6)
    icon:SetSize(PORTRAIT_SIZE, PORTRAIT_SIZE)
    -- Item icons have a dark frame painted in their edges: zoom past it.
    icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
    icon:SetPoint("CENTER", button, "CENTER", 0, 0)
    local mask = button:CreateMaskTexture()
    mask:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask", "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
    mask:SetAllPoints(icon)
    icon:AddMaskTexture(mask)
    button.wowClassicPortrait = icon
  end
  return button.wowClassicPortrait
end

-- Only the classic bags' menu button is a frame: BetterBags Next's bag button (next.lua) is an object of its own, its
-- portrait the art's.
local function updatePortrait()
  local bag = BetterBags.Bags and BetterBags.Bags.Backpack
  local button = bag and bag.menuButton
  if button == nil or button.CreateTexture == nil then return end
  local texture = sonata:GetCurrentThemeKey() == "WoWClassic" and firstBagIcon() or nil
  if texture == nil then
    if button.wowClassicPortrait ~= nil then button.wowClassicPortrait:Hide() end
    return
  end
  local icon = portraitOf(button)
  icon:SetTexture(texture)
  icon:Show()
end

events:RegisterMessage('sonata/ThemeChanged', updatePortrait)
events:RegisterMessage('bags/DesignChanged', updatePortrait)
events:RegisterEvent('BAG_CONTAINER_UPDATE', updatePortrait)
events:RegisterEvent('PLAYER_ENTERING_WORLD', updatePortrait)

-- BetterBags stacks a theme's action buttons down from the first (frames/bagactions.lua, BagActions:Place); this theme's
-- (Layout.Actions with Row, its own key) go right to left from it instead, each SORT_GAP left of the one before.
-- KEEP WATCH on BetterBags releases: this hooks BetterBags' internals (the BagActions module's Place and the buttons it
-- keeps). If they are renamed the buttons stack down again; if BetterBags lets a theme lay its actions in a row, use that.
local bagActions = BetterBags:GetModule('BagActions', true)
if bagActions ~= nil and bagActions.Place ~= nil then
  hooksecurefunc(bagActions, "Place", function(_, actions, layout)
    if type(layout) ~= "table" or not layout.Row or actions == nil or actions.buttons == nil then return end
    for i = 2, #(layout.Buttons or {}) do
      local button, before = actions.buttons[i], actions.buttons[i - 1]
      if button ~= nil and before ~= nil then
        button:ClearAllPoints()
        button:SetPoint("RIGHT", before, "LEFT", -(layout.Spacing or 0), 0)
      end
    end
  end)
end
