;
;ldtr == cloud (remove data)
Pro sm_make_tc_distance_eu_vegetation_m, daysNumber, data_in, idx_doIt, day, meandat, std_mean, nfield, index_2, splitDims, faparMean, cloudtype=cloudtype
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
  ; day : the day to be used in the time composite
  ; index_2 : number of observation after outliers
  ;
  ; meandat : temporal deviation over the period (only valid pixels after outliers)
  ;
  ; compute the distance
  ;help, idx_doIT
  ;stop
  sm_FindEuclideanMatricDistance, daysNumber, data_in, idx_doIt, distance, meandat, std_mean, nfield, splitDims, faparMean, cloudtype=cloudtype
  ;
  ;window,11, xsize=720*2, ysize=360*2, title='Mean fapar after'
  ;faparcolor
  ;
  ; remove outliers
  ;
  if nfield eq 3 then thres = 7.915
  if nfield eq 2 then thres = 5.991
  ; this setting coming from SeaWifs l3time C-Code
  ;  if nfield eq 3 then thres = 3.53
  ;  if nfield eq 2 then thres = 2.30
  ;
  ;=================================================================
  ;
  ; re-compute number of days
  ;
  ;========================================================================
  index_2=bytarr(splitDims[0],splitDims[1])
  buf=fltarr(splitDims[0],splitDims[1])
  index_2(*,*)=0b
  one=index_2
  one(*,*)=1b
  tt=[0, daysNumber]
  ;try to avoid indexing/masking...
  for t=0, tt(1)-1 do begin
    buf=reform(distance[t,*,*])
    ;stop
    ; MM & NG 22/09/2016
    idx_valid = where(buf le thres and buf ge 0.0, validCount); and distance(t,*,*) lt 50.0)
    ; check our distance vs StdDev
    if validCount gt 0 then index_2(idx_valid)=index_2(idx_valid)+one(idx_valid)
    ; mark and remove outliers using flag 1 (21)
    if nfield eq 2 then idx_bad_mask = where(buf gt thres and (data_in(t).flag eq 4 or data_in(t).flag eq 5), outliersCount)
    if nfield eq 3 then idx_bad_mask = where(buf gt thres and data_in(t).flag eq 0, outliersCount)
    vld=where(buf lt 100)
    ;if outliersCount gt 1 then data_in(t).flag(idx_bad_mask)=21.0
    if outliersCount gt 1 then data_in(t).flag(idx_bad_mask)=1
  endfor
  ;
  ;stop
  if nfield eq 3 then idx_remake=where(data_in.flag eq 0 and index_2 ge 3, complement=saveIndexes)
  if nfield eq 2 then idx_remake=where((data_in.flag eq 4 or data_in.flag eq 5) and index_2 ge 3)
  ; Use DelIdlVar to save memory
  DelidlVar, buf
  DelidlVar, one
  DelidlVar, idx_bad_mask
  if idx_remake(0) ge 0 then begin
    print, 'Remake after Outliers out'
    sm_FindEuclideanMatricDistance, daysNumber, data_in, idx_remake, distanceRes, meandatRes, std_meanRes, nfield, splitDims
    distance(*,idx_remake)=distanceRes(*,idx_remake)
    DelidlVar, distanceRes
    meandat.red(idx_remake)=meandatRes.red(idx_remake)
    meandat.nir(idx_remake)=meandatRes.nir(idx_remake)
    meandat.fapar(idx_remake)=meandatRes.fapar(idx_remake)
    DelidlVar, meandatRes
    std_mean.red(idx_remake)=std_meanRes.red(idx_remake)
    std_mean.nir(idx_remake)=std_meanRes.nir(idx_remake)
    std_mean.temp(idx_remake)=std_meanRes.temp(idx_remake)

    DelidlVar, std_meanRes
  endif
  ;
  ;
  ;faparcolor
  ;window,12, xsize=72*2, ysize=360*2, title='mean fapar after outliers out'
  ;tvscl, congrid(img,72,360)
  ;img=bytarr(splitDims[0],splitDims[1])
  ;if nfield eq 3 then img(*,*)=meandat(2,*,*)*250.0
  ;if nfield eq 2 then img(*,*)=meandat(0,*,*)*250.0
  ;tvscl, reverse(congrid(img,720*2,360*2),2)
  ;tvscl, congrid(img,720*2,360*2)
  ;
  ; look for day of minimum distance
  ;
  day=bytarr(splitDims[0],splitDims[1])
  day(*,*)=255
  min_val=fltarr(splitDims[0],splitDims[1])
  buf=fltarr(splitDims[0],splitDims[1])
  ;
  ; take the first as minimum value
  ;
  min_val(*,*)=10000.0
  ; MM: 20161028: check use of idx_remake
  for t=tt(1)-1, 0, -1 do begin
    buf(*,*) = 11000.0
    ; MM 20161028: subscribe distance with idx_remake???
    buf=reform((distance[t,*,*]))
    idx_mask = where(buf(*,*) lt min_val(*,*) and buf(*,*) lt 100, count)
    if count gt 0 then begin
      min_val(idx_mask)=buf(idx_mask)
      day(idx_mask)=data_in(t).day
      ;aa=where(day ne 255, count)
      ;print, count
      ;tvscl, congrid(day, 72, 360)
      ;tempD=where(day eq 255, complement=rev)
      ;dd=day
      ;dd[tempD]=1
      ;dd[rev]=100
      ;tvscl, congrid(dd, 72, 360)
      ;print, t, count
      ;print, idx_mask(0), min_val(idx_mask(0)), t, day(idx_mask(0))
    endif
  endfor
  print,'find minimum distance day ...'
  ;
END

