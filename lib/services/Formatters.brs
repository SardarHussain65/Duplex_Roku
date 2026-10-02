function DuplexPlaylistTypeLabel(typeValue as String) as String
    lower = LCase(typeValue)
    if Instr(1, lower, "xtream") > 0 or Instr(1, lower, "xtreme") > 0 or Instr(1, lower, "xui") > 0 or lower = "xc"
        return "Xtream Codes"
    end if
    return "Playlist URL"
end function

function DuplexTruncateUrl(url as String, maxLen as Integer) as String
    if len(url) <= maxLen
        return url
    end if
    return Left(url, maxLen - 3) + "..."
end function

function DuplexPreviewPlaylists() as Object
    return [
        { id: "1", name: "Live top", url: "http://appe-buntu.top/get.php?username=Duplex2&password=***", type: "url", isPinRequired: false }
        { id: "2", name: "Blade", url: "http://example.com/get.php?username=demo&password=demo", type: "url", isPinRequired: false }
        { id: "3", name: "five top", url: "http://example.com/get.php?username=demo&password=demo", type: "url", isPinRequired: false }
        { id: "4", name: "URL Playlist flash", url: "http://example.com/playlist.m3u8", type: "url", isPinRequired: false }
    ]
end function
