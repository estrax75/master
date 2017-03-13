;soilCoeffs[0] As,   soilCoeffs[1] Bs
function CheckDataTOC, red, nir, soilCoeffs
  ;
  ; to be updated
  ;
  ; for AVHRR
  ;
  
  ; Bad Data --> 1
  validIdx=where(finite(red) and finite(nir), count, compl=compl)
  mask=red & mask[*]=1
  
  mask[validIdx] = (((red[validIdx] le 0.) + (nir[validIdx] le 0.)) gt 0.) * 1
  ;window, 0, xsize=720, ysize=360
 ; tv, congrid(mask, 720,360)
;  stop
  ;mask = mask + (((red ge 0.5) + (nir ge 0.6)) gt 0) * (mask eq 0) * 2
  ; attempt to catch cloud/soil in a better way
  ; Cloud/Ice(?) --> 2
  mask[validIdx] = mask[validIdx] + (((red[validIdx] ge 0.5) + (nir[validIdx] ge 0.7)) gt 0) * (mask[validIdx] eq 0) * 2
 ; tv, congrid(mask, 720,360)

  ; old version 
  ;mask = mask + (nir lt 0.15) * (mask eq 0) * 3
  ;mask = mask + (red gt 0.3) * (mask eq 0) * 4
  ;mask = mask + (nir lt (1.33*red)) * (mask eq 0) * 4
  ; new (check table) 
  ;print, 'Bare soil As', 'Bare soil Bs', soilCoeffs[0], soilCoeffs[1]
  ; soil (NOAA mission dependent parameters) --> 4
  mask[validIdx] = mask[validIdx] + (nir[validIdx] lt (soilCoeffs[0]*red[validIdx]+soilCoeffs[1])) * (mask[validIdx] eq 0) * 4
  ;mask[compl]=1
  return, byte(mask)
end
