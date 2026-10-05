' SettingsLoadTask — playlist, parental, history, and autoplay reads and writes.
sub Init()
  m.top.functionName = "runSettings"
end sub

sub runSettings()
  section = m.top.section
  action = m.top.action
  if action = invalid or action = "" then action = "load"
  playlistId = m.top.playlistId
  bag = { section: section, action: action }

  if action = "toggleParental"
    result = DuplexToggleParentalControl(playlistId)
    if result <> invalid and result.error = invalid and result.data <> invalid and result.data.toggleParentalControl <> invalid
      bag.parentalOn = (result.data.toggleParentalControl.isRestricted = true)
    else
      bag.error = "Could not update parental control"
    end if
    m.top.result = bag
    return
  end if

  if action = "toggleAutoplay"
    result = DuplexTogglePlaylistAutoplay(playlistId, m.top.autoplay)
    if result <> invalid and result.error = invalid and result.data <> invalid
      bag.autoplayOn = (result.data = true)
    else
      bag.error = "Could not update autoplay"
    end if
    m.top.result = bag
    return
  end if

  if action = "clearHistory"
    if playlistId <> "" then DuplexClearWatchHistory(playlistId, m.top.historyType)
  end if

  if section = "playlist"
    result = DuplexFetchPlaylists(m.top.deviceId)
    if result <> invalid and result.error <> invalid
      bag.error = result.error
      bag.playlists = []
    else
      rows = []
      if result <> invalid and result.data <> invalid then rows = result.data
      bag.playlists = rows
    end if
  else if section = "parental"
    bag.parentalOn = false
    bag.parentalHasPin = false
    if playlistId <> ""
      result = DuplexGetParentalToggle(playlistId)
      if result <> invalid and result.error = invalid and result.data <> invalid and result.data.getToggleParentalControl <> invalid
        row = result.data.getToggleParentalControl
        bag.parentalOn = (row.isRestricted = true)
        if row.pin <> invalid and row.pin.ToStr() <> "" then bag.parentalHasPin = true
      else if result <> invalid and result.error <> invalid
        bag.error = result.error
      end if
    end if
  else if section = "history"
    bag.historyItems = []
    if playlistId = ""
      bag.error = "No active playlist"
    else
      result = DuplexGetWatchHistory(playlistId, 1, 50, m.top.historyType)
      if result <> invalid and result.error <> invalid
        bag.error = result.error
      else if result <> invalid and result.data <> invalid and result.data.getWatchHistory <> invalid
        payload = result.data.getWatchHistory
        if payload.data <> invalid then bag.historyItems = payload.data
        bag.totalLive = payload.totalLive
        bag.totalMovies = payload.totalMovies
        bag.totalSeries = payload.totalSeries
      end if
    end if
  else if section = "autoplay"
    bag.autoplayOn = DuplexLoadAutoplay()
    if playlistId <> ""
      result = DuplexFetchPlaylistAutoplay(playlistId)
      if result <> invalid and result.error = invalid and result.data <> invalid
        bag.autoplayOn = (result.data = true)
      else if result <> invalid and result.error <> invalid
        bag.error = result.error
      end if
    end if
  end if

  m.top.result = bag
end sub
