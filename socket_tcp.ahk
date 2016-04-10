#Include socket.ahk

class socket_tcp extends socket_base
{
  static AsyncMsgNumber := 7890
  __New(type)
  {
    this.type := type
    this.recvBuf := new socket_buffer()
    this.sendBuf := new socket_buffer()
    
    this.base.__New()
  }
  
  listen(port, ipversion=4)
  {
    this.close()
    VarSetCapacity(hints, sz:=16+4*A_PtrSize, 0)  ;addrinfo structure
    Numput(1, hints, 0, "int")   ;hints.ai_flags = AI_PASSIVE
    Numput(ipversion = 4 ? AF_INET : AF_INET6, hints, 4, "int")    ;hints.ai_family
    Numput(SOCK_STREAM, hints, 8, "int")  ;hints.ai_socktype = SOCK_STREAM
    Numput(IPPROTO_TCP, hints, 12, "int")  ;hints.ai_protocol = IPPROTO_TCP
    
    if (r := GetAddrInfo(, port, &hints, results))
      return this.setLastError("GetAddrInfo", r)
    
    ;socket(results.ai_family, results.ai_socktype, results.ai_protocol)
    this.socket := socket(NumGet(results+4, 0, "int"), NumGet(results+8, 0, "int"), NumGet(results+12, 0, "int"))
    if (this.socket = INVALID_SOCKET)
    {
      FreeAddrInfo(results)
      return this.setLastError("socket", WSAGetLastError())
    }
    
    ;bind(this.socket, results.ai_addr, results.ai_addrlen)
    if bind(this.socket, Numget(results+16, 2*A_PtrSize, "ptr"), Numget(results+16, 0, "ptr"))
    {
      FreeAddrInfo(results)
      return this.setLastError("bind", WSAGetLastError())
    }
    
    FreeAddrInfo(results)
    
    ;register for FD_READ | FD_WRITE | FD_ACCEPT | FD_CLOSE
    if (r := WSAAsyncSelect(this.socket, A_ScriptHwnd, socket_tcp.AsyncMsgNumber, 43))
      return this.setLastError("WSAAsyncSelect", r)
    OnMessage(socket_tcp.AsyncMsgNumber, "AsyncSelectHandlerTCP")
    
    if (listen(this.socket) = SOCKET_ERROR)
      return this.setLastError("listen", WSAGetLastError())
    
    return this.clearErrors()
  }
  
  connect(address, port, ipversion=4)
  {
    
  }
  
  onConnect(server, success)
  {
    this.warn("Connect callback:`nserver: " server.socket "`nsuccess: " success)
  }
  
  onClose(reason)
  {
    this.warn("Close", "reason: " reason)
  }
  
  close(reason=0)
  {
    if (this.socket = INVALID_SOCKET)
      return
    closesocket(this.socket), this.socket := INVALID_SOCKET
  }
  
  forceClose()
  {
    
  }
}

AsyncSelectHandlerTCP(wParam, lParam)
{
  
}