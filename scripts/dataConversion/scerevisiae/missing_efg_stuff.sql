-- Copyright [1999-2014] EMBL-European Bioinformatics Institute
-- and Wellcome Trust Sanger Institute
-- 
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
-- 
--      http://www.apache.org/licenses/LICENSE-2.0
-- 
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- For some reason, it is missing !

-- analysis_description

UPDATE analysis_description SET web_data = "{'type' => '_oligo', 'key' => 'array_chip', 'colourset' => 'feature', 'display' =>'off' }", display_label = 'AFFY_UTR_ProbeAlign', displayable = 1, description = 'Genomic alignments for AFFY_UTR arrays' WHERE analysis_id = (SELECT analysis_id FROM analysis WHERE logic_name = 'AFFY_UTR_ProbeAlign');

UPDATE analysis_description SET web_data = "{'type' => '_oligo', 'key' => 'array_chip', 'colourset' => 'feature', 'display' =>'off' }", display_label = 'AFFY_UTR_ProbeTranscriptAlign', displayable = 1, description = 'Transcript alignments for AFFY_UTR arrays' WHERE analysis_id = (SELECT analysis_id FROM analysis WHERE logic_name = 'AFFY_UTR_ProbeTranscriptAlign');

UPDATE analysis_description SET display_label = 'Probe2Transcript Annotation' WHERE analysis_id = (SELECT analysis_id FROM analysis WHERE logic_name = 'Probe2Transcript');

-- status
-- seems fine now !
-- actually not, but add only DISPLAYABLE!
-- INSERT INTO status select a.array_id, 'array', sn.status_name_id  FROM array a, status_name sn WHERE sn.name IN ('DISPLAYABLE','MART_DISPLAYABLE') AND a.vendor='AFFY';
