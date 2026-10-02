' LiveChannelPanel component script. Markup lives in LiveChannelPanel.xml.
sub init()
  m.top.focusable = true
  m.focusZone = "list"
  m.listIndex = 0
  m.scrollTop = 0
  m.visibleRows = 10
  m.rowH = 72
  m.channels = []
  m.category = "All"

  styleLabel(m.top.findNode("header"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("listTitle"), 20, "0x9CA3AFFF")
  styleLabel(m.top.findNode("previewHint"), 18, "0x9CA3AFFF")
  styleLabel(m.top.findNode("metaTitle"), 30, "0xFFFFFFFF")
  styleLabel(m.top.findNode("metaSub"), 20, "0xB1B5C3FF")
  styleLabel(m.top.findNode("statusLabel"), 20, "0x9CA3AFFF")

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
  m.top.findNode("header").text = "Live TV  |  " + label
  m.top.findNode("statusLabel").text = "Loading channels..."

  m.task.playlistId = DuplexLoadActivePlaylistId()
  m.task.contentType = "LIVE"
  m.task.page = 1
  m.task.limit = 80
  m.task.category = m.category
  m.task.control = "RUN"

  if initial <> invalid
    m.channels = [initial]
    m.listIndex = 0
    renderList()
    updateMeta()
  end if
end sub

sub onChannels()
  m.channels = m.task.channels
  if m.channels = invalid then m.channels = []
  if m.channels.Count() = 0 and DuplexIsDev()
    m.channels = DuplexPreviewLiveChannels()
  end if
  m.listIndex = 0
  m.scrollTop = 0
  m.top.findNode("statusLabel").text = m.channels.Count().ToStr() + " channels"
  renderList()
  updateMeta()
  startPreviewForSelection()
end sub

sub onError()
  err = m.task.error
  m.top.findNode("statusLabel").text = err
  if DuplexIsDev()
    m.channels = DuplexPreviewLiveChannels()
    renderList()
    updateMeta()
    startPreviewForSelection()
    m.top.findNode("statusLabel").text = "Preview channels"
  end if
end sub

sub renderList()
  root = m.top.findNode("listRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while

  if m.listIndex < m.scrollTop then m.scrollTop = m.listIndex
  if m.listIndex >= m.scrollTop + m.visibleRows then m.scrollTop = m.listIndex - m.visibleRows + 1

  row = 0
  for i = m.scrollTop to m.channels.Count() - 1
    if row >= m.visibleRows then exit for
    ch = m.channels[i]
    name = ch.name
    if name = invalid then name = "Channel"
    grp = root.createChild("Group")
    grp.translation = [0, row * m.rowH]
    bg = grp.createChild("Rectangle")
    bg.width = 520
    bg.height = 64
    if m.focusZone = "list" and i = m.listIndex
      bg.color = "0x0451DFFF"
    else if i = m.listIndex
      bg.color = "0x23252BFF"
    else
      bg.color = "0x1A1B1FFF"
    end if
    lbl = grp.createChild("Label")
    lbl.translation = [16, 18]
    lbl.width = 488
    lbl.height = 28
    lbl.text = name
    lbl.font.size = 22
    lbl.color = "0xFFFFFFFF"
    row = row + 1
  end for
end sub

sub updateMeta()
  if m.channels.Count() = 0
    m.top.findNode("metaTitle").text = ""
    m.top.findNode("metaSub").text = ""
    return
  end if
  ch = m.channels[m.listIndex]
  name = ch.name
  if name = invalid then name = "Channel"
  cat = ch.groupTitle
  if cat = invalid or cat = "" then cat = m.category
  if cat = "" then cat = "Live"
  m.top.findNode("metaTitle").text = name
  m.top.findNode("metaSub").text = name + " · Live · " + cat
end sub

sub stopPreview()
  if m.video <> invalid
    m.video.control = "stop"
    m.video.content = invalid
  end if
end sub

sub startPreviewForSelection()
  stopPreview()
  if m.channels.Count() = 0 then return
  ch = m.channels[m.listIndex]
  url = ""
  if ch.streamUrl <> invalid then url = ch.streamUrl
  url = DuplexResolveStreamUrl(url)
  if url = ""
    m.top.findNode("statusLabel").text = "No preview URL"
    return
  end if
  content = CreateObject("roSGNode", "ContentNode")
  content.url = url
  content.streamFormat = "hls"
  if ch.name <> invalid then content.title = ch.name
  m.video.content = content
  m.video.control = "play"
  m.top.findNode("statusLabel").text = "Previewing..."
end sub

sub onPreviewState()
  state = m.video.state
  if state = "playing"
    m.top.findNode("statusLabel").text = "LIVE preview"
  else if state = "buffering"
    m.top.findNode("statusLabel").text = "Buffering preview..."
  else if state = "error"
    m.top.findNode("statusLabel").text = "Preview unavailable — OK to try fullscreen"
  end if
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    stopPreview()
    m.top.backSelected = true
    return true
  end if

  if key = "up"
    if m.focusZone = "preview"
      m.focusZone = "list"
      renderList()
    else if m.listIndex > 0
      m.listIndex = m.listIndex - 1
      renderList()
      updateMeta()
      startPreviewForSelection()
    end if
    return true
  end if

  if key = "down"
    if m.focusZone = "list"
      if m.listIndex < m.channels.Count() - 1
        m.listIndex = m.listIndex + 1
        renderList()
        updateMeta()
        startPreviewForSelection()
      end if
    end if
    return true
  end if

  if key = "right"
    m.focusZone = "preview"
    renderList()
    return true
  end if

  if key = "left"
    m.focusZone = "list"
    renderList()
    return true
  end if

  if key = "OK"
    if m.channels.Count() = 0 then return true
    stopPreview()
    m.top.channelSelected = m.channels[m.listIndex]
    return true
  end if

  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
