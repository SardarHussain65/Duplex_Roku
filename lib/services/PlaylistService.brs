function DuplexFetchPlaylists(deviceId as String) as Object
    if deviceId = ""
        if DuplexIsDev()
            return { data: DuplexPreviewPlaylists() }
        end if
        return { error: "Device not registered" }
    end if

    query = "query GetPlaylistsByDevice($deviceId: String!, $limit: Float!, $page: Float!) { getPlaylistsByDevice(deviceId: $deviceId, limit: $limit, page: $page) { data { id name url type isPinRequired } } }"
    body = {
        query: query
        variables: {
            deviceId: deviceId
            limit: 50
            page: 1
        }
    }
    result = DuplexGraphqlPost(body)
    if result.error <> invalid
        return result
    end if

    rows = result.data.getPlaylistsByDevice.data
    if rows = invalid
        rows = []
    end if
    return { data: rows }
end function

function DuplexCreatePlaylist(input as Object) as Object
    query = "mutation CreatePlaylist($input: CreatePlaylistInput!) { createPlaylist(input: $input) { deviceId name pin id } }"
    body = {
        query: query
        variables: {
            input: input
        }
    }
    result = DuplexGraphqlPost(body)
    if result.error <> invalid
        return result
    end if

    payload = result.data.createPlaylist
    if payload = invalid or payload.id = invalid
        return { error: "Failed to create playlist" }
    end if
    return { data: payload }
end function
