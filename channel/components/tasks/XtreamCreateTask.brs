' XtreamCreateTask component script. Markup lives in XtreamCreateTask.xml.
sub Init()
  m.top.functionName = "createPlaylist"
end sub

sub createPlaylist()
  print "Duplex: creating playlist"
  result = DuplexCreatePlaylist(m.top.input)
  if result.error <> invalid
    m.top.error = result.error
    return
  end if
  m.top.response = result.data
end sub
