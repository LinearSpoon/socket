#Include winsock.ahk
#Include buffer.ahk
#Include socket_tcp.ahk
#Include protocol_raw.ahk
#Include protocol_script.ahk

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
    this.warn("Recv")
  }
  
  warn(str)
  {
    if IsFunc(t := "cmd")
      %t%((this.socket ? "Warning (Socket " this.socket "): " : "Warning: " ) str)
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
}