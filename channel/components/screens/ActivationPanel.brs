' ActivationPanel — Web TV ActivationScreen parity (trial/active/expired/blocked/inactive).
sub init()
  m.top.focusable = true
  m.focusIndex = 0
  m.exitFocus = 0
  m.exitConfirmOpen = false
  m.screenState = "trial"
  m.hasPlaylist = false
  m.expiryDays = 0
  m.actions = ["continue", "quickSetup"]
  m.loading = true
  m.subscription = invalid

  styleLabel(m.top.findNode("heading"), 34, "0xFFFFFFFF")
  styleLabel(m.top.findNode("copy"), 20, "0xFFFFFFFF")
  styleLabel(m.top.findNode("bannerTitle"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("bannerSub"), 18, "0xD3F2C6FF")
  styleLabel(m.top.findNode("macLabel"), 16, "0x8E8E93FF")
  styleLabel(m.top.findNode("deviceLabel"), 16, "0x8E8E93FF")
  styleLabel(m.top.findNode("macValue"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("deviceValue"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("qrHint"), 16, "0x8E8E93FF")
  styleLabel(m.top.findNode("warning"), 18, "0xF97066FF")
  styleLabel(m.top.findNode("footerCopy"), 18, "0xFFFFFFFF")
  styleLabel(m.top.findNode("btn0Text"), 22, "0x111111FF")
  styleLabel(m.top.findNode("btn1Text"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("exitTitle"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("exitMsg"), 20, "0xB1B5C3FF")
  styleLabel(m.top.findNode("exitNoText"), 20, "0xFFFFFFFF")
  styleLabel(m.top.findNode("exitYesText"), 20, "0x111111FF")

  m.hardwareId = DuplexGetHardwareId()
  m.top.findNode("macValue").text = DuplexGetDisplayCode(m.hardwareId)
  m.top.findNode("qrCode").uri = DuplexActivationQrUrl(m.hardwareId)
  m.top.findNode("deviceValue").text = "LOADING..."

  m.task = m.top.createChild("ActivationTask")
  m.task.observeField("response", "onRegisterSuccess")
  m.task.observeField("error", "onRegisterError")

  applyScreenState()
  startRegister()
end sub

sub onPanelShown()
  m.focusIndex = 0
  m.exitConfirmOpen = false
  m.top.findNode("exitConfirm").visible = false
  m.top.continueSelected = false
  m.top.quickSetupSelected = false
  m.top.refreshSelected = false
  m.top.exitSelected = false
  applyScreenState()
  scene = m.top.getScene()
  if scene <> invalid then scene.setFocus(true)
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub startRegister()
  m.loading = true
  m.top.findNode("deviceValue").text = "LOADING..."
  m.task.hardwareId = m.hardwareId
  m.task.control = "RUN"
end sub

function expiryDaysFrom(endDate as Dynamic) as Integer
  if endDate = invalid then return 0
  endStr = endDate.ToStr()
  if endStr = "" then return 0
  endDt = CreateObject("roDateTime")
  endDt.FromISO8601String(endStr)
  nowDt = CreateObject("roDateTime")
  nowDt.Mark()
  diff = endDt.AsSeconds() - nowDt.AsSeconds()
  days = Int((diff + 86399) / 86400)
  if days > 0 then return days
  return 0
end function

sub deriveScreenState(errorMessage as String)
  msg = LCase(errorMessage)
  if msg <> ""
    if Instr(1, msg, "cors") > 0 or Instr(1, msg, "fetch") > 0 or Instr(1, msg, "network") > 0
      ' transport error — keep current / trial
    else if Instr(1, msg, "suspend") > 0 or Instr(1, msg, "block") > 0 or Instr(1, msg, "auth") > 0 or Instr(1, msg, "unauthenticated") > 0
      m.screenState = "blocked"
      return
    else if Instr(1, msg, "inactive") > 0
      m.screenState = "inactive"
      return
    else if Instr(1, msg, "expire") > 0
      m.screenState = "expired"
      return
    end if
  end if

  if m.subscription = invalid
    m.screenState = "trial"
    return
  end if

  subStatus = ""
  if m.subscription.status <> invalid
    subStatus = UCase(m.subscription.status.ToStr())
  end if

  if subStatus = "SUSPENDED" or subStatus = "CANCELLED" or subStatus = "BLOCKED"
    m.screenState = "blocked"
  else if subStatus = "EXPIRED"
    m.screenState = "expired"
  else if subStatus = "ACTIVE"
    m.screenState = "active"
  else
    m.screenState = "trial"
  end if
end sub

sub rebuildActions()
  state = m.screenState
  if state = "blocked"
    m.actions = ["refresh", "exit"]
  else if state = "inactive" or state = "expired"
    m.actions = ["exit"]
  else if m.hasPlaylist = false and (state = "trial" or state = "active")
    if m.expiryDays > 0
      m.actions = ["continue"]
    else
      m.actions = ["continue", "quickSetup"]
    end if
  else
    m.actions = ["continue"]
  end if
  m.focusIndex = m.actions.Count() - 1
  if m.focusIndex < 0 then m.focusIndex = 0
end sub

sub applyScreenState()
  rebuildActions()

  title = "Your MAC is Activated!"
  if m.screenState = "expired"
    title = "License Expired!"
  else if m.screenState = "blocked"
    title = "Device Blocked!"
  else if m.screenState = "inactive"
    title = "Device Inactive!"
  else if m.screenState = "active"
    title = "Welcome back!"
  else if m.expiryDays > 0
    title = "Your subscription will expire in " + m.expiryDays.ToStr() + " days"
  end if
  m.top.findNode("heading").text = title

  copyNode = m.top.findNode("copy")
  if m.screenState = "expired"
    copyNode.text = "Please contact your license reseller to activate Or visit www.duplexnew.tv/activate for more info." + Chr(10) + "You can activate 6-Months | 1 Year | Lifetime plan."
  else if m.screenState = "blocked"
    copyNode.text = "Please contact your license reseller/admin to unblock your device."
  else if m.screenState = "inactive"
    copyNode.text = "Device is inactive by admin. Please contact admin."
  else
    copyNode.text = "Visit our website www.duplexnew.tv/manageplaylists to add/manage playlists."
  end if

  showIds = (m.screenState <> "inactive")
  showTrialBanner = (m.screenState = "trial" and m.expiryDays = 0)
  showWarning = (m.screenState = "trial" and m.expiryDays = 0)
  showPlansFooter = (m.screenState = "expired")

  m.top.findNode("bannerGroup").visible = showTrialBanner
  if showTrialBanner
    m.top.findNode("bannerTitle").text = "7-Day Free Trial Active!"
    m.top.findNode("bannerSub").text = "Enjoy your 7-day free trial! Activation will be required when the trial ends."
  end if

  m.top.findNode("idsGroup").visible = showIds
  m.top.findNode("warning").visible = showWarning and showIds
  m.top.findNode("footerCopy").visible = showPlansFooter and showIds

  ' Vertical packing so blocked/expired don't leave a huge gap
  yCopy = 196
  yBanner = 310
  yIds = 420
  yWarn = 700
  yBtns = 800
  if not showTrialBanner
    yIds = 310
    yWarn = 590
    yBtns = 680
  end if
  if not showIds
    yBtns = 420
  end if
  if showTrialBanner then m.top.findNode("bannerGroup").translation = [0, yBanner]
  m.top.findNode("idsGroup").translation = [0, yIds]
  m.top.findNode("warning").translation = [0, yWarn]
  m.top.findNode("footerCopy").translation = [50, yWarn]

  layoutButtons(yBtns)
  updateFocus()
end sub

function actionLabel(actionId as String) as String
  if actionId = "refresh" then return "Refresh"
  if actionId = "quickSetup" then return "Quick Setup (Xtreme Codes)"
  if actionId = "continue" then return "Continue"
  if actionId = "exit" then return "Exit App"
  return actionId
end function

function actionIsOutline(actionId as String, actionCount as Integer) as Boolean
  if actionId = "refresh" then return true
  if actionId = "continue" and actionCount > 1 then return true
  return false
end function

sub layoutButtons(yBtns as Integer)
  count = m.actions.Count()
  btn0 = m.top.findNode("btn0")
  btn1 = m.top.findNode("btn1")
  btn0.visible = count >= 1
  btn1.visible = count >= 2

  if count = 1
    btn0.translation = [0, yBtns]
    m.top.findNode("btn0Bg").width = 960
    m.top.findNode("btn0Bg").height = 64
    m.top.findNode("btn0Text").width = 960
    m.top.findNode("btn0Text").text = actionLabel(m.actions[0])
  else if count >= 2
    w0 = 380
    w1 = 564
    btn0.translation = [0, yBtns]
    btn1.translation = [w0 + 16, yBtns]
    m.top.findNode("btn0Bg").width = w0
    m.top.findNode("btn0Bg").height = 64
    m.top.findNode("btn0Text").width = w0
    m.top.findNode("btn1Bg").width = w1
    m.top.findNode("btn1Bg").height = 64
    m.top.findNode("btn1Text").width = w1
    m.top.findNode("btn0Text").text = actionLabel(m.actions[0])
    m.top.findNode("btn1Text").text = actionLabel(m.actions[1])
  end if
end sub

function buttonUri(width as Integer, focused as Boolean, outline as Boolean) as String
  w = width.ToStr()
  if focused then return "pkg:/images/ui/btn-white-" + w + ".png"
  if outline then return "pkg:/images/ui/btn-outline-" + w + ".png"
  return "pkg:/images/ui/btn-dark-" + w + ".png"
end function

sub paintButton(index as Integer, focused as Boolean)
  if index < 0 or index >= m.actions.Count() then return
  actionId = m.actions[index]
  outline = actionIsOutline(actionId, m.actions.Count())
  if index = 0
    bg = m.top.findNode("btn0Bg")
    txt = m.top.findNode("btn0Text")
  else
    bg = m.top.findNode("btn1Bg")
    txt = m.top.findNode("btn1Text")
  end if

  w = Int(bg.width)
  bg.uri = buttonUri(w, focused, outline)
  if focused
    txt.color = "0x111111FF"
  else
    txt.color = "0xFFFFFFFF"
  end if
end sub

sub updateFocus()
  paintButton(0, m.focusIndex = 0)
  if m.actions.Count() > 1
    paintButton(1, m.focusIndex = 1)
  end if
end sub

sub updateExitFocus()
  if m.exitFocus = 0
    m.top.findNode("exitNoBg").uri = "pkg:/images/ui/btn-white-280.png"
    m.top.findNode("exitNoText").color = "0x111111FF"
    m.top.findNode("exitYesBg").uri = "pkg:/images/ui/btn-dark-280.png"
    m.top.findNode("exitYesText").color = "0xFFFFFFFF"
  else
    m.top.findNode("exitNoBg").uri = "pkg:/images/ui/btn-outline-280.png"
    m.top.findNode("exitNoText").color = "0xFFFFFFFF"
    m.top.findNode("exitYesBg").uri = "pkg:/images/ui/btn-white-280.png"
    m.top.findNode("exitYesText").color = "0x111111FF"
  end if
end sub

sub onRegisterSuccess()
  payload = m.task.response
  m.loading = false
  if payload = invalid then return

  device = payload.device
  if device <> invalid
    if device.deviceKey <> invalid
      DuplexSaveDeviceKey(device.deviceKey)
      m.top.findNode("deviceValue").text = DuplexFormatDeviceKey(device.deviceKey)
    else
      m.top.findNode("deviceValue").text = "N/A"
    end if
    if device.id <> invalid then DuplexSaveDeviceId(device.id)
    if device.status <> invalid then DuplexSaveDeviceStatus(device.status)
  end if

  if payload.hasPlaylist = true
    m.hasPlaylist = true
  else
    m.hasPlaylist = false
  end if

  m.subscription = payload.subscription
  if m.subscription <> invalid
    DuplexSaveSubscriptionJson(FormatJson(m.subscription))
    m.expiryDays = expiryDaysFrom(m.subscription.endDate)
  else
    m.expiryDays = 0
  end if

  ' Device blocked flag
  if device <> invalid
    if device.status <> invalid and LCase(device.status.ToStr()) = "blocked"
      m.screenState = "blocked"
      applyScreenState()
      DuplexLog("device registered (blocked)")
      return
    end if
  end if
  if m.subscription <> invalid and m.subscription.status <> invalid
    if LCase(m.subscription.status.ToStr()) = "blocked"
      m.screenState = "blocked"
      applyScreenState()
      DuplexLog("device registered (blocked)")
      return
    end if
  end if

  deriveScreenState("")
  applyScreenState()
  DuplexLog("device registered → " + m.screenState)
end sub

sub onRegisterError()
  err = m.task.error
  if err = invalid then err = "Activation failed"
  m.loading = false
  print "Duplex: registration failed - " + err
  m.top.findNode("deviceValue").text = "Unavailable"
  deriveScreenState(err)
  applyScreenState()
  m.top.findNode("warning").text = err
  m.top.findNode("warning").visible = true
end sub

sub runFocusedAction()
  if m.focusIndex < 0 or m.focusIndex >= m.actions.Count() then return
  actionId = m.actions[m.focusIndex]
  if actionId = "continue"
    m.top.continueSelected = true
  else if actionId = "quickSetup"
    m.top.quickSetupSelected = true
  else if actionId = "refresh"
    startRegister()
    m.top.refreshSelected = true
  else if actionId = "exit"
    openExitConfirm()
  end if
end sub

sub openExitConfirm()
  m.exitConfirmOpen = true
  m.exitFocus = 1
  m.top.findNode("exitConfirm").visible = true
  updateExitFocus()
end sub

sub closeExitConfirm()
  m.exitConfirmOpen = false
  m.top.findNode("exitConfirm").visible = false
end sub

function handleKeyEvent(key as String) as Boolean
  if m.exitConfirmOpen
    if key = "left"
      m.exitFocus = 0
      updateExitFocus()
      return true
    else if key = "right"
      m.exitFocus = 1
      updateExitFocus()
      return true
    else if key = "back"
      closeExitConfirm()
      return true
    else if key = "OK"
      if m.exitFocus = 1
        m.top.exitSelected = true
      else
        closeExitConfirm()
      end if
      return true
    end if
    return true
  end if

  if key = "back"
    openExitConfirm()
    return true
  end if

  if key = "left"
    m.focusIndex = m.focusIndex - 1
    if m.focusIndex < 0 then m.focusIndex = 0
    updateFocus()
    return true
  else if key = "right"
    m.focusIndex = m.focusIndex + 1
    if m.focusIndex > m.actions.Count() - 1 then m.focusIndex = m.actions.Count() - 1
    updateFocus()
    return true
  else if key = "OK"
    runFocusedAction()
    return true
  end if

  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
