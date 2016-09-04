class socket_tcp extends socket_base
{
  static AsyncMsgNumber := 7890
  static active_sockets := Object()
  static write_fns := Object()
  static read_fns := Object()
  static types := Object()
  
  __New(type)
  {
    this.type := type
    
    this.recvBuf := new socket_buffer()
    this.sendBuf := new socket_buffer()
    
    this.sendOK := false
    base.__New()
  }
  
  __Delete()
  {
    cmd("delete " this.socket)
    this.close()
    this.base.__Delete()
  }
  
  send(type_objects*)
  {
    ; Calculate total size required
    for k,v in type_objects
    {
      socket_tcp.write_fns[this.type].(this, v)
      if (this.sendBuf.isLocked)
        this.sendBuf.unlock()
    }
    this.markForSend()
  }
  
  ;ipversion = 0 = IPv6 server, with IPv4 clients mapped to IPv6 addresses
  ;ipversion = 4 = IPv4 only
  ;ipversion = 6 = IPv6 only
  listen(port, ipversion=0)
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
    
    if (ipversion = 0)
    {
      VarSetCapacity(v, 4, 0)
      ;setsockopt(s, IPPROTO_IPV6, IPV6_V6ONLY, 0, len)
      if (SOCKET_ERROR = setsockopt(this.socket, 41, 27, &v, 4))
        return this.cleanupAndError("setsockopt", WSAGetLastError(), results)
    }
    
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
    
    this.clients := Object()
    return this.clearErrors()
  }
  
  connect(address, port)
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
    this.notify("Connection " (success ? "to " this.getRemoteAddr() " established" : "failed"))
  }
  
  onAccept(client)
  {
    this.notify(this.getLocalAddr() " accepted client " client.socket)
  }
  
  onClose(reason)
  {
    this.notify("Close callback: reason == " reason)
  }
  
  close(reason=0)
  {
    if (this.socket = INVALID_SOCKET || this.socket = "")
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
    if (!this.sendOK)
      return ; Winsock will call FD_WRITE when it is ready
    AsyncSelectHandlerTCP(this.socket, 2) ;Call FD_WRITE
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

  registerType(typeclass)
  {
    socket_tcp.types[typeclass.get_id()] := typeclass
  }
}

