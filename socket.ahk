#Include winsock.ahk
#Include buffer.ahk
class socket_base
{
  __New()
  {
    WSAStartup()
    
    this.socket := INVALID_SOCKET
    
    this.recvBuf := new socket_buffer()
    this.sendBuf := new socket_buffer()
    
    this.bytesSent := 0
    this.bytesRecv := 0
    this.timeCreated := A_TickCount
  }
  
  __Delete()
  {
    WSACleanup()
  }
  
  onConnect(p*)
  {
    this._defaultCallback("Connect", "")
  }
  
  onClose(p*)
  {
    this._defaultCallback("Close", "")
  }
  
  onRecv(p*)
  {
    this._defaultCallback("Recv", "")
  }
  
  close(reason=0)
  {
    
    
  }
  
  forceClose()
  {
    
  }
  
  send()
  {
    
  }
  
  
  _defaultCallback(type, str)
  {
    str := "Default " type " callback to socket " this.socket "`n" str
    if IsFunc(t := "cmd")
      %t%(str)
    else
      Msgbox % str
    return 1
  }
}