' ParentalPinPanel — Web EnterPinModal parity + real verifyParentalControlPin API
sub init()
  m.top.focusable = true
  m.pin = ""
  m.focus = 0 ' 0-9 keys, 10=Cancel, 11=Continue
  m.keys = ["0", "1", "2", "3", "4", "5", "6", "7", "8", "9"]
  m.busy = false

  styleLabel(m.top.findNode("title"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("status"), 18, "0xF97066FF")
  styleLabel(m.top.findNode("cancelLbl"), 24, "0xFFFFFFFF")
  styleLabel(m.top.findNode("continueLbl"), 24, "0x000000FF")
  for i = 0 to 3
    styleLabel(m.top.findNode("boxLbl" + i.ToStr()), 32, "0x9CA3AFFF")
  end for
  buildPad()
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

sub buildPad()
  root = m.top.findNode("padRoot")
  clearGroup(root)
  keyW = 64
  gapX = 20
  gapY = 16
  for i = 0 to 9
    col = i mod 5
    row = Int(i / 5)
    grp = root.createChild("Group")
    grp.translation = [col * (keyW + gapX), row * (keyW + gapY)]
    bg = grp.createChild("Poster")
    bg.width = keyW
    bg.height = keyW
    bg.uri = "pkg:/images/ui/pin-key.png"
    bg.loadDisplayMode = "scaleToFit"
    lbl = grp.createChild("Label")
    lbl.translation = [0, 14]
    lbl.width = keyW
    lbl.height = 36
    lbl.horizAlign = "center"
    lbl.vertAlign = "center"
    lbl.text = m.keys[i]
    lbl.font.size = 24
    lbl.color = "0xD6D8E0FF"
  end for
end sub

sub onPanelShown()
  m.top.backSelected = false
  m.top.unlockedSelected = false
  m.pin = ""
  m.focus = 0
  m.busy = false
  m.top.findNode("status").text = ""
  if m.top.mode = "setup"
    m.top.findNode("title").text = "Create a 4-digit PIN"
  else
    m.top.findNode("title").text = "Enter PIN to Continue"
  end if
  refreshUi()
  m.top.setFocus(true)
end sub

sub refreshUi()
  refreshBoxes()
  refreshPadFocus()
  refreshActions()
end sub

sub refreshBoxes()
  for i = 0 to 3
    pinBox = m.top.findNode("box" + i.ToStr())
    lbl = m.top.findNode("boxLbl" + i.ToStr())
    if i < Len(m.pin)
      lbl.text = "•"
      lbl.color = "0xFFFFFFFF"
      pinBox.uri = "pkg:/images/ui/pin-box.png"
    else
      lbl.text = "-"
      lbl.color = "0x9CA3AFFF"
      if i = Len(m.pin)
        pinBox.uri = "pkg:/images/ui/pin-box-active.png"
      else
        pinBox.uri = "pkg:/images/ui/pin-box.png"
      end if
    end if
  end for
end sub

sub refreshPadFocus()
  root = m.top.findNode("padRoot")
  for i = 0 to 9
    if i >= root.getChildCount() then exit for
    grp = root.getChild(i)
    if grp = invalid or grp.getChildCount() < 2 then exit for
    bg = grp.getChild(0)
    lbl = grp.getChild(1)
    focused = (m.focus = i)
    if focused
      bg.uri = "pkg:/images/ui/pin-key-focus.png"
      lbl.color = "0xFFFFFFFF"
    else
      bg.uri = "pkg:/images/ui/pin-key.png"
      lbl.color = "0xD6D8E0FF"
    end if
  end for
end sub

sub refreshActions()
  cancelFocus = (m.focus = 10)
  contFocus = (m.focus = 11)
  if cancelFocus
    m.top.findNode("cancelBg").uri = "pkg:/images/ui/pin-btn-cancel-focus.png"
  else
    m.top.findNode("cancelBg").uri = "pkg:/images/ui/pin-btn-cancel.png"
  end if
  if contFocus
    m.top.findNode("continueBg").uri = "pkg:/images/ui/pin-btn-continue-focus.png"
  else
    m.top.findNode("continueBg").uri = "pkg:/images/ui/pin-btn-continue.png"
  end if
  if Len(m.pin) = 4 and not m.busy
    m.top.findNode("continueLbl").color = "0x000000FF"
  else
    m.top.findNode("continueLbl").color = "0x888888FF"
  end if
end sub

sub appendDigit(digit as String)
  if m.busy then return
  if Len(m.pin) >= 4 then return
  m.pin = m.pin + digit
  m.top.findNode("status").text = ""
  if Len(m.pin) = 4 then m.focus = 11
  refreshUi()
end sub

function pinVerifySucceeded(result as Object) as Boolean
  if result = invalid then return false
  if result.error <> invalid then return false
  if result.data = invalid then return false
  value = result.data.verifyParentalControlPin
  if value = invalid then return false
  if type(value) = "Boolean" or type(value) = "roBoolean"
    return value = true
  end if
  ' Some backends return string/number
  if type(value) = "String" or type(value) = "roString"
    return LCase(value) = "true" or value = "1"
  end if
  return value = true or value = 1
end function

function pinSetSucceeded(result as Object) as Boolean
  if result = invalid then return false
  if result.error <> invalid then return false
  ' setParentalControlPin often returns boolean or null on success
  if result.data = invalid then return true
  value = result.data.setParentalControlPin
  if value = invalid then return true
  if type(value) = "Boolean" or type(value) = "roBoolean"
    return value = true
  end if
  return true
end function

sub submitPin()
  if m.busy then return
  if Len(m.pin) <> 4
    m.top.findNode("status").text = "Enter 4 digits"
    return
  end if

  m.busy = true
  m.top.findNode("status").text = "Verifying..."
  m.top.findNode("status").color = "0x9CA3AFFF"
  refreshActions()

  playlistId = DuplexLoadActivePlaylistId()
  DuplexLog("parental PIN submit mode=" + m.top.mode + " playlist=" + playlistId)

  ' Preview-only shortcut when there is no playlist session
  if playlistId = ""
    if DuplexIsDev() and Len(m.pin) = 4
      DuplexLog("parental PIN preview unlock (no playlist)")
      m.top.unlockedSelected = true
      m.busy = false
      return
    end if
    m.top.findNode("status").text = "No active playlist"
    m.top.findNode("status").color = "0xF97066FF"
    m.busy = false
    refreshUi()
    return
  end if

  if m.top.mode = "setup"
    result = DuplexSetParentalPin(m.pin, playlistId)
    DuplexLog("parental setPin result error=" + FormatJson(result))
    if pinSetSucceeded(result)
      m.top.unlockedSelected = true
      m.busy = false
      return
    end if
    msg = "Could not save PIN"
    if result <> invalid and result.error <> invalid then msg = result.error.ToStr()
    m.top.findNode("status").text = msg
    m.top.findNode("status").color = "0xF97066FF"
    m.pin = ""
    m.focus = 0
    m.busy = false
    refreshUi()
    return
  end if

  result = DuplexVerifyParentalPin(m.pin, playlistId)
  if result <> invalid and result.error <> invalid
    DuplexLog("parental verify error: " + result.error.ToStr())
  else if result <> invalid and result.data <> invalid
    DuplexLog("parental verify data: " + FormatJson(result.data))
  else
    DuplexLog("parental verify empty result")
  end if

  if pinVerifySucceeded(result)
    m.top.unlockedSelected = true
    m.busy = false
    return
  end if

  msg = "Incorrect PIN"
  if result <> invalid and result.error <> invalid then msg = result.error.ToStr()
  m.top.findNode("status").text = msg
  m.top.findNode("status").color = "0xF97066FF"
  m.pin = ""
  m.focus = 0
  m.busy = false
  refreshUi()
end sub

function movePad(focus as Integer, dir as String) as Integer
  if focus < 10
    row = Int(focus / 5)
    col = focus mod 5
    if dir = "left"
      if col = 0 then return focus
      return focus - 1
    end if
    if dir = "right"
      if col = 4 then return focus
      return focus + 1
    end if
    if dir = "up"
      if row = 0 then return focus
      return focus - 5
    end if
    if row = 0 then return focus + 5
    if col >= 3 then return 11
    return 10
  end if
  if dir = "left" then return 10
  if dir = "right" then return 11
  if dir = "down" then return focus
  if focus = 11 then return 8
  return 6
end function

function digitFromKey(key as String) as String
  if key = "0" or key = "1" or key = "2" or key = "3" or key = "4" or key = "5" or key = "6" or key = "7" or key = "8" or key = "9"
    return key
  end if
  return ""
end function

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if

  digit = digitFromKey(key)
  if digit <> ""
    appendDigit(digit)
    return true
  end if

  if key = "left" or key = "right" or key = "up" or key = "down"
    m.focus = movePad(m.focus, key)
    refreshUi()
    return true
  end if

  if key = "OK"
    if m.focus < 10
      appendDigit(m.keys[m.focus])
    else if m.focus = 10
      m.top.backSelected = true
    else
      submitPin()
    end if
    return true
  end if

  return true
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
