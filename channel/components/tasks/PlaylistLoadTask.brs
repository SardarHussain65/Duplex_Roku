' PlaylistLoadTask component script. Markup lives in PlaylistLoadTask.xml.
sub Init()
  m.top.functionName = "loadPlaylists"
end sub

sub loadPlaylists()
  print "Duplex: loading playlists for device " + m.top.deviceId
  result = DuplexFetchPlaylists(m.top.deviceId)
  if result.error <> invalid
    m.top.error = result.error
    return
  end if
  m.top.playlists = { items: result.data }
end sub
