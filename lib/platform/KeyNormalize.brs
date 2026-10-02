function DuplexNormalizeKey(key as String) as String
    lk = LCase(key)
    if lk = "up" or lk = "down" or lk = "left" or lk = "right"
        return lk
    end if
    if lk = "ok" then return "OK"
    if lk = "back" or lk = "escape" then return "back"
    if lk = "play" or lk = "playfrombeginning" then return "play"
    if lk = "pause" then return "pause"
    if lk = "replay" or lk = "instantreplay" then return "replay"
    if lk = "fastforward" then return "fastforward"
    if lk = "rewind" then return "rewind"
    if lk = "0" or lk = "1" or lk = "2" or lk = "3" or lk = "4" or lk = "5" or lk = "6" or lk = "7" or lk = "8" or lk = "9"
        return lk
    end if
    if lk = "lit_0" or lk = "lit_1" or lk = "lit_2" or lk = "lit_3" or lk = "lit_4" or lk = "lit_5" or lk = "lit_6" or lk = "lit_7" or lk = "lit_8" or lk = "lit_9"
        return Right(lk, 1)
    end if
    return key
end function
