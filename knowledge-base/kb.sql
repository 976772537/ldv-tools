SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

-- -----------------------------------------------------
-- Table `kb`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `kb` ;

CREATE  TABLE IF NOT EXISTS `kb` (
  `id` INT NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(50) NOT NULL ,
  `public` TINYINT(1) NOT NULL DEFAULT TRUE ,
  `task_attributes` VARCHAR(2000) NULL DEFAULT NULL ,
  `model` VARCHAR(500) NULL DEFAULT NULL ,
  `module` VARCHAR(500) NULL DEFAULT NULL ,
  `main` VARCHAR(500) NULL DEFAULT NULL ,
  `error_trace` MEDIUMTEXT NULL DEFAULT NULL ,
  `script` TEXT NULL DEFAULT NULL ,
  `verdict` ENUM('False positive', 'True positive', 'Unknown', 'Inconclusive') NOT NULL DEFAULT 'Unknown' ,
  `tags` TEXT NULL DEFAULT NULL ,
  PRIMARY KEY (`id`) ,
  UNIQUE INDEX `ID` (`name` ASC, `public` ASC) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;


-- -----------------------------------------------------
-- Table `results_kb`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `results_kb` ;

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
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_results_kb_2`
    FOREIGN KEY (`trace_id` )
    REFERENCES `traces` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
