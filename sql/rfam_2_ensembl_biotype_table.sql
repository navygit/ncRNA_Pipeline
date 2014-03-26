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

DROP TABLE IF EXISTS rfam_2_ensembl_biotype;

CREATE TABLE rfam_2_ensembl_biotype (
       rfam_ac			    VARCHAR(10) NOT NULL,
       rfam_name		    VARCHAR(50) NOT NULL,
       rfam_desc		    VARCHAR(150) NOT NULL,
       embl_feature_key		    VARCHAR(20) NOT NULL,
       embl_feature_class	    VARCHAR(50) NOT NULL,
       biotype			    VARCHAR(40) NOT NULL,
       kingdom			    VARCHAR(40) NULL,
       
       UNIQUE KEY rfam_ac_idx (rfam_ac),
       KEY biotype_idx (biotype)
) COLLATE=latin1_swedish_ci ENGINE=MyISAM;
