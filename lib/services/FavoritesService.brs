' Favorites GraphQL stubs (Phase 5 — wired when Favorites UI ships)
function DuplexFetchFavorites(playlistId as String) as Object
    query = "query GetFavorites($playlistId: String!) { getFavorites(playlistId: $playlistId) { id name contentType } }"
    body = {
        query: query
        variables: { playlistId: playlistId }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexAddFavorite(input as Object) as Object
    query = "mutation AddFavorite($input: AddFavoriteInput!) { addFavorite(input: $input) { id } }"
    body = {
        query: query
        variables: { input: input }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexRemoveFavorite(input as Object) as Object
    query = "mutation RemoveFavorite($input: RemoveFavoriteInput!) { removeFavorite(input: $input) }"
    body = {
        query: query
        variables: { input: input }
    }
    return DuplexGraphqlPost(body)
end function
