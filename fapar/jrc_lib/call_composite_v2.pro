; =======================================================================
;
Pro make_tc_distance_eu_vegetation_m, idx_doIt, day, meandat, std_mean, nfield, index_2

  COMMON bigData
  ;
  ;
  ; data_in : daily data (at least 3 days contain valid value)
  ; index : number of observation
  ; idx_doIt : position where index ge 3
  ;
  ;
  ; nfield : 3 over vegetation pixels
  ; nfield : 2 over bare soil
  ;
  ; output:
  ;	day : the day to be used in the time composite
  ;	index_2 : number of observation after outliers
  ;
  ;	meandat : temporal deviation over the period (only valid pixels after outliers)
  ;
  ; compute the distance
  ;
  ;
  print, 'call: FindEuclideanMatricDistance'
  FindEuclideanMatricDistance, idx_doIt, distance, meandat, std_mean, nfield
  print, 'done: FindEuclideanMatricDistance'
  ;
  ;
  ;window,11, xsize=720*2, ysize=360*2, title='Mean fapar after'
  ;faparcolor
  ;img=bytarr(7200,3600)
  ;img(*,*)=meandat(2,*,*)*250.0
  ;tvscl, reverse(congrid(img,720*2,360*2),2)
  ;
  ;
  ; remove outliers ; check the numbers
  ;
  if nfield eq 3 then thres = 7.915
  if nfield eq 2 then thres = 5.991
  ;
  ;=================================================================
  ;
  ; re-compute number of days
  ;
  ;========================================================================
  index_2=bytarr(7200,3600)
  buf=fltarr(7200,3600)
  index_2(*,*)=0.
  one=index_2
  one(*,*)=1.
  ;tt=size(expectedDays)
  for t=0, expectedDays-1 do begin
    print, t, '/', expectedDays
    buf(*,*)=-1.0
    buf(idx_doIt)=distance(t,*)
    idx_mask = where(buf lt thres and buf ge 0.0)
    if idx_mask(0) ge 0 then index_2(idx_doIt(idx_mask))=index_2(idx_doIt(idx_mask))+one(idx_doIt(idx_mask))
    idx_bad_mask = where(buf gt thres and buf ge 0.0)
    if idx_bad_mask(0) ge 0 then data_day(t).flag(idx_doIt(idx_bad_mask))=11.0
  endfor
  ;

  if nfield eq 3 then idx_remake=where(data_day.flag eq 0.0 and index_2 ge 3)
  if nfield eq 2 then idx_remake=where(data_day.flag eq 4.0 and index_2 ge 3)
  ;
  if idx_remake(0) ge 0 then begin
    print, 'Remake after Outliers out'
    FindEuclideanMatricDistance, idx_remake, distance_2, meandat2, std_mean2, nfield

    distance(*,idx_remake)=distance_2
    meandat(*,idx_remake)=meandat2(*,idx_remake)
    std_mean(*,idx_remake)=std_mean2(*,idx_remake)
  endif
  ;
  ;
  ;window,12, xsize=720*2, ysize=360*2, title='mean fapar after outliers out'
  ;faparcolor
  img=bytarr(7200,3600)
  if nfield eq 3 then img(*,*)=meandat(2,*,*)*250.0
  if nfield eq 2 then img(*,*)=meandat(0,*,*)*250.0
  tvscl, reverse(congrid(img,720*2,360*2),2)
  ;
  ; look for day of minimum distance
  ;
  day=bytarr(7200,3600)
  day(*,*)=255
  min_val=fltarr(7200,3600)
  buf=fltarr(7200,3600)
  ;
  ; take the first as minimum value
  ;
  min_val(*,*)=10000.0
  ;
  ;
  for t=0, expectedDays-1 do begin
    buf(*,*) = 11000.0
    buf(idx_doIt)=distance(t,*)
    idx_mask = where(buf(*,*) lt min_val(*,*))
    if idx_mask(0) ge 0 then begin
      min_val(idx_mask)=buf(idx_mask)
      day(idx_mask)=t
    endif
  endfor
  ;
  ;stop
  print,'find minimum distance day ...'
  ;
