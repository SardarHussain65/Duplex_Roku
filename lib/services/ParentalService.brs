' Parental control GraphQL (parity with Web TV)
function DuplexVerifyParentalPin(pin as String, playlistId as String) as Object
    query = "mutation VerifyParentalControlPin($input: VerifyParentalControlPinInput!) { verifyParentalControlPin(input: $input) }"
    body = {
        query: query
        variables: { input: { pin: pin, playlistId: playlistId } }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexSetParentalPin(pin as String, playlistId as String) as Object
    query = "mutation SetParentalControlPin($input: SetParentalControlPinInput!) { setParentalControlPin(input: $input) }"
    body = {
        query: query
        variables: { input: { pin: pin, playlistId: playlistId } }
    }
    return DuplexGraphqlPost(body)
end function

function DuplexGetParentalToggle(playlistId as String) as Object
    query = "query GetToggleParentalControl($playlistId: String!) { getToggleParentalControl(playlistId: $playlistId) { pin enabled } }"
    body = {
        query: query
        variables: { playlistId: playlistId }
    }
    return DuplexGraphqlPost(body)
end function
