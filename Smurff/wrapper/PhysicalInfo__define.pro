FUNCTION PhysicalInfo::getPhysical, physicalCode

  physical=obj_new('Physical')
  idx=self->getIndexByCode(physicalCode)
  fNames=self->getFullFileNames()
  res = physical->fillDataFromXMLFile(fNames[idx])
  return, physical  

END

PRO PhysicalInfo::buildForApp

  modis=obj_new('satellite')
  modis->setArchiveRoot, 'E:\data\mariomi\application\oxyrisk\input\vol15\modisa\archive\europe\l3smi'
  modis->setDisplayname, 'modis'
  modis->setCode, 'modis'
  modis->setFiletype, 'JRC'
  modis->setParametersList, ['412', '443', '488', '531', '551', '667', '001', '002']
  modis->setDescription, 'modis data files'
  modisfileName='E:\data\mariomi\application\oxyrisk\resource\modis_satellite.xml'
  modis->xmlWriteStructList, modisfileName
  obj_destroy, modis

  seawifs=obj_new('satellite')
  seawifs->setArchiveroot, 'E:\data\mariomi\application\oxyrisk\input\vol15\seawifs\archive\europe\l3smi'
  seawifs->setDisplayname, 'SeaWiFS'
  seawifs->setCode, 'seawifs'
  seawifs->setFileType, 'SeaWifs'
  seawifs->setParametersList, ['412', '443', '490', '510', '555', '670', '001', '002']
  seawifs->setDescription, 'seawifs data files'
  seawifsfileName='E:\data\mariomi\application\oxyrisk\resource\seawifs_satellite.xml'
  seawifs->xmlWriteStructList, seawifsfileName
  obj_destroy, modis
  
END

PRO PhysicalInfo::testForApp

  modis=obj_new('satellite')
  modisfileName='E:\data\mariomi\application\oxyrisk\configuration\modis_satellite.xml'
  modis->parse, modisfileName
  modis->streamPrint

  obj_destroy, modis
  
  seawifs=obj_new('satellite')
  seawifsName='E:\data\mariomi\application\oxyrisk\configuration\seawifs_satellite.xml'
  seawifs->ParseFile, seawifsfileName
  seawifs->streamPrint
  obj_destroy, seawifs
  
END

FUNCTION PhysicalInfo::getFullElement, code, INDEX=INDEX

 element=self->getListStructDef()
 if n_elements(code) ne 1 then elementIndex=INDEX else elementIndex=self->getIndexByCode(code) 
 thisList=self->getList()
 element.code=thisList.code[elementIndex]
 element.displayname=thisList.displayname[elementIndex]
 element.fullfilename=thisList.fullfilename[elementIndex]

END

FUNCTION PhysicalInfo::getIndexByCode, code

 codes=self->getCodes()
 idx=(where(code eq codes))[0]
 return, idx

END

FUNCTION PhysicalInfo::buildFullFieldList, simpleList

  baseStruct=self->getListStructDef()
  nElem=n_elements(simpleList)
  list=replicate(baseStruct, nElem)
  for i=0, nElem-1 do begin
    list[i].code=simpleList[i]
    list[i].displayname=simpleList[i]
    list[i].fullfilename=simpleList[i]
  endfor
  return, list
  
END

FUNCTION  PhysicalInfo::getVersion

  return, '1.0'
  
END

FUNCTION PhysicalInfo::buildRecordFromElement, index, structElement

  code=structElement
  displayName=structElement
  fullfilename=''
  record=[code, displayName, fullfilename]
  return, record
  
END

FUNCTION PhysicalInfo::getDisplayNames

  thisList=self->getList()
  return, thisList[*].displayName
  
END

FUNCTION PhysicalInfo::getCodes

  thisList=self->getList()
  return, thisList[*].code
  
END

FUNCTION PhysicalInfo::getFullFileNames

  thisList=self->getList()
  return, thisList[*].fullfilename
  
END

PRO PhysicalInfo::streamPrint

  print, '***********************'
  print, '**Start of<',OBJ_CLASS(self),'>**'
  
  print, '**** fileName:<', self.fileName,'>'
  thisList=self->getList()
  for i=0, n_elements(thisList)-1 do begin
    print, '**element n.<', strcompress(i, /REMOVE),'>'
    print, '**** code:<', thisList[i].code,'>'
    print, '**** displayName:<', thisList[i].displayName,'>'
    print, '**** fullfilename:<', thisList[i].fullfilename,'>'
    print, '**'
  endfor
  
  print, '***********************'
  print, '**End of:<',OBJ_CLASS(self),'>**'
  
END

FUNCTION PhysicalInfo::getListStructDef

  struct = { code:'',$
    displayName:'', $
    fullfilename: '' $
    }
    
  return, struct
  
END

FUNCTION PhysicalInfo::buildListStruct, fieldsInfo, NOFILL=NOFILL

  thisStruct=self->getListStructDef()
  if ~keyword_set(NOFILL) gt 0 then begin
    thisStruct.code=fieldsInfo[0]
    thisStruct.displayName=fieldsInfo[1]
    thisStruct.fullfilename=fieldsInfo[2]
  endif
  return, thisStruct
  
END

FUNCTION PhysicalInfo::listFieldsExpectedNumber

  return, n_tags(self->buildListStruct(/NOFILL))
  
END

FUNCTION PhysicalInfo::init, application, filename, mode=mode

  if not(self -> ConfigurableData::init(application, filename, mode=mode)) then return, 0
  return, 1
  
END

PRO PhysicalInfo::cleanUp

  self -> ConfigurableData::cleanUp
  
END

PRO PhysicalInfo__Define

  Struct = { PhysicalInfo , $
    Inherits ConfigurableData $
    }
    
END