Function DeviceIPAddress() as String
    device = CreateObject("roDeviceInfo")
    IPs = device.getIpAddrs()
	IPs.reset()
	ip = IPs[IPs.next()]

    return ip
end Function