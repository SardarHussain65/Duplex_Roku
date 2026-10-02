' Watch history GraphQL stubs (Phase 5)
function DuplexSaveWatchHistory(input as Object) as Object
    query = "mutation SaveWatchHistory($input: SaveWatchHistoryInput!) { saveWatchHistory(input: $input) }"
    body = {
        query: query
        variables: { input: input }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexGetWatchHistory(playlistId as String) as Object
    query = "query GetWatchHistory($playlistId: String!) { getWatchHistory(playlistId: $playlistId) { items { id name contentType progress } } }"
    body = {
        query: query
        variables: { playlistId: playlistId }
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
                contentType: contentType
            }
        }
    }
    return DuplexGraphqlPost(body)
end function