AsyncSelectHandlerTCP(wParam, lParam)
{
  Critical
  static EventConstants := {1:"FD_READ", 2:"FD_WRITE", 8:"FD_ACCEPT", 16:"FD_CONNECT", 32:"FD_CLOSE"}
  Event := lParam & 0xFFFF, ErrorCode := lParam >> 16, sockobj := socket_tcp.active_sockets[wParam]
  
  if not isObject(sockobj)
  {
    socket_base.warn("Event: " EventConstants[Event] "`t  Unknown socket: " wParam)
    return 0
  }
  else
  {
    sockobj.notify("Event: " EventConstants[Event] "`t  ErrorCode: " ErrorCode)
  }
  
  if (Event = 1) ;FD_READ
  {
    ioctlsocket(sockobj.socket, 1074030207, bytesAvailable)
    r := recv(sockobj.socket, sockobj.recvBuf.lock(bytesAvailable), bytesAvailable, 0)
    sockobj.recvBuf.unlock(r)
    If (r > 0)
    { ;We received data!
      sockobj.bytesRecv += r
      socket_tcp.read_fns[sockobj.type].(sockobj)
    }
    return r
  }
  else if (Event = 2) ;FD_WRITE
  {
    cmd("Pending bytes: " sockobj.sendBuf.used())
    r := send(sockobj.socket, sockobj.sendBuf.dataStart, sockobj.sendBuf.used(), 0)
    if (r < 0)
    {
      e := WSAGetLastError()
      if (e = 10035)
      {
        cmd("wouldblock")
        sockobj.sendOK := false
        return
      }
      return sockobj.setLastError("recv", e)
    }
    cmd("Sent bytes: " r)
    sockobj.bytesSent += r
    sockobj.sendBuf.discardBytes(r)
    sockobj.sendOK := true
  }
  else if (Event = 8) ;FD_ACCEPT
  {
    clientsock := new socket_tcp(sockobj.type)
    VarSetCapacity(saddr, 28)
    clientsock.socket := accept(sockobj.socket, &saddr, 28)
    if (clientsock.socket = INVALID_SOCKET)
      return sockobj.setLastError("accept", WSAGetLastError())
    sockobj.clients.Insert(clientsock)
    clientsock.onRecv := sockobj.onRecv
    clientsock.onClose := sockobj.onClose
    socket_tcp.active_sockets[clientsock.socket] := clientsock
    sockobj.onAccept(clientsock)
  }
  else if (Event = 16) ;FD_CONNECT
  {
    if (ErrorCode)
    { ;Connection failed - try next address
      if (sockobj.tryNextTarget())
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
    sockobj.onClose(ErrorCode)
  }
  return true
}


; Script protocol
protocol_script_write(sockobj, typeobj)
{
   cmdi("write " sockobj.type " << " typeobj.type ", size: " typeobj.get_length() " type: " typeobj.get_id())
  ; [2 byte size][2 byte type][data...]
  ; if (size == 0)
  ;   [2 byte null][2 byte type][4 byte size][data...]
  len := typeobj.get_length()
  if (len <= 0xFFF0)
  { ; Small header
    sptr := sockobj.sendBuf.lock(len+4)
    Numput(typeobj.get_id() | ((len+4) << 16), sptr+0, 0, "uint")
    typeobj.write_self(sptr+4)
    sockobj.sendBuf.unlock()
    return 1
  }
  else
  { ; Large header
    sptr := sockobj.sendBuf.lock(len+8)
    Numput(typeobj.get_id(), sptr+0, 0, "uint")
    Numput(len+8, sptr+4, 0, "uint")
    typeobj.write_self(sptr+8)
    sockobj.sendBuf.unlock()
    return 1
  }
}
socket_tcp.write_fns["script"] := Func("protocol_script_write")

protocol_script_read(sockobj)
{
   ; cmdi("read")
  Critical
  lenBuffer := sockobj.recvBuf.used(), offset := 0
  while(lenBuffer-offset >= 4) ;While we have 4+ bytes remaining...
  {
    dataAddress := sockobj.recvBuf.dataStart+offset
    header1 := NumGet(dataAddress+0, 0, "uint")
    if (lenData := header1 >> 16) ;Short header
      typeID := header1 & 0xFFFF, lenHeader := 4
    else if (lenBuffer-offset >= 8) ;Long header
      typeID := header1, lenData := NumGet(dataAddress+4, 0, "uint"), lenHeader := 8
    else  
      break ; long header, and less than 8 bytes available

    if (lenData > lenBuffer-offset)
      break  ; Not all of the data has arrived
    ;cmd(lenData " " offset " " lenHeader " " typeID)
    ;typeID 
    typeclass := socket_tcp.types[typeID]
    if (!IsObject(typeclass))
      sockobj.warn("Received unknown type ID: " typeID)
    sockobj.onRecv(typeclass.read_self(dataAddress+lenHeader, lenData-lenHeader))
    offset += lenData
  }
  sockobj.recvBuf.discardBytes(offset)
}
socket_tcp.read_fns["script"] := Func("protocol_script_read")


; Raw protocol
protocol_raw_write(sockobj, typeobj)
{
  len := typeobj.get_length()
  sptr := sockobj.sendBuf.lock(len)
  typeobj.write_self(sptr)
  sockobj.sendBuf.unlock()
}
socket_tcp.write_fns["raw"] := Func("protocol_raw_write")

protocol_raw_read(sockobj)
{
  Critical
  sockobj.onRecv(sockobj.recvBuf.dataStart, sockobj.recvBuf.used())
  ; onRecv must use unlock to free data from recvBuf
}
socket_tcp.read_fns["raw"] := Func("protocol_raw_read")
