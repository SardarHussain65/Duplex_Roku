' SettingsPanel — two-column Web TV parity (Duplex_Web_TV SettingsScreen)
sub init()
  m.top.focusable = true
  m.focusZone = "side"
  m.sectionIndex = 0
  m.bodyIndex = 0
  m.playlistTab = 0
  m.historyTab = 0
  m.playlists = []
  m.historyItems = []
  m.historyCounts = { LIVE: 0, MOVIE: 0, SERIES: 0 }
  m.parentalOn = false
  m.parentalHasPin = false
  m.autoplayOn = DuplexLoadAutoplay()
  m.currentLang = DuplexGetLanguage()
  m.settingsTask = invalid
  m.sectionLoading = false
  m.sectionError = ""
  m.pendingSection = ""
  if m.currentLang = invalid or m.currentLang = "" then m.currentLang = "en"

  m.sections = [
    { id: "language", label: "Language", sub: "Select your preferred language for the app interface", icon: "pkg:/images/ui/settings-icon-language.png" }
    { id: "cache", label: "Cache & Storage", sub: "Manage app cache and storage usage", icon: "pkg:/images/ui/settings-icon-cache.png" }
    { id: "device", label: "Device Info", sub: "Device details and account status", icon: "pkg:/images/ui/settings-icon-device.png" }
    { id: "subscription", label: "Subscription", sub: "View your current plan and expiry details", icon: "pkg:/images/ui/settings-icon-subscription.png" }
    { id: "playlist", label: "Playlist Management", sub: "Select and manage your playlists", icon: "pkg:/images/ui/settings-icon-playlist.png" }
    { id: "parental", label: "Parental Control", sub: "Manage content restrictions and PIN settings", icon: "pkg:/images/ui/settings-icon-parental.png" }
    { id: "history", label: "Watch History", sub: "Your recently watched content", icon: "pkg:/images/ui/settings-icon-history.png" }
    { id: "autoplay", label: "Autoplay Settings", sub: "Control how episodes and videos play automatically", icon: "pkg:/images/ui/settings-icon-autoplay.png" }
  ]

  m.langs = [
    { id: "en", title: "English", native: "English" }
    { id: "pt", title: "Portuguese", native: "Português" }
    { id: "es", title: "Spanish", native: "Español" }
  ]

  styleLabel(m.top.findNode("panelTitle"), 38, "0xFFFFFFFF")
  styleLabel(m.top.findNode("panelSub"), 22, "0x9E9E9EFF")
  styleLabel(m.top.findNode("clearHistoryText"), 18, "0xFFFFFFFF")
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub clearGroup(node as Object)
  if node = invalid then return
  while node.getChildCount() > 0
    node.removeChildIndex(0)
  end while
end sub

function bodyMax() as Integer
  sec = m.sections[m.sectionIndex].id
  if sec = "language" then return m.langs.Count()
  if sec = "cache" then return 1
  if sec = "device" then return 0
  if sec = "subscription" then return 0
  if sec = "playlist"
    return 2 + filteredPlaylists().Count()
  end if
  if sec = "parental" then return 2
  if sec = "history"
    return 1 + 3 + m.historyItems.Count()
  end if
  if sec = "autoplay" then return 1
  return 0
end function

function filteredPlaylists() as Object
  out = []
  for each p in m.playlists
    t = ""
    if p.type <> invalid then t = LCase(p.type.ToStr())
    isX = t = "xcode" or t = "xtream" or t = "xtream codes" or t = "xc"
    if m.playlistTab = 1
      if isX then out.Push(p)
    else
      if not isX then out.Push(p)
    end if
  end for
  return out
end function

sub onPanelShown()
  m.top.backSelected = false
  m.top.logoutSelected = false
  m.top.changePinSelected = false
  m.focusZone = "side"
  m.sectionIndex = 0
  m.bodyIndex = 0
  m.playlistTab = 0
  m.historyTab = 0
  m.currentLang = DuplexGetLanguage()
  if m.currentLang = invalid or m.currentLang = "" then m.currentLang = "en"
  m.autoplayOn = DuplexLoadAutoplay()
  loadSectionData()
  renderAll()
end sub

sub loadSectionData()
  stopSettingsTask()
  sec = m.sections[m.sectionIndex].id
  m.sectionError = ""
  m.sectionLoading = false
  if sec = "playlist" or sec = "parental" or sec = "history" or sec = "autoplay"
    if sec = "playlist" then m.playlists = []
    if sec = "history" then m.historyItems = []
    m.sectionLoading = true
    startSettingsTask("load")
  end if
end sub

sub loadHistory()
  m.historyItems = []
  m.sectionError = ""
  m.sectionLoading = true
  startSettingsTask("load")
end sub

sub stopSettingsTask()
  if m.settingsTask = invalid then return
  m.settingsTask.unobserveField("result")
  m.settingsTask.control = "stop"
  m.top.removeChild(m.settingsTask)
  m.settingsTask = invalid
