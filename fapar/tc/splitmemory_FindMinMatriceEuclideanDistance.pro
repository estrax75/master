Pro sm_call_mean_3,  daysNumber, data_in, mean_field, std_mean, std_field, nfield, splitDims, faparMean, cloudtype=cloudtype
  ;
  if n_elements(splitDims) ne 2 then splitDims=[7200,3600]
  mean_field={red:fltarr(splitDims[0],splitDims[1]), nir:fltarr(splitDims[0],splitDims[1]), fapar:fltarr(splitDims[0],splitDims[1])}
  buf1=fltarr(splitDims[0],splitDims[1])
  buf2=fltarr(splitDims[0],splitDims[1])
  ;

  if nfield eq 3 then buf3=fltarr(splitDims[0],splitDims[1])
  tt=[0,daysNumber]
  num_used=bytarr(splitDims[0],splitDims[1])
  one=num_used
  one(*,*)=1
  ; compute the average for each field, i.e red nir and fapar ...
  ;
  if nfield eq 3 then begin

    for t=0, tt(1)-1 do begin
      validMask=finite(data_in(t).fapar(*,*)) and finite(data_in(t).red(*,*)) and finite(data_in(t).nir(*,*))
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(data_in(t).fapar[goodIndexes] gt 0.0 and $
        data_in(t).red[goodIndexes] gt 0.0 and data_in(t).red[goodIndexes] lt 1.0 and $
        data_in(t).nir[goodIndexes] gt 0.0 and data_in(t).nir[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg
      idx_c = where(validMaskVeg eq 1 and data_in(t).flag(*,*) eq 0, countVeg)

      ; previous (without NaN)
      ;      idx_cOld= where((data_in(t).red gt 0. and data_in(t).red lt 1.) and $
      ;        (data_in(t).nir gt 0. and data_in(t).nir lt 1.) and $
      ;        (data_in(t).fapar gt 0. and data_in(t).fapar le 1.) and $
      ;        (data_in(t).flag eq 0), countVegOld)
      ;      if countVegOld ne countVeg then stop
      if idx_c(0) ge 0 then begin
        buf1(idx_c)= data_in(t).red(idx_c)+buf1(idx_c)
        buf2(idx_c)= data_in(t).nir(idx_c)+buf2(idx_c)
        buf3(idx_c)= data_in(t).fapar(idx_c)+buf3(idx_c)
        num_used(idx_c)=num_used(idx_c)+one(idx_c)
      endif
    endfor
  endif else begin
    for t=0, tt(1)-1 do begin
      validMask=finite(data_in(t).fapar(*,*)) and finite(data_in(t).red(*,*)) and finite(data_in(t).nir(*,*))
      goodIndexes=where(validMask eq 1)

      idxMaskSoil=where(data_in(t).fapar[goodIndexes] eq 0 and $
        data_in(t).red[goodIndexes] gt 0.0 and data_in(t).red[goodIndexes] lt 1.0 and $
        data_in(t).nir[goodIndexes] gt 0.0 and data_in(t).nir[goodIndexes] lt 1.0)
      validMaskSoil=validMask*0
      validMaskSoil[goodIndexes[idxMaskSoil]]=1
      validMaskSoil=validMask*validMaskSoil
      idx_c= where(validMaskSoil eq 1 and (data_in(t).flag eq 4 or data_in(t).flag eq 5), countSoil)
      ;      idx_cOld= where((data_in(t).red gt 0. and data_in(t).red lt 1.) and $
      ;        (data_in(t).nir gt 0. and data_in(t).nir lt 1.) and $
      ;        (data_in(t).fapar eq 0.) and $
      ;        (data_in(t).flag eq 4 or data_in(t).flag eq 5), countSoilOld)
      ;      if countSoilOld ne countSoil then stop
      ;      a=where((data_in(t).red gt 0. and data_in(t).red lt 1.), redc)
      ;      b=where((data_in(t).nir gt 0. and data_in(t).nir lt 1.), nirc)
      ;      c=where(data_in(t).fapar eq 0., faparc)
      ;      d=where(data_in(t).flag eq 4 or data_in(t).flag eq 5, flagc)
      ;print,  redc, nirc, faparc, flagc
      ; help, t, idx_c
      ; stop
      if idx_c(0) ge 0 then begin
        buf1(idx_c)= data_in(t).red(idx_c)+buf1(idx_c)
        buf2(idx_c)= data_in(t).nir(idx_c)+buf2(idx_c)
        num_used(idx_c)=num_used(idx_c)+one(idx_c)
      endif
    endfor
  endelse
  if nfield eq 3 then begin
    idx_ok=where(num_used ge 3b and buf1 gt 0.0 and buf2 gt 0. and buf3 gt 0.)   ; ng 2016
    ;help, idx_ok
    if idx_ok(0) ge 0 then begin
      buf1(idx_ok)=buf1(idx_ok)/float(num_used(idx_ok))
      buf2(idx_ok)=buf2(idx_ok)/float(num_used(idx_ok))
      buf3(idx_ok)=buf3(idx_ok)/float(num_used(idx_ok))
      ;   stop
    endif
    idx_nok=where(num_used le 2b or buf1 le 0.0 or buf2 le 0.0 or buf3 le 0.0)   ; ng 2016
    if idx_nok(0) ge 0 then begin
      buf1(idx_nok)=-1.0
      buf2(idx_nok)=-1.0
      buf3(idx_nok)=-1.0
    endif
  endif else begin
    idx_ok=where(num_used ge 3b and buf1 gt 0.0 and buf2 gt 0.)  ;ng 2016
    ; bare soil here
    if idx_ok(0) ge 0 then begin
      buf1(idx_ok)=buf1(idx_ok)/float(num_used(idx_ok))
      buf2(idx_ok)=buf2(idx_ok)/float(num_used(idx_ok))
    endif
    idx_nok=where(num_used le 2b or buf1 lt 0.0 or buf2 lt 0.0)  ; ng 2016
    ; no data here
    if idx_nok(0) ge 0 then begin
      buf1(idx_nok)=-1.0
      buf2(idx_nok)=-1.0
    endif
  endelse
  if n_elements(buf3) ne 0 then faparMean=buf3
  ;tvscl, faparMean
  mean_field(*,*).red=buf1(*,*)
  mean_field(*,*).nir=buf2(*,*)
  if nfield eq 3 then mean_field.fapar=buf3(*,*)
  ;
  ;window,0
  ;plot, mean_field.fapar(idx_ok), psym=1
  ;stop
  ;
  ;window, 0, xsize=splitDims(0), ysize=splitDims(1)/3.
  ;tvscl, congrid(buf1(*,*), splitDims(0), splitDims(1)/3.)
  ;stop
  ; compute the standard deviation for each field, i.e red nir and fapar ...
  ;
  initValues=fltarr(tt(1),splitDims[0],splitDims[1])
  initValues[*]=-1.0
  std_field={red:initValues, nir:initValues, fapar:initValues}
  if nfield eq 3 then begin
    for t=0, tt(1)-1 do begin
      buf1=fltarr(splitDims[0],splitDims[1])
      buf2=fltarr(splitDims[0],splitDims[1])
      buf3=fltarr(splitDims[0],splitDims[1])
      buf1(*,*)=-1.0
      buf2(*,*)=-1.0
      buf3(*,*)=-1.0
      ;buf=fltarr(splitDims[0],splitDims[1])
      ;buff=fltarr(splitDims[0],splitDims[1])
      ;
      ;print, 'size(buf(*,*))', 'data_in(t).red(*,*)', 'buff(*,*)', 'mean_field(0,*,*)'
      ;print, size(buf(*,*)), size(data_in(t).red(*,*)), size(buff(*,*)), size(mean_field(0,*,*))
      buf=data_in(t).red
      buff=mean_field.red
      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)
      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and data_in(t).flag eq 0 and num_used ge 3b, countBuf) ;ng 2016
      ; previous version without NaN
      ;idx=where((buf gt 0. and buf lt 1.0) and (buff gt 0. and buff lt 1.) and data_in(t).flag eq 0 and num_used ge 3b, countBuf) ;ng 2016
      if idx(0) ge 0 then buf1(idx) = abs(buf(idx)-buff(idx))
      buf=data_in(t).nir(*,*)
      buff(*,*)=mean_field.nir(*,*)
      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and data_in(t).flag eq 0 and num_used ge 3b, countBuf) ;ng 2016
      ; previous version without NaN
      ;idx=where((buf gt 0. and buf lt 1.0) and (buff gt 0. and buff lt 1.) and (data_in(t).flag eq 0) and num_used ge 3b, countBuf) ;ng 2016 )
      if idx(0) ge 0 then buf2(idx)= abs(buf(idx)-buff(idx))
      ;
      buf=data_in(t).fapar(*,*)
      ;buff(*,*)=mean_field(2,*,*)
      buff(*,*)=mean_field.fapar(*,*)
      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and data_in(t).flag eq 0 and num_used ge 3b, countBuf) ;ng 2016
      ;idx=where((buf gt 0. and buf le 1.0) and (buff gt 0. and buff le 1.) and (data_in(t).flag eq 0) and num_used ge 3b, countBuf) ;ng 2016
      if idx(0) ge 0 then buf3(idx)  = abs(buf(idx)-buff(idx))
      std_field.red(t,*,*)=buf1
      std_field.nir(t,*,*)=buf2
      std_field.fapar(t,*,*)=buf3
    endfor
    ;   stop
  endif else begin
    for t=0, tt(1)-1 do begin
      buf1=fltarr(splitDims[0],splitDims[1])
      buf2=fltarr(splitDims[0],splitDims[1])
      buf1(*,*)=-1.0
      buf2(*,*)=-1.0
      buf=fltarr(splitDims[0],splitDims[1])
      buff=fltarr(splitDims[0],splitDims[1])
      ;
      buf=data_in(t).red
      buff=mean_field.red
      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and (data_in(t).flag eq 4 or data_in(t).flag eq 5) and num_used ge 3b, countBuf) ;ng 2016
      ;;;;
      ;idxOld=where((buf gt 0. and buf lt 1.0) and (buff gt 0. and buff lt 1.) and (data_in(t).flag eq 4 or data_in(t).flag eq 5) and num_used ge 3b, countBufOld) ; ng 2016
      ;if countBufOld ne countBuf then stop
      if idx(0) ge 0 then buf1(idx) = abs(buf(idx)-buff(idx))
      ;
      buf=data_in(t).nir
      buff=mean_field(*,*).nir
      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and (data_in(t).flag eq 4 or data_in(t).flag eq 5) and num_used ge 3b, countBuf) ;ng 2016
      ;idxOld=where((buf gt 0. and buf lt 1.0) and (buff gt 0. and buff lt 1.) and (data_in(t).flag eq 4 or data_in(t).flag eq 5) and num_used ge 3b, countBufOld) ; ng 2016
      ;if countBufOld-countBuf gt 1 then stop
      if idx(0) ge 0 then buf2(idx)= abs(buf(idx)-buff(idx))
      std_field.red(t,*,*)=buf1
      std_field.nir(t,*,*)=buf2
      ;  stop
    endfor
  endelse
  ;window, /free
  ;plot,
  ;
  ; compute the mean of the standard deviation ...
  ;
  ; now split...
  std_mean={red:fltarr(splitDims[0],splitDims[1]), nir:fltarr(splitDims[0],splitDims[1]), temp:fltarr(splitDims[0],splitDims[1])}
  ;
  num_used_1=bytarr(splitDims[0],splitDims[1])
  num_used_2=bytarr(splitDims[0],splitDims[1])
  if nfield eq 3 then num_used_3=bytarr(splitDims[0],splitDims[1])
  buf=fltarr(splitDims[0],splitDims[1])
  buf1=fltarr(splitDims[0],splitDims[1])
  buf2=fltarr(splitDims[0],splitDims[1])
  if nfield eq 3 then buf3=fltarr(splitDims[0],splitDims[1])
  for t=0, tt(1)-1 do begin
    buf=reform(std_field.red(t,*,*))
    idx_ca=where(buf ge 0.)
    if idx_ca(0) ge 0 then begin
      buf1(idx_ca)=(buf(idx_ca)^2)+buf1(idx_ca)
      num_used_1(idx_ca)  = num_used_1(idx_ca)+one(idx_ca)
    endif
    buf=reform(std_field.nir(t,*,*))
    idx_ca=where(buf ge 0.)
    if idx_ca(0) ge 0 then begin
      buf2(idx_ca)=(buf(idx_ca)^2)+buf2(idx_ca)
      num_used_2(idx_ca)  = num_used_2(idx_ca)+one(idx_ca)
    endif
    if nfield eq 3 then begin
      buf=reform(std_field.fapar(t,*,*))
      idx_ca=where(buf ge 0.)
      if idx_ca(0) ge 0 then begin
        buf3(idx_ca)=(buf(idx_ca)^2)+buf3(idx_ca)
        num_used_3(idx_ca)  = num_used_3(idx_ca)+one(idx_ca)
      endif
    endif
  endfor
  idx_ok=where(num_used_1 ge 3b) ; ng 2016
  if idx_ok(0) ge 0 then buf1(idx_ok)=sqrt(buf1(idx_ok)/float(num_used_1(idx_ok)-1))
  idx_ok=where(num_used_2 ge 3b) ; ng 2016
  if idx_ok(0) ge 0 then buf2(idx_ok)=sqrt(buf2(idx_ok)/float(num_used_2(idx_ok)-1))
  if nfield eq 3 then begin
    idx_ok=where(num_used_3 ge 3b) ; ng 2016
    if idx_ok(0) ge 0 then buf3(idx_ok)=sqrt(buf3(idx_ok)/float(num_used_3(idx_ok)-1))
  endif
  ;
  ;erase
  ;window,0
  ;plot, num_used_1 , num_used_2, psym =2
  ;stop
  idx_nok=where(num_used le 2b)  ; ng 2016
  if idx_nok(0) ge 0 then begin
    buf1(idx_nok)=-1.0
    buf2(idx_nok)=-1.0
    if nfield eq 3 then buf3(idx_nok)=-1.0
  endif
  std_mean.red[*,*]=buf1[*,*]
  std_mean.nir[*,*]=buf2[*,*]
  if nfield eq 3 then begin
    std_mean.temp[*,*]=buf3[*,*]
    checkZeroes=where(std_mean.temp[*,*] eq 0, countZeroes)
    print,'Find # points with Standard Deviation Mean FAPAR = 0 ', countZeroes
  endif
  ;
  ;stop
  ;plot, mean_field(*,*).red, mean_field(*,*).nir, psym=1
  ;oplot, mean_field(*,*).nir, psym=4
  ;oplot, mean_field(*,*).fapar, psym=6

  if n_elements(cloudtype) eq 1 then begin
    ;device, decomposed=0
    ;faparcolor
    ;titles=['mask bit 1 or 2 (cloudy/shadow cloud)', 'fapar - mask bit 1 (cloudy)', 'fapar - mask bit 2 (shadow cloud)', 'fapar - no mask']
    ;fNames=['both', 'only_cloudy', 'only_shadow_cloud', 'no_mask']
    ;tempDir='E:\mariomi\Documents\projects\ldtr\data\pics\avhrr\'
    ;; fapar
    ;window, 0, title='fapar - '+titles[cloudtype]
    ;nday=n_elements(data_in)
    all_day_data=reform(data_in(*).fapar(0,1950:2100))
    meandata=reform(mean_field.fapar(0,1950:2100))
    stddata=reform(std_field.fapar(*,0,1950:2100))
    stdmean=reform(std_mean.temp(0,1950:2100))
    save, all_day_data, meandata, stddata, stdmean, filename='fpa_'+strcompress(cloudtype, /REMOVE)+'.sav'
    all_day_data=reform(data_in(*).red(0,1950:2100))
    meandata=reform(mean_field.red(0,1950:2100))
    stddata=reform(std_field.red(*,0,1950:2100))
    stdmean=reform(std_mean.red(0,1950:2100))
    save, all_day_data, meandata, stddata, stdmean, filename='red_'+strcompress(cloudtype, /REMOVE)+'.sav'
    all_day_data=reform(data_in(*).nir(0,1950:2100))
    meandata=reform(mean_field.nir(0,1950:2100))
    stddata=reform(std_field.nir(*,0,1950:2100))
    stdmean=reform(std_mean.nir(0,1950:2100))
    save, all_day_data, meandata, stddata, stdmean, filename='nir_'+strcompress(cloudtype, /REMOVE)+'.sav'
