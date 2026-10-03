' ContentLoadTask component script. Markup lives in ContentLoadTask.xml.
sub Init()
  m.top.functionName = "loadContent"
end sub

sub loadContent()
  playlistId = m.top.playlistId
  contentType = m.top.contentType
  if contentType = "" then contentType = "LIVE"

  if contentType = "FAVORITES"
    loadFavorites()
    return
  end if

  if contentType = "PARENTAL"
    loadParental()
    return
  end if

  cats = DuplexFetchCategories(playlistId, contentType)
  if cats.error <> invalid
    if DuplexIsDev()
      m.top.categories = DuplexPreviewCategories()
      if contentType = "MOVIE" or contentType = "SERIES"
        m.top.channels = DuplexPreviewVodTitles(contentType)
      else
        m.top.channels = DuplexPreviewLiveChannels()
      end if
      return
    end if
    m.top.error = cats.error
    return
  end if

  channels = DuplexFetchChannels(playlistId, contentType, m.top.page, m.top.limit, m.top.category, "")
  if channels.error <> invalid
    if DuplexIsDev()
      m.top.categories = DuplexPreviewCategories()
      if contentType = "MOVIE" or contentType = "SERIES"
        m.top.channels = DuplexPreviewVodTitles(contentType)
      else
        m.top.channels = DuplexPreviewLiveChannels()
      end if
      return
    end if
    m.top.error = channels.error
    return
  end if

  m.top.categories = cats.data
  m.top.channels = channels.data
end sub

sub loadFavorites()
  playlistId = m.top.playlistId
  favType = m.top.favoriteType
  if favType = invalid or favType = "" then favType = "LIVE"
  page = m.top.page
  limit = m.top.limit
  if limit < 1 then limit = 50

  DuplexLog("favorites load type=" + favType + " playlist=" + playlistId)
  fav = DuplexFetchFavorites(playlistId, page, limit, favType)
  if fav.error <> invalid
    DuplexLog("favorites error: " + fav.error)
    if DuplexIsDev() and (playlistId = invalid or playlistId = "")
      m.top.categories = [{ name: "All" }]
      m.top.channels = DuplexPreviewFavorites()
      m.top.totalLive = 3
      m.top.totalMovies = 1
      m.top.totalSeries = 1
      return
    end if
    m.top.error = fav.error
    return
  end if

  payload = invalid
  if fav.data <> invalid then payload = fav.data.getFavorites
  if payload = invalid
    m.top.categories = [{ name: "All" }]
    m.top.channels = []
    m.top.totalLive = 0
    m.top.totalMovies = 0
    m.top.totalSeries = 0
    return
  end if

  rows = []
  if payload.data <> invalid then rows = payload.data
  mapped = DuplexMapFavoriteRecords(rows, favType)

  totalLive = 0
  totalMovies = 0
  totalSeries = 0
  if payload.totalLive <> invalid then totalLive = payload.totalLive
  if payload.totalMovies <> invalid then totalMovies = payload.totalMovies
  if payload.totalSeries <> invalid then totalSeries = payload.totalSeries

  m.top.categories = [{ name: "All" }]
  m.top.totalLive = totalLive
  m.top.totalMovies = totalMovies
  m.top.totalSeries = totalSeries
  m.top.channels = mapped
  DuplexLog("favorites ok count=" + mapped.Count().ToStr())
end sub

sub loadParental()
  playlistId = m.top.playlistId
  favType = m.top.favoriteType
  if favType = invalid or favType = "" then favType = "LIVE"
  category = m.top.category
  page = m.top.page
  limit = m.top.limit
  if limit < 1 then limit = 50

  ' Empty category → locked categories list; otherwise locked titles in that category
  if category = invalid or category = ""
    DuplexLog("parental categories type=" + favType)
    cats = DuplexFetchParentalCategories(playlistId, favType)
    if cats.error <> invalid
      DuplexLog("parental cats error: " + cats.error)
      if DuplexIsDev() and (playlistId = invalid or playlistId = "")
        m.top.categories = DuplexPreviewParentalCategories(favType)
        m.top.channels = []
        return
      end if
      m.top.error = cats.error
      return
    end if
    rows = []
    if cats.data <> invalid and cats.data.getParentalControlCategories <> invalid
      rows = cats.data.getParentalControlCategories
    end if
    out = []
    if rows <> invalid
      for each row in rows
        if row <> invalid and row.name <> invalid and row.name <> ""
          out.Push({ name: row.name, count: row.count, type: row.type })
        end if
      end for
    end if
    m.top.categories = out
    m.top.channels = []
    return
  end if

  DuplexLog("parental items type=" + favType + " category=" + category)
  list = DuplexFetchParentalControls(playlistId, page, limit, favType, category)
  if list.error <> invalid
    DuplexLog("parental items error: " + list.error)
    if DuplexIsDev() and (playlistId = invalid or playlistId = "")
      m.top.categories = []
      m.top.channels = DuplexPreviewFavorites()
      return
    end if
    m.top.error = list.error
    return
  end if

  payload = invalid
  if list.data <> invalid then payload = list.data.getParentalControls
  rows = []
  if payload <> invalid and payload.data <> invalid then rows = payload.data
  ' Reuse favorite mapper — parental records share metadata shape
  m.top.categories = []
  m.top.channels = DuplexMapFavoriteRecords(rows, favType)
end sub
