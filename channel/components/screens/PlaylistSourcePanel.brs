' PlaylistSourcePanel — Web TV PlaylistSourceScreen layout/behavior parity.
sub init()
  m.top.focusable = true
  m.focusArea = "list"
  m.focusIndex = 0
  m.scrollTop = 0
  m.lastListIndex = 0
  m.playlists = []
  m.cardSpacing = 116 ' 100 card + 16 gap (Web margin-top 16)
  m.cardHeight = 100
  m.listVisibleRows = 4

  styleLabel(m.top.findNode("title"), 40, "0xFFFFFFFF")
  styleLabel(m.top.findNode("subtitle"), 22, "0x9CA3AFFF")
  styleLabel(m.top.findNode("statusLabel"), 20, "0x9CA3AFFF")
  styleLabel(m.top.findNode("addTitle"), 26, "0xFFFFFFFF")
  styleLabel(m.top.findNode("addSub"), 20, "0x9CA3AFFF")

  m.listRoot = m.top.findNode("listRoot")
  m.task = invalid
  m.loading = false

  updateAddFocus(false)
end sub

sub onPanelShown()
  m.focusIndex = 0
  m.scrollTop = 0
  m.lastListIndex = 0
  m.playlists = []
  clearListCards()
  m.top.playlistSelected = invalid
  m.top.addXtreamSelected = false
  m.top.backSelected = false

  m.top.findNode("statusLabel").visible = false
  startPlaylistLoad()
end sub

sub stopPlaylistTask()
  if m.task = invalid then return
  m.task.unobserveField("playlists")
  m.task.unobserveField("error")
  m.task.control = "stop"
  m.top.removeChild(m.task)
  m.task = invalid
end sub

sub startPlaylistLoad()
  stopPlaylistTask()
  m.loading = true
  m.task = m.top.createChild("PlaylistLoadTask")
  m.task.observeField("playlists", "onPlaylistsLoaded")
  m.task.observeField("error", "onPlaylistsError")
  m.task.deviceId = DuplexLoadDeviceId()
  m.task.control = "RUN"
  showPlaylistSkeleton()

  if m.top.focusAddButton
    m.focusArea = "add"
    updateAddFocus(true)
  else
    m.focusArea = "list"
    updateAddFocus(false)
  end if
  scene = m.top.getScene()
  if scene <> invalid then scene.setFocus(true)
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub showPlaylistSkeleton()
  clearListCards()
  for i = 0 to 2
    card = m.listRoot.createChild("Group")
    card.translation = [0, i * 116]
    bg = card.createChild("Rectangle")
    bg.width = 720
    bg.height = 100
    bg.color = "0x1C1E24FF"
    icon = card.createChild("Rectangle")
    icon.translation = [22, 26]
    icon.width = 48
    icon.height = 48
    icon.color = "0x2A2E38FF"
    name = card.createChild("Rectangle")
    name.translation = [88, 28]
    name.width = 280
    name.height = 18
    name.color = "0x2A2E38FF"
    url = card.createChild("Rectangle")
    url.translation = [88, 56]
    url.width = 420
    url.height = 14
    url.color = "0x23262EFF"
  end for
end sub

sub clearListCards()
  while m.listRoot.getChildCount() > 0
    m.listRoot.removeChildIndex(0)
  end while
end sub

sub renderPlaylists()
  clearListCards()
  count = m.playlists.Count()
  if count = 0 then return

  for i = m.scrollTop to count - 1
    visibleIndex = i - m.scrollTop
    if visibleIndex >= m.listVisibleRows then exit for

    item = m.playlists[i]
    card = m.listRoot.createChild("PlaylistCard")
    card.translation = [0, visibleIndex * m.cardSpacing]
    card.cardName = item.name
    url = item.url
    if url = invalid or url = ""
      url = "No URL provided"
    end if
    card.cardUrl = DuplexTruncateUrl(url, 56)
    ' Web tag: type label only (no "# ")
    card.cardTag = DuplexPlaylistTypeLabel(item.type)
    card.cardFocused = (m.focusArea = "list" and i = m.focusIndex)
  end for