;    plot, data_in(0).fapar(0,1950:2100), yr=[0.,0.6], min=0.01, psym = 3, max=0.9
;    ;for t=0, nday-1 do oplot, data_in(t).fapar(0,1950:2100), col=fix(float(t)*255/nday), psym = 2, min=0.01
;    ;for t=0, nday-1 do oplot, mean_field.fapar(0,1950:2100)+std_field.fapar(t,0,1950:2100), col=fix(float(t)*255/nday), min=0.01
;    nData=float(n_elements(data_in(0).fapar(0,1950:2100)))
;    for t=0, nday-1 do begin
;      oplot, data_in(t).fapar(0,1950:2100), col=fix(float(t)*255/nday), psym = 2, min=0.01
;      oplot, mean_field.fapar(0,1950:2100)+std_field.fapar(t,0,1950:2100), col=fix(float(t)*255/nday), min=0.01
;      plots, [0., .05], [1.*t/nday,1.*t/nday], /NORM, col=fix(float(t)*255/nday), thick=4.
;      xyouts, .05, 1.*t/nday, string(t+1, format='(I02)'), /NORM, col=fix(float(t)*255/nday), charsize=1.2, ALIGN=1.;fix(float(t)*255/nday)
;    endfor
;    device, decomposed=1
;    oplot, std_mean.temp(0,1950:2100), min=0.01, col=0l, thick=2.5
;    oplot, mean_field.fapar(0,1950:2100), line = 0, min=0.01, thick=2.5, color=255l*255*255
;    oplot, mean_field.fapar(0,1950:2100)+ std_mean.temp(0,1950:2100), min=0.01, color=255l*255*255, thick=1.5, max=0.9, linestyle=3
;    oplot, mean_field.fapar(0,1950:2100)- std_mean.temp(0,1950:2100), min=0.01, color=255l*255*255, thick=1.5, linestyle=3
;    device, decomposed=0
;    save, all_day_data, meandata, stddata, stdmean, filename='fpa.sav'
;    all_day_data=0 & meandata=0 & stddata=0 & stdmean=0
;    restore, filename='fpa.sav'
;    window, 1, title='fapar - '+titles[cloudtype]
;    plot, reform(all_day_data[*,0]), yr=[0.,0.6], min=0.01, psym = 3, max=0.9
;    nData=float(n_elements(all_day_data[*,0]))
;    nday=float(n_elements(all_day_data[0,*]))
;    for t=0, nday-1 do begin
;      oplot, reform(all_day_data[*,t]), col=fix(float(t)*255/nday), psym = 2, min=0.01
;      oplot, reform(meandata)+reform(stddata[t]), col=fix(float(t)*255/nday), min=0.01
;      plots, [0., .05], [1.*t/nday,1.*t/nday], /NORM, col=fix(float(t)*255/nday), thick=4.
;      xyouts, .05, 1.*t/nday, string(t+1, format='(I02)'), /NORM, col=fix(float(t)*255/nday), charsize=1.2, ALIGN=1.;fix(float(t)*255/nday)
;    endfor
;    device, decomposed=1
;    oplot, reform(stdmean), min=0.01, col=0l, thick=2.5
;    oplot, reform(meandata), line = 0, min=0.01, thick=2.5, color=255l*255*255
;    oplot, reform(meandata)+ reform(stdmean), min=0.01, col=255l*255*255, thick=1.5, max=0.9, linestyle=3
;    oplot, reform(meandata)- reform(stdmean), min=0.01, col=255l*255*255, thick=1.5, linestyle=3
;    device, decomposed=0
;    
;    plotimg=tvrd(true=1)
;    fName=tempDir+'fapar_'+fNames[cloudtype]+'.png'
;    write_png,fName,plotimg
;    ;; b1 / red
;    window, 1, title='red - '+titles[cloudtype]
;    plot, data_in(0).red(0,1950:2100), yr=[0.,0.6], min=0.01, psym = 3, max=0.9
;    for t=0, nday-1 do begin
;      oplot, data_in(t).red(0,1950:2100), col=fix(float(t)*255/nday), psym = 2, min=0.01
;      oplot, mean_field.red(0,1950:2100)+std_field.red(t,0,1950:2100), col=fix(float(t)*255/nday), min=0.01
;      plots, [0., .05], [1.*t/nday,1.*t/nday], /NORM, col=fix(float(t)*255/nday), thick=4.
;      xyouts, .05, 1.*t/nday, string(t+1, format='(I02)'), /NORM, col=fix(float(t)*255/nday), charsize=1.2, ALIGN=1.;fix(float(t)*255/nday)
;    endfor
;    oplot, mean_field.red(0,1950:2100), line = 0, min=0.01, thick=2.5
;    oplot, std_mean.red(0,1950:2100), min=0.01, col=250, thick=2.5
;    oplot, mean_field.red(0,1950:2100)+ std_mean.red(0,1950:2100), min=0.01, col=250, thick=1.5, max=0.9
;    oplot, mean_field.red(0,1950:2100)- std_mean.red(0,1950:2100), min=0.01, col=250, thick=1.5
;    plotimg=tvrd(true=1)
;    fName=tempDir+'red_'+fNames[cloudtype]+'.png'
;    write_png,fName,plotimg
;    ;; b2 / nir
;    window, 2, title='nir - '+titles[cloudtype]
;    plot, data_in(0).nir(0,1950:2100), yr=[0.,0.6], min=0.01, psym = 3, max=0.9
;    ;for t=0, nday-1 do oplot, data_in(t).fapar(0,1950:2100), col=fix(float(t)*255/nday), psym = 2, min=0.01
;    ;for t=0, nday-1 do oplot, mean_field.fapar(0,1950:2100)+std_field.fapar(t,0,1950:2100), col=fix(float(t)*255/nday), min=0.01
;    for t=0, nday-1 do begin
;      oplot, data_in(t).nir(0,1950:2100), col=fix(float(t)*255/nday), psym = 2, min=0.01
;      oplot, mean_field.nir(0,1950:2100)+std_field.nir(t,0,1950:2100), col=fix(float(t)*255/nday), min=0.01
;      plots, [0., .05], [1.*t/nday,1.*t/nday], /NORM, col=fix(float(t)*255/nday), thick=4.
;      xyouts, .05, 1.*t/nday, string(t, format='(I02)'), /NORM, col=fix(float(t)*255/nday), charsize=1.2, ALIGN=1.;fix(float(t)*255/nday)
;    endfor
;    oplot, mean_field.nir(0,1950:2100), line = 0, min=0.01, thick=2.5
;    oplot, std_mean.nir(0,1950:2100), min=0.01, col=250, thick=2.5
;    oplot, mean_field.nir(0,1950:2100)+ std_mean.nir(0,1950:2100), min=0.01, col=250, thick=1.5, max=0.9
;    oplot, mean_field.nir(0,1950:2100)- std_mean.nir(0,1950:2100), min=0.01, col=250, thick=1.5
;    plotimg=tvrd(true=1)
;    fName=tempDir+'nir_'+fNames[cloudtype]+'.png'
;    write_png,fName,plotimg

  endif

  ;  window, 1, title='red'
  ;  plot, data_in(0).red(0,1950:2100), yr=[0.,0.6], min=0.01, psym = 3
  ;  for t=0, 9 do oplot, data_in(t).red(0,1950:2100), col=t*20, psym = 2, min=0.01
  ;  oplot, mean_field.red(0,1950:2100), line = 0, min=0.01, thick=2.5
  ;  for t=0, 9 do oplot, mean_field.red(0,1950:2100)-std_field.red(t,0,1950:2100), col=t*20, max=0.6
  ;  for t=0, 9 do oplot, mean_field.red(0,1950:2100)+std_field.red(t,0,1950:2100), col=t*20, min=0.01
  ;  oplot, std_mean.red(0,1950:2100), min=0.01, col=250, thick=2.5
  ;  oplot, mean_field.red(0,1950:2100)+ std_mean.red(0,1950:2100), min=0.01, col=250, thick=1.5, max=0.6
  ;  oplot, mean_field.red(0,1950:2100)- std_mean.red(0,1950:2100), min=0.01, col=250, thick=1.5
  ;
  ;  window, 2, title='nir'
  ;  plot, data_in(0).nir(0,1950:2100), yr=[0.,0.6], min=0.01, psym = 3
  ;  for t=0, 9 do oplot, data_in(t).nir(0,1950:2100), col=t*20, psym = 2, min=0.01
  ;  oplot, mean_field.nir(0,1950:2100), line = 0, min=0.01, thick=2.5
  ;  for t=0, 9 do oplot, mean_field.nir(0,1950:2100)-std_field.red(t,0,1950:2100), col=t*20, max=0.6
  ;  for t=0, 9 do oplot, mean_field.nir(0,1950:2100)+std_field.red(t,0,1950:2100), col=t*20, min=0.01
  ;  oplot, std_mean.nir(0,1950:2100), min=0.01, col=250, thick=2.5
  ;  oplot, mean_field.nir(0,1950:2100)+ std_mean.nir(0,1950:2100), min=0.01, col=250, thick=1.5, max=0.6
  ;  oplot, mean_field.nir(0,1950:2100)- std_mean.nir(0,1950:2100), min=0.01, col=250, thick=1.5
  ;  stop
