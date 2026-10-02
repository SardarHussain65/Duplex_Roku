' PlaylistCard — rounded Poster chrome matching Web TV (radius 14).
sub init()
  m.cardArt = m.top.findNode("cardArt")
  m.urlLabel = m.top.findNode("urlLabel")
  styleLabel(m.top.findNode("nameLabel"), 24, "0xFFFFFFFF")
  styleLabel(m.urlLabel, 18, "0x9CA3AFFF")
  styleLabel(m.top.findNode("tagLabel"), 14, "0x9BA1A6FF")
  styleLabel(m.top.findNode("tagGlyph"), 14, "0x9BA1A6FF")
  styleLabel(m.top.findNode("iconGlyph"), 26, "0x9BA1A6FF")
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
    m.cardArt.uri = "pkg:/images/ui/playlist-card-focus.png"
    m.urlLabel.color = "0xE5E7EBFF"
    m.top.findNode("iconGlyph").color = "0xFFFFFFFF"
  else
    m.cardArt.uri = "pkg:/images/ui/playlist-card.png"
    m.urlLabel.color = "0x9CA3AFFF"
    m.top.findNode("iconGlyph").color = "0x9BA1A6FF"
  end if
end sub
