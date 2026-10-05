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
  styleLabel(m.top.findNode("actionStatus"), 22, "0xF5C451FF")
  m.skeletonBright = false
  m.skeletonTimer = m.top.createChild("Timer")
  m.skeletonTimer.duration = 0.7
  m.skeletonTimer.repeat = true
  m.skeletonTimer.observeField("fire", "onSkeletonPulse")
  m.favoriteId = ""
  m.lockId = ""
  m.actionBusy = false
  m.infoTask = invalid
  m.actionTask = invalid
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
  m.top.findNode("actionStatus").visible = false
  m.favoriteId = ""
  m.lockId = ""
  showDetailSkeleton()

  backdropNode = m.top.findNode("backdrop")
  posterNode = m.top.findNode("poster")
  if backdrop <> "" then backdropNode.uri = backdrop else backdropNode.uri = "pkg:/images/heroImageLiveTV.jpg"
  if poster <> "" then posterNode.uri = poster else posterNode.uri = "pkg:/images/heroImageLiveTV.jpg"
  paintActions()
  startDetailLoad()
end sub

sub showDetailSkeleton()
  bones = [
    { x: 96, y: 190, w: 404, h: 606 }
    { x: 564, y: 210, w: 380, h: 28 }
    { x: 564, y: 260, w: 760, h: 64 }
    { x: 564, y: 350, w: 150, h: 36 }
    { x: 730, y: 350, w: 72, h: 36 }
    { x: 564, y: 410, w: 980, h: 22 }
    { x: 564, y: 444, w: 920, h: 22 }
    { x: 564, y: 478, w: 860, h: 22 }
    { x: 564, y: 560, w: 320, h: 72 }
    { x: 908, y: 556, w: 80, h: 80 }
    { x: 1004, y: 556, w: 80, h: 80 }
    { x: 564, y: 670, w: 720, h: 24 }
  ]
  DuplexFillSkeleton(m.top.findNode("detailSkeleton"), bones)
  m.top.findNode("loadingOverlay").visible = true
  m.skeletonBright = false
  m.skeletonTimer.control = "start"
end sub

sub hideDetailSkeleton()
  if m.skeletonTimer <> invalid then m.skeletonTimer.control = "stop"
  DuplexHideSkeleton(m.top.findNode("detailSkeleton"))
  m.top.findNode("loadingOverlay").visible = false
end sub

sub onSkeletonPulse()
  if m.top.findNode("loadingOverlay").visible <> true then return
  m.skeletonBright = not m.skeletonBright
  DuplexPulseSkeleton(m.top.findNode("detailSkeleton"), m.skeletonBright)
end sub

sub stopDetailTask()
  if m.infoTask = invalid then return
  m.infoTask.unobserveField("result")
  m.infoTask.control = "stop"
  m.top.removeChild(m.infoTask)
  m.infoTask = invalid
end sub

sub startDetailLoad()
  stopDetailTask()
  m.infoTask = m.top.createChild("DetailInfoTask")
  m.infoTask.observeField("result", "onDetailInfo")
  m.infoTask.playlistId = DuplexLoadActivePlaylistId()
  m.infoTask.item = m.top.item
  m.infoTask.control = "RUN"
end sub

sub onDetailInfo()
  if m.infoTask = invalid then return
  result = m.infoTask.result
  if result = invalid or result.contentId = invalid then return
  hideDetailSkeleton()
  if result.favoriteId <> invalid then m.favoriteId = result.favoriteId
  if result.lockId <> invalid then m.lockId = result.lockId
  applyInfo(result.info)
  paintActions()
end sub

sub applyInfo(info as Object)
  if info = invalid then return
  movie = info
  if info.info <> invalid then movie = info.info
  plot = ""
  if movie.plot <> invalid and movie.plot <> "" then plot = movie.plot
  if plot = "" and movie.description <> invalid then plot = movie.description
  if plot <> "" then m.top.findNode("plot").text = plot
  genre = ""
  if movie.genre <> invalid then genre = movie.genre
  year = ""
  released = ""
  if movie.releasedate <> invalid then released = movie.releasedate.ToStr()
  if movie.releaseDate <> invalid and released = "" then released = movie.releaseDate.ToStr()
  if Len(released) >= 4 then year = Left(released, 4)
  duration = ""
  if movie.duration <> invalid then duration = movie.duration.ToStr()
  if genre <> "" or year <> "" or duration <> ""
    m.top.findNode("meta").text = joinBits([genre, year, duration])
  end if
  if movie.rating <> invalid and movie.rating.ToStr() <> ""
    m.top.findNode("starText").text = "★  " + movie.rating.ToStr()
  end if
  cast = formatCast(movie.cast)
  if cast = "" then cast = formatCast(movie.actors)
  if cast <> ""
    m.top.findNode("castNames").text = cast
    m.top.findNode("castRow").visible = true
  end if
  if info.movie_data <> invalid and info.movie_data.name <> invalid and info.movie_data.name <> ""
    m.top.findNode("title").text = info.movie_data.name
  else if info.name <> invalid and info.name <> ""
    m.top.findNode("title").text = info.name
  end if
  poster = ""
  if movie.movie_image <> invalid then poster = movie.movie_image
  if poster = "" and info.cover <> invalid then poster = info.cover
  if poster <> "" then m.top.findNode("poster").uri = poster
  backdrop = ""
  if movie.backdrop <> invalid then backdrop = movie.backdrop
  if backdrop = "" and info.backdropPath <> invalid then backdrop = info.backdropPath
  if backdrop <> "" then m.top.findNode("backdrop").uri = backdrop
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
  m.top.findNode("favOn").visible = (m.favoriteId <> "")
  m.top.findNode("lockOn").visible = (m.lockId <> "")
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
    if m.actionIndex = 0
      m.top.watchSelected = m.top.item
    else if not m.actionBusy
      if m.actionIndex = 1
        if m.favoriteId <> ""
          startLibraryAction("removeFavorite", m.favoriteId)
        else
          startLibraryAction("addFavorite", "")
        end if
      else
        if m.lockId <> ""
          startLibraryAction("removeLock", m.lockId)
        else
          startLibraryAction("addLock", "")
        end if
      end if
    end if
    return true
  end if
  return false
end function

sub startLibraryAction(action as String, recordId as String)
  if m.actionTask <> invalid
    m.actionTask.unobserveField("result")
    m.actionTask.control = "stop"
    m.top.removeChild(m.actionTask)
  end if
  m.actionBusy = true
  m.top.findNode("actionStatus").visible = true
  m.top.findNode("actionStatus").text = "Saving..."
  m.actionTask = m.top.createChild("LibraryActionTask")
  m.actionTask.observeField("result", "onLibraryAction")
  m.actionTask.action = action
  m.actionTask.playlistId = DuplexLoadActivePlaylistId()
  m.actionTask.item = m.top.item
  m.actionTask.recordId = recordId
  m.actionTask.control = "RUN"
end sub

sub onLibraryAction()
  if m.actionTask = invalid then return
  result = m.actionTask.result
  if result = invalid or result.action = invalid then return
  m.actionBusy = false
  if result.ok = true
    id = ""
    if result.recordId <> invalid then id = result.recordId
    if result.action = "addFavorite" or result.action = "removeFavorite" then m.favoriteId = id
    if result.action = "addLock" or result.action = "removeLock" then m.lockId = id
    m.top.findNode("actionStatus").visible = false
  else
    message = "Could not update"
    if result.error <> invalid and result.error <> "" then message = result.error
    m.top.findNode("actionStatus").text = message
    m.top.findNode("actionStatus").visible = true
  end if
  paintActions()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
