#Include winsock.ahk
#Include buffer.ahk
#Include socket_tcp.ahk
;#Include protocol_raw.ahk
;#Include protocol_script.ahk
#Include types.ahk

/*
  ip protocol
    tcp
      socket_buffer
      onRecv(sockobj, ...)
      send(...) implicit send to previous connect/accept peer
      
    udp
      linked list buffer?
      onRecv(address, ...)
      send(address, ...)
*/

class socket_base
{
  static showNotifications := false
  static showWarnings := false
  
  __New()
  {
    WSAStartup()
    this.socket := INVALID_SOCKET
    this.bytesSent := 0
    this.bytesRecv := 0
    this.timeCreated := A_TickCount
    this.clearErrors()
  }
  
  __Delete()
  {
    WSACleanup()
  }
  
  onRecv(p*)
  {
    str := ""
    for k,v in p
      str .= "`n     " k " = " v.type
    this.notify("Recv" str)
  }
  
  notify(str)
  {
    if (socket_base.showNotifications && IsFunc(t := "cmd"))
      %t%("Notice  (Socket " (this.socket ? this.socket : "---") "): " str)
  }
  
  warn(str)
  {
    if (socket_base.showWarnings && IsFunc(t := "cmd"))
      %t%("Warning (Socket " (this.socket ? this.socket : "---") "): " str)
  }
  
  setLastError(fn, err)
  {
    this.warn(fn " threw " WSAGetErrorName(err))
    this.lastFunction := fn
    return this.lastError := err
  }

  clearErrors()
  {
    this.lastFunction := "N/A"
    return this.lastError := 0
  }
  
  getLastError()
  {
    return """" this.lastFunction """ threw error " this.lastError ".`n" WSAGetErrorName(this.lastError) ": " WSAGetErrorDesc(this.lastError)
  }
  
  getLocalAddr()
  {
    VarSetCapacity(addr, sz:=128)
    if getsockname(this.socket, &addr, sz)
    {
      this.setLastError("getsockname", WSAGetLastError())
      return ""
    }
    this.clearLastError()
    return WSAAddressToString(&addr, sz) 
  }
  
  getRemoteAddr()
  {
    VarSetCapacity(addr, sz:=128)
    if getpeername(this.socket, &addr, sz)
    {
      this.setLastError("getpeername", WSAGetLastError())
      return ""
    }
    this.clearLastError()
    return WSAAddressToString(&addr, sz) 
  }
}