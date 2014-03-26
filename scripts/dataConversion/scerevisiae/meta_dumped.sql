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

-- MySQL dump 10.11
--
-- Host: mysql-eg-devel-1.ebi.ac.uk    Database: saccharomyces_cerevisiae_core_8_61_2d
-- ------------------------------------------------------
-- Server version	5.1.49-log
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Dumping data for table `meta`
--
-- WHERE:  species_id = 1

INSERT INTO `meta` VALUES (66,1,'assembly.overlapping_regions','0');
INSERT INTO `meta` VALUES (6,1,'genebuild.id','1');
INSERT INTO `meta` VALUES (68,1,'marker.priority','1');
INSERT INTO `meta` VALUES (57,1,'assembly.num_toplevel_seqs','18');
INSERT INTO `meta` VALUES (8,1,'genebuild.start_date','2009-07-SGD');
INSERT INTO `meta` VALUES (9,1,'genebuild.initial_release_date','2009-09');
INSERT INTO `meta` VALUES (90,1,'assembly.date','2011-02');
INSERT INTO `meta` VALUES (10,1,'genebuild.last_geneset_update','2011-02');
INSERT INTO `meta` VALUES (80,1,'genebuild.version','2011-02-EnsemblFungi');
INSERT INTO `meta` VALUES (34,1,'species.taxonomy_id','4932');
INSERT INTO `meta` VALUES (20,1,'species.classification','Ascomycota');
INSERT INTO `meta` VALUES (21,1,'species.classification','Dikarya');
INSERT INTO `meta` VALUES (11,1,'repeat.analysis','Dust');
INSERT INTO `meta` VALUES (91,1,'assembly.name','EF 3');
INSERT INTO `meta` VALUES (92,1,'assembly.default','EF3');
INSERT INTO `meta` VALUES (36,1,'species.division','EnsemblFungi');
INSERT INTO `meta` VALUES (23,1,'species.classification','Eukaryota');
INSERT INTO `meta` VALUES (22,1,'species.classification','Fungi');
INSERT INTO `meta` VALUES (64,1,'repeat.analysis','RepeatMask');
INSERT INTO `meta` VALUES (37,1,'provider.name','SGD');
INSERT INTO `meta` VALUES (26,1,'species.alias','S_cerevisiae');
INSERT INTO `meta` VALUES (14,1,'species.classification','Saccharomyces');
INSERT INTO `meta` VALUES (29,1,'species.ensembl_alias_name','Saccharomyces cerevisiae');
INSERT INTO `meta` VALUES (30,1,'species.alias','Saccharomyces cerevisiae');
INSERT INTO `meta` VALUES (77,1,'species.scientific_name','Saccharomyces cerevisiae');
INSERT INTO `meta` VALUES (31,1,'species.alias','Saccharomyces cerevisiae (Baker\'s yeast)');
INSERT INTO `meta` VALUES (19,1,'species.classification','Saccharomyceta');
INSERT INTO `meta` VALUES (15,1,'species.classification','Saccharomycetaceae');
INSERT INTO `meta` VALUES (16,1,'species.classification','Saccharomycetales');
INSERT INTO `meta` VALUES (17,1,'species.classification','Saccharomycetes');
INSERT INTO `meta` VALUES (18,1,'species.classification','Saccharomycotina');
INSERT INTO `meta` VALUES (12,1,'repeat.analysis','TRF');
INSERT INTO `meta` VALUES (28,1,'species.common_name','baker\'s yeast');
INSERT INTO `meta` VALUES (32,1,'species.ensembl_common_name','baker\'s yeast');
INSERT INTO `meta` VALUES (13,1,'species.classification','cerevisiae');
INSERT INTO `meta` VALUES (39,1,'assembly.mapping','chromosome:EF3#contig');
INSERT INTO `meta` VALUES (65,1,'assembly.coverage_depth','high');
INSERT INTO `meta` VALUES (38,1,'provider.url','http://www.yeastgenome.org/');
INSERT INTO `meta` VALUES (69,1,'genebuild.method','import');
INSERT INTO `meta` VALUES (81,1,'sample.variation_param','s02-316976');
INSERT INTO `meta` VALUES (82,1,'sample.variation_text','s02-316976');
INSERT INTO `meta` VALUES (76,1,'species.production_name','saccharomyces_cerevisiae');
INSERT INTO `meta` VALUES (41,1,'genebuild.level','toplevel');
INSERT INTO `meta` VALUES (42,1,'transcriptbuild.level','toplevel');
INSERT INTO `meta` VALUES (43,1,'exonbuild.level','toplevel');
INSERT INTO `meta` VALUES (44,1,'repeat_featurebuild.level','toplevel');
INSERT INTO `meta` VALUES (45,1,'dna_align_featurebuild.level','toplevel');
INSERT INTO `meta` VALUES (46,1,'protein_align_featurebuild.level','toplevel');
INSERT INTO `meta` VALUES (47,1,'simple_featurebuild.level','toplevel');
INSERT INTO `meta` VALUES (78,1,'species.short_name','yeast');
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2011-02-09 15:26:13
