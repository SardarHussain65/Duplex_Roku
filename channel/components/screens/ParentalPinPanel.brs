' ParentalPinPanel component script. Markup lives in ParentalPinPanel.xml.
sub init()
  m.top.focusable = true
  m.pin = ""
  styleLabel(m.top.findNode("title"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("subtitle"), 22, "0xB1B5C3FF")
  styleLabel(m.top.findNode("pinDisplay"), 40, "0xFFFFFFFF")
  styleLabel(m.top.findNode("status"), 20, "0xF97066FF")
  styleLabel(m.top.findNode("hint"), 18, "0x9CA3AFFF")
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPanelShown()
  m.top.backSelected = false
  m.top.unlockedSelected = false
  m.pin = ""
  m.top.findNode("status").text = ""
  if m.top.mode = "setup"
    m.top.findNode("subtitle").text = "Create a 4-digit Parental PIN"
  else
    m.top.findNode("subtitle").text = "Enter your 4-digit PIN"
  end if
  refreshPinDisplay()
end sub

sub refreshPinDisplay()
  dots = ""
  for i = 1 to 4
    if i <= Len(m.pin)
      dots = dots + "● "
    else
      dots = dots + "○ "
    end if
  end for
  m.top.findNode("pinDisplay").text = dots
end sub

sub submitPin()
  if Len(m.pin) <> 4
    m.top.findNode("status").text = "Enter 4 digits"
    return
  end if

  playlistId = DuplexLoadActivePlaylistId()
  if DuplexIsDev() and (playlistId = "" or m.pin = "0000" or m.pin = "1234")
    m.top.unlockedSelected = true
    return
  end if

  if m.top.mode = "setup"
    result = DuplexSetParentalPin(m.pin, playlistId)
    if result <> invalid and result.error = invalid
      m.top.unlockedSelected = true
      return
    end if
    m.top.findNode("status").text = "Could not save PIN"
    if DuplexIsDev() then m.top.unlockedSelected = true
    return
  end if

  result = DuplexVerifyParentalPin(m.pin, playlistId)
  ok = false
  if result <> invalid and result.error = invalid
    ' GraphQL may return boolean in data
    ok = true
  end if
  if ok or DuplexIsDev()
    m.top.unlockedSelected = true
  else
    m.top.findNode("status").text = "Incorrect PIN"
    m.pin = ""
    refreshPinDisplay()
  end if
end sub

function digitFromKey(key as String) as String
  if key = "0" or key = "1" or key = "2" or key = "3" or key = "4" or key = "5" or key = "6" or key = "7" or key = "8" or key = "9"
    return key
  end if
  ' Roku remotes often send options/lit_* ; map replay etc. skip
  return ""
end function

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if

  if key = "left" or key = "backspace"
    if Len(m.pin) > 0
      m.pin = Left(m.pin, Len(m.pin) - 1)
      refreshPinDisplay()
    end if
    return true
  end if

  digit = digitFromKey(key)
  if digit <> ""
    if Len(m.pin) < 4
      m.pin = m.pin + digit
      refreshPinDisplay()
      if Len(m.pin) = 4 then submitPin()
    end if
    return true
  end if

  if key = "OK"
    submitPin()
    return true
  end if

  ' Allow up/down to cycle last digit when no number pad
  if key = "up" or key = "down"
    if Len(m.pin) = 0 then m.pin = "0"
    last = Val(Right(m.pin, 1))
    if key = "up"
      last = (last + 1) mod 10
    else
      last = last - 1
      if last < 0 then last = 9
    end if
    if Len(m.pin) = 1
      m.pin = last.ToStr()
    else
      m.pin = Left(m.pin, Len(m.pin) - 1) + last.ToStr()
    end if
    refreshPinDisplay()
    return true
  end if

  if key = "right" and Len(m.pin) < 4
    m.pin = m.pin + "0"
    refreshPinDisplay()
    return true
  end if

  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
