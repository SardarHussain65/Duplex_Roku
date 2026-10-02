function DuplexDefaultMacAddress() as String
    return "02:00:00:00:00:00"
end function

function DuplexFormatDisplayCode(raw as String) as String
    clean = ""
    for i = 0 to len(raw) - 1
        ch = Mid(raw, i + 1, 1)
        code = Asc(ch)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
            if code >= 97
                code = code - 32
            end if
            clean = clean + Chr(code)
        end if
    end for
    if len(clean) < 8
        return "DPX - UNKNOWN"
    end if
    return "DPX - " + Left(clean, 4) + Right(clean, 4)
end function

function DuplexFormatDeviceKey(raw as String) as String
    if raw = invalid or raw = ""
        return "N/A"
    end if
    clean = ""
    for i = 0 to len(raw) - 1
        ch = Mid(raw, i + 1, 1)
        code = Asc(ch)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122)
            if code >= 97
                code = code - 32
            end if
            clean = clean + Chr(code)
        end if
    end for
    if len(clean) < 8
        return UCase(raw)
    end if
    return Left(clean, 4) + "-" + Right(clean, 4)
end function

function DuplexGetHardwareId() as String
    ' Simulator / constrained hosts keep the shared placeholder MAC.
    if DuplexIsSimulator() or DuplexIsDev()
        return DuplexDefaultMacAddress()
    end if

    di = CreateObject("roDeviceInfo")
    clientId = ""
    if di <> invalid
        clientId = di.GetChannelClientId()
        if clientId = invalid or clientId = ""
            clientId = di.GetClientTrackingId()
        end if
    end if

    if clientId = invalid or clientId = ""
        return DuplexDefaultMacAddress()
    end if
    return clientId
end function

function DuplexGetDisplayCode(hardwareId as String) as String
    ' Match Web TV formatDisplayCode — always DPX - XXXXYYYY (even for colon MACs).
    return DuplexFormatDisplayCode(hardwareId)
end function

function DuplexByteToHex(code as Integer) as String
    digits = "0123456789ABCDEF"
    hi = Int(code / 16)
    lo = code mod 16
    return Mid(digits, hi + 1, 1) + Mid(digits, lo + 1, 1)
end function

function DuplexUrlEncode(value as String) as String
    encoded = ""
    for i = 0 to len(value) - 1
        ch = Mid(value, i + 1, 1)
        code = Asc(ch)
        if (code >= 48 and code <= 57) or (code >= 65 and code <= 90) or (code >= 97 and code <= 122) or ch = "-" or ch = "_" or ch = "." or ch = "~"
            encoded = encoded + ch
        else
            encoded = encoded + "%" + DuplexByteToHex(code)
        end if
    end for
    return encoded
end function

function DuplexActivationQrUrl(hardwareId as String) as String
    encoded = DuplexUrlEncode(hardwareId)
    target = "https://duplex-iptv-website.vercel.app/activate/?mac=" + encoded
    return "https://api.qrserver.com/v1/create-qr-code/?size=280x280&margin=1&data=" + DuplexUrlEncode(target)
end function
