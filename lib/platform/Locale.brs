' Simple locale loader (Phase 5 i18n foundation)
function DuplexLoadLocale(lang as String) as Object
    path = "pkg:/locale/" + lang + ".json"
    text = ReadAsciiFile(path)
    if text = invalid or text = ""
        text = ReadAsciiFile("pkg:/locale/en.json")
    end if
    if text = invalid or text = ""
        return {}
    end if
    parsed = ParseJson(text)
    if parsed = invalid then return {}
    return parsed
end function

function DuplexT(keyName as String) as String
    g = GetGlobalAA()
    if g.duplexLocale = invalid
        g.duplexLocale = DuplexLoadLocale("en")
    end if
    value = g.duplexLocale[keyName]
    if value = invalid or value = ""
        return keyName
    end if
    return value
end function

sub DuplexSetLanguage(lang as String)
    g = GetGlobalAA()
    g.duplexLocale = DuplexLoadLocale(lang)
    DuplexRegistryWrite("language", lang)
end sub
