class Database{	
	__New(strDir,bits=64,strArrays*){
		this.arrArrays:=[]
		
		; If the specified database path doesn't contain a ".db" file, append ".db" to the directory
		this.strDir:=strDir (SubStr(strDir,-2)=".db"?"":".db")
		
		; Define bits
		this.bits:=bits
		
		; Add each array to the container and initialize each one
		for k,v in strArrays
			this.arrArrays.Push(v)
		
		; If the class failed to open the file
		if(!this.objFile:=FileOpen(this.strDir,"rw-rw")){
			MsgBox,16,Error - File Open Failure,% """" this.strDir """ failed to open."
			this.Close()
			this:=""
			return,-1
		}
		
		; For further convenience
		this.Read()
	}
	
	; Reads the database and puts the data into the arrays
	Read(){
		this.objFile.Position:=0
		
		for arrKey,array in this.arrArrays
			this[array]:=[]
		
		subVars:=["len","obj"]
		
		for subKey,subVar in subVars{
			for varKey,var in this.arrArrays{
				len:=""
				Loop,% this.bits//8
				{	h:=hex(this.objFile.ReadUChar())
					len.=enum("0",2-StrLen(h)) h
				}
				len:=dec(len)
				%var%_%subVar%:=len
			}
		}
		
		for varKey,var in this.arrArrays{
			thisObjLen:=%var%_obj-1
			offsets:=0
			Loop,%thisObjLen%{
				len:=""
				Loop,% this.bits//8
				{	h:=hex(this.objFile.ReadUChar())
					len.=enum("0",2-StrLen(h)) h
				}
				len:=dec(len)
				%var%_os%A_Index%:=len
			}
		}
		
		for varKey,var in this.arrArrays{
			thisOffset:=%var%_obj
			previousOffset:=0
			Loop,%thisOffset%{
				if(A_Index<thisOffset)
					this[var][A_Index]:=this.objFile.Read(%var%_os%A_Index%-previousOffset)
				else
					this[var][A_Index]:=this.objFile.Read(%var%_len-previousOffset)
				previousOffset:=%var%_os%A_Index%
			}
		}
	}
	
	; Writes to the database given the assigned arrays
	Save(){
		this.objFile.Length:=0
		
		for key,thisArr in this.arrArrays{
			len:=0
			for k,v in this[thisArr]
				len+=StrLen(v)
			if(len>18446744073709551615) ; Larger than a 64-bit unsigned integer
				return,-1
			if(len){
				format:=A_FormatInteger
				SetFormat,Integer,H
				len+=0
				len:=StrReplace(len,"0x")
				SetFormat,Integer,%format%
				len:=enum("0",(this.bits//4)-StrLen(len)) len
				p:=1
				while(p<(this.bits//4)){
					thisByte:=SubStr(len,p,2)
					this.objFile.WriteUChar(dec(thisByte))
					p+=2
				}
			}else
				this.objFile.Position:=this.objFile.Position+(this.bits//8)
		}
		
		for key,thisArr in this.arrArrays{
			if(len:=this[thisArr].Length()){
				if(len>18446744073709551615)
					return,-1
				format:=A_FormatInteger
				SetFormat,Integer,H
				len+=0
				len:=StrReplace(len,"0x")
				SetFormat,Integer,%format%
				len:=enum("0",(this.bits//4)-StrLen(len)) len
				p:=1
				while(p<(this.bits//4)){
					thisByte:=SubStr(len,p,2)
					this.objFile.WriteUChar(dec(thisByte))
					p+=2
				}
			}else
				this.objFile.Position:=this.objFile.Position+(this.bits//8)
		}
		
		for key,thisArr in this.arrArrays{
			len:=i:=0
			l:=this[thisArr].Length()
			if(l>18446744073709551615)
				return,-1
			while(i<l-1){
				i++
				val:=this[thisArr][i]
				len+=StrLen(val)
				if(len){
					if(len>18446744073709551615)
						return,-1
					prevLen:=len
					format:=A_FormatInteger
					SetFormat,Integer,H
					len+=0
					len:=StrReplace(len,"0x")
					SetFormat,Integer,%format%
					len:=enum("0",(this.bits//4)-StrLen(len)) len
					p:=1
					while(p<(this.bits//4)){
						thisByte:=SubStr(len,p,2)
						this.objFile.WriteUChar(dec(thisByte))
						p+=2
					}
					len:=prevLen
				}else
					this.objFile.Position:=this.objFile.Position+(this.bits//8)
			}
		}
		
		for key,thisArr in this.arrArrays{
			for k,v in this[thisArr]
				this.objFile.Write(v)
		}
		
		;this.Read()
	}
	
	__Delete(){
		this.objFile.Close()
	}
}

hex(num){
	format:=A_FormatInteger
	SetFormat,Integer,H
	num+=0
	SetFormat,Integer,%format%
	return,StrReplace(num,"0x")
}

dec(hex){
	format:=A_FormatInteger
	SetFormat,Integer,D
	if(!InStr(hex,"0x"))
		hex:="0x" hex
	hex+=0
	SetFormat,Integer,%format%
	return,hex
}

enum(char,len){
	loop,%len%
		return.=char
	return,return
}
