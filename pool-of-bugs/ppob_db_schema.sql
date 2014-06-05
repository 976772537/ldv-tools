SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

START TRANSACTION;

-- -----------------------------------------------------
-- 1. Table `environments` - kernels
-- -----------------------------------------------------
DROP TABLE IF EXISTS `environments` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `environments` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`version` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`id`),
	KEY (`version`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 2. Table `modules`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `modules` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `modules` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`id`),
	KEY (`name`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 3. Table `rule_specifications`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `rule_specifications` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `rule_specifications` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`id`),
	KEY (`name`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 4. Table `verifiers`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `verifiers` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `verifiers` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`id`),
	KEY (`name`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 5. Table `traces`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `traces` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `traces` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`svt` LONGTEXT NOT NULL, -- static verifier trace - text
	PRIMARY KEY (`id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 6. Table `sources`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `sources` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `sources` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`path` VARCHAR(255) NOT NULL, -- path to the source file (<kernel_version>/<path_in_kernel>)
	`content` LONGTEXT NOT NULL, -- content of the source file
	PRIMARY KEY (`id`),
	KEY (`path`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 7. Table `traces_sources`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `traces_sources` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `traces_sources` (
	`trace_id` INT NOT NULL,
	`source_id` INT NOT NULL,
	UNIQUE (`trace_id`, `source_id`),
	INDEX `fk_traces_sources_1` (`trace_id` ASC),
	INDEX `fk_traces_sources_2` (`source_id` ASC),
	CONSTRAINT `fk_traces_sources_1`
		FOREIGN KEY (`trace_id`)
		REFERENCES `traces` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION,
	CONSTRAINT `fk_traces_sources_2`
		FOREIGN KEY (`source_id`)
		REFERENCES `sources` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
	)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 8. Table `possible_bugs` (unsafes)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `possible_bugs` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `possible_bugs` (
	`id` INT NOT NULL AUTO_INCREMENT,
	
	`environment_id` INT NOT NULL,
	`module_id` INT NOT NULL,
	`rule_specification_id` INT NOT NULL,
	`verifier_id` INT NOT NULL,
	`trace_id` INT NOT NULL,
	`entry_point` VARCHAR(255) NOT NULL, -- main
	UNIQUE (`environment_id`, `module_id`, `rule_specification_id`, `verifier_id`, `trace_id`),
	
	`verdict` ENUM('False positive', 'True positive', 'Unknown') NOT NULL DEFAULT 'Unknown',
	`comment` MEDIUMTEXT NULL DEFAULT NULL,
	`found_time` DATETIME NULL DEFAULT NULL, -- When this bug was revealed.
	
	PRIMARY KEY (`id`),
	INDEX `fk_possible_bugs_environment` (`environment_id` ASC),
	INDEX `fk_possible_bugs_module` (`module_id` ASC),
	INDEX `fk_possible_bugs_rule_specification` (`rule_specification_id` ASC),
	INDEX `fk_possible_bugs_verifier` (`verifier_id` ASC),
	INDEX `fk_possible_bugs_trace` (`trace_id` ASC),
	CONSTRAINT `fk_possible_bugs_environment`
		FOREIGN KEY (`environment_id`)
		REFERENCES `environments` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION,
	CONSTRAINT `fk_possible_bugs_module`
		FOREIGN KEY (`module_id`)
		REFERENCES `modules` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION,
	CONSTRAINT `fk_possible_bugs_rule_specification`
		FOREIGN KEY (`rule_specification_id`)
		REFERENCES `rule_specifications` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION,
	CONSTRAINT `fk_possible_bugs_verifier`
		FOREIGN KEY (`verifier_id`)
		REFERENCES `verifiers` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION,
	CONSTRAINT `fk_possible_bugs_trace`
		FOREIGN KEY (`trace_id`)
		REFERENCES `traces` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
	)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 9. Table `bugs` (true positives)
-- -----------------------------------------------------
DROP TABLE IF EXISTS `bugs` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `bugs` (
	`id` INT NOT NULL AUTO_INCREMENT,
	
	`possible_bug_id` INT NOT NULL,
	`fix_time` DATETIME NULL DEFAULT NULL, -- When this bug was corrected (time of corresponding commit).
	`author_id` INT NOT NULL, -- Author of the corresponding commit.
	`committer_id` INT NOT NULL,
	`commit` VARCHAR(255) NULL DEFAULT NULL,
	
	PRIMARY KEY (`id`),
	KEY (`possible_bug_id`),
	INDEX `fk_bugs_1` (`possible_bug_id` ASC),
	INDEX `fk_bugs_2` (`author_id` ASC),
	INDEX `fk_bugs_3` (`committer_id` ASC),
	CONSTRAINT `fk_bugs_1`
		FOREIGN KEY (`possible_bug_id`)
		REFERENCES `possible_bugs` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION,
	CONSTRAINT `fk_bugs_2`
		FOREIGN KEY (`author_id`)
		REFERENCES `developers` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION,
	CONSTRAINT `fk_bugs_3`
		FOREIGN KEY (`committer_id`)
		REFERENCES `developers` (`id`)
		ON DELETE CASCADE
		ON UPDATE NO ACTION
	)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- 10. Table `developers`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `developers` ;
SHOW WARNINGS;
CREATE TABLE IF NOT EXISTS `developers` (
	`id` INT NOT NULL AUTO_INCREMENT,
	`name` VARCHAR(255) NOT NULL,
	`email` VARCHAR(255) NOT NULL,
	PRIMARY KEY (`id`),
	KEY (`name`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

COMMIT;

SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
