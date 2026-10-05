' LiveChannelPanel — Web TV LiveChannelScreen layout.
sub init()
  m.top.focusable = true
  m.focusZone = "list"
  m.listIndex = 0
  m.playIndex = 0
  m.actionIndex = 0
  m.epgIndex = 1
  m.scrollTop = 0
  m.visibleRows = 7
  m.rowH = 116
  m.channels = []
  m.category = "All"

  styleLabel(m.top.findNode("header"), 30, "0xFFFFFFFF")
  styleLabel(m.top.findNode("statusLabel"), 24, "0xB1B5C3FF")
  styleLabel(m.top.findNode("previewTitle"), 26, "0xFFFFFFFF")
  styleLabel(m.top.findNode("liveBadgeText"), 20, "0xFFFFFFFF")
  styleLabel(m.top.findNode("metaLine"), 22, "0xB7BCC6FF")
  styleLabel(m.top.findNode("liveLeft"), 22, "0xB1B5C3FF")
  styleLabel(m.top.findNode("infoTitle"), 40, "0xFFFFFFFF")
  styleLabel(m.top.findNode("infoDesc"), 24, "0xC5C9D1FF")
  styleLabel(m.top.findNode("epgToday"), 26, "0xFFFFFFFF")
  styleLabel(m.top.findNode("epgChevron"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("epgTime0"), 22, "0x8B909AFF")
  styleLabel(m.top.findNode("epgTime1"), 22, "0x8B909AFF")
  styleLabel(m.top.findNode("epgTime2"), 22, "0x8B909AFF")
  styleLabel(m.top.findNode("epgNowTitle"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("epgNowSub"), 18, "0xC5C9D1FF")
  styleLabel(m.top.findNode("epgNextTitle"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("epgNextSub"), 18, "0xC5C9D1FF")

  m.video = m.top.findNode("previewVideo")
  m.video.observeField("state", "onPreviewState")

  m.task = m.top.createChild("ContentLoadTask")
  m.task.observeField("channels", "onChannels")
  m.task.observeField("error", "onError")
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPanelShown()
  m.top.backSelected = false
  m.top.channelSelected = invalid
  m.focusZone = "list"
  m.listIndex = 0
  m.playIndex = 0
  m.actionIndex = 0
  m.epgIndex = 1
  m.scrollTop = 0
  stopPreview()

  browse = m.top.browse
  m.category = ""
  initial = invalid
  if browse <> invalid
    if browse.category <> invalid then m.category = browse.category
    if browse.channel <> invalid then initial = browse.channel
  end if
  if m.category = "All" then m.category = ""

  label = m.category
  if label = "" then label = "All"
  m.top.findNode("header").text = "Category  |  " + label
  showStatus("Loading channels...")

  m.task.playlistId = DuplexLoadActivePlaylistId()
  m.task.contentType = "LIVE"
  m.task.page = 1
  m.task.limit = 80
  m.task.category = m.category
  m.task.control = "RUN"

  if initial <> invalid
    m.channels = [initial]
    m.listIndex = 0
    m.playIndex = 0
    hideStatus()
    renderList()
    updateMeta()
  end if
end sub

sub showStatus(text as String)
  label = m.top.findNode("statusLabel")
  label.visible = true
  label.text = text
end sub

sub hideStatus()
  m.top.findNode("statusLabel").visible = false
end sub

sub onChannels()
  m.channels = m.task.channels
  if m.channels = invalid then m.channels = []
  if m.channels.Count() = 0 and DuplexIsDev()
    m.channels = DuplexPreviewLiveChannels()
  end if
  m.listIndex = 0
  m.playIndex = 0
  m.scrollTop = 0
  focusInitialChannel()
  if m.channels.Count() = 0
    showStatus("No live channels in this category.")
  else
    hideStatus()
  end if
  renderList()
  updateMeta()
  startPreviewForSelection()
end sub

sub onError()
  err = m.task.error
  if err = invalid or err = "" then err = "Could not load channels"
  showStatus(err)
  if DuplexIsDev()
    m.channels = DuplexPreviewLiveChannels()
    m.listIndex = 0
    m.playIndex = 0
    hideStatus()
    renderList()
    updateMeta()
    startPreviewForSelection()
  end if
end sub

sub focusInitialChannel()
  browse = m.top.browse
  if browse = invalid or browse.channel = invalid then return
  want = browse.channel
  for i = 0 to m.channels.Count() - 1
    if sameChannel(m.channels[i], want)
      m.listIndex = i
      m.playIndex = i
      return
    end if
  end for
end sub

function sameChannel(a as Object, b as Object) as Boolean
  if a = invalid or b = invalid then return false
  if a.streamUrl <> invalid and b.streamUrl <> invalid and a.streamUrl <> "" and a.streamUrl = b.streamUrl then return true
  if a.tvgId <> invalid and b.tvgId <> invalid and a.tvgId <> "" and a.tvgId = b.tvgId then return true
  if a.name <> invalid and b.name <> invalid and a.name <> "" and a.name = b.name then return true
  return false
end function

function channelLogo(ch as Object) as String
  if ch = invalid then return ""
  if ch.tvgLogo <> invalid and ch.tvgLogo <> "" then return ch.tvgLogo
  if ch.backdropPath <> invalid and ch.backdropPath <> "" then return ch.backdropPath
  return ""
end function

function channelName(ch as Object) as String
  if ch <> invalid and ch.name <> invalid and ch.name <> "" then return ch.name
  return "Channel"
end function

sub renderList()
  root = m.top.findNode("listRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while

  count = m.channels.Count()
  if count = 0
    updateFocus()
    return
  end if
  if m.listIndex < 0 then m.listIndex = 0
  if m.listIndex > count - 1 then m.listIndex = count - 1
  if m.listIndex < m.scrollTop then m.scrollTop = m.listIndex
  if m.listIndex >= m.scrollTop + m.visibleRows then m.scrollTop = m.listIndex - m.visibleRows + 1

  row = 0
  for i = m.scrollTop to count - 1
    if row >= m.visibleRows then exit for
    ch = m.channels[i]
    playing = (i = m.playIndex)
    focused = (m.focusZone = "list" and i = m.listIndex)

    grp = root.createChild("Group")
    grp.translation = [0, row * m.rowH]

    border = grp.createChild("Rectangle")
    border.width = 476
    border.height = 110
    fill = grp.createChild("Rectangle")
    fill.translation = [3, 3]
    fill.width = 470
    fill.height = 104
    if focused
      border.color = "0x0451DFFF"
      fill.color = "0x19253EFF"
    else if playing
      border.color = "0x113578FF"
      fill.color = "0x23262FFF"
    else
      border.color = "0x00000000"
      fill.color = "0x00000000"
    end if

    thumb = grp.createChild("Rectangle")
    thumb.translation = [18, 19]
    thumb.width = 72
    thumb.height = 72
    thumb.color = "0x000000FF"
    logo = grp.createChild("Poster")
    logo.translation = [22, 23]
    logo.width = 64
    logo.height = 64
    logo.loadDisplayMode = "scaleToFit"
    uri = channelLogo(ch)
    if uri <> "" then logo.uri = uri

    nameLbl = grp.createChild("Label")
    nameLbl.translation = [108, 24]
    nameLbl.width = 348
    nameLbl.height = 32
    nameLbl.text = channelName(ch)
    nameLbl.font.size = 24
    nameLbl.color = "0xFFFFFFFF"
    if playing
      nameLbl.translation = [108, 16]
      liveLbl = grp.createChild("Label")
      liveLbl.translation = [108, 52]
      liveLbl.width = 348
      liveLbl.height = 28
      liveLbl.text = "Live..."
      liveLbl.font.size = 20
      liveLbl.color = "0xB1B5C3FF"
    end if

    row = row + 1
  end for
  updateFocus()
end sub

sub updateMeta()
  if m.channels.Count() = 0
    m.top.findNode("previewTitle").text = ""
    m.top.findNode("metaLine").text = ""
    m.top.findNode("infoTitle").text = ""
    m.top.findNode("infoDesc").text = ""
    m.top.findNode("epgNowTitle").text = ""
    m.top.findNode("epgNextTitle").text = ""
    m.top.findNode("previewPoster").uri = ""
    m.top.findNode("epgLogoPoster").uri = ""
    return
  end if
  ch = m.channels[m.playIndex]
  name = channelName(ch)
  cat = ""
  if ch.category <> invalid and ch.category <> "" then cat = ch.category
  if cat = "" and ch.groupTitle <> invalid then cat = ch.groupTitle
  if cat = "" then cat = m.category
  if cat = "" then cat = "Live"

  m.top.findNode("previewTitle").text = name
  m.top.findNode("infoTitle").text = name
  m.top.findNode("metaLine").text = name + "  •  Live  •  " + cat + "  •  " + todayLabel()
  m.top.findNode("infoDesc").text = "Now streaming: " + name
  m.top.findNode("epgNowTitle").text = name
  m.top.findNode("epgNextTitle").text = name

  uri = channelLogo(ch)
  poster = m.top.findNode("previewPoster")
  epgLogo = m.top.findNode("epgLogoPoster")
  if uri = ""
    poster.uri = ""
    epgLogo.uri = ""
  else
    poster.uri = uri
    epgLogo.uri = uri
  end if
end sub

function todayLabel() as String
  months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  dt = CreateObject("roDateTime")
  dt.ToLocalTime()
  month = dt.GetMonth()
  if month < 1 or month > 12 then return ""
  return months[month - 1] + " " + dt.GetDayOfMonth().ToStr() + ", " + dt.GetYear().ToStr()
end function

sub updateFocus()
  m.top.findNode("previewRing").visible = (m.focusZone = "preview")
  setCircle("favBg", m.focusZone = "actions" and m.actionIndex = 0)
  setCircle("lockBg", m.focusZone = "actions" and m.actionIndex = 1)
  setRing("epgLogoRing", m.focusZone = "epg" and m.epgIndex = 0)
  setRing("epgNowRing", m.focusZone = "epg" and m.epgIndex = 1)
  setRing("epgNextRing", m.focusZone = "epg" and m.epgIndex = 2)
end sub

sub setCircle(id as String, focused as Boolean)
  bg = m.top.findNode(id)
  if focused
    bg.uri = "pkg:/images/ui/hub-util-focus.png"
  else
    bg.uri = "pkg:/images/ui/hub-util.png"
  end if
end sub

sub setRing(id as String, focused as Boolean)
  ring = m.top.findNode(id)
  if focused
    ring.color = "0xFFFFFFFF"
  else
    ring.color = "0x00000000"
  end if
end sub

sub stopPreview()
  if m.video <> invalid
    m.video.control = "stop"
    m.video.content = invalid
    m.video.visible = false
  end if
end sub

sub startPreviewForSelection()
  stopPreview()
  if m.channels.Count() = 0 then return
  ch = m.channels[m.playIndex]
  url = ""
  if ch.streamUrl <> invalid then url = ch.streamUrl
  url = DuplexResolveStreamUrl(url)
  if url = "" then return
  content = CreateObject("roSGNode", "ContentNode")
  content.url = url
  content.streamFormat = "hls"
  content.title = channelName(ch)
  m.video.visible = true
  m.video.content = content
  m.video.control = "play"
end sub

sub onPreviewState()
  if m.video = invalid then return
  state = m.video.state
  if state = "error"
    m.video.visible = false
  else if state = "playing" or state = "buffering"
    m.video.visible = true
  end if
end sub

sub openSelectedChannel()
  if m.channels.Count() = 0 then return
  stopPreview()
  m.top.channelSelected = m.channels[m.playIndex]
end sub

sub selectFocusedChannel()
  if m.listIndex = m.playIndex
    openSelectedChannel()
    return
  end if
  m.playIndex = m.listIndex
  renderList()
  updateMeta()
  startPreviewForSelection()
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    stopPreview()
    m.top.backSelected = true
    return true
  end if

  if key = "up"
    if m.focusZone = "list"
      if m.listIndex > 0
        m.listIndex = m.listIndex - 1
        renderList()
      end if
    else if m.focusZone = "epg"
      m.focusZone = "preview"
      updateFocus()
    end if
    return true
  end if

  if key = "down"
    if m.focusZone = "list"
      if m.listIndex < m.channels.Count() - 1
        m.listIndex = m.listIndex + 1
        renderList()
      end if
    else if m.focusZone = "preview" or m.focusZone = "actions"
      m.focusZone = "epg"
      updateFocus()
    end if
    return true
  end if

  if key = "right"
    wasList = (m.focusZone = "list")
    if m.focusZone = "list"
      m.focusZone = "preview"
    else if m.focusZone = "preview"
      m.focusZone = "actions"
      m.actionIndex = 0
    else if m.focusZone = "actions"
      if m.actionIndex = 0
        m.actionIndex = 1
      end if
    else if m.focusZone = "epg"
      if m.epgIndex < 2 then m.epgIndex = m.epgIndex + 1
    end if
    if wasList or m.focusZone = "list"
      renderList()
    else
      updateFocus()
    end if
    return true
  end if

  if key = "left"
    if m.focusZone = "preview" or m.focusZone = "epg"
      m.focusZone = "list"
      renderList()
    else if m.focusZone = "actions"
      if m.actionIndex = 1
        m.actionIndex = 0
        updateFocus()
      else
        m.focusZone = "preview"
        updateFocus()
      end if
    end if
    return true
  end if

  if key = "OK"
    if m.focusZone = "list"
      selectFocusedChannel()
    else if m.focusZone = "preview"
      openSelectedChannel()
    else if m.focusZone = "epg" and m.epgIndex > 0
      openSelectedChannel()
    end if
    return true
  end if

  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
