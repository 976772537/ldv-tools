SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0;
SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0;
SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='TRADITIONAL';

ALTER  TABLE `results_kb` 
  ADD COLUMN `published_trace_id` INT NULL DEFAULT NULL ,
  ADD COLUMN `sync_status` ENUM('Unpublished', 'Synchronized', 'Desynchronized') NOT NULL DEFAULT 'Unpublished' ,
  ADD COLUMN `status` ENUM('Fixed', 'Reported', 'Unreported', 'Rejected', 'Obsolete') NOT NULL DEFAULT 'Unreported' ;



SET SQL_MODE=@OLD_SQL_MODE;
SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS;
SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS;