END
;
;
PRO call_composite, data_tc
  ;
  ;
  ;
  ; data_day = products for each day and each pixels
  ;
  ; data_tc = time-composite results
  ;
  COMMON bigData

  print, 'In the time composite program ...'
  ;

  data_tc= {Composite, day: bytarr(7200,3600), $
    nday: bytarr(7200,3600), $
    fapar: fltarr(7200,3600), $
    dev_temp: fltarr(7200,3600), $
    sigma: fltarr(7200,3600), $
    red: fltarr(7200,3600), $
    dev_red_temp: fltarr(7200,3600), $
    sigma_red:fltarr(7200,3600), $
    nir: fltarr(7200,3600), $
    dev_nir_temp: fltarr(7200,3600), $
    sigma_nir: fltarr(7200,3600), $
    flag: bytarr(7200,3600), $
    toc_red: fltarr(7200,3600), $
    toc_nir: fltarr(7200,3600), $
    qa: bytarr(7200,3600)}
  ;
  ; initiate flag to sea mask
  ;
  data_tc.flag(*,*)=6
  ;
  ;==========================================================================================
  ;
  ;	look for vegetated pixels
  ;
  ; count the number of dates where we have valid pixels over vegetation land
  ;
  ;
  index=bytarr(7200,3600)
  index(*,*)=0
  one=index
  one(*,*)=1
  ;ddata_day=replicate(exStruct, expectedDays)
  ;  ndata_day=*data_day[0]
  ;  for j=1, n_elements(data_day)-1 do begin
  ;    dd=*data_day[j]
  ;    ndata_day=[ndata_day, dd]
  ;    delIdlVar, dd
  ;    ptr_free, data_day[j]
  ;    delIdlVar, data_day[j]
  ;  endfor
  for t=0, expectedDays-1 do begin
    maxF=max(data_day[t].fapar(*,*), min=minF)
    ;aa=where(data_day[t].fapar(*,*) gt 0.0 and data_day[t].fapar(*,*) lt 1.1, count1)
    ;aa=where(data_day[t].red(*,*) gt 0.0 and data_day[t].red(*,*) lt 1.0, count2)
    ;aa=where(data_day[t].nir(*,*) gt 0.0 and data_day[t].nir(*,*) lt 1.0, count3)
    ;print, count1, count2, count3
    ;print, minF, maxF
    print, t, '/', expectedDays
    idx_mask = where(data_day[t].flag(*,*) eq 0.0 and data_day[t].fapar(*,*) gt 0.0 and $
      data_day[t].red(*,*) gt 0.0 and data_day[t].red(*,*) lt 1.0 and $
      data_day[t].nir(*,*) gt 0.0 and data_day[t].nir(*,*) lt 1.0)
    if idx_mask[0] ge 0 then index[idx_mask]=index[idx_mask]+one[idx_mask]
  endfor
  ;==========================================================================================
  ;loadct,12
  ;window,0, xsize=720, ysize=360, title='Number of day over vegetation'
  ;tvscl, reverse(congrid(index,720,360),2)
  ;
  ;
  ; More than two dates
  ;
  ; associated values for the number of date is bigger or equal to 3
  ;
  idx_third = where(index ge 3)
  ;
  dims = SIZE(index, /DIMENSIONS)
  ind = ARRAY_INDICES(dims, idx_third, /DIMENSIONS)
  ;
  ;
  print, 'call: make_tc_distance_eu_vegetation_m'
  make_tc_distance_eu_vegetation_m, idx_third, resDay, meandat, std_mean, 3, index_2
  print, 'done: make_tc_distance_eu_vegetation_m'
  ;
  ;stop
  ;
  ;
  ; to check if follow is ok
  ;
  ;for t=0, tt(1)-1 do data_day(t).fapar=meandat(2,*,*)
  ;
  for t =0 , expectedDays-1 do begin
    print, t, '/', expectedDays

    idx_t=where(resDay eq float(t) and index ge 3)

    if idx_t(0) ge 0 then begin
      data_tc.red(idx_t)= data_day(t).red(idx_t)
      data_tc.nir(idx_t)= data_day(t).nir(idx_t)
      data_tc.fapar(idx_t)= data_day(t).fapar(idx_t)
      ;
      data_tc.sigma_red(idx_t)= data_day(t).sigma_red(idx_t)
      data_tc.sigma_nir(idx_t)= data_day(t).sigma_nir(idx_t)
      data_tc.sigma(idx_t)= data_day(t).sigma(idx_t)
      ;
      data_tc.flag(idx_t)= data_day(t).flag(idx_t)
      data_tc.day(idx_t) = resDay(idx_t)
      ;
      ;	data_tc.dev_red_temp(idx_t)= std_mean(0,idx_t)
      ;	data_tc.dev_nir_temp(idx_t)= std_mean(1,idx_t)
      ;	data_tc.dev_temp(idx_t)= std_mean(2,idx_t)
    endif
    ;
  endfor
  ;
  idx_third=where(index ge 3)
  data_tc.nday(idx_third)=index(idx_third)
  ;

  ;window,1, xsize=720, ysize=360, title='FAPAR after more than 3 days'
  ;faparcolor
  ;tv, reverse(congrid(data_tc.fapar*250.0, 720, 360),2)
  ;
  ;stop
  ;window,2, xsize=720, ysize=360, title='FLAG after more than 3 days'
  ;loadct,12
  ;tvscl, reverse(congrid(data_tc.flag, 720, 360),2)

  ;window,22, xsize=720, ysize=360, title='THE Day'
  ;tvscl, reverse(congrid(data_tc.day, 720, 360),2)
  ;stop
  ;==========================================================================================
  ; If only One date
  ;
  ; associated values for the only dates
  ;
  ;
  ;
  idx_one=where(index eq 1 or index_2 eq 1)
  ;
  for t=0, expectedDays-1 do begin
    print, t, '/', expectedDays
    idx_time = where(data_day(t).flag eq 0.0 and data_day(t).fapar gt 0.0 and index eq 1 or index_2 eq 1)
    ;
    if idx_time(0) ge 0 then begin
      data_tc.red(idx_time)=data_day(t).red(idx_time)
      data_tc.nir(idx_time)=data_day(t).nir(idx_time)
      data_tc.fapar(idx_time)=data_day(t).fapar(idx_time)
      data_tc.day(idx_time)=t
      data_tc.sigma_red(idx_time)= data_day(t).sigma_red(idx_time)
      data_tc.sigma_nir(idx_time)= data_day(t).sigma_nir(idx_time)
      data_tc.sigma(idx_time)= data_day(t).sigma(idx_time)
    endif
  endfor
  data_tc.nday(idx_one)=1
  data_tc.flag(idx_one)=0
  data_tc.dev_red_temp(idx_one)=0.
  data_tc.dev_nir_temp(idx_one)=0.
  data_tc.dev_temp(idx_one)=0.
  ;
  ;faparcolor
  ;window,3, xsize=720, ysize=360, title='FAPAR after more than 3 days and 1 date'
  ;tv, reverse(congrid(data_tc.fapar*250.0, 720, 360),2)
  ;loadct,12
  ;window,23, xsize=720, ysize=360, title='THE Day 1'
  ;tvscl, reverse(congrid(data_tc.day, 720, 360),2)
  ;stop
  ;==========================================================================================
  ;
  ; If only two dates
  ;
  ; associated values for the only dates
  ;
  idx_two = where(index eq 2 or index_2 eq 2)
  ;
  fapar_two=fltarr(7200,3600)
  ;
  for t=0, expectedDays-1 do begin
    print, t, '/', expectedDays
    buf=data_day(t).flag
    buf1=data_day(t).fapar
    idx_time = where(buf eq 0.0 and buf1 gt 0.0 and index eq 2 or index_2 eq 2)
    if idx_time(0) ge 0 then begin
      idx_lp= where(buf1(idx_time) gt fapar_two(idx_time))
      if idx_lp(0) ge 0 then begin
        fapar_two(idx_time(idx_lp))=buf1(idx_time(idx_lp))
        data_tc.fapar(idx_time(idx_lp)) = fapar_two(idx_time(idx_lp))
        data_tc.red(idx_time(idx_lp))=data_day(t).red(idx_time(idx_lp))
        data_tc.nir(idx_time(idx_lp))=data_day(t).nir(idx_time(idx_lp))
        data_tc.sigma_red(idx_time(idx_lp))= data_day(t).sigma_red(idx_time(idx_lp))
        data_tc.sigma_nir(idx_time(idx_lp))= data_day(t).sigma_nir(idx_time(idx_lp))
        data_tc.sigma(idx_time(idx_lp))= data_day(t).sigma(idx_time(idx_lp))
        data_tc.day(idx_time(idx_lp))=t
      endif
    endif
  endfor
  ;
  ; compute the deviation ???? ---> do it after the third call ....
  ;
  for t=0, expectedDays-1 do begin
    print, t, '/', expectedDays
    idx_ok=where(data_day(t).flag eq 0.0 and data_day(t).fapar gt 0.0 and index eq 2 and data_tc.day ne t)
    if idx_ok(0) ge 0 then begin
      data_tc.dev_red_temp(idx_ok)=abs(data_tc.red(idx_ok)-data_day(t).red(idx_ok))
      data_tc.dev_nir_temp(idx_ok)=abs(data_tc.nir(idx_ok)-data_day(t).nir(idx_ok))
      data_tc.dev_temp(idx_ok)=abs(data_tc.fapar(idx_ok)-data_day(t).fapar(idx_ok))
    endif
  endfor
  ;
  ;
  data_tc.nday(idx_two)=2
  data_tc.flag(idx_two)=0
  print, 'done, plot image'
  ;
  ;faparcolor
  ;window,5, xsize=720, ysize=360, title='FAPAR after more than 3 days and 1 date and 2 dates'
  ;tv, reverse(congrid(data_tc.fapar*250.0, 720, 360),2)
  ;
  ;loadct,12
  ;window,25, xsize=720, ysize=360, title='THE Day 3'
  ;tvscl, reverse(congrid(data_tc.day, 720, 360),2)
  ;
  ;stop
  ;==========================================================================================
  ;
  ;
  window,0, xsize=720*2, ysize=360*2, title='TC FAPAR after vegetation'
  faparcolor
  ;tv, reverse(congrid(data_tc.fapar*250.0, 720*2, 360*2),2)
  tv, congrid(data_tc.fapar*250.0, 720*2, 360*2)
  ;

  window,1, xsize=720*2, ysize=360*2, title='TC RED after vegetation'
  ;tv, reverse(congrid(data_tc.red*250.0, 720*2, 360*2),2)
  tv, congrid(data_tc.red*250.0, 720*2, 360*2)

  ;loadct,12
  ;window,7, xsize=720, ysize=360, title='Number of Days'
  ;tv, reverse(congrid(data_tc.nday*100.0, 720, 360),2)
  ;
  ;window,26, xsize=720, ysize=360, title='THE Day 4'
  ;tvscl, reverse(congrid(data_tc.day, 720, 360),2)

  ;plot, data_tc.fapar, meandat(2,*,*), psym = 1

  ;print,'Finish vegetation ....'
  ; stop
  ;==========================================================================================
  ;	look for bare soil  pixels
  ;    ;
  ; count the number of date where we have valid pixels over vegetation land
  ;
  ;
  indexs=bytarr(7200,3600)
  indexs(*,*)=0
  one=indexs
  one(*,*)=1
  for t=0, expectedDays-1 do begin
    print, t, '/', expectedDays
    idx_masks = where(data_day(t).fapar eq 0 and $
      data_day(t).red(*,*) gt 0.0 and data_day(t).red(*,*) lt 1.0 and $
      data_day(t).nir(*,*) gt 0.0 and data_day(t).nir(*,*) lt 1.0 and index eq 0.0)
    if idx_masks(0) ge 0 then indexs(idx_masks)=indexs(idx_masks)+one(idx_masks)
  endfor
  ;==========================================================================================
  window,4, xsize=720*2, ysize=360*2, title='Number of day over bare soil'
  loadct,12
  ;tv, reverse(congrid(bytscl(indexs,min=0,max=10.),720*2,360*2),2)
  tv, congrid(bytscl(indexs,min=0,max=10.),720*2,360*2)
  ;
  window,5, xsize=720*2, ysize=360*2, title='Number of day over vegetation'
  ;tv, reverse(congrid(bytscl(index,min=0,max=10.),720*2,360*2),2)
  tv, congrid(bytscl(index,min=0,max=10.),720*2,360*2)
  ;
  ;stop
  ;==========================================================================================
  ; More than two dates
  ;
  ; associated values for the number of dates is bigger than 3
  ;
  idx_thirds = where(indexs ge 3)
  ;==========================================================================================
  dims = SIZE(indexs, /DIMENSIONS)
  ind = ARRAY_INDICES(dims, idx_thirds, /DIMENSIONS)
  print, 'call: make_tc_distance_eu_vegetation_m'
  make_tc_distance_eu_vegetation_m, idx_thirds, resDays, meandats, std_means, 2, index_2s
  print, 'done: make_tc_distance_eu_vegetation_m'
  ;
  for t =0 , expectedDays -1 do begin
    print, t, '/', expectedDays

    idx_t=where(resDays eq float(t))
    ;
    data_tc.red(idx_t)= data_day(t).red(idx_t)
    data_tc.nir(idx_t)= data_day(t).nir(idx_t)
    data_tc.fapar(idx_t)= data_day(t).fapar(idx_t)
    data_tc.flag(idx_t)= data_day(t).flag(idx_t)
    data_tc.day(idx_t) = resDays(idx_t)
    ;
    data_tc.sigma_red(idx_t)= data_day(t).sigma_red(idx_t)
    data_tc.sigma_nir(idx_t)= data_day(t).sigma_nir(idx_t)
    data_tc.sigma(idx_t)= data_day(t).sigma(idx_t)
    ;
    ;
    ;	data_tc.dev_red_temp(idx_t)= std_means(0,idx_t)
    ;	data_tc.dev_nir_temp(idx_t)= std_means(1,idx_t)
    ;	data_tc.dev_temp(idx_t)= std_means(2,idx_t)
    ;
  endfor
  ;
  ;
  ;==========================================================================================
  ; If only One date
  ;
  ; associated values for the only dates
  ;
  idx_ones = where(indexs eq 1)
  ;
  for t=0, expectedDays-1 do begin
    print, t, '/', expectedDays
    idx_time = where(data_day(t).flag(idx_ones) eq 4.0)
    data_tc.red(idx_ones(idx_time))=data_day(t).red(idx_ones(idx_time))
    data_tc.nir(idx_ones(idx_time))=data_day(t).nir(idx_ones(idx_time))
    data_tc.fapar(idx_ones(idx_time))=data_day(t).fapar(idx_ones(idx_time))
    data_tc.day(idx_ones(idx_time))=data_day(t).day(idx_ones(idx_time))
  endfor
  data_tc.nday(idx_ones)=1
  data_tc.flag(idx_ones)=4
  data_tc.dev_red_temp(idx_ones)=0.
  data_tc.dev_nir_temp(idx_ones)=0.
  data_tc.dev_temp(idx_ones)=0.
  ;
  ;window,2, xsize=720, ysize=360, title='RED after more than 3 days and 1 date'
  ;tv, reverse(congrid(data_tc.red*250.0, 720, 360),2)
  ;stop
  ;
  ;==========================================================================================
  ;
  ; If  two dates
  ;
  idx_two = where(indexs eq 2 or index_2s eq 2)
  ;
  nir_two=fltarr(7200,3600)
  ;
  for t=0, expectedDays-1 do begin
    print, t, '/', expectedDays
    buf=data_day(t).flag
    buf1=data_day(t).nir
    idx_time = where(buf eq 0.0 and buf1 gt 0.0 and indexs eq 2 or index_2s eq 2)
    if idx_time(0) ge 0 then begin
      idx_lp= where(buf1(idx_time) gt nir_two(idx_time))
      if idx_lp(0) ge 0 then begin
        nir_two(idx_time(idx_lp))=buf1(idx_time(idx_lp))
        data_tc.fapar(idx_time(idx_lp)) = data_day(t).fapar(idx_time(idx_lp))
        data_tc.red(idx_time(idx_lp))=data_day(t).red(idx_time(idx_lp))
        data_tc.nir(idx_time(idx_lp))= nir_two(idx_time(idx_lp))
        data_tc.sigma_red(idx_time(idx_lp))= data_day(t).sigma_red(idx_time(idx_lp))
        data_tc.sigma_nir(idx_time(idx_lp))= data_day(t).sigma_nir(idx_time(idx_lp))
        data_tc.sigma(idx_time(idx_lp))= data_day(t).sigma(idx_time(idx_lp))
        data_tc.day(idx_time(idx_lp))=t
      endif
    endif
  endfor
  ;
  ; compute the deviation ???? ---> do it after the third call ....
  ;
  for t=0, expectedDays-1 do begin
    print, t, '/', expectedDays
    idx_ok=where(data_day(t).flag eq 4.0 and data_day(t).fapar eq 0.0 and indexs eq 2 and data_tc.day ne t)
    if idx_ok(0) ge 0 then begin
      data_tc.dev_red_temp(idx_ok)=abs(data_tc.red(idx_ok)-data_day(t).red(idx_ok))
      data_tc.dev_nir_temp(idx_ok)=abs(data_tc.nir(idx_ok)-data_day(t).nir(idx_ok))
      data_tc.dev_temp(idx_ok)=abs(data_tc.fapar(idx_ok)-data_day(t).fapar(idx_ok))
    endif
  endfor
  ;
  ;
  data_tc.nday(idx_two)=2
  data_tc.flag(idx_two)=4
  ;
  ;===================================================================================================
  ;
  ;
  window,2, xsize=720*2, ysize=360*2, title='TC FAPAR'
  faparcolor
  ;tv, reverse(congrid(data_tc.fapar*250.0, 720*2, 360*2),2)
  tv, congrid(data_tc.fapar*250.0, 720*2, 360*2)
  ;
  window,3, xsize=720*2, ysize=360*2, title='TC RED'
  ;tv, reverse(congrid(data_tc.red*250.0, 720*2, 360*2),2)
  tv, congrid(data_tc.red*250.0, 720*2, 360*2)

end
;========================================================================================================
