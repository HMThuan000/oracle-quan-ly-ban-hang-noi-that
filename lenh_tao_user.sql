alter session set "_oracle_script" = true;
create user std789 identified by 1;
grant create session to std789;
grant create table to std789;
alter user std789 quota 10M on users;

grant create any procedure to std789;
grant create any trigger to std789;
