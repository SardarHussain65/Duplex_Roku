' HomePanel — Web browse parity for Live / Movies / Series.
sub init()
  m.top.focusable = true
  m.focusZone = "recent"
  m.heroBtn = 0
  m.heroSlide = 0
  m.recentIndex = 0
  m.catIndex = 0
  m.gridIndex = 0
  m.cols = 5
  m.categories = []
  m.channels = []
  m.recent = []
  m.heroPool = []
  m.contentType = "LIVE"
  m.sectionKey = "liveTv"
  m.isLive = true
  m.isVod = false
  m.view = "browse" ' browse | titles
  m.activeCategory = ""

  styleLabel(m.top.findNode("heroTitleA"), 64, "0xFFFFFFFF")
  styleLabel(m.top.findNode("heroTitleB"), 64, "0xC60057FF")
  styleLabel(m.top.findNode("heroDesc"), 24, "0xD6D8E0FF")
  styleLabel(m.top.findNode("vodMeta"), 22, "0xD1D5DBFF")
  styleLabel(m.top.findNode("vodTitle"), 56, "0xFFFFFFFF")
  styleLabel(m.top.findNode("vodDesc"), 24, "0xD6D8E0FF")
  styleLabel(m.top.findNode("btnWatchLbl"), 24, "0xFFFFFFFF")
  styleLabel(m.top.findNode("btnLearnLbl"), 24, "0xFFFFFFFF")
  styleLabel(m.top.findNode("recentTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("catsTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("titlesHeading"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("statusLabel"), 20, "0x9CA3AFFF")

  m.task = m.top.createChild("ContentLoadTask")
  m.task.observeField("categories", "onCategories")
  m.task.observeField("channels", "onChannels")
  m.task.observeField("error", "onError")
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPanelShown()
  m.top.backSelected = false
  m.top.channelSelected = invalid
  m.top.categorySelected = ""
  m.recentIndex = 0
  m.catIndex = 0
  m.gridIndex = 0
  m.heroBtn = 0
  m.heroSlide = 0
  m.view = "browse"
  m.activeCategory = ""

  sectionKey = m.top.initialTab
  if sectionKey = invalid or sectionKey = "" then sectionKey = "liveTv"
  m.sectionKey = sectionKey
  m.contentType = sectionToContentType(sectionKey)
  m.isLive = (sectionKey = "liveTv" or sectionKey = "favorites" or sectionKey = "parental")
  m.isVod = (sectionKey = "movies" or sectionKey = "series")

  showBrowseChrome()
  m.top.findNode("contentRoot").translation = [0, 0]
  m.top.findNode("statusLabel").text = "Loading..."
  m.top.findNode("statusLabel").visible = true
  m.top.findNode("statusLabel").translation = [72, 640]

  if m.isVod
    m.focusZone = "hero"
  else
    m.focusZone = "recent"
  end if

  m.task.playlistId = DuplexLoadActivePlaylistId()
  m.task.contentType = m.contentType
  m.task.page = 1
  m.task.limit = 50
  m.task.category = ""
  m.task.control = "RUN"
end sub

sub showBrowseChrome()
  m.top.findNode("liveHero").visible = m.isLive and m.view = "browse"
  m.top.findNode("vodHero").visible = m.isVod and m.view = "browse"
  m.top.findNode("recentTitle").visible = false
  m.top.findNode("catsTitle").visible = false
  m.top.findNode("recentRoot").visible = (m.isLive or m.isVod) and m.view = "browse"
  m.top.findNode("catsRoot").visible = (m.isLive or m.isVod) and m.view = "browse"
  m.top.findNode("titlesView").visible = (m.view = "titles")
end sub

function sectionToContentType(sectionKey as String) as String
  if sectionKey = "movies" then return "MOVIE"
  if sectionKey = "series" then return "SERIES"
  if sectionKey = "favorites" then return "FAVORITES"
  if sectionKey = "parental" then return "LIVE"
  return "LIVE"
end function

sub onCategories()
  m.categories = m.task.categories
  if m.categories = invalid then m.categories = []
  if m.view = "browse" and (m.isLive or m.isVod) then renderCategories()
end sub

sub onChannels()
  m.channels = m.task.channels
  if m.channels = invalid then m.channels = []
  m.top.findNode("statusLabel").visible = false

  if m.view = "titles"
    if m.channels.Count() = 0
      m.top.findNode("statusLabel").text = "No titles found"
      m.top.findNode("statusLabel").visible = true
      m.top.findNode("statusLabel").translation = [72, 120]
    end if
    m.gridIndex = 0
    m.focusZone = "grid"
    renderGrid()
    return
  end if

  ' browse
  m.recent = []
  maxRecent = m.channels.Count()
  if maxRecent > 8 then maxRecent = 8
  for i = 0 to maxRecent - 1
    m.recent.Push(m.channels[i])
  end for

  m.heroPool = []
  maxHero = m.channels.Count()
  if maxHero > 4 then maxHero = 4
  for i = 0 to maxHero - 1
    m.heroPool.Push(m.channels[i])
  end for

  m.top.findNode("recentTitle").visible = (m.recent.Count() > 0)
  m.top.findNode("catsTitle").visible = true
  layoutBrowseY()

  if m.isVod
    m.focusZone = "hero"
    m.heroBtn = 0
    if m.heroSlide >= m.heroPool.Count() then m.heroSlide = 0
    updateVodHero()
  else
    m.focusZone = "recent"
    if m.recent.Count() = 0 then m.focusZone = "cats"
  end if

  renderRecent()
  renderCategories()
  updateScroll()
end sub

sub layoutBrowseY()
  ' Live hero ~420; VOD hero ~620 — keep recent below hero
  if m.isVod
    m.top.findNode("recentTitle").translation = [72, 640]
    m.top.findNode("recentRoot").translation = [72, 696]
    m.top.findNode("catsTitle").translation = [72, 960]
    m.top.findNode("catsRoot").translation = [72, 1016]
    m.top.findNode("statusLabel").translation = [72, 640]
  else
    m.top.findNode("recentTitle").translation = [72, 400]
    m.top.findNode("recentRoot").translation = [72, 456]
    m.top.findNode("catsTitle").translation = [72, 720]
    m.top.findNode("catsRoot").translation = [72, 776]
    m.top.findNode("statusLabel").translation = [72, 400]
  end if
end sub

sub onError()
  err = m.task.error
  m.top.findNode("statusLabel").text = err
  m.top.findNode("statusLabel").visible = true
  if DuplexIsDev()
    m.categories = DuplexPreviewCategories()
    if m.isVod
      m.channels = DuplexPreviewVodTitles(m.contentType)
    else
      m.channels = DuplexPreviewLiveChannels()
    end if
    m.top.findNode("statusLabel").visible = false
    m.view = "browse"
    showBrowseChrome()
    onChannels()
  end if
end sub

sub clearChildren(root as Object)
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while
end sub

function itemPoster(item as Object) as String
  if item = invalid then return "pkg:/images/channel-poster.png"
  if item.backdropPath <> invalid and item.backdropPath <> "" then return item.backdropPath
  if item.tvgLogo <> invalid and item.tvgLogo <> "" then return item.tvgLogo
  if item.streamIcon <> invalid and item.streamIcon <> "" then return item.streamIcon
  if item.cover <> invalid and item.cover <> "" then return item.cover
  return "pkg:/images/channel-poster.png"
end function

function itemBackdrop(item as Object) as String
  if item = invalid then return ""
  if item.backdropPath <> invalid and item.backdropPath <> "" then return item.backdropPath
  return itemPoster(item)
end function

sub updateVodHero()
  if not m.isVod then return
  item = invalid
  if m.heroPool.Count() > 0
    if m.heroSlide < 0 then m.heroSlide = 0
    if m.heroSlide >= m.heroPool.Count() then m.heroSlide = 0
    item = m.heroPool[m.heroSlide]
  end if

  meta = "Movie"
  if m.contentType = "SERIES" then meta = "Series"
  title = "Movies"
  if m.contentType = "SERIES" then title = "Series"
  desc = "A relentless detective unravels a web of secrets as he hunts a mysterious assassin lurking in the shadows."

  if item <> invalid
    name = item.name
    if name <> invalid and name <> "" then title = UCase(name)
    if item.genre <> invalid and item.genre <> ""
      meta = item.genre
    else if item.groupTitle <> invalid and item.groupTitle <> ""
      meta = item.groupTitle
    end if
    if item.releaseYear <> invalid then meta = meta + " • " + item.releaseYear.ToStr()
    if item.plot <> invalid and item.plot <> "" then desc = item.plot
    m.top.findNode("vodBackdrop").uri = itemBackdrop(item)
  else
    m.top.findNode("vodBackdrop").uri = "pkg:/images/heroImageLiveTV.jpg"
  end if

  m.top.findNode("vodMeta").text = meta
  m.top.findNode("vodTitle").text = title
  m.top.findNode("vodDesc").text = desc

  focusedHero = (m.focusZone = "hero")
  watchFocus = focusedHero and m.heroBtn = 0
  learnFocus = focusedHero and m.heroBtn = 1
  m.top.findNode("btnWatchRing").visible = watchFocus
  m.top.findNode("btnLearnRing").visible = learnFocus
  if watchFocus
    m.top.findNode("btnWatchBg").uri = "pkg:/images/ui/home-hero-btn-focus.png"
  else
    m.top.findNode("btnWatchBg").uri = "pkg:/images/ui/home-hero-btn.png"
  end if
  if learnFocus
    m.top.findNode("btnLearnBg").uri = "pkg:/images/ui/home-hero-btn-focus.png"
  else
    m.top.findNode("btnLearnBg").uri = "pkg:/images/ui/home-hero-btn.png"
  end if

  for d = 0 to 3
    dot = m.top.findNode("dot" + d.ToStr())
    if d = m.heroSlide and m.heroPool.Count() > 0
      dot.uri = "pkg:/images/ui/home-dot-on.png"
    else
      dot.uri = "pkg:/images/ui/home-dot-off.png"
    end if
    dot.visible = (d < m.heroPool.Count() or m.heroPool.Count() = 0 and d < 4)
  end for
end sub

sub renderRecent()
  root = m.top.findNode("recentRoot")
  clearChildren(root)
  cardW = 327
  cardH = 184
  gap = 35
  for i = 0 to m.recent.Count() - 1
    if i >= 5 then exit for
    item = m.recent[i]
    focused = (m.focusZone = "recent" and i = m.recentIndex)
    grp = root.createChild("Group")
    grp.translation = [i * (cardW + gap), 0]

    ring = grp.createChild("Poster")
    ring.id = "ring"
    ring.translation = [-16, -16]
    ring.width = 372
    ring.height = 224
    ring.uri = "pkg:/images/ui/home-card-focus-ring.png"
    ring.loadDisplayMode = "scaleToFit"
    ring.visible = focused

    chrome = grp.createChild("Poster")
    chrome.width = cardW
    chrome.height = cardH
    chrome.uri = "pkg:/images/ui/home-recent-card.png"
    chrome.loadDisplayMode = "scaleToFit"

    poster = grp.createChild("Poster")
    if m.isLive
      poster.translation = [24, 24]
      poster.width = cardW - 48
      poster.height = cardH - 56
      poster.loadDisplayMode = "scaleToFit"
    else
      poster.translation = [0, 0]
      poster.width = cardW
      poster.height = cardH
      poster.loadDisplayMode = "scaleToFill"
    end if
    poster.uri = itemPoster(item)

    if m.isLive
      accent = grp.createChild("Poster")
      accent.translation = [14, cardH - 10]
      accent.width = cardW - 28
      accent.height = 4
      accent.uri = "pkg:/images/ui/home-recent-accent.png"
      accent.loadDisplayMode = "scaleToFit"
    end if

    lbl = grp.createChild("Label")
    lbl.translation = [0, cardH + 12]
    lbl.width = cardW
    lbl.height = 28
    name = item.name
    if name = invalid then name = "Title"
    lbl.text = name
    lbl.font.size = 16
    lbl.color = "0xFFFFFFFF"
  end for
end sub

sub renderCategories()
  root = m.top.findNode("catsRoot")
  clearChildren(root)
  cardW = 327
  cardH = 184
  gapX = 35
  gapY = 18
  maxShow = m.categories.Count()
  if maxShow > 20 then maxShow = 20

  for i = 0 to maxShow - 1
    cat = m.categories[i]
    name = cat.name
    if name = invalid then name = "Category"
    focused = (m.focusZone = "cats" and i = m.catIndex)
    col = i mod m.cols
    row = Int(i / m.cols)
    grp = root.createChild("Group")
    grp.translation = [col * (cardW + gapX), row * (cardH + gapY)]

    ring = grp.createChild("Poster")
    ring.id = "ring"
    ring.translation = [-16, -16]
    ring.width = 372
    ring.height = 224
    ring.uri = "pkg:/images/ui/home-card-focus-ring.png"
    ring.loadDisplayMode = "scaleToFit"
    ring.visible = focused

    bg = grp.createChild("Poster")
    bg.width = cardW
    bg.height = cardH
    if LCase(name) = "all"
      bg.uri = "pkg:/images/ui/home-cat-bg-all.png"
    else
      bg.uri = "pkg:/images/ui/home-cat-bg.png"
    end if
    bg.loadDisplayMode = "scaleToFit"

    lbl = grp.createChild("Label")
    lbl.translation = [12, Int(cardH / 2) - 18]
    lbl.width = cardW - 24
    lbl.height = 40
    lbl.horizAlign = "center"
    lbl.text = UCase(name)
    lbl.font.size = 22
    lbl.color = "0xFFFFFFFF"
  end for
end sub

sub renderGrid()
  root = m.top.findNode("gridRoot")
  clearChildren(root)
  for i = 0 to m.channels.Count() - 1
    if i >= 15 then exit for
    item = m.channels[i]
    col = i mod m.cols
    row = Int(i / m.cols)
    card = root.createChild("ContentCard")
    card.translation = [col * 340, row * 210]
    title = item.name
    if title = invalid then title = "Title"
    card.cardTitle = title
    subT = item.groupTitle
    if subT = invalid then subT = ""
    card.cardSubtitle = subT
    card.cardPoster = itemPoster(item)
    card.cardFocused = (i = m.gridIndex and m.focusZone = "grid")
  end for
end sub

sub updateScroll()
  if m.view = "titles"
    m.top.findNode("contentRoot").translation = [0, 0]
    return
  end if
  if m.focusZone = "cats"
    if m.isVod
      m.top.findNode("contentRoot").translation = [0, -520]
    else
      m.top.findNode("contentRoot").translation = [0, -340]
    end if
  else if m.focusZone = "recent" and m.isVod
    m.top.findNode("contentRoot").translation = [0, -200]
  else
    m.top.findNode("contentRoot").translation = [0, 0]
  end if
end sub

sub refreshFocusVisuals()
  if m.view = "titles"
    renderGrid()
    return
  end if
  if m.isVod then updateVodHero()
  renderRecent()
  renderCategories()
  updateScroll()
end sub

sub openTitlesForCategory(catName as String)
  m.activeCategory = catName
  m.view = "titles"
  showBrowseChrome()
  heading = catName
  if heading = "" then heading = "All"
  m.top.findNode("titlesHeading").text = heading
  m.top.findNode("statusLabel").text = "Loading..."
  m.top.findNode("statusLabel").visible = true
  m.top.findNode("statusLabel").translation = [72, 120]
  m.top.findNode("contentRoot").translation = [0, 0]
  m.task.contentType = m.contentType
  m.task.category = catName
  m.task.control = "RUN"
end sub

sub returnToBrowse()
  m.view = "browse"
  m.activeCategory = ""
  showBrowseChrome()
  layoutBrowseY()
  m.top.findNode("statusLabel").text = "Loading..."
  m.top.findNode("statusLabel").visible = true
  m.task.contentType = m.contentType
  m.task.category = ""
  m.task.control = "RUN"
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    if m.view = "titles"
      returnToBrowse()
      return true
    end if
    m.top.backSelected = true
    return true
  end if

  if m.view = "titles" then return handleGridKeys(key)
  return handleBrowseKeys(key)
end function

function handleBrowseKeys(key as String) as Boolean
  if key = "up"
    if m.focusZone = "cats"
      if m.catIndex < m.cols
        if m.recent.Count() > 0
          m.focusZone = "recent"
          if m.recentIndex > 4 then m.recentIndex = 4
        else if m.isVod
          m.focusZone = "hero"
        end if
      else
        m.catIndex = m.catIndex - m.cols
      end if
      refreshFocusVisuals()
    else if m.focusZone = "recent" and m.isVod
      m.focusZone = "hero"
      refreshFocusVisuals()
    end if
    return true
  end if

  if key = "down"
    if m.focusZone = "hero"
      if m.recent.Count() > 0
        m.focusZone = "recent"
        m.recentIndex = 0
      else
        m.focusZone = "cats"
        m.catIndex = 0
      end if
      refreshFocusVisuals()
    else if m.focusZone = "recent"
      m.focusZone = "cats"
      m.catIndex = 0
      refreshFocusVisuals()
    else if m.catIndex + m.cols < m.categories.Count()
      m.catIndex = m.catIndex + m.cols
      refreshFocusVisuals()
    end if
    return true
  end if

  if key = "left"
    if m.focusZone = "hero"
      if m.heroBtn > 0
        m.heroBtn = m.heroBtn - 1
      else if m.heroPool.Count() > 1
        m.heroSlide = m.heroSlide - 1
        if m.heroSlide < 0 then m.heroSlide = m.heroPool.Count() - 1
      end if
    else if m.focusZone = "recent"
      m.recentIndex = m.recentIndex - 1
      if m.recentIndex < 0 then m.recentIndex = 0
    else
      m.catIndex = m.catIndex - 1
      if m.catIndex < 0 then m.catIndex = 0
    end if
    refreshFocusVisuals()
    return true
  end if

  if key = "right"
    if m.focusZone = "hero"
      if m.heroBtn < 1
        m.heroBtn = m.heroBtn + 1
      else if m.heroPool.Count() > 1
        m.heroSlide = m.heroSlide + 1
        if m.heroSlide >= m.heroPool.Count() then m.heroSlide = 0
        m.heroBtn = 0
      end if
    else if m.focusZone = "recent"
      maxR = m.recent.Count() - 1
      if maxR > 4 then maxR = 4
      m.recentIndex = m.recentIndex + 1
      if m.recentIndex > maxR then m.recentIndex = maxR
    else
      m.catIndex = m.catIndex + 1
      if m.catIndex >= m.categories.Count() then m.catIndex = m.categories.Count() - 1
    end if
    refreshFocusVisuals()
    return true
  end if

  if key = "OK"
    if m.focusZone = "hero"
      if m.heroPool.Count() > 0 and m.heroSlide < m.heroPool.Count()
        m.top.channelSelected = m.heroPool[m.heroSlide]
      end if
    else if m.focusZone = "recent"
      if m.recentIndex >= 0 and m.recentIndex < m.recent.Count()
        m.top.channelSelected = m.recent[m.recentIndex]
      end if
    else if m.focusZone = "cats"
      if m.catIndex >= 0 and m.catIndex < m.categories.Count()
        catName = m.categories[m.catIndex].name
        if catName = invalid then catName = ""
        if catName = "All" then catName = ""
        if m.isLive
          if catName = ""
            m.top.categorySelected = "All"
          else
            m.top.categorySelected = catName
          end if
        else
          openTitlesForCategory(catName)
        end if
      end if
    end if
    return true
  end if

  return false
end function

function handleGridKeys(key as String) as Boolean
  if key = "up"
    if m.gridIndex >= m.cols
      m.gridIndex = m.gridIndex - m.cols
      renderGrid()
    end if
    return true
  end if
  if key = "down"
    if m.gridIndex + m.cols < m.channels.Count()
      m.gridIndex = m.gridIndex + m.cols
      renderGrid()
    end if
    return true
  end if
  if key = "left"
    if m.gridIndex > 0
      m.gridIndex = m.gridIndex - 1
      renderGrid()
    end if
    return true
  end if
  if key = "right"
    if m.gridIndex < m.channels.Count() - 1
      m.gridIndex = m.gridIndex + 1
      renderGrid()
    end if
    return true
  end if
  if key = "OK"
    if m.gridIndex >= 0 and m.gridIndex < m.channels.Count()
      m.top.channelSelected = m.channels[m.gridIndex]
    end if
    return true
  end if
  return false
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
