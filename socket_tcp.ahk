class socket_tcp extends socket_base
{
  static AsyncMsgNumber := 7890
  static active_sockets := Object()
  static recv_fns := Object()
  static send_fns := Object()
  
  __New(type)
  {
    this.type := type
    if (socket_tcp.recv_fns[type].Name = "")
      this.warn("No recv function defined for " type)
    if (socket_tcp.send_fns[type].Name = "")
      this.warn("No send function defined for " type)
    
    this.recvBuf := new socket_buffer()
    this.sendBuf := new socket_buffer()
    
    base.__New()
  }
  
  __Delete()
  {
    this.close()
    this.base.__Delete()
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
      return this.cleanupAndError("socket", WSAGetLastError(), results)
    
    socket_tcp.active_sockets[this.socket] := this
    
    ;bind(this.socket, results.ai_addr, results.ai_addrlen)
    if bind(this.socket, Numget(results+16, 2*A_PtrSize, "ptr"), Numget(results+16, 0, "ptr"))
      return this.cleanupAndError("bind", WSAGetLastError(), results)
    
    FreeAddrInfo(results)
    
    ;register for FD_READ | FD_WRITE | FD_ACCEPT | FD_CLOSE
    if (r := WSAAsyncSelect(this.socket, A_ScriptHwnd, socket_tcp.AsyncMsgNumber, 43))
      return this.cleanupAndError("WSAAsyncSelect", r)
    OnMessage(socket_tcp.AsyncMsgNumber, "AsyncSelectHandlerTCP")
    
    if (listen(this.socket) = SOCKET_ERROR)
      return this.cleanupAndError("listen", WSAGetLastError())
    
    return this.clearErrors()
  }
  
  connect(address, port, ipversion=4)
  {
    this.close()
    ;Specifying NULL for pHints parameter assumes AF_UNSPEC and 0 for all other members
    if (r :=  GetAddrInfo(address, port, 0, results))
      return this.setLastError("GetAddrInfo", r)
    
    this.targets := results
    return this.tryNextTarget()
  }
  
  onConnect(success)
  {
    this.warn("Connection " (success ? "established" : "failed"))
  }
  
  onAccept(client)
  {
    this.warn("Accepted client " client.socket)
  }
  
  onClose(reason)
  {
    this.warn("Close callback: reason == " reason)
  }
  
  close(reason=0)
  {
    if (this.socket = INVALID_SOCKET)
      return
    ObjRemove(socket_tcp.active_sockets, this.socket, "")
    closesocket(this.socket), this.socket := INVALID_SOCKET
  }
  
  forceClose()
  {
    
  }
  
  cleanupAndError(fn="", err="", addrInfo=0)
  {
    if (addrInfo)
      FreeAddrInfo(addrInfo)
    if (this.targets)
      FreeAddrInfo(this.targets), this.targets := this.current := ""
    this.close()
    return this.setLastError(fn ? fn : this.lastFunction, err ? err : this.lastError)
  }
  
  markForSend()
  {
    if (this.pendingSend)
      return
    this.pendingSend := true
    DetectHiddenWindows, On
    PostMessage, socket_tcp.AsyncMsgNumber, this.socket, 2,, ahk_id %A_ScriptHwnd%  ;Call FD_WRITE indirectly
  }
  
  tryNextTarget()
  {
    this.current := this.current = "" ? this.targets : NumGet(this.current, 16+3*A_PtrSize, "ptr")
    if (!this.current) ;No more targets or called inappropriately
      return this.cleanupAndError("tryNextTarget", 10065)
 
    ;socket(current.ai_family,...)
    this.socket := socket(NumGet(this.current, 4, "int"), SOCK_STREAM, IPPROTO_TCP)
    if (this.socket = INVALID_SOCKET)
      return this.cleanupAndError("socket", WSAGetLastError())
    
    socket_tcp.active_sockets[this.socket] := this
    
    ;register for FD_READ | FD_WRITE | FD_CONNECT | FD_CLOSE
    if (r := WSAAsyncSelect(this.socket, A_ScriptHwnd, socket_tcp.AsyncMsgNumber, 51))
      return this.cleanupAndError("WSAAsyncSelect", r)
    OnMessage(socket_tcp.AsyncMsgNumber, "AsyncSelectHandlerTCP")

    ; connect(this.socket, current.ai_addr, current.ai_addrlen)
    if connect(this.socket, Numget(this.current, 16+2*A_Ptrsize, "ptr"), Numget(this.current, 16, "ptr"))
    {
      e := WSAGetLastError()
      if (e != 10035) ;10035 = WSAEWOULDBLOCK is OK, we will be notified of connection result in AsyncSelectHandler
      {
        this.close(), this.setLastError("connect", e)
        return this.tryNextTarget()  ;Try the next target in case this one is simply an unsupported protocol
      }
    }

    return this.clearErrors()
  }
}

AsyncSelectHandlerTCP(wParam, lParam)
{
  Critical
  static EventConstants := {1:"FD_READ", 2:"FD_WRITE", 8:"FD_ACCEPT", 16:"FD_CONNECT", 32:"FD_CLOSE"}
  Event := lParam & 0xFFFF, ErrorCode := lParam >> 16, sockobj := socket_tcp.active_sockets[wParam]
  if not isObject(sockobj)
  {
    socket_base.warn("Unknown TCP socket: " wParam)
    return 0
  }
  ;cmd("Socket: " sockobj.socket "`tType: " sockobj.type "`tEvent: " EventConstants[Event] "  `tErrorCode: " ErrorCode)
  
  if (Event = 1) ;FD_READ
  {
    ioctlsocket(sockobj.socket, 1074030207, bytesAvailable)
    r := recv(sockobj.socket, sockobj.recvBuf.lock(bytesAvailable), bytesAvailable, 0)
    sockobj.recvBuf.unlock(r)
    If (r > 0)
    { ;We received data!
      sockobj.bytesRecv += r
      socket_tcp.recv_fns[sockobj.type].(sockobj)
    }
    return r
  }
  else if (Event = 2) ;FD_WRITE
  {
    
  }
  else if (Event = 8) ;FD_ACCEPT
  {
    clientsock := new socket_tcp(sockobj.type)
    VarSetCapacity(saddr, 28)
    clientsock.socket := accept(sockobj.socket, &saddr, 28)
    if (clientsock.socket == INVALID_SOCKET)
      return sockobj.setLastError("accept", WSAGetLastError())

    socket_tcp.active_sockets[clientsock.socket] := clientsock
    sockobj.onAccept(clientsock)
  }
  else if (Event = 16) ;FD_CONNECT
  {
    if (ErrorCode)
    { ;Connection failed - try next address
      if (sockobj.tryNextTarget())
        sockobj.onConnect(false)
      sockobj.onConnect(false)
    }
    else
    {
      FreeAddrInfo(sockobj.targets), sockobj.targets := sockobj.current := ""
      sockobj.onConnect(true)
    }
  }
  else if (Event = 32) ;FD_CLOSE
  {
    sockobj.onClose(0)
  }
  return true
}