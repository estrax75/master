@/fapar/compile
@../Library/library/ncdf_tools/compile
@/reader/compile
@/colors/compile
@/avhrr/compile
pro doSomething

  dir1='E:\mariomi\Documents\projects\LDTR\AVHRR\NOAA\surface_refl\2003'
  file1='AVHRR-Land_v004_AVH09C1_NOAA-16_20030101_c20140421105754.nc'
  fullFile1=dir1+path_sep()+file1
  myVar1='RHO0'

  dir2='E:\mariomi\Documents\projects\LDTR\AVHRR\AVH\2003'
  file2='AVH09C1.A2003001.N16.004.2014111105754.hdf'
  fullFile2=dir2+path_sep()+file2
  myVar2='SREFL_CH0'

  print, fullFile1, (file_info(fullFile1)).size
  print, fullFile2, (file_info(fullFile2)).size

  
  
  aa=readStandardNcContents1(fullFile1, myVar1, outputVarList, conv_functions, tempDir, ignoreValue, outFuncList, NOTFOUND=NOTFOUND)
  aa=readStandardNcContents1(fullFile2, myVar2, outputVarList, conv_functions, tempDir, ignoreValue, outFuncList, NOTFOUND=NOTFOUND)

  aa=read_nc4_dataset(file1, myVar1, start=start, count=count)
  aa=read_nc4_dataset(file2, myVar2, start=start, count=count)

  aa=readSingleBand(myVar1, file1)
  aa=readSingleBand(myVar2, file2)
  
  ;refl=AVH09C1 file --> RHO0 // GLOBAL file -> SREFL_CH0
  ;input_data[i][j] = (float)refl[j]*0.0001;

  ;refl=AVH09C1 file --> SZEN // GLOBAL file -> TS

  ;input_data[i][j] = (float)cos((double)refl[j]*0.01*DEG2RAD)
  ;native_ts[j] = (float)refl[j]*0.01;

  ;day=['01','02','03','04','05','06','07','08','09','10','11','12',$
  ;     '13','14','15','16','17','18','19','20','21','22','23','24','25',$
  ;     '26','27','28','29','30','31']

  ;sensorName='AVHRR'
  ;sensorType='16' ;'14'
  years=[2003]
  months=indgen(12)+1

  rootDir1='E:\mariomi\Documents\projects\LDTR\AVHRR\NOAA\surface_refl'
  sensor1='AVHRR-Land_v004'
  missionCode1='NOAA'

  rootDir2='E:\mariomi\Documents\projects\LDTR\AVHRR\AVH'
  sensor2='AVH09C1'
  missionCode2='N' ;number coming from year info by mapping "table"

  utility=obj_new('Utility')

  ;AVH09C1.A2003339.N16.004.2014112030717
  for y=0, n_elements(years)-1 do begin
    for m=0, n_elements(months)-1 do begin
      monthDays=utility->calcDayOfMonth([years[y],months[m],1,0])
      for dayNum=1, monthDays do begin
        testFile1=buildAvhrrLandFileName_D(sensor1, missionCode1, years[y], months[m], dayNum, rootDir1, /full)
        testFile2=buildAvhFileName_D(sensor2, missionCode2, years[y], months[m], dayNum, rootDir2, /full, /JULDAY)
        file1=file_search(testFile1, count=count1)
        file2=file_search(testFile2, count=count2)
        if count1 ne 1 then begin
          file1=file_search(testFile1, count=count1, FOLD_CASE=1)
          if count1 ne 1 then begin
            print, 'AvhrrLand skip year/month/day', years[y], months[m], dayNum
            continue
          endif
        endif
        if count2 ne 1 then begin
          file2=file_search(testFile2, count=count2, FOLD_CASE=1)
          if count2 ne 1 then begin
            print, 'Avh skip year/month/day', years[y], months[m], dayNum
            continue
          endif
        endif
        resFile=merge_BRFGlob(file1, file2, years[y], months[m], dayNum)
      endfor
    endfor
  endfor
  obj_destroy, utility

END