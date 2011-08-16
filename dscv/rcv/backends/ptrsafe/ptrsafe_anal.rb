select c, count(*) from (select launch_id, count(*) as c from launches join launches_ptrs on launch_id = launches.id join ptrs on ptr_id = ptrs.id where fname not like 'include/%' group by launch_id order by c asc) as subb group by c order by c asc;


select fname, expr, count(*) as r from ptrs join launches_ptrs on ptr_id = id group by fname,expr having fname not like 'include/%' order by r asc;
