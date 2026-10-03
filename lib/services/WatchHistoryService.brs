' Watch history GraphQL — mirrors Duplex_Web_TV watchHistory ops
function DuplexSaveWatchHistory(input as Object) as Object
    query = "mutation SaveWatchHistory($input: SaveWatchHistoryInput!) { saveWatchHistory(input: $input) }"
    body = {
        query: query
        variables: { input: input }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexGetWatchHistory(playlistId as String, page as Integer, limit as Integer, contentType as String) as Object
    if page < 1 then page = 1
    if limit < 1 then limit = 50
    if contentType = invalid or contentType = "" then contentType = "LIVE"
    query = "query GetWatchHistory($filters: QueryWatchHistoryInput!) { getWatchHistory(filters: $filters) { data { id name type metadata lastWatchedAt watchedPercent } total totalLive totalMovies totalSeries } }"
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

function DuplexClearWatchHistory(playlistId as String, contentType as String) as Object
    query = "mutation ClearWatchHistory($input: ClearWatchHistoryInput!) { clearWatchHistory(input: $input) }"
    body = {
        query: query
        variables: {
            input: {
                playlistId: playlistId
                type: contentType
            }
        }
    }
    return DuplexGraphqlPost(body)
end function
