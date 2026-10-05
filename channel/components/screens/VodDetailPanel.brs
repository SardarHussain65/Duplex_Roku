' VodDetailPanel component script. Markup lives in VodDetailPanel.xml.
sub init()
  m.top.focusable = true
  m.actionIndex = 0
  styleLabel(m.top.findNode("meta"), 22, "0xB7BCC6FF")
  styleLabel(m.top.findNode("title"), 56, "0xFFFFFFFF")
  styleLabel(m.top.findNode("starText"), 18, "0xF5C451FF")
  styleLabel(m.top.findNode("ageText"), 18, "0xFFFFFFFF")
  styleLabel(m.top.findNode("plot"), 24, "0xC5C9D1FF")
  styleLabel(m.top.findNode("watchText"), 26, "0x111111FF")
  styleLabel(m.top.findNode("castLabel"), 24, "0xFFFFFFFF")
  styleLabel(m.top.findNode("castNames"), 24, "0xD0D4DCFF")
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPanelShown()
  m.top.backSelected = false
  m.top.watchSelected = invalid
  m.actionIndex = 0
  item = m.top.item
  name = "Title"
  plot = ""
  genre = ""
  year = ""
  poster = ""
  backdrop = ""
  cast = ""
  age = "13+"
  if item <> invalid
    if item.name <> invalid and item.name <> "" then name = item.name
    if item.plot <> invalid then plot = item.plot
    if item.groupTitle <> invalid then genre = item.groupTitle
    if item.genre <> invalid and item.genre <> "" then genre = item.genre
    if item.category <> invalid and item.category <> "" and genre = "" then genre = item.category
    if item.releaseYear <> invalid and item.releaseYear.ToStr() <> "" and item.releaseYear.ToStr() <> "0" then year = item.releaseYear.ToStr()
    if item.year <> invalid and item.year.ToStr() <> "" and year = "" then year = item.year.ToStr()
    if item.tvgLogo <> invalid then poster = item.tvgLogo
    if item.streamIcon <> invalid and item.streamIcon <> "" and poster = "" then poster = item.streamIcon
    if item.backdropPath <> invalid then backdrop = item.backdropPath
    if item.age <> invalid and item.age.ToStr() <> "" then age = item.age.ToStr()
    if item.contentRating <> invalid and item.contentRating.ToStr() <> "" then age = item.contentRating.ToStr()
    cast = formatCast(item.cast)
    if cast = "" then cast = formatCast(item.actors)
  end if
  if poster = "" then poster = backdrop
  if backdrop = "" then backdrop = poster
  if plot = "" then plot = "Select Watch now to start playback."

  m.top.findNode("title").text = name
  m.top.findNode("meta").text = joinBits([genre, year, formatClock(item)])
  m.top.findNode("plot").text = plot
  m.top.findNode("starText").text = "★  " + ratingLabel(item)
  m.top.findNode("ageText").text = age
  m.top.findNode("castNames").text = cast
  m.top.findNode("castRow").visible = cast <> ""

  backdropNode = m.top.findNode("backdrop")
  posterNode = m.top.findNode("poster")
  if backdrop <> "" then backdropNode.uri = backdrop else backdropNode.uri = "pkg:/images/heroImageLiveTV.jpg"
  if poster <> "" then posterNode.uri = poster else posterNode.uri = "pkg:/images/heroImageLiveTV.jpg"
  paintActions()
end sub

function formatCast(value as Object) as String
  if value = invalid then return ""
  text = ""
  if GetInterface(value, "ifArray") <> invalid
    for each part in value
      bit = ""
      if part <> invalid then bit = part.ToStr()
      if bit <> "" and LCase(bit) <> "null" and LCase(bit) <> "n/a"
        if text <> "" then text = text + " • "
        text = text + bit
      end if
    end for
  else
    text = value.ToStr()
    if LCase(text) = "null" or LCase(text) = "n/a" or text = "-" then return ""
    text = text.Replace(", ", " • ")
    text = text.Replace(",", " • ")
  end if
  return text
end function

function joinBits(parts as Object) as String
  out = ""
  for each part in parts
    if part <> invalid and part <> ""
      if out <> "" then out = out + "  •  "
      out = out + part
    end if
  end for
  return out
end function

function formatClock(item as Object) as String
  if item = invalid then return ""
  raw = invalid
  if item.duration <> invalid and item.duration.ToStr() <> "" then raw = item.duration
  if raw = invalid and item.runtime <> invalid and item.runtime.ToStr() <> "" then raw = item.runtime
  if raw = invalid and item.episodeRunTime <> invalid and item.episodeRunTime.ToStr() <> "" then raw = item.episodeRunTime
  if raw = invalid then return ""
  text = raw.ToStr()
  if Instr(1, text, ":") > 0 then return text
  n = Int(Val(text))
  if n <= 0 then return ""
  secs = n
  if n < 1000 then secs = n * 60
  return pad2(Int(secs / 3600)) + ":" + pad2(Int((secs mod 3600) / 60)) + ":" + pad2(secs mod 60)
end function

function pad2(n as Integer) as String
  if n < 10 then return "0" + n.ToStr()
  return n.ToStr()
end function

function ratingLabel(item as Object) as String
  if item = invalid then return "N/A"
  raw = invalid
  if item.rating5based <> invalid and item.rating5based.ToStr() <> "" then raw = item.rating5based
  if raw = invalid and item.rating_5based <> invalid and item.rating_5based.ToStr() <> "" then raw = item.rating_5based
  if raw = invalid and item.rating <> invalid and item.rating.ToStr() <> "" then raw = item.rating
  if raw = invalid then return "N/A"
  value = Val(raw.ToStr())
  if value <= 0 then return "N/A"
  if value > 5 then value = value / 2
  whole = Int(value)
  frac = Int((value - whole) * 10 + 0.5)
  if frac >= 10
    whole = whole + 1
    frac = 0
  end if
  return whole.ToStr() + "." + frac.ToStr()
end function

sub paintActions()
  m.top.findNode("watchRing").visible = m.actionIndex = 0
  if m.actionIndex = 1
    m.top.findNode("favBg").uri = "pkg:/images/ui/hub-util-focus.png"
  else
    m.top.findNode("favBg").uri = "pkg:/images/ui/hub-util.png"
  end if
  if m.actionIndex = 2
    m.top.findNode("lockBg").uri = "pkg:/images/ui/hub-util-focus.png"
  else
    m.top.findNode("lockBg").uri = "pkg:/images/ui/hub-util.png"
  end if
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if
  if key = "left"
    if m.actionIndex > 0 then m.actionIndex = m.actionIndex - 1
    paintActions()
    return true
  end if
  if key = "right"
    if m.actionIndex < 2 then m.actionIndex = m.actionIndex + 1
    paintActions()
    return true
  end if
  if key = "OK"
    if m.actionIndex = 0 then m.top.watchSelected = m.top.item
    return true
  end if
  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
