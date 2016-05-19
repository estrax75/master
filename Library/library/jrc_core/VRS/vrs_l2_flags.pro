


;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; NAME:
;       l2_flags
;
; PURPOSE:
;
;       split a flag value into base-2 bits.
;
; CATEGORY:
; 
;       statistics
;
; CALLING SEQUENCE:
;
;       value = l2_flags(flag)
;
; INPUTS:
;			flag:			flag value
;			
; OUTPUTS:
;			return value:	flag array in bit
;			
; KEYWORD PARAMETERS:
;					none
;
; COMMENTS:
;	
; REFERENCES:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;
;       Written by: F. MELIN, JRC/IES/GEM.
;			
;
;------------------------------------------------------------------------------

FUNCTION vrs_l2_flags,flag


bin = BYTARR(32)

FOR j=0,31 DO BEGIN
   powerOfTwo = 2uL^j
   IF (LONG(flag) AND powerOfTwo) EQ powerOfTwo THEN $
      bin(j) = 1 ELSE bin(j) = 0
ENDFOR

;RETURN, Reverse(bin)
RETURN, bin

END

;           Attribute =>   5       f01_name = ATMFAIL
;           Attribute =>   6       f02_name = LAND
;           Attribute =>   7       f03_name = PRODWARN
;           Attribute =>   8       f04_name = HIGLINT
;           Attribute =>   9       f05_name = HILT
;           Attribute =>  10       f06_name = HISATZEN
;           Attribute =>  11       f07_name = COASTZ
;           Attribute =>  12       f08_name = SPARE
;           Attribute =>  13       f09_name = STRAYLIGHT
;           Attribute =>  14       f10_name = CLDICE
;           Attribute =>  15       f11_name = COCCOLITH
;           Attribute =>  16       f12_name = TURBIDW
;           Attribute =>  17       f13_name = HISOLZEN
;           Attribute =>  18       f14_name = SPARE
;           Attribute =>  19       f15_name = LOWLW
;           Attribute =>  20       f16_name = CHLFAIL
;           Attribute =>  21       f17_name = NAVWARN
;           Attribute =>  22       f18_name = ABSAER
;           Attribute =>  23       f19_name = SPARE
;           Attribute =>  24       f20_name = MAXAERITER
;           Attribute =>  25       f21_name = MODGLINT
;           Attribute =>  26       f22_name = CHLWARN
;           Attribute =>  27       f23_name = ATMWARN
;           Attribute =>  28       f24_name = SPARE
;           Attribute =>  29       f25_name = SEAICE
;           Attribute =>  30       f26_name = NAVFAIL
;           Attribute =>  31       f27_name = FILTER
;           Attribute =>  32       f28_name = SSTWARN
;           Attribute =>  33       f29_name = SSTFAIL
;           Attribute =>  34       f30_name = HIPOL
;           Attribute =>  35       f31_name = PRODFAIL
;           Attribute =>  36       f32_name = SPARE

;  ATMFAIL             1    0
;  LAND                2    1
;  SPARE3              4    2
;  HIGLINT             8    3
;  HILT               16    4
;  HISATZEN           32    5
;  COASTZ             64    6
;  NEGLW             128    7
;  STRAYLIGHT        256    8
;  CLDICE            512    9
;  COCCOLITH        1024    10
;  TURBIDW          2048    11
;  HISOLZEN         4096    12 
;  HITAU            8192    13
;  LOWLW           16384    14
;  CHLFAIL         32768    15
;  NAVWARN         65536    16
;  ABSAER         131072    17
;  SPARE2         262144    18
;  MAXAERITER     524288    19
;  MODGLINT      1048576    20
;  CHLWARN       2097152    21
;  ATMWARN       4194304    22
;  DARKPIXEL     8388608    23
;  SEAICE       16777216    24
;  NAVFAIL      33554432	25
;  FILTER       67108864	26
;  SSTWARN     134217728	27
;  SSTFAIL     268435456	28
;  SPARE       536870912	29
;  HIPOL      1073741824	30
;  OCEAN      2147483648 	31


