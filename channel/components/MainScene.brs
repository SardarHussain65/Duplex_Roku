' MainScene component script. Markup lives in MainScene.xml.
sub init()
  m.top.backgroundUri = ""
  m.top.setFocus(true)
  m.returnFocusAdd = false
  m.activeScreen = ""
  m.splashTimer = invalid
  m.suppressNav = false
  m.homeTab = "liveTv"
  m.playerReturn = "home"

  wireObservers()

  ' Web TV parity: every cold start is Splash → Activation (never skip to Hub).
  showScreen(DuplexResolveInitialScreen(), {})
  m.splashTimer = CreateObject("roSGNode", "Timer")
  m.splashTimer.duration = 2.2
  m.splashTimer.repeat = false
  m.splashTimer.observeField("fire", "onSplashTimeout")
  m.top.appendChild(m.splashTimer)
  m.splashTimer.control = "start"
end sub

sub wireObservers()
  m.top.findNode("activation").observeField("continueSelected", "onContinue")
  m.top.findNode("activation").observeField("quickSetupSelected", "onQuickSetup")
  m.top.findNode("activation").observeField("exitSelected", "onActivationExit")
  m.top.findNode("playlistSource").observeField("backSelected", "onPlaylistSourceBack")
  m.top.findNode("playlistSource").observeField("playlistSelected", "onPlaylistPicked")
  m.top.findNode("playlistSource").observeField("addXtreamSelected", "onAddXtream")
  m.top.findNode("xtreamSetup").observeField("backSelected", "onXtreamBack")
  m.top.findNode("xtreamSetup").observeField("playlistCreated", "onXtreamCreated")
  m.top.findNode("playlistLoading").observeField("backSelected", "onLoadingBack")
  m.top.findNode("playlistLoading").observeField("readySelected", "onLoadingReady")
  m.top.findNode("hub").observeField("sectionSelected", "onHubSection")
  m.top.findNode("hub").observeField("switchPlaylistSelected", "onHubSwitchPlaylist")
  m.top.findNode("hub").observeField("parentalSelected", "onHubParental")
  m.top.findNode("hub").observeField("settingsSelected", "onHubSettings")
  m.top.findNode("hub").observeField("backSelected", "onHubBack")
  m.top.findNode("home").observeField("backSelected", "onHomeBack")
  m.top.findNode("home").observeField("channelSelected", "onHomeItemPicked")
  m.top.findNode("home").observeField("categorySelected", "onHomeCategoryPicked")
  m.top.findNode("liveChannel").observeField("backSelected", "onLiveChannelBack")
  m.top.findNode("liveChannel").observeField("channelSelected", "onLiveWatch")
  m.top.findNode("vodDetail").observeField("backSelected", "onVodBack")
  m.top.findNode("vodDetail").observeField("watchSelected", "onVodWatch")
  m.top.findNode("player").observeField("backSelected", "onPlayerBack")
  m.top.findNode("settings").observeField("backSelected", "onSettingsBack")
  m.top.findNode("settings").observeField("logoutSelected", "onSettingsLogout")
  m.top.findNode("parentalPin").observeField("backSelected", "onParentalPinBack")
  m.top.findNode("parentalPin").observeField("unlockedSelected", "onParentalUnlocked")
end sub

sub hideAllScreens()
  for each screenId in DuplexAllScreenIds()
    node = m.top.findNode(screenId)
    if node <> invalid
      node.visible = false
      node.setFocus(false)
    end if
  end for
end sub

sub takeSceneFocus()
  m.top.setFocus(true)
end sub

