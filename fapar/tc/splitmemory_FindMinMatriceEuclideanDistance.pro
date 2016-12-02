Pro sm_call_mean_3,  daysNumber, data_in, mean_field, std_mean, std_field, nfield, flagNan, splitDims
  ;
  if n_elements(splitDims) ne 2 then splitDims=[7200,3600]
  mean_field={red:fltarr(splitDims[0],splitDims[1]), nir:fltarr(splitDims[0],splitDims[1]), fapar:fltarr(splitDims[0],splitDims[1])}
  ;mean_field=fltarr(nfield,splitDims[0],splitDims[1])
  ;
  buf1=fltarr(splitDims[0],splitDims[1])
  buf2=fltarr(splitDims[0],splitDims[1])
  ;

  if nfield eq 3 then buf3=fltarr(splitDims[0],splitDims[1])
  ;
  ;tt=size(data_in.day)
  tt=[0,daysNumber]
  ;
  num_used=bytarr(splitDims[0],splitDims[1])
  one=num_used
  one(*,*)=1
  ;
  ;
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
      idx_c = where(validMaskVeg eq 1 and data_in(t).flag(*,*) eq 0.0, countVeg)

      ; previous (without NaN)
;      idx_cOld= where((data_in(t).red gt 0. and data_in(t).red lt 1.) and $
;        (data_in(t).nir gt 0. and data_in(t).nir lt 1.) and $
;        (data_in(t).fapar gt 0. and data_in(t).fapar le 1.) and $
;        (data_in(t).flag eq 0.), countVegOld)
;      if countVegOld ne countVeg then stop

      if idx_c(0) ge 0 then begin
        buf1(idx_c)= data_in(t).red(idx_c)+buf1(idx_c)
        buf2(idx_c)= data_in(t).nir(idx_c)+buf2(idx_c)
        buf3(idx_c)= data_in(t).fapar(idx_c)+buf3(idx_c)
        num_used(idx_c)=num_used(idx_c)+one(idx_c)
      endif
    endfor
    ;print, data_in(*).fapar[280,2580]
  endif else begin
    for t=0, tt(1)-1 do begin
      ;;;;
      validMask=finite(data_in(t).fapar(*,*)) and finite(data_in(t).red(*,*)) and finite(data_in(t).nir(*,*))
      goodIndexes=where(validMask eq 1)

      idxMaskSoil=where(data_in(t).fapar[goodIndexes] eq 0 and $
        data_in(t).red[goodIndexes] gt 0.0 and data_in(t).red[goodIndexes] lt 1.0 and $
        data_in(t).nir[goodIndexes] gt 0.0 and data_in(t).nir[goodIndexes] lt 1.0)
      validMaskSoil=validMask*0
      validMaskSoil[goodIndexes[idxMaskSoil]]=1
      validMaskSoil=validMask*validMaskSoil
      idx_c= where(validMaskSoil eq 1 and (data_in(t).flag eq 4. or data_in(t).flag eq 5.), countSoil)
      ;;;;
