' HomePanel component script. Markup lives in HomePanel.xml.
sub init()
  m.top.focusable = true
  m.focusZone = "grid"
  m.catIndex = 0
  m.gridIndex = 0
  m.cols = 5
  m.categories = []
  m.channels = []
  m.selectedCategory = ""
  m.contentType = "LIVE"

  styleLabel(m.top.findNode("title"), 36, "0xFFFFFFFF")
  styleLabel(m.top.findNode("heroTag"), 28, "0xFFFFFFFF")
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
  m.catIndex = 0
  m.gridIndex = 0
  m.selectedCategory = ""
  m.focusZone = "grid"

  sectionKey = m.top.initialTab
  if sectionKey = invalid or sectionKey = "" then sectionKey = "liveTv"
  m.contentType = sectionToContentType(sectionKey)
  titleMap = {
    liveTv: "Live TV"
    movies: "Movies"
    series: "Series"
    favorites: "Favorites"
    parental: "Parental Control"
  }
  titleText = titleMap[sectionKey]
  if titleText = invalid then titleText = "Browse"
  m.top.findNode("title").text = titleText
  m.top.findNode("statusLabel").text = "Loading..."
  m.top.findNode("statusLabel").visible = true

  showHero = (sectionKey = "liveTv")
  m.top.findNode("hero").visible = showHero
  m.top.findNode("heroFade").visible = showHero
  m.top.findNode("heroTag").visible = showHero
  if showHero
    m.top.findNode("title").translation = [80, 240]
    m.top.findNode("statusLabel").translation = [80, 360]
    m.top.findNode("catsRoot").translation = [80, 400]
    m.top.findNode("gridRoot").translation = [80, 480]
  else
    m.top.findNode("title").translation = [80, 40]
    m.top.findNode("statusLabel").translation = [80, 100]
    m.top.findNode("catsRoot").translation = [80, 150]
    m.top.findNode("gridRoot").translation = [80, 240]
  end if

  m.task.playlistId = DuplexLoadActivePlaylistId()
  m.task.contentType = m.contentType
  m.task.page = 1
  m.task.limit = 50
  m.task.category = ""
  m.task.control = "RUN"
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
  renderCategories()
end sub

sub onChannels()
  m.channels = m.task.channels
  if m.channels = invalid then m.channels = []
  m.top.findNode("statusLabel").visible = false
  if m.channels.Count() = 0
    m.top.findNode("statusLabel").text = "No channels found"
    m.top.findNode("statusLabel").visible = true
  end if
  m.gridIndex = 0
  renderGrid()
end sub

sub onError()
  err = m.task.error
  m.top.findNode("statusLabel").text = err
  m.top.findNode("statusLabel").visible = true
  if DuplexIsDev()
    m.categories = DuplexPreviewCategories()
    m.channels = DuplexPreviewLiveChannels()
    renderCategories()
    renderGrid()
    m.top.findNode("statusLabel").visible = false
  end if
end sub

sub renderCategories()
  root = m.top.findNode("catsRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while

  x = 0
  for i = 0 to m.categories.Count() - 1
    cat = m.categories[i]
    name = cat.name
    if name = invalid then name = "Category"
    grp = root.createChild("Group")
    grp.translation = [x, 0]
    bg = grp.createChild("Rectangle")
    bg.width = 180
    bg.height = 48
    if i = m.catIndex and m.focusZone = "cats"
      bg.color = "0x0451DFFF"
    else if name = m.selectedCategory or (m.selectedCategory = "" and i = 0)
      bg.color = "0x23262FFF"
    else
      bg.color = "0x1C1E24FF"
    end if
    lbl = grp.createChild("Label")
    lbl.translation = [0, 10]
    lbl.width = 180
    lbl.height = 28
    lbl.horizAlign = "center"
    lbl.text = name
    lbl.font.size = 18
    lbl.color = "0xFFFFFFFF"
    x = x + 200
    if x > 1700 then exit for
  end for
end sub

sub renderGrid()
  root = m.top.findNode("gridRoot")
  while root.getChildCount() > 0
    root.removeChildIndex(0)
  end while

  for i = 0 to m.channels.Count() - 1
    if i >= 15 then exit for
    item = m.channels[i]
    col = i mod m.cols
    row = Int(i / m.cols)
    card = root.createChild("ContentCard")
    card.translation = [col * 340, row * 210]
    title = item.name
    if title = invalid then title = "Channel"
    card.cardTitle = title
    subT = item.groupTitle
    if subT = invalid then subT = "Live"
    card.cardSubtitle = subT
    poster = item.tvgLogo
    if poster = invalid then poster = ""
    card.cardPoster = poster
    card.cardFocused = (i = m.gridIndex and m.focusZone = "grid")
  end for
end sub

sub reloadWithCategory()
  catName = ""
  if m.catIndex >= 0 and m.catIndex < m.categories.Count()
    catName = m.categories[m.catIndex].name
    if catName = "All" then catName = ""
  end if
  m.selectedCategory = catName
  m.top.findNode("statusLabel").text = "Loading..."
  m.top.findNode("statusLabel").visible = true
  m.task.contentType = m.contentType
  m.task.category = catName
  m.task.control = "RUN"
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    m.top.backSelected = true
    return true
  end if

  if key = "up"
    if m.focusZone = "grid"
      if m.gridIndex < m.cols
        m.focusZone = "cats"
        renderCategories()
        renderGrid()
      else
        m.gridIndex = m.gridIndex - m.cols
        renderGrid()
      end if
    end if
    return true
  end if

  if key = "down"
    if m.focusZone = "cats"
      m.focusZone = "grid"
      renderCategories()
      renderGrid()
    else if m.gridIndex + m.cols < m.channels.Count()
      m.gridIndex = m.gridIndex + m.cols
      renderGrid()
    end if
    return true
  end if

  if key = "left"
    if m.focusZone = "cats"
      m.catIndex = m.catIndex - 1
      if m.catIndex < 0 then m.catIndex = 0
      renderCategories()
    else if m.gridIndex > 0
      m.gridIndex = m.gridIndex - 1
      renderGrid()
    end if
    return true
  end if

  if key = "right"
    if m.focusZone = "cats"
      m.catIndex = m.catIndex + 1
      if m.catIndex >= m.categories.Count() then m.catIndex = m.categories.Count() - 1
      renderCategories()
    else if m.gridIndex < m.channels.Count() - 1
      m.gridIndex = m.gridIndex + 1
      renderGrid()
    end if
    return true
  end if

  if key = "OK"
    if m.focusZone = "cats"
      catName = ""
      if m.catIndex >= 0 and m.catIndex < m.categories.Count()
        catName = m.categories[m.catIndex].name
      end if
      sectionKey = m.top.initialTab
      if sectionKey = "liveTv" or sectionKey = "favorites" or sectionKey = "parental"
        if catName = "All" then catName = ""
        m.top.categorySelected = catName
      else
        reloadWithCategory()
      end if
    else if m.gridIndex >= 0 and m.gridIndex < m.channels.Count()
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
