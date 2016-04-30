#Include ..\Classes\cmd.ahk
#Include socket.ahk

socket_base.showWarnings := true
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
;                     script protocol test
;################################################################################
socket_base.showNotifications := true
s := new socket_tcp("script")
s.onAccept := Func("script_accept")
s.listen(25568)
c := new socket_tcp("script")
c.onRecv := Func("script_recv")
c.connect("localhost", 25568)

script_recv(sockobj, type, p*)
{
  cmd(type " = " p.1)
  if (type == "string" && p.1 != "你好, hello world")
    cmd("Failed test: " A_LineNumber)
  if (type == "integer" && p.1 != 123456789)
    cmd("Failed test: " A_LineNumber)
  if (type == "float" && p.1 != 123456789.0123456)
    cmd("Failed test: " A_LineNumber)
  if (type == "binary")
  {
    Loop, % p.1.len
      if (NumGet(p.1.ptr, A_Index-1, "uchar") != 7)
      {
        cmd("Failed test: " A_LineNumber)
        break
      }
  }
  if (type == "file")
  {
    SaveFile("result.jpg", p.2)
    ;run, result.jpg
  }
  if (type == "object")
  {
    cmd(objToJson(p.1))
  }
}
script_accept(sockobj, client)
{
  sockobj.notify("Accepting " client.socket)
  client.send("string", "你好, hello world")
  client.send("float", 123456789.0123456)
  client.send("integer", 123456789)
  VarSetCapacity(t, 400000, 7)
  client.send("binary", {len:400000, ptr:&t})
  if (FileExist("test.jpg"))
    client.send("file", "test.jpg")
  o := {x:10, y:20, z:[1,2,3], str:"hello"}
  client.send("object", o)
  
}
;################################################################################
;                     IPv4 raw protocol test
;################################################################################
/*
s1 := new socket_tcp("raw")
s1.onRecv := Func("raw_recv")
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
s1.listen(25565)

c1 := new socket_tcp("raw")
c1.onConnect := Func("raw_connect")
client_connect(sockobj, success)
{
  VarSetCapacity(t, 16, 7)
  sockobj.send(&t, 16)
}

c1.connect("127.0.0.1", 25565)
*/
;################################################################################
;                     IPv6 raw protocol test
;################################################################################
/*
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
c2.onConnect := Func("raw_connect")
c2.connect("::1", 25566)
*/

;################################################################################
;                     Remote test
;################################################################################
/*
; Remote server test
  g := new socket_tcp("raw")
  g.onConnect := Func("on_connect")
  g.connect("www.google.com", 80)
  sleep, 250

on_connect(sockobj, success)
{
  if !success
    cmd("Failed test: " A_LineNumber)
  SetTimer, CloseGoogle, -1000
  CloseGoogle:
    g.close()
  return
}
*/

;################################################################################
;                     Common
;################################################################################

cmd("All tests complete.") ; All except the asynch ones..
return


