function DuplexPlaylistTypeLabel(typeValue as String) as String
    lower = LCase(typeValue)
    if Instr(1, lower, "xtream") > 0 or Instr(1, lower, "xtreme") > 0 or Instr(1, lower, "xui") > 0 or lower = "xc"
        return "Xtreme Codes"
    end if
    return "Playlist URL"
end function

function DuplexTruncateUrl(url as String, maxLen as Integer) as String
    if len(url) <= maxLen
        return url
    end if
    return Left(url, maxLen - 3) + "..."
end function

sub DuplexFillSkeleton(parent as Object, bones as Object)
    if parent = invalid then return
    while parent.getChildCount() > 0
        parent.removeChildIndex(0)
    end while
    if bones = invalid then return
    for each bone in bones
        rect = parent.createChild("Rectangle")
        rect.translation = [bone.x, bone.y]
        rect.width = bone.w
        rect.height = bone.h
        tone = "card"
        if bone.tone <> invalid then tone = bone.tone
        if tone = "hero"
            rect.color = "0x1A1D24FF"
        else if tone = "line"
            rect.color = "0x3A4150FF"
        else
            rect.color = "0x2A2E38FF"
        end if
    end for
    parent.visible = true
end sub

sub DuplexHideSkeleton(parent as Object)
    if parent = invalid then return
    parent.visible = false
    while parent.getChildCount() > 0
        parent.removeChildIndex(0)
    end while
end sub

sub DuplexPulseSkeleton(parent as Object, bright as Boolean)
    if parent = invalid or not parent.visible then return
    amount = 0.62
    if bright then amount = 1
    count = parent.getChildCount()
    for i = 0 to count - 1
        child = parent.getChild(i)
        if child <> invalid then child.opacity = amount
    end for
end sub

function DuplexPreviewPlaylists() as Object
    return [
        { id: "1", name: "Live top", url: "http://appe-buntu.top/get.php?username=Duplex2&password=***", type: "url", isPinRequired: false }
        { id: "2", name: "Blade", url: "http://example.com/get.php?username=demo&password=demo", type: "url", isPinRequired: false }
        { id: "3", name: "five top", url: "http://example.com/get.php?username=demo&password=demo", type: "url", isPinRequired: false }
        { id: "4", name: "URL Playlist flash", url: "http://example.com/playlist.m3u8", type: "url", isPinRequired: false }
    ]
end function
