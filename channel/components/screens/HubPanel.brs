' HubPanel component script. Markup lives in HubPanel.xml.
sub init()
  m.top.focusable = true
  m.focusZone = "tiles"
  m.tileIndex = 0
  m.utilIndex = 0
  m.tiles = [
    { id: "liveTv", label: "Live TV" }
    { id: "movies", label: "Movies" }
    { id: "series", label: "Series" }
    { id: "favorites", label: "Favorites" }
  ]

  for i = 0 to 2
    styleLabel(m.top.findNode("util" + i.ToStr() + "Text"), 18, "0xFFFFFFFF")
  end for

  renderTiles()
  updateFocusVisuals()
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
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
    grp.translation = [i * 308, 0]

    bg = grp.createChild("Rectangle")
    bg.id = "tileBg"
    bg.width = 280
    bg.height = 300
    bg.color = "0x15161AFF"

    border = grp.createChild("Rectangle")
    border.id = "tileBorder"
    border.width = 280
    border.height = 300
    border.color = "0xFFFFFF2E"

    focusPoster = grp.createChild("Poster")
    focusPoster.id = "tileFocusBg"
    focusPoster.width = 280
    focusPoster.height = 300
      focusPoster.uri = "pkg:/images/hubCardFocusedBg.jpg"
    focusPoster.loadDisplayMode = "scaleToFill"
    focusPoster.visible = false

    lbl = grp.createChild("Label")
    lbl.id = "tileLabel"
    lbl.translation = [10, 200]
    lbl.width = 260
    lbl.height = 40
    lbl.horizAlign = "center"
    lbl.text = tile.label
    lbl.font.size = 28
    lbl.color = "0xFFFFFFFF"
  end for
end sub

sub updateFocusVisuals()
  root = m.top.findNode("tilesRoot")
  for i = 0 to m.tiles.Count() - 1
    grp = root.getChild(i)
    if grp <> invalid
      focused = (m.focusZone = "tiles" and i = m.tileIndex)
      focusPoster = invalid
      border = invalid
      for c = 0 to grp.getChildCount() - 1
        child = grp.getChild(c)
        if child.id = "tileFocusBg" then focusPoster = child
        if child.id = "tileBorder" then border = child
      end for
      if focusPoster <> invalid then focusPoster.visible = focused
      if border <> invalid
        if focused
          border.color = "0xDB2C6DFF"
        else
          border.color = "0xFFFFFF2E"
        end if
      end if
    end if
  end for

  for u = 0 to 2
    bg = m.top.findNode("util" + u.ToStr() + "Bg")
    txt = m.top.findNode("util" + u.ToStr() + "Text")
    if m.focusZone = "util" and m.utilIndex = u
      bg.color = "0x23252BFF"
      txt.color = "0xFFFFFFFF"
    else
      bg.color = "0x1A1B1FFF"
      txt.color = "0xFFFFFFFF"
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
