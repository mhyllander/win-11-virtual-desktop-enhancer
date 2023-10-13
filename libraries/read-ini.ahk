
; https://autohotkey.com/board/topic/33506-read-ini-file-in-one-go/

ReadIni( filename := 0 )
; Read a whole .ini file and creates variables like this:
; %Section%%Key% = %value%
{
	global
	Local s, c, p, key, k, v, i, match, isArray

	if not filename
		filename := SubStr( A_ScriptName, 1, -3 ) . "ini"

	s := FileRead(filename)

	Loop Parse s, "`n`r", A_Space . A_Tab
	{
		c := SubStr(A_LoopField, 1, 1)
		if (c="[")
			key := SubStr(A_LoopField, 2, -1)
		else if (c=";")
			continue
		else {
			p := InStr(A_LoopField, "=")
			if p {
				k := SubStr(A_LoopField, 1, p-1)
				v := SubStr(A_LoopField, p+1)
				;if (RegExMatch(v, "^[0-9]+$", &match) > 0) {
				;	v := Integer(v)
				;}
				isArray := RegExMatch(k, "^(.*?)([0-9]+)$", &match)
				if (isArray) {
					k := match[1]
					i := Integer(match[2])
					if (%key%%k%.Length >= i) {
						%key%%k%[i] = v
					} else {
						%key%%k%.InsertAt(i, v)
					}
				} else {
					%key%%k% := v
				}
			}
		}
	}
}