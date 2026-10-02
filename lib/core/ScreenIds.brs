' Screen identifiers used by ScreenRouter / KeyRouter / Session
function DuplexScreenSplash() as String
    return "splash"
end function

function DuplexScreenActivation() as String
    return "activation"
end function

function DuplexScreenPlaylistSource() as String
    return "playlistSource"
end function

function DuplexScreenXtreamSetup() as String
    return "xtreamSetup"
end function

function DuplexScreenPlaylistLoading() as String
    return "playlistLoading"
end function

function DuplexScreenHub() as String
    return "hub"
end function

function DuplexScreenHome() as String
    return "home"
end function

function DuplexScreenLiveChannel() as String
    return "liveChannel"
end function

function DuplexScreenVodDetail() as String
    return "vodDetail"
end function

function DuplexScreenPlayer() as String
    return "player"
end function

function DuplexScreenSettings() as String
    return "settings"
end function

function DuplexScreenParentalPin() as String
    return "parentalPin"
end function

function DuplexAllScreenIds() as Object
    return [
        DuplexScreenSplash()
        DuplexScreenActivation()
        DuplexScreenPlaylistSource()
        DuplexScreenXtreamSetup()
        DuplexScreenPlaylistLoading()
        DuplexScreenHub()
        DuplexScreenHome()
        DuplexScreenLiveChannel()
        DuplexScreenVodDetail()
        DuplexScreenPlayer()
        DuplexScreenSettings()
        DuplexScreenParentalPin()
    ]
end function

function DuplexPanelIdForScreen(screenId as String) as String
    return screenId
end function
