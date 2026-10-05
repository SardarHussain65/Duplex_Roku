' HomePanel — Web browse parity for Live / Movies / Series.
sub init()
  m.top.focusable = true
  m.focusZone = "recent"
  m.heroBtn = 0
  m.heroSlide = 0
  m.recentIndex = 0
  m.recentScrollX = 0
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
  m.isLibrary = false
  m.filterIndex = 0 ' 0 LIVE, 1 MOVIE, 2 SERIES
  m.allFavorites = []
  m.filteredItems = []
  m.countLive = 0
  m.countMovie = 0
  m.countSeries = 0
  m.view = "browse" ' browse | titles
  m.activeCategory = ""

  styleLabel(m.top.findNode("heroTitleA"), 72, "0xFFFFFFFF")
  styleLabel(m.top.findNode("heroTitleB"), 72, "0xC60057FF")
  styleLabel(m.top.findNode("heroDesc"), 24, "0xD6D8E0FF")
  styleLabel(m.top.findNode("vodMeta"), 22, "0xD1D5DBFF")
  styleLabel(m.top.findNode("vodTitle"), 72, "0xFFFFFFFF")
  styleLabel(m.top.findNode("vodDesc"), 24, "0xD6D8E0FF")
  styleLabel(m.top.findNode("btnWatchLbl"), 24, "0xFFFFFFFF")
  styleLabel(m.top.findNode("btnLearnLbl"), 24, "0xFFFFFFFF")
  styleLabel(m.top.findNode("recentTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("catsTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("titlesHeading"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("titlesSearchText"), 26, "0x9CA3AFFF")
  styleLabel(m.top.findNode("libraryTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("librarySectionTitle"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("libraryEmpty"), 24, "0x9CA3AFFF")
  styleLabel(m.top.findNode("statusLabel"), 28, "0xFFFFFFFF")

  m.task = invalid
  m.loading = false
  m.skeletonBright = false
  m.skeletonTimer = m.top.createChild("Timer")
  m.skeletonTimer.duration = 0.7
  m.skeletonTimer.repeat = true
  m.skeletonTimer.observeField("fire", "onSkeletonPulse")
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
  m.recentScrollX = 0
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
  m.isLibrary = (sectionKey = "favorites" or sectionKey = "parental")
  m.libraryMode = ""
  if sectionKey = "favorites" then m.libraryMode = "favorites"
  if sectionKey = "parental" then m.libraryMode = "parental"
  m.isLive = (sectionKey = "liveTv")
  m.isVod = (sectionKey = "movies" or sectionKey = "series")
  m.filterIndex = 0
  m.allFavorites = []
  m.filteredItems = []
  m.libraryCategories = []
  m.countLive = 0
  m.countMovie = 0
  m.countSeries = 0
  m.libraryShowingCategories = (m.libraryMode = "parental")

  contentType = m.contentType
  favoriteType = "LIVE"
  category = ""
  if m.isLibrary
    m.focusZone = "filters"
    if m.libraryMode = "favorites"
      m.top.findNode("libraryTitle").text = "Favorites"
      contentType = "FAVORITES"
      favoriteType = libraryFilterType()
    else
      m.top.findNode("libraryTitle").text = "Parental Control"
      contentType = "PARENTAL"
      favoriteType = libraryFilterType()
    end if
  else if m.isVod
    m.focusZone = "hero"
  else
    m.focusZone = "recent"
  end if

  m.top.findNode("contentRoot").translation = [0, 0]
  clearLoadedContent()
  showBrowseChrome()
  showLoadingStatus()
  startContentTask(contentType, favoriteType, category)
end sub

sub stopContentTask()
  if m.task = invalid then return
  m.task.unobserveField("categories")
  m.task.unobserveField("channels")
  m.task.unobserveField("totalLive")
  m.task.unobserveField("totalMovies")
  m.task.unobserveField("totalSeries")
  m.task.unobserveField("error")
  m.task.control = "stop"
  m.top.removeChild(m.task)
  m.task = invalid
end sub

sub clearLoadedContent()
  m.channels = []
  m.categories = []
  m.recent = []
  m.heroPool = []
  m.filteredItems = []
  m.libraryCategories = []
  clearChildren(m.top.findNode("gridRoot"))
  clearChildren(m.top.findNode("recentRoot"))
  clearChildren(m.top.findNode("catsRoot"))
  clearChildren(m.top.findNode("libraryGrid"))
  clearChildren(m.top.findNode("libraryFilters"))
  m.top.findNode("libraryEmpty").visible = false
  m.top.findNode("recentTitle").visible = false
  m.top.findNode("catsTitle").visible = false
  m.top.findNode("heroArt").uri = ""
  m.top.findNode("vodBackdrop").uri = ""
  m.top.findNode("vodTitle").text = ""
  m.top.findNode("vodDesc").text = ""
  m.top.findNode("vodMeta").text = ""
end sub

sub showLoadingStatus()
  m.top.findNode("statusLabel").visible = false
  kind = "browseLive"
  if m.isVod then kind = "browseVod"
  if m.view = "titles"
    kind = "liveGrid"
    if m.isVod or libraryFilterType() = "MOVIE" or libraryFilterType() = "SERIES" then kind = "posters"
  else if m.isLibrary
    kind = "library"
  end if
  DuplexFillSkeleton(m.top.findNode("skeletonRoot"), homeSkeletonBones(kind))
  m.skeletonBright = false
  m.skeletonTimer.control = "start"
end sub

sub hideSkeleton()
  if m.skeletonTimer <> invalid then m.skeletonTimer.control = "stop"
  DuplexHideSkeleton(m.top.findNode("skeletonRoot"))
end sub

sub onSkeletonPulse()
  if not m.loading then return
  m.skeletonBright = not m.skeletonBright
  DuplexPulseSkeleton(m.top.findNode("skeletonRoot"), m.skeletonBright)
end sub

function homeSkeletonBones(kind as String) as Object
  bones = []
  if kind = "posters"
    ' Search and "Category | …" stay real. Two rows match the visible poster grid.
    baseY = 200
    cardW = 268
    posterH = 402
    stride = 292
    rowPitch = 470
    for row = 0 to 1
      for col = 0 to 5
        x = 72 + col * stride
        y = baseY + row * rowPitch
        bones.Push({ x: x, y: y, w: cardW, h: posterH })
        bones.Push({ x: x + cardW - 108, y: y + 14, w: 96, h: 40, tone: "line" })
        if row = 0
          bones.Push({ x: x, y: y + posterH + 12, w: cardW - 28, h: 22, tone: "line" })
        end if
      end for
    end for
  else if kind = "liveGrid"
    for row = 0 to 2
      for col = 0 to 4
        bones.Push({ x: 72 + col * 340, y: 110 + row * 210, w: 280, h: 180 })
      end for
    end for
  else if kind = "library"
    bones.Push({ x: 72, y: 120, w: 180, h: 56 })
    bones.Push({ x: 268, y: 120, w: 180, h: 56 })
    bones.Push({ x: 464, y: 120, w: 180, h: 56 })
    for col = 0 to 4
      bones.Push({ x: 72 + col * 351, y: 270, w: 327, h: 184 })
    end for
  else if kind = "browseVod"
    bones.Push({ x: 0, y: 0, w: 1920, h: 810, tone: "hero" })
    bones.Push({ x: 72, y: 420, w: 280, h: 22, tone: "line" })
    bones.Push({ x: 72, y: 458, w: 720, h: 36, tone: "line" })
    bones.Push({ x: 72, y: 506, w: 480, h: 36, tone: "line" })
    bones.Push({ x: 72, y: 564, w: 680, h: 20, tone: "line" })
    bones.Push({ x: 72, y: 594, w: 460, h: 20, tone: "line" })
    bones.Push({ x: 72, y: 670, w: 280, h: 64, tone: "line" })
    bones.Push({ x: 372, y: 670, w: 280, h: 64, tone: "line" })
    bones.Push({ x: 936, y: 768, w: 16, h: 16, tone: "line" })
    bones.Push({ x: 960, y: 768, w: 16, h: 16, tone: "line" })
    bones.Push({ x: 984, y: 768, w: 16, h: 16, tone: "line" })
    bones.Push({ x: 1008, y: 768, w: 16, h: 16, tone: "line" })
    bones.Push({ x: 72, y: 834, w: 280, h: 28, tone: "line" })
    for i = 0 to 4
      bones.Push({ x: 72 + i * 362, y: 878, w: 327, h: 184 })
    end for
  else
    bones.Push({ x: 72, y: 822, w: 280, h: 28 })
    for i = 0 to 4
      bones.Push({ x: 72 + i * 362, y: 878, w: 327, h: 184 })
    end for
  end if
  return bones
end function

sub startContentTask(contentType as String, favoriteType as String, category as String)
  stopContentTask()
  m.loading = true
  m.task = m.top.createChild("ContentLoadTask")
  m.task.observeField("categories", "onCategories")
  m.task.observeField("channels", "onChannels")
  m.task.observeField("totalLive", "onFavoriteTotals")
  m.task.observeField("totalMovies", "onFavoriteTotals")
  m.task.observeField("totalSeries", "onFavoriteTotals")
  m.task.observeField("error", "onError")
  m.task.playlistId = DuplexLoadActivePlaylistId()
  m.task.contentType = contentType
  m.task.favoriteType = favoriteType
  m.task.category = category
  m.task.page = 1
  m.task.limit = 50
  showBrowseChrome()
  m.task.control = "RUN"
end sub

sub showBrowseChrome()
  showContent = not m.loading
  m.top.findNode("liveHero").visible = m.isLive and m.view = "browse"
  m.top.findNode("vodHero").visible = showContent and m.isVod and m.view = "browse"
  parentalCategoryScreen = (m.isLibrary and m.libraryMode = "parental" and not m.libraryShowingCategories)
  m.top.findNode("libraryView").visible = m.isLibrary and not parentalCategoryScreen
  m.top.findNode("recentTitle").visible = false
  m.top.findNode("catsTitle").visible = false
  m.top.findNode("recentRoot").visible = showContent and (m.isLive or m.isVod) and m.view = "browse"
  m.top.findNode("catsRoot").visible = showContent and (m.isLive or m.isVod) and m.view = "browse"
  m.top.findNode("titlesView").visible = ((m.view = "titles") and not m.isLibrary) or parentalCategoryScreen
end sub

function sectionToContentType(sectionKey as String) as String
  if sectionKey = "movies" then return "MOVIE"
  if sectionKey = "series" then return "SERIES"
  if sectionKey = "favorites" then return "FAVORITES"
  if sectionKey = "parental" then return "PARENTAL"
  return "LIVE"
end function

sub onCategories()
  if not m.loading or m.task = invalid then return
  if m.task.categories = invalid then return
  m.categories = m.task.categories
  if m.categories = invalid then m.categories = []
  if m.isLibrary and m.libraryMode = "parental" and m.libraryShowingCategories
    m.libraryCategories = m.categories
    m.top.findNode("statusLabel").visible = false
    if m.focusZone <> "filters" and m.focusZone <> "grid" then m.focusZone = "filters"
    m.gridIndex = 0
    renderLibrary()
    return
  end if
  if m.view = "browse" and (m.isLive or m.isVod) then renderCategories()
end sub

sub onChannels()
  if not m.loading or m.task = invalid then return
  if m.task.channels = invalid then return
  m.loading = false
  hideSkeleton()
  m.channels = m.task.channels
  if m.channels = invalid then m.channels = []
  m.top.findNode("statusLabel").visible = false
  showBrowseChrome()

  if m.isLibrary
    if m.libraryMode = "parental" and m.libraryShowingCategories
      ' Categories arrive via onCategories; ignore empty channel payload
      return
    end if
    if m.libraryMode = "parental" and not m.libraryShowingCategories
      m.filteredItems = m.channels
      if m.gridIndex >= m.filteredItems.Count() then m.gridIndex = 0
      m.focusZone = "grid"
      renderParentalCategoryItems()
      return
    end if
    m.filteredItems = m.channels
    if m.libraryMode = "favorites"
      if m.task.totalLive <> invalid then m.countLive = m.task.totalLive
      if m.task.totalMovies <> invalid then m.countMovie = m.task.totalMovies
      if m.task.totalSeries <> invalid then m.countSeries = m.task.totalSeries
    end if
    if m.focusZone <> "filters" and m.focusZone <> "grid" then m.focusZone = "filters"
    if m.gridIndex >= m.filteredItems.Count() then m.gridIndex = 0
    renderLibrary()
    return
  end if

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
  ' Live + VOD heroes ~810 (Web) — keep recent below hero
  m.catScrollOffset = 0
  m.gridScrollOffset = 0
  m.top.findNode("recentTitle").translation = [72, 822]
  m.top.findNode("recentRoot").translation = [72, 878]
  m.top.findNode("catsTitle").translation = [72, 1120]
  m.top.findNode("catsRoot").translation = [72, 1176]
  m.top.findNode("statusLabel").translation = [72, 822]
end sub

function catRowPitch() as Integer
  return 202 ' cardH 184 + gapY 18
end function

function titleCols() as Integer
  if m.isVod then return 6
  return m.cols
end function

function gridRowPitch() as Integer
  if m.view = "titles" and m.isVod then return 470
  return 210
end function

function titlesGridBaseY() as Integer
  if m.isVod then return 200
  return 110
end function

sub updateScroll()
  if m.view = "titles"
    ' Keep heading fixed; scroll only the titles grid content
    m.top.findNode("contentRoot").translation = [0, 0]
    cols = titleCols()
    row = 0
    if cols > 0 then row = Int(m.gridIndex / cols)
    visibleRows = 4
    if m.isVod then visibleRows = 2
    scrollRows = row - (visibleRows - 1)
    if scrollRows < 0 then scrollRows = 0
    if m.focusZone = "search" then scrollRows = 0
    m.gridScrollOffset = scrollRows * gridRowPitch()
    m.top.findNode("gridRoot").translation = [72, titlesGridBaseY() - m.gridScrollOffset]
    return
  end if

  if m.focusZone = "cats"
    ' Lock page so "Browse Categories" stays put; scroll only catsRoot
    catsTitleY = 1120
    catsRootBaseY = 1176
    pageScroll = 48 - catsTitleY
    m.top.findNode("contentRoot").translation = [0, pageScroll]

    row = Int(m.catIndex / m.cols)
    ' Screen space after page scroll: cats start ~104px; ~4 rows fit
    visibleRows = 4
    scrollRows = row - (visibleRows - 1)
    if scrollRows < 0 then scrollRows = 0
    m.catScrollOffset = scrollRows * catRowPitch()
    m.top.findNode("catsTitle").translation = [72, catsTitleY]
    m.top.findNode("catsRoot").translation = [72, catsRootBaseY - m.catScrollOffset]
  else if m.focusZone = "recent"
    ' Reset category content offset; nudge page for recent row
    m.catScrollOffset = 0
    m.top.findNode("catsRoot").translation = [72, 1176]
    m.top.findNode("contentRoot").translation = [0, -40]
  else
    m.catScrollOffset = 0
    m.top.findNode("catsRoot").translation = [72, 1176]
    m.top.findNode("contentRoot").translation = [0, 0]
  end if
end sub

sub refreshFocusVisuals()
  if m.isLibrary
    if m.libraryMode = "parental" and not m.libraryShowingCategories
      renderParentalCategoryItems()
      updateLibraryScroll()
      return
    end if
    renderLibrary()
    updateLibraryScroll()
    return
  end if
  if m.view = "titles"
    renderGrid()
    updateScroll()
    return
  end if
  if m.isVod then updateVodHero()
  renderRecent()
  renderCategories()
  updateScroll()
end sub

sub updateLibraryScroll()
  ' Keep filters/title fixed; scroll only the library grid
  m.top.findNode("contentRoot").translation = [0, 0]
  if m.focusZone <> "grid"
    m.top.findNode("libraryGrid").translation = [72, 270]
    return
  end if
  row = Int(m.gridIndex / m.cols)
  visibleRows = 3
  scrollRows = row - (visibleRows - 1)
  if scrollRows < 0 then scrollRows = 0
  offset = scrollRows * 202
  m.top.findNode("libraryGrid").translation = [72, 270 - offset]
end sub

sub onError()
  if not m.loading or m.task = invalid then return
  err = m.task.error
  if err = invalid or err = "" then return
  m.loading = false
  hideSkeleton()
  m.channels = []
  m.categories = []
  clearLoadedContent()
  showBrowseChrome()
  m.top.findNode("statusLabel").text = err
  m.top.findNode("statusLabel").visible = true
end sub

sub onFavoriteTotals()
  if not m.loading or m.task = invalid then return
  if m.task.channels = invalid then return
  if not m.isLibrary then return
  if m.task.totalLive <> invalid then m.countLive = m.task.totalLive
  if m.task.totalMovies <> invalid then m.countMovie = m.task.totalMovies
  if m.task.totalSeries <> invalid then m.countSeries = m.task.totalSeries
  renderLibraryFilters()
end sub

sub computeFavoriteCounts()
  ' Counts come from API totals; kept for preview fallback only.
  m.countLive = 0
  m.countMovie = 0
  m.countSeries = 0
  for each item in m.channels
    ct = item.contentType
    if ct = invalid then ct = "LIVE"
    ct = UCase(ct)
    if ct = "MOVIE"
      m.countMovie = m.countMovie + 1
    else if ct = "SERIES"
      m.countSeries = m.countSeries + 1
    else
      m.countLive = m.countLive + 1
    end if
  end for
end sub

function libraryFilterType() as String
  if m.filterIndex = 1 then return "MOVIE"
  if m.filterIndex = 2 then return "SERIES"
  return "LIVE"
end function

sub reloadLibraryFilter()
  m.gridIndex = 0
  contentType = "FAVORITES"
  if m.libraryMode = "parental"
    m.libraryShowingCategories = true
    m.activeCategory = ""
    contentType = "PARENTAL"
  end if
  m.filteredItems = []
  m.view = "browse"
  clearLoadedContent()
  showBrowseChrome()
  showLoadingStatus()
  startContentTask(contentType, libraryFilterType(), "")
end sub

sub openParentalCategory(catName as String)
  m.activeCategory = catName
  m.libraryShowingCategories = false
  m.view = "titles"
  m.focusZone = "grid"
  m.gridIndex = 0
  ' Full category screen (Web library--category-view)
  m.top.findNode("libraryView").visible = false
  m.top.findNode("titlesView").visible = true
  m.top.findNode("titlesHeading").text = "Category | " + catName
  styleLabel(m.top.findNode("titlesHeading"), 36, "0xFFFFFFFF")
  m.top.findNode("contentRoot").translation = [0, 0]
  clearLoadedContent()
  showBrowseChrome()
  showLoadingStatus()
  startContentTask("PARENTAL", libraryFilterType(), catName)
end sub

sub returnParentalToCategories()
  m.libraryShowingCategories = true
  m.activeCategory = ""
  m.filteredItems = []
  m.view = "browse"
  m.focusZone = "filters"
  m.gridIndex = 0
  m.top.findNode("titlesView").visible = false
  m.top.findNode("libraryView").visible = true
  m.top.findNode("statusLabel").visible = false
  reloadLibraryFilter()
end sub

sub applyLibraryFilter()
  reloadLibraryFilter()
end sub

sub renderLibrary()
  if m.libraryMode = "parental" and not m.libraryShowingCategories
    ' Items are shown on the dedicated category screen
    return
  end if
  renderLibraryFilters()
  if m.libraryMode = "parental" and m.libraryShowingCategories
    renderParentalCategories()
  else
    renderLibraryGrid()
  end if
end sub

sub renderParentalCategoryItems()
  root = m.top.findNode("gridRoot")
  clearChildren(root)
  m.top.findNode("titlesView").visible = true
  m.top.findNode("libraryView").visible = false
  empty = m.top.findNode("libraryEmpty")
  empty.visible = false

  if m.filteredItems.Count() = 0
    m.top.findNode("statusLabel").text = "No content has been restricted under parental control."
    m.top.findNode("statusLabel").visible = true
    m.top.findNode("statusLabel").translation = [72, 200]
    return
  end if
  m.top.findNode("statusLabel").visible = false

  liveFilter = (libraryFilterType() = "LIVE")
  cardW = 327
  cardH = 184
  gapX = 35
  gapY = 48
  cols = 5
  maxShow = m.filteredItems.Count()
  if maxShow > 20 then maxShow = 20

  for i = 0 to maxShow - 1
    item = m.filteredItems[i]
    focused = (m.focusZone = "grid" and i = m.gridIndex)
    col = i mod cols
    row = Int(i / cols)
    grp = root.createChild("Group")
    grp.translation = [col * (cardW + gapX), row * (cardH + gapY)]

    ring = grp.createChild("Poster")
    ring.translation = [-16, -16]
    ring.width = 372
    ring.height = 224
    ring.uri = "pkg:/images/ui/home-card-focus-ring.png"
    ring.loadDisplayMode = "scaleToFit"
    ring.visible = focused

    chrome = grp.createChild("Poster")
    chrome.width = cardW
    chrome.height = cardH
    if liveFilter
      chrome.uri = "pkg:/images/ui/library-live-card.png"
    else
      chrome.uri = "pkg:/images/ui/home-recent-card.png"
    end if
    chrome.loadDisplayMode = "scaleToFit"

    poster = grp.createChild("Poster")
    if liveFilter
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

    if liveFilter
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
    lbl.text = UCase(name)
    lbl.font.size = 16
    lbl.color = "0xD1D5DBFF"
  end for
end sub

sub renderLibraryFilters()
  root = m.top.findNode("libraryFilters")
  clearChildren(root)
  if m.libraryMode = "parental"
    labels = ["Live TV", "Movies", "Series"]
    pillW = 220
  else
    labels = [
      "Live TV (" + m.countLive.ToStr() + ")"
      "Movies (" + m.countMovie.ToStr() + ")"
      "Series (" + m.countSeries.ToStr() + ")"
    ]
    pillW = 280
  end if
  iconsLight = [
    "pkg:/images/ui/library-icon-live.png"
    "pkg:/images/ui/library-icon-movies.png"
    "pkg:/images/ui/library-icon-series.png"
  ]
  iconsDark = [
    "pkg:/images/ui/library-icon-live-dark.png"
    "pkg:/images/ui/library-icon-movies-dark.png"
    "pkg:/images/ui/library-icon-series-dark.png"
  ]
  gap = 16
  pillH = 64
  iconSize = 22
  ' Vertically center icon + label in 64px pill (Web align-items: center)
  iconY = Int((pillH - iconSize) / 2)
  labelY = Int((pillH - 28) / 2)
  padL = 24
  iconTextGap = 10
  x = 0
  for i = 0 to 2
    selected = (i = m.filterIndex)
    focused = (m.focusZone = "filters" and i = m.filterIndex)
    grp = root.createChild("Group")
    grp.translation = [x, 0]

    ring = grp.createChild("Poster")
    ring.translation = [-10, -10]
    ring.width = pillW + 20
    ring.height = pillH + 20
    ring.uri = "pkg:/images/ui/library-filter-focus.png"
    ring.loadDisplayMode = "scaleToFit"
    ring.visible = focused and selected

    bg = grp.createChild("Poster")
    bg.width = pillW
    bg.height = pillH
    if selected
      bg.uri = "pkg:/images/ui/library-filter-selected.png"
    else
      bg.uri = "pkg:/images/ui/library-filter.png"
    end if
    bg.loadDisplayMode = "scaleToFill"

    icon = grp.createChild("Poster")
    icon.translation = [padL, iconY]
    icon.width = iconSize
    icon.height = iconSize
    if selected
      icon.uri = iconsDark[i]
    else
      icon.uri = iconsLight[i]
    end if
    icon.loadDisplayMode = "scaleToFit"

    lbl = grp.createChild("Label")
    lbl.translation = [padL + iconSize + iconTextGap, labelY]
    lbl.width = pillW - (padL + iconSize + iconTextGap + 20)
    lbl.height = 28
    lbl.vertAlign = "center"
    lbl.text = labels[i]
    lbl.font.size = 22
    if selected
      lbl.color = "0x111111FF"
    else
      lbl.color = "0xFFFFFFFF"
    end if

    x = x + pillW + gap
  end for
end sub

sub renderParentalCategories()
  root = m.top.findNode("libraryGrid")
  clearChildren(root)
  ' Keep grid below filters + section title (do not move to overlap filters)
  root.translation = [72, 270]

  section = m.top.findNode("librarySectionTitle")
  section.visible = true
  section.text = "Browse Categories"
  section.translation = [72, 214]

  empty = m.top.findNode("libraryEmpty")
  if m.libraryCategories.Count() = 0
    empty.visible = true
    empty.translation = [72, 360]
    empty.text = "No content has been restricted under parental control."
    return
  end if
  empty.visible = false

  cardW = 327
  cardH = 184
  gapX = 35
  gapY = 18
  maxShow = m.libraryCategories.Count()
  if maxShow > 20 then maxShow = 20
  for i = 0 to maxShow - 1
    cat = m.libraryCategories[i]
    name = cat.name
    if name = invalid then name = "Category"
    focused = (m.focusZone = "grid" and i = m.gridIndex)
    col = i mod m.cols
    row = Int(i / m.cols)
    grp = root.createChild("Group")
    grp.translation = [col * (cardW + gapX), row * (cardH + gapY)]

    ring = grp.createChild("Poster")
    ring.translation = [-16, -16]
    ring.width = 372
    ring.height = 224
    ring.uri = "pkg:/images/ui/home-card-focus-ring.png"
    ring.loadDisplayMode = "scaleToFit"
    ring.visible = focused

    bg = grp.createChild("Poster")
    bg.width = cardW
    bg.height = cardH
    if LCase(name) = "all" or LCase(name) = "noticias" or Instr(1, LCase(name), "news") > 0
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

sub renderLibraryGrid()
  root = m.top.findNode("libraryGrid")
  clearChildren(root)
  section = m.top.findNode("librarySectionTitle")
  if m.libraryMode = "parental" and m.activeCategory <> ""
    section.visible = true
    section.text = "Category | " + m.activeCategory
    section.translation = [72, 214]
    root.translation = [72, 270]
  else
    section.visible = false
    root.translation = [72, 220]
  end if

  empty = m.top.findNode("libraryEmpty")
  if m.filteredItems.Count() = 0
    empty.visible = true
    empty.translation = [72, 360]
    if m.libraryMode = "parental"
      empty.text = "No content has been restricted under parental control."
    else
      empty.text = "No favorites in this section yet."
    end if
    return
  end if
  empty.visible = false

  liveFilter = (libraryFilterType() = "LIVE")
  cardW = 327
  cardH = 184
  gapX = 35
  gapY = 48
  cols = 5

  maxShow = m.filteredItems.Count()
  if maxShow > 15 then maxShow = 15
  for i = 0 to maxShow - 1
    item = m.filteredItems[i]
    focused = (m.focusZone = "grid" and i = m.gridIndex)
    col = i mod cols
    row = Int(i / cols)
    grp = root.createChild("Group")
    grp.translation = [col * (cardW + gapX), row * (cardH + gapY)]

    ring = grp.createChild("Poster")
    ring.translation = [-16, -16]
    ring.width = 372
    ring.height = 224
    ring.uri = "pkg:/images/ui/home-card-focus-ring.png"
    ring.loadDisplayMode = "scaleToFit"
    ring.visible = focused

    chrome = grp.createChild("Poster")
    chrome.width = cardW
    chrome.height = cardH
    if liveFilter
      chrome.uri = "pkg:/images/ui/library-live-card.png"
    else
      chrome.uri = "pkg:/images/ui/home-recent-card.png"
    end if
    chrome.loadDisplayMode = "scaleToFit"

    poster = grp.createChild("Poster")
    if liveFilter
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

    if liveFilter
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
    lbl.text = UCase(name)
    lbl.font.size = 16
    lbl.color = "0xD1D5DBFF"
  end for
end sub

sub clearChildren(root as Object)
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while
end sub

function posterArt(item as Object) as String
  if item = invalid then return "pkg:/images/channel-poster.png"
  if item.tvgLogo <> invalid and item.tvgLogo <> "" then return item.tvgLogo
  if item.streamIcon <> invalid and item.streamIcon <> "" then return item.streamIcon
  if item.cover <> invalid and item.cover <> "" then return item.cover
  if item.backdropPath <> invalid and item.backdropPath <> "" then return item.backdropPath
  return "pkg:/images/channel-poster.png"
end function

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

function recentCardPitch() as Integer
  return 362 ' cardW 327 + gap 35
end function

sub updateRecentScrollOffset()
  if m.recentScrollX = invalid then m.recentScrollX = 0
  if m.recent.Count() = 0
    m.recentScrollX = 0
    return
  end if
  pitch = recentCardPitch()
  cardW = 327
  viewW = 1776
  pad = 28
  if m.recentIndex < 0 then m.recentIndex = 0
  if m.recentIndex >= m.recent.Count() then m.recentIndex = m.recent.Count() - 1
  focusLeft = m.recentIndex * pitch
  focusRight = focusLeft + cardW
  if focusRight - m.recentScrollX > viewW - pad
    m.recentScrollX = focusRight - (viewW - pad)
  end if
  if focusLeft - m.recentScrollX < pad
    m.recentScrollX = focusLeft - pad
  end if
  if m.recentScrollX < 0 then m.recentScrollX = 0
  maxScroll = m.recent.Count() * pitch - 35 - viewW
  if maxScroll < 0 then maxScroll = 0
  if m.recentScrollX > maxScroll then m.recentScrollX = maxScroll
end sub

sub renderRecent()
  root = m.top.findNode("recentRoot")
  clearChildren(root)
  ' Clip so scrolled cards do not draw over the left gutter
  root.clippingRect = [-16, -20, 1808, 250]
  cardW = 327
  cardH = 184
  gap = 35
  pitch = cardW + gap
  updateRecentScrollOffset()
  for i = 0 to m.recent.Count() - 1
    item = m.recent[i]
    focused = (m.focusZone = "recent" and i = m.recentIndex)
    grp = root.createChild("Group")
    grp.translation = [i * pitch - m.recentScrollX, 0]

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
  if maxShow > 60 then maxShow = 60

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
  layoutTitlesChrome()
  if m.isVod
    renderPosterGrid()
  else
    renderLiveTitleGrid()
  end if
  updateScroll()
end sub

sub layoutTitlesChrome()
  search = m.top.findNode("titlesSearch")
  if m.isVod
    search.visible = true
    placeholder = "Search for movies..."
    if m.contentType = "SERIES" then placeholder = "Search for series..."
    m.top.findNode("titlesSearchText").text = placeholder
    if m.focusZone = "search"
      m.top.findNode("titlesSearchFocus").color = "0xFFFFFFFF"
      m.top.findNode("titlesSearchText").color = "0xFFFFFFFF"
    else
      m.top.findNode("titlesSearchFocus").color = "0x00000000"
      m.top.findNode("titlesSearchText").color = "0x9CA3AFFF"
    end if
    m.top.findNode("titlesHeading").translation = [72, 132]
  else
    search.visible = false
    m.top.findNode("titlesHeading").translation = [72, 40]
  end if
end sub

sub renderLiveTitleGrid()
  root = m.top.findNode("gridRoot")
  clearChildren(root)
  maxShow = m.channels.Count()
  if maxShow > 60 then maxShow = 60
  for i = 0 to maxShow - 1
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

sub renderPosterGrid()
  root = m.top.findNode("gridRoot")
  clearChildren(root)
  cardW = 268
  posterH = 402
  gapX = 24
  cols = 6
  maxShow = m.channels.Count()
  if maxShow > 60 then maxShow = 60
  for i = 0 to maxShow - 1
    item = m.channels[i]
    focused = (m.focusZone = "grid" and i = m.gridIndex)
    col = i mod cols
    row = Int(i / cols)
    grp = root.createChild("Group")
    grp.translation = [col * (cardW + gapX), row * gridRowPitch()]

    if focused
      border = grp.createChild("Rectangle")
      border.translation = [-5, -5]
      border.width = cardW + 10
      border.height = posterH + 10
      border.color = "0x0451DFFF"
    end if

    poster = grp.createChild("Poster")
    poster.width = cardW
    poster.height = posterH
    poster.loadDisplayMode = "scaleToZoom"
    poster.uri = posterArt(item)

    badge = ratingBadge(item)
    badgeW = 96
    chip = grp.createChild("Rectangle")
    chip.translation = [cardW - badgeW - 12, 14]
    chip.width = badgeW
    chip.height = 40
    chip.color = badge.color
    badgeLbl = grp.createChild("Label")
    badgeLbl.translation = [cardW - badgeW - 12, 18]
    badgeLbl.width = badgeW
    badgeLbl.height = 32
    badgeLbl.horizAlign = "center"
    badgeLbl.text = "★ " + badge.label
    badgeLbl.font.size = 18
    badgeLbl.color = "0xFFFFFFFF"

    name = "Title"
    if item.name <> invalid and item.name <> "" then name = item.name
    lbl = grp.createChild("Label")
    lbl.translation = [0, posterH + 12]
    lbl.width = cardW
    lbl.height = 32
    lbl.text = name
    lbl.font.size = 20
    if focused
      lbl.color = "0xFFFFFFFF"
    else
      lbl.color = "0xE5E7EBFF"
    end if
  end for
end sub

function ratingBadge(item as Object) as Object
  raw = invalid
  if item <> invalid
    if item.rating5based <> invalid then raw = item.rating5based
    if (raw = invalid or raw = "") and item.rating_5based <> invalid then raw = item.rating_5based
    if (raw = invalid or raw = "") and item.rating <> invalid then raw = item.rating
  end if
  if raw = invalid or raw.ToStr() = "" then return { label: "N/A", color: "0x64748BFF" }
  val = Val(raw.ToStr())
  if val <= 0 then return { label: "N/A", color: "0x64748BFF" }
  if val > 5 then val = val / 2.0
  tenths = Int(val * 10 + 0.5)
  label = Int(tenths / 10).ToStr() + "." + (tenths mod 10).ToStr()
  color = "0xF97316FF"
  if val >= 4
    color = "0x12B76AFF"
  else if val >= 3
    color = "0x64748BFF"
  end if
  return { label: label, color: color }
end function

sub openTitlesForCategory(catName as String)
  m.activeCategory = catName
  m.view = "titles"
  showBrowseChrome()
  heading = catName
  if heading = "" then heading = "All"
  m.focusZone = "grid"
  m.top.findNode("titlesHeading").text = "Category | " + heading
  m.top.findNode("contentRoot").translation = [0, 0]
  m.gridScrollOffset = 0
  m.top.findNode("gridRoot").translation = [72, titlesGridBaseY()]
  clearLoadedContent()
  showBrowseChrome()
  showLoadingStatus()
  startContentTask(m.contentType, "LIVE", catName)
end sub

sub returnToBrowse()
  m.view = "browse"
  m.activeCategory = ""
  clearLoadedContent()
  showBrowseChrome()
  layoutBrowseY()
  showLoadingStatus()
  startContentTask(m.contentType, "LIVE", "")
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    if m.isLibrary and m.libraryMode = "parental" and not m.libraryShowingCategories
      returnParentalToCategories()
      return true
    end if
    if m.view = "titles" and not m.isLibrary
      returnToBrowse()
      return true
    end if
    m.top.backSelected = true
    return true
  end if

  if m.isLibrary and m.libraryMode = "parental" and not m.libraryShowingCategories
    return handleParentalCategoryKeys(key)
  end if
  if m.isLibrary then return handleLibraryKeys(key)
  if m.view = "titles" then return handleGridKeys(key)
  return handleBrowseKeys(key)
end function

function handleParentalCategoryKeys(key as String) as Boolean
  count = m.filteredItems.Count()
  if key = "up"
    if m.gridIndex >= m.cols
      m.gridIndex = m.gridIndex - m.cols
      refreshFocusVisuals()
    end if
    return true
  end if
  if key = "down"
    if m.gridIndex + m.cols < count
      m.gridIndex = m.gridIndex + m.cols
      refreshFocusVisuals()
    end if
    return true
  end if
  if key = "left"
    if m.gridIndex > 0
      m.gridIndex = m.gridIndex - 1
      refreshFocusVisuals()
    end if
    return true
  end if
  if key = "right"
    if m.gridIndex < count - 1
      m.gridIndex = m.gridIndex + 1
      refreshFocusVisuals()
    end if
    return true
  end if
  if key = "OK"
    if m.gridIndex >= 0 and m.gridIndex < count
      m.top.channelSelected = m.filteredItems[m.gridIndex]
    end if
    return true
  end if
  return false
end function

function handleLibraryKeys(key as String) as Boolean
  gridCount = 0
  if m.libraryMode = "parental" and m.libraryShowingCategories
    gridCount = m.libraryCategories.Count()
  else
    gridCount = m.filteredItems.Count()
  end if

  if key = "up"
    if m.focusZone = "grid"
      if m.gridIndex < m.cols
        m.focusZone = "filters"
      else
        m.gridIndex = m.gridIndex - m.cols
      end if
      refreshFocusVisuals()
    end if
    return true
  end if

  if key = "down"
    if m.focusZone = "filters"
      if gridCount > 0
        m.focusZone = "grid"
        m.gridIndex = 0
        refreshFocusVisuals()
      end if
    else if m.gridIndex + m.cols < gridCount
      m.gridIndex = m.gridIndex + m.cols
      refreshFocusVisuals()
    end if
    return true
  end if

  if key = "left"
    if m.focusZone = "filters"
      m.filterIndex = m.filterIndex - 1
      if m.filterIndex < 0 then m.filterIndex = 0
      m.gridIndex = 0
      renderLibraryFilters()
      reloadLibraryFilter()
    else if m.gridIndex > 0
      m.gridIndex = m.gridIndex - 1
      refreshFocusVisuals()
    end if
    return true
  end if

  if key = "right"
    if m.focusZone = "filters"
      m.filterIndex = m.filterIndex + 1
      if m.filterIndex > 2 then m.filterIndex = 2
      m.gridIndex = 0
      renderLibraryFilters()
      reloadLibraryFilter()
    else if m.gridIndex < gridCount - 1
      m.gridIndex = m.gridIndex + 1
      refreshFocusVisuals()
    end if
    return true
  end if

  if key = "OK"
    if m.focusZone = "filters"
      if gridCount > 0
        m.focusZone = "grid"
        m.gridIndex = 0
        refreshFocusVisuals()
      end if
    else if m.focusZone = "grid"
      if m.libraryMode = "parental" and m.libraryShowingCategories
        if m.gridIndex >= 0 and m.gridIndex < m.libraryCategories.Count()
          openParentalCategory(m.libraryCategories[m.gridIndex].name)
        end if
      else if m.gridIndex >= 0 and m.gridIndex < m.filteredItems.Count()
        m.top.channelSelected = m.filteredItems[m.gridIndex]
      end if
    end if
    return true
  end if

  return false
end function

function handleBrowseKeys(key as String) as Boolean
  if key = "up"
    if m.focusZone = "cats"
      if m.catIndex < m.cols
        if m.recent.Count() > 0
          m.focusZone = "recent"
          if m.recentIndex >= m.recent.Count() then m.recentIndex = m.recent.Count() - 1
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
  if m.focusZone = "search"
    if key = "down"
      m.focusZone = "grid"
      renderGrid()
    end if
    return true
  end if

  cols = titleCols()
  if key = "up"
    if m.isVod and m.gridIndex < cols
      m.focusZone = "search"
      renderGrid()
    else if m.gridIndex >= cols
      m.gridIndex = m.gridIndex - cols
      renderGrid()
    end if
    return true
  end if
  if key = "down"
    if m.gridIndex + cols < m.channels.Count()
      m.gridIndex = m.gridIndex + cols
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
