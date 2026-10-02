' Build / runtime flags. isDev=true keeps simulator-friendly fallbacks.
function DuplexIsDev() as Boolean
    return true
end function

function DuplexIsSimulator() as Boolean
    di = CreateObject("roDeviceInfo")
    model = di.GetModel()
    if model = invalid or model = "" then return true
    if Instr(1, LCase(model), "brs") > 0 then return true
    return false
end function

function DuplexApiBaseUrl() as String
    return "https://backend.duplexnew.com"
end function

function DuplexGraphqlUrl() as String
    return DuplexApiBaseUrl() + "/graphql"
end function

sub DuplexLog(message as String)
    if DuplexIsDev()
        print "Duplex: " + message
    end if
end sub
