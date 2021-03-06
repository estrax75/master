

;++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
; NAME:
;       SelectData
;
; PURPOSE:
;
;       extract a subset of selected data from a SeaWiFS image,
;		represented by the structure SeaWiFSStruct.
;		The extracted data is a square centered on a line/elem number of size subsetsize.
;
;
; CATEGORY:
;
;       I/O
;
; CALLING SEQUENCE:
;
;       SelectData,filename,SeaWiFSStruct,line,elem,subsetsize,SatData
;
; INPUTS:
;			filename:		input file name (string)
;			SeaWiFSStruct:	structure describing the SeaWiFS image
;			line:			line number for central location of extraction
;			elem:			element number for central location of extraction
;			subsetsize:		side size of the extracted square
;			(the number of pixels extracted is subsetsize x subsetsize)
;
; OUTPUTS:
;			SatData:		extracted data set
;
; KEYWORD PARAMETERS:
;					none
;
; COMMENTS:
;			The list of variables extracted is fixed.
;			Needs routines:
;				read_hdf_data
;				swf_ExtractSubset
; REFERENCES:
;
; EXAMPLE:
;
; MODIFICATION HISTORY:
;
;       Written by: F. MELIN, 02/2001, JRC/IES/GEM.
;
;
;------------------------------------------------------------------------------

