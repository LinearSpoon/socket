; [2 byte size][2 byte type][data...]
; if (size == 0)
;   [2 byte null][2 byte type][4 byte size][data...]

protocol_script_recv(sockobj)
{
  sockobj.onRecv("")
}

protocol_script_send(sockobj, type, p*)
{
  ;...
  sockobj.markForSend()
}

socket_tcp.recv_fns["script"] := Func("protocol_script_recv")
socket_tcp.send_fns["script"] := Func("protocol_script_send")