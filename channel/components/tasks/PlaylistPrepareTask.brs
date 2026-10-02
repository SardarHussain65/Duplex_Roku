' PlaylistPrepareTask component script. Markup lives in PlaylistPrepareTask.xml.
sub Init()
  m.top.functionName = "preparePlaylist"
end sub

sub emitStep(stepKey as String, status as String)
  m.top.stepUpdate = { stepKey: stepKey, status: status }
end sub

sub preparePlaylist()
  playlistId = m.top.playlistId
  DuplexLog("prepare task for " + playlistId)

  emitStep("connecting", "loading")
  infoResult = DuplexFetchConnectionInfo(playlistId)
  emitStep("connecting", "done")

  if infoResult.error <> invalid
    if DuplexIsDev()
      emitStep("liveTv", "loading")
      emitStep("liveTv", "done")
      emitStep("movies", "loading")
      emitStep("movies", "done")
      emitStep("series", "loading")
      emitStep("series", "done")
      emitStep("finalizing", "loading")
      DuplexSaveActivePlaylistId(playlistId)
      emitStep("finalizing", "done")
      m.top.complete = true
      return
    end if
    m.top.error = infoResult.error
    return
  end if

  info = infoResult.data

  emitStep("liveTv", "loading")
  if DuplexNeedsClientIngest(info) and info.endpoints <> invalid
    liveCat = DuplexFetchJsonUrl(info.endpoints.liveCategories)
    liveStr = DuplexFetchJsonUrl(info.endpoints.liveStreams)
    if liveStr.error <> invalid
      m.top.error = liveStr.error
      return
    end if
    up = DuplexUploadPartition(playlistId, "LIVE", DuplexPruneLiveStreams(liveStr.data))
    if up.error <> invalid
      m.top.error = up.error
      return
    end if
  else
    live = DuplexPrefetchContentTab(playlistId, "LIVE")
    if live.error <> invalid and not DuplexIsDev()
      m.top.error = live.error
      return
    end if
  end if
  emitStep("liveTv", "done")

  emitStep("movies", "loading")
  if DuplexNeedsClientIngest(info) and info.endpoints <> invalid and info.endpoints.vodStreams <> invalid
    vod = DuplexFetchJsonUrl(info.endpoints.vodStreams)
    if vod.error = invalid
      DuplexUploadPartition(playlistId, "MOVIE", DuplexPruneGenericCatalog(vod.data))
    end if
  else
    DuplexPrefetchContentTab(playlistId, "MOVIE")
  end if
  emitStep("movies", "done")

  emitStep("series", "loading")
  if DuplexNeedsClientIngest(info) and info.endpoints <> invalid and info.endpoints.series <> invalid
    series = DuplexFetchJsonUrl(info.endpoints.series)
    if series.error = invalid
      DuplexUploadPartition(playlistId, "SERIES", DuplexPruneGenericCatalog(series.data))
    end if
  else
    DuplexPrefetchContentTab(playlistId, "SERIES")
  end if
  emitStep("series", "done")

  emitStep("finalizing", "loading")
  if DuplexNeedsClientIngest(info)
    fin = DuplexFinalizeIngest(playlistId)
    if fin.error <> invalid and not DuplexIsDev()
      m.top.error = fin.error
      return
    end if
  end if
  DuplexSaveActivePlaylistId(playlistId)
  emitStep("finalizing", "done")
  m.top.complete = true
end sub