end sub

sub startSettingsTask(action as String)
  stopSettingsTask()
  m.pendingSection = m.sections[m.sectionIndex].id
  m.settingsTask = m.top.createChild("SettingsLoadTask")
  m.settingsTask.observeField("result", "onSettingsResult")
  m.settingsTask.section = m.pendingSection
  m.settingsTask.action = action
  m.settingsTask.playlistId = DuplexLoadActivePlaylistId()
  m.settingsTask.deviceId = DuplexLoadDeviceId()
  types = ["LIVE", "MOVIE", "SERIES"]
  m.settingsTask.historyType = types[m.historyTab]
  m.settingsTask.autoplay = not m.autoplayOn
  m.settingsTask.control = "RUN"
end sub

sub onSettingsResult()
  if m.settingsTask = invalid then return
  result = m.settingsTask.result
  if result = invalid or result.section = invalid then return
  if result.section <> m.pendingSection then return
  m.sectionLoading = false
  m.sectionError = ""
  if result.error <> invalid and result.error <> "" then m.sectionError = result.error
  if result.playlists <> invalid then m.playlists = result.playlists
  if result.parentalOn <> invalid then m.parentalOn = (result.parentalOn = true)
  if result.parentalHasPin <> invalid then m.parentalHasPin = (result.parentalHasPin = true)
  if result.historyItems <> invalid then m.historyItems = result.historyItems
  if result.totalLive <> invalid then m.historyCounts.LIVE = result.totalLive
  if result.totalMovies <> invalid then m.historyCounts.MOVIE = result.totalMovies
  if result.totalSeries <> invalid then m.historyCounts.SERIES = result.totalSeries
  if result.autoplayOn <> invalid then m.autoplayOn = (result.autoplayOn = true)
  renderAll()
end sub

sub renderAll()
  renderSide()
  renderHeader()
  renderBody()
end sub

sub renderSide()
  root = m.top.findNode("sideNav")
  clearGroup(root)
  rowH = 64
  rowGap = 16
  iconSize = 28
  for i = 0 to m.sections.Count() - 1
    sec = m.sections[i]
    grp = root.createChild("Group")
    grp.translation = [0, i * (rowH + rowGap)]

    selected = (i = m.sectionIndex)
    focused = (m.focusZone = "side" and i = m.sectionIndex)

    if selected or focused
      chrome = grp.createChild("Poster")
      chrome.width = 340
      chrome.height = rowH
      chrome.uri = "pkg:/images/ui/settings-nav-selected.png"
      chrome.loadDisplayMode = "scaleToFill"
    end if

    ' Vertically center icon in 64px row (Web: align-items:center)
    icon = grp.createChild("Poster")
    icon.translation = [20, Int((rowH - iconSize) / 2)]
    icon.width = iconSize
    icon.height = iconSize
    icon.uri = sec.icon
    icon.loadDisplayMode = "scaleToFit"

    ' Full-row label with vertAlign center so text baselines match icons
    lbl = grp.createChild("Label")
    lbl.translation = [20 + iconSize + 16, 0]
    lbl.width = 280
    lbl.height = rowH
    lbl.text = sec.label
    lbl.font.size = 22
    lbl.vertAlign = "center"
    if selected or focused
      lbl.color = "0xFFFFFFFF"
    else
      lbl.color = "0xD6D8E0FF"
    end if
  end for
end sub

sub renderHeader()
  sec = m.sections[m.sectionIndex]
  m.top.findNode("panelTitle").text = sec.label
  m.top.findNode("panelSub").text = sec.sub
  clearBtn = m.top.findNode("clearHistoryBtn")
  isHistory = sec.id = "history"
  clearBtn.visible = isHistory
  ' Remove prior focus ring child if any (id clearFocusRing)
  oldRing = clearBtn.findNode("clearFocusRing")
  if oldRing <> invalid then clearBtn.removeChild(oldRing)
  m.top.findNode("clearHistoryText").color = "0xFFFFFFFF"
  m.top.findNode("clearHistoryIcon").blendColor = "0xFFFFFFFF"
  if isHistory and m.focusZone = "body" and m.bodyIndex = 0
    ring = clearBtn.createChild("Poster")
    ring.id = "clearFocusRing"
    ring.translation = [-8, -8]
    ring.width = 296
    ring.height = 72
    ring.uri = "pkg:/images/ui/settings-focus-ring.png"
    ring.loadDisplayMode = "scaleToFill"
  end if
end sub

