' Parental control GraphQL — mirrors Duplex_Web_TV src/api/operations/parental.ts
function DuplexVerifyParentalPin(pin as String, playlistId as String) as Object
    query = "mutation VerifyParentalControlPin($input: VerifyPlaylistPinInput!) { verifyParentalControlPin(input: $input) }"
    body = {
        query: query
        variables: { input: { pin: pin, playlistId: playlistId } }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexSetParentalPin(pin as String, playlistId as String) as Object
    query = "mutation SetParentalControlPin($input: VerifyPlaylistPinInput!) { setParentalControlPin(input: $input) }"
    body = {
        query: query
        variables: { input: { pin: pin, playlistId: playlistId } }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexGetParentalToggle(playlistId as String) as Object
    query = "query GetToggleParentalControl($playlistId: ID!) { getToggleParentalControl(playlistId: $playlistId) { id isRestricted pin } }"
    body = {
        query: query
        variables: { playlistId: playlistId }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexToggleParentalControl(playlistId as String) as Object
    query = "mutation ToggleParentalControl($playlistId: ID!) { toggleParentalControl(playlistId: $playlistId) { id isRestricted } }"
    body = {
        query: query
        variables: { playlistId: playlistId }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexFetchParentalCategories(playlistId as String, contentType as String) as Object
    if contentType = invalid or contentType = "" then contentType = "LIVE"
    query = "query GetParentalControlCategories($filters: QueryParentalControlCategoriesInput!) { getParentalControlCategories(filters: $filters) { name type count } }"
    body = {
        query: query
        variables: { filters: { playlistId: playlistId, type: contentType } }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexFetchParentalControls(playlistId as String, page as Integer, limit as Integer, contentType as String, category as String) as Object
    if page < 1 then page = 1
    if limit < 1 then limit = 50
    if contentType = invalid or contentType = "" then contentType = "LIVE"
    filters = {
        playlistId: playlistId
        page: page
        limit: limit
        type: contentType
    }
    if category <> invalid and category <> ""
        filters.category = category
    end if
    query = "query GetParentalControls($filters: QueryParentalControlInput!) { getParentalControls(filters: $filters) { data { metadata id type playlistId name } total totalLive totalMovies totalSeries } }"
    body = {
        query: query
        variables: { filters: filters }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexPreviewParentalCategories(contentType as String) as Object
    if contentType = "MOVIE"
        return [
            { name: "Action", count: 3 }
            { name: "Kids", count: 2 }
            { name: "Drama", count: 1 }
        ]
    else if contentType = "SERIES"
        return [
            { name: "Animation", count: 3 }
            { name: "Comedy", count: 2 }
            { name: "Drama", count: 1 }
        ]
    end if
    return [
        { name: "News", count: 2 }
        { name: "Sports", count: 3 }
        { name: "Entertainment", count: 1 }
    ]
end function
