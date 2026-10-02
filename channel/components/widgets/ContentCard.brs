' ContentCard component script. Markup lives in ContentCard.xml.
sub init()
  styleLabel(m.top.findNode("titleLabel"), 18, "0xFFFFFFFF")
  styleLabel(m.top.findNode("subLabel"), 14, "0x9CA3AFFF")
  setFocused(false)
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPosterChanged()
  uri = m.top.cardPoster
  if uri <> invalid and uri <> ""
    m.top.findNode("poster").uri = uri
  end if
end sub

sub onFocusChanged()
  setFocused(m.top.cardFocused)
end sub

sub setFocused(focused as Boolean)
  if focused
    m.top.findNode("border").color = "0x588BEAFF"
    m.top.findNode("cardBg").color = "0x23262FFF"
  else
    m.top.findNode("border").color = "0x353945FF"
    m.top.findNode("cardBg").color = "0x1C1E24FF"
  end if
end sub