sub renderBody()
  root = m.top.findNode("bodyRoot")
  clearGroup(root)
  sec = m.sections[m.sectionIndex].id
  if m.sectionLoading and (sec = "playlist" or sec = "parental" or sec = "history" or sec = "autoplay")
    for i = 0 to 3
      card = root.createChild("Rectangle")
      card.translation = [0, i * 112]
      card.width = 860
      card.height = 96
      card.color = "0x1C1E24FF"
      line = root.createChild("Rectangle")
      line.translation = [24, i * 112 + 28]
      line.width = 280
      line.height = 18
      line.color = "0x2A2E38FF"
      subLine = root.createChild("Rectangle")
      subLine.translation = [24, i * 112 + 56]
      subLine.width = 460
      subLine.height = 14
      subLine.color = "0x23262EFF"
    end for
    return
  end if
  if m.sectionError <> "" and (sec = "playlist" or sec = "parental" or sec = "history" or sec = "autoplay")
    lbl = root.createChild("Label")
    lbl.translation = [0, 80]
    lbl.width = 900
    lbl.height = 80
    lbl.wrap = true
    lbl.text = m.sectionError
    lbl.font.size = 24
    lbl.color = "0xF5C451FF"
    return
  end if
  if sec = "language"
    renderLanguage(root)
  else if sec = "cache"
    renderCache(root)
  else if sec = "device"
    renderDevice(root)
  else if sec = "subscription"
    renderSubscription(root)
  else if sec = "playlist"
    renderPlaylist(root)
  else if sec = "parental"
    renderParental(root)
  else if sec = "history"
    renderHistory(root)
  else if sec = "autoplay"
    renderAutoplay(root)
  end if
end sub

function isBodyFocused(index as Integer) as Boolean
  return m.focusZone = "body" and m.bodyIndex = index
end function

sub addFocusRing(parent as Object, w as Integer, h as Integer)
  ring = parent.createChild("Rectangle")
  ring.width = w
  ring.height = h
  ring.color = "0x00000000"
  ' Blue outline via nested rects (Roku Rectangle has no stroke) — use Poster ring when available
  outline = parent.createChild("Poster")
  outline.translation = [-8, -8]
  outline.width = w + 16
  outline.height = h + 16
  outline.uri = "pkg:/images/ui/settings-focus-ring.png"
  outline.loadDisplayMode = "scaleToFill"
end sub

sub addKvRow(parent as Object, y as Integer, labelText as String, valueText as String, valueColor as String, cardW as Integer)
  lab = parent.createChild("Label")
  lab.translation = [28, y]
  lab.width = 400
  lab.height = 28
  lab.text = labelText
  lab.font.size = 20
  lab.color = "0x9E9E9EFF"

  val = parent.createChild("Label")
  val.translation = [440, y]
  val.width = cardW - 468
  val.height = 28
  val.horizAlign = "right"
  val.text = valueText
  val.font.size = 20
  val.color = valueColor
end sub

sub renderLanguage(root as Object)
  cardW = 640
  cardH = 100
  gap = 22
  for i = 0 to m.langs.Count() - 1
    lang = m.langs[i]
    col = i mod 2
    row = Int(i / 2)
    grp = root.createChild("Group")
    grp.translation = [col * (cardW + gap), row * (cardH + gap)]

    bg = grp.createChild("Poster")
    bg.width = cardW
    bg.height = cardH
    bg.uri = "pkg:/images/ui/settings-lang-card.png"
    bg.loadDisplayMode = "scaleToFill"

    if isBodyFocused(i)
      addFocusRing(grp, cardW, cardH)
    end if

    title = grp.createChild("Label")
    title.translation = [24, 24]
    title.width = 500
    title.height = 28
    title.text = lang.title
    title.font.size = 22
    title.color = "0xFFFFFFFF"

    native = grp.createChild("Label")
    native.translation = [24, 54]
    native.width = 500
    native.height = 24
    native.text = lang.native
    native.font.size = 18
    native.color = "0x9E9E9EFF"

    if m.currentLang = lang.id
      check = grp.createChild("Poster")
      check.translation = [cardW - 52, Int((cardH - 24) / 2)]
      check.width = 24
      check.height = 24
      check.uri = "pkg:/images/ui/settings-check.png"
      check.loadDisplayMode = "scaleToFit"
    end if
  end for
end sub

