' HubPanel — Web TV HubScreen visual parity (rounded tiles, circular utils, icons).
sub init()
  m.top.focusable = true
  m.focusZone = "tiles"
  m.tileIndex = 0
  m.utilIndex = 0
  m.tiles = [
    { id: "liveTv", label: "Live TV", icon: "pkg:/images/ui/hub-tile-live.png" }
    { id: "movies", label: "Movies", icon: "pkg:/images/ui/hub-tile-movies.png" }
    { id: "series", label: "Series", icon: "pkg:/images/ui/hub-tile-series.png" }
    { id: "favorites", label: "Favorites", icon: "pkg:/images/ui/hub-tile-favorites.png" }
  ]

  renderTiles()
  updateFocusVisuals()
end sub

sub onPanelShown()
  m.focusZone = "tiles"
  m.tileIndex = 0
  m.utilIndex = 0
  m.top.sectionSelected = ""
  m.top.switchPlaylistSelected = false
  m.top.parentalSelected = false
  m.top.settingsSelected = false
  m.top.backSelected = false
  updateFocusVisuals()
end sub

sub renderTiles()
  root = m.top.findNode("tilesRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while

  for i = 0 to m.tiles.Count() - 1
    tile = m.tiles[i]
    grp = root.createChild("Group")
    ' 280 tile + 28 gap
    grp.translation = [i * 308, 0]

    ' Magenta focus ring + soft glow (pad 44 → 368x388)
    ring = grp.createChild("Poster")
    ring.id = "tileRing"
    ring.translation = [-44, -44]
    ring.width = 368
    ring.height = 388
    ring.uri = "pkg:/images/ui/hub-tile-focus-ring.png"
    ring.loadDisplayMode = "scaleToFit"
    ring.visible = false

    ' Rounded tile chrome
    art = grp.createChild("Poster")
    art.id = "tileArt"
    art.width = 280
    art.height = 300
    art.uri = "pkg:/images/ui/hub-tile.png"
    art.loadDisplayMode = "scaleToFit"

    ' Focus background image (Web hubCardFocusedBg)
    focusBg = grp.createChild("Poster")
    focusBg.id = "tileFocusBg"
    focusBg.width = 280
    focusBg.height = 300
    focusBg.uri = "pkg:/images/ui/hub-tile-focus-bg.png"
    focusBg.loadDisplayMode = "scaleToFit"
    focusBg.visible = false

    icon = grp.createChild("Poster")
    icon.id = "tileIcon"
    icon.translation = [104, 78]
    icon.width = 72
    icon.height = 72
    icon.uri = tile.icon
    icon.loadDisplayMode = "scaleToFit"

    lbl = grp.createChild("Label")
    lbl.id = "tileLabel"
    lbl.translation = [10, 168]
    lbl.width = 260
    lbl.height = 44
    lbl.horizAlign = "center"
    lbl.text = tile.label
    lbl.font.size = 32
    lbl.color = "0xFFFFFFFF"
  end for
end sub

sub updateFocusVisuals()
  root = m.top.findNode("tilesRoot")
  for i = 0 to m.tiles.Count() - 1
    grp = root.getChild(i)
    if grp <> invalid
      focused = (m.focusZone = "tiles" and i = m.tileIndex)
      ring = invalid
      focusBg = invalid
      for c = 0 to grp.getChildCount() - 1
        child = grp.getChild(c)
        if child.id = "tileRing" then ring = child
        if child.id = "tileFocusBg" then focusBg = child
      end for
      if ring <> invalid then ring.visible = focused
      if focusBg <> invalid then focusBg.visible = focused
      ' Approximate Web scale(1.07) with slight lift
      if focused
        grp.translation = [i * 308 - 10, -12]
      else
        grp.translation = [i * 308, 0]
      end if
    end if
  end for

  for u = 0 to 2
    bg = m.top.findNode("util" + u.ToStr() + "Bg")
    if m.focusZone = "util" and m.utilIndex = u
      bg.uri = "pkg:/images/ui/hub-util-focus.png"
    else
      bg.uri = "pkg:/images/ui/hub-util.png"
    end if
  end for
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if

  if key = "up"
    if m.focusZone = "tiles"
      m.focusZone = "util"
      m.utilIndex = 2
      updateFocusVisuals()
    end if
    return true
  end if

  if key = "down"
    if m.focusZone = "util"
      m.focusZone = "tiles"
      m.tileIndex = 0
      updateFocusVisuals()
    end if
    return true
  end if

  if key = "left"
    if m.focusZone = "tiles"
      m.tileIndex = m.tileIndex - 1
      if m.tileIndex < 0 then m.tileIndex = 0
    else
      m.utilIndex = m.utilIndex - 1
      if m.utilIndex < 0 then m.utilIndex = 0
    end if
    updateFocusVisuals()
    return true
  end if

  if key = "right"
    if m.focusZone = "tiles"
      m.tileIndex = m.tileIndex + 1
      if m.tileIndex >= m.tiles.Count() then m.tileIndex = m.tiles.Count() - 1
    else
      m.utilIndex = m.utilIndex + 1
      if m.utilIndex > 2 then m.utilIndex = 2
    end if
    updateFocusVisuals()
    return true
  end if

  if key = "OK"
    if m.focusZone = "util"
      if m.utilIndex = 0
        m.top.switchPlaylistSelected = true
      else if m.utilIndex = 1
        m.top.parentalSelected = true
      else
        m.top.settingsSelected = true
      end if
    else
      m.top.sectionSelected = m.tiles[m.tileIndex].id
    end if
    return true
  end if

  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