PRO sm_call_composite, daysNumber, data_day_f, data_tc, nSlice, prevFlag=prevFlag, cloudtype=cloudtype
  ;
  ;
  ;
  ; data_day = products for each day and each pixels
  ;
  ; data_tc = time-composite results
  ;
  ; test pixel position

  INT_NAN=2^15
  DATA_RANGE=[0., 1.]
  DATA_NAN=!VALUES.F_NAN

  ; only with a valid filename there is a valid day...
  validIdx=where(data_day_f.fname ne '', count)
  data_day_t=data_day_f[validIdx]
  daysNumber=count
  print, 'In the time composite program ...'
  ;
  ; !!!!!!!!!!!!!!!!
  ; NG 2016: YOU HAVE TO CHANGE THIS AS IF THERE IS MISSING DAILY FILE THE DAY WILL NOT CORRESPOND TO THE T ...
  ;         I suggest that you add and save the DOY to replace in to DAY fiels in the output files
  ;
  tt=[0, daysNumber-1]    ; ng ++
  print, 'daysNumber', daysnumber
  ;
  ;  data_tc= {day: bytarr(7200,3600), $
  ;    nday: bytarr(7200,3600), $
  ;    fapar: fltarr(7200,3600), $
  ;    dev_temp: fltarr(7200,3600), $
  ;    sigma: fltarr(7200,3600), $
  ;    red: fltarr(7200,3600), $
  ;    dev_red_temp: fltarr(7200,3600), $
  ;    sigma_red:fltarr(7200,3600), $
  ;    nir: fltarr(7200,3600), $
  ;    dev_nir_temp: fltarr(7200,3600), $
  ;    sigma_nir: fltarr(7200,3600), $
  ;    qa: intarr(7200,3600), $
  ;    flag: bytarr(7200,3600)}

  ;only for test
  prevflag=bytarr(7200,3600)
  data_tc= {day: bytarr(7200,3600), $
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
    qa: intarr(7200,3600), $
    flag: bytarr(7200,3600), $
    ts: fltarr(7200,3600), $
    tv: fltarr(7200,3600), $
    toc_red: fltarr(7200,3600), $
    toc_nir: fltarr(7200,3600), $
    faparMean: fltarr(7200,3600)}
  ;end test

  data_tc.fapar[*,*]=DATA_NAN
  data_tc.red[*,*]=DATA_NAN
  data_tc.nir[*,*]=DATA_NAN

  data_tc.dev_red_temp[*,*]=DATA_NAN
  data_tc.dev_nir_temp[*,*]=DATA_NAN
  data_tc.dev_temp[*,*]=DATA_NAN

  data_tc.sigma[*,*]=DATA_NAN
  data_tc.sigma_red[*,*]=DATA_NAN
  data_tc.sigma_nir[*,*]=DATA_NAN

  ;only for test
  data_tc.tv[*,*]=INT_NAN
  data_tc.ts[*,*]=INT_NAN
  data_tc.toc_red[*,*]=DATA_NAN
  data_tc.toc_nir[*,*]=DATA_NAN
  ;end test
  ;
  ; initiate flag to sea mask
  ; MM & NC 22/09/2016 flagging water
  ; initialize to unvalid
  data_tc.flag[*,*]=1
  ; day may be 0 (the first); 255 means no data
  data_tc.day[*,*]=255
  ; nday equal 0 means no data.
  data_tc.nday[*,*]=255
  ;
  ;==========================================================================================
  ;
  ; look for vegetated pixels
  ;
  ; count the number of dates where we have valid pixels over vegetation land
  xSplitDim=7200/nSlice
  ySplitDim=3600; full dim,

  tt=[0, daysNumber-1]    ; ng ++
  pixel_position=[460, 1680]

  ; for a faster test set a specific slice here...
  ;startSlice=0;2
  ;endSlice=nSlice;2
  ; good test: vertical slice half of total slices shows "Center Europe and Africa"
  startSlice=10;2
  endSlice=11;2

  for slice=startSlice, endSlice-1 do begin ;nSlice-1 do begin
    subXStart=slice*xSplitDim & subXEnd=(slice+1)*xSplitDim-1
    subYStart=0 & subYEnd=3600-1

    ; initialize this slice (overwriting previous...)
    ;data_day_split={  day: bytarr(xSplitDim,ySplitDim), $
    ;  data_day_split={  day: 0b, $
    ;    ;nday: bytarr(xSplitDim,ySplitDim), $
    ;    fapar: fltarr(xSplitDim,ySplitDim), $
    ;    ;dev_temp: fltarr(xSplitDim,ySplitDim), $
    ;    sigma: fltarr(xSplitDim,ySplitDim), $
    ;    red: fltarr(xSplitDim,ySplitDim), $
    ;    ;dev_red_temp: fltarr(xSplitDim,ySplitDim), $
    ;    sigma_red:fltarr(xSplitDim,ySplitDim), $
    ;    nir: fltarr(xSplitDim,ySplitDim), $
    ;    ;dev_nir_temp: fltarr(xSplitDim,ySplitDim), $
    ;    sigma_nir: fltarr(xSplitDim,ySplitDim), $
    ;    flag: bytarr(xSplitDim,ySplitDim), $
    ;    qa: intarr(xSplitDim,ySplitDim), $
    ;    ts: intarr(xSplitDim,ySplitDim), $
    ;    tv: intarr(xSplitDim,ySplitDim), $
    ;    valid:0}

    ; only for test
    data_day_split={  day: 0b, $
      ;nday: bytarr(xSplitDim,ySplitDim), $
      fapar: fltarr(xSplitDim,ySplitDim), $
      ;dev_temp: fltarr(xSplitDim,ySplitDim), $
      sigma: fltarr(xSplitDim,ySplitDim), $
      red: fltarr(xSplitDim,ySplitDim), $
      ;dev_red_temp: fltarr(xSplitDim,ySplitDim), $
      sigma_red:fltarr(xSplitDim,ySplitDim), $
      nir: fltarr(xSplitDim,ySplitDim), $
      ;dev_nir_temp: fltarr(xSplitDim,ySplitDim), $
      sigma_nir: fltarr(xSplitDim,ySplitDim), $
      flag: bytarr(xSplitDim,ySplitDim), $
      qa: intarr(xSplitDim,ySplitDim), $
      ts: fltarr(xSplitDim,ySplitDim), $
      tv: fltarr(xSplitDim,ySplitDim), $
      toc_red: fltarr(xSplitDim,ySplitDim), $
      toc_nir: fltarr(xSplitDim,ySplitDim), $
      valid:0}
    ; end test

    ;  data_tc_split={  day: bytarr(xSplitDim,ySplitDim), $
    ;    nday: bytarr(xSplitDim,ySplitDim), $
    ;    fapar: fltarr(xSplitDim,ySplitDim), $
    ;    dev_temp: fltarr(xSplitDim,ySplitDim), $
    ;    sigma: fltarr(xSplitDim,ySplitDim), $
    ;    red: fltarr(xSplitDim,ySplitDim), $
    ;    dev_red_temp: fltarr(xSplitDim,ySplitDim), $
    ;    sigma_red:fltarr(xSplitDim,ySplitDim), $
    ;    nir: fltarr(xSplitDim,ySplitDim), $
    ;    dev_nir_temp: fltarr(xSplitDim,ySplitDim), $
    ;    sigma_nir: fltarr(xSplitDim,ySplitDim), $
    ;    flag: bytarr(xSplitDim,ySplitDim), $
    ;    qa: intarr(xSplitDim,ySplitDim), $
    ;    ts: intarr(xSplitDim,ySplitDim), $
    ;    tv: intarr(xSplitDim,ySplitDim), $
    ;    valid:0}

    ; only for test
    data_tc_split={  day: bytarr(xSplitDim,ySplitDim), $
      nday: bytarr(xSplitDim,ySplitDim), $
      fapar: fltarr(xSplitDim,ySplitDim), $
      dev_temp: fltarr(xSplitDim,ySplitDim), $
      sigma: fltarr(xSplitDim,ySplitDim), $
      red: fltarr(xSplitDim,ySplitDim), $
      dev_red_temp: fltarr(xSplitDim,ySplitDim), $
      sigma_red:fltarr(xSplitDim,ySplitDim), $
      nir: fltarr(xSplitDim,ySplitDim), $
      dev_nir_temp: fltarr(xSplitDim,ySplitDim), $
      sigma_nir: fltarr(xSplitDim,ySplitDim), $
      flag: bytarr(xSplitDim,ySplitDim), $
      qa: intarr(xSplitDim,ySplitDim), $
      ts: fltarr(xSplitDim,ySplitDim), $
      tv: fltarr(xSplitDim,ySplitDim), $
      toc_red: fltarr(xSplitDim,ySplitDim), $
      toc_nir: fltarr(xSplitDim,ySplitDim), $
      valid:0}
    ; end test
    notAssignedFlag=15
    data_tc_split.flag=notAssignedFlag ; init to not-assigned flag coding....
    data_tc_split.fapar[*,*]=DATA_NAN
    data_tc_split.red[*,*]=DATA_NAN
    data_tc_split.nir[*,*]=DATA_NAN

    data_tc_split.dev_red_temp[*,*]=DATA_NAN
    data_tc_split.dev_nir_temp[*,*]=DATA_NAN
    data_tc_split.dev_temp[*,*]=DATA_NAN

    data_tc_split.sigma[*,*]=DATA_NAN
    data_tc_split.sigma_red[*,*]=DATA_NAN
    data_tc_split.sigma_nir[*,*]=DATA_NAN

    data_tc_split.day[*,*]=255
    data_tc_split.nday[*,*]=255

    ; only for test
    data_tc_split.ts[*,*]=INT_NAN
    data_tc_split.tv[*,*]=INT_NAN
    data_tc_split.toc_red[*,*]=DATA_NAN
    data_tc_split.toc_nir[*,*]=DATA_NAN
    ; end test

    data_day_split=replicate(data_day_split, daysNumber)

    print, 'reading day from: ', tt[0]+1, 'to: ', tt[1]+1
    print, '...'
    resFlags=0
    for t=0, tt[1] do begin   ; ng ++

      print, 'reading day...', t+1, '/', tt[1]+1
      if data_day_f[t].fid gt 0 then faparData=read_AVHRR_FAPAR(data_day_f[t].fDir, data_day_f[t].fName, FOUND=FOUND, /APPLY, offset=[subXStart, 0], count=[xSplitDim, ySplitDim], fid=data_day_f[t].fid, /FULL) $
      else faparData=read_AVHRR_FAPAR(data_day_f[t].fDir, data_day_f[t].fName, FOUND=FOUND, /APPLY, offset=[subXStart, 0], count=[xSplitDim, ySplitDim], fid=fid, /FULL)
      print, 'done'
      data_day_split[t].valid=0
      if keyword_set(FOUND) then begin

        data_day_split[t].sigma=faparData.sigma
        data_day_split[t].red=faparData.red
        data_day_split[t].sigma_red=faparData.sigma_red
        data_day_split[t].nir=faparData.nir
        data_day_split[t].sigma_nir=faparData.sigma_nir
        data_day_split[t].qa=faparData.qa
        data_day_split[t].ts=fapardata.ts
        data_day_split[t].tv=faparData.tv
        ; remove clouds from data...
        ;titles=['fapar - mask bit 1 or 2 (cloudy/shadow cloud)', 'fapar - mask bit 1 (cloudy', 'fapar - mask bit 2 (shadow cloud)', 'fapar - no mask']
        countCloud=0
        if cloudtype le 2 then begin
          checkCloud1=cgi_map_bitwise_flag(data_day_split[t].qa,1)
          checkCloud2=cgi_map_bitwise_flag(data_day_split[t].qa,2)
          if cloudtype eq 0 then cloudNaN=where(checkCloud1 eq 1 or checkCloud2 eq 1, countCloud)
          if cloudtype eq 1 then cloudNaN=where(checkCloud1 eq 1, countCloud)
          if cloudtype eq 2 then cloudNaN=where(checkCloud2 eq 1, countCloud)
        endif
        if countCloud gt 0 then begin
          ;faparData.fapar[cloudNaN]=!VALUES.F_NAN
          ;faparData.nir[cloudNaN]=!VALUES.F_NAN
          ;faparData.red[cloudNaN]=!VALUES.F_NAN
          ;faparData.toc_nir[cloudNaN]=!VALUES.F_NAN
          ;faparData.toc_red[cloudNaN]=!VALUES.F_NAN
          ;leave original values, but flag cloud
          changeIdxs=where(faparData.flag[cloudNaN] eq 4 or faparData.flag[cloudNaN] eq 5 or faparData.flag[cloudNaN] eq 6 or faparData.flag[cloudNaN] eq 0, cnt)
          if cnt gt 0 then faparData.flag[cloudNaN[changeIdxs]]=2 ; force cloud code for fapar and soil
        endif
        data_day_split[t].fapar=faparData.fapar
        data_day_split[t].red=faparData.red
        data_day_split[t].nir=faparData.nir
        data_day_split[t].toc_red=fapardata.toc_red
        data_day_split[t].toc_nir=faparData.toc_nir
        flagMatrix=fapardata.flag
        data_day_split[t].flag=flagMatrix
        resFlags=[resFlags,flagMatrix[UNIQ(flagMatrix, SORT(flagMatrix))]]
        flagMatrix=0
        checkCloud1=-1 & checkCloud2=-1
        ;.day set to position of file in the (sub)sequence (n/8,9,10 for decade n/28,29,30,31 for mponthly), use doy???
        data_day_split[t].day=t
        ;array=faparData.flag
        ;print, array[UNIQ(array, SORT(array))]
        ; test flag...
        if keyword_set(test_pics) then begin
          loadct,12
          tvlct,r,g,b, /get
          ;8Invalid
          ;9Invalid
          ;3Pixel is over water1 = yes, 0 = no
          ;2Pixel contains cloud shadow1 = yes, 0 = no
          ;1Pixel is cloudy1 = yes, 0 = no
          red = [0,1,0.8,0,0.00,0.68,0.,0.55,0.00,0.00,0.85,0,00,0.]
          gre = [0,0,0.0,0,1.00,0.00,0.,0.55,0.77,0.66,0.00,0.00,0.]
          blu = [0,0,0.0,1,1.00,1.00,1.,1.00,1.00,0.55,0.80,0.77,0.]
          TVLCT, red*255, gre*255, blu*255
          tvlct,r,g,b, /get
          destFlag=(data_day_split[t].qa)*0
          cloud1=cgi_map_bitwise_flag(data_day_split[t].qa,1)
          idx=where(cloud1 eq 1, cnt)
          destFlag[idx]=1
          write_tiff,'/space2/storage/projects/LAN/AVH/L3/PLC/1999/06/flag_pics/LDTR_cloud1_day'+strcompress(t+1, /remove)+'.tiff', reverse(destFlag,2), red=r,gre=g,blu=b

          cloud2=cgi_map_bitwise_flag(data_day_split[t].qa,2)
          idx=where(cloud2 eq 1, cnt)
          destFlag[idx]=2
          write_tiff,'/space2/storage/projects/LAN/AVH/L3/PLC/1999/06/flag_pics/LDTR_cloud2_day'+strcompress(t+1, /remove)+'.tiff', reverse(destFlag, 2), red=r,gre=g,blu=b

          water=cgi_map_bitwise_flag(data_day_split[t].qa,3)
          idx=where(water eq 1, cnt)
          destFlag[idx]=3
          write_tiff,'/space2/storage/projects/LAN/AVH/L3/PLC/1999/06/flag_pics/LDTR_water_day'+strcompress(t+1, /remove)+'.tiff', reverse(destFlag,2), red=r,gre=g,blu=b

          invalid1=cgi_map_bitwise_flag(data_day_split[t].qa,8)
          idx=where(invalid1 eq 1, cnt)
          destFlag[idx]=4
          write_tiff,'/space2/storage/projects/LAN/AVH/L3/PLC/1999/06/flag_pics/LDTR_invalid1_day'+strcompress(t+1, /remove)+'.tiff', reverse(destFlag,2), red=r,gre=g,blu=b

          invalid2=CGI_MAP_BITWISE_FLAG(data_day_split[t].qa,9)
          idx=where(invalid2 eq 1, cnt)
          destFlag[idx]=4
          write_tiff,'/space2/storage/projects/LAN/AVH/L3/PLC/1999/06/flag_pics/LDTR_invalid2_day'+strcompress(t+1, /remove)+'.tiff', reverse(destflag,2), red=r,gre=g,blu=b

          write_tiff,'/space2/storage/projects/LAN/AVH/L3/PLC/1999/06/flag_pics/LDTR_day'+strcompress(t+1, /remove)+'.tiff', reverse(bytscl(faparData.qa, min=0, max=25600),2), red=r,gre=g,blu=b
          red = [0,1,1,0,0.66,0.68,0.,0.55,0.00,0.00,0.85,0,00,0.]
          gre = [0,0,0,0,0.66,0.00,0.,0.55,0.77,0.66,0.00,0.00,0.]
          blu = [0,0,1,1,0.66,1.00,1.,1.00,1.00,0.55,0.80,0.77,0.]
          TVLCT, red*255, gre*255, blu*255
          tvlct,r,g,b, /get
          write_tiff,'/space2/storage/projects/LAN/AVH/L3/PLC/1999/06/flag_pics/JRC_day'+strcompress(t+1, /remove)+'.tiff', reverse(faparData.flag,2), red=r,gre=g,blu=b
        endif
        ; .valid eq 1 means a good file
        data_day_split[t].valid=1
      endif
    endfor
    TOCnir=reform(data_day_split[*].toc_nir[0,1950:2100])
    TOCred=reform(data_day_split[*].toc_red[0,1950:2100])
    nir=reform(data_day_split[*].nir[0,1950:2100])
    red=reform(data_day_split[*].red[0,1950:2100])
    save, filename='tocdata_199906_CT'+strcompress(cloudType, /REMOVE)+'.sav', TOCnir, TOCred
    save, filename='brfdata_199906_CT'+strcompress(cloudType, /REMOVE)+'.sav', nir, red

    resFlags=resFlags[UNIQ(resFlags, SORT(resFlags))]
    print, 'input flags list:', resFlags
    vIdxs=where(data_day_split.valid eq 1, dNumber)
    daysNumber=dNumber
    data_day_split=data_day_split[vIdxs]
    tt=[0, daysNumber-1]
    waterMask=data_day_split[0].flag*0

    dayVeg=bytarr(xSplitDim,ySplitDim)
    dayVeg(*,*)=0

    one=dayVeg
    one(*,*)=1

    ;window,1,xsize=360, ysize=360, title='flag 1'
    ;array=data_tc_split.flag
    ;tvscl, congrid(array, 72, 360)
    ;print, array[UNIQ(array, SORT(array))]
    pixel_position=[460, 1680]
    for t=0, tt(1) do begin
      ; cut off Nan
      validMask=finite(data_day_split(t).fapar(*,*)) and finite(data_day_split(t).red(*,*)) and finite(data_day_split(t).nir(*,*))
      goodIndexes=where(validMask eq 1)

      ;create Soil mask
      idxMaskSoil=where(data_day_split(t).fapar[goodIndexes] ge 0.0 and $
        data_day_split(t).red[goodIndexes] gt 0.0 and data_day_split(t).red[goodIndexes] lt 1.0 and $
        data_day_split(t).nir[goodIndexes] gt 0.0 and data_day_split(t).nir[goodIndexes] lt 1.0)
      validMaskSoil=validMask*0
      validMaskSoil[goodIndexes[idxMaskSoil]]=1
      validMaskSoil=validMask*validMaskSoil

      ;create Veg mask
      idxMaskVeg=where(data_day_split(t).fapar[goodIndexes] gt 0.0 and $
        data_day_split(t).red[goodIndexes] gt 0.0 and data_day_split(t).red[goodIndexes] lt 1.0 and $
        data_day_split(t).nir[goodIndexes] gt 0.0 and data_day_split(t).nir[goodIndexes] lt 1.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1

      validMaskVeg=validMask*validMaskVeg
      ;final Veg Mask
      idx_maskVeg = where(validMaskVeg eq 1 and data_day_split(t).flag(*,*) eq 0, countVeg)
      ;final Soil Mask
      idx_maskSoil = where(validMaskSoil eq 1 and (data_day_split(t).flag(*,*) eq 4 or data_day_split(t).flag(*,*) eq 5), countSoil)
      ; previous version (without Nan)
      ;      idx_maskVeg = where(data_day_split(t).fapar(*,*) gt 0.0 and data_day_split(t).flag(*,*) eq 0 and  $
      ;        data_day_split(t).red(*,*) gt 0.0 and data_day_split(t).red(*,*) lt 1.0 and $
      ;        data_day_split(t).nir(*,*) gt 0.0 and data_day_split(t).nir(*,*) lt 1.0, count1)
      ;      idx_maskBareSoil = where((data_day_split(t).flag(*,*) eq 4 or data_day_split(t).flag(*,*) eq 5) and $
      ;        data_day_split(t).fapar(*,*) ge 0.0 and $
      ;        data_day_split(t).red(*,*) gt 0.0 and data_day_split(t).red(*,*) lt 1.0 and $
      ;        data_day_split(t).nir(*,*) gt 0.0 and data_day_split(t).nir(*,*) lt 1.0, count1)
      ;window,3
      ;tvscl, congrid(diff, 36,720)
      if countVeg gt 0 then dayVeg[idx_maskVeg]=dayVeg[idx_maskVeg]+one[idx_maskVeg]
      ;if countBSoil gt 0 then indexVeg[idx_maskVeg]=indexVeg[idx_maskVeg]+one[idx_maskVeg]
      ;if idx_maskBareSoil(0) ge 0 then indexBareSoil(idx_maskBareSoil)=indexBareSoil(idx_maskBareSoil)+one(idx_maskBareSoil)
    endfor
    ;==========================================================================================
    ; More than two dates
    ;
    ; associated values for the number of date is bigger or equal to 3
    ;
    idx_third = where(dayVeg ge 3, complement=flagNan)
    ;
    sm_make_tc_distance_eu_vegetation_m, daysNumber, data_day_split, idx_third, day, meandat, std_mean, 3, index_2, [xSplitDim, ySplitDim], faparMean, cloudtype=cloudtype

    for t =0 , tt(1)  do begin      ; ng ++
      ; MM & NG 22/09/2016
      idx_t=where(day eq t and index_2 ge 3)
      if idx_t(0) ge 0 then begin
        data_tc_split.nday[idx_t]=dayVeg[idx_t]
        data_tc_split.red(idx_t)= data_day_split(t).red(idx_t)
        data_tc_split.nir(idx_t)= data_day_split(t).nir(idx_t)
        data_tc_split.fapar(idx_t)= data_day_split(t).fapar(idx_t)
        ;
        data_tc_split.sigma_red(idx_t)= data_day_split(t).sigma_red(idx_t)
        data_tc_split.sigma_nir(idx_t)= data_day_split(t).sigma_nir(idx_t)
        data_tc_split.sigma(idx_t)= data_day_split(t).sigma(idx_t)
        ;wrongIndex=where(data_day_split(t).flag(idx_t) eq 21, countWrong)
        ;if countWrong ne 0 then stop
        data_tc_split.flag(idx_t)= data_day_split(t).flag(idx_t)
        ;overwriteCheck=where(data_tc_split.day(idx_t) ne 255, overWriteCount)
        ;if overWriteCount ne 0 then stop
        data_tc_split.day(idx_t) = day(idx_t)
        ; MM & NG 22/9/2016
        data_tc_split.toc_red(idx_t)= data_day_split(t).toc_red(idx_t)
        data_tc_split.toc_nir(idx_t) = data_day_split(t).toc_nir(idx_t)
        ; data_tc_split.dev_temp not time-dependent
      endif
      tv, congrid(reform(data_tc_split.fapar[*,*]), 72, 360)
    endfor
    data_tc_split.dev_red_temp= std_mean.red
    data_tc_split.dev_nir_temp= std_mean.nir
    data_tc_split.dev_temp= std_mean.temp
    tvscl, congrid(reform(data_tc_split.nday), 72, 360)

    ; If only One date
    ; associated values for the only dates
    idx_one=where(dayVeg eq 1 or index_2 eq 1)
    ;totDay=data_day_split[0].flag*0
    ;
    for t=0, tt(1) do begin     ;   ng ++
      validMask=finite(data_day_split(t).fapar)
      goodIndexes=where(validMask eq 1)
      idxMaskVeg=where(data_day_split(t).fapar[goodIndexes] gt 0.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      ;create Veg mask

      validMaskVeg=validMask*validMaskVeg
      ;final Veg Mask
      idx_time = where(validMaskVeg eq 1 and (data_day_split(t).flag eq 0) and (dayVeg eq 1 or index_2 eq 1), countSingleDay)

      ;      idx_timeOld = where((data_day_split(t).flag eq 0) and (data_day_split(t).fapar gt 0.0) and (dayVeg eq 1 or index_2 eq 1), countSingleDayOld)
      ;      if countSingleDay ne countSingleDayOld then stop
      print, 'singleDay for day: ', t, countSingleDay
      if countSingleDay gt 0 then begin
        data_tc_split.nday(idx_time)=1
        data_tc_split.red(idx_time)=data_day_split(t).red(idx_time)
        data_tc_split.nir(idx_time)=data_day_split(t).nir(idx_time)
        data_tc_split.fapar(idx_time)=data_day_split(t).fapar(idx_time)
        ;wrongIndex=where(data_day_split(t).flag(idx_time) eq 21, countWrong)
        ;if countWrong ne 0 then stop
        data_tc_split.flag(idx_time)=data_day_split(t).flag(idx_time)
        data_tc_split.sigma_red(idx_time)= data_day_split(t).sigma_red(idx_time)
        data_tc_split.sigma_nir(idx_time)= data_day_split(t).sigma_nir(idx_time)
        data_tc_split.sigma(idx_time)= data_day_split(t).sigma(idx_time)
        data_tc_split.toc_red(idx_time)= data_day_split(t).toc_red(idx_time)
        data_tc_split.toc_nir(idx_time)= data_day_split(t).toc_nir(idx_time)
        data_tc_split.day(idx_time)=data_day_split(t).day
      endif
    endfor

    tvscl, congrid(reform(data_tc_split.nday), 72, 360)
    data_tc_split.dev_red_temp(idx_one)=0.
    data_tc_split.dev_nir_temp(idx_one)=0.
    data_tc_split.dev_temp(idx_one)=0.

    ; If only two dates
    ; associated values for the only dates
    ;
    idx_two = where(dayVeg eq 2 or index_2 eq 2)
    fapar_two=fltarr(xSplitDim,3600)
    for t=0, tt(1)  do begin      ; ng ++
      buf=data_day_split(t).flag
      buf1=data_day_split(t).fapar

      validMask=finite(buf1)
      goodIndexes=where(validMask eq 1)
      idxMaskVeg=where(buf[goodIndexes] eq 0 and (buf1[goodIndexes] gt 0.0))
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      ;create Veg mask

      validMaskVeg=validMask*validMaskVeg
      ;final Veg Mask
      idx_time = where(validMaskVeg eq 1 and (dayVeg eq 2 or index_2 eq 2) and buf eq 0, coundTwoDays)

      ;idx_timeOld = where((buf eq 0) and (buf1 gt 0.0) and (dayVeg eq 2 or index_2 eq 2), coundTwoDaysOld)
      ;if coundTwoDays ne coundTwoDaysOld then stop
      print, 'DoubleDay for day: ', t, coundTwoDays
      if coundTwoDays gt 0 then begin
        idx_lp= where(buf1(idx_time) gt fapar_two(idx_time))
        if idx_lp(0) ge 0 then begin
          fapar_two(idx_time(idx_lp))=buf1(idx_time(idx_lp))
          data_tc_split.nday(idx_time(idx_lp))=2
          data_tc_split.fapar(idx_time(idx_lp)) = fapar_two(idx_time(idx_lp))
          data_tc_split.red(idx_time(idx_lp))=data_day_split(t).red(idx_time(idx_lp))
          data_tc_split.nir(idx_time(idx_lp))=data_day_split(t).nir(idx_time(idx_lp))
          data_tc_split.toc_red(idx_time(idx_lp))= data_day_split(t).toc_red(idx_time(idx_lp))
          data_tc_split.toc_nir(idx_time(idx_lp))= data_day_split(t).toc_nir(idx_time(idx_lp))
          data_tc_split.sigma(idx_time(idx_lp))= data_day_split(t).sigma(idx_time(idx_lp))
          data_tc_split.sigma_red(idx_time(idx_lp))= data_day_split(t).sigma_red(idx_time(idx_lp))
          data_tc_split.sigma_nir(idx_time(idx_lp))= data_day_split(t).sigma_nir(idx_time(idx_lp))
          ;wrongIndex=where(data_day_split(t).flag(idx_time(idx_lp)) eq 21, countWrong)
          ;if countWrong ne 0 then stop
          data_tc_split.flag(idx_time(idx_lp))= data_day_split(t).flag(idx_time(idx_lp))
          data_tc_split.day(idx_time(idx_lp))=data_day_split(t).day
        endif
      endif
    endfor
    ; compute the deviation ???? ---> do it after the third call ....
    ;
    for t=0, tt(1)  do begin        ; NG ++
      ; MM & NG 22/9/2016
      validMask=finite(data_day_split(t).fapar(*,*))
      goodIndexes=where(validMask eq 1)
      idxMaskVeg=where(data_day_split(t).fapar[goodIndexes] gt 0.0)
      validMaskVeg=validMask*0
      validMaskVeg[goodIndexes[idxMaskVeg]]=1
      ;create Veg mask

      validMaskVeg=validMask*validMaskVeg
      ;final Veg Mask
      idx_ok = where(validMaskVeg eq 1 and (dayVeg eq 2 or index_2 eq 2) and (data_tc_split.day ne t) and data_day_split(t).flag eq 0, countDay)

      ;      idx_okOld=where((data_day_split(t).flag eq 0) and (data_day_split(t).fapar gt 0.0) and (dayVeg eq 2 or index_2 eq 2) and (data_tc_split.day ne t), countDayOld)
      ;      if countDay ne countDayOld then stop
      if idx_ok(0) ge 0 then begin
        data_tc_split.dev_red_temp(idx_ok)=abs(data_tc_split.red(idx_ok)-data_day_split(t).red(idx_ok))
        data_tc_split.dev_nir_temp(idx_ok)=abs(data_tc_split.nir(idx_ok)-data_day_split(t).nir(idx_ok))
        data_tc_split.dev_temp(idx_ok)=abs(data_tc_split.fapar(idx_ok)-data_day_split(t).fapar(idx_ok))
      endif
    endfor
    tvscl, congrid(reform(data_tc_split.nday), 72, 360)
    ;faparcolor
    ;window,5, xsize=720, ysize=360, title='FAPAR after more than 3 days and 1 date and 2 dates'
    ;tv, reverse(congrid(data_tc_split.fapar*250.0, 720, 360),2)
    ;stop
    ;print,'Finish vegetation ....'

    ;==========================================================================================
    ; look for bare soil  pixels
    ; count the number of date where we have valid pixels over vegetation land
    indexBareSoil=bytarr(xSplitDim,3600)
    indexBareSoil(*,*)=0
    one=indexBareSoil
    one(*,*)=1
    for t=0, tt(1)  do begin        ;  ng ++
      ; Cut off NaN from original data
      validMask=finite(data_day_split(t).fapar(*,*)) and finite(data_day_split(t).red(*,*)) and finite(data_day_split(t).nir(*,*))
      goodIndexes=where(validMask eq 1)
      idxMaskSoil=where(data_day_split(t).fapar[goodIndexes] ge 0.0 and $
        data_day_split(t).red[goodIndexes] gt 0.0 and data_day_split(t).red[goodIndexes] lt 1.0 and $
        data_day_split(t).nir[goodIndexes] gt 0.0 and data_day_split(t).nir[goodIndexes] lt 1.0)
      validMaskSoil=validMask*0
      validMaskSoil[goodIndexes[idxMaskSoil]]=1
      ;create soil mask
      validMaskSoil=validMask*validMaskSoil
      ;final Soil Mask
      idx_masks = where(validMaskSoil eq 1 and (data_day_split(t).flag(*,*) eq 4 or data_day_split(t).flag(*,*) eq 5), countSoil)
      ;      idx_masksOld = where(data_day_split(t).fapar eq 0 and $
      ;        data_day_split(t).red(*,*) gt 0.0 and data_day_split(t).red(*,*) lt 1.0 and $
      ;        data_day_split(t).nir(*,*) gt 0.0 and data_day_split(t).nir(*,*) lt 1.0 and data_day_split(t).flag(*,*) eq 4 or $
      ;        data_day_split(t).flag(*,*) eq 5, countSoilOld)                                                                                       ; ng 2016
      ;      if countSoilOld ne countSoil then stop
      if idx_masks(0) ge 0 then indexBareSoil(idx_masks)=indexBareSoil(idx_masks)+one(idx_masks)
    endfor

    array=data_tc_split.flag
    ;==========================================================================================
    ; More than two dates
    ; associated values for the number of dates is bigger than 3
    idx_thirds = where(indexBareSoil ge 3, complement=flagNan)
    print, '# soil pixels more than 3 times', N_elements(idx_thirds)
    ;stop

    ;==========================================================================================
    sm_make_tc_distance_eu_vegetation_m, daysNumber, data_day_split, idx_thirds, days, meandats, std_means, 2, index_2s, [xSplitDim, ySplitDim]
    array=data_tc_split.flag
    bareSday=data_tc_split.red
    bareSday[*]=0

    for t=0 , tt(1) do begin        ; ng ++
      idx_t1=where(days eq t and index_2s ge 3, countThreeDays1)
      idx_t=where(days eq t and index_2s ge 3 and (data_day_split(t).flag eq 4 or $
        data_day_split(t).flag eq 5) and data_tc_split.flag ne 0, countThreeDays)
      print, 'countThreeDay (bare soil) for day: ', t, countThreeDays
      if countThreeDays ne 0 then begin
        data_tc_split.nday(idx_t)=index_2s[idx_t]
        data_tc_split.red(idx_t)= data_day_split(t).red(idx_t)
        data_tc_split.nir(idx_t)= data_day_split(t).nir(idx_t)
        data_tc_split.fapar(idx_t)= data_day_split(t).fapar(idx_t)
        ;wrongIndex=where(data_day_split(t).flag(idx_t) eq 21, countWrong)
        ;if countWrong ne 0 then stop
        data_tc_split.flag(idx_t)= data_day_split(t).flag(idx_t)
        data_tc_split.day(idx_t) = days(idx_t)
        data_tc_split.toc_red(idx_t)= data_day_split(t).toc_red(idx_t)
        data_tc_split.toc_nir(idx_t)= data_day_split(t).toc_nir(idx_t)
        data_tc_split.sigma_red(idx_t)= data_day_split(t).sigma_red(idx_t)
        data_tc_split.sigma_nir(idx_t)= data_day_split(t).sigma_nir(idx_t)
        data_tc_split.sigma(idx_t)= data_day_split(t).sigma(idx_t)
        ; MM & NG 22/9/2016
        data_tc_split.dev_red_temp(idx_t)= std_means.red[idx_t]
        data_tc_split.dev_nir_temp(idx_t)= std_means.nir[idx_t]
        data_tc_split.dev_temp(idx_t)= std_means.temp[idx_t]
        bareSday(idx_t)=1.
      endif
      tvscl, congrid(reform(bareSday), 72, 360)
    endfor
    ;stop
    tvscl, congrid(reform(data_tc_split.nday), 72, 360)

    ;==========================================================================================
    ; If only One date
    ; associated values for the only dates
    ; MM & NG 23/9/2016
    idx_ones = where(((indexBareSoil eq 1) or (index_2s eq 1)) and data_tc_split.flag ne 0)
    ones=0b*data_tc_split.day+1
    for t=0, tt(1)  do begin          ;  ng ++
      ; MM & NG 22/9/2016
      idx_time = where((data_day_split(t).flag(idx_ones) eq 4) or (data_day_split(t).flag(idx_ones) eq 5) , countSingleDay)
      print, 'countSingleDay (bare soil) for day: ', t, countSingleDay
      if countSingleDay gt 0 then begin
        data_tc_split.nday(idx_ones(idx_time))=1
        data_tc_split.red(idx_ones(idx_time))=data_day_split(t).red(idx_ones(idx_time))
        data_tc_split.nir(idx_ones(idx_time))=data_day_split(t).nir(idx_ones(idx_time))
        data_tc_split.toc_red(idx_ones(idx_time))=data_day_split(t).toc_red(idx_ones(idx_time))
        data_tc_split.toc_nir(idx_ones(idx_time))=data_day_split(t).toc_nir(idx_ones(idx_time))
        data_tc_split.fapar(idx_ones(idx_time))=data_day_split(t).fapar(idx_ones(idx_time))
        data_tc_split.sigma(idx_ones(idx_time))=data_day_split(t).sigma(idx_ones(idx_time))
        data_tc_split.sigma_red(idx_ones(idx_time))=data_day_split(t).sigma_red(idx_ones(idx_time))
        data_tc_split.sigma_nir(idx_ones(idx_time))=data_day_split(t).sigma_nir(idx_ones(idx_time))
        ;wrongIndex=where(data_day_split(t).flag(idx_ones(idx_time)) eq 21, countWrong)
        ;if countWrong ne 0 then stop
        data_tc_split.flag(idx_ones(idx_time))=data_day_split(t).flag(idx_ones(idx_time))
        data_tc_split.day(idx_ones(idx_time))=data_day_split(t).day(idx_ones(idx_time))
        bareSday(idx_ones(idx_time))=1.
      endif
    endfor
    tvscl, congrid(reform(data_tc_split.nday), 72, 360)
    data_tc_split.dev_red_temp(idx_ones)=0.
    data_tc_split.dev_nir_temp(idx_ones)=0.
    data_tc_split.dev_temp(idx_ones)=0.
    ;==========================================================================================
    ;
    ; If  two dates
    idx_two = where(indexBareSoil eq 2 or index_2s eq 2 and data_tc_split.flag ne 0)
    nir_two=fltarr(xSplitDim,3600)
    for t=0, tt(1)  do begin      ; ng ++
      buf=reform(data_day_split(t).flag)
      buf1=reform(data_day_split(t).nir)
      ; MM & NG 22/9/2016
      validMask=finite(buf1)
      goodIndexes=where(validMask eq 1)
      idxMaskSoil=where(buf1[goodIndexes] gt 0.0)
      validMaskSoil=validMask*0
      validMaskSoil[goodIndexes[idxMaskSoil]]=1
      ;create soil mask
      validMaskSoil=validMask*validMaskSoil
      ;final Soil Mask
      idx_time = where(validMaskSoil eq 1 and (buf eq 4 or buf eq 5) and data_tc_split.flag ne 0 and (indexBareSoil eq 2 or index_2s eq 2), countTwoDays)
      ;idx_timeOld = where((buf eq 4 or buf eq 5) and data_tc_split.flag ne 0 and (buf1 gt 0.0) and (indexBareSoil eq 2 or index_2s eq 2), countTwoDaysOld)
      print, 'DoubleDay (bare soil) for day: ', t, coundTwoDays
      ;if countTwoDaysOld ne  countTwoDays then stop
      if countTwoDays gt 0 then begin
        idx_lp= where(buf1(idx_time) gt nir_two(idx_time))
        if idx_lp(0) ge 0 then begin
          nir_two(idx_time(idx_lp))=buf1(idx_time(idx_lp))
          data_tc_split.nday(idx_time(idx_lp))=2
          data_tc_split.fapar(idx_time(idx_lp)) = data_day_split(t).fapar(idx_time(idx_lp))
          data_tc_split.red(idx_time(idx_lp))=data_day_split(t).red(idx_time(idx_lp))
          data_tc_split.nir(idx_time(idx_lp))= nir_two(idx_time(idx_lp))
          data_tc_split.sigma_red(idx_time(idx_lp))= data_day_split(t).sigma_red(idx_time(idx_lp))
          data_tc_split.sigma_nir(idx_time(idx_lp))= data_day_split(t).sigma_nir(idx_time(idx_lp))
          data_tc_split.sigma(idx_time(idx_lp))= data_day_split(t).sigma(idx_time(idx_lp))
          data_tc_split.toc_red(idx_time(idx_lp))= data_day_split(t).toc_red(idx_time(idx_lp))
          data_tc_split.toc_nir(idx_time(idx_lp))= data_day_split(t).toc_nir(idx_time(idx_lp))
          ;wrongIndex=where(data_day_split(t).flag(idx_time(idx_lp)) eq 21, countWrong)
          ;if countWrong ne 0 then stop
          data_tc_split.flag(idx_time(idx_lp))= data_day_split(t).flag(idx_time(idx_lp))
          data_tc_split.day(idx_time(idx_lp))=data_day_split(t).day
          bareSday(idx_time(idx_lp))=1.
        endif
      endif
      DelIdlVar, buf
      DelIdlVar, buf1
    endfor
    ; compute the deviation ???? ---> do it after the third call ....
    ;
    tempFlag=data_tc_split.flag
    notAssigned1=where(data_tc_split.flag eq notAssignedFlag and data_tc_split.fapar gt 0., notAssignedCount)
    if notAssignedCount gt 0 then stop
    nCloudIceMx=0b*data_tc_split.flag
    nSeaMx=nCloudIceMx

    for t=0, tt(1)   do begin       ;  ng ++
      ; MM & NG 22/9/2016
      ;fill jrc_flag (composite) with water ONLY if fapar is lt 0 (invalid, never computed)
      idx_water=where((data_day_split(t).flag eq 3 and data_tc_split.fapar lt 0.0), checkWater)
      if checkWater ne 0 then data_tc_split.flag[idx_water]=3
      idx_ok=where((data_day_split(t).flag eq 4 or data_day_split(t).flag eq 5) and (data_day_split(t).fapar eq 0.0) and (indexBareSoil eq 2 or index_2s eq 2) and data_tc_split.day ne t)
      if idx_ok(0) ge 0 then begin
        data_tc_split.dev_red_temp(idx_ok)=abs(data_tc_split.red(idx_ok)-data_day_split(t).red(idx_ok))
        data_tc_split.dev_nir_temp(idx_ok)=abs(data_tc_split.nir(idx_ok)-data_day_split(t).nir(idx_ok))
        data_tc_split.dev_temp(idx_ok)=abs(data_tc_split.fapar(idx_ok)-data_day_split(t).fapar(idx_ok))
      endif
      thisDayIndexes=where(data_tc_split.day eq data_day_split[t].day, count)
      if count ne 0 then begin
        data_tc_split.ts[thisDayIndexes]=data_day_split[t].ts[thisDayIndexes]
        data_tc_split.tv[thisDayIndexes]=data_day_split[t].tv[thisDayIndexes]
        data_tc_split.flag[thisDayIndexes]=data_day_split[t].flag[thisDayIndexes]
        data_tc_split.toc_red[thisDayIndexes]=data_day_split[t].toc_red[thisDayIndexes]
        data_tc_split.toc_nir[thisDayIndexes]=data_day_split[t].toc_nir[thisDayIndexes]
      endif
      idxSea=where(data_day_split(t).flag eq 3, cntSea)
      idxCloudIce=where(data_day_split(t).flag eq 2, cntCloudIce)
      if cntCloudIce gt 0 then nSeaMx[idxSea]=nseaMx[idxSea]+ones[idxSea]
      if cntSea gt 0 then nCloudIceMx[idxCloudIce]=nCloudIceMx[idxCloudIce]+ones[idxCloudIce]
    endfor
    ;    restore, filename='fpa_'+strcompress(cloudtype, /REMOVE)+'.sav'
    ;    restore, filename='red_'+strcompress(cloudtype, /REMOVE)+'.sav'
    ;    restore, filename='nir_'+strcompress(cloudtype, /REMOVE)+'.sav'
    ;    meandata=reform(mean_field.nir(0,1950:2100))
    ;    stddata=reform(std_field.nir(*,0,1950:2100))
    ;    stdmean=reform(std_mean.nir(0,1950:2100))

    ; Set best flag available for tc (only when not assigned by previous steps) flag eq notAssignedFlag
    tempFlag=data_tc_split.flag
    notAssigned=where(data_tc_split.flag eq notAssignedFlag, notAssignedCount)
    aa=where(data_tc_split.flag eq 255, nancnt)
    if notAssignedCount gt 1 then begin
      print, '**Flag = ', notAssignedFlag, '!!! (not assigned value)***'
      ;at least one pixel classified as sea/water...
      idxSea=where(nSeaMx ne 0 and data_tc_split.flag eq notAssignedFlag, cntSea)
      ;at least one pixel classified as cloud/ice...
      ; aggiungere flag ldtr  afare per natale
      ;
      ;      idxCloudIce=where(nCloudIceMx ne 0 and data_tc_split.flag eq notAssignedFlag, cntCloudIce)
      choosenDay=-1
      if cntSea gt 0 then begin
        for pix=0, cntSea-1 do begin
          ; lowest flag values... different decoding table
          flagList=data_day_split[*].flag[idxSea[pix]]
          unikFlags=flagList[UNIQ(flagList, SORT(flagList))]
          ;if n_elements(unikFlags) ne 1 then stop
          ; work around to map best flag using C/Seawifs approach
          mapFlagList=mapFaparFlag(flagList)
          selectedFlag=min(mapFlagList)
          selectedDay=(where(selectedFlag eq mapFlagList))[0]
          selectedFlag=mapFaparFlag(selectedFlag,/REVERT)
          ; come back to AVHRR flag decoding
          data_tc_split.flag[idxSea[pix]]=selectedFlag
          ;aa=where(data_tc_split.flag eq 255, cnt255)
          ;if cnt255 ne 0 then stop
          data_tc_split.fapar[idxSea[pix]] = data_day_split[selectedDay].fapar[idxSea[pix]]
          data_tc_split.red[idxSea[pix]]=data_day_split[selectedDay].red[idxSea[pix]]
          data_tc_split.day[idxSea[pix]]=data_day_split[selectedDay].day
          data_tc_split.nir[idxSea[pix]]= data_day_split[selectedDay].nir[idxSea[pix]]
          data_tc_split.sigma_red[idxSea[pix]]= data_day_split[selectedDay].sigma_red[idxSea[pix]]
          data_tc_split.sigma_nir[idxSea[pix]]= data_day_split[selectedDay].sigma_nir[idxSea[pix]]
          data_tc_split.sigma[idxSea[pix]]= data_day_split[selectedDay].sigma[idxSea[pix]]
          data_tc_split.toc_red[idxSea[pix]]= data_day_split[selectedDay].toc_red[idxSea[pix]]
          data_tc_split.toc_nir[idxSea[pix]]= data_day_split[selectedDay].toc_nir[idxSea[pix]]
          data_tc_split.ts[idxSea[pix]]=data_day_split[selectedDay].ts[idxSea[pix]]
          data_tc_split.tv[idxSea[pix]]=data_day_split[selectedDay].tv[idxSea[pix]]
          data_tc_split.toc_red[idxSea[pix]]=data_day_split[selectedDay].toc_red[idxSea[pix]]
          data_tc_split.toc_nir[idxSea[pix]]=data_day_split[selectedDay].toc_nir[idxSea[pix]]
        endfor
      endif
      nSeaMx[*]=0
      aa=where(data_tc_split.flag eq 255, cnt255)
      if cnt255 ne 0 then stop
      if cntCloudIce gt 0 then begin
        print, 'clouds:', cntCloudIce
        for pix=0, cntCloudIce-1 do begin
          ; just for display test recycle nSeaMx variable
          nSeaMx[idxCloudIce[pix]]=1
          flagList=data_day_split[*].flag[idxCloudIce[pix]]
          unikFlags=flagList[UNIQ(flagList, SORT(flagList))]
          ;aa=where(unikFlags eq 21,c)
          ;if n_elements(unikFlags) ne 1 and c eq 0 then stop
          ; work around to map best flag using C/Seawifs approach
          mapFlagList=mapFaparFlag(flagList)
          notBad=where(mapFlagList ne 255, cnt)
          if cnt gt 0 then selectedFlag=max(mapFlagList[notBad]) else selectedFlag=255
          selectedDay=(where(selectedFlag eq mapFlagList))[0]
          selectedFlag=mapFaparFlag(selectedFlag,/REVERT)
          ; come back to AVHRR flag decoding
          ;if selectedFlag ne 1 then begin
          data_tc_split.flag[idxCloudIce[pix]] = selectedFlag
          ;print, 'choose:', selectedFlag
          ;print, 'from:', unikFlags
          data_tc_split.fapar[idxCloudIce[pix]] = data_day_split[selectedDay].fapar[idxCloudIce[pix]]
          data_tc_split.day[idxCloudIce[pix]] = data_day_split[selectedDay].day
          data_tc_split.red[idxCloudIce[pix]]=data_day_split[selectedDay].red[idxCloudIce[pix]]
          data_tc_split.nir[idxCloudIce[pix]]= data_day_split[selectedDay].nir[idxCloudIce[pix]]
          data_tc_split.sigma_red[idxCloudIce[pix]]= data_day_split[selectedDay].sigma_red[idxCloudIce[pix]]
          data_tc_split.sigma_nir[idxCloudIce[pix]]= data_day_split[selectedDay].sigma_nir[idxCloudIce[pix]]
          data_tc_split.sigma[idxCloudIce[pix]]= data_day_split[selectedDay].sigma[idxCloudIce[pix]]
          data_tc_split.toc_red[idxCloudIce[pix]]= data_day_split[selectedDay].toc_red[idxCloudIce[pix]]
          data_tc_split.toc_nir[idxCloudIce[pix]]= data_day_split[selectedDay].toc_nir[idxCloudIce[pix]]
          data_tc_split.ts[idxCloudIce[pix]]=data_day_split[selectedDay].ts[idxCloudIce[pix]]
          data_tc_split.tv[idxCloudIce[pix]]=data_day_split[selectedDay].tv[idxCloudIce[pix]]
          ;endif
        endfor
      endif
      notAssigned=where(data_tc_split.flag eq notAssignedFlag, notAssignedCount)
      for jj=0, n_elements(notAssigned)-1 do begin
        fList=data_day_split[*].flag[notAssigned[jj]]
        unikFlags=fList[UNIQ(fList, SORT(fList))]
        if n_elements(unikFlags) ne 1 then print, 'warning'
        if unikFlags[0] ne 1 then print, 'warning'
        data_tc_split.flag[notAssigned[jj]]=min(unikFlags)
        print, 'undetermined flag-->', min(unikFlags)
      endfor
    endif
    waterIdxs=where(data_tc_split.flag[*,*] eq 3, waterCount)
    if waterCount gt 0 then begin
      data_tc_split.day[waterIdxs]=255
      data_tc_split.nday[waterIdxs]=255
    endif
    NanDay=where(data_tc_split.day ne 255, validCountDay)
    if validCountDay gt 0 then data_tc_split.day=data_tc_split.day+1

    ; test daily behaviour

    ;    diffDay=dd-data_tc_split.day
    ;    window, 1
    ;    tvscl, congrid(reform(data_tc_split.day), 72, 360)
    ;    window, 2
    ;    tvscl, congrid(reform(diffDay), 72, 360)
    ;      for jj=0, notAssignedCount-1 do begin
    ;        strangeReasonIdx=where((data_day_split[*].flag[notAssigned[jj]] ne 1) and (data_day_split[*].flag[notAssigned[jj]] ne 2), strangereasonCount)
    ;        if strangereasonCount gt 1 then begin
    ;          print, data_tc_split.fapar[notAssigned[jj]]
    ;          print, data_day_split[*].fapar[notAssigned[jj]]
    ;          print, data_day_split[*].flag[notAssigned[jj]]
    ;        endif
    ;      endfor
    ;      print, '**Flag = ',notAssignedFlag,'!!! (end)***'
    ;    endif


    ;array=data_tc_split.flag
    ;window,3, xsize=72*3, ysize=360*3, title='-->3<--'
    ;window,12,xsize=360, ys 360)
    ;print, array[UNIQ(array, SORT(array))];

    ;tvscl, congrid(data_tc_split.flag, 72, 360)
    ;data_tc_split.nday(idx_two)=2
    ;data_tc_split.flag(idx_two)=4
    ;    bareSday=data_tc_split.flag
    ;    aa=where(bareSday eq 4)
    ;    bareSday[*]=0
    ;    bareSday[aa]=1
    ;    tvscl, congrid(reform(bareSday), 72, 360)
    tvscl, congrid(reform(data_tc_split.nday), 72, 360)
    ;tvscl, congrid(reform(nSeaMx), 72, 360)
    ;    window, 10, xsize=360, ysize=360, title='day - 4'
    ;    tvscl, congrid(data_tc_split.day, 72, 360)
    ;    window, 11, xsize=360, ysize=360, title='fapar - 4'
    ;    tvscl, congrid(data_tc_split.fapar, 72, 360)
    ;    window, 12, xsize=360, ysize=360, title='nday - 4'
    ;    tvscl, congrid(data_tc_split.nday, 72, 360)

    ;aa=where(data_tc_split.fapar gt 0 and data_tc_split.fapar le 1, fpa_count)
    ;print, '-->7',  fpa_count, n_elements(data_tc_split.fapar)
    ;window,7, xsize=72*3, ysize=360*3, title='final'
    ;tv, reverse(congrid(data_tc_split.fapar*250.0, 720*2, 360*2),2)
    ;tv, congrid(data_tc_split.fapar*250.0, 72*3, 360*3)
    print, 'compute slice...', slice+1, '/', nSlice
    ; Add 1 to update 0-based day "index": more readable field (think about set doy instead)

    prevflag[subXStart:subXEnd, subYStart:subYEnd]=tempFlag
    data_tc.nday[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.nday[*,*]
    data_tc.day[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.day[*,*]

    data_tc.dev_red_temp[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.dev_red_temp[*,*]
    data_tc.dev_nir_temp[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.dev_nir_temp[*,*]
    data_tc.dev_temp[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.dev_temp[*,*]

    data_tc.sigma[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.sigma[*,*]
    data_tc.sigma_red[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.sigma_red[*,*]
    data_tc.sigma_nir[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.sigma_nir[*,*]
    data_tc.flag[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.flag[*,*]
    data_tc.fapar[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.fapar[*,*]

    data_tc.nir[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.nir[*,*]
    data_tc.red[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.red[*,*]
    ;only for deep check test
    data_tc.ts[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.ts[*,*]
    data_tc.tv[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.tv[*,*]
    data_tc.toc_red[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.toc_red[*,*]
    data_tc.toc_nir[subXStart:subXEnd, subYStart:subYEnd]=data_tc_split.toc_nir[*,*]
    data_tc.faparMean[subXStart:subXEnd, subYStart:subYEnd]=faparMean
    ;end test

  endfor
  ;===================================================================================================
  ;tNames=tag_names(data_tc)

  ; check Sahara mistery...
  ;data_tc.fapar[3500:3700, 2100]=0.5
  ;saharaIndex=where(data_tc.fapar eq 0 and data_tc.flag eq 6, countSahara)

end
;========================================================================================================
