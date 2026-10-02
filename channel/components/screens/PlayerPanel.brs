' PlayerPanel component script. Markup lives in PlayerPanel.xml.
sub init()
  m.top.focusable = true
  m.playing = false
  styleLabel(m.top.findNode("title"), 28, "0xFFFFFFFF")
  styleLabel(m.top.findNode("liveBadge"), 24, "0xFF3B5CFF")
  styleLabel(m.top.findNode("hint"), 20, "0xB1B5C3FF")
  styleLabel(m.top.findNode("status"), 20, "0x9CA3AFFF")

  m.video = m.top.findNode("video")
  m.video.observeField("state", "onVideoState")
  m.isLive = true
end sub

sub styleLabel(label as Object, size as Integer, color as String)
  if label = invalid then return
  label.font.size = size
  label.color = color
end sub

sub onPanelShown()
  m.top.backSelected = false
  channel = m.top.channel
  title = "Live"
  streamUrl = ""
  m.isLive = true
  if channel <> invalid
    if channel.name <> invalid then title = channel.name
    if channel.streamUrl <> invalid then streamUrl = channel.streamUrl
    if channel.contentType <> invalid
      if channel.contentType = "MOVIE" or channel.contentType = "SERIES"
        m.isLive = false
      end if
    end if
  end if
  m.top.findNode("title").text = title
  m.top.findNode("liveBadge").visible = m.isLive
  m.top.findNode("status").text = "Connecting..."

  stopPlayback()
  streamUrl = DuplexResolveStreamUrl(streamUrl)
  if streamUrl = ""
    m.top.findNode("status").text = "No stream URL available"
    return
  end if

  content = CreateObject("roSGNode", "ContentNode")
  content.url = streamUrl
  content.streamFormat = "hls"
  content.title = title
  m.video.content = content
  m.video.control = "play"
  m.playing = true
end sub

sub stopPlayback()
  if m.video <> invalid
    m.video.control = "stop"
    m.video.content = invalid
  end if
  m.playing = false
end sub

sub onVideoState()
  state = m.video.state
  if state = "playing"
    m.top.findNode("status").text = "Playing"
    m.playing = true
  else if state = "buffering"
    m.top.findNode("status").text = "Buffering..."
  else if state = "error"
    m.top.findNode("status").text = "Playback error — press Back"
    m.playing = false
  else if state = "paused"
    m.top.findNode("status").text = "Paused"
    m.playing = false
  end if
end sub

function handleKeyEvent(key as String) as Boolean
  if key = "back"
    stopPlayback()
    m.top.backSelected = true
    return true
  end if

  if key = "OK" or key = "play" or key = "pause"
    if m.playing
      m.video.control = "pause"
      m.playing = false
    else
      m.video.control = "resume"
      m.playing = true
    end if
    return true
  end if

  if not m.isLive and (key = "left" or key = "right")
    seekPos = m.video.position
    if seekPos = invalid then seekPos = 0
    if key = "left"
      seekPos = seekPos - 10
      if seekPos < 0 then seekPos = 0
    else
      seekPos = seekPos + 10
    end if
    m.video.seek = seekPos
    return true
  end if

  return true
end function

function onKeyEvent(key as String, press as Boolean) as Boolean
  if not press then return false
  return handleKeyEvent(DuplexNormalizeKey(key))
end function
