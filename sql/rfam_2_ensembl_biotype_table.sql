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
