function DuplexRegistrySection() as Object
    return CreateObject("roRegistrySection", "duplex")
end function

sub DuplexRegistryWrite(keyName as String, value as String)
    sec = DuplexRegistrySection()
    sec.Write(keyName, value)
    sec.Flush()
end sub

function DuplexRegistryRead(keyName as String) as String
    sec = DuplexRegistrySection()
    if sec.Exists(keyName)
        return sec.Read(keyName)
    end if
    return ""
end function

sub DuplexRegistryClear(keyName as String)
    sec = DuplexRegistrySection()
    if sec.Exists(keyName)
        sec.Delete(keyName)
        sec.Flush()
    end if
end sub

sub DuplexSaveTokens(accessToken as String, refreshToken as String)
    g = GetGlobalAA()
    g.duplexAccessToken = accessToken
    g.duplexRefreshToken = refreshToken
    DuplexRegistryWrite("accessToken", accessToken)
    DuplexRegistryWrite("refreshToken", refreshToken)
end sub

function DuplexLoadAccessToken() as String
    g = GetGlobalAA()
    if g.duplexAccessToken <> invalid and g.duplexAccessToken <> ""
        return g.duplexAccessToken
    end if
    return DuplexRegistryRead("accessToken")
end function

function DuplexLoadRefreshToken() as String
    g = GetGlobalAA()
    if g.duplexRefreshToken <> invalid and g.duplexRefreshToken <> ""
        return g.duplexRefreshToken
    end if
    return DuplexRegistryRead("refreshToken")
end function

sub DuplexClearTokens()
    g = GetGlobalAA()
    g.duplexAccessToken = ""
    g.duplexRefreshToken = ""
    DuplexRegistryClear("accessToken")
    DuplexRegistryClear("refreshToken")
end sub

sub DuplexSaveDeviceId(deviceId as String)
    g = GetGlobalAA()
    g.duplexDeviceId = deviceId
    DuplexRegistryWrite("deviceId", deviceId)
end sub

function DuplexLoadDeviceId() as String
    g = GetGlobalAA()
    if g.duplexDeviceId <> invalid and g.duplexDeviceId <> ""
        return g.duplexDeviceId
    end if
    return DuplexRegistryRead("deviceId")
end function

sub DuplexSaveDeviceKey(deviceKey as String)
    g = GetGlobalAA()
    g.duplexDeviceKey = deviceKey
    DuplexRegistryWrite("deviceKey", deviceKey)
end sub

function DuplexLoadDeviceKey() as String
    g = GetGlobalAA()
    if g.duplexDeviceKey <> invalid and g.duplexDeviceKey <> ""
        return g.duplexDeviceKey
    end if
    return DuplexRegistryRead("deviceKey")
end function

sub DuplexSaveActivePlaylistId(playlistId as String)
    g = GetGlobalAA()
    g.duplexActivePlaylistId = playlistId
    DuplexRegistryWrite("activePlaylistId", playlistId)
end sub

function DuplexLoadActivePlaylistId() as String
    g = GetGlobalAA()
    if g.duplexActivePlaylistId <> invalid and g.duplexActivePlaylistId <> ""
        return g.duplexActivePlaylistId
    end if
    return DuplexRegistryRead("activePlaylistId")
end function

sub DuplexSaveDeviceStatus(status as String)
    g = GetGlobalAA()
    g.duplexDeviceStatus = status
    DuplexRegistryWrite("deviceStatus", status)
end sub

function DuplexLoadDeviceStatus() as String
    g = GetGlobalAA()
    if g.duplexDeviceStatus <> invalid and g.duplexDeviceStatus <> ""
        return g.duplexDeviceStatus
    end if
    return DuplexRegistryRead("deviceStatus")
end function

sub DuplexSaveSubscriptionJson(jsonText as String)
    DuplexRegistryWrite("subscriptionJson", jsonText)
end sub

function DuplexLoadSubscriptionJson() as String
    return DuplexRegistryRead("subscriptionJson")
end function

sub DuplexClearSession()
    DuplexClearTokens()
    DuplexRegistryClear("deviceId")
    DuplexRegistryClear("deviceKey")
    DuplexRegistryClear("activePlaylistId")
    DuplexRegistryClear("deviceStatus")
    DuplexRegistryClear("subscriptionJson")
    g = GetGlobalAA()
    g.duplexDeviceId = ""
    g.duplexDeviceKey = ""
    g.duplexActivePlaylistId = ""
    g.duplexDeviceStatus = ""
end sub

sub DuplexSaveAutoplay(enabled as Boolean)
    value = "0"
    if enabled then value = "1"
    DuplexRegistryWrite("autoplay", value)
end sub

function DuplexLoadAutoplay() as Boolean
    return DuplexRegistryRead("autoplay") = "1"
end function

function DuplexHasValidSession() as Boolean
    token = DuplexLoadAccessToken()
    playlistId = DuplexLoadActivePlaylistId()
    return token <> "" and playlistId <> ""
end function
