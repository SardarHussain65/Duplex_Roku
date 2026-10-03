' Settings GraphQL — mirrors Duplex_Web_TV src/api/operations/settings.ts
function DuplexFetchPlaylistAutoplay(playlistId as String) as Object
    if playlistId = "" then return { data: DuplexLoadAutoplay() }
    query = "query GetAutoplayByPlaylistId($playlistId: String!) { getAutoplayByPlaylistId(playlistId: $playlistId) { autoplay playlistId } }"
    body = {
        query: query
        variables: { playlistId: playlistId }
    }
    result = DuplexGraphqlPost(body)
    if result.error <> invalid then return result
    row = result.data.getAutoplayByPlaylistId
    if row = invalid or row.autoplay = invalid
        return { data: DuplexLoadAutoplay() }
    end if
    return { data: row.autoplay = true }
end function

function DuplexTogglePlaylistAutoplay(playlistId as String, autoplay as Boolean) as Object
    if playlistId = ""
        DuplexSaveAutoplay(autoplay)
        return { data: autoplay }
    end if
    query = "mutation AutoplayToggle($autoplay: Boolean!, $playlistId: String!) { autoplayToggle(autoplay: $autoplay, playlistId: $playlistId) { autoplay playlistId } }"
    body = {
        query: query
        variables: {
            autoplay: autoplay
            playlistId: playlistId
        }
    }
    result = DuplexGraphqlPost(body)
    if result.error <> invalid
        DuplexSaveAutoplay(autoplay)
        return { data: autoplay }
    end if
    row = result.data.autoplayToggle
    enabled = autoplay
    if row <> invalid and row.autoplay <> invalid then enabled = row.autoplay = true
    DuplexSaveAutoplay(enabled)
    return { data: enabled }
end function
