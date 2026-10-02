' PlaylistCard component script. Markup lives in PlaylistCard.xml.
sub init()
  m.border = m.top.findNode("border")
  m.cardBg = m.top.findNode("cardBg")
  m.urlLabel = m.top.findNode("urlLabel")
  styleLabel(m.top.findNode("nameLabel"), 24, "0xFFFFFFFF")
  styleLabel(m.urlLabel, 18, "0x9CA3AFFF")
  styleLabel(m.top.findNode("tagLabel"), 14, "0x9BA1A6FF")
  styleLabel(m.top.findNode("iconGlyph"), 22, "0x9BA1A6FF")
  setFocused(false)
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onFocusChanged()
  setFocused(m.top.cardFocused)
end sub

sub setFocused(focused as Boolean)
  if focused
    m.border.color = "0xB1B5C3FF"
    m.cardBg.color = "0x353945FF"
    m.urlLabel.color = "0xE5E7EBFF"
    m.top.findNode("iconGlyph").color = "0xFFFFFFFF"
  else
    m.border.color = "0x353945FF"
    m.cardBg.color = "0x1C1E24FF"
    m.urlLabel.color = "0x9CA3AFFF"
    m.top.findNode("iconGlyph").color = "0x9BA1A6FF"
  end if
end sub
