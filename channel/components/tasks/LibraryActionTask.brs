' LibraryActionTask — add or remove a favorite or parental lock.
sub Init()
  m.top.functionName = "runAction"
end sub

sub runAction()
  action = m.top.action
  item = m.top.item
  playlistId = m.top.playlistId
  bag = { action: action, ok: false, error: "" }
  if item = invalid or playlistId = ""
    bag.error = "Missing playlist"
    m.top.result = bag
    return
  end if

  if action = "status"
    kind = "LIVE"
    if item.contentType <> invalid and item.contentType <> "" then kind = UCase(item.contentType)
    fav = DuplexFetchFavorites(playlistId, 1, 50, kind)
    locks = DuplexFetchParentalControls(playlistId, 1, 50, kind, "")
    bag.ok = true
    bag.favoriteId = DuplexMatchLibraryId(fav, "getFavorites", item)
    bag.lockId = DuplexMatchLibraryId(locks, "getParentalControls", item)
    m.top.result = bag
    return
  end if

  kind = "LIVE"
  if item.contentType <> invalid and item.contentType <> "" then kind = UCase(item.contentType)
  name = "Title"
  if item.name <> invalid and item.name <> "" then name = item.name
  category = ""
  if item.category <> invalid and item.category <> "" then category = item.category
  if category = "" and item.groupTitle <> invalid then category = item.groupTitle
  if category = "" and item.genre <> invalid then category = item.genre

  meta = {
    name: name
    tvgId: textOf(item, "tvgId")
    tvgName: name
    tvgLogo: textOf(item, "tvgLogo")
    groupTitle: category
    contentType: kind
    category: category
    genre: textOf(item, "genre")
    streamUrl: textOf(item, "streamUrl")
    seriesStreamId: textOf(item, "seriesStreamId")
    plot: textOf(item, "plot")
    cast: textOf(item, "cast")
    rating: textOf(item, "rating")
  }
  if item.releaseYear <> invalid then meta.releaseYear = item.releaseYear

  if action = "addFavorite"
    result = DuplexAddFavorite({
      playlistId: playlistId
      name: name
      type: kind
      metadata: meta
    })
    if result <> invalid and result.error = invalid and result.data <> invalid and result.data.addFavorite <> invalid
      bag.ok = true
      if result.data.addFavorite.id <> invalid then bag.recordId = result.data.addFavorite.id.ToStr()
    else
      bag.error = "Could not save favorite"
    end if
  else if action = "removeFavorite"
    result = DuplexRemoveFavorite(m.top.recordId)
    if result <> invalid and result.error = invalid
      bag.ok = true
      bag.recordId = ""
    else
      bag.error = "Could not remove favorite"
    end if
  else if action = "addLock"
    result = DuplexAddParentalControl({
      playlistId: playlistId
      name: name
      type: kind
      category: category
      metadata: meta
    })
    if result <> invalid and result.error = invalid and result.data <> invalid and result.data.addParentalControl <> invalid
      bag.ok = true
      if result.data.addParentalControl.id <> invalid then bag.recordId = result.data.addParentalControl.id.ToStr()
    else
      bag.error = "Could not lock title"
    end if
  else if action = "removeLock"
    result = DuplexRemoveParentalControl({
      playlistId: playlistId
      id: m.top.recordId
      type: kind
      category: category
    })
    if result <> invalid and result.error = invalid
      bag.ok = true
      bag.recordId = ""
    else
      bag.error = "Could not unlock title"
    end if
  else
    bag.error = "Unknown action"
  end if

  m.top.result = bag
end sub

function textOf(source as Object, keyName as String) as String
  if source = invalid then return ""
  value = source[keyName]
  if value = invalid then return ""
  return value.ToStr()
end function