end
;===================================================================================================
PRO sm_FindEuclideanMatricDistance, daysNumber, data_in, idx_third, distance, mean_field, std_mean, nfield, splitDims, faparMean, cloudtype=cloudtype
  ;
  ;
  ;
  ; inputs:
  ; data_in : daily data
  ; position of of valid points > 3
  ; nfield: 3 if vegetation - 2 if bare soil
  ;
  ; option: add weight with uncertainties
  ;
  ; outputs:
  ; distance : normalized euclidean distance
  ; mean_field: average over the valid dates
  ; std_mean: mean standard deviation over the valid dates
  ;
  ;
  ;
  tt=[0, daysNumber]
  okpix=N_elements(idx_third)
  ; compute the mean and std of the fapar and red/nir channels
  ;
  ;
  sm_call_mean_3, daysNumber, data_in, mean_field, std_mean, std_field, nfield, splitDims, faparMean, cloudtype=cloudtype
  ;
  ; compute the distance
  ;  help, mean_field
  ;  help, std_mean
  ;  help, std_field
  distance=fltarr(tt(1),splitDims[0],splitDims[1], /NO)
  ;
  ;help, distance
  ;stop
  distance[*]=100.0
  buf=fltarr(splitDims[0],splitDims[1])
  ; MM 22/9/2016
  buf1=std_mean.red[*,*]
  buf2=std_mean.nir[*,*]
  if nfield eq 3 then begin
    buf3=std_mean.temp[*,*]
  endif
  ;
  if nfield eq 3 then begin

    for t=0, tt(1)-1 do begin
      buf4=reform(std_field.red(t,*,*))
      buf5=reform(std_field.nir(t,*,*))
      buf6=reform(std_field.fapar(t,*,*))
      buf(*)=100.0
      ;
      ; first case none nul
      ;
      idx_ca=where(buf1 gt 0.0 and buf2 gt 0.0 and buf3 gt 0.0 and $
        buf4 gt 0.0 and  buf5 gt 0.0 and  buf6 gt 0.0, foundElements)
      ;
      ; original computation of distance
      if foundElements gt 0 then begin
        buf(idx_ca)= sqrt( $
          buf4(idx_ca)^2/buf1(idx_ca)^2 +$
          buf5(idx_ca)^2/buf2(idx_ca)^2 +$
          buf6(idx_ca)^2/buf3(idx_ca)^2 )
      endif
      idx_ca1=where(buf1 eq 0.0 and buf4  ge 0.0, count1)
      idx_ca2=where(buf2 eq 0.0 and buf5  ge 0.0, count2)
      idx_ca3=where(buf3 eq 0.0 and buf6  ge 0.0, count3)
      ;
      print, '# std = 0:', count1, count2, count3 ; ng 2016
      if count1 gt 0 then begin      ; ng 2016
        buf(idx_ca1)= sqrt($
          buf5(idx_ca1)^2/buf2(idx_ca1)^2 +$
          buf6(idx_ca1)^2/buf3(idx_ca1)^2 )
      endif
      if count2 gt 0 then begin      ; ng 2016
        buf(idx_ca2)= sqrt($
          buf4(idx_ca2)^2/buf1(idx_ca2)^2 +$
          buf6(idx_ca2)^2/buf3(idx_ca2)^2 )
      endif
      if count3 gt 0 then begin      ; ng 2016
        buf(idx_ca3)= sqrt($
          buf4(idx_ca3)^2/buf1(idx_ca3)^2 +$
          buf5(idx_ca3)^2/buf2(idx_ca3)^2 )
      endif
      distance[t,*,*]=buf
    endfor
  endif else begin
    for t=0, tt(1)-1 do begin
      buf4=reform(std_field.red(t,*,*))
      buf5=reform(std_field.nir(t,*,*))
      buf(*)=100.0
      ;
      ; first case none nul
      ;
      idx_ca=where(buf1 gt 0.0 and buf2 gt 0.0 and $
        buf4 gt 0.0 and  buf5 gt 0.0, validDataCount)
      ;   stop
      if validDataCount gt 0 then begin
        buf(idx_ca)= sqrt( $
          buf4(idx_ca)^2/buf1(idx_ca)^2 +$
          buf5(idx_ca)^2/buf2(idx_ca)^2)
      endif
      idx_ca1=where(buf1 eq 0.0 and buf4 ge 0.0, count1)
      idx_ca2=where(buf2 eq 0.0 and buf5 ge 0.0, count2)
      print, '# std = 0 for soil pixels ', count1, count2; ng 2016
      if count1 gt 0 then begin      ; ng 2016
        buf(idx_ca1)= sqrt($
          buf5(idx_ca1)^2/buf2(idx_ca1)^2 )
      endif
      if count2 gt 0 then begin      ; ng 2016
        buf(idx_ca2)= sqrt($
          buf4(idx_ca2)^2/buf1(idx_ca2)^2)
      endif
      ; second case if one is equal to zero ... i.e no change during the period
      distance[t,*,*]=buf
    endfor
    ;stop
  endelse
  ; stop
END
