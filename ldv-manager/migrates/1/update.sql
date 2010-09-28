-- Database update schema for benchmarking results

-- ----------------------------
-- STATISTICS
-- ----------------------------

create table if not exists processes(
	trace_id int(10) unsigned not null,
	name varchar(50) not null,
	pattern varchar(50) not null,

	time_average int(10) unsigned not null default 0, 
	time_detailed int(10) unsigned not null default 0, 

	primary key(trace_id, name, pattern),
	UNIQUE (trace_id, name, pattern),
	foreign key (trace_id) references traces(id)
) ENGINE=InnoDB;

-- ----------------------------
-- DATABASE PROPERTIES
-- ----------------------------

create table db_properties(
        id int(10) unsigned not null auto_increment,
        name varchar(50) not null,
        value varchar(50) not null,
        primary key(id),
        unique (name)
) ENGINE=InnoDB;

-- ----------------------------
-- INSERT DATABASE PARAMETERS
-- ----------------------------
insert into db_properties (name, value) values ("version","1");
