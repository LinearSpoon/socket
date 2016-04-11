#Include ..\Classes\cmd.ahk
#Include socket.ahk

local_only := true  ; Only do tests that connect to the local device

cmdshow(0,0)

;################################################################################
;                     socket_buffer tests
;################################################################################
sb := new socket_buffer(10000)
if (sb.capacity() < 10000)
  cmd("Failed test: " A_LineNumber)

; Request a small amount that would not trigger a resize
tmp := sb.lock(5)
if (tmp = 0)
  cmd("Failed test: " A_LineNumber)
sb.unlock(0)

; Request a large amount that would trigger a resize
sb.lock(1000000)
if (sb.bytesAvailable() < 1000000)
  cmd("Failed test: " A_LineNumber)

; Create a request that triggers a move but no resize
sb.unlock(900000)
if (sb.used() != 900000)
  cmd("Failed test: " A_LineNumber)
sb.discardBytes(800000)
if (sb.used() != 100000)
  cmd("Failed test: " A_LineNumber)
sb.lock(200000)
if (sb.bytesAvailable() < 200000)
  cmd("Failed test: " A_LineNumber)

; Test discard
sb.discardAll()
if (sb.used() > 0)
  cmd("Failed test: " A_LineNumber)

; Test freeing memory in __Delete
sb := ""
if (socket_buffer.heap != 0)
  cmd("Failed test: " A_LineNumber)
if (socket_buffer.blocks != 0)
  cmd("Failed test: " A_LineNumber)

;################################################################################
;                     IPv4 raw protocol test
;################################################################################
s := new socket_tcp("raw")
s.onRecv := Func("raw_recv")
raw_recv(sockobj, ptr, len)
{
  if (len != 16)
    cmd("Failed test: " A_LineNumber)
  Loop, 16
    if (NumGet(ptr+A_Index, -1, "uchar") != 7)
    {
      cmd("Failed test: " A_LineNumber)
      return
    }
  sockobj.close()
}
s.listen(25565)

c := new socket_tcp("raw")
c.onConnect := Func("client_connect")
c.onClose := Func("silence")

c.connect("127.0.0.1", 25565)
;################################################################################
;                     IPv6 raw protocol test
;################################################################################
s2 := new socket_tcp("raw")
s2.onRecv := Func("raw_recv2")
raw_recv2(sockobj, ptr, len)
{
  if (len != 16)
    cmd("Failed test: " A_LineNumber)
  Loop, 16
    if (NumGet(ptr+A_Index, -1, "uchar") != 7)
    {
      cmd("Failed test: " A_LineNumber)
      return
    }
  sockobj.close()
}
s2.listen(25566, 6)

c2 := new socket_tcp("raw")
c2.onConnect := Func("client_connect")
c2.onClose := Func("silence")
c2.connect("::1", 25566)


;################################################################################
;                     Remote test
;################################################################################
; Remote server test
if (!local_only)
{
  g := new socket_tcp("raw")
  g.onConnect := Func("on_connect")
  g.connect("www.google.com", 80)
}
on_connect(sockobj, success)
{
  if !success
    cmd("Failed test: " A_LineNumber)
  SetTimer, CloseGoogle, -1000
  CloseGoogle:
    g.close()
  return
}
;################################################################################
;                     Common
;################################################################################

cmd("All tests complete.") ; All except the asynch ones..
return

silence()
{
}

client_connect(sockobj, success)
{
  VarSetCapacity(t, 16, 7)
  sockobj.send(&t, 16)
}

