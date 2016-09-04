class integer_type
{
  static type := "integer"
  
  __New(value)
  {
    this.value := value
  }
  
  get_id()
  {
    return 1
  }
  
  get_length()
  {
    return 8
  }
  
  write_self(ptr)
  {
    Numput(this.value, ptr+0, 0, "int64")
  }
  
  read_self(ptr, len)
  {
    return new integer_type(Numget(ptr+0, 0, "int64"))
  }
}

class string_type
{
  static type := "string"
  
  __New(value)
  {
    this.value := value
  }
  
  get_id()
  {
    return 2
  }
  
  get_length()
  {
    return StrPut(this.value, "utf-16") * 2
  }
  
  write_self(ptr)
  {
    StrPut(this.value, ptr, "utf-16")
  }
  
  read_self(ptr, len)
  {
    return new string_type(StrGet(ptr, "utf-16"))
  }
}

class binary_type
{
  static type := "binary"

  __New(ptr, len)
  {
    this.ptr := ptr
    this.len := len
  }
  
  get_id()
  {
    return 3
  }
  
  get_length()
  {
    return this.len
  }
  
  write_self(ptr)
  {
    ; ptr := NumPut(this.len, ptr+0, 0, "uint")
    DllCall("RtlMoveMemory", "ptr", ptr, "ptr", this.ptr, "ptr", this.len)
  }
  
  read_self(ptr, len)
  {
    return new binary_type(ptr, len)
  }
}

class file_type
{
  static type := "file"

  __New(filepath)
  {
    this.filepath := filepath
  }
  
  get_id()
  {
    return 4
  }
  
  get_length()
  {
    this.open()
    return this.file.length + 2 * StrLen(this.filename) + 6
  }
  
  write_self(ptr)
  {
    this.open()
    ptr += StrPut(this.filename, ptr+0, "utf-16") * 2
    Numput(file.length, ptr+0, 0, "uint")
    this.file.seek(0, 0)  ;Force file stream to start of file in case AHK consumed the BOM
    this.file.RawRead(ptr + 4, file.length)
  }
  
  read_self(ptr, len)
  {
    filename := StrGet(ptr, "utf-16")
    ret := new file_type(filename)
    ptr += StrLen(filename) * 2 + 2
    ret.len := NumGet(ptr+0, 0, "uint")
    ret.ptr := ptr+4
    return ret
  }
  
  open()
  {   
    if (!this.file_opened)
    {
      filepath := this.filepath
      this.file := FileOpen(filepath, "r")
      SplitPath, filepath, filename
      this.filename := filename
      this.file_opened := true
    }
  }
  
  save(filepath)
  {
    if (!this.len || !this.ptr)
      return
    file := FileOpen(filepath != "" ? filepath : this.filepath, "w")
    file.RawWrite(this.ptr, this.len)
    file.close()
  }
  
  __Delete()
  {
    if (this.file_opened)
      this.file.close()
  }
}

class object_type
{
  static type := "object"

  __New(obj_or_json)
  {
    if (IsObject(obj_or_json))
    {
      this.value := obj_or_json
      this.json := objToJson(obj_or_json)
    }
    else
    {
      this.value := jsonToObj(obj_or_json, p := 1)
      this.json := obj_or_json
    }
  }
  
  get_id()
  {
    return 5
  }
  
  get_length()
  {
    return StrPut(this.json, "utf-16") * 2
  }
  
  write_self(ptr)
  {
    StrPut(this.json, ptr, "utf-16")
  }
  
  read_self(ptr, len)
  {
    return new object_type(StrGet(ptr, "utf-16"))
  }
}

class float_type
{
  static type := "float"

  __New(value)
  {
    this.value := value
  }
  
  get_id()
  {
    return 6
  }
  
  get_length()
  {
    return 8
  }
  
  write_self(ptr)
  {
    Numput(this.value, ptr+0, 0, "double")
  }
  
  read_self(ptr, len)
  {
    return new float_type(Numget(ptr+0, 0, "double"))
  }
}

;################################################################################
;                     Object<->String
;################################################################################
jsonToObj(byref jsonStr, byref p) ;, indent = "") ; p = 1
{
  static constants = {true:true, false:false, null:"", _:"", Function:""}
  ;cmdi(indent "S at " p ": " RegexReplace(SubStr(jsonStr, p, 25), "[ `t`r`n]+", " ") "..." )
  r := Object(), pp := 0
  p := RegexMatch(jsonStr, "[^ `t`r`n]", firstChar, p)+1
  lastChar := firstChar = "{" ? "}" : "]"
  while( res2 != lastChar && p < strlen(jsonStr) && p > pp)
  {
    ;cmd(indent " L at " p ": " RegexReplace(SubStr(jsonStr, p, 25), "[ `t`r`n]+", " ") "..." )
    Name := A_Index, pp := p
    if (firstChar = "{")
    { ;Expect: Name, possibly quoted
      p := RegexMatch(jsonStr, "([^ `t`r`n:]*)[ `t`r`n]*:", res, p)+strlen(res)
      Name := RegexReplace(res1, """(.*)""", "$1") ;strip quotes if needed
    }
    p := RegexMatch(jsonStr, "[^ `t`r`n]", res, p) ;Find first character but don't consume
    if res in {,[
      r[Name ""] := jsonToObj(jsonStr, p), p := RegexMatch(jsonStr, "[,\]}]", res2, p)+1
    else
    { ;else it is a basic type
      p := RegexMatch(jsonStr, "(""[^""]*""|.*?)[ `t`r`n]*([,\]}])", res, p) + strlen(res)
      if res1 is number
        r[Name ""] := res1
      else if (constants.HasKey(res1))
        r[Name ""] := constants[res1]
      else
        r[Name ""] := RegexReplace(res1, """(.*)""", "$1")
    }
    ;Expect: comma or lastchar
  }
  ;cmd(indent "E at " p ": " RegexReplace(SubStr(jsonStr, p, 25), "[ `t`r`n]+", " ") "..." )
  return r
}

objToJson(obj)
{
  if !IsObject(obj)
    return ""
  simpleArray := true
  for k,v in obj
  {
    if (k != A_Index)
    {
      simpleArray := false
      break
    }
  }
  str := simpleArray ? "[" : "{"
  for k,v in obj
  {
    if (k = "")
      k := """"""
    if IsObject(v)
    {
      if IsFunc(v.name)
        v := "Function"
      else
        v := objToJson(v)
      str .= (simpleArray ? "" : k ":") v ", "
    }
    else if v is number
      str .= (simpleArray ? "" : k ":") v ", "
    else if (v = "")
      str .= (simpleArray ? "" : k ":") "_, "
    else
      str .= (simpleArray ? "" : k ":") """" v """, "
  }
  if IsObject(obj.base)
    str .= "base:" objToJson(obj.base)
  return RegexReplace(str, ", $", "") (simpleArray ? "]" : "}")
}

;################################################################################
;                     Register types with socket class
;################################################################################
socket_tcp.registerType(integer_type)
socket_tcp.registerType(string_type)
socket_tcp.registerType(file_type)
socket_tcp.registerType(binary_type)
socket_tcp.registerType(object_type)
socket_tcp.registerType(float_type)