sub showScreen(screenId as String, options as Object)
  m.suppressNav = true
  hideAllScreens()
  m.activeScreen = screenId
  panel = m.top.findNode(screenId)
  if panel = invalid
    m.suppressNav = false
    DuplexLog("missing panel " + screenId)
    return
  end if

  if screenId = DuplexScreenPlaylistSource()
    focusAdd = false
    if options <> invalid and options.focusAdd = true then focusAdd = true
    m.returnFocusAdd = focusAdd
    panel.focusAddButton = focusAdd
  else if screenId = DuplexScreenPlaylistLoading()
    panel.playlist = options.playlist
  else if screenId = DuplexScreenHome()
    panel.initialTab = "liveTv"
    if options <> invalid and options.section <> invalid
      panel.initialTab = options.section
      m.homeTab = options.section
    end if
  else if screenId = DuplexScreenLiveChannel()
    panel.browse = options.browse
  else if screenId = DuplexScreenVodDetail()
    panel.item = options.item
  else if screenId = DuplexScreenPlayer()
    panel.channel = options.channel
  else if screenId = DuplexScreenParentalPin()
    panel.mode = "pin"
    if options <> invalid and options.mode <> invalid
      panel.mode = options.mode
    end if
  end if

  panel.visible = true
  if screenId <> DuplexScreenSplash()
    panel.callFunc("onPanelShown")
  end if
  m.suppressNav = false
  takeSceneFocus()
  DuplexLog("screen → " + screenId)
end sub

sub onSplashTimeout()
  showScreen(DuplexScreenActivation(), {})
end sub

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  normKey = DuplexNormalizeKey(key)

  if m.activeScreen = DuplexScreenSplash() and (normKey = "OK" or normKey = "back")
    if m.splashTimer <> invalid then m.splashTimer.control = "stop"
    showScreen(DuplexScreenActivation(), {})
    return true
  end if

  panel = m.top.findNode(m.activeScreen)
  if panel <> invalid
    handled = panel.callFunc("handleKeyEvent", normKey)
    if handled = true then return true
  end if
  return false
end function

sub onContinue()
  if m.suppressNav then return
  if m.top.findNode("activation").continueSelected <> true then return
  showScreen(DuplexScreenPlaylistSource(), { focusAdd: false })
end sub

sub onQuickSetup()
  if m.suppressNav then return
  if m.top.findNode("activation").quickSetupSelected <> true then return
  showScreen(DuplexScreenPlaylistSource(), { focusAdd: true })
end sub

sub onActivationExit()
  if m.suppressNav then return
  if m.top.findNode("activation").exitSelected <> true then return
  DuplexLog("Exit App")
  appMgr = CreateObject("roAppManager")
  if appMgr <> invalid
    appMgr.Exit()
  end if
end sub

sub onPlaylistSourceBack()
  if m.suppressNav then return
  if m.top.findNode("playlistSource").backSelected <> true then return
  showScreen(DuplexScreenActivation(), {})
end sub

sub onPlaylistPicked()
  if m.suppressNav then return
  playlist = m.top.findNode("playlistSource").playlistSelected
  if playlist = invalid then return
  showScreen(DuplexScreenPlaylistLoading(), { playlist: playlist })
end sub

sub onAddXtream()
  if m.suppressNav then return
  if m.top.findNode("playlistSource").addXtreamSelected <> true then return
  showScreen(DuplexScreenXtreamSetup(), {})
end sub

sub onXtreamBack()
  if m.suppressNav then return
  if m.top.findNode("xtreamSetup").backSelected <> true then return
  showScreen(DuplexScreenPlaylistSource(), { focusAdd: m.returnFocusAdd })
end sub

sub onXtreamCreated()
  if m.suppressNav then return
  playlist = m.top.findNode("xtreamSetup").playlistCreated
  if playlist = invalid then return
  showScreen(DuplexScreenPlaylistLoading(), { playlist: playlist })
end sub

sub onLoadingBack()
  if m.suppressNav then return
  if m.top.findNode("playlistLoading").backSelected <> true then return
  showScreen(DuplexScreenPlaylistSource(), { focusAdd: m.returnFocusAdd })
end sub

sub onLoadingReady()
  if m.suppressNav then return
  if m.top.findNode("playlistLoading").readySelected <> true then return
  showScreen(DuplexScreenHub(), {})
end sub

sub onHubSection()
  if m.suppressNav then return
  section = m.top.findNode("hub").sectionSelected
  if section = invalid or section = "" then return
  m.homeTab = section
  showScreen(DuplexScreenHome(), { section: section })
end sub

sub onHubSwitchPlaylist()
  if m.suppressNav then return
  if m.top.findNode("hub").switchPlaylistSelected <> true then return
  showScreen(DuplexScreenPlaylistSource(), { focusAdd: false })
