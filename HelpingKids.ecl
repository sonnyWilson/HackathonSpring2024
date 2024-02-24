IMPORT STD;
IMPORT Visualizer;

filtersDefLayout := RECORD
  STRING FieldName;  // The name of the field in your dataset to filter on
  STRING Label;      // A user-friendly label for the filter (used in UI components)
  // Additional attributes can be added here based on your filtering requirements
END;

// SOR Data Layout
SORLayout := RECORD
  STRING City;
  STRING County;
END;

// Reference Layout for FIPS Codes
REFLayout := RECORD
  STRING FIPSCode; // FIPS Code as STRING
  STRING CountyName;
END;

// Load the reference dataset (FIPS codes and County names)
CountyFIPSReference := CHOOSEN(DATASET('~.::sorandfib.csv', REFLayout, CSV), 1000);

// Load your main dataset (SOR Data)
SORData := CHOOSEN(DATASET('~.::sororganized.csv', SORLayout, CSV(SEPARATOR(','), TERMINATOR('\n'), HEADING(1))), 500);

// Layout to include FIPS in the SOR Data
SORLayoutWithFIPS := RECORD
  STRING FIPS; // Include FIPS code
  STRING City;
  STRING County;
  
END;

// Join SORData with CountyFIPSReference to match County names and update FIPS codes
TransFibs := JOIN(SORData, CountyFIPSReference,
                  STD.Str.ToUpperCase(LEFT.County) = STD.Str.ToUpperCase(RIGHT.CountyName), // Match County names
                  TRANSFORM(SORLayoutWithFIPS,
                            SELF.FIPS := RIGHT.FIPSCode, // Update FIPS from the reference dataset
                            SELF.County := LEFT.County,
                            SELF.City := LEFT.City),
                  INNER); // Use INNER JOIN to only include matched records

OUTPUT(TransFibs, NAMED('TransFibs'));                  

// Aggregate the transformed data by FIPS codes to count records per FIPS
// Aggregate the data by FIPS code to get a count of records per FIPS code
AggregatedDataByFIPS := TABLE(TransFibs, {FIPS, CountOfRecords := COUNT(GROUP)}, FIPS);

OUTPUT(AggregatedDataByFIPS, NAMED('AggregatedDataCheck'));


// Prepare the data for visualization
// Create the choropleth map visualization
Visualizer.Choropleth.USCounties('myLine',,'AggregatedDataCheck' , , , DATASET([{'paletteID', 'Reds'}], Visualizer.KeyValueDef));

// Output the visualization