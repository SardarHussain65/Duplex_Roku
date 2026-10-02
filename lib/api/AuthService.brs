function DuplexAuthRefresh() as Object
    refreshToken = DuplexLoadRefreshToken()
    if refreshToken = ""
        return { error: "No refresh token" }
    end if

    query = "mutation RefreshTokenMobile($refreshToken: String!) { refreshTokenMobile(refreshToken: $refreshToken) { accessToken refreshToken } }"
    body = {
        query: query
        variables: {
            refreshToken: refreshToken
        }
    }

    ' Direct post without retry to avoid refresh loops
    result = DuplexGraphqlPostRaw(body, false)
    if result.error <> invalid
        return result
    end if

    payload = result.data.refreshTokenMobile
    if payload = invalid or payload.accessToken = invalid
        return { error: "Token refresh failed" }
    end if

    newRefresh = payload.refreshToken
    if newRefresh = invalid or newRefresh = ""
        newRefresh = refreshToken
    end if
    DuplexSaveTokens(payload.accessToken, newRefresh)
    return { data: payload }
end function

sub DuplexAuthExpireSession()
    DuplexLog("session expired — clearing tokens")
    DuplexClearTokens()
end sub