sub renderCache(root as Object)
  cardW = 1400
  cardH = 280
  grp = root.createChild("Group")

  bg = grp.createChild("Poster")
  bg.width = cardW
  bg.height = cardH
  bg.uri = "pkg:/images/ui/settings-card-tall.png"
  bg.loadDisplayMode = "scaleToFill"

  title = grp.createChild("Label")
  title.translation = [28, 24]
  title.width = 600
  title.height = 28
  title.text = "Storage Usage"
  title.font.size = 22
  title.color = "0xFFFFFFFF"

  addKvRow(grp, 72, "Image Cache", "—", "0xFFFFFFFF", cardW)
  addKvRow(grp, 108, "Video Cache", "0 B", "0xFFFFFFFF", cardW)
  addKvRow(grp, 144, "EPG Data", "—", "0xFFFFFFFF", cardW)
  addKvRow(grp, 180, "App Data", "—", "0xFFFFFFFF", cardW)

  rule = grp.createChild("Rectangle")
  rule.translation = [28, 220]
  rule.width = cardW - 56
  rule.height = 1
  rule.color = "0xFFFFFF1A"

  totalLab = grp.createChild("Label")
  totalLab.translation = [28, 236]
  totalLab.width = 400
  totalLab.height = 28
  totalLab.text = "Total"
  totalLab.font.size = 20
  totalLab.color = "0xFFFFFFFF"

  totalVal = grp.createChild("Label")
  totalVal.translation = [440, 236]
  totalVal.width = cardW - 468
  totalVal.height = 28
  totalVal.horizAlign = "right"
  totalVal.text = "—"
  totalVal.font.size = 20
  totalVal.color = "0x588BEAFF"

  btn = root.createChild("Group")
  btn.translation = [0, cardH + 20]
  btnBg = btn.createChild("Poster")
  btnBg.width = 420
  btnBg.height = 64
  btnBg.uri = "pkg:/images/ui/settings-btn-danger.png"
  btnBg.loadDisplayMode = "scaleToFill"
  if isBodyFocused(0)
    addFocusRing(btn, 420, 64)
  end if
  ' Center icon + label as a group inside 420x64 button
  iconW = 20
  gap = 10
  textW = 170
  contentW = iconW + gap + textW
  startX = Int((420 - contentW) / 2)
  icon = btn.createChild("Poster")
  icon.translation = [startX, Int((64 - iconW) / 2)]
  icon.width = iconW
  icon.height = iconW
  icon.uri = "pkg:/images/ui/settings-trash.png"
  icon.loadDisplayMode = "scaleToFit"
  txt = btn.createChild("Label")
  txt.translation = [startX + iconW + gap, 0]
  txt.width = textW
  txt.height = 64
  txt.vertAlign = "center"
  txt.text = "Clear All Cache"
  txt.font.size = 20
  txt.color = "0xFFFFFFFF"
end sub

sub renderDevice(root as Object)
  mac = DuplexGetDisplayCode(DuplexGetHardwareId())
  if mac = "" then mac = "N/A"
  key = DuplexLoadDeviceKey()
  if key = "" then key = "N/A" else key = DuplexFormatDeviceKey(key)
  state = DuplexLoadDeviceStatus()
  if state = "" then state = "N/A"

  cardW = 1400
  cardH = 200
  grp = root.createChild("Group")
  bg = grp.createChild("Poster")
  bg.width = cardW
  bg.height = cardH
  bg.uri = "pkg:/images/ui/settings-card.png"
  bg.loadDisplayMode = "scaleToFill"

  title = grp.createChild("Label")
  title.translation = [28, 24]
  title.width = 600
  title.height = 28
  title.text = "Account Details"
  title.font.size = 22
  title.color = "0xFFFFFFFF"

  addKvRow(grp, 72, "Mac Address", mac, "0xFFFFFFFF", cardW)
  addKvRow(grp, 112, "Device Key", key, "0xFFFFFFFF", cardW)
  addKvRow(grp, 152, "Device State", UCase(state), "0xFFFFFFFF", cardW)
end sub

sub renderSubscription(root as Object)
  subJson = DuplexLoadSubscriptionJson()
  endDate = ""
  status = DuplexLoadDeviceStatus()
  if status = "" then status = "ACTIVE"
  if subJson <> ""
    parsed = ParseJson(subJson)
    if parsed <> invalid
      if parsed.endDate <> invalid then endDate = parsed.endDate.ToStr()
      if parsed.status <> invalid and parsed.status <> "" then status = parsed.status.ToStr()
    end if
  end if

  expiresLabel = formatSubDate(endDate)
  days = daysRemaining(endDate)
  planName = "Monthly Plan"
  if days > 180 then planName = "Yearly Plan"

  cardW = 1400
  cardH = 180
  grp = root.createChild("Group")
  bg = grp.createChild("Poster")
  bg.width = cardW
  bg.height = cardH
  bg.uri = "pkg:/images/ui/settings-card-mid.png"
  bg.loadDisplayMode = "scaleToFill"

  title = grp.createChild("Label")
  title.translation = [28, 24]
  title.width = 360
  title.height = 28
  title.text = planName
  title.font.size = 22
  title.color = "0xFFFFFFFF"

  badge = grp.createChild("Poster")
  badge.translation = [220, 24]
  badge.width = 90
  badge.height = 28
  badge.uri = "pkg:/images/ui/settings-badge-active.png"
  badge.loadDisplayMode = "scaleToFill"
  badgeTxt = grp.createChild("Label")
  badgeTxt.translation = [220, 26]
  badgeTxt.width = 90
  badgeTxt.height = 24
  badgeTxt.horizAlign = "center"
  badgeTxt.text = UCase(status)
  badgeTxt.font.size = 12
  badgeTxt.color = "0xFFFFFFFF"

  addKvRow(grp, 80, "Expires", expiresLabel, "0xFFFFFFFF", cardW)
  daysText = days.ToStr() + " Days"
  addKvRow(grp, 120, "Days Remaining", daysText, "0xF04438FF", cardW)
end sub

function formatSubDate(iso as String) as String
  if iso = invalid or iso = "" then return "—"
  ' Expect YYYY-MM-DD or full ISO; show short readable form
  parts = iso.Split("T")
  datePart = parts[0]
  bits = datePart.Split("-")
  if bits.Count() < 3 then return datePart
  months = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
  mi = bits[1].ToInt()
  if mi < 1 or mi > 12 then return datePart
  return months[mi - 1] + " " + bits[2].ToInt().ToStr() + ", " + bits[0]
end function

function daysRemaining(iso as String) as Integer
  if iso = invalid or iso = "" then return 0
  parts = iso.Split("T")
  datePart = parts[0]
  bits = datePart.Split("-")
  if bits.Count() < 3 then return 0
  ' Approximate via seconds since epoch using roDateTime
  endDt = CreateObject("roDateTime")
  endDt.fromISO8601String(iso)
  nowDt = CreateObject("roDateTime")
  nowDt.mark()
  diff = endDt.asSeconds() - nowDt.asSeconds()
  if diff <= 0 then return 0
  return Int((diff + 86399) / 86400)
end function

sub renderPlaylist(root as Object)
  ' Tabs
  tabs = ["Playlist URL", "Xtreme Codes"]
  for i = 0 to 1
    tabGrp = root.createChild("Group")
    tabGrp.translation = [i * 240, 0]
    tw = 220
    th = 56
    bg = tabGrp.createChild("Rectangle")
    bg.width = tw
    bg.height = th
    bg.color = "0x2A2D35FF"
    if m.playlistTab = i
      bg.color = "0xFFFFFFFF"
    end if
    if isBodyFocused(i)
      addFocusRing(tabGrp, tw, th)
    end if
    lbl = tabGrp.createChild("Label")
    lbl.translation = [0, 0]
    lbl.width = tw
    lbl.height = th
    lbl.horizAlign = "center"
    lbl.vertAlign = "center"
    lbl.text = tabs[i]
    lbl.font.size = 20
    if m.playlistTab = i
      lbl.color = "0x111111FF"
    else
      lbl.color = "0xFFFFFFFF"
    end if
  end for

  list = filteredPlaylists()
  activeId = DuplexLoadActivePlaylistId()
  y = 80
  cardW = 1400
  cardH = 100
  for i = 0 to list.Count() - 1
    p = list[i]
    bodyIdx = i + 2
    grp = root.createChild("Group")
    grp.translation = [0, y]
    bg = grp.createChild("Poster")
    bg.width = cardW
    bg.height = cardH
    bg.uri = "pkg:/images/ui/settings-playlist-row.png"
    bg.loadDisplayMode = "scaleToFill"
    if isBodyFocused(bodyIdx)
      addFocusRing(grp, cardW, cardH)
    end if

    icon = grp.createChild("Poster")
    icon.translation = [24, Int((cardH - 36) / 2)]
    icon.width = 36
    icon.height = 36
    icon.uri = "pkg:/images/ui/settings-layers.png"
    icon.loadDisplayMode = "scaleToFit"

    name = ""
    if p.name <> invalid then name = p.name.ToStr()
    url = ""
    if p.url <> invalid then url = p.url.ToStr()

    nameLbl = grp.createChild("Label")
    nameLbl.translation = [76, 22]
    nameLbl.width = 1200
    nameLbl.height = 28
    nameLbl.text = name
    nameLbl.font.size = 22
    nameLbl.color = "0xFFFFFFFF"

    urlLbl = grp.createChild("Label")
    urlLbl.translation = [76, 52]
    urlLbl.width = 1200
    urlLbl.height = 24
    urlLbl.text = url
    urlLbl.font.size = 16
    urlLbl.color = "0x9E9E9EFF"

    pid = ""
    if p.id <> invalid then pid = p.id.ToStr()
    if pid <> "" and pid = activeId
      check = grp.createChild("Poster")
      check.translation = [cardW - 52, Int((cardH - 24) / 2)]
      check.width = 24
      check.height = 24
      check.uri = "pkg:/images/ui/settings-check.png"
      check.loadDisplayMode = "scaleToFit"
    end if
    y = y + cardH + 16
  end for

  if list.Count() = 0
    empty = root.createChild("Label")
    empty.translation = [0, 90]
    empty.width = 800
    empty.height = 32
    empty.text = "No playlists in this tab."
    empty.font.size = 20
    empty.color = "0x9E9E9EFF"
  end if
end sub

