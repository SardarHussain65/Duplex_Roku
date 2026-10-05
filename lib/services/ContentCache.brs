' Session cache for catalog data. Lives until the channel process exits,
' the playlist is prepared again, or Settings clears cache.
' Recently watched is not stored here.

function duplexReadContentCache() as Object
    if m.global = invalid then return {}
    if m.global.duplexContentCache = invalid
        m.global.addFields({ duplexContentCache: {} })
    end if
    bag = m.global.duplexContentCache
    if bag = invalid then return {}
    return bag
end function

function duplexWriteContentCache(bag as Object)
    if m.global = invalid or bag = invalid then return
    m.global.duplexContentCache = bag
end function

function duplexCopyList(items as Object) as Object
    out = []
    if items = invalid then return out
    if GetInterface(items, "ifArray") = invalid then return out
    for each item in items
        out.Push(item)
    end for
    return out
end function

function duplexCacheSep() as String
    return Chr(31)
end function

function duplexChannelCacheKey(playlistId as String, contentType as String, category as String, page as Integer) as String
    if category = invalid then category = ""
    if page < 1 then page = 1
    return playlistId + duplexCacheSep() + UCase(contentType) + duplexCacheSep() + "channels" + duplexCacheSep() + category + duplexCacheSep() + page.ToStr()
end function

function duplexCategoryCacheKey(playlistId as String, contentType as String) as String
    return playlistId + duplexCacheSep() + UCase(contentType) + duplexCacheSep() + "categories"
end function

function duplexDetailCacheKey(playlistId as String, contentId as String) as String
    return playlistId + duplexCacheSep() + "DETAIL" + duplexCacheSep() + contentId
end function

function DuplexGetCachedChannels(playlistId as String, contentType as String, category as String, page as Integer) as Object
    if playlistId = invalid or playlistId = "" then return invalid
    bag = duplexReadContentCache()
    key = duplexChannelCacheKey(playlistId, contentType, category, page)
    if bag.DoesExist(key) = false then return invalid
    entry = bag[key]
    if entry = invalid or entry.items = invalid then return invalid
    return entry.items
end function

function DuplexPutCachedChannels(playlistId as String, contentType as String, category as String, page as Integer, items as Object)
    if playlistId = invalid or playlistId = "" then return
    bag = duplexReadContentCache()
    bag[duplexChannelCacheKey(playlistId, contentType, category, page)] = { items: duplexCopyList(items) }
    duplexWriteContentCache(bag)
end function

function DuplexGetCachedCategories(playlistId as String, contentType as String) as Object
    if playlistId = invalid or playlistId = "" then return invalid
    bag = duplexReadContentCache()
    key = duplexCategoryCacheKey(playlistId, contentType)
    if bag.DoesExist(key) = false then return invalid
    entry = bag[key]
    if entry = invalid or entry.items = invalid then return invalid
    return entry.items
end function

function DuplexPutCachedCategories(playlistId as String, contentType as String, items as Object)
    if playlistId = invalid or playlistId = "" then return
    bag = duplexReadContentCache()
    bag[duplexCategoryCacheKey(playlistId, contentType)] = { items: duplexCopyList(items) }
    duplexWriteContentCache(bag)
end function

function DuplexGetCachedDetail(playlistId as String, contentId as String) as Object
    if playlistId = invalid or playlistId = "" or contentId = invalid or contentId = "" then return invalid
    bag = duplexReadContentCache()
    key = duplexDetailCacheKey(playlistId, contentId)
    if bag.DoesExist(key) = false then return invalid
    return bag[key]
end function

function DuplexPutCachedDetail(playlistId as String, contentId as String, payload as Object)
    if playlistId = invalid or playlistId = "" or contentId = invalid or contentId = "" or payload = invalid then return
    bag = duplexReadContentCache()
    bag[duplexDetailCacheKey(playlistId, contentId)] = payload
    duplexWriteContentCache(bag)
end function

function DuplexClearContentCache(playlistId as String)
    if m.global = invalid or m.global.duplexContentCache = invalid then return
    if playlistId = invalid or playlistId = ""
        m.global.duplexContentCache = {}
        return
    end if
    prefix = playlistId + duplexCacheSep()
    source = m.global.duplexContentCache
    nextBag = {}
    for each key in source
        if Left(key, Len(prefix)) <> prefix then nextBag[key] = source[key]
    end for
    m.global.duplexContentCache = nextBag
end function
