FUNCTION extract_ungeoref_L2_parameter_global_Meris_D, periodType, $
  date, year, roiCode, roiArchiveCode, inputDir, outputDir, $
  parCode, day=day, outTitle=outTitle, refRoi=refRoi, elabName=elabName, $
  NOTFOUND=NOTFOUND, GETCHLVAR=GETCHLVAR, GETMAPINFO=GETMAPINFO, $
  outMapInfo=outMapInfo, SETNAN=SETNAN, NORANGE=NORANGE, $
  FULLPATH=FULLPATH, EXPORTMAP=EXPORTMAP, report=report, $
  READ_FROM_DB=READ_FROM_DB, GLOBTYPE=GLOBTYPE, DUPLICATE=DUPLICATE
  
  COMMON smurffCB, mainApp
  
  roi=roiArchiveCode
  NOTFOUND=0
  fs=mainApp->getFileSystem()
  utility=mainApp->getUtility()
  
  tempDir=mainApp->getKeyValue('TEMP_DIR')
  ignoreValue=float(mainApp->getKeyValue('NAN_VALUE'))
  
  L2Op=obj_new('L2Meris_Operator', mainApp, tempDir, sensorCode='Meris')
  
  data=L2Op->importBand(periodType, parCode, date, year, roiCode, roiArchiveCode, inputDir, NF=NF, $
    day=day, targetMapInfo=targetMapInfo, report=report, DUPLICATE=DUPLICATE)
  return, data
    
END