sub renderParental(root as Object)
  cardW = 1400
  ' Enable row
  row1 = root.createChild("Group")
  bg1 = row1.createChild("Poster")
  bg1.width = cardW
  bg1.height = 120
  bg1.uri = "pkg:/images/ui/settings-card-row.png"
  bg1.loadDisplayMode = "scaleToFill"
  if isBodyFocused(0)
    addFocusRing(row1, cardW, 120)
  end if

  t1 = row1.createChild("Label")
  t1.translation = [28, 32]
  t1.width = 900
  t1.height = 28
  t1.text = "Enable Parental Control"
  t1.font.size = 22
  t1.color = "0xFFFFFFFF"

  s1 = row1.createChild("Label")
  s1.translation = [28, 66]
  s1.width = 900
  s1.height = 24
  s1.text = "Require PIN to access restricted content"
  s1.font.size = 18
  s1.color = "0x9E9E9EFF"

  tog = row1.createChild("Poster")
  tog.translation = [cardW - 100, 40]
  tog.width = 72
  tog.height = 40
  if m.parentalOn
    tog.uri = "pkg:/images/ui/settings-toggle-on.png"
  else
    tog.uri = "pkg:/images/ui/settings-toggle-off.png"
  end if
  tog.loadDisplayMode = "scaleToFit"

  ' Pin setting
  row2 = root.createChild("Group")
  row2.translation = [0, 140]
  bg2 = row2.createChild("Poster")
  bg2.width = cardW
  bg2.height = 160
  bg2.uri = "pkg:/images/ui/settings-card-mid.png"
  bg2.loadDisplayMode = "scaleToFill"
  if isBodyFocused(1)
    addFocusRing(row2, cardW, 160)
  end if

  t2 = row2.createChild("Label")
  t2.translation = [28, 24]
  t2.width = 400
  t2.height = 28
  t2.text = "Pin Setting"
  t2.font.size = 22
  t2.color = "0xFFFFFFFF"

  cur = row2.createChild("Label")
  cur.translation = [28, 58]
  cur.width = 400
  cur.height = 24
  cur.text = "Current Pin"
  cur.font.size = 18
  cur.color = "0x9E9E9EFF"

  pinBox = row2.createChild("Rectangle")
  pinBox.translation = [28, 92]
  pinBox.width = 900
  pinBox.height = 48
  pinBox.color = "0x14151AFF"
  pinTxt = row2.createChild("Label")
  pinTxt.translation = [44, 102]
  pinTxt.width = 860
  pinTxt.height = 28
  if m.parentalHasPin
    pinTxt.text = "****"
  else
    pinTxt.text = "Not set"
  end if
  pinTxt.font.size = 20
  pinTxt.color = "0xFFFFFFFF"

  btn = row2.createChild("Group")
  btn.translation = [948, 88]
  btnBg = btn.createChild("Poster")
  btnBg.width = 220
  btnBg.height = 56
  btnBg.uri = "pkg:/images/ui/settings-btn-white.png"
  btnBg.loadDisplayMode = "scaleToFill"
  ' Center lock icon + "Change Pin" text in white button
  lockW = 20
  gap = 8
  textW = 110
  contentW = lockW + gap + textW
  startX = Int((220 - contentW) / 2)
  lock = btn.createChild("Poster")
  lock.translation = [startX, Int((56 - lockW) / 2)]
  lock.width = lockW
  lock.height = lockW
  lock.uri = "pkg:/images/ui/settings-lock.png"
  lock.loadDisplayMode = "scaleToFit"
  btnTxt = btn.createChild("Label")
  btnTxt.translation = [startX + lockW + gap, 0]
  btnTxt.width = textW
  btnTxt.height = 56
  btnTxt.vertAlign = "center"
  btnTxt.text = "Change Pin"
  btnTxt.font.size = 18
  btnTxt.color = "0x111111FF"
end sub

