' XtreamSetupPanel component script. Markup lives in XtreamSetupPanel.xml.
sub init()
  m.top.focusable = true
  m.playlistType = "XC"
  m.focusId = "tabXc"
  m.keyboardOpen = false
  m.kbMode = "alpha"
  m.kbShift = false
  m.kbRow = 0
  m.kbCol = 0
  m.loading = false
  m.fieldKeys = ["playlistName", "serverUrl", "username", "password"]
  m.fieldValues = { playlistName: "", serverUrl: "", username: "", password: "" }
  m.placeholders = {
    playlistName: "Enter playlist name"
    serverUrl: "http://example.com:8080"
    username: "Enter username"
    password: "Enter password"
  }

  styleLabel(m.top.findNode("title"), 36, "0xFFFFFFFF")
  styleLabel(m.top.findNode("subtitle"), 20, "0x9CA3AFFF")
  styleLabel(m.top.findNode("pillMac"), 16, "0xB1B5C3FF")
  styleLabel(m.top.findNode("pillKey"), 16, "0xB1B5C3FF")
  styleLabel(m.top.findNode("tabXcText"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("tabUrlText"), 22, "0x777E90FF")
  styleLabel(m.top.findNode("errorLabel"), 20, "0xFF5252FF")
  styleLabel(m.top.findNode("cancelText"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("confirmText"), 22, "0x777E90FF")
  styleLabel(m.top.findNode("kbFieldLabel"), 18, "0xE6E8ECFF")
  styleLabel(m.top.findNode("kbFieldValue"), 22, "0xFFFFFFFF")

  for i = 0 to 3
    styleLabel(m.top.findNode("label" + i.ToStr()), 18, "0xE6E8ECFF")
    styleLabel(m.top.findNode("input" + i.ToStr()), 22, "0x6B7280FF")
  end for

  m.task = m.top.createChild("XtreamCreateTask")
  m.task.observeField("response", "onCreateSuccess")
  m.task.observeField("error", "onCreateError")

  refreshIdentityPill()
  applyPlaylistType()
  updateAllFieldDisplays()
  updateFocusVisuals()
end sub

sub onPanelShown()
  m.fieldValues = { playlistName: "", serverUrl: "", username: "", password: "" }
  m.playlistType = "XC"
  m.focusId = "tabXc"
  m.keyboardOpen = false
  m.loading = false
  m.top.findNode("errorLabel").visible = false
  closeKeyboard()
  refreshIdentityPill()
  applyPlaylistType()
  updateAllFieldDisplays()
  updateFocusVisuals()
  scene = m.top.getScene()
  if scene <> invalid
    scene.setFocus(true)
  end if
  DuplexLog("xtream setup ready — arrows move focus, OK opens keyboard")
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub refreshIdentityPill()
  mac = DuplexGetDisplayCode(DuplexGetHardwareId())
  key = DuplexLoadDeviceKey()
  if key = ""
    keyText = "N/A"
  else
    keyText = DuplexFormatDeviceKey(key)
  end if
  m.top.findNode("pillMac").text = "MAC Address: " + mac
  m.top.findNode("pillKey").text = "Device Key: " + keyText
end sub

function focusOrder() as Object
  if m.playlistType = "XC"
    return ["tabXc", "tabUrl", "field0", "field1", "field2", "field3", "cancel", "confirm"]
  end if
  return ["tabXc", "tabUrl", "field0", "field1", "cancel", "confirm"]
end function

function fieldKeyForIndex(index as Integer) as String
  return m.fieldKeys[index]
end function

sub applyPlaylistType()
  isXc = m.playlistType = "XC"
  m.top.findNode("title").text = iff(isXc, "Add Xtream Codes Playlist", "Add URL Playlist")
  m.top.findNode("subtitle").text = iff(isXc, "Enter your Xtream Codes server details to add a new playlist.", "Enter a direct M3U or playlist URL to add a new source.")
  m.top.findNode("label1").text = iff(isXc, "Server DNS", "Playlist URL")
  m.top.findNode("input1").text = iff(isXc, m.placeholders.serverUrl, "http://example.com/get.php?...")
  m.top.findNode("label2").visible = isXc
  m.top.findNode("input2Bg").visible = isXc
  m.top.findNode("input2").visible = isXc
  m.top.findNode("label3").visible = isXc
  m.top.findNode("input3Bg").visible = isXc
  m.top.findNode("input3").visible = isXc

  if isXc
    m.top.findNode("tabXcBg").color = "0x23262FFF"
    m.top.findNode("tabXcText").color = "0xFFFFFFFF"
    m.top.findNode("tabUrlBg").color = "0x00000001"
    m.top.findNode("tabUrlText").color = "0x777E90FF"
  else
    m.top.findNode("tabUrlBg").color = "0x23262FFF"
    m.top.findNode("tabUrlText").color = "0xFFFFFFFF"
    m.top.findNode("tabXcBg").color = "0x00000001"
    m.top.findNode("tabXcText").color = "0x777E90FF"
  end if
end sub

function iff(cond as Boolean, whenTrue as String, whenFalse as String) as String
  if cond then return whenTrue
  return whenFalse
end function

sub updateFieldDisplay(index as Integer)
  key = fieldKeyForIndex(index)
  value = m.fieldValues[key]
  placeholder = m.placeholders[key]
  if index = 1 and m.playlistType = "URL"
    placeholder = "http://example.com/get.php?..."
  end if

  labelNode = m.top.findNode("input" + index.ToStr())
  if value = ""
    labelNode.text = placeholder
    labelNode.color = "0x6B7280FF"
  else if key = "password"
    labelNode.text = stringRepeat("•", len(value))
    labelNode.color = "0xFFFFFFFF"
  else
    labelNode.text = value
    labelNode.color = "0xFFFFFFFF"
  end if
end sub

function stringRepeat(ch as String, count as Integer) as String
  out = ""
  for i = 1 to count
    out = out + ch
  end for
  return out
end function

sub updateAllFieldDisplays()
  for i = 0 to 3
    updateFieldDisplay(i)
  end for
end sub

function isFormValid() as Boolean
  if m.loading then return false
  if m.fieldValues.playlistName = "" or m.fieldValues.serverUrl = "" then return false
  if m.playlistType = "XC"
    if m.fieldValues.username = "" or m.fieldValues.password = "" then return false
  end if
  return true
end function

sub updateFocusVisuals()
  tabXcFocused = m.focusId = "tabXc"
  tabUrlFocused = m.focusId = "tabUrl"
  xcActive = m.playlistType = "XC"

  ' Active tab fill + strong focus ring (blue) when focused
  if xcActive
    m.top.findNode("tabXcBg").color = "0x23262FFF"
    m.top.findNode("tabUrlBg").color = "0x00000001"
  else
    m.top.findNode("tabUrlBg").color = "0x23262FFF"
    m.top.findNode("tabXcBg").color = "0x00000001"
  end if

  if tabXcFocused
    m.top.findNode("tabXcBg").color = "0x0451DFFF"
    m.top.findNode("tabXcText").color = "0xFFFFFFFF"
  else
    m.top.findNode("tabXcText").color = iff(xcActive, "0xFFFFFFFF", "0x777E90FF")
  end if

  if tabUrlFocused
    m.top.findNode("tabUrlBg").color = "0x0451DFFF"
    m.top.findNode("tabUrlText").color = "0xFFFFFFFF"
  else
    m.top.findNode("tabUrlText").color = iff(not xcActive, "0xFFFFFFFF", "0x777E90FF")
  end if

  for i = 0 to 3
    fieldId = "field" + i.ToStr()
    ring = m.top.findNode("input" + i.ToStr() + "Ring")
    bg = m.top.findNode("input" + i.ToStr() + "Bg")
    if ring <> invalid
      if m.focusId = fieldId
        ring.color = "0x588BEAFF"
        ring.visible = true
        if bg <> invalid then bg.color = "0x1A2744FF"
      else
        ring.visible = false
        if bg <> invalid then bg.color = "0x1C1E24FF"
      end if
    end if
  end for

  cancelFocused = m.focusId = "cancel"
  confirmFocused = m.focusId = "confirm"
  valid = isFormValid()

  if cancelFocused
    m.top.findNode("cancelBg").color = "0xFFFFFFFF"
    m.top.findNode("cancelText").color = "0x111111FF"
  else
    m.top.findNode("cancelBg").color = "0x1C1E24FF"
    m.top.findNode("cancelText").color = "0xFFFFFFFF"
  end if

  if confirmFocused
    if valid
      m.top.findNode("confirmBg").color = "0xFFFFFFFF"
      m.top.findNode("confirmText").color = "0x111111FF"
    else
      m.top.findNode("confirmBg").color = "0x588BEAFF"
      m.top.findNode("confirmText").color = "0xFFFFFFFF"
    end if
  else if valid
    m.top.findNode("confirmBg").color = "0x353945FF"
    m.top.findNode("confirmText").color = "0xFFFFFFFF"
  else
    m.top.findNode("confirmBg").color = "0x353945FF"
    m.top.findNode("confirmText").color = "0x777E90FF"
  end if
end sub

sub moveFocus(delta as Integer)
  order = focusOrder()
  index = 0
  for i = 0 to order.Count() - 1
    if order[i] = m.focusId
      index = i
      exit for
    end if
  end for
  index = index + delta
  if index < 0 then index = 0
  if index >= order.Count() then index = order.Count() - 1
  m.focusId = order[index]
  updateFocusVisuals()
end sub

sub openKeyboard(fieldIndex as Integer)
  m.keyboardOpen = true
  m.activeFieldIndex = fieldIndex
  m.kbMode = "alpha"
  m.kbShift = false
  m.kbRow = 0
  m.kbCol = 0

  m.top.findNode("headerGroup").visible = false
  m.top.findNode("formRoot").visible = false
  m.top.findNode("actionsRoot").visible = false
  m.top.findNode("keyboardHeader").visible = true
  m.top.findNode("keyboardRoot").visible = true

  key = fieldKeyForIndex(fieldIndex)
  m.top.findNode("kbFieldLabel").text = m.top.findNode("label" + fieldIndex.ToStr()).text
  updateKeyboardFieldDisplay()
  renderKeyboard()
  scene = m.top.getScene()
  if scene <> invalid
    scene.setFocus(true)
  end if
end sub

sub closeKeyboard()
  m.keyboardOpen = false
  m.top.findNode("headerGroup").visible = true
  m.top.findNode("formRoot").visible = true
  m.top.findNode("actionsRoot").visible = true
  m.top.findNode("keyboardHeader").visible = false
  m.top.findNode("keyboardRoot").visible = false
  clearKeyboardKeys()
  updateAllFieldDisplays()
  updateFocusVisuals()
end sub

sub updateKeyboardFieldDisplay()
  key = fieldKeyForIndex(m.activeFieldIndex)
  value = m.fieldValues[key]
  node = m.top.findNode("kbFieldValue")
  if key = "password" and value <> ""
    node.text = stringRepeat("•", len(value))
  else
    node.text = value
  end if
  node.color = "0xFFFFFFFF"
end sub

sub clearKeyboardKeys()
  root = m.top.findNode("keyboardRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while
end sub

sub renderKeyboard()
  clearKeyboardKeys()
  root = m.top.findNode("keyboardRoot")
  layout = DuplexKeyboardLayout(m.kbMode)
  keyW = 84
  keyH = 52
  gap = 6

  for row = 0 to layout.Count() - 1
    rowKeys = layout[row]
    rowW = rowKeys.Count() * keyW + (rowKeys.Count() - 1) * gap
    startX = (920 - rowW) / 2
    for col = 0 to rowKeys.Count() - 1
      token = rowKeys[col]
      grp = root.createChild("Group")
      grp.translation = [startX + col * (keyW + gap), row * (keyH + gap)]
      bg = grp.createChild("Rectangle")
      bg.width = keyW
      bg.height = keyH
      if row = m.kbRow and col = m.kbCol
        bg.color = "0x588BEAFF"
      else
        bg.color = "0x23262FFF"
      end if
      lbl = grp.createChild("Label")
      lbl.translation = [0, 14]
      lbl.width = keyW
      lbl.height = 28
      lbl.horizAlign = "center"
      lbl.font.size = 18
      lbl.color = "0xFFFFFFFF"
      lbl.text = DuplexKeyboardDisplayToken(token, m.kbShift, m.kbMode)
    end for
  end for
end sub

sub applyKeyboardToken(token as String)
  key = fieldKeyForIndex(m.activeFieldIndex)
  current = m.fieldValues[key]
  result = DuplexKeyboardApplyToken(current, token, m.kbShift, m.kbMode)
  m.fieldValues[key] = result.value
  m.kbShift = result.shift
  m.kbMode = result.mode
  updateKeyboardFieldDisplay()
  updateFieldDisplay(m.activeFieldIndex)
  renderKeyboard()
  if result.done
    closeKeyboard()
  end if
end sub

sub appendToActiveField(ch as String)
  if not startsWith(m.focusId, "field") then return
  index = val(mid(m.focusId, 6))
  key = fieldKeyForIndex(index)
  m.fieldValues[key] = m.fieldValues[key] + ch
  updateFieldDisplay(index)
end sub

sub backspaceActiveField()
  if not startsWith(m.focusId, "field") then return
  index = val(mid(m.focusId, 6))
  key = fieldKeyForIndex(index)
  value = m.fieldValues[key]
  if len(value) > 0
    m.fieldValues[key] = left(value, len(value) - 1)
    updateFieldDisplay(index)
  end if
end sub

function startsWith(text as String, prefix as String) as Boolean
  return left(text, len(prefix)) = prefix
end function

sub submitForm()
  if not isFormValid() then return
  deviceId = DuplexLoadDeviceId()
  if deviceId = ""
    m.top.findNode("errorLabel").text = "Device not registered. Go back and try again."
    m.top.findNode("errorLabel").visible = true
    return
  end if

  m.loading = true
  m.top.findNode("errorLabel").visible = false
  m.top.findNode("confirmText").text = "Adding..."
  updateFocusVisuals()

  input = {
    deviceId: deviceId
    isPinRequired: false
    name: m.fieldValues.playlistName
    type: m.playlistType
    url: m.fieldValues.serverUrl
  }
  if m.playlistType = "XC"
    input.username = m.fieldValues.username
    input.password = m.fieldValues.password
  end if

  m.task.input = input
  m.task.control = "RUN"
end sub

sub onCreateSuccess()
  m.loading = false
  m.top.findNode("confirmText").text = "Confirm"
  payload = m.task.response
  if payload = invalid then return

  playlist = {
    id: payload.id
    name: payload.name
    url: m.fieldValues.serverUrl
    type: m.playlistType
    isPinRequired: false
  }
  print "Duplex: playlist created " + playlist.name
  m.top.playlistCreated = playlist
end sub

sub onCreateError()
  m.loading = false
  m.top.findNode("confirmText").text = "Confirm"
  err = m.task.error
  print "Duplex: create playlist failed - " + err
  m.top.findNode("errorLabel").text = err
  m.top.findNode("errorLabel").visible = true
  updateFocusVisuals()
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function

function handleKeyEvent(key as String) as Boolean
  if m.loading
    if key = "back"
      return true
    end if
    return false
  end if

  if m.keyboardOpen
    layout = DuplexKeyboardLayout(m.kbMode)
    if key = "back"
      closeKeyboard()
      return true
    else if key = "up" or key = "down" or key = "left" or key = "right"
      moveDir = key
      cursorPos = DuplexKeyboardMoveCursor(layout, m.kbRow, m.kbCol, moveDir)
      m.kbRow = cursorPos.row
      m.kbCol = cursorPos.col
      renderKeyboard()
      return true
    else if key = "OK"
      token = layout[m.kbRow][m.kbCol]
      applyKeyboardToken(token)
      return true
    else if len(key) = 1 and key >= "0" and key <= "9"
      applyKeyboardToken(key)
      return true
    end if
    return false
  end if

  if key = "back"
    m.top.backSelected = true
    return true
  end if

  if key = "left"
    if m.focusId = "tabUrl"
      m.focusId = "tabXc"
    else if m.focusId = "confirm"
      m.focusId = "cancel"
    end if
    updateFocusVisuals()
    return true
  end if

  if key = "right"
    if m.focusId = "tabXc"
      m.focusId = "tabUrl"
    else if m.focusId = "cancel"
      m.focusId = "confirm"
    end if
    updateFocusVisuals()
    return true
  end if

  if key = "up"
    moveFocus(-1)
    return true
  end if

  if key = "down"
    moveFocus(1)
    return true
  end if

  if len(key) = 1 and key >= "0" and key <= "9"
    if startsWith(m.focusId, "field")
      appendToActiveField(key)
      return true
    end if
  end if

  if key = "OK"
    if m.focusId = "tabXc"
      m.playlistType = "XC"
      applyPlaylistType()
      updateFocusVisuals()
    else if m.focusId = "tabUrl"
      m.playlistType = "URL"
      applyPlaylistType()
      updateFocusVisuals()
    else if startsWith(m.focusId, "field")
      index = val(mid(m.focusId, 6))
      openKeyboard(index)
    else if m.focusId = "cancel"
      m.top.backSelected = true
    else if m.focusId = "confirm"
      submitForm()
    end if
    return true
  end if

  return false
end function