end sub

sub updateListFocus()
  count = m.playlists.Count()
  if count = 0 then return

  if m.focusIndex < m.scrollTop
    m.scrollTop = m.focusIndex
  else if m.focusIndex >= m.scrollTop + m.listVisibleRows
    m.scrollTop = m.focusIndex - m.listVisibleRows + 1
  end if

  renderPlaylists()
end sub

sub onPlaylistsLoaded()
  if not m.loading or m.task = invalid then return
  payload = m.task.playlists
  if payload = invalid or payload.items = invalid then return
  m.loading = false
  items = payload.items

  if items.Count() = 0
    m.top.findNode("statusLabel").visible = true
    m.top.findNode("statusLabel").text = "No playlists yet. Add an Xtream Codes playlist."
    m.playlists = []
    clearListCards()
    m.focusArea = "add"
    updateAddFocus(true)
    return
  end if

  m.playlists = items
  m.top.findNode("statusLabel").visible = false

  if m.top.focusAddButton
    m.focusArea = "add"
    m.focusIndex = 0
    m.scrollTop = 0
    renderPlaylists()
    updateAddFocus(true)
  else
    m.focusArea = "list"
    m.focusIndex = 0
    m.scrollTop = 0
    renderPlaylists()
    updateAddFocus(false)
  end if

  print "Duplex: loaded " + items.Count().ToStr() + " playlists"
end sub

sub onPlaylistsError()
  if not m.loading or m.task = invalid then return
  err = m.task.error
  if err = invalid or err = "" then return
  m.loading = false
  DuplexLog("playlist load failed - " + err)
  m.top.findNode("statusLabel").visible = true
  m.top.findNode("statusLabel").text = err
  m.playlists = []
  clearListCards()
  m.focusArea = "add"
  updateAddFocus(true)
end sub

sub updateAddFocus(focused as Boolean)
  ring = m.top.findNode("addRing")
  fill = m.top.findNode("addFill")
  if focused
    ring.uri = "pkg:/images/add-circle-focus.png"
    fill.visible = true
  else
    ring.uri = "pkg:/images/add-circle-dashed.png"
    fill.visible = false
  end if

  if focused
    for i = 0 to m.listRoot.getChildCount() - 1
      card = m.listRoot.getChild(i)
      if card <> invalid then card.cardFocused = false
    end for
  end if
end sub

sub selectFocusedPlaylist()
  if m.focusIndex < 0 or m.focusIndex >= m.playlists.Count() then return
  m.top.playlistSelected = m.playlists[m.focusIndex]
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if

  if key = "down" and m.focusArea = "list" and m.playlists.Count() > 0
    m.focusIndex = m.focusIndex + 1
    if m.focusIndex >= m.playlists.Count()
      m.focusIndex = m.playlists.Count() - 1
    end if
    m.lastListIndex = m.focusIndex
    updateListFocus()
    return true
  end if

  if key = "up" and m.focusArea = "list" and m.playlists.Count() > 0
    m.focusIndex = m.focusIndex - 1
    if m.focusIndex < 0 then m.focusIndex = 0
    m.lastListIndex = m.focusIndex
    updateListFocus()
    return true
  end if

  if key = "right" and m.focusArea = "list"
    m.lastListIndex = m.focusIndex
    m.focusArea = "add"
    updateAddFocus(true)
    return true
  end if

  if key = "left" and m.focusArea = "add" and m.playlists.Count() > 0
    m.focusArea = "list"
    m.focusIndex = m.lastListIndex
    updateAddFocus(false)
    updateListFocus()
    return true
  end if

  if key = "OK" and m.focusArea = "add"
    m.top.addXtreamSelected = true
    return true
  end if

  if key = "OK" and m.focusArea = "list"
    if m.playlists.Count() = 0
      m.top.addXtreamSelected = true
    else
      selectFocusedPlaylist()
    end if
    return true
  end if

  return false
end function
