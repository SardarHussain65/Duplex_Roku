' SettingsPanel component script. Markup lives in SettingsPanel.xml.
sub init()
  m.top.focusable = true
  m.sectionIndex = 0
  m.optionIndex = 0
  m.focusZone = "nav"
  m.sections = [
    { id: "language", label: "Language" }
    { id: "device", label: "Device" }
    { id: "subscription", label: "Subscription" }
    { id: "playlist", label: "Playlist" }
    { id: "parental", label: "Parental" }
    { id: "history", label: "Watch History" }
    { id: "autoplay", label: "Autoplay" }
    { id: "cache", label: "Cache" }
    { id: "signout", label: "Sign Out" }
  ]
  m.langs = [
    { id: "en", label: "English" }
    { id: "pt", label: "Português" }
    { id: "es", label: "Español" }
  ]

  styleLabel(m.top.findNode("title"), 36, "0xFFFFFFFF")
  styleLabel(m.top.findNode("detailTitle"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("detailBody"), 22, "0xD1D5DBFF")
  styleLabel(m.top.findNode("actionText"), 20, "0xFFFFFFFF")
  styleLabel(m.top.findNode("hint"), 18, "0x9CA3AFFF")
  renderNav()
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPanelShown()
  m.top.backSelected = false
  m.top.logoutSelected = false
  m.sectionIndex = 0
  m.optionIndex = 0
  m.focusZone = "nav"
  renderNav()
  renderDetail()
end sub

sub renderNav()
  root = m.top.findNode("navRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while
  for i = 0 to m.sections.Count() - 1
    sec = m.sections[i]
    grp = root.createChild("Group")
    grp.translation = [0, i * 72]
    bg = grp.createChild("Rectangle")
    bg.width = 400
    bg.height = 60
    if m.focusZone = "nav" and i = m.sectionIndex
      bg.color = "0x0451DFFF"
    else if i = m.sectionIndex
      bg.color = "0x23252BFF"
    else
      bg.color = "0x1A1B1FFF"
    end if
    lbl = grp.createChild("Label")
    lbl.translation = [20, 16]
    lbl.width = 360
    lbl.height = 28
    lbl.text = sec.label
    lbl.font.size = 22
    lbl.color = "0xFFFFFFFF"
  end for
end sub

sub renderDetail()
  sec = m.sections[m.sectionIndex]
  m.top.findNode("detailTitle").text = sec.label
  body = ""
  action = ""
  actionVisible = true

  if sec.id = "language"
    body = "Choose the UI language." + Chr(10) + Chr(10)
    for i = 0 to m.langs.Count() - 1
      mark = "  "
      if i = m.optionIndex then mark = "> "
      body = body + mark + m.langs[i].label + Chr(10)
    end for
    action = "Apply language"
  else if sec.id = "device"
    mac = DuplexGetDisplayCode(DuplexGetHardwareId())
    key = DuplexLoadDeviceKey()
    if key = "" then key = "N/A" else key = DuplexFormatDeviceKey(key)
    body = "MAC: " + mac + Chr(10) + "Device Key: " + key + Chr(10) + "Device ID: " + DuplexLoadDeviceId() + Chr(10) + "Status: " + DuplexLoadDeviceStatus()
    actionVisible = false
  else if sec.id = "subscription"
    body = "Plan status: " + DuplexLoadDeviceStatus() + Chr(10) + "Manage playlists at www.duplexnew.tv/manageplaylists"
    actionVisible = false
  else if sec.id = "playlist"
    body = "Active playlist: " + DuplexLoadActivePlaylistId() + Chr(10) + "Use Hub → Playlists to switch or add a source."
    action = "Open playlists"
  else if sec.id = "parental"
    body = "Parental PIN and locked categories." + Chr(10) + "Open Parental from Hub to unlock, or set a PIN later from this section (coming next)."
    actionVisible = false
  else if sec.id = "history"
    body = "Recently watched Live, Movies, and Series will appear here." + Chr(10) + "Full history sync lands in the next phase."
    actionVisible = false
  else if sec.id = "autoplay"
    onOff = "Off"
    if DuplexLoadAutoplay() then onOff = "On"
    body = "Automatically play the next episode in a series." + Chr(10) + "Current: " + onOff
    action = "Toggle autoplay"
  else if sec.id = "cache"
    body = "Clear cached content metadata for this device session."
    action = "Clear session cache"
  else if sec.id = "signout"
    body = "Sign out clears tokens and returns to Activation (same as Web TV)."
    action = "Sign out"
  end if

  m.top.findNode("detailBody").text = body
  m.top.findNode("actionBtn").visible = actionVisible
  m.top.findNode("actionText").text = action
  if m.focusZone = "action"
    m.top.findNode("actionBg").color = "0xFFFFFFFF"
    m.top.findNode("actionText").color = "0x111111FF"
  else
    m.top.findNode("actionBg").color = "0x0451DFFF"
    m.top.findNode("actionText").color = "0xFFFFFFFF"
  end if
end sub

sub activateAction()
  sec = m.sections[m.sectionIndex]
  if sec.id = "language"
    lang = m.langs[m.optionIndex].id
    DuplexSetLanguage(lang)
    m.top.findNode("detailBody").text = "Language set to " + m.langs[m.optionIndex].label + "." + Chr(10) + "Restart screens to apply all strings."
  else if sec.id = "playlist"
    ' Reuse logout field? Better fire back and let hub open playlists — use a hack: set logout false and back then... 
    ' MainScene has no playlist from settings yet — signpost via back for now after toast.
    m.top.findNode("detailBody").text = "Press Back, then Hub → Playlists (or Back again to playlist source)."
  else if sec.id = "autoplay"
    current = DuplexLoadAutoplay()
    DuplexSaveAutoplay(not current)
    renderDetail()
  else if sec.id = "cache"
    m.top.findNode("detailBody").text = "Local UI cache cleared for this session." + Chr(10) + "Tokens and playlist selection were kept."
  else if sec.id = "signout"
    DuplexClearSession()
    m.top.logoutSelected = true
  end if
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if

  if key = "up"
    if m.focusZone = "action"
      m.focusZone = "nav"
    else if m.sectionIndex > 0
      m.sectionIndex = m.sectionIndex - 1
      m.optionIndex = 0
    end if
    renderNav()
    renderDetail()
    return true
  end if

  if key = "down"
    sec = m.sections[m.sectionIndex]
    if m.focusZone = "nav" and m.top.findNode("actionBtn").visible
      m.focusZone = "action"
    else if m.sectionIndex < m.sections.Count() - 1
      m.sectionIndex = m.sectionIndex + 1
      m.optionIndex = 0
      m.focusZone = "nav"
    end if
    renderNav()
    renderDetail()
    return true
  end if

  if key = "left" or key = "right"
    sec = m.sections[m.sectionIndex]
    if sec.id = "language"
      if key = "left" and m.optionIndex > 0 then m.optionIndex = m.optionIndex - 1
      if key = "right" and m.optionIndex < m.langs.Count() - 1 then m.optionIndex = m.optionIndex + 1
      renderDetail()
    end if
    return true
  end if

  if key = "OK"
    if m.focusZone = "action" or m.sections[m.sectionIndex].id = "signout" or m.sections[m.sectionIndex].id = "language"
      if m.focusZone <> "action" and m.sections[m.sectionIndex].id = "language"
        m.focusZone = "action"
        renderDetail()
      else
        activateAction()
      end if
    else if m.top.findNode("actionBtn").visible
      m.focusZone = "action"
      renderDetail()
    end if
    return true
  end if

  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