;      idx_cOld= where((data_in(t).red gt 0. and data_in(t).red lt 1.) and $
;        (data_in(t).nir gt 0. and data_in(t).nir lt 1.) and $
;        (data_in(t).fapar eq 0.) and $
;        (data_in(t).flag eq 4. or data_in(t).flag eq 5.), countSoilOld)
;      if countSoilOld ne countSoil then stop
      ;      a=where((data_in(t).red gt 0. and data_in(t).red lt 1.), redc)
      ;      b=where((data_in(t).nir gt 0. and data_in(t).nir lt 1.), nirc)
      ;      c=where(data_in(t).fapar eq 0., faparc)
      ;      d=where(data_in(t).flag eq 4. or data_in(t).flag eq 5., flagc)
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
  ;
  if nfield eq 3 then begin
    idx_ok=where(num_used ge 3 and buf1 gt 0.0 and buf2 gt 0. and buf3 gt 0.)   ; ng 2016
    if idx_ok(0) ge 0 then begin
      buf1(idx_ok)=buf1(idx_ok)/float(num_used(idx_ok))
      buf2(idx_ok)=buf2(idx_ok)/float(num_used(idx_ok))
      buf3(idx_ok)=buf3(idx_ok)/float(num_used(idx_ok))
      ;print, buf3[280,2580]
    endif
    idx_nok=where(num_used le 2.0 or buf1 le 0.0 or buf2 le 0.0 or buf3 le 0.0)   ; ng 2016
    if idx_nok(0) ge 0 then begin
      buf1(idx_nok)=-1.0
      buf2(idx_nok)=-1.0
      buf3(idx_nok)=-1.0
    endif
  endif else begin
    idx_ok=where(num_used ge 3 and buf1 gt 0.0 and buf2 gt 0.)  ;ng 2016
    ; bare soil here
    if idx_ok(0) ge 0 then begin
      buf1(idx_ok)=buf1(idx_ok)/float(num_used(idx_ok))
      buf2(idx_ok)=buf2(idx_ok)/float(num_used(idx_ok))
    endif
    idx_nok=where(num_used le 2.0 or buf1 lt 0.0 or buf2 lt 0.0)  ; ng 2016
    ; no data here
    if idx_nok(0) ge 0 then begin
      buf1(idx_nok)=-1.0
      buf2(idx_nok)=-1.0
    endif
  endelse
  ;
  ;
  ;
  ;mean_field(0,*,*)=buf1(*,*)
  ;mean_field(1,*,*)=buf2(*,*)
  ;if nfield eq 3 then mean_field(2,*,*)=buf3(*,*)
  mean_field(*,*).red=buf1(*,*)
  mean_field(*,*).nir=buf2(*,*)
  if nfield eq 3 then mean_field.fapar=buf3(*,*)
  ;
  ;stop
  ;
  ;window, 0, xsize=splitDims(0), ysize=splitDims(1)/3.
  ;tvscl, congrid(buf1(*,*), splitDims(0), splitDims(1)/3.)
  ;stop
  ; compute the standard deviation for each field, i.e red nir and fapar ...
  ;
  ;std_field=fltarr(nfield,tt(1),splitDims[0],splitDims[1])
  initValues=fltarr(tt(1),splitDims[0],splitDims[1])
  initValues[*]=-1
  std_field={red:initValues, nir:initValues, fapar:initValues}
  ;std_field(*,*,*,*)=-1.0
  ;
  ;
  if nfield eq 3 then begin
    for t=0, tt(1)-1 do begin
      buf1=fltarr(splitDims[0],splitDims[1])
      buf2=fltarr(splitDims[0],splitDims[1])
      buf3=fltarr(splitDims[0],splitDims[1])
      buf1(*,*)=-1.0
      buf2(*,*)=-1.0
      buf3(*,*)=-1.0
      buf=fltarr(splitDims[0],splitDims[1])
      buff=fltarr(splitDims[0],splitDims[1])
      ;
      ;print, 'size(buf(*,*))', 'data_in(t).red(*,*)', 'buff(*,*)', 'mean_field(0,*,*)'
      ;print, size(buf(*,*)), size(data_in(t).red(*,*)), size(buff(*,*)), size(mean_field(0,*,*))
      buf(*,*)=data_in(t).red(*,*)
      ;buff(*,*)=mean_field(0,*,*)
      buff(*,*)=mean_field(*,*).red

      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and data_in(t).flag eq 0. and num_used ge 3.0, countBuf) ;ng 2016
      ; previous version without NaN
      ;idx=where((buf gt 0. and buf lt 1.0) and (buff gt 0. and buff lt 1.) and data_in(t).flag eq 0. and num_used ge 3.0, countBuf) ;ng 2016
      if idx(0) ge 0 then buf1(idx) = abs(buf(idx)-buff(idx))
      ;
      buf=data_in(t).nir
      ;buff(*,*)=mean_field(1,*,*)
      buff(*,*)=mean_field(*,*).nir

      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and data_in(t).flag eq 0. and num_used ge 3.0, countBuf) ;ng 2016
      ; previous version without NaN
      ;idx=where((buf gt 0. and buf lt 1.0) and (buff gt 0. and buff lt 1.) and (data_in(t).flag eq 0.) and num_used ge 3.0, countBuf) ;ng 2016 )
      if idx(0) ge 0 then buf2(idx)= abs(buf(idx)-buff(idx))
      ;
      buf=data_in(t).fapar
      ;buff(*,*)=mean_field(2,*,*)
      buff(*,*)=mean_field(*,*).fapar
      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and data_in(t).flag eq 0. and num_used ge 3.0, countBuf) ;ng 2016
      ;idx=where((buf gt 0. and buf le 1.0) and (buff gt 0. and buff le 1.) and (data_in(t).flag eq 0.) and num_used ge 3.0, countBuf) ;ng 2016
      if idx(0) ge 0 then buf3(idx)  = abs(buf(idx)-buff(idx))
      ;
      ;      std_field(0,t,*,*)=buf1
      ;      std_field(1,t,*,*)=buf2
      ;      std_field(2,t,*,*)=buf3
      std_field.red(t,*,*)=buf1
      std_field.nir(t,*,*)=buf2
      std_field.fapar(t,*,*)=buf3
    endfor
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
      ;buff(*,*)=mean_field(0,*,*)
      buff(*,*)=mean_field(*,*).red

      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and (data_in(t).flag eq 4. or data_in(t).flag eq 5.) and num_used ge 3.0, countBuf) ;ng 2016
      ;;;;
      ;idxOld=where((buf gt 0. and buf lt 1.0) and (buff gt 0. and buff lt 1.) and (data_in(t).flag eq 4. or data_in(t).flag eq 5.) and num_used ge 3.0, countBufOld) ; ng 2016
      ;if countBufOld ne countBuf then stop
      if idx(0) ge 0 then buf1(idx) = abs(buf(idx)-buff(idx))
      ;
      buf=data_in(t).nir
      buff(*,*)=mean_field(*,*).nir

      ;;;
      validMask=finite(buf) and finite(buff)
      goodIndexes=where(validMask eq 1)

      idxMaskVeg=where(buf[goodIndexes] gt 0.0 and buf[goodIndexes] lt 1.0 and $
        buff[goodIndexes] gt 0.0 and buff[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      validMaskVeg=validMask*validMaskVeg

      idx=where(validMaskVeg eq 1 and (data_in(t).flag eq 4. or data_in(t).flag eq 5.) and num_used ge 3.0, countBuf) ;ng 2016
      ;idxOld=where((buf gt 0. and buf lt 1.0) and (buff gt 0. and buff lt 1.) and (data_in(t).flag eq 4. or data_in(t).flag eq 5.) and num_used ge 3.0, countBufOld) ; ng 2016
      ;if countBufOld-countBuf gt 1 then stop
      if idx(0) ge 0 then buf2(idx)= abs(buf(idx)-buff(idx))
      ;
      ;std_field(0,t,*,*)=buf1
      ;std_field(1,t,*,*)=buf2
      std_field.red(t,*,*)=buf1
      std_field.nir(t,*,*)=buf2
      ;  stop
    endfor
  endelse
  ;where()
  ;
  ;
  ; compute the mean of the standard deviation ...
  ;
  ; now split...
  ;std_mean=fltarr(nfield,splitDims[0],splitDims[1])
  std_mean={red:fltarr(splitDims[0],splitDims[1]), nir:fltarr(splitDims[0],splitDims[1]), temp:fltarr(splitDims[0],splitDims[1])}
  ;
  num_used_1=bytarr(splitDims[0],splitDims[1])
  num_used_2=bytarr(splitDims[0],splitDims[1])
  if nfield eq 3 then num_used_3=bytarr(splitDims[0],splitDims[1])
  ;
  buf=fltarr(splitDims[0],splitDims[1])
  ;
  buf1=fltarr(splitDims[0],splitDims[1])
  buf2=fltarr(splitDims[0],splitDims[1])
  if nfield eq 3 then buf3=fltarr(splitDims[0],splitDims[1])
  ;
  for t=0, tt(1)-1 do begin
    buf(*,*)=std_field.red(t,*,*)
    idx_ca=where(buf ge 0.)
    if idx_ca(0) ge 0 then begin
      buf1(idx_ca)=(buf(idx_ca)^2)+buf1(idx_ca)
      num_used_1(idx_ca)  = num_used_1(idx_ca)+one(idx_ca)
    endif
    buf(*,*)=std_field.nir(t,*,*)
    idx_ca=where(buf ge 0.)
    if idx_ca(0) ge 0 then begin
      buf2(idx_ca)=(buf(idx_ca)^2)+buf2(idx_ca)
      num_used_2(idx_ca)  = num_used_2(idx_ca)+one(idx_ca)
    endif
    if nfield eq 3 then begin
      buf(*,*)=std_field.fapar(t,*,*)
      idx_ca=where(buf ge 0.)
      if idx_ca(0) ge 0 then begin
        buf3(idx_ca)=(buf(idx_ca)^2)+buf3(idx_ca)
        num_used_3(idx_ca)  = num_used_3(idx_ca)+one(idx_ca)
      endif
    endif
  endfor
  ;
  ;
  ;
  idx_ok=where(num_used_1 ge 3.0) ; ng 2016
  if idx_ok(0) ge 0 then buf1(idx_ok)=sqrt(buf1(idx_ok)/float(num_used_1(idx_ok)-1))
  idx_ok=where(num_used_2 ge 3.0) ; ng 2016
  if idx_ok(0) ge 0 then buf2(idx_ok)=sqrt(buf2(idx_ok)/float(num_used_2(idx_ok)-1))
  if nfield eq 3 then begin
    idx_ok=where(num_used_3 ge 3.0) ; ng 2016
    if idx_ok(0) ge 0 then buf3(idx_ok)=sqrt(buf3(idx_ok)/float(num_used_3(idx_ok)-1))
  endif
  ;
  ;erase
  ;window,0
  ;plot, num_used_1 , num_used_2, psym =2
  ;stop
  idx_nok=where(num_used le 2.0)  ; ng 2016
  if idx_nok(0) ge 0 then begin
    buf1(idx_nok)=-1.0
    buf2(idx_nok)=-1.0
    if nfield eq 3 then buf3(idx_nok)=-1.0
  endif
  ;
  std_mean.red[*,*]=buf1[*,*]
  std_mean.nir[*,*]=buf2[*,*]
  if nfield eq 3 then begin
    std_mean.temp[*,*]=buf3[*,*]
    checkZeroes=where(std_mean.temp[*,*] eq 0, countZeroes)
    print,'Find # points with Standard Deviation Mean FAPAR = 0 ', countZeroes

  endif
  ;
  ;stop
  ;std_mean(0,*,*)=buf1(*,*)
  ;std_mean(1,*,*)=buf2(*,*)
  ;if nfield eq 3 then std_mean(2,*,*)=buf3(*,*)
  ;plot, mean_field(*,*).red, mean_field(*,*).nir, psym=1
  ;oplot, mean_field(*,*).nir, psym=4
  ;oplot, mean_field(*,*).fapar, psym=6
  ; stop
end
;===================================================================================================
;


PRO sm_FindEuclideanMatricDistance, daysNumber, data_in, idx_third, distance, mean_field, std_mean, nfield, flagNan, splitDims
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
  ;tt=size(data_in.day)
  tt=[0, daysNumber]
  ; reduct memory version
  okpix=N_elements(idx_third)
  ; full memory version
  ;
  ; compute the mean and std of the fapar and red/nir channels
  ;
  ;
  sm_call_mean_3, daysNumber, data_in, mean_field, std_mean, std_field, nfield, flagNan, splitDims
  ;
  ; compute the distance
  ;
  ;distance=fltarr(tt(1),okpix)
  distance=fltarr(tt(1),splitDims[0],splitDims[1], /NO)
  ;
  ;help, distance
  ;stop
  distance[*]=100.0
  ;
  ;buf=fltarr(okpix)
  buf=fltarr(splitDims[0],splitDims[1])
  ;
  ;buf1=fltarr(okpix)
  ;buf2=fltarr(okpix)
  ;if nfield eq 3 then buf3=fltarr(okpix)
  ;
  ;buf4=fltarr(okpix)
  ;buf5=fltarr(okpix)
  ;if nfield eq 3 then buf6=fltarr(okpix)
  ;
  ;img=fltarr(splitDims[0],splitDims[1])
  ; MM 22/9/2016
  ;img(*,*)=std_mean(0,*,*)
  ;img(*,*)=std_mean.red[*,*]
  ;buf1=img(idx_third)
  buf1=std_mean.red[*,*]
  ;img(*,*)=std_mean(1,*,*)
  ;img(*,*)=std_mean.nir[*,*]
  ;buf2=img(idx_third)
  buf2=std_mean.nir[*,*]
  if nfield eq 3 then begin
    ;img(*,*)=std_mean.temp[*,*]
    ;img(*,*)=std_mean(2,*,*)
    ;buf3=img(idx_third)
    buf3=std_mean.temp[*,*]
  endif
  ;
  if nfield eq 3 then begin

    for t=0, tt(1)-1 do begin
      ;img=fltarr(splitDims[0],splitDims[1])
      ;img=std_field(0,t,*,*)
      ;buf4(*)=img(idx_third)
      buf4=reform(std_field.red(t,*,*))
      ;img=std_field(1,t,*,*)
      ;buf5(*)=img(idx_third)
      buf5=reform(std_field.nir(t,*,*))
      ;img=std_field(2,t,*,*)
      ;buf6(*)=img(idx_third)
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

      ; simplified computation of distance
      ;      if foundElements gt 0 then begin
      ;        buf(idx_ca)= abs(buf6(idx_ca)-buf3(idx_ca))
      ;      endif
      ;
      ;
      ; second case if one is equal to zero ... i.e no change during the period
      ;
      ;      idx_ca1=where(buf1 eq 0.0 and buf4  ge 0.0, count1)
      ;      idx_ca2=where(buf2 eq 0.0 and buf5  ge 0.0, count2)
      ;      idx_ca3=where(buf3 eq 0.0 and buf6  ge 0.0, count3)
      ;b1=buf[idx_third] & b2=buf2[idx_third] & b3=buf3[idx_third] & b4=buf4[idx_third] & b5=buf5[idx_third] & b6=buf6[idx_third]
      ;stop
      ; if count1 gt 0 then begin
      ;   buf(idx_third(idx_ca1))= sqrt( $
      ;     buf5(idx_third(idx_ca1))^2/buf2(idx_third(idx_ca1))^2 +$
      ;    buf6(idx_third(idx_ca1))^2/buf3(idx_third(idx_ca1))^2 )
      ; endif

      ;  if count3 gt 0 then begin
      ; set a very low stddev
      ;   buf[idx_third[idx_ca3]]=0.0001
      ;  print, '**'
      ; for kkk=0, count3-1 do begin
      ;  for jjj=0, tt(1)-1 do begin
      ;   print, data_in[jjj].fapar[idx_third[idx_ca3[kkk]]]
      ; endfor
      ;endfor
      ;print, '**'
      ;endif
      ;if count1 gt 0 or count2 gt 0 then stop
      ;        buf[idx_third[idx_ca3]]=0.0001 ; set an epsilon only where necessary
      ;        print, data_in[jjj].fapar[idx_third[idx_ca3]]
      ;        print, mean_field.fapar[idx_third[idx_ca3]]
      ;        temp=std_field[2,t,*,*]
      ;        print, temp[idx_third[idx_ca3]]
      ;        print, data_in
      ;        print, mean_field.fapar[idx_third[idx_ca3[0]]]
      ;        for jjj=0, 9 do print, data_in[jjj].fapar[idx_third[idx_ca3]]
      ;        distance(t,*,*)=0
      ;        print, [idx_third[idx_ca3]]
      ;      endif
      ;
      ;
      ;
      ;
      ;distance(t,*)=buf(*)
      distance[t,*,*]=buf
    endfor
  endif else begin
    for t=0, tt(1)-1 do begin
      img=fltarr(splitDims[0],splitDims[1])
      buf4=reform(std_field.red(t,*,*))
      buf5=reform(std_field.nir(t,*,*))
      buf(*)=100.0
      ;
      ; first case none nul
      ;
      ;b1=buf[idx_third] & b2=buf2[idx_third] & b3=buf3[idx_third] & b4=buf4[idx_third] & b5=buf5[idx_third] & b6=buf6[idx_third]

      idx_ca=where(buf1 gt 0.0 and buf2 gt 0.0 and $
        buf4 gt 0.0 and  buf5 gt 0.0, validDataCount)
      ;   stop
      ;
      ;
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
      ;
      ;
      ; second case if one is equal to zero ... i.e no change during the period
      ;
      ;b1=buf[idx_third] & b2=buf2[idx_third] & b4=buf4[idx_third] & b5=buf5[idx_third]


      ; on short period sometimes happen: check here...
      ;     if count1 gt 0 then begin
      ; set a very low stddev
      ;      buf1[idx_third[idx_ca1]]=0.0001
      ;     print, '**'
      ;    for kkk=0, count1-1 do begin
      ;     for jjj=0, tt(1)-1 do begin
      ;      print, data_in[jjj].red[idx_third[idx_ca1[kkk]]]
      ;    endfor
      ;  endfor
      ;  print, '**'
      ;endif
      ;     if count2 gt 0 then begin
      ;      ; set a very low stddev
      ;     buf2[idx_third[idx_ca2]]=0.0001
      ;    print, '**'
      ;   for kkk=0, count2-1 do begin
      ;    for jjj=0, tt(1)-1 do begin
      ;     print, data_in[jjj].nir[idx_third[idx_ca2[kkk]]]
      ;  endfor
      ;endfor
      ;print, '**'
      ;endif
      ;
      ;
      ;
      ;
      ;distance(t,*)=buf(*)
      distance[t,*,*]=buf
    endfor
    ;stop
  endelse

  ; stop
  ;
END
