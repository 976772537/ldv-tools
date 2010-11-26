-- Database schema for benchmarking results

-- ----------------------------
-- INPUT TO LAUNCHES
-- ----------------------------

drop table if exists db_properties ;
drop table if exists processes ;
drop table if exists launches;
drop table if exists tasks;
drop table if exists sources;
drop table if exists problems_stats;
drop table if exists problems;
drop table if exists traces;
drop table if exists stats;
drop table if exists scenarios;
drop table if exists toolsets;
drop table if exists rule_models;
drop table if exists drivers ;
drop table if exists environments ;

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
-- LAUNCH RESULTS
-- ----------------------------

create table stats(
	id int(10) unsigned not null auto_increment,
	success boolean not null default false,
-- Runtime in milliseconds (non-cumulative)
	time int(10) not null default 0,
-- Lines of code analyzed
	loc int(10) not null default 0,
-- Description of an error
	description text,

	primary key (id)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

create table traces(
	id int(10) unsigned not null auto_increment,
	build_id int(10) unsigned not null,
	maingen_id int(10) unsigned,
	dscv_id int(10) unsigned,
	ri_id int(10) unsigned,
	rcv_id int(10) unsigned,

	result enum('safe','unsafe','unknown') not null default 'unknown',
-- Error trace if error is found
	error_trace mediumtext,
-- RCV backend used in this measurement
	verifier varchar(100),

	primary key (id),

	foreign key (build_id) references stats(id),
	foreign key (maingen_id) references stats(id),
	foreign key (dscv_id) references stats(id),
	foreign key (ri_id) references stats(id),
	foreign key (rcv_id) references stats(id)
) ENGINE=InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;

create table sources(
	id int(10) unsigned not null auto_increment,
	trace_id int(10) unsigned not null,
	name varchar(255) not null,
	contents mediumblob,

	primary key (id),
	foreign key (trace_id) references traces(id)
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
-- STATISTICS
-- ----------------------------

create table processes(
	trace_id int(10) unsigned not null,
	name varchar(50) not null,
	pattern varchar(50) not null,

	time_average int(10) unsigned not null default 0, 
	time_detailed int(10) unsigned not null default 0, 

	primary key(trace_id, name, pattern),
	UNIQUE (trace_id, name, pattern),
	foreign key (trace_id) references traces(id)
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

	trace_id int(10) unsigned,

	task_id int(10) unsigned,

	status enum('queued','running','failed','finished') not null,

	primary key (id),
	UNIQUE (driver_id,toolset_id,environment_id,rule_model_id,scenario_id,task_id),

	foreign key (driver_id) references drivers(id) on delete cascade,
	foreign key (toolset_id) references toolsets(id) on delete cascade,
	foreign key (environment_id) references environments(id) on delete cascade,
	foreign key (rule_model_id) references rule_models(id) on delete cascade,
	foreign key (scenario_id) references scenarios(id) on delete cascade,
	foreign key (trace_id) references traces(id),
	foreign key (task_id) references tasks(id) on delete cascade
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
-- INSERT DATABASE PARAMETERS
-- ----------------------------
insert into db_properties (name, value) values ("version","1");