PRO swf_SelectData,filename,SatStruct,line,elem,subsetsize,SatData,option

  hbad = -9999.
  lbad =-1L


  ; definition of the size of the subset. The extracted array
  ; from the satellite image will be a square of 'subsetsize x subsetsize',
  ; rearranged in a 1-D array, one line after the other in the order
  ; of the track (southward).

  n_side = FIX ( (subsetsize-1)/2 + 0.1)
  n_square = subsetsize * subsetsize


  ; Definition of the structure bearing the SeaWiFS data subset.

  SatData = { Name:' ', $
    Source:' ', $
    Level:' ', $
    Type:' ', $
    Software:' ', $
    Version: ' ', $
    OrbitNumber:0L, $
    StartYear:-1, $
    EndYear:-1, $
    StartDay:-1, $
    EndDay:-1, $
    StartMillisec:0L, $
    EndMillisec:0L, $
    StartTime:hbad, $
    EndTime:hbad, $
    NumberLine:-1, $
    NumberPixel:-1, $
    StartPixel:-1, $
    Subsampling:-1, $
    Line:-1, $
    Elem:-1, $
    SubsetSize:-1, $
    Latitude:hbad, $
    Longitude:hbad   }

  data = { $
    AOT_412:hbad, AOT_443:hbad, AOT_490:hbad, AOT_510:hbad, AOT_555:hbad, AOT_670:hbad, AOT_765:hbad, AOT_865:hbad, $
    angstrom_510:hbad, $
    aer_model_min: hbad, aer_model_max: hbad, aer_model_ratio: hbad, $
    Rrs_412:hbad, Rrs_443:hbad, Rrs_490:hbad, Rrs_510:hbad, Rrs_555:hbad, Rrs_670:hbad, Rrs_765:hbad, Rrs_865:hbad,$
    Kd_490:hbad, $
    chla:hbad, tsm_clark:hbad, $
    aph_443_qaa:hbad,  $
    adg_443_qaa:hbad,  $
    bbp_555_qaa:hbad,  $
    flag:-1L, $
    SunZenith: hbad, SunAzimuth:hbad, $
    SatZenith: hbad, SatAzimuth:hbad, $
    RelAzimuth: hbad, $
    ozone: hbad, $
    zwind: hbad, mwind: hbad, $
    water_vapor: hbad, $
    pressure: hbad, $
    humidity:hbad, $
    fsol: hbad, $
    Latitude:hbad, Longitude:hbad }

  BadData = data

  data = REPLICATE (data,subsetsize*subsetsize)

  SatData = CREATE_STRUCT (SatData,"Data",data)


  ; Update the Header for the SatData structure.

  SatData.Name          = SatStruct.Name
  SatData.Source        = SatStruct.Source
  SatData.Level         = SatStruct.Level
  SatData.Type          = SatStruct.Type
  SatData.Software      = SatStruct.Software
  SatData.Version       = SatStruct.Version
  SatData.OrbitNumber   = SatStruct.OrbitNumber
  SatData.StartYear     = SatStruct.StartYear
  SatData.EndYear       = SatStruct.EndYear
  SatData.StartDay      = SatStruct.StartDay
  SatData.EndDay        = SatStruct.EndDay
  SatData.StartMillisec = SatStruct.StartMillisec
  SatData.EndMillisec   = SatStruct.EndMillisec
  SatData.StartTime     = SatStruct.StartTime
  SatData.EndTime       = SatStruct.EndTime
  SatData.NumberLine    = SatStruct.NumberLine
  SatData.NumberPixel   = SatStruct.NumberPixel
  SatData.StartPixel    = 1 ; SeaWiFSStruct.StartPixel
  SatData.Subsampling   = 1 ; SeaWiFSStruct.Subsampling

  SatData.Line          = line
  SatData.Elem          = elem
  SatData.SubsetSize    = subsetsize

  ; finds content of the file

  fid = H5F_OPEN(filename)

  H5_LIST,filename,OUTPUT=res
  vlist = REFORM(res[1,*])

  H5F_CLOSE, fid

  ; Extract subset of file.

  ; Rrs
  ; DFNT_INT16
  slope_Rrs = 0.001
  offset_Rrs = 0
  slope_Rrs_670 = 0.0001
  bad_Rrs = -32000

  ; AOT
  ; DFNT_INT16
  slope_tau = 0.0001
  offset_tau = 0.
  bad_tau = -32000

  ; angstrom_510
  ; DFNT_INT16
  slope_angstrom_510=0.0002
  offset_angstrom_510=0.
  bad_angstrom_510 = -32000 ; -32767
  bad_aer_model = 0
  bad_aer_ratio = -32000.

  ; eps_78
  ; DFNT_UINT8
  slope_eps_78 = 0.01
  offset_eps_78 = 0.
  bad_eps_78 = 0

  ; La
  ; DFNT_FLOAT32
  slope_La = 1.
  offset_La = 0.
  bad_La = 0.

  ; K_490
  ; DFNT_INT16
  slope_k_490 = 0.0002
  oofset_k_490 = 0.
  bad_k_490 = -32000

  ; Chl a, OC4v4, GSM01
  ; DFNT_FLOAT32
  slope_chla = 1.
  offset_chla = 0.
  bad_chla = 0. ; -1.

  ; Pigment
  ; DFNT_FLOAT32
  slope_pigment = 1.
  offset_pigment = 0.
  bad_pigment = -1.0

  ; TSM, Clark
  ; DFNT_FLOAT32
  slope_tsm = 1.
  offset_tsm = 0.
  bad_tsm = 0. ; -1.0

  ; a
  ; DFNT_INT16
  slope_a =0.0001
  offset_a=2.5
  bad_a = -25500 ; -25221

  ; aph
  ; DFNT_INT16
  slope_aph =0.0001
  offset_aph=2.5
  bad_aph = -32000 ; -25221

  ; adg
  ; DFNT_INT16
  slope_adg = 0.0001
  offset_adg = 2.5
  bad_adg = -32000 ; -32767

  ; bbp
  ; DFNT_INT16
  slope_bbp = 5.e-6
  offset_bbp = 0.16
  bad_bbp = -32000 ; -32000 or -32767

  ; PAR
  ; DFNT_INT16
  slope_par = 0.002
  offset_par = 65.5
  bad_par= -32750

  bad_ozone = -9999.
  bad_pressure = -9999.
  bad_zwind = -9999.
  bad_mwind = -9999.
  bad_humidity = -9999.
  bad_water_vapor = -9999.

  bad_sena = -32767
  bad_senz = -32767
  bad_sola = -32767
  bad_solz = -32767

  subset=fltarr(n_square) & subset(*)=hbad

  ;###########################################################################################################
  ; AOT

  ; AOT_412
  name = "taua_412"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].AOT_412 = float(subset[i]) * header.slope + header.intercept

  ; AOT_443
  name = "taua_443"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].AOT_443 = float(subset[i]) * header.slope + header.intercept

  ; AOT_490
  name = "taua_490"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].AOT_490 = float(subset[i]) * header.slope + header.intercept

  ; AOT_510
  name = "taua_510"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].AOT_510 = float(subset[i]) * header.slope + header.intercept

  ; AOT_555
  name = "taua_555"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].AOT_555 = float(subset[i]) * header.slope + header.intercept

  ; AOT_670
  name = "taua_670"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].AOT_670 = float(subset[i]) * header.slope + header.intercept

  ; AOT_765
  name = "taua_765"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].AOT_765 = float(subset[i]) * header.slope + header.intercept

  ; AOT_865
  name = "aot_865"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].AOT_865 = float(subset[i]) * header.slope + header.intercept

  ;###########################################################################################################

  ; angstrom_510
  name = "angstrom"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].angstrom_510 = float(subset[i]) * header.slope + header.intercept

  ; aer_model_min
  name = "aer_model_min"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GE bad_aer_model ) then SatData.Data[i].aer_model_min = float(subset[i]) * header.slope + header.intercept
  ; aer_model_max
  name = "aer_model_max"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GE bad_aer_model ) then SatData.Data[i].aer_model_max = float(subset[i]) * header.slope + header.intercept
  ; aer_model_ratio
  name = "aer_model_ratio"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].aer_model_ratio = float(subset[i]) * header.slope + header.intercept

  ;###########################################################################################################
  ; Rrs

  ; Rrs_412
  name = "Rrs_412"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].Rrs_412 = float(subset[i]) * header.slope + header.intercept

  ; Rrs_443
  name = "Rrs_443"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].Rrs_443 = float(subset[i]) * header.slope + header.intercept


  ; Rrs_490
  name = "Rrs_490"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].Rrs_490 = float(subset[i]) * header.slope + header.intercept


  ; Rrs_510
  name = "Rrs_510"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].Rrs_510 = float(subset[i]) * header.slope + header.intercept

  ; Rrs_555
  name = "Rrs_555"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue) then SatData.Data[i].Rrs_555 = float(subset[i]) * header.slope + header.intercept


  ; Rrs_670
  name = "Rrs_670"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].Rrs_670 = float(subset[i]) * header.slope + header.intercept

  ; Rrs_765
  name = "Rrs_765"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].Rrs_765 = float(subset[i]) * header.slope + header.intercept

  ; Rrs_865
  name = "Rrs_865"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].Rrs_865 = float(subset[i]) * header.slope + header.intercept

  ;###########################################################################################################
  ; flag
  name = "l2_flags"
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  SatData.Data(*).flag = subset

  ;###########################################################################################################

  ; Kd_490
  name = "Kd_490"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].Kd_490 = float(subset[i]) * header.slope + header.intercept

  ; chlor_a, OC4v4
  name = "chlor_a"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].chla = float(subset[i]) * header.slope + header.intercept

  ; aph, qaa
  name = "aph_443_qaa"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].aph_443_qaa = float(subset[i]) * header.slope + header.intercept

  ; adg, qaa
  name = "adg_443_qaa"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].adg_443_qaa = float(subset[i]) * header.slope + header.intercept

  ; bbp, qaa
  name = "bbp_555_qaa"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].bbp_555_qaa = float(subset[i]) * header.slope + header.intercept


  ;###########################################################################################################

  ; ozone
  name = "ozone"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GE header.badvalue ) then SatData.Data[i].ozone = float(subset[i]) * header.slope*1000. + header.intercept

  ; zwind
  name = "zwind"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GE header.badvalue ) then SatData.Data[i].zwind = float(subset[i]) * header.slope + header.intercept

  ; mwind
  name = "mwind"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GE header.badvalue ) then SatData.Data[i].mwind = float(subset[i]) * header.slope + header.intercept

  ; water_vapor
  name = "water_vapor"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GE header.badvalue ) then SatData.Data[i].water_vapor = float(subset[i]) * header.slope + header.intercept

  ; pressure
  name = "pressure"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GE header.badvalue ) then SatData.Data[i].pressure = float(subset[i]) * header.slope + header.intercept

  ; humidity
  name = "humidity"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GE header.badvalue ) then SatData.Data[i].humidity = float(subset[i]) * header.slope + header.intercept

  ;###########################################################################################################

  ; sena
  name = "sena"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].SatAzimuth = float(subset[i]) * header.slope + header.intercept

  ; senz
  name = "senz"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].SatZenith = float(subset[i]) * header.slope + header.intercept

  ; sola
  name = "sola"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].SunAzimuth = float(subset[i]) * header.slope + header.intercept

  ; solz
  name = "solz"
  subset=fltarr(n_square) & subset(*)=hbad
  swf_ExtractSubset,filename,name,vlist,n_side,line,elem,subset,header,iflag
  if ( iflag GE 0 ) then for i=0,n_square-1 do $
    if ( subset[i] GT header.badvalue ) then SatData.Data[i].SunZenith = float(subset[i]) * header.slope + header.intercept

  for i=0,n_square-1 do $
    if ( SatData.Data[i].SatAzimuth GT hbad AND SatData.Data[i].SunAzimuth GT hbad ) then $
    SatData.Data[i].RelAzimuth = SatData.Data[i].SatAzimuth - SatData.Data[i].SunAzimuth

  ;###########################################################################################################

  ; Latitude

  subset1 = SatStruct.Latitude[elem-n_side:elem+n_side,line-n_side:line+n_side]
  nn = (1 + 2*n_side)^2
  subset = REFORM(subset1,nn)
  FOR i=0,n_square-1 DO SatData.Data[i].Latitude = FLOAT(subset[i])

  ; Longitude

  subset1 = SatStruct.Longitude[elem-n_side:elem+n_side,line-n_side:line+n_side]
  nn = (1 + 2*n_side)^2
  subset = REFORM(subset1,nn)
  FOR i=0,n_square-1 DO SatData.Data[i].Longitude = FLOAT(subset[i])


END

