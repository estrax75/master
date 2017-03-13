; GLOBAL ATTRIBS from AVHRR/NASA
function getJRCHeader_v1_6

  date=systime()

  return, { $
    cdm_data_type:['cdm_data_type', 'Grid'], $
    cdr_variable:['cdr_variable', 'to_be_filled'], $
    ;title: ['title', 'JRC daily FAPAR with AVHRR'], $
    date_created: ['date_created', 'to_be_filled'], $ ;2014-02-12T13:39:25Z', $
    Process: ['process', 'to_be_filled'], $
    PostProcessingVersion:['postProcessingVersion', 'v1r0'], $
    product_version:['product_version', 'v1r0'], $
    grid_mapping_name:['grid_mapping_name', 'latitude_longitude'], $
    geospatial_lat_max: ['geospatial_lat_max', '90.0 degrees_north'], $
    geospatial_lat_min: ['geospatial_lat_min', '-90.0 degrees_north'], $
    geospatial_lon_max: ['geospatial_lon_max', '180.0 degrees_east'], $
    geospatial_lon_min: ['geospatial_lon_min', '-180.0 degrees_east'], $
    geospatial_lat_resolution: ['geospatial_lat_resolution', '0.05 degrees'], $
    geospatial_lon_resolution: ['geospatial_lon_resolution', '0.05 degrees'], $
    geospatial_reference:['geospatial_reference', 'EPSG:4326'], $
    time_coverage_start:['time_coverage_start', 'to_be_filled'], $;1999-06-07T00:00:00Z', $
    time_coverage_end:['time_coverage_end', 'to_be_filled'], $1999-06-07T23:59:00Z', $
    id:['id', 'n_a'], $ ;'AVHRR-Land_v004_AVH09C1_NOAA-14_19990607_c20140212133925.nc' filename, $
    ;InputDataType:['InputDataType','GAC'], $
    institution:['institution', 'European Commission - Joint Research Center'], $
    institution_url:['institution_url', 'ec.europa.eu/jrc'], $
    institution_contact:['institution_contact','Dr. Nadine Gobron (nadine.gobron@jrc.ec.europa.eu)'], $
    license:['license', '(c) European Commission 2016'], $
    Satellite:['satellite', 'to_be_filled'], $ ;NOAA-14', $
    sensor:['sensor', 'AVHRR > Advanced Very High Resolution Radiometer'], $
    title:['title', 'to_be_filled'], $
    keywords:['keywords', 'EARTH SCIENCE , LAND SURFACE , SURFACE RADIATIVE PROPERTIES , REFLECTANCE , ECV'] $
  }

end