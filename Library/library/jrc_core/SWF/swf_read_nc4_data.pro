; docformat:'rst'

;+
; :Author:
;   
;   Frédéric Mélin (European Commission/JRC/IES)
;
; :version: 1
;   
; :History:
; 
;   Created by Frédéric Mélin, 02/2016
;   
; :Categories:
; 
;   I/O routines
;   
; :Description:
; 
; Reads netcdf-4 data.
; 
; :Examples:
;
;   Example syntax::
;     read_nc4_data,filename,vname,header,data,iflag
;   
; :Pre:
;   
; :Requires:
; 
;   IDL 8
;   
; :Returns:
;   data set (NB: the data set needs to be within the file).
;   header structure containing following fields::
;   
;     header = { name:vname, longname:' ',units: ' ', slope:1., intercept:0., badvalue:-999999. }
;     
; :Params:
; 
;   filename: in, required, type=string
;		input file name
;   vname: in, required, type=string
;		variable name
;	header: out, required, type=structure
;		attributes associated with the data read.
;	data: out, required, type=array
;		data returned
;	iflag: out, required, type=byte
;		diagnostic value; -1 if reading failed, 1 otherwise
;         
;-


PRO swf_read_nc4_data,filename,vname,header,data,iflag

scale_factor = 1.
add_offset = 0.
hbad = -32767.

iflag = -1

!QUIET=1

attrlist = [' ']

fid = H5F_OPEN(filename)

data_id = H5D_OPEN(fid,vname)

IF ( data_id GE 0 ) THEN BEGIN ; ----------------------------------

header = { name:vname, longname:' ',units: ' ', slope:1., intercept:0., badvalue:-999999. }

nattrs = H5A_GET_NUM_ATTRS(data_id) ; number of attributes

FOR idx=0,nattrs-1 DO BEGIN

attr_id = H5A_OPEN_IDX(data_id,idx)
res = H5A_GET_NAME(attr_id)
H5A_CLOSE,attr_id

attrlist = [attrlist,res]
ENDFOR

ii = WHERE ( attrlist EQ 'long_name',cnt )
IF ( cnt EQ 1 ) THEN BEGIN

  attr_id = H5A_OPEN_NAME(data_id,'long_name')

  res = H5A_READ(attr_id)
  H5A_CLOSE,attr_id
  header.longname = res[0]
ENDIF

ii = WHERE ( attrlist EQ 'scale_factor',cnt )
IF ( cnt EQ 1 ) THEN BEGIN
  attr_id = H5A_OPEN_NAME(data_id,'scale_factor')

  res = H5A_READ(attr_id)
  H5A_CLOSE,attr_id
  header.slope = res[0]
ENDIF

ii = WHERE ( attrlist EQ 'add_offset',cnt )
IF ( cnt EQ 1 ) THEN BEGIN
  attr_id = H5A_OPEN_NAME(data_id,'add_offset')

  res = H5A_READ(attr_id)
  H5A_CLOSE,attr_id
  header.intercept = res[0]
ENDIF

ii = WHERE ( attrlist EQ '_FillValue',cnt )
IF ( cnt EQ 1 ) THEN BEGIN
  attr_id = H5A_OPEN_NAME(data_id,'_FillValue')

  res = H5A_READ(attr_id)
  H5A_CLOSE,attr_id
  header.badvalue = res[0]
ENDIF

ii = WHERE ( attrlist EQ 'units',cnt )
IF ( cnt EQ 1 ) THEN BEGIN
  attr_id = H5A_OPEN_NAME(data_id,'units')

  res = H5A_READ(attr_id)
  H5A_CLOSE,attr_id
  header.units = res[0]
ENDIF


dataspace_id = H5D_GET_SPACE(data_id)

dimensions = H5S_GET_SIMPLE_EXTENT_DIMS(dataspace_id)

data = H5D_READ(data_id) ; read actual data

H5S_CLOSE, dataspace_id

iflag = 1 ; variable read

ENDIF
H5D_CLOSE, data_id

H5F_CLOSE, fid


END
