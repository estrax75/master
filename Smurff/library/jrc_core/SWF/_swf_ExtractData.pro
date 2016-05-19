
; Procedures needed:
; .run /home/melinfr/OC/CAL/SWF/read_nc4_data

; .run /home/melinfr/OC/CAL/SWF/ExtractSubset

; .run /home/melinfr/OC/CAL/SWF/SWFInfo
; .run /home/melinfr/OC/CAL/SWF/FindPixel

; Execution
; .run /home/melinfr/OC/CAL/SWF/ExtractDataAEROC

PRO _ExtractData,k_site,option,n_side,in_dir,out_dir,root

; Site chosen for extraction of data.

; MSEA
IF ( k_site EQ 1 ) THEN BEGIN
 sitelat = 34.
 sitelon = 25.
 ext = "msea"
ENDIF



; Size of extraction (extraction of a square of n_side x n_side pixels) with n_side = 2n_e +1
n_e = FIX ( (n_side-1)/2 + 0.1)

; type of the files to be read
findvariable = STRCOMPRESS(in_dir+root,/REMOVE_ALL)

; List of files.
filename=FINDFILE(findvariable, count=NbFiles)

print,'Number of files: ',NbFiles

; Delta time for LAC data: 166msec.
delta_time = 200L

; Loop over the files.
FOR f=0,NbFiles-1 DO BEGIN
;FOR f=1,1 DO BEGIN

    print,filename[f]
    
; Define output    

    ifile = STRMID(STRCOMPRESS(filename[f],/REMOVE_ALL),STRLEN(in_dir), $
                   STRLEN(STRCOMPRESS(filename[f],/REMOVE_ALL))-STRLEN(in_dir))

    ofile = STRMID(STRCOMPRESS(filename[f],/REMOVE_ALL),STRLEN(in_dir), $
                   STRLEN(STRCOMPRESS(filename[f],/REMOVE_ALL))-STRLEN(in_dir))
                   
    ofile = STRCOMPRESS(out_dir+ofile+"."+ext,/REMOVE_ALL)
	
; Get all SeaWiFS information useful for processing: time, location, size,...        
    SWFInfo,filename[f],SeaWiFSStruct

    SeaWiFSStruct.Source = ifile

	IF ( STRPOS(ifile,"LAC") GE 0 ) THEN ctype = "LAC" ELSE ctype = "GAC"
	SeaWiFSStruct.Type = ctype


; Find nearest pixel to searched location.
    FindPixel,SeaWiFSStruct,sitelat,sitelon,n_side,line,elem,istatus

    nline = SeaWiFSStruct.NumberLine
    nelem = SeaWiFSStruct.NumberPixel

mm = LONARR(n_side)
; Check if the pixel is not close to edges and if the line are temporally contiguous. 
IF ( istatus EQ 1 ) THEN BEGIN

   IF ( line LE n_e OR line GE nline-n_e OR elem LE n_e OR elem GE nelem-n_e ) THEN BEGIN
        istatus = -1
   ENDIF ELSE BEGIN

     FOR l=0,n_side-1 DO mm[l] = SeaWiFSStruct.msec[line+l-n_e]

     FOR l=0,n_side-2 DO IF ( mm[l+1]-mm[l] GT delta_time ) THEN istatus = -1

   ENDELSE
ENDIF

IF ( SeaWiFSStruct.StartDay NE SeaWiFSStruct.EndDay ) THEN BEGIN

    IF ( SeaWiFSStruct.StartMillisec GT mm[0] ) THEN BEGIN
        SeaWiFSStruct.StartDay = SeaWiFSStruct.EndDay
        SeaWiFSStruct.StartYear = SeaWiFSStruct.EndYear
    ENDIF
    
    IF ( SeaWiFSStruct.EndMillisec LT mm[n_side-1] ) THEN BEGIN
        SeaWiFSStruct.EndDay = SeaWiFSStruct.StartDay
        SeaWiFSStruct.EndYear = SeaWiFSStruct.StartYear
    ENDIF 

ENDIF

    SeaWiFSStruct.StartMillisec = mm[0]
    SeaWiFSStruct.EndMillisec = mm[n_side-1]

; Go ahead only if a contiguous square of pixels is available around the site.
IF ( istatus EQ 1 ) THEN BEGIN

; Get the geophysical values.
     SelectData,filename[f],SeaWiFSStruct,line,elem,n_side,SeaWiFSData,option

     SeaWiFSData.Latitude = sitelat
     SeaWiFSData.Longitude = sitelon

; Write the various variables into a ascii file.
;     WriteData,ofile,SeaWiFSData,option
STOP
ENDIF

ENDFOR
; End of loop over files.

END