end sub

sub onHubParental()
  if m.suppressNav then return
  if m.top.findNode("hub").parentalSelected <> true then return
  DuplexLog("Hub Parental → PIN")
  showScreen(DuplexScreenParentalPin(), { mode: "pin" })
end sub

sub onHubSettings()
  if m.suppressNav then return
  if m.top.findNode("hub").settingsSelected <> true then return
  showScreen(DuplexScreenSettings(), {})
end sub

sub onHubBack()
  if m.suppressNav then return
  if m.top.findNode("hub").backSelected <> true then return
  showScreen(DuplexScreenPlaylistSource(), { focusAdd: false })
end sub

sub onHomeBack()
  if m.suppressNav then return
  if m.top.findNode("home").backSelected <> true then return
  showScreen(DuplexScreenHub(), {})
end sub

sub onHomeCategoryPicked()
  if m.suppressNav then return
  cat = m.top.findNode("home").categorySelected
  if cat = invalid or cat = "" then return
  sectionKey = m.top.findNode("home").initialTab
  if sectionKey = "liveTv" or sectionKey = "favorites" or sectionKey = "parental"
    showScreen(DuplexScreenLiveChannel(), { browse: { category: cat, channel: invalid } })
  end if
end sub

sub onHomeItemPicked()
  if m.suppressNav then return
  channel = m.top.findNode("home").channelSelected
  if channel = invalid then return
  sectionKey = m.top.findNode("home").initialTab
  if sectionKey = "movies" or sectionKey = "series"
    showScreen(DuplexScreenVodDetail(), { item: channel })
  else
    cat = ""
    if channel.groupTitle <> invalid then cat = channel.groupTitle
    showScreen(DuplexScreenLiveChannel(), { browse: { category: cat, channel: channel } })
  end if
end sub

sub onLiveChannelBack()
  if m.suppressNav then return
  if m.top.findNode("liveChannel").backSelected <> true then return
  showScreen(DuplexScreenHome(), { section: m.homeTab })
end sub

sub onLiveWatch()
  if m.suppressNav then return
  channel = m.top.findNode("liveChannel").channelSelected
  if channel = invalid then return
  m.playerReturn = "liveChannel"
  showScreen(DuplexScreenPlayer(), { channel: channel })
end sub

sub onVodBack()
  if m.suppressNav then return
  if m.top.findNode("vodDetail").backSelected <> true then return
  showScreen(DuplexScreenHome(), { section: m.homeTab })
end sub

sub onVodWatch()
  if m.suppressNav then return
  item = m.top.findNode("vodDetail").watchSelected
  if item = invalid then return
  m.playerReturn = "vodDetail"
  showScreen(DuplexScreenPlayer(), { channel: item })
end sub

sub onPlayerBack()
  if m.suppressNav then return
  if m.top.findNode("player").backSelected <> true then return
  if m.playerReturn = "liveChannel"
    browse = m.top.findNode("liveChannel").browse
    showScreen(DuplexScreenLiveChannel(), { browse: browse })
  else if m.playerReturn = "vodDetail"
    item = m.top.findNode("vodDetail").item
    showScreen(DuplexScreenVodDetail(), { item: item })
  else
    showScreen(DuplexScreenHome(), { section: m.homeTab })
  end if
end sub

sub onSettingsBack()
  if m.suppressNav then return
  if m.top.findNode("settings").backSelected <> true then return
  showScreen(DuplexScreenHub(), {})
end sub

sub onSettingsLogout()
  if m.suppressNav then return
  if m.top.findNode("settings").logoutSelected <> true then return
  showScreen(DuplexScreenActivation(), {})
end sub

sub onParentalPinBack()
  if m.suppressNav then return
  if m.top.findNode("parentalPin").backSelected <> true then return
  showScreen(DuplexScreenHub(), {})
end sub

sub onParentalUnlocked()
  if m.suppressNav then return
  if m.top.findNode("parentalPin").unlockedSelected <> true then return
  m.homeTab = "parental"
  showScreen(DuplexScreenHome(), { section: "parental" })
end sub
