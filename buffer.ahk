;This is the buffer used to hold data that is waiting to be sent out, or waiting to be processed after receiving
;The pending data always exists in a contiguous section of the buffer starting at the dataStart pointer up to the dataEnd pointer.
;New data can be added to the end of the data section via lock()/unlock(), and old data can be removed from the beginning of the data section via discardBytes()
class socket_buffer
{
  static heap := 0
  static blocks := 0
  
  __New(initialSize = 32768)
  {
    if (socket_buffer.heap = 0) ;No heap has been created
      socket_buffer.heap := DllCall("HeapCreate", "uint", 1, "ptr", 0, "ptr", 0)
    this.dataStart := this.dataEnd := this.bufStart := DllCall("HeapAlloc", "ptr", socket_buffer.heap, "uint", 0, "ptr", initialSize)
    this.bufEnd := this.bufStart + DllCall("HeapSize", "ptr", socket_buffer.heap, "uint", 0, "ptr", this.bufStart)
    socket_buffer.blocks++
  }
  
  __Delete()
  {
    DllCall("HeapFree", "ptr", socket_buffer.heap, "uint", 0, "ptr", this.bufStart)
    if (--socket_buffer.blocks = 0) ;This is the last buffer
    {
      DllCall("HeapDestroy", "ptr", socket_buffer.heap)
      socket_buffer.heap := 0
    }
  }
  
  ;Returns the capacity of the buffer in bytes, including used and unused space
  capacity()
  {
    return this.bufEnd - this.bufStart
  }
  
  ;Returns the amount of data in the heap in bytes
  used()
  {
    return this.dataEnd - this.dataStart
  }
  
  ;Returns space available at the end of the buffer, after the data portion
  bytesAvailable()
  {
    return this.bufEnd - this.dataEnd
  }
  
  ;Returns space available at the start and end
  maxBytesAvailable()
  {
    return this.bufEnd - this.dataEnd + this.dataStart - this.bufStart
  }
  
  ;Returns a pointer within the buffer for new data to be written. Guarantees at least bytesRequested bytes will be available.
  lock(bytesRequested)
  {
    if (this.isLocked)
      return 0
     this.isLocked := bytesRequested
 
    ;Check if we have enough space at the end of the buffer
    if (this.bytesAvailable() >= bytesRequested)
    {
      return this.dataEnd  ;We've already got enough space
    }
    ;Else, we need more space
    
    ;Check if we can make enough space by copying the data forward in the buffer
    if (this.maxBytesAvailable() < bytesRequested || this.used() / this.capacity() >= 0.75) 
    { ;We don't have enough free space or the buffer is mostly full already, so we need to expand
      this.resize(bytesRequested + this.capacity() + (this.capacity() >= 0x200000 ? 0x100000 : this.capacity()//2))
    }
    else
    {
      ;We have enough free space and the buffer is mostly unused, so we just need to copy the data forward
      DllCall("RtlMoveMemory", "ptr", this.bufStart, "ptr", this.dataStart, "ptr", this.used())
      this.dataEnd += this.bufStart - this.dataStart, this.dataStart := this.bufStart
    }
   
    return this.dataEnd
  }
  
  ;Call when finished writing data to the pointer given by lock()
  unlock(bytesUsed="")
  {
    this.dataEnd += bytesUsed != "" ? bytesUsed : this.isLocked
    this.isLocked := 0
  }
  
  ;Forces the buffer to be resized to newSize capacity
  ;This can be used to shrink the buffer, but it will not shrink the buffer the point where data will be lost in the process.
  resize(newSize=0)
  {
    ;Make sure we don't get rid of any data that we still need
    if (newSize < this.used())
      newSize := this.used()
    tmp := DllCall("HeapAlloc", "ptr", socket_buffer.heap, "uint", 0, "ptr", newSize)
    ;We can use this as an opportunity to move the data to the front of the new buffer.
    DllCall("RtlMoveMemory", "ptr", tmp, "ptr", this.dataStart, "ptr", this.used())
    DllCall("HeapFree", "ptr", socket_buffer.heap, "uint", 0, "ptr", this.bufStart)
    this.dataEnd += tmp - this.dataStart, this.dataStart := this.bufStart := tmp
    this.bufEnd := tmp + DllCall("HeapSize", "ptr", socket_buffer.heap, "uint", 0, "ptr", tmp)
  }
  
  ;Discards bytes from the start of the data segment
  discardBytes(bytesUsed)
  {
    if (bytesUsed = 0)
      return
    this.dataStart+=bytesUsed
    if (this.dataStart >= this.dataEnd) ;if we used all the data, reset the pointers
      this.dataStart := this.dataEnd := this.bufStart
    ;We should shrink the buffer if it has grown large and is mostly unused.
    if (this.used() / this.capacity() <= 0.10 && this.capacity() > 20971520) ;20Mb
      this.resize(this.used() + 10485760) ;10Mb
  }
  
  ;Discards the entire data section.
  discardAll()
  {
    this.dataStart := this.dataEnd := this.bufStart
  }
}