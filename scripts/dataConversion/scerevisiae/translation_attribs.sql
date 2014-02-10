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

INSERT INTO translation_attrib (translation_id, attrib_type_id, value)
SELECT translation_id, 144, '9 9 E'
FROM translation_stable_id
WHERE stable_id = 'YOR031W';

INSERT INTO translation_attrib (translation_id, attrib_type_id, value)
SELECT translation_id, 144, '142 142 W'
FROM translation_stable_id
WHERE stable_id = 'YER109C';

