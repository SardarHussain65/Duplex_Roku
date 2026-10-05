' PlaylistLoadingPanel — Web TV PlaylistLoadingScreen visual/copy parity.
sub init()
  m.top.focusable = true
  m.stepOrder = ["connecting", "liveTv", "movies", "series", "finalizing"]
  m.stepLabels = {
    connecting: "Connecting to playlist source"
    liveTv: "Loading Live TV channels"
    movies: "Loading movies"
    series: "Loading series"
    finalizing: "Preparing your home screen"
  }
  m.stepStatus = {}
  m.phase = "idle"
  m.spinFrame = 0
  m.spinIcons = []

  for each stepKey in m.stepOrder
    m.stepStatus[stepKey] = "pending"
  end for

  styleLabel(m.top.findNode("title"), 40, "0xFFFFFFFF")
  styleLabel(m.top.findNode("subtitle"), 22, "0xD1D5DBFF")
  styleLabel(m.top.findNode("errorIcon"), 36, "0xCC1C6AFF")
  styleLabel(m.top.findNode("errorTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("errorCopy"), 22, "0xD6D8E0FF")
  styleLabel(m.top.findNode("errorBackText"), 22, "0x111111FF")

  m.task = invalid

  m.spinTimer = m.top.createChild("Timer")
  m.spinTimer.duration = 0.12
  m.spinTimer.repeat = true
  m.spinTimer.observeField("fire", "onSpinTick")

  renderSteps()
  setTrackFill(0)
end sub

' Poster width 0 uses the bitmap's pixel size and draws past the track on 720p.
' Keep the fill at the track width and reveal it with the clip.
sub setTrackFill(w as Integer)
  if w < 0 then w = 0
  if w > 920 then w = 920
  fill = m.top.findNode("trackFill")
  clip = m.top.findNode("trackClip")
  if w = 0
    fill.visible = false
    clip.clippingRect = [0, 0, 0, 8]
    return
  end if
  fill.width = 920
  fill.visible = true
  clip.clippingRect = [0, 0, w, 8]
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPanelShown()
  playlist = m.top.playlist
  name = "your playlist"
  if playlist <> invalid and playlist.name <> invalid and playlist.name <> ""
    name = playlist.name
  end if
  m.top.findNode("title").text = "Preparing Your Playlist"
  m.top.findNode("subtitle").text = "Setting up " + name + " — this will only take a moment."

  m.top.findNode("loadingRoot").visible = true
  m.top.findNode("errorRoot").visible = false
  m.top.readySelected = false
  m.top.backSelected = false

  for i = 0 to m.stepOrder.Count() - 1
    m.stepStatus[m.stepOrder[i]] = "pending"
  end for
  m.phase = "loading"
  m.spinFrame = 0
  setTrackFill(0)
  renderSteps()
  m.spinTimer.control = "start"

  playlistId = ""
  if playlist <> invalid and playlist.id <> invalid
    playlistId = playlist.id
  end if

  if m.task <> invalid
    m.task.unobserveField("stepUpdate")
    m.task.unobserveField("complete")
    m.task.unobserveField("error")
    m.task.control = "stop"
    m.top.removeChild(m.task)
  end if
  m.task = m.top.createChild("PlaylistPrepareTask")
  m.task.observeField("stepUpdate", "onStepUpdate")
  m.task.observeField("complete", "onPrepareComplete")
  m.task.observeField("error", "onPrepareError")
  m.task.playlistId = playlistId
  m.task.control = "RUN"
end sub

sub onSpinTick()
  if m.phase <> "loading" then return
  m.spinFrame = (m.spinFrame + 1) mod 4
  uri = "pkg:/images/ui/load-step-spin-" + m.spinFrame.ToStr() + ".png"
  for each icon in m.spinIcons
    if icon <> invalid then icon.uri = uri
  end for
end sub

sub onStepUpdate()
  update = m.task.stepUpdate
  if update = invalid then return
  stepKey = update.stepKey
  status = update.status
  if stepKey <> invalid and status <> invalid
    m.stepStatus[stepKey] = status
    renderSteps()
    updateProgress()
  end if
end sub

sub updateProgress()
  doneCount = 0
  loadingCount = 0
  for i = 0 to m.stepOrder.Count() - 1
    st = m.stepStatus[m.stepOrder[i]]
    if st = "done"
      doneCount = doneCount + 1
    else if st = "loading"
      loadingCount = loadingCount + 1
    end if
  end for
  ' Partial credit for in-progress step (matches Web feel)
  pct = (doneCount + loadingCount * 0.45) / m.stepOrder.Count()
  w = Int(920 * pct)
  if w < 8 and pct > 0 then w = 8
  if w > 920 then w = 920
  setTrackFill(w)
end sub

sub renderSteps()
  root = m.top.findNode("stepsRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while
  m.spinIcons = []

  rowH = 64 ' ~28px gap matching Web card spacing
  for i = 0 to m.stepOrder.Count() - 1
    stepKey = m.stepOrder[i]
    status = m.stepStatus[stepKey]
    row = root.createChild("Group")
    row.translation = [0, i * rowH]

    icon = row.createChild("Poster")
    icon.width = 36
    icon.height = 36
    icon.loadDisplayMode = "scaleToFit"
    if status = "done"
      icon.uri = "pkg:/images/ui/load-step-done.png"
    else if status = "loading"
      icon.uri = "pkg:/images/ui/load-step-spin-" + m.spinFrame.ToStr() + ".png"
      m.spinIcons.Push(icon)
    else
      icon.uri = "pkg:/images/ui/load-step-pending.png"
    end if

    lbl = row.createChild("Label")
    lbl.translation = [56, 4]
    lbl.width = 780
    lbl.height = 32
    lbl.text = m.stepLabels[stepKey]
    lbl.font.size = 24
    if status = "done"
      lbl.color = "0xF4F5F6FF"
    else if status = "loading"
      lbl.color = "0xFFFFFFFF"
    else
      lbl.color = "0x777E90FF"
    end if
  end for
end sub

sub onPrepareComplete()
  if m.phase <> "loading" or m.task = invalid or m.task.complete <> true then return
  DuplexLog("playlist ready → hub")
  m.phase = "done"
  m.spinTimer.control = "stop"
  for i = 0 to m.stepOrder.Count() - 1
    m.stepStatus[m.stepOrder[i]] = "done"
  end for
  renderSteps()
  setTrackFill(920)
  m.top.readySelected = true
end sub

sub onPrepareError()
  if m.phase <> "loading" or m.task = invalid then return
  if m.task.error = invalid or m.task.error = "" then return
  m.spinTimer.control = "stop"
  showError(m.task.error)
end sub

sub showError(message as String)
  m.phase = "error"
  m.top.findNode("loadingRoot").visible = false
  m.top.findNode("errorRoot").visible = true
  if message = invalid or message = ""
    message = "Something went wrong while loading your playlist."
  end if
  m.top.findNode("errorCopy").text = message
end sub

function handleKeyEvent(key as String) as Boolean
  if m.top.findNode("errorRoot").visible
    if key = "OK" or key = "back"
      m.top.backSelected = true
      return true
    end if
    return false
  end if

  if key = "back"
    m.spinTimer.control = "stop"
    m.top.backSelected = true
    return true
  end if
  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
