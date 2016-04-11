protocol_raw_recv(sockobj)
{
  sockobj.onRecv(sockobj.recvBuf.dataStart, sockobj.recvBuf.used())
}

protocol_raw_send(sockobj, ptr, len)
{
  sptr := sockobj.sendBuf.lock(len)
  DllCall("RtlMoveMemory", "ptr", sptr, "ptr", ptr, "ptr", len)
  sockobj.sendBuf.unlock(len)
  sockobj.markForSend()
}

socket_tcp.recv_fns["raw"] := Func("protocol_raw_recv")
socket_tcp.send_fns["raw"] := Func("protocol_raw_send")