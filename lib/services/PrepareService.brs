function DuplexFetchConnectionInfo(playlistId as String) as Object
    return DuplexRestGet("/playlists/" + playlistId + "/connection-info")
end function

function DuplexNeedsClientIngest(info as Object) as Boolean
    if info = invalid then return false
    if info.requiresClientSync = true then return true
    if info.syncStatus <> invalid and UCase(info.syncStatus.ToStr()) = "REQUIRES_CLIENT_SYNC"
        return true
    end if
    return false
end function

function DuplexPruneLiveStreams(raw as Object) as Object
    out = []
    if raw = invalid then return out
    for each item in raw
        row = {}
        if item.stream_id <> invalid then row.stream_id = item.stream_id
        if item.name <> invalid then row.name = item.name
        if item.category_id <> invalid then row.category_id = item.category_id
        if item.stream_icon <> invalid then row.stream_icon = item.stream_icon
        if item.epg_channel_id <> invalid then row.epg_channel_id = item.epg_channel_id
        if item.num <> invalid then row.num = item.num
        out.Push(row)
    end for
    return out
end function

function DuplexPruneGenericCatalog(raw as Object) as Object
    out = []
    if raw = invalid then return out
    for each item in raw
        out.Push(item)
    end for
    return out
end function

function DuplexUploadPartition(playlistId as String, contentType as String, items as Object) as Object
    path = "/playlists/" + playlistId + "/client-ingest/partition?contentType=" + contentType
    return DuplexRestPost(path, { items: items })
end function

function DuplexFinalizeIngest(playlistId as String) as Object
    return DuplexRestPost("/playlists/" + playlistId + "/client-ingest/finalize", {})
end function

function DuplexPerformClientIngest(playlistId as String, endpoints as Object, emit as Object) as Object
    if endpoints = invalid
        return { error: "Missing ingest endpoints" }
    end if

    ' LIVE
    if emit <> invalid then emit.callback("liveTv", "loading")
    liveCat = DuplexFetchJsonUrl(endpoints.liveCategories)
    liveStr = DuplexFetchJsonUrl(endpoints.liveStreams)
    if liveStr.error <> invalid
        return liveStr
    end if
    liveItems = DuplexPruneLiveStreams(liveStr.data)
    up = DuplexUploadPartition(playlistId, "LIVE", liveItems)
    if up.error <> invalid then return up
    if emit <> invalid then emit.callback("liveTv", "done")

    ' MOVIE
    if emit <> invalid then emit.callback("movies", "loading")
    if endpoints.vodStreams <> invalid
        vod = DuplexFetchJsonUrl(endpoints.vodStreams)
        if vod.error = invalid
            up = DuplexUploadPartition(playlistId, "MOVIE", DuplexPruneGenericCatalog(vod.data))
            if up.error <> invalid then return up
        end if
    end if
    if emit <> invalid then emit.callback("movies", "done")

    ' SERIES
    if emit <> invalid then emit.callback("series", "loading")
    if endpoints.series <> invalid
        series = DuplexFetchJsonUrl(endpoints.series)
        if series.error = invalid
            up = DuplexUploadPartition(playlistId, "SERIES", DuplexPruneGenericCatalog(series.data))
            if up.error <> invalid then return up
        end if
    end if
    if emit <> invalid then emit.callback("series", "done")

    fin = DuplexFinalizeIngest(playlistId)
    if fin.error <> invalid then return fin
    return { data: true }
end function

function DuplexPrefetchContentTab(playlistId as String, contentType as String) as Object
    cats = DuplexRestGet("/playlists/" + playlistId + "/channels/categories?contentType=" + contentType)
    if cats.error <> invalid then return cats

    limit = 50
    if contentType <> "LIVE"
        limit = 48
    end if
    channels = DuplexRestGet("/playlists/" + playlistId + "/channels?page=1&limit=" + limit.ToStr() + "&contentType=" + contentType)
    if channels.error <> invalid then return channels

    items = []
    if channels.data <> invalid and channels.data.items <> invalid
        items = channels.data.items
    end if
    return { data: { categories: cats.data, channels: items } }
end function

' Task-callable prepare. emitCallback is optional AA with .callback(stepKey, status)
function DuplexPreparePlaylist(playlistId as String) as Object
    if playlistId = invalid or playlistId = ""
        return { error: "Missing playlist id" }
    end if

    DuplexLog("preparing playlist " + playlistId)

    infoResult = DuplexFetchConnectionInfo(playlistId)
    if infoResult.error <> invalid
        ' Dev/simulator fallback: succeed with fake progress so UI can be tested offline
        if DuplexIsDev()
            DuplexLog("connection-info failed in dev — using soft success")
            DuplexSaveActivePlaylistId(playlistId)
            return { data: { status: "success", soft: true } }
        end if
        return infoResult
    end if

    info = infoResult.data
    if DuplexNeedsClientIngest(info) and info.endpoints <> invalid
        ingest = DuplexPerformClientIngest(playlistId, info.endpoints, invalid)
        if ingest.error <> invalid
            return ingest
        end if
    end if

    live = DuplexPrefetchContentTab(playlistId, "LIVE")
    if live.error <> invalid
        if DuplexIsDev()
            DuplexSaveActivePlaylistId(playlistId)
            return { data: { status: "success", soft: true } }
        end if
        return live
    end if

    ' Warm MOVIE + SERIES caches (best effort)
    DuplexPrefetchContentTab(playlistId, "MOVIE")
    DuplexPrefetchContentTab(playlistId, "SERIES")

    DuplexSaveActivePlaylistId(playlistId)
    return { data: { status: "success" } }
end function