sub renderHistory(root as Object)
  types = [
    { key: "LIVE", label: "Live TV", count: m.historyCounts.LIVE }
    { key: "MOVIE", label: "Movies", count: m.historyCounts.MOVIE }
    { key: "SERIES", label: "Series", count: m.historyCounts.SERIES }
  ]
  for i = 0 to 2
    tabGrp = root.createChild("Group")
    tabGrp.translation = [i * 220, 0]
    tw = 200
    th = 52
    bg = tabGrp.createChild("Rectangle")
    bg.width = tw
    bg.height = th
    selected = (m.historyTab = i)
    if selected
      bg.color = "0xFFFFFFFF"
    else
      bg.color = "0x2A2D35FF"
    end if
    ' body index: 0 = clear, 1-3 = tabs
    if isBodyFocused(i + 1)
      addFocusRing(tabGrp, tw, th)
    end if
    lbl = tabGrp.createChild("Label")
    lbl.translation = [0, 0]
    lbl.width = tw
    lbl.height = th
    lbl.horizAlign = "center"
    lbl.vertAlign = "center"
    count = 0
    if types[i].count <> invalid then count = types[i].count
    lbl.text = types[i].label + " (" + count.ToStr() + ")"
    lbl.font.size = 18
    if selected
      lbl.color = "0x111111FF"
    else
      lbl.color = "0xFFFFFFFF"
    end if
  end for

  y = 80
  cardW = 680
  cardH = 100
  gap = 20
  for i = 0 to m.historyItems.Count() - 1
    item = m.historyItems[i]
    col = i mod 2
    row = Int(i / 2)
    bodyIdx = i + 4
    grp = root.createChild("Group")
    grp.translation = [col * (cardW + gap), y + row * (cardH + gap)]
    bg = grp.createChild("Poster")
    bg.width = cardW
    bg.height = cardH
    bg.uri = "pkg:/images/ui/settings-lang-card.png"
    bg.loadDisplayMode = "scaleToFill"
    if isBodyFocused(bodyIdx)
      addFocusRing(grp, cardW, cardH)
    end if

    dateStr = historyDateLabel(item)
    name = ""
    if item.name <> invalid then name = item.name.ToStr()
    typeLabel = "Live"
    if item.type <> invalid
      t = UCase(item.type.ToStr())
      if t = "MOVIE" then typeLabel = "Movie"
      if t = "SERIES" then typeLabel = "Series"
    end if

    d = grp.createChild("Label")
    d.translation = [24, 18]
    d.width = 600
    d.height = 22
    d.text = dateStr
    d.font.size = 16
    d.color = "0x9E9E9EFF"

    n = grp.createChild("Label")
    n.translation = [24, 42]
    n.width = 620
    n.height = 28
    n.text = name
    n.font.size = 20
    n.color = "0xFFFFFFFF"

    ty = grp.createChild("Label")
    ty.translation = [24, 70]
    ty.width = 600
    ty.height = 22
    ty.text = typeLabel
    ty.font.size = 16
    ty.color = "0x9E9E9EFF"
  end for

  if m.historyItems.Count() = 0
    empty = root.createChild("Label")
    empty.translation = [0, 90]
    empty.width = 800
    empty.height = 32
    empty.text = "No watch history for this filter."
    empty.font.size = 20
    empty.color = "0x9E9E9EFF"
  end if
end sub

function historyDateLabel(item as Object) as String
  iso = ""
  if item.lastWatchedAt <> invalid then iso = item.lastWatchedAt.ToStr()
  if iso = "" then return "--"
  parts = iso.Split("T")
  datePart = parts[0]
  bits = datePart.Split("-")
  if bits.Count() < 3 then return datePart
  yy = bits[0]
  if yy.Len() >= 2 then yy = yy.Right(2)
  return bits[2] + "-" + bits[1] + "-" + yy
end function

sub renderAutoplay(root as Object)
  cardW = 1400
  grp = root.createChild("Group")
  bg = grp.createChild("Poster")
  bg.width = cardW
  bg.height = 120
  bg.uri = "pkg:/images/ui/settings-card-row.png"
  bg.loadDisplayMode = "scaleToFill"
  if isBodyFocused(0)
    addFocusRing(grp, cardW, 120)
  end if

  t = grp.createChild("Label")
  t.translation = [28, 32]
  t.width = 1000
  t.height = 28
  t.text = "Enable Autoplay"
  t.font.size = 22
  t.color = "0xFFFFFFFF"

  s = grp.createChild("Label")
  s.translation = [28, 66]
  s.width = 1000
  s.height = 24
  s.text = "Automatically play the next episode after the current one finishes."
  s.font.size = 18
  s.color = "0x9E9E9EFF"

  tog = grp.createChild("Poster")
  tog.translation = [cardW - 100, 40]
  tog.width = 72
  tog.height = 40
  if m.autoplayOn
    tog.uri = "pkg:/images/ui/settings-toggle-on.png"
  else
    tog.uri = "pkg:/images/ui/settings-toggle-off.png"
  end if
  tog.loadDisplayMode = "scaleToFit"
end sub

