-- Database schema for benchmarking results

-- ----------------------------
-- INPUT TO LAUNCHES
-- ----------------------------

drop table if exists db_properties ;
drop table if exists processes ;
drop table if exists sources;
drop table if exists problems_stats;
drop table if exists problems;
drop table if exists stats;
drop table if exists results_kb_calculated; 
drop table if exists results_kb;
drop table if exists traces;
drop table if exists launches;
drop table if exists tasks;
drop table if exists scenarios;
drop table if exists toolsets;
drop table if exists rule_models;
drop table if exists drivers ;
drop table if exists environments ;
drop table if exists kb;

-- Environments table holds kernels
create table environments (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	version VARCHAR(50) NOT NULL,
	kind VARCHAR(20),
	PRIMARY KEY (id)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

-- Drivers holds drivers that were checked
create table drivers (
	id int(10) unsigned not null auto_increment,
	name varchar(255) not null,
	origin enum('kernel','external') not null,
	primary key (id),
	key (name)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

-- Rule-models
create table rule_models(
	id int(10) unsigned not null auto_increment,
	name varchar(20),
	description varchar(200),
	primary key (id)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

-- Instruments
create table toolsets(
	id int(10) unsigned not null auto_increment,
	version varchar(100) not null,
-- verifier should contain "model-specific" if verifier is set up by model.
-- Otherwise, if the verifier was forced by user, it should contain a user-defined verifier name 
	verifier varchar(100) not null default "model-specific",
	primary key(id),
	unique (version,verifier),
	key (version),
	key (verifier)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

create table scenarios(
	id int(10) unsigned not null auto_increment,
	driver_id int(10) unsigned not null,
	executable varchar(255) not null,
	main varchar(100) not null,
	primary key (id),
	foreign key (driver_id) references drivers(id)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- TASKS
-- ----------------------------

create table tasks(
	id int(10) unsigned not null auto_increment,

	username varchar(50),
	timestamp datetime,

	driver_spec varchar(255),
	driver_spec_origin enum('kernel','external'),

	description text,

-- Its primary use is to refer to particular tasks in URL of statistics server
	name varchar(255),


	primary key (id)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- LAUNCHES JOIN
-- ----------------------------

create table launches(
	id int(10) unsigned not null auto_increment,
	driver_id int(10) unsigned not null,
	toolset_id int(10) unsigned not null,
	environment_id int(10) unsigned not null,
-- Can be NULL if rule-instrumentor failed to create a model
	rule_model_id int(10) unsigned,
-- Can be NULL if the driver failed to build
	scenario_id int(10) unsigned,

	task_id int(10) unsigned,

	status enum('queued','running','failed','finished') not null,

-- For backwards compatibility: reference to the relevant trace.  DO NOT use this field in the newer code.
	trace_id int(10) unsigned,

	primary key (id),
	UNIQUE (driver_id,toolset_id,environment_id,rule_model_id,scenario_id,task_id),

	foreign key (driver_id) references drivers(id) on delete cascade,
	foreign key (toolset_id) references toolsets(id) on delete cascade,
	foreign key (environment_id) references environments(id) on delete cascade,
	foreign key (rule_model_id) references rule_models(id) on delete cascade,
	foreign key (scenario_id) references scenarios(id) on delete cascade,
	foreign key (task_id) references tasks(id) on delete cascade
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- LAUNCH RESULTS
-- ----------------------------
create table traces(
	id int(10) unsigned not null auto_increment,
	launch_id int(10) unsigned not null,

	result enum('safe','unsafe','unknown') not null default 'unknown',
-- Error trace if error is found
	error_trace mediumtext,
-- RCV backend used in this measurement
	verifier varchar(100),

	primary key (id),

	foreign key (launch_id) references launches(id) on delete cascade,

-- Links to relevant stats for backward compatibility.  DO NOT use in the new code!
	build_id int(10) unsigned,
	maingen_id int(10) unsigned,
	dscv_id int(10) unsigned,
	ri_id int(10) unsigned,
	rcv_id int(10) unsigned

) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

create table sources(
	id int(10) unsigned not null auto_increment,
	trace_id int(10) unsigned not null,
	name varchar(255) not null,
	contents mediumblob,

	primary key (id),
	foreign key (trace_id) references traces(id) on delete cascade
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- STATISTICS
-- ----------------------------

create table stats(
	id int(10) unsigned not null auto_increment,
	trace_id int(10) unsigned not null,
	kind enum ('build','maingen','dscv','ri','rcv') not null,
	success boolean not null default false,
-- Runtime in milliseconds (non-cumulative)
	time int(10) not null default 0,
-- Lines of code analyzed
	loc int(10) not null default 0,
-- Description of an error
	description text,

	primary key (id),
	unique (trace_id,kind),
-- key k_trace (trace_id),
	foreign key (trace_id) references traces(id) on delete cascade
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

create table processes(
	trace_id int(10) unsigned not null,
	name varchar(50) not null,
	pattern varchar(50) not null,

	time_average int(10) unsigned not null default 0, 
	time_detailed int(10) unsigned not null default 0, 

	primary key(trace_id, name, pattern),
	UNIQUE (trace_id, name, pattern),
	key k_trace (trace_id),
	foreign key (trace_id) references traces(id) on delete cascade
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;




-- ----------------------------
-- PROBLEM DATABASE
-- ----------------------------

create table problems(
	id int(10) unsigned not null auto_increment,
-- To look up in scripts output
	name varchar(100),

-- To show user
	description text,

	PRImary key (id),
	key (name)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

create table problems_stats(
	stats_id int(10) unsigned not null,
	problem_id int(10) unsigned not null,
	unique (stats_id,problem_id),

	foreign key (stats_id) references stats(id) on delete cascade,
	foreign key (problem_id) references problems(id) on delete cascade
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

-- ----------------------------
-- DATABASE PROPERTIES
-- ----------------------------

create table db_properties(
        id int(10) unsigned not null auto_increment,
        name varchar(50) not null,
        value varchar(50) not null,
        primary key(id),
        unique (name)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;


-- ----------------------------
-- KNOWLEDGE BASE
-- ----------------------------

-- Note, that some of KB SQL were generated automatically by means of
-- mysql-workbench (related project is in ../knowledge-base/kb.mwb).

-- -----------------------------------------------------
-- Table `kb`
-- -----------------------------------------------------
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
-- New information for PPoB (Public Pool of Bugs).
  `status` ENUM('Fixed', 'Reported', 'Unreported', 'Rejected') NOT NULL DEFAULT 'Unreported',
  `published_trace_id` INT NULL DEFAULT NULL,
  `internal_status` ENUM('Unpublished', 'Synchronized', 'Unsynchronized') NOT NULL DEFAULT 'Unpublished'

  
  PRIMARY KEY (`id`) )
ENGINE = InnoDB
DEFAULT CHARACTER SET = utf8
COLLATE = utf8_general_ci;
SHOW WARNINGS;

-- -----------------------------------------------------
-- Table `results_kb`
-- -----------------------------------------------------
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

-- ----------------------------
-- INSERT DATABASE PARAMETERS
-- ----------------------------
insert into db_properties (name, value) values ("version","4");
