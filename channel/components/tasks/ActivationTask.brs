' ActivationTask component script. Markup lives in ActivationTask.xml.
sub Init()
  m.top.functionName = "registerDevice"
end sub

sub registerDevice()
  hardwareId = m.top.hardwareId
  print "Duplex: registering device " + hardwareId

  result = DuplexRegisterDevice(hardwareId)
  if result.error <> invalid
    m.top.error = result.error
    return
  end if

  m.top.response = result.data
end sub