sub activateBody()
  sec = m.sections[m.sectionIndex].id
  idx = m.bodyIndex

  if sec = "language"
    if idx >= 0 and idx < m.langs.Count()
      lang = m.langs[idx]
      DuplexSetLanguage(lang.id)
      m.currentLang = lang.id
      renderAll()
    end if
    return
  end if

  if sec = "cache"
    ' Best-effort local clear signal; tokens/playlist kept
    DuplexLog("settings: clear cache requested")
    renderAll()
    return
  end if

  if sec = "playlist"
    if idx = 0 or idx = 1
      m.playlistTab = idx
      m.bodyIndex = idx
      renderAll()
      return
    end if
    list = filteredPlaylists()
    pIdx = idx - 2
    if pIdx >= 0 and pIdx < list.Count()
      p = list[pIdx]
      pid = ""
      if p.id <> invalid then pid = p.id.ToStr()
      if pid <> "" and pid <> DuplexLoadActivePlaylistId()
        m.top.playlistSelected = p
      end if
    end if
    return
  end if

  if sec = "parental"
    playlistId = DuplexLoadActivePlaylistId()
    if idx = 0
      if not m.parentalOn and not m.parentalHasPin
        m.top.changePinSelected = true
        return
      end if
      if playlistId <> ""
        m.sectionLoading = true
        m.sectionError = ""
        renderAll()
        startSettingsTask("toggleParental")
        return
      end if
      m.parentalOn = not m.parentalOn
      renderAll()
    else
      m.top.changePinSelected = true
    end if
    return
  end if

  if sec = "history"
    if idx = 0
      playlistId = DuplexLoadActivePlaylistId()
      if playlistId <> ""
        m.historyItems = []
        m.sectionLoading = true
        m.sectionError = ""
        renderAll()
        startSettingsTask("clearHistory")
        return
      end if
      m.historyItems = []
      renderAll()
      return
    end if
    if idx >= 1 and idx <= 3
      m.historyTab = idx - 1
      loadHistory()
      m.bodyIndex = idx
      renderAll()
      return
    end if
    return
  end if

  if sec = "autoplay"
    m.sectionLoading = true
    m.sectionError = ""
    renderAll()
    startSettingsTask("toggleAutoplay")
  end if
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if

  maxBody = bodyMax()

  if key = "left"
    if m.focusZone = "body"
      m.focusZone = "side"
      renderAll()
      return true
    end if
    return true
  end if

  if key = "right"
    if m.focusZone = "side" and maxBody > 0
      m.focusZone = "body"
      m.bodyIndex = 0
      renderAll()
      return true
    end if
    if m.focusZone = "body"
      sec = m.sections[m.sectionIndex].id
      if sec = "language" and m.bodyIndex mod 2 = 0 and m.bodyIndex + 1 < maxBody
        m.bodyIndex = m.bodyIndex + 1
        renderAll()
      else if sec = "history" and m.bodyIndex >= 4
        ' move to next card in row
        if (m.bodyIndex - 4) mod 2 = 0 and m.bodyIndex + 1 < maxBody
          m.bodyIndex = m.bodyIndex + 1
          renderAll()
        end if
      end if
    end if
    return true
  end if

  if key = "up"
    if m.focusZone = "side"
      if m.sectionIndex > 0
        m.sectionIndex = m.sectionIndex - 1
        m.bodyIndex = 0
        loadSectionData()
        renderAll()
      end if
      return true
    end if
    ' body
    sec = m.sections[m.sectionIndex].id
    if sec = "language"
      if m.bodyIndex >= 2
        m.bodyIndex = m.bodyIndex - 2
        renderAll()
      else
        m.focusZone = "side"
        renderAll()
      end if
    else if sec = "history"
      if m.bodyIndex >= 4
        ' up within grid or to tabs
        prev = m.bodyIndex - 2
        if prev < 4 then prev = m.historyTab + 1
        m.bodyIndex = prev
        renderAll()
      else if m.bodyIndex >= 1
        m.bodyIndex = 0
        renderAll()
      else
        m.focusZone = "side"
        renderAll()
      end if
    else if sec = "playlist"
      if m.bodyIndex >= 2
        m.bodyIndex = m.bodyIndex - 1
        if m.bodyIndex < 2 then m.bodyIndex = m.playlistTab
        renderAll()
      else if m.bodyIndex > 0
        m.bodyIndex = 0
        renderAll()
      else
        m.focusZone = "side"
        renderAll()
      end if
    else if m.bodyIndex > 0
      m.bodyIndex = m.bodyIndex - 1
      renderAll()
    else
      m.focusZone = "side"
      renderAll()
    end if
    return true
  end if

  if key = "down"
    if m.focusZone = "side"
      if m.sectionIndex < m.sections.Count() - 1
        m.sectionIndex = m.sectionIndex + 1
        m.bodyIndex = 0
        loadSectionData()
        renderAll()
      else if maxBody > 0
        m.focusZone = "body"
        m.bodyIndex = 0
        renderAll()
      end if
      return true
    end if
    sec = m.sections[m.sectionIndex].id
    if sec = "language"
      if m.bodyIndex + 2 < maxBody
        m.bodyIndex = m.bodyIndex + 2
        renderAll()
      end if
    else if sec = "history"
      if m.bodyIndex = 0 and maxBody > 1
        m.bodyIndex = m.historyTab + 1
        renderAll()
      else if m.bodyIndex >= 1 and m.bodyIndex <= 3
        if maxBody > 4
          m.bodyIndex = 4
          renderAll()
        end if
      else if m.bodyIndex + 2 < maxBody
        m.bodyIndex = m.bodyIndex + 2
        renderAll()
      end if
    else if m.bodyIndex + 1 < maxBody
      m.bodyIndex = m.bodyIndex + 1
      renderAll()
    end if
    return true
  end if

  if key = "OK"
    if m.focusZone = "side"
      if maxBody > 0
        m.focusZone = "body"
        m.bodyIndex = 0
        renderAll()
      end if
      return true
    end if
    activateBody()
    return true
  end if

  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
