@..\wrapper\structure_definition
FUNCTION L2JRCSeawifs_Summary_Operator::getInternalOperator, mainApp, tempDir, sensorCode

  return, obj_new('L2Seawifs_Operator', mainApp, tempDir, sensorCode=sensorCode)

END

PRO L2JRCSeawifs_Summary_Operator::CleanUp

  self->L2Summary_Operator::Cleanup
  
END

FUNCTION L2JRCSeawifs_Summary_Operator::init, application, workingDir, periodType, mask=mask, geoData=geoData, fileName=fileName, bandToExportList=bandToExportList, $
  REMOVE_EXTENSION=REMOVE_EXTENSION, ENVITYPE=ENVITYPE, OPEN=OPEN, COPY=COPY, sensorCode=sensorCode
  
  if not (self -> L2Summary_Operator :: init(application, workingDir, periodType, bandToExportList=bandToExportList, fileName=fileName, $
    REMOVE_EXTENSION=REMOVE_EXTENSION, OPEN=OPEN, COPY=COPY, ENVITYPE=ENVITYPE, sensorCode=sensorCode)) then return, 0
  self.sensorCode='JRCSeawifs'
  return, 1
  
END

PRO L2JRCSeawifs_Summary_Operator__Define

  Struct = { L2JRCSeawifs_Summary_Operator , $
    Inherits  L2Summary_Operator $
  }
  
END