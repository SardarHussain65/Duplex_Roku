' VodDetailPanel component script. Markup lives in VodDetailPanel.xml.
sub init()
  m.top.focusable = true
  styleLabel(m.top.findNode("title"), 40, "0xFFFFFFFF")
  styleLabel(m.top.findNode("meta"), 22, "0xB1B5C3FF")
  styleLabel(m.top.findNode("plot"), 20, "0xD1D5DBFF")
  styleLabel(m.top.findNode("watchText"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("hint"), 18, "0x9CA3AFFF")
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPanelShown()
  m.top.backSelected = false
  m.top.watchSelected = invalid
  item = m.top.item
  name = "Title"
  ctype = "MOVIE"
  poster = ""
  plot = ""
  genre = ""
  if item <> invalid
    if item.name <> invalid then name = item.name
    if item.contentType <> invalid then ctype = item.contentType
    if item.tvgLogo <> invalid then poster = item.tvgLogo
    if item.backdropPath <> invalid and item.backdropPath <> "" then poster = item.backdropPath
    if item.plot <> invalid then plot = item.plot
    if item.groupTitle <> invalid then genre = item.groupTitle
    if item.genre <> invalid and item.genre <> "" then genre = item.genre
  end if
  if plot = "" then plot = "Select Watch Now to start playback."
  m.top.findNode("title").text = name
  m.top.findNode("meta").text = ctype + " · " + genre
  m.top.findNode("plot").text = plot
  if poster <> ""
    m.top.findNode("backdrop").uri = poster
  else
    m.top.findNode("backdrop").uri = "pkg:/images/heroImageLiveTV.jpg"
  end if
  m.top.findNode("watchBg").color = "0xFFFFFFFF"
  m.top.findNode("watchText").color = "0x111111FF"
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if
  if key = "OK"
    m.top.watchSelected = m.top.item
    return true
  end if
  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
