' ActivationPanel component script. Markup lives in ActivationPanel.xml.
sub init()
  m.top.focusable = true
  m.focusIndex = 0
  m.buttons = ["continueBtn", "quickSetupBtn"]

  styleLabel(m.top.findNode("heading"), 34, "0xFFFFFFFF")
  styleLabel(m.top.findNode("copy"), 20, "0xFFFFFFFF")
  styleLabel(m.top.findNode("bannerTitle"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("bannerSub"), 18, "0xD3F2C6FF")
  styleLabel(m.top.findNode("macLabel"), 16, "0x9BA1A6FF")
  styleLabel(m.top.findNode("deviceLabel"), 16, "0x9BA1A6FF")
  styleLabel(m.top.findNode("macValue"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("deviceValue"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("qrHint"), 16, "0x9BA1A6FF")
  styleLabel(m.top.findNode("warning"), 18, "0xF97066FF")
  styleLabel(m.top.findNode("continueText"), 22, "0xFFFFFFFF")
  styleLabel(m.top.findNode("quickSetupText"), 22, "0xFFFFFFFF")

  m.hardwareId = DuplexGetHardwareId()
  displayCode = DuplexGetDisplayCode(m.hardwareId)
  m.top.findNode("macValue").text = displayCode
  m.top.findNode("qrCode").uri = DuplexActivationQrUrl(m.hardwareId)

  m.task = m.top.createChild("ActivationTask")
  m.task.observeField("response", "onRegisterSuccess")
  m.task.observeField("error", "onRegisterError")
  m.task.hardwareId = m.hardwareId
  m.task.control = "RUN"

  updateFocus()
end sub

sub onPanelShown()
  m.focusIndex = 0
  m.top.continueSelected = false
  m.top.quickSetupSelected = false
  updateFocus()
  scene = m.top.getScene()
  if scene <> invalid
    scene.setFocus(true)
  end if
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onRegisterSuccess()
  payload = m.task.response
  if payload = invalid then return
  device = payload.device
  if device <> invalid
    if device.deviceKey <> invalid
      DuplexSaveDeviceKey(device.deviceKey)
      m.top.findNode("deviceValue").text = DuplexFormatDeviceKey(device.deviceKey)
    end if
    if device.id <> invalid
      DuplexSaveDeviceId(device.id)
    end if
    if device.status <> invalid
      DuplexSaveDeviceStatus(device.status)
    end if
  end if

  applySubscriptionBanner(payload)
  m.top.findNode("warning").visible = true
  DuplexLog("device registered")
end sub

sub applySubscriptionBanner(payload as Object)
  bannerTitle = m.top.findNode("bannerTitle")
  bannerSub = m.top.findNode("bannerSub")
  bannerBg = m.top.findNode("bannerBg")

  device = payload.device
  subscription = payload.subscription
  status = ""
  if device <> invalid and device.status <> invalid
    status = LCase(device.status.ToStr())
  end if

  isBlocked = status = "blocked"
  hasUsedTrial = false
  isTrial = false
  if device <> invalid
    if device.hasUsedTrial = true then hasUsedTrial = true
    if device.isTrial = true then isTrial = true
  end if

  subStatus = ""
  if subscription <> invalid and subscription.status <> invalid
    subStatus = LCase(subscription.status.ToStr())
  end if

  if isBlocked
    bannerBg.color = "0xB42318FF"
    bannerTitle.text = "Account Blocked"
    bannerSub.text = "Contact support to restore access."
  else if subStatus = "active"
    bannerBg.color = "0x0451DFFF"
    bannerTitle.text = "Subscription Active"
    bannerSub.text = "Your Duplex subscription is active."
  else if subStatus = "expired"
    bannerBg.color = "0xB54708FF"
    bannerTitle.text = "Subscription Expired"
    bannerSub.text = "Renew your plan to continue watching."
  else if isTrial or not hasUsedTrial
    bannerBg.color = "0x1F7A28FF"
    bannerTitle.text = "Trial Available"
    bannerSub.text = "Start your free trial to explore Duplex."
  else
    bannerBg.color = "0x353945FF"
    bannerTitle.text = "No Active Plan"
    bannerSub.text = "Visit www.duplexnew.tv to manage your account."
  end if

  if subscription <> invalid
    DuplexSaveSubscriptionJson(FormatJson(subscription))
  end if
end sub

sub onRegisterError()
  err = m.task.error
  print "Duplex: registration failed - " + err
  m.top.findNode("deviceValue").text = "Unavailable"
  m.top.findNode("warning").text = err
  m.top.findNode("warning").visible = true
end sub

sub updateFocus()
  continueFocused = m.focusIndex = 0
  if continueFocused
    m.top.findNode("continueBg").color = "0x0451DFFF"
    m.top.findNode("quickSetupBg").color = "0x2C2C2EFF"
  else
    m.top.findNode("continueBg").color = "0x2C2C2EFF"
    m.top.findNode("quickSetupBg").color = "0x0451DFFF"
  end if
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function

function handleKeyEvent(key as String) as Boolean
  if key = "left"
    m.focusIndex = 0
    updateFocus()
    return true
  else if key = "right"
    m.focusIndex = 1
    updateFocus()
    return true
  else if key = "OK"
    if m.focusIndex = 0
      print "Duplex: Continue selected"
      m.top.continueSelected = true
    else
      print "Duplex: Quick Setup selected"
      m.top.quickSetupSelected = true
    end if
    return true
  end if

  return false
end function
