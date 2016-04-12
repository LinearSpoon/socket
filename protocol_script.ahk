; [2 byte size][2 byte type][data...]
; if (size == 0)
;   [2 byte null][2 byte type][4 byte size][data...]

protocol_script_recv(sockobj)
{
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
    typename := socket_tcp.typeNames[typeID]
    socket_tcp.scriptRecvs[typename].(sockobj, typename, dataAddress+lenHeader, lenData-lenHeader)
    offset += lenData
  }
  sockobj.recvBuf.discardBytes(offset)
}

protocol_script_send(sockobj, typename, data*)
{
  Critical
  socket_tcp.scriptSends[typename].(sockobj, typename, data*)
  if (sockobj.sendBuf.isLocked)
     sockobj.sendBuf.unlock()
  sockobj.markForSend()
}

protocol_script_prepareHeader(sockobj, len, typename)
{
  if (len <= 0xFFF0)
  { ; Small header
    sptr := sockobj.sendBuf.lock(len+4)
    Numput(socket_tcp.typeIDs[typename] | ((len+4) << 16), sptr+0, 0, "uint")
    return sptr+4
  }
  else
  { ; Large header
    sptr := sockobj.sendBuf.lock(len+8)
    Numput(socket_tcp.typeIDs[typename], sptr+0, 0, "uint")
    Numput(len+8, sptr+4, 0, "uint")
    return sptr+8
  }
  return 0
}



socket_tcp.recv_fns["script"] := Func("protocol_script_recv")
socket_tcp.send_fns["script"] := Func("protocol_script_send")


socket_tcp.typeDefs := Object()
socket_tcp.scriptSends := Object()
socket_tcp.scriptRecvs := Object()
socket_tcp.typeIDs := Object()
socket_tcp.typeNames := Object()

protocol_script_addType(1, "string",,, "utf-16")
protocol_script_addType(2, "binary",,, "sbin")
protocol_script_addType(3, "integer",,, "int64")
protocol_script_addType(4, "float",,, "double")
protocol_script_addType(5, "file", "protocol_script_sendFile",, "utf-16", "bin")


protocol_script_addType(typeID, typename, sendFn="", recvFn="", typedef*)
{
  socket_tcp.typeIDs[typename] := typeID
  socket_tcp.typeNames[typeID] := typename
  socket_tcp.scriptSends[typename] := isFunc(sendFn) ? Func(sendFn) : Func("protocol_script_genericSend")
  socket_tcp.scriptRecvs[typename] := isFunc(recvFn) ? Func(recvFn) : Func("protocol_script_genericRecv")
  socket_tcp.typeDefs[typename] := typedef
}

protocol_script_genericSend(sockobj, typename, data*)
{
  typedef := socket_tcp.typeDefs[typename]
  len := protocol_raw_measure(typedef, data)
  ptr := protocol_script_prepareHeader(sockobj, len, typename)
  protocol_raw_pack(ptr, typedef, data)
}

protocol_script_sendFile(sockobj, typename, filepath)
{
  file := FileOpen(filepath, "r")
  SplitPath, filepath, filepath
  ptr := protocol_script_prepareHeader(sockobj, len := file.length+2*StrLen(filepath)+6, typename)
  ptr += StrPut(filepath, ptr+0, "utf-16")*2
  Numput(file.length, ptr+0, 0, "uint")
  file.seek(0, 0)  ;Force file stream to start of file in case AHK consumed the BOM
  file.RawRead(ptr+4, file.length)
  file.close()
}

protocol_script_genericRecv(sockobj, typename, ptr, len)
{
  typedef := socket_tcp.typeDefs[typename]
  sockobj.onRecv(typename, protocol_raw_unpack(ptr, typedef)*)
}