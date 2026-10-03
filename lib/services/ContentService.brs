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

function DuplexPreviewVodTitles(contentType as String) as Object
    kind = "Movie"
    if contentType = "SERIES" then kind = "Series"
    return [
        { name: "007 Contra a Chantagem", contentType: contentType, groupTitle: "Action / Thriller", genre: "Action / Thriller", plot: "A relentless detective unravels a web of secrets as he hunts a mysterious assassin lurking in the shadows.", tvgLogo: "", backdropPath: "", releaseYear: 2024 }
        { name: "1917", contentType: contentType, groupTitle: "War", genre: "War / Drama", plot: "Two young soldiers are given a dangerous mission in enemy territory.", tvgLogo: "", backdropPath: "", releaseYear: 2019 }
        { name: "O Bom Bandido", contentType: contentType, groupTitle: "Drama", genre: "Crime / Drama", plot: "A notorious outlaw seeks redemption while being hunted by rivals.", tvgLogo: "", backdropPath: "", releaseYear: 2021 }
        { name: "Filhos do Ecstasy", contentType: contentType, groupTitle: "Drama", genre: "Drama", plot: "Friends chase nightlife thrills that spiral out of control.", tvgLogo: "", backdropPath: "", releaseYear: 2022 }
        { name: "Night Runner", contentType: contentType, groupTitle: "Action", genre: "Action", plot: "A courier is forced into a deadly overnight race across the city.", tvgLogo: "", backdropPath: "", releaseYear: 2023 }
        { name: "Silent Harbor", contentType: contentType, groupTitle: kind, genre: kind, plot: "A coastal town hides secrets beneath its quiet surface.", tvgLogo: "", backdropPath: "", releaseYear: 2020 }
    ]
end function
