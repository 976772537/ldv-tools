
drop table if exists launches_ptrs;
drop table if exists ptrs;

create table ptrs(
	id int(10) unsigned not null auto_increment,
	fname varchar(255),
	line int(10),
	expr varchar(255),
	primary key (id),
	key (fname,line,expr),
	key (fname,line)
) ENGINE=InnoDB;

create table launches_ptrs(
	launch_id int(10) unsigned not null,
	ptr_id int(10) unsigned not null,
	foreign key (launch_id) references launches(id) on delete cascade,
	foreign key (ptr_id) references ptrs(id) on delete cascade
) ENGINE=InnoDB;

