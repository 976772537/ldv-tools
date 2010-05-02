-- Database schema for benchmarking results

-- ----------------------------
-- INPUT TO LAUNCHES
-- ----------------------------

-- Environments table holds kernels
drop table if exists environments ;
create table environments (
	id INT(10) UNSIGNED NOT NULL AUTO_INCREMENT,
	version VARCHAR(20) NOT NULL,
	kind VARCHAR(20),
	PRIMARY KEY (id)
);

-- Drivers holds drivers that were checked
drop table if exists drivers ;
create table drivers (
	id int(10) unsigned not null auto_increment,
	name varchar(20) not null,
	origin enum('kernel','external') not null,
	primary key (id),
	key (name)
);

-- Rule-models
drop table if exists rule_models;
create table rule_models(
	id int(10) unsigned not null auto_increment,
	description varchar(200),
	primary key (id)
);

-- Instruments
drop table if exists toolsets;
create table toolsets(
	id int(10) unsigned not null auto_increment,
	version varchar(20) not null,
-- RCV backend used in this measurement
	verifier varchar(20) not null,
	primary key(id),
	key (verifier)
);

drop table if exists scenarios;
create table scenarios(
	id int(10) unsigned not null auto_increment,
	driver_id int(10) unsigned not null,
	executable varchar(100) not null,
	main varchar(100) not null,
	primary key (id),
	foreign key (driver_id) references drivers(id)
);

-- ----------------------------
-- LAUNCHES JOIN
-- ----------------------------

drop table if exists launches;
create table launches(
	driver_id int(10) unsigned not null,
	toolset_id int(10) unsigned not null,
	envirnoment_id int(10) unsigned not null,
	rule_model_id int(10) unsigned not null,
	scenario_id int(10) unsigned not null,
	trace_id int(10) unsigned not null,

	PRImary key (driver_id,toolset_id,envirnoment_id,rule_model_id,scenario_id),

	foreign key (driver_id) references drivers(id),
	foreign key (toolset_id) references toolsets(id),
	foreign key (envirnoment_id) references envirnoments(id),
	foreign key (rule_model_id) references rules(id),
	foreign key (scenario_id) references scenarios(id),
	foreign key (trace_id) references traces(id)
);

-- ----------------------------
-- LAUNCH RESULTS
-- ----------------------------

drop table if exists stats;
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
);

drop table if exists traces;
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
-- Auxilliary information (uname, etc)
	aux_info text,


	primary key (id),

	foreign key (build_id) references stats(id),
	foreign key (maingen_id) references stats(id),
	foreign key (dscv_id) references stats(id),
	foreign key (ri_id) references stats(id),
	foreign key (rcv_id) references stats(id)
);




