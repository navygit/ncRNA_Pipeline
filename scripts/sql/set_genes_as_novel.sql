UPDATE gene SET status = 'NOVEL' WHERE biotype NOT IN ('protein_coding','pseudogene');
UPDATE transcript SET status = 'NOVEL' WHERE biotype NOT IN ('protein_coding','pseudogene');
