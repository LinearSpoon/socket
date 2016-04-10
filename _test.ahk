#Include ..\Classes\cmd.ahk
#Include buffer.ahk
#Include socket.ahk

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
;                     socket tests
;################################################################################

s := new socket_tcp()
s.listen(1234)
if (s.socket == -1)
  cmd("Failed test: " A_LineNumber)

s.close()
s := ""



cmd("All tests complete.")
