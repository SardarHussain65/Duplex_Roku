' DetailInfoTask — movie/series info plus favorite and lock ids.
sub Init()
  m.top.functionName = "loadDetail"
end sub

sub loadDetail()
  item = m.top.item
  playlistId = m.top.playlistId
  kind = "MOVIE"
  if item <> invalid and item.contentType <> invalid and UCase(item.contentType) = "SERIES" then kind = "SERIES"
  contentId = DuplexContentId(item)
  info = invalid
  infoError = ""
  if playlistId <> "" and contentId <> ""
    if kind = "SERIES"
      fetched = DuplexFetchSeriesInfo(playlistId, contentId, 1)
    else
      fetched = DuplexFetchMovieInfo(playlistId, contentId)
    end if
    if fetched <> invalid and fetched.error <> invalid
      infoError = fetched.error
    else if fetched <> invalid
      info = fetched.data
    end if
  end if

  favoriteId = ""
  lockId = ""
  if playlistId <> ""
    fav = DuplexFetchFavorites(playlistId, 1, 50, kind)
    favoriteId = DuplexMatchLibraryId(fav, "getFavorites", item)
    locks = DuplexFetchParentalControls(playlistId, 1, 50, kind, "")
    lockId = DuplexMatchLibraryId(locks, "getParentalControls", item)
  end if

  m.top.result = {
    info: info
    infoError: infoError
    favoriteId: favoriteId
    lockId: lockId
    contentId: contentId
  }
end sub
