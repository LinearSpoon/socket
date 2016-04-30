protocol_raw_recv(sockobj)
{
  Critical
  sockobj.onRecv(sockobj.recvBuf.dataStart, sockobj.recvBuf.used())
}

protocol_raw_send(sockobj, ptr, len)
{
  Critical
  sptr := sockobj.sendBuf.lock(len)
  DllCall("RtlMoveMemory", "ptr", sptr, "ptr", ptr, "ptr", len)
  sockobj.sendBuf.unlock(len)
  sockobj.markForSend()
}

socket_tcp.recv_fns["raw"] := Func("protocol_raw_recv")
socket_tcp.send_fns["raw"] := Func("protocol_raw_send")

socket_base.typeSizes := {uint:4, int:4, int64:8, short:2, ushort:2, char:1, uchar:1, double:8, float:4, "utf-8":1, "utf-16":2}

protocol_raw_measure(types, values)
{
  size := 0
  for k,t in types
  {
    if (t = "utf-8" || t = "utf-16")
      size += StrPut(values[k], t) * socket_base.typeSizes[t]
    else if (t = "bin")
      size += values[k].len
    else if (t = "sbin")
      size += 4 + values[k].len
    else ;UInt, Int, Int64, Short, UShort, Char, UChar, Double, Float
      size += socket_base.typeSizes[t]
  }
  return size
}

protocol_raw_pack(ptr, types, values)
{
  for k,t in types
  {
    if (t = "utf-16" || t = "utf-8")
    {
      ptr += StrPut(values[k], ptr, t) * socket_base.typeSizes[t]
    }
    else if (t = "bin")
    {
      DllCall("RtlMoveMemory", "ptr", ptr, "ptr", values[k].ptr, "ptr", values[k].len)
      ptr += values[k].len
    }
    else if (t = "sbin")
    {
      ptr := NumPut(values[k].len, ptr+0, 0, "uint")
      DllCall("RtlMoveMemory", "ptr", ptr, "ptr", values[k].ptr, "ptr", values[k].len)
      ptr += 4 + values[k].len
    }
    else
    { ;UInt, Int, Int64, Short, UShort, Char, UChar, Double, Float
      ptr := Numput(values[k], ptr+0, 0, t)
    }
  }
}

protocol_raw_unpack(ptr, types)
{
  values := Object()
  for k,t in types
  {
    if (t = "utf-16" || t = "utf-8")
    {
      values.Insert(s := StrGet(ptr, t))
      ptr += (StrLen(s)+1) * socket_base.typeSizes[t]
    }
    else if (t = "bin")
    {
      socket_base.warn("Cannot unpack bin type without len (try sbin type)")
      values.insert("")
    }
    else if (t = "sbin")
    {
      binSize := Numget(ptr+0, 0, "uint")
      values.Insert({ptr:ptr+4, len:binSize}), ptr += binSize + 4
    }
    else
    { ;UInt, Int, Int64, Short, UShort, Char, UChar, Double, Float
      values.Insert(Numget(ptr+0, 0, t))
      ptr += socket_base.typeSizes[t]
    }
  }
  return values
}