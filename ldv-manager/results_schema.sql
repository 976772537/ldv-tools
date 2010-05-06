-- Database schema for benchmarking results

-- ----------------------------
-- INPUT TO LAUNCHES
-- ----------------------------

drop table if exists launches;
drop table if exists tasks;
drop table if exists sources;
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
	version VARCHAR(20) NOT NULL,
	kind VARCHAR(20),
	PRIMARY KEY (id)
) ENGINE=InnoDB;

-- Drivers holds drivers that were checked
create table drivers (
	id int(10) unsigned not null auto_increment,
	name varchar(20) not null,
	origin enum('kernel','external') not null,
	primary key (id),
	key (name)
) ENGINE=InnoDB;

-- Rule-models
create table rule_models(
	id int(10) unsigned not null auto_increment,
	name varchar(20),
	description varchar(200),
	primary key (id)
) ENGINE=InnoDB;

-- Instruments
create table toolsets(
	id int(10) unsigned not null auto_increment,
	version varchar(20) not null,
-- RCV backend used in this measurement
	verifier varchar(20) not null,
	primary key(id),
	key (verifier)
) ENGINE=InnoDB;

create table scenarios(
	id int(10) unsigned not null auto_increment,
	driver_id int(10) unsigned not null,
	executable varchar(100) not null,
	main varchar(100) not null,
	primary key (id),
	foreign key (driver_id) references drivers(id)
) ENGINE=InnoDB;

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
) ENGINE=InnoDB;

create table traces(
	id int(10) unsigned not null auto_increment,
	build_id int(10) unsigned not null,
	maingen_id int(10) unsigned not null,
	dscv_id int(10) unsigned not null,
	ri_id int(10) unsigned not null,
	rcv_id int(10) unsigned not null,

	result enum('safe','unsafe','unknown') not null default 'unknown',
-- Error trace if error is found
	error_trace text,

	primary key (id),

	foreign key (build_id) references stats(id),
	foreign key (maingen_id) references stats(id),
	foreign key (dscv_id) references stats(id),
	foreign key (ri_id) references stats(id),
	foreign key (rcv_id) references stats(id)
) ENGINE=InnoDB;

create table sources(
	id int(10) unsigned not null auto_increment,
	trace_id int(10) unsigned not null,
	name varchar(255) not null,
	contents blob,

	primary key (id),
	foreign key (trace_id) references traces(id)
) ENGINE=InnoDB;

-- ----------------------------
-- TASKS
-- ----------------------------

create table tasks(
	id int(10) unsigned not null auto_increment,

	username varchar(50),
	timestamp datetime,

	primary key (id)
) ENGINE=InnoDB;


-- ----------------------------
-- LAUNCHES JOIN
-- ----------------------------

create table launches(
	driver_id int(10) unsigned not null,
	toolset_id int(10) unsigned not null,
	environment_id int(10) unsigned not null,
	rule_model_id int(10) unsigned not null,
	scenario_id int(10) unsigned not null,

	trace_id int(10) unsigned not null,

	task_id int(10) unsigned,

	PRImary key (driver_id,toolset_id,environment_id,rule_model_id,scenario_id),

	foreign key (driver_id) references drivers(id),
	foreign key (toolset_id) references toolsets(id),
	foreign key (environment_id) references environments(id),
	foreign key (rule_model_id) references rule_models(id),
	foreign key (scenario_id) references scenarios(id),
	foreign key (trace_id) references traces(id),
	foreign key (task_id) references tasks(id)
) ENGINE=InnoDB;

