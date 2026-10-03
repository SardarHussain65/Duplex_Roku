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
  styleLabel(m.top.findNode("vodTitle"), 56, "0xFFFFFFFF")
  styleLabel(m.top.findNode("vodDesc"), 24, "0xD6D8E0FF")
  styleLabel(m.top.findNode("btnWatchLbl"), 24, "0xFFFFFFFF")
  styleLabel(m.top.findNode("btnLearnLbl"), 24, "0xFFFFFFFF")
  styleLabel(m.top.findNode("recentTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("catsTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("titlesHeading"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("libraryTitle"), 32, "0xFFFFFFFF")
  styleLabel(m.top.findNode("librarySectionTitle"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("libraryEmpty"), 24, "0x9CA3AFFF")
  styleLabel(m.top.findNode("statusLabel"), 20, "0x9CA3AFFF")

  m.task = m.top.createChild("ContentLoadTask")
  m.task.observeField("categories", "onCategories")
  m.task.observeField("channels", "onChannels")
  m.task.observeField("totalLive", "onFavoriteTotals")
  m.task.observeField("totalMovies", "onFavoriteTotals")
  m.task.observeField("totalSeries", "onFavoriteTotals")
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

  showBrowseChrome()
  m.top.findNode("contentRoot").translation = [0, 0]
  m.top.findNode("statusLabel").text = "Loading..."
  m.top.findNode("statusLabel").visible = true
  if m.isLibrary
    m.top.findNode("statusLabel").translation = [72, 280]
    m.focusZone = "filters"
    if m.libraryMode = "favorites"
      m.top.findNode("libraryTitle").text = "Favorites"
      m.task.contentType = "FAVORITES"
      m.task.favoriteType = libraryFilterType()
      m.task.category = ""
    else
      m.top.findNode("libraryTitle").text = "Parental Control"
      m.task.contentType = "PARENTAL"
      m.task.favoriteType = libraryFilterType()
      m.task.category = ""
    end if
  else if m.isVod
    m.top.findNode("statusLabel").translation = [72, 640]
    m.focusZone = "hero"
    m.task.contentType = m.contentType
    m.task.category = ""
  else
    m.top.findNode("statusLabel").translation = [72, 640]
    m.focusZone = "recent"
    m.task.contentType = m.contentType
    m.task.category = ""
  end if

  m.task.playlistId = DuplexLoadActivePlaylistId()
  m.task.page = 1
  m.task.limit = 50
  m.task.control = "RUN"
end sub

sub showBrowseChrome()
  m.top.findNode("liveHero").visible = m.isLive and m.view = "browse"
  m.top.findNode("vodHero").visible = m.isVod and m.view = "browse"
  parentalCategoryScreen = (m.isLibrary and m.libraryMode = "parental" and not m.libraryShowingCategories)
  m.top.findNode("libraryView").visible = m.isLibrary and not parentalCategoryScreen
  m.top.findNode("recentTitle").visible = false
  m.top.findNode("catsTitle").visible = false
  m.top.findNode("recentRoot").visible = (m.isLive or m.isVod) and m.view = "browse"
  m.top.findNode("catsRoot").visible = (m.isLive or m.isVod) and m.view = "browse"
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
  m.channels = m.task.channels
  if m.channels = invalid then m.channels = []
  m.top.findNode("statusLabel").visible = false

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
  ' Live hero ~810 (Web); VOD hero ~620 — keep recent below hero
  if m.isVod
    m.top.findNode("recentTitle").translation = [72, 640]
    m.top.findNode("recentRoot").translation = [72, 696]
    m.top.findNode("catsTitle").translation = [72, 960]
    m.top.findNode("catsRoot").translation = [72, 1016]
    m.top.findNode("statusLabel").translation = [72, 640]
  else
    m.top.findNode("recentTitle").translation = [72, 822]
    m.top.findNode("recentRoot").translation = [72, 878]
    m.top.findNode("catsTitle").translation = [72, 1120]
    m.top.findNode("catsRoot").translation = [72, 1176]
    m.top.findNode("statusLabel").translation = [72, 822]
  end if
end sub

sub onError()
  err = m.task.error
  m.top.findNode("statusLabel").text = err
  m.top.findNode("statusLabel").visible = true
  if DuplexIsDev()
    m.categories = DuplexPreviewCategories()
    if m.isLibrary
      if m.libraryMode = "parental"
        m.libraryCategories = DuplexPreviewParentalCategories(libraryFilterType())
        m.libraryShowingCategories = true
        m.filteredItems = []
        m.top.findNode("statusLabel").visible = false
        renderLibrary()
        return
      end if
      m.channels = DuplexPreviewFavorites()
      computeFavoriteCounts()
      m.filteredItems = []
      want = libraryFilterType()
      for each item in m.channels
        ct = item.contentType
        if ct = invalid then ct = "LIVE"
        if UCase(ct) = want then m.filteredItems.Push(item)
      end for
      m.top.findNode("statusLabel").visible = false
      renderLibrary()
      return
    else if m.isVod
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

sub onFavoriteTotals()
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
  m.top.findNode("statusLabel").text = "Loading..."
  m.top.findNode("statusLabel").visible = true
  m.top.findNode("statusLabel").translation = [72, 280]
  m.gridIndex = 0
  if m.libraryMode = "parental"
    m.libraryShowingCategories = true
    m.activeCategory = ""
    m.filteredItems = []
    m.task.contentType = "PARENTAL"
    m.task.favoriteType = libraryFilterType()
    m.task.category = ""
  else
    m.task.contentType = "FAVORITES"
    m.task.favoriteType = libraryFilterType()
    m.task.category = ""
  end if
  m.task.page = 1
  m.task.limit = 50
  m.task.control = "RUN"
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
  m.top.findNode("statusLabel").text = "Loading..."
  m.top.findNode("statusLabel").visible = true
  m.top.findNode("statusLabel").translation = [72, 120]
  m.top.findNode("contentRoot").translation = [0, 0]
  clearChildren(m.top.findNode("gridRoot"))
  m.task.contentType = "PARENTAL"
  m.task.favoriteType = libraryFilterType()
  m.task.category = catName
  m.task.page = 1
  m.task.limit = 50
  m.task.control = "RUN"
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
      ' Tall live hero — scroll so Browse Categories sits near top
      m.top.findNode("contentRoot").translation = [0, -1040]
    end if
  else if m.focusZone = "recent" and m.isVod
    m.top.findNode("contentRoot").translation = [0, -200]
  else if m.focusZone = "recent" and m.isLive
    ' Keep hero dominant; nudge slightly so recent row is fully on-screen
    m.top.findNode("contentRoot").translation = [0, -40]
  else
    m.top.findNode("contentRoot").translation = [0, 0]
  end if
end sub

sub refreshFocusVisuals()
  if m.isLibrary
    if m.libraryMode = "parental" and not m.libraryShowingCategories
      renderParentalCategoryItems()
      return
    end if
    renderLibrary()
    return
  end if
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
