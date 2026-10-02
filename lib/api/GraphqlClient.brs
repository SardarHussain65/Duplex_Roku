function DuplexGraphqlPostRaw(body as Object, withAuth as Boolean) as Object
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(DuplexGraphqlUrl())
    request.AddHeader("Content-Type", "application/json")
    request.AddHeader("Accept", "application/json")
    if withAuth
        token = DuplexLoadAccessToken()
        if token <> ""
            request.AddHeader("Authorization", "Bearer " + token)
        end if
    end if
    request.SetRequest("POST")

    payload = FormatJson(body)
    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    responseText = invalid
    httpCode = 0

    if request.AsyncPostFromString(payload)
        while true
            msg = wait(30000, port)
            if msg = invalid
                return { error: "Network request timed out", httpCode: 0 }
            end if
            if type(msg) = "roUrlEvent"
                httpCode = msg.GetResponseCode()
                responseText = msg.GetString()
                exit while
            end if
        end while
    else
        responseText = request.PostFromString(payload)
        httpCode = request.GetResponseCode()
    end if

    if httpCode = 401
        return { error: "Unauthorized", httpCode: 401 }
    end if

    if httpCode <> 0 and httpCode <> 200
        return { error: "HTTP " + httpCode.ToStr(), httpCode: httpCode }
    end if

    if responseText = invalid or (type(responseText) = "roString" and responseText = "")
        return { error: "Network request failed", httpCode: httpCode }
    end if
    if type(responseText) <> "roString" and type(responseText) <> "String"
        return { error: "Unexpected network response", httpCode: httpCode }
    end if

    parsed = ParseJson(responseText)
    if parsed = invalid
        return { error: "Invalid JSON response", httpCode: httpCode }
    end if

    if parsed.errors <> invalid and parsed.errors.Count() > 0
        err = parsed.errors[0]
        message = "GraphQL error"
        if err.message <> invalid
            message = err.message
        end if
        return { error: message, httpCode: httpCode }
    end if

    return { data: parsed.data, httpCode: httpCode }
end function

function DuplexGraphqlPost(body as Object) as Object
    result = DuplexGraphqlPostRaw(body, true)
    if result.httpCode = 401
        refresh = DuplexAuthRefresh()
        if refresh.error <> invalid
            DuplexAuthExpireSession()
            return { error: "Session expired" }
        end if
        result = DuplexGraphqlPostRaw(body, true)
    end if
    return result
end function
