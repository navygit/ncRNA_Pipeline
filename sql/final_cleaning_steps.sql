-- Remove Submit* analysis entries

DELETE FROM analysis WHERE logic_name like 'Submit%';

-- Remove pipeline tables

DROP TABLE input_id_analysis;

DROP TABLE input_id_type_analysis;

DROP TABLE job;

DROP TABLE job_status;

DROP TABLE rule_conditions;

DROP TABLE rule_goal;

