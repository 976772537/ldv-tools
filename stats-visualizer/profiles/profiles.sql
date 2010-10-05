SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

CREATE SCHEMA IF NOT EXISTS `profiles` DEFAULT CHARACTER SET latin1 COLLATE latin1_swedish_ci ;
SHOW WARNINGS;
USE `profiles`;

-- -----------------------------------------------------
-- Table `profiles`.`profiles`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`profiles` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`profiles` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` VARCHAR(45) NOT NULL DEFAULT 'default' ,
  `user` VARCHAR(100) NOT NULL DEFAULT 'default' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`pages`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`pages` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`pages` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` ENUM('Index', 'Task id', 'Task name', 'Task description', 'Task user name', 'Task timestamp', 'Toolset version', 'Toolset verifier', 'Driver name', 'Driver origin', 'Environment version', 'Environment kind', 'Rule name', 'Module', 'Entry point', 'Result', 'Result ok', 'Result unsafe', 'Result unknown', 'Verifier', 'Error trace', 'BCE', 'DEG', 'DSCV', 'RI', 'RCV', 'BCE ok', 'BCE fail', 'BCE time', 'BCE loc', 'BCE description', 'BCE problems', 'DEG ok', 'DEG fail', 'DEG time', 'DEG loc', 'DEG description', 'DEG problems') NOT NULL DEFAULT 'index' ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`profiles_pages`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`profiles_pages` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`profiles_pages` (
  `profile_id` INT UNSIGNED NOT NULL DEFAULT 0 ,
  `page_id` INT UNSIGNED NOT NULL DEFAULT 0 ,
  PRIMARY KEY (`profile_id`, `page_id`) ,
  INDEX `fk_profiles_pages_1` (`profile_id` ASC) ,
  INDEX `fk_profiles_pages_2` (`page_id` ASC) ,
  CONSTRAINT `fk_profiles_pages_1`
    FOREIGN KEY (`profile_id` )
    REFERENCES `profiles`.`profiles` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_profiles_pages_2`
    FOREIGN KEY (`page_id` )
    REFERENCES `profiles`.`pages` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`aux_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`aux_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`aux_info` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `order` INT UNSIGNED NOT NULL ,
  `presence` TINYINT(1) NOT NULL DEFAULT FALSE ,
  `require_unique_key` TINYINT(1) NOT NULL DEFAULT FALSE ,
  PRIMARY KEY (`id`) )
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`launch_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`launch_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`launch_info` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` ENUM('Task id', 'Task name', 'Task description', 'Task user name', 'Task timestamp', 'Toolset version', 'Toolset verifier', 'Driver name', 'Driver origin', 'Environment version', 'Environment kind', 'Rule name', 'Module', 'Entry point') NOT NULL ,
  `aux_info_id` INT UNSIGNED NOT NULL ,
  `desc` TINYINT(1) NOT NULL DEFAULT FALSE ,
  `hide` TINYINT(1) NOT NULL DEFAULT FALSE ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_launch_info_1` (`aux_info_id` ASC) ,
  CONSTRAINT `fk_launch_info_1`
    FOREIGN KEY (`aux_info_id` )
    REFERENCES `profiles`.`aux_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`pages_launch_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`pages_launch_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`pages_launch_info` (
  `pages_id` INT UNSIGNED NOT NULL DEFAULT 0 ,
  `launch_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`pages_id`, `launch_info_id`) ,
  INDEX `fk_pages_launch_info_1` (`pages_id` ASC) ,
  CONSTRAINT `fk_pages_launch_info_1`
    FOREIGN KEY (`pages_id` )
    REFERENCES `profiles`.`pages` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_pages_launch_info_2`
    FOREIGN KEY (`launch_info_id` )
    REFERENCES `profiles`.`launch_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`verification_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`verification_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`verification_info` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` ENUM('Result', 'Verifier', 'Error trace') NOT NULL ,
  `aux_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_verification_info_1` (`aux_info_id` ASC) ,
  CONSTRAINT `fk_verification_info_1`
    FOREIGN KEY (`aux_info_id` )
    REFERENCES `profiles`.`aux_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`tools_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`tools_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`tools_info` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` ENUM('BCE', 'DEG', 'DSCV', 'RI', 'RCV') NOT NULL ,
  `aux_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_tools_info_1` (`aux_info_id` ASC) ,
  CONSTRAINT `fk_tools_info_1`
    FOREIGN KEY (`aux_info_id` )
    REFERENCES `profiles`.`aux_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`tool_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`tool_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`tool_info` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` ENUM('Ok', 'Fail', 'Time', 'LOC', 'Description', 'Problems') NOT NULL ,
  `aux_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_tool_info_1` (`aux_info_id` ASC) ,
  CONSTRAINT `fk_tool_info_1`
    FOREIGN KEY (`aux_info_id` )
    REFERENCES `profiles`.`aux_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`result_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`result_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`result_info` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `name` ENUM('Safe', 'Unsafe', 'Unknown') NOT NULL ,
  `aux_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_result_info_1` (`aux_info_id` ASC) ,
  CONSTRAINT `fk_result_info_1`
    FOREIGN KEY (`aux_info_id` )
    REFERENCES `profiles`.`aux_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`pages_verification_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`pages_verification_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`pages_verification_info` (
  `pages_id` INT UNSIGNED NOT NULL DEFAULT 0 ,
  `verification_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`pages_id`, `verification_info_id`) ,
  INDEX `fk_pages_verification_info_1` (`pages_id` ASC) ,
  INDEX `fk_pages_verification_info_2` (`verification_info_id` ASC) ,
  CONSTRAINT `fk_pages_verification_info_1`
    FOREIGN KEY (`pages_id` )
    REFERENCES `profiles`.`pages` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_pages_verification_info_2`
    FOREIGN KEY (`verification_info_id` )
    REFERENCES `profiles`.`verification_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`verification_result_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`verification_result_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`verification_result_info` (
  `verification_info_id` INT UNSIGNED NOT NULL ,
  `result_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`result_info_id`, `verification_info_id`) ,
  INDEX `fk_verification_result_info_1` (`verification_info_id` ASC) ,
  INDEX `fk_verification_result_info_2` (`result_info_id` ASC) ,
  CONSTRAINT `fk_verification_result_info_1`
    FOREIGN KEY (`verification_info_id` )
    REFERENCES `profiles`.`verification_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_verification_result_info_2`
    FOREIGN KEY (`result_info_id` )
    REFERENCES `profiles`.`result_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`tools_tool_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`tools_tool_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`tools_tool_info` (
  `tools_info_id` INT UNSIGNED NOT NULL ,
  `tool_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`tools_info_id`, `tool_info_id`) ,
  INDEX `fk_tools_tool_info_1` (`tools_info_id` ASC) ,
  INDEX `fk_tools_tool_info_2` (`tool_info_id` ASC) ,
  CONSTRAINT `fk_tools_tool_info_1`
    FOREIGN KEY (`tools_info_id` )
    REFERENCES `profiles`.`tools_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_tools_tool_info_2`
    FOREIGN KEY (`tool_info_id` )
    REFERENCES `profiles`.`tool_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`pages_tools_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`pages_tools_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`pages_tools_info` (
  `pages_id` INT UNSIGNED NOT NULL DEFAULT 0 ,
  `tools_info_id` INT UNSIGNED NOT NULL ,
  PRIMARY KEY (`pages_id`, `tools_info_id`) ,
  INDEX `fk_pages_tools_info_1` (`pages_id` ASC) ,
  INDEX `fk_pages_tools_info_2` (`tools_info_id` ASC) ,
  CONSTRAINT `fk_pages_tools_info_1`
    FOREIGN KEY (`pages_id` )
    REFERENCES `profiles`.`pages` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION,
  CONSTRAINT `fk_pages_tools_info_2`
    FOREIGN KEY (`tools_info_id` )
    REFERENCES `profiles`.`tools_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `profiles`.`filter_info`
-- -----------------------------------------------------
DROP TABLE IF EXISTS `profiles`.`filter_info` ;

SHOW WARNINGS;
CREATE  TABLE IF NOT EXISTS `profiles`.`filter_info` (
  `id` INT UNSIGNED NOT NULL AUTO_INCREMENT ,
  `launch_info_id` INT UNSIGNED NOT NULL ,
  `name` ENUM('LIKE', 'IN', '>', 'NULL') NOT NULL ,
  `not` TINYINT(1) NOT NULL DEFAULT FALSE ,
  `value` VARCHAR(500) NOT NULL ,
  PRIMARY KEY (`id`) ,
  INDEX `fk_filter_info_1` (`launch_info_id` ASC) ,
  CONSTRAINT `fk_filter_info_1`
    FOREIGN KEY (`launch_info_id` )
    REFERENCES `profiles`.`launch_info` (`id` )
    ON DELETE NO ACTION
    ON UPDATE NO ACTION)
ENGINE = InnoDB;

SHOW WARNINGS;


SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;
