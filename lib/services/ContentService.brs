function DuplexFetchCategories(playlistId as String, contentType as String) as Object
    result = DuplexRestGet("/playlists/" + playlistId + "/channels/categories?contentType=" + contentType)
    if result.error <> invalid then return result
    items = []
    if result.data <> invalid and result.data.items <> invalid
        items = result.data.items
    end if
    return { data: items }
end function

function DuplexFetchChannels(playlistId as String, contentType as String, page as Integer, limit as Integer, category as String, search as String) as Object
    path = "/playlists/" + playlistId + "/channels?page=" + page.ToStr() + "&limit=" + limit.ToStr() + "&contentType=" + contentType
    if category <> invalid and category <> ""
        path = path + "&category=" + DuplexUrlEncode(category)
    end if
    if search <> invalid and search <> ""
        path = path + "&search=" + DuplexUrlEncode(search)
    end if
    result = DuplexRestGet(path)
    if result.error <> invalid then return result
    items = []
    if result.data <> invalid and result.data.items <> invalid
        items = result.data.items
    end if
    return { data: items }
end function

function DuplexResolveStreamUrl(url as String) as String
    if url = invalid or url = ""
        return ""
    end if
    if Left(url, 7) = "http://" or Left(url, 8) = "https://"
        return url
    end if
    return url
end function

function DuplexPreviewLiveChannels() as Object
    return [
        { name: "CNN HD", tvgId: "cnn", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", contentType: "LIVE", groupTitle: "News", tvgLogo: "" }
        { name: "Sports 1", tvgId: "sp1", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", contentType: "LIVE", groupTitle: "Sports", tvgLogo: "" }
        { name: "Movies Max", tvgId: "mm", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", contentType: "LIVE", groupTitle: "Movies", tvgLogo: "" }
        { name: "Kids Zone", tvgId: "kz", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", contentType: "LIVE", groupTitle: "Kids", tvgLogo: "" }
        { name: "Music TV", tvgId: "mtv", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", contentType: "LIVE", groupTitle: "Music", tvgLogo: "" }
        { name: "Documentary", tvgId: "doc", streamUrl: "https://test-streams.mux.dev/x36xhzz/x36xhzz.m3u8", contentType: "LIVE", groupTitle: "Docs", tvgLogo: "" }
    ]
end function

function DuplexPreviewCategories() as Object
    return [
        { name: "All", count: 6 }
        { name: "News", count: 1 }
        { name: "Sports", count: 1 }
        { name: "Movies", count: 1 }
        { name: "Kids", count: 1 }
        { name: "Music", count: 1 }
        { name: "Docs", count: 1 }
    ]
end function
