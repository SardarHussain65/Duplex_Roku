function DuplexRestRequest(method as String, path as String, bodyJson as Object) as Object
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(DuplexApiBaseUrl() + path)
    request.AddHeader("Accept", "application/json")
    token = DuplexLoadAccessToken()
    if token <> ""
        request.AddHeader("Authorization", "Bearer " + token)
    end if
    request.SetRequest(method)

    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    responseText = invalid
    httpCode = 0

    if method = "GET"
        if request.AsyncGetToString()
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
            responseText = request.GetToString()
            httpCode = request.GetResponseCode()
        end if
    else
        request.AddHeader("Content-Type", "application/json")
        payload = "{}"
        if bodyJson <> invalid
            payload = FormatJson(bodyJson)
        end if
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
    end if

    if httpCode = 401
        refresh = DuplexAuthRefresh()
        if refresh.error <> invalid
            DuplexAuthExpireSession()
            return { error: "Session expired", httpCode: 401 }
        end if
        return DuplexRestRequest(method, path, bodyJson)
    end if

    if httpCode <> 0 and (httpCode < 200 or httpCode >= 300)
        return { error: "HTTP " + httpCode.ToStr(), httpCode: httpCode }
    end if

    if responseText = invalid or responseText = ""
        if httpCode >= 200 and httpCode < 300
            return { data: {}, httpCode: httpCode }
        end if
        return { error: "Network request failed", httpCode: httpCode }
    end if

    parsed = ParseJson(responseText)
    if parsed = invalid
        return { error: "Invalid JSON response", httpCode: httpCode }
    end if
    return { data: parsed, httpCode: httpCode }
end function

function DuplexRestGet(path as String) as Object
    return DuplexRestRequest("GET", path, invalid)
end function

function DuplexRestPost(path as String, bodyJson as Object) as Object
    return DuplexRestRequest("POST", path, bodyJson)
end function

function DuplexFetchJsonUrl(url as String) as Object
    request = CreateObject("roUrlTransfer")
    request.SetCertificatesFile("common:/certs/ca-bundle.crt")
    request.SetUrl(url)
    request.AddHeader("Accept", "application/json")
    request.AddHeader("User-Agent", "VLC/3.0.21 LibVLC/3.0.21")
    request.SetRequest("GET")

    port = CreateObject("roMessagePort")
    request.SetMessagePort(port)
    responseText = invalid

    if request.AsyncGetToString()
        while true
            msg = wait(45000, port)
            if msg = invalid
                return { error: "Provider request timed out" }
            end if
            if type(msg) = "roUrlEvent"
                code = msg.GetResponseCode()
                if code <> 200
                    return { error: "Provider HTTP " + code.ToStr() }
                end if
                responseText = msg.GetString()
                exit while
            end if
        end while
    else
        responseText = request.GetToString()
    end if

    if responseText = invalid or responseText = ""
        return { error: "Empty provider response" }
    end if
    parsed = ParseJson(responseText)
    if parsed = invalid
        return { error: "Invalid provider JSON" }
    end if
    return { data: parsed }
end function
