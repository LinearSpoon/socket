global AF_UNSPEC := 0
global AF_INET := 2
global AF_INET6 := 23

global SOCK_STREAM := 1
global SOCK_DGRAM := 2
global SOCK_RAW := 3

global IPPROTO_TCP := 6
global IPPROTO_UDP := 17

global SOCKET_ERROR  := -1
global INVALID_SOCKET := -1
global INADDR_ANY := 0


global WSAErrors := {0:"SUCCESS"
      , 6:"WSA_INVALID_HANDLE"
      , 8:"WSA_NOT_ENOUGH_MEMORY"
      , 87:"WSA_INVALID_PARAMETER"
      , 995:"WSA_OPERATION_ABORTED"
      , 996:"WSA_IO_INCOMPLETE"
      , 997:"WSA_IO_PENDING"
      , 10004:"WSAEINTR"
      , 10009:"WSAEBADF"
      , 10013:"WSAEACCES"
      , 10014:"WSAEFAULT"
      , 10022:"WSAEINVAL"
      , 10024:"WSAEMFILE"
      , 10035:"WSAEWOULDBLOCK"
      , 10036:"WSAEINPROGRESS"
      , 10037:"WSAEALREADY"
      , 10038:"WSAENOTSOCK"
      , 10039:"WSAEDESTADDRREQ"
      , 10040:"WSAEMSGSIZE"
      , 10041:"WSAEPROTOTYPE"
      , 10042:"WSAENOPROTOOPT"
      , 10043:"WSAEPROTONOSUPPORT"
      , 10044:"WSAESOCKTNOSUPPORT"
      , 10045:"WSAEOPNOTSUPP"
      , 10046:"WSAEPFNOSUPPORT"
      , 10047:"WSAEAFNOSUPPORT"
      , 10048:"WSAEADDRINUSE"
      , 10049:"WSAEADDRNOTAVAIL"
      , 10050:"WSAENETDOWN"
      , 10051:"WSAENETUNREACH"
      , 10052:"WSAENETRESET"
      , 10053:"WSAECONNABORTED"
      , 10054:"WSAECONNRESET"
      , 10055:"WSAENOBUFS"
      , 10056:"WSAEISCONN"
      , 10057:"WSAENOTCONN"
      , 10058:"WSAESHUTDOWN"
      , 10059:"WSAETOOMANYREFS"
      , 10060:"WSAETIMEDOUT"
      , 10061:"WSAECONNREFUSED"
      , 10062:"WSAELOOP"
      , 10063:"WSAENAMETOOLONG"
      , 10064:"WSAEHOSTDOWN"
      , 10065:"WSAEHOSTUNREACH"
      , 10066:"WSAENOTEMPTY"
      , 10067:"WSAEPROCLIM"
      , 10068:"WSAEUSERS"
      , 10069:"WSAEDQUOT"
      , 10070:"WSAESTALE"
      , 10071:"WSAEREMOTE"
      , 10091:"WSASYSNOTREADY"
      , 10092:"WSAVERNOTSUPPORTED"
      , 10093:"WSANOTINITIALISED"
      , 10101:"WSAEDISCON"
      , 10102:"WSAENOMORE"
      , 10103:"WSAECANCELLED"
      , 10104:"WSAEINVALIDPROCTABLE"
      , 10105:"WSAEINVALIDPROVIDER"
      , 10106:"WSAEPROVIDERFAILEDINIT"
      , 10107:"WSASYSCALLFAILURE"
      , 10108:"WSASERVICE_NOT_FOUND"
      , 10109:"WSATYPE_NOT_FOUND"
      , 10110:"WSA_E_NO_MORE"
      , 10111:"WSA_E_CANCELLED"
      , 10112:"WSAEREFUSED"
      , 11001:"WSAHOST_NOT_FOUND"
      , 11002:"WSATRY_AGAIN"
      , 11003:"WSANO_RECOVERY"
      , 11004:"WSANO_DATA" }

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms737526(v=vs.85).aspx
accept(s, addr, byref addrlen)
{
  return DllCall("Ws2_32\accept", "ptr", s, "ptr", addr, "int*", addrlen, "ptr")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms737550(v=vs.85).aspx
bind(s, name, namelen)
{
  return DllCall("Ws2_32\bind", "ptr", s, "ptr", name, "int", namelen)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms737582(v=vs.85).aspx
closesocket(s)
{
  return DllCall("Ws2_32\closesocket", "ptr", s)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms737625(v=vs.85).aspx
connect(s, name, namelen)
{
  return DllCall("Ws2_32\connect", "ptr", s, "ptr", name, "int", namelen)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms737823(v=vs.85).aspx
EnumProtocols(lpiProtocols, lpProtocolBuffer, byref lpdwBufferLength)
{
  return DllCall("Ws2_32\EnumProtocols", "ptr", lpiProtocols, "ptr", lpProtocolBuffer, "uint*", lpdwBufferLength)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms737912(v=vs.85).aspx
FreeAddrInfo(pAddrInfo)
{
  static fn := A_IsUnicode ? "Ws2_32\FreeAddrInfoW" : "Ws2_32\freeaddrinfo"
  DllCall(fn, "ptr", pAddrInfo)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738519(v=vs.85).aspx
GetAddrInfo(pNodeName=0, pServiceName=0, pHints=0, byref ppResult="")
{
  static fn := A_IsUnicode ? "Ws2_32\GetAddrInfoW" : "Ws2_32\getaddrinfo"
  return DllCall(fn, pNodeName=0 ? "ptr" : "str", pNodeName, pServiceName=0 ? "ptr" : "str", pServiceName, "ptr", pHints, "ptr*", ppResult)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/dn793576(v=vs.85).aspx
GetHostName()
{
  static fn := A_IsUnicode ? "Ws2_32\GetHostNameW" : "Ws2_32\gethostname"
  VarSetCapacity(name, 512), DllCall(fn, "str", name, "int", 255)
  return name
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738533(v=vs.85).aspx
getpeername(s, name, byref namelen)
{
  return DllCall("Ws2_32\getpeername", "ptr", s, "ptr", name, "int*", namelen)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738543(v=vs.85).aspx
getsockname(s, name, byref namelen)
{
  return DllCall("Ws2_32\getsockname", "ptr", s, "ptr", name, "int*", namelen)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738544(v=vs.85).aspx
getsockopt(s, level, optname, optval, byref optlen)
{
  return DllCall("Ws2_32\getsockopt", "ptr", s, "int", level, "int", optname, "ptr", optval, "int*" optlen)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/jj710197(v=vs.85).aspx
htond(value)
{
  return DllCall("Ws2_32\htond", "double", value, "uint64")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/jj710198(v=vs.85).aspx
htonf(value)
{
  return DllCall("Ws2_32\htonf", "float", value, "uint")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738556(v=vs.85).aspx
htonl(value)
{
  return DllCall("Ws2_32\htonl", "uint", value, "uint")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738557(v=vs.85).aspx
htons(value)
{
  return DllCall("Ws2_32\htons", "ushort", value, "ushort")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738563(v=vs.85).aspx
inet_addr(cp)
{
  return DllCall("Ws2_32\inet_addr", "astr", cp)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738564(v=vs.85).aspx
inet_ntoa(in)
{
  return DllCall("Ws2_32\inet_ntoa", "uint", in, "astr")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/cc805843(v=vs.85).aspx
InetNtop(family, pAddr)
{
  static fn := A_IsUnicode ? "Ws2_32\InetNtop" : "Ws2_32\inet_ntop"
  VarSetCapacity(addr, 94)
  return StrGet(DllCall(fn, "int", family, "ptr", pAddr, "str", addr, "uptr", 46))
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/cc805844(v=vs.85).aspx
InetPton(family, pszAddrString, pAddrBuf)
{
  return DllCall("Ws2_32\InetPtonW", "int", family, "wstr", pszAddrString, "ptr", pAddrBuf)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms738573(v=vs.85).aspx
ioctlsocket(s, cmd, byref argp)
{
  return DllCall("Ws2_32\ioctlsocket", "ptr", s, "int", cmd, "uint*", argp)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms739168(v=vs.85).aspx
listen(s, backlog=0x7FFFFFFF)
{
  return DllCall("Ws2_32\listen", "ptr", s, "int", backlog)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/jj710200(v=vs.85).aspx
ntohd(value)
{
  return DllCall("Ws2_32\ntohd", "uint64", value, "double")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/jj710201(v=vs.85).aspx
ntohf(value)
{
  return DllCall("Ws2_32\ntohf", "uint", value, "float")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740069(v=vs.85).aspx
ntohl(value)
{
  return DllCall("Ws2_32\ntohl", "uint", value, "uint")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740075(v=vs.85).aspx
ntohs(value)
{
  return DllCall("Ws2_32\ntohs", "ushort", value, "ushort")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740121(v=vs.85).aspx
recv(s, buf, len, flags)
{
  return DllCall("Ws2_32\recv", "ptr", s, "ptr", buf, "int", len, "int", flags)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740120(v=vs.85).aspx
recvfrom(s, buf, len, flags, from, byref fromlen)
{
  return DllCall("Ws2_32\recvfrom", "ptr", s, "ptr", buf, "int", len, "int", flags, "ptr", from, "int*", fromlen)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740141(v=vs.85).aspx
select(nfds, readfds, writefds, exceptfds, timeout)
{
  return DllCall("Ws2_32\select", "int", nfds, "ptr", readfds, "ptr", writefds, "ptr", exceptfds, "ptr", timeout)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740149(v=vs.85).aspx
send(s, buf, len, flags)
{
  return DllCall("Ws2_32\send", "ptr", s, "ptr", buf, "int", len, "int", flags)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740148(v=vs.85).aspx
sendto(s, buf, len, flags, to, tolen)
{
  return DllCall("Ws2_32\sendto", "ptr", s, "ptr", buf, "int", len, "int", flags, "ptr", to, "int", tolen)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740476(v=vs.85).aspx
setsockopt(s, level, optname, optval, optlen)
{
  return DllCall("Ws2_32\setsockopt", "ptr", s, "int", level, "int", optname, "ptr", optval, "int", optlen)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740481(v=vs.85).aspx
shutdown(s, how)
{
  return DllCall("Ws2_32\shutdown", "ptr", s, "int", how)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms740506(v=vs.85).aspx
socket(af, type, protocol)
{
  return DllCall("Ws2_32\socket", "int", af, "int", type, "int", protocol, "ptr")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms741513(v=vs.85).aspx
WSAAccept(s, addr, byref addrlen, lpfnCondition, dwCallbackdata)
{
  return DllCall("Ws2_32\WSAAccept", "ptr", s, "ptr", addr, "int*", addrlen, "ptr", lpfnCondition, "ptr", dwCallbackdata, "ptr")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms741516(v=vs.85).aspx
WSAAddressToString(lpsaAddress, dwAddressLength, lpProtocolInfo = 0)
{
  VarSetCapacity(buf, 512)
  DllCall("Ws2_32\WSAAddressToString", "ptr", lpsaAddress, "uint", dwAddressLength, "ptr", lpProtocolInfo, "str", buf, "uint*", 512)
  return buf
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms741540(v=vs.85).aspx
WSAAsyncSelect(s, hWnd, wMsg, lEvent)
{
  return DllCall("Ws2_32\WSAAsyncSelect", "ptr", s, "ptr", hWnd, "uint", wMsg, "int", lEvent)
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms741549(v=vs.85).aspx
WSACleanup()
{
  return DllCall("Ws2_32\WSACleanup")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms679351%28v=vs.85%29.aspx
WSAGetErrorDesc(e)
{
  VarSetCapacity(desc,1024)
  if (0 < DllCall("FormatMessage", "uint", 0x1200, "uint", 0, "int", e, "uint", 1024, "str", desc, "uint", 1024, "uint", 0))
    return desc
  else
    return "Could not retrieve error description."
}

WSAGetErrorName(e)
{
  return ObjHasKey(WSAErrors, e) ? WSAErrors[e] : "UNKNOWN_ERROR"
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms741580(v=vs.85).aspx
WSAGetLastError()
{
  return DllCall("Ws2_32\WSAGetLastError")
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms742213(v=vs.85).aspx
WSAStartup(wVersionRequested = 0x0202)
{
  VarSetCapacity(wsaData, 408)
  if (i := DllCall("Ws2_32\WSAStartup", "UShort", wVersionRequested, "Ptr", &wsaData))
    return i
  if (NumGet(wsaData, 2, "UShort") < wVersionRequested)
  {
    DllCall("Ws2_32\WSACleanup")
    return -1  ; Version too low
  }
  return 0
}

;https://msdn.microsoft.com/en-us/library/windows/desktop/ms742214(v=vs.85).aspx
WSAStringToAddress(AddressString, AddressFamily, lpProtocolInfo, lpAddress, byref lpAddressLength)
{
  return DllCall("Ws2_32\WSAStringToAddress", "str", AddressString, "int", AddressFamily, "ptr", lpProtocolInfo, "ptr", lpAddress, "int*", lpAddressLength)
}















