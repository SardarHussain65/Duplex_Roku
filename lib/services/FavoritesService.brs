' Favorites GraphQL — mirrors Duplex_Web_TV src/api/operations/favorites.ts
function DuplexFetchFavorites(playlistId as String, page as Integer, limit as Integer, contentType as String) as Object
    if page < 1 then page = 1
    if limit < 1 then limit = 50
    if contentType = invalid or contentType = "" then contentType = "LIVE"

    query = "query GetFavorites($filters: QueryFavoriteInput!) { getFavorites(filters: $filters) { data { metadata id type playlistId name } total totalLive totalMovies totalSeries } }"
    filters = {
        playlistId: playlistId
        page: page
        limit: limit
        type: contentType
    }
    body = {
        query: query
        variables: { filters: filters }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexAddFavorite(input as Object) as Object
    query = "mutation AddFavorite($input: CreateFavoriteInput!) { addFavorite(input: $input) { id name type } }"
    body = {
        query: query
        variables: { input: input }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexRemoveFavorite(favoriteId as String) as Object
    query = "mutation RemoveFavorite($removeFavoriteId: ID!) { removeFavorite(id: $removeFavoriteId) }"
    body = {
        query: query
        variables: { removeFavoriteId: favoriteId }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexParseFavoriteMeta(raw as Object) as Object
    if raw = invalid then return {}
    if GetInterface(raw, "ifAssociativeArray") <> invalid then return raw
    if type(raw) = "roString" or type(raw) = "String"
        if raw = "" then return {}
        parsed = ParseJson(raw)
        if parsed <> invalid and GetInterface(parsed, "ifAssociativeArray") <> invalid
            return parsed
        end if
    end if
    return {}
end function

function DuplexFavoriteRecordToChannel(record as Object, fallbackType as String) as Object
    if record = invalid then return invalid
    meta = DuplexParseFavoriteMeta(record.metadata)
    contentType = fallbackType
    if record.type <> invalid and record.type <> ""
        contentType = UCase(record.type)
    else if meta.contentType <> invalid and meta.contentType <> ""
        contentType = UCase(meta.contentType)
    end if
    if contentType <> "MOVIE" and contentType <> "SERIES" then contentType = "LIVE"

    name = ""
    if meta.name <> invalid and meta.name <> "" then name = meta.name
    if name = "" and meta.tvgName <> invalid then name = meta.tvgName
    if name = "" and record.name <> invalid then name = record.name
    if name = "" and (meta.streamUrl = invalid or meta.streamUrl = "") then return invalid
    if name = "" then name = "Untitled"

    logo = ""
    if meta.tvgLogo <> invalid and meta.tvgLogo <> "" then logo = meta.tvgLogo
    if logo = "" and meta.logoUrl <> invalid then logo = meta.logoUrl

    streamUrl = ""
    if meta.streamUrl <> invalid then streamUrl = meta.streamUrl

    tvgId = name
    if meta.tvgId <> invalid and meta.tvgId <> "" then tvgId = meta.tvgId

    groupTitle = ""
    if meta.groupTitle <> invalid then groupTitle = meta.groupTitle

    genre = ""
    if meta.genre <> invalid then genre = meta.genre

    category = groupTitle
    if meta.category <> invalid and meta.category <> "" then category = meta.category
    if category = "" and genre <> "" then category = genre

    seriesStreamId = ""
    if meta.seriesStreamId <> invalid then seriesStreamId = meta.seriesStreamId
    if seriesStreamId = "" and meta.seriesId <> invalid then seriesStreamId = meta.seriesId

    releaseYear = invalid
    if meta.releaseYear <> invalid
        if GetInterface(meta.releaseYear, "ifInt") <> invalid or GetInterface(meta.releaseYear, "ifFloat") <> invalid
            releaseYear = Int(meta.releaseYear)
        else if GetInterface(meta.releaseYear, "ifString") <> invalid or type(meta.releaseYear) = "roString" or type(meta.releaseYear) = "String"
            releaseYear = Int(Val(meta.releaseYear))
        end if
    end if

    plot = ""
    if meta.plot <> invalid then plot = meta.plot

    channel = {
        id: record.id
        name: name
        tvgId: tvgId
        tvgName: name
        tvgLogo: logo
        backdropPath: logo
        groupTitle: groupTitle
        contentType: contentType
        category: category
        genre: genre
        streamUrl: streamUrl
        seriesStreamId: seriesStreamId
        plot: plot
        favoriteId: record.id
    }
    if releaseYear <> invalid and releaseYear > 0 then channel.releaseYear = releaseYear
    if meta.seriesTitle <> invalid then channel.seriesTitle = meta.seriesTitle
    if meta.rating <> invalid then channel.rating = meta.rating
    return channel
end function

function DuplexMapFavoriteRecords(records as Object, fallbackType as String) as Object
    out = []
    if records = invalid then return out
    if GetInterface(records, "ifArray") = invalid then return out
    for each record in records
        channel = DuplexFavoriteRecordToChannel(record, fallbackType)
        if channel <> invalid then out.Push(channel)
    end for
    return out
end function
