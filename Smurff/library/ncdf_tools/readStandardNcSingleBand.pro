function readStandardNcSingleBand, bandName, files, mask, convFunction, nanValue=nanValue, $
  NOTFOUND=NOTFOUND, REVERSE=REVERSE, TRANSPOSE=TRANSPOSE, ONEDIM=ONEDIM

  COMMON smurffCB, mainApp
  
  gOp=obj_new('GenericOperator', mainApp, tempDir)
  NOTFOUND=1
  for i=0, n_elements(files)-1 do begin
    ;res=gOp->readNcdfVar(files[i], bandName, FOUND=FOUND, REVERSE=REVERSE, TRANSPOSE=TRANSPOSE)
    ;if ~NCDF_IsValidFile(files[i]) then 
    res=gOp->readNcdfVar(files[i], bandName, FOUND=FOUND, REVERSE=REVERSE, TRANSPOSE=TRANSPOSE)
    if keyword_set(FOUND) then begin
       NOTFOUND=0
       break
    endif
  endfor
  obj_destroy, gOp
  if ~keyword_set(FOUND) then begin
    doLog, 'band: '+bandName+' not found in '+files+'. Check spelling or file contents', LEVEL=4
    return, -1
  endif
  if ~keyword_set(nanValue) then localNanValue=min(res.data)-1 else localNanValue=nanValue 
  checkIdx=where(res.data ne localNanValue, count) 
  ;if count eq 0 then message, 'band: ', bandName, ' contains only nan ( '+nanValue+' ) values, or file is missing.'
  if count eq 0 then doLog, 'band: ', bandName, ' contains only nan ( '+localNanValue+' ) values, or file is missing.', LEVEL=4
  dims=size(res.data, /DIM)
  resDims=(size(dims, /DIM))[0]
  dt=size(res.data, /TYPE)
  ns=dims[0]
  ; force second dimensions to at least 1 (latitude/longitudine georef global specification from AVHHR)
  if resDims ne 1 then nl=dims[1] else nl=1 

  
  if n_elements(nanValue) eq 1 then thisMask = res.data eq nanValue else thisMask=res.data
  if n_elements(mask) eq 0 and n_elements(thisMask) ne 0 then begin
    mask = thisMask
  endif else begin
    mask = res.data
    mask[*]=0b
  endelse 
  res.data=convertValues(res.data, convFunction, ignoreValue=nanValue)
  
  return, {data:res.data, mask:mask, nl:nl, ns:ns, dt:dt}
  
end