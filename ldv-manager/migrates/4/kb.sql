SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';


-- -----------------------------------------------------
-- Table `kb`
-- -----------------------------------------------------
SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `kb` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(50) NULL DEFAULT NULL ,
  `public` TINYINT(1) NOT NULL DEFAULT TRUE ,
  `task_attributes` VARCHAR(2000) NULL DEFAULT NULL ,
  `model` VARCHAR(500) NULL DEFAULT NULL ,
  `module` VARCHAR(500) NULL DEFAULT NULL ,
  `main` VARCHAR(500) NULL DEFAULT NULL ,
  `error_trace` MEDIUMTEXT NULL DEFAULT NULL ,
  `script` TEXT NULL DEFAULT NULL ,
  `verdict` ENUM('False positive', 'True positive', 'Unknown', 'Inconclusive') NOT NULL DEFAULT 'Unknown' ,
  `tags` TEXT NULL DEFAULT NULL ,
  `comment` MEDIUMTEXT NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `results_kb`
-- -----------------------------------------------------
SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `results_kb` (
  `trace_id` INT(10) UNSIGNED NOT NULL ,
  `kb_id` INT NOT NULL ,
  `fit` ENUM('Exact', 'Require script', 'TBD') NOT NULL DEFAULT 'TBD' ,
  PRIMARY KEY (`trace_id`, `kb_id`) ,
  INDEX `fk_results_kb_1` (`kb_id` ASC) ,
  INDEX `fk_results_kb_2` (`trace_id` ASC) ,
  CONSTRAINT `fk_results_kb_1`
    FOREIGN KEY (`kb_id` )
    REFERENCES `kb` (`id` )
    ON DELETE CASCADE
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_results_kb_2`
    FOREIGN KEY (`trace_id` )
    REFERENCES `traces` (`id` )
    ON DELETE CASCADE
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `results_kb_calculated`
-- -----------------------------------------------------
SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `results_kb_calculated` (
  `trace_id` INT(10) UNSIGNED NOT NULL ,
  `Verdict` ENUM('False positive', 'True positive', 'Unknown', 'Inconclusive') NOT NULL DEFAULT 'Unknown' ,
  `Tags` TEXT NULL DEFAULT NULL ,
  PRIMARY KEY (`trace_id`) ,
  INDEX `fk_results_kb_calculated_1` (`trace_id` ASC) ,
  CONSTRAINT `fk_results_kb_calculated_1`
    FOREIGN KEY (`trace_id` )
    REFERENCES `traces` (`id` )
    ON DELETE CASCADE
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

delimiter //

-- Calculate a resulting Verdict for two given Verdicts by means of the
-- following table:
--     TP  FP  UNK INC
-- TP  TP  INC TP  INC
-- FP  INC FP  FP  INC
-- UNK TP  FP  UNK INC
-- INC INC INC INC INC
-- where TP is True positive, FP is False positive, UNK is Unknown and INC is 
-- Inconclusive.
DROP FUNCTION IF EXISTS joinVerdicts//
SHOW WARNINGS//
CREATE FUNCTION joinVerdicts(
  verdictFirst enum('False positive', 'True positive', 'Unknown', 'Inconclusive')
  , verdictSecond enum('False positive', 'True positive', 'Unknown', 'Inconclusive')) 
  RETURNS enum('False positive', 'True positive', 'Unknown', 'Inconclusive')
BEGIN
  -- This corresponds to the last column of the table given above.
  IF verdictSecond LIKE 'Inconclusive'
    THEN RETURN verdictSecond;
  -- This - to the previous to the last column.
  ELSEIF verdictSecond LIKE 'Unknown'
    THEN RETURN verdictFirst;
  -- This - to the third row.
  ELSEIF verdictFirst LIKE 'Unknown'
    THEN RETURN verdictSecond;
  -- This - to two first diagonal elements.
  ELSEIF verdictFirst LIKE verdictSecond
    THEN RETURN verdictFirst;
  -- This - to the rest (all 'Inconclusive' from two first columns).
  ELSE RETURN 'Inconclusive';
  END IF; 
END//
SHOW WARNINGS//

-- Recalculate extended KB cache after a new record appears into KB cache. 
DROP TRIGGER IF EXISTS kb_cache_insert//
SHOW WARNINGS//
CREATE TRIGGER kb_cache_insert AFTER INSERT ON results_kb
FOR EACH ROW BEGIN
  -- Whether there is a corresponding record in extended KB cache or not.
  IF (SELECT COUNT(*) 
     FROM results_kb_calculated 
     WHERE results_kb_calculated.trace_id = NEW.trace_id) = 0
  -- If there isn't, then create it filling with new KB verdict and tags.
  THEN INSERT INTO results_kb_calculated(trace_id, Verdict, Tags)
       VALUES(NEW.trace_id, (SELECT verdict FROM kb WHERE kb.id = NEW.kb_id)
         , (SELECT tags FROM kb WHERE kb.id = NEW.kb_id));
  -- If there is, then recalculate Verdict on the basis of previous value of
  -- Verdict and a new KB verdict. Resulting Tags is just concation of previous
  -- Tags and new KB tags. 
  ELSE UPDATE results_kb_calculated 
       SET Verdict = (SELECT joinVerdicts(
         (SELECT kb.verdict FROM kb WHERE kb.id = NEW.kb_id), results_kb_calculated.Verdict))
         , Tags = (SELECT CONCAT(results_kb_calculated.Tags, ';'
           , (SELECT kb.tags FROM kb WHERE kb.id = NEW.kb_id)))
       WHERE results_kb_calculated.trace_id = NEW.trace_id;
  END IF;
END//
SHOW WARNINGS//

-- Calculate a resulting Verdict for a given Unsafe by means of the following
-- table:
--     TP  FP  UNK
-- TP  TP  INC TP 
-- FP  INC FP  FP 
-- UNK TP  FP  UNK
-- where TP is True positive, FP is False positive, UNK is Unknown and INC is 
-- Inconclusive (the last cannot be specified by a user).
DROP FUNCTION IF EXISTS calculateVerdict//
SHOW WARNINGS//
CREATE FUNCTION calculateVerdict(trace_id INT(10))
  RETURNS enum('False positive', 'True positive', 'Unknown', 'Inconclusive')
BEGIN
  -- There is 'True positive' verdict among a set of verdicts for a given
  -- Unsafe (it corresponds to the first row or column of the table above).
  IF (SELECT COUNT(*)
      FROM results_kb LEFT JOIN kb ON results_kb.kb_id = kb.id
      WHERE results_kb.trace_id = trace_id AND kb.verdict LIKE 'True positive') != 0
  THEN
    -- There isn't 'False positive' at all so the resulting Verdict is
    -- 'True positive'.
    IF (SELECT COUNT(*)
        FROM results_kb LEFT JOIN kb ON results_kb.kb_id = kb.id
        WHERE results_kb.trace_id = trace_id AND kb.verdict LIKE 'False positive') = 0
    THEN RETURN 'True positive';
    -- Both 'True positive' and 'False positive' leads to 'Inconclusive'.
    ELSE RETURN 'Inconclusive';
    END IF;
  -- There is 'False positive' and there isn't 'True positive'.
  ELSEIF (SELECT COUNT(*)
          FROM results_kb LEFT JOIN kb ON results_kb.kb_id = kb.id
          WHERE results_kb.trace_id = trace_id AND kb.verdict LIKE 'False positive') != 0
  THEN RETURN 'False positive';
  -- There is neither 'False positive' nor 'True positive', just 'Unknown'.
  ELSE RETURN 'Unknown';
  END IF;
END//
SHOW WARNINGS//

-- Obtain all relevant tags for a given Unsafe.
DROP FUNCTION IF EXISTS calculateTags//
SHOW WARNINGS//
CREATE FUNCTION calculateTags(trace_id INT(10))
  RETURNS TEXT
BEGIN
  -- Extend the maximum length of string obtained by means of GROUP_CONCAT. 
  SET SESSION group_concat_max_len = @@max_allowed_packet;
  RETURN (SELECT GROUP_CONCAT(kb.tags SEPARATOR ';') FROM results_kb LEFT JOIN kb ON results_kb.kb_id = kb.id WHERE results_kb.trace_id = trace_id GROUP BY results_kb.trace_id);
END//
SHOW WARNINGS//

-- Recalculate extended KB cache after a record is deleted from KB cache.
DROP TRIGGER IF EXISTS kb_cache_delete//
SHOW WARNINGS//
CREATE TRIGGER kb_cache_delete AFTER DELETE ON results_kb
FOR EACH ROW BEGIN
  -- Check whether there is something relevant left after a record is deleted.
  IF (SELECT COUNT(*) 
     FROM results_kb 
     WHERE results_kb.trace_id = OLD.trace_id) = 0
  -- If there isn't, then delete corresponding record from extended KB cache.
  THEN DELETE FROM results_kb_calculated WHERE results_kb_calculated.trace_id = OLD.trace_id;
  -- Otherwise recalculate Verdict and Tags on the basis of all relevant
  -- verdicts and tags. 
  ELSE UPDATE results_kb_calculated 
       SET Verdict = (SELECT calculateVerdict(OLD.trace_id))
         , Tags = (SELECT calculateTags(OLD.trace_id))
       WHERE results_kb_calculated.trace_id = OLD.trace_id;
  END IF;
END//
SHOW WARNINGS//

-- Recalculate extended KB cache after a verdict or/and tag is changed in KB.
DROP TRIGGER IF EXISTS kb_result_update//
SHOW WARNINGS//
CREATE TRIGGER kb_result_update AFTER UPDATE ON kb
FOR EACH ROW BEGIN
  IF NEW.verdict NOT LIKE OLD.verdict OR NEW.tags NOT LIKE OLD.tags
  -- Recalculate Verdict and Tags on the basis of all relevant verdicts and
  -- tags.
  THEN UPDATE results_kb, results_kb_calculated
       SET Verdict = (SELECT calculateVerdict(results_kb.trace_id))
         , Tags = (SELECT calculateTags(results_kb_calculated.trace_id))
       WHERE results_kb.trace_id = results_kb_calculated.trace_id; 
  END IF;
END//
SHOW WARNINGS//

delimiter ;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
