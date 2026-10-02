' PlaylistLoadingPanel component script. Markup lives in PlaylistLoadingPanel.xml.
sub init()
  m.top.focusable = true
  m.stepOrder = ["connecting", "liveTv", "movies", "series", "finalizing"]
  m.stepLabels = {
    connecting: "Connecting to server"
    liveTv: "Loading Live TV"
    movies: "Loading Movies"
    series: "Loading Series"
    finalizing: "Finalizing setup"
  }
  m.stepStatus = {}
  m.phase = "idle"

  for each stepKey in m.stepOrder
    m.stepStatus[stepKey] = "pending"
  end for

  styleLabel(m.top.findNode("title"), 40, "0xFFFFFFFF")
  styleLabel(m.top.findNode("subtitle"), 22, "0xD1D5DBFF")
  styleLabel(m.top.findNode("errorIcon"), 36, "0xCC1C6AFF")
  styleLabel(m.top.findNode("errorTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("errorCopy"), 22, "0xD6D8E0FF")
  styleLabel(m.top.findNode("errorBackText"), 22, "0xFFFFFFFF")

  m.task = m.top.createChild("PlaylistPrepareTask")
  m.task.observeField("stepUpdate", "onStepUpdate")
  m.task.observeField("complete", "onPrepareComplete")
  m.task.observeField("error", "onPrepareError")

  renderSteps()
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
  m.top.findNode("subtitle").text = "Preparing " + name + "..."

  m.top.findNode("loadingRoot").visible = true
  m.top.findNode("errorRoot").visible = false

  for i = 0 to m.stepOrder.Count() - 1
    m.stepStatus[m.stepOrder[i]] = "pending"
  end for
  m.phase = "loading"
  m.top.findNode("trackFill").width = 0
  renderSteps()

  playlistId = ""
  if playlist <> invalid and playlist.id <> invalid
    playlistId = playlist.id
  end if

  m.task.playlistId = playlistId
  m.task.control = "RUN"
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
  for i = 0 to m.stepOrder.Count() - 1
    if m.stepStatus[m.stepOrder[i]] = "done"
      doneCount = doneCount + 1
    end if
  end for
  pct = doneCount / m.stepOrder.Count()
  m.top.findNode("trackFill").width = Int(920 * pct)
end sub

sub renderSteps()
  root = m.top.findNode("stepsRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while

  rowH = 56
  for i = 0 to m.stepOrder.Count() - 1
    stepKey = m.stepOrder[i]
    status = m.stepStatus[stepKey]
    row = root.createChild("Group")
    row.translation = [0, i * rowH]

    iconBg = row.createChild("Rectangle")
    iconBg.translation = [0, 2]
    iconBg.width = 36
    iconBg.height = 36
    if status = "done"
      iconBg.color = "0x0451DFFF"
    else if status = "loading"
      iconBg.color = "0x588BEAFF"
    else
      iconBg.color = "0x2A2D36FF"
    end if

    if status = "done"
      check = row.createChild("Label")
      check.translation = [8, 6]
      check.width = 24
      check.height = 24
      check.text = "OK"
      check.font.size = 14
      check.color = "0xFFFFFFFF"
    else if status = "loading"
      ring = row.createChild("Rectangle")
      ring.translation = [10, 10]
      ring.width = 16
      ring.height = 16
      ring.color = "0xFFFFFFFF"
    else
      dot = row.createChild("Rectangle")
      dot.translation = [14, 16]
      dot.width = 8
      dot.height = 8
      dot.color = "0x777E90FF"
    end if

    lbl = row.createChild("Label")
    lbl.translation = [56, 6]
    lbl.width = 760
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
  DuplexLog("playlist ready → hub")
  m.phase = "done"
  m.top.readySelected = true
end sub

sub onPrepareError()
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
    m.top.backSelected = true
    return true
  end if
  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
