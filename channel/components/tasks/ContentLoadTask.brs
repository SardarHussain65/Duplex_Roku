' ContentLoadTask component script. Markup lives in ContentLoadTask.xml.
sub Init()
  m.top.functionName = "loadContent"
end sub

sub loadContent()
  playlistId = m.top.playlistId
  contentType = m.top.contentType
  if contentType = "" then contentType = "LIVE"

  if contentType = "FAVORITES"
    fav = DuplexFetchFavorites(playlistId)
    if fav.error <> invalid
      if DuplexIsDev()
        m.top.categories = [{ name: "All" }]
        m.top.channels = DuplexPreviewLiveChannels()
        return
      end if
      m.top.error = fav.error
      return
    end if
    items = []
    if fav.data <> invalid
      if fav.data.getFavorites <> invalid
        items = fav.data.getFavorites
      else if GetInterface(fav.data, "ifArray") <> invalid
        items = fav.data
      end if
    end if
    m.top.categories = [{ name: "All" }]
    m.top.channels = items
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
