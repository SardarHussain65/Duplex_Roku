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

  m.sidebarOpen = false
  m.confirmOpen = false
  m.confirmFocus = 1
  m.sidebarFocus = 0
  m.sidebarScroll = 0
  m.sidebarVisible = 9
  m.sidebarRowH = 92
  m.playlists = []
  m.sidebarLoading = false
  m.sidebarError = ""
  m.playlistTask = invalid

  styleLabel(m.top.findNode("sidebarTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("sidebarStatus"), 20, "0x9CA3AFFF")
  styleLabel(m.top.findNode("confirmTitle"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("confirmCopy"), 20, "0x9CA3AFFF")
  styleLabel(m.top.findNode("confirmCancelText"), 20, "0xFFFFFFFF")
  styleLabel(m.top.findNode("confirmOkText"), 20, "0x111111FF")

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
  closePlaylistSidebar()
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
  if m.confirmOpen then return handleConfirmKey(key)
  if m.sidebarOpen then return handleSidebarKey(key)

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
        openPlaylistSidebar()
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

sub openPlaylistSidebar()
  m.sidebarOpen = true
  m.confirmOpen = false
  m.sidebarFocus = 0
  m.sidebarScroll = 0
  m.playlists = []
  m.sidebarLoading = true
  m.sidebarError = ""
  m.top.findNode("playlistConfirm").visible = false
  m.top.findNode("playlistSidebar").visible = true
  renderSidebar()
  startPlaylistLoad()
end sub

sub closePlaylistSidebar()
  m.sidebarOpen = false
  m.confirmOpen = false
  m.sidebarLoading = false
  stopPlaylistTask()
  sidebar = m.top.findNode("playlistSidebar")
  if sidebar <> invalid then sidebar.visible = false
  confirm = m.top.findNode("playlistConfirm")
  if confirm <> invalid then confirm.visible = false
end sub

sub startPlaylistLoad()
  stopPlaylistTask()
  m.playlistTask = m.top.createChild("PlaylistLoadTask")
  m.playlistTask.observeField("playlists", "onSidebarPlaylists")
  m.playlistTask.observeField("error", "onSidebarError")
  m.playlistTask.deviceId = DuplexLoadDeviceId()
  m.playlistTask.control = "RUN"
end sub

sub stopPlaylistTask()
  if m.playlistTask = invalid then return
  m.playlistTask.unobserveField("playlists")
  m.playlistTask.unobserveField("error")
  m.playlistTask.control = "stop"
  m.top.removeChild(m.playlistTask)
  m.playlistTask = invalid
end sub

sub onSidebarPlaylists()
  if not m.sidebarOpen then return
  if m.playlistTask = invalid then return
  payload = m.playlistTask.playlists
  if payload = invalid or payload.items = invalid then return
  items = payload.items
  m.sidebarLoading = false
  m.sidebarError = ""
  m.playlists = items
  m.sidebarFocus = 0
  m.sidebarScroll = 0
  activeId = DuplexLoadActivePlaylistId()
  for i = 0 to m.playlists.Count() - 1
    item = m.playlists[i]
    itemId = ""
    if item <> invalid and item.id <> invalid then itemId = item.id.ToStr()
    if itemId <> "" and itemId = activeId
      m.sidebarFocus = i
      exit for
    end if
  end for
  ensureSidebarScroll()
  renderSidebar()
end sub

sub onSidebarError()
  if not m.sidebarOpen then return
  if m.playlistTask = invalid then return
  message = m.playlistTask.error
  if message = invalid or message = "" then return
  m.sidebarLoading = false
  m.sidebarError = message
  m.playlists = []
  renderSidebar()
end sub

function handleSidebarKey(key as String) as Boolean
  if key = "back"
    closePlaylistSidebar()
    return true
  end if
  if m.sidebarLoading or m.sidebarError <> "" then return true
  count = m.playlists.Count()
  if count = 0 then return true

  if key = "up"
    if m.sidebarFocus > 0 then m.sidebarFocus = m.sidebarFocus - 1
    ensureSidebarScroll()
    renderSidebar()
    return true
  end if
  if key = "down"
    if m.sidebarFocus < count - 1 then m.sidebarFocus = m.sidebarFocus + 1
    ensureSidebarScroll()
    renderSidebar()
    return true
  end if
  if key = "OK"
    requestPlaylistSwitch()
    return true
  end if
  return true
end function

sub requestPlaylistSwitch()
  if m.sidebarFocus < 0 or m.sidebarFocus >= m.playlists.Count() then return
  item = m.playlists[m.sidebarFocus]
  if item = invalid then return
  activeId = DuplexLoadActivePlaylistId()
  itemId = ""
  if item.id <> invalid then itemId = item.id.ToStr()
  if itemId <> "" and itemId = activeId then return
  m.confirmOpen = true
  m.confirmFocus = 1
  m.top.findNode("playlistConfirm").visible = true
  updateConfirmFocus()
end sub

function handleConfirmKey(key as String) as Boolean
  if key = "back"
    m.confirmOpen = false
    m.top.findNode("playlistConfirm").visible = false
    return true
  end if
  if key = "left"
    m.confirmFocus = 0
    updateConfirmFocus()
    return true
  end if
  if key = "right"
    m.confirmFocus = 1
    updateConfirmFocus()
    return true
  end if
  if key = "OK"
    if m.confirmFocus = 0
      m.confirmOpen = false
      m.top.findNode("playlistConfirm").visible = false
    else
      applyPlaylistSwitch()
    end if
    return true
  end if
  return true
end function

sub applyPlaylistSwitch()
  if m.sidebarFocus < 0 or m.sidebarFocus >= m.playlists.Count() then return
  item = m.playlists[m.sidebarFocus]
  if item = invalid then return
  picked = {
    id: item.id
    name: item.name
    url: item.url
    type: item.type
    isPinRequired: item.isPinRequired
  }
  closePlaylistSidebar()
  m.top.playlistPicked = picked
end sub

sub updateConfirmFocus()
  cancelBg = m.top.findNode("confirmCancelBg")
  cancelText = m.top.findNode("confirmCancelText")
  okBg = m.top.findNode("confirmOkBg")
  okText = m.top.findNode("confirmOkText")
  if m.confirmFocus = 0
    cancelBg.uri = "pkg:/images/ui/btn-white-280.png"
    cancelText.color = "0x111111FF"
    okBg.uri = "pkg:/images/ui/btn-outline-280.png"
    okText.color = "0xFFFFFFFF"
  else
    cancelBg.uri = "pkg:/images/ui/btn-outline-280.png"
    cancelText.color = "0xFFFFFFFF"
    okBg.uri = "pkg:/images/ui/btn-white-280.png"
    okText.color = "0x111111FF"
  end if
end sub

sub ensureSidebarScroll()
  count = m.playlists.Count()
  if count = 0 then return
  if m.sidebarFocus < 0 then m.sidebarFocus = 0
  if m.sidebarFocus > count - 1 then m.sidebarFocus = count - 1
  if m.sidebarFocus < m.sidebarScroll
    m.sidebarScroll = m.sidebarFocus
  else if m.sidebarFocus >= m.sidebarScroll + m.sidebarVisible
    m.sidebarScroll = m.sidebarFocus - m.sidebarVisible + 1
  end if
end sub

sub renderSidebar()
  root = m.top.findNode("sidebarList")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while

  status = m.top.findNode("sidebarStatus")
  if m.sidebarLoading
    status.visible = false
    for i = 0 to 3
      row = root.createChild("Rectangle")
      row.translation = [0, i * 88]
      row.width = 488
      row.height = 72
      row.color = "0x3A3F4AFF"
    end for
    return
  end if
  if m.sidebarError <> ""
    status.visible = true
    status.text = m.sidebarError
    return
  end if
  if m.playlists.Count() = 0
    status.visible = true
    status.text = "No playlists found."
    return
  end if
  status.visible = false

  activeId = DuplexLoadActivePlaylistId()
  rowW = 488
  rowH = 84
  for i = m.sidebarScroll to m.playlists.Count() - 1
    vis = i - m.sidebarScroll
    if vis >= m.sidebarVisible then exit for
    item = m.playlists[i]
    row = root.createChild("Group")
    row.translation = [0, vis * m.sidebarRowH]

    if i = m.sidebarFocus
      bg = row.createChild("Rectangle")
      bg.width = rowW
      bg.height = rowH
      bg.color = "0x505359FF"
    end if

    name = "Playlist"
    if item.name <> invalid and item.name.ToStr() <> "" then name = item.name.ToStr()
    url = ""
    if item.url <> invalid then url = item.url.ToStr()
    if url = "" then url = "No URL provided"

    nameLbl = row.createChild("Label")
    nameLbl.translation = [18, 14]
    nameLbl.width = 420
    nameLbl.height = 30
    nameLbl.text = name
    nameLbl.font.size = 22
    nameLbl.color = "0xFFFFFFFF"

    urlLbl = row.createChild("Label")
    urlLbl.translation = [18, 46]
    urlLbl.width = 420
    urlLbl.height = 24
    urlLbl.text = DuplexTruncateUrl(url, 42)
    urlLbl.font.size = 16
    urlLbl.color = "0x9CA3AFFF"

    itemId = ""
    if item.id <> invalid then itemId = item.id.ToStr()
    if itemId <> "" and itemId = activeId
      check = row.createChild("Poster")
      check.translation = [448, 30]
      check.width = 22
      check.height = 22
      check.uri = "pkg:/images/ui/settings-check.png"
      check.loadDisplayMode = "scaleToFit"
    end if
  end for
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
