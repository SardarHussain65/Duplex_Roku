' Match Web TV: every cold start begins on Splash.
' Tokens may still persist for activation API; never skip to Hub.
function DuplexResolveInitialScreen() as String
    DuplexLog("cold start → splash")
    return DuplexScreenSplash()
end function
