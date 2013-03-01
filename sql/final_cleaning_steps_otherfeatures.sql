-- Remove Submit* analysis entries

DELETE FROM analysis WHERE logic_name like 'Submit%';

-- Remove pipeline tables

DROP TABLE IF EXISTS input_id_analysis;

DROP TABLE IF EXISTS input_id_type_analysis;

DROP TABLE IF EXISTS job;

DROP TABLE IF EXISTS job_status;

DROP TABLE IF EXISTS rule_conditions;

DROP TABLE IF EXISTS rule_goal;

-- Remove Genes etc.

truncate gene;

truncate transcript;

truncate translation;

truncate exon;

truncate exon_transcript;

truncate supporting_feature;

DELETE FROM meta_coord WHERE table_name != 'dna_align_feature';

DELETE FROM meta WHERE meta_value = 'toplevel';

INSERT INTO meta (species_id,meta_key,meta_value) VALUES (1,'dna_align_feature.level','toplevel');

