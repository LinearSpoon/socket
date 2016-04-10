#Include winsock.ahk
#Include buffer.ahk

/*
  protocol overrides send/recv
    raw
      send(ptr, len)
      recv(ptr, len)
    ahk
      send(type, value)
      recv(type, value)
    text ?
      send(string)
      recv(string)
  
  ip protocol
    tcp
      socket_buffer
      onRecv(sockobj, ...)
      send(...) implicit send to previous connect/accept peer
      
    udp
      linked list buffer?
      onRecv(address, ...)
      send(address, ...)
  
  socket_client
    automatic ip version
  socket_server
    must specify ipv4 or ipv6
    
    
  asyncselecthandler(...)
  {
    if recv
    {
      udp/tcp fill recvbuf
      protocol custom parse buffer
        protocol custom function calls socket.onRecv
    }
    if send
    {
      udp/tcp send sendbuf
    }
    if connect/accept
    {
      call socket.onConnect
    }
    if close
    {
      call socket.onClose
    }
  }
*/

class socket_base
{
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
  
  onRecv(sender, p*)
  {
    this.warn("Recv", "")
  }
  
  warn(str)
  {
    if IsFunc(t := "cmd")
      %t%("Socket " this.socket ": " str)
  }
  
  setLastError(fn, err)
  {
    this.warn(fn " threw " err)
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
}