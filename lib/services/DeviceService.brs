function DuplexRegisterDevice(hardwareId as String) as Object
    query = "mutation GenerateDeviceId($input: GenerateDeviceIdInput!) { generateDeviceId(input: $input) { device { id hasUsedTrial isTrial deviceKey status country } subscription { id startDate endDate status } refreshToken accessToken hasPlaylist } }"
    body = {
        query: query
        variables: {
            input: {
                macAddress: hardwareId
            }
        }
    }
    result = DuplexGraphqlPost(body)
    if result.error <> invalid
        return result
    end if

    payload = result.data.generateDeviceId
    if payload = invalid
        return { error: "Missing generateDeviceId payload" }
    end if

    if payload.accessToken <> invalid and payload.refreshToken <> invalid
        DuplexSaveTokens(payload.accessToken, payload.refreshToken)
    end if

    device = payload.device
    if device <> invalid
        if device.id <> invalid
            DuplexSaveDeviceId(device.id)
        end if
        if device.deviceKey <> invalid
            DuplexSaveDeviceKey(device.deviceKey)
        end if
        if device.status <> invalid
            DuplexSaveDeviceStatus(device.status)
        end if
    end if

    if payload.subscription <> invalid
        DuplexSaveSubscriptionJson(FormatJson(payload.subscription))
    end if

    return { data: payload }
end function
