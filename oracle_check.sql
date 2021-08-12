Rem 数据库巡检脚本
Rem 更新时间于2020-4-15，版本号2.2
Rem 该脚本仅对数据库的做一个初步的巡检，具体的优化方案应结合监控、awr、ash去具体分析


Rem 设置相关格式
set feedback off verify off trimspool on term off timing off heading on
set pagesize 100 linesize 500


Rem 生成的文件 ~/oracle_xj_实例名_日期.txt
column inst_name new_value inst_name noprint
select instance_name inst_name from v$instance;
column txt_time new_value txt_time noprint
select to_char(sysdate,'yyyymmdd') txt_time from dual;
spool /home/oracle/oracle_xj_&inst_name._&txt_time..txt


prompt 说明：如果有的条目没有结果，则该条目状态正常
prompt
prompt 一、数据库的基本情况
prompt
prompt 1.1、数据库基本信息
col host_name for a20
select dbid, name db_name, instance_name, version, parallel rac, host_name
  from v$database, v$instance;

  
prompt
prompt 1.2、实例状态
select instance_number, instance_name, status, host_name from gv$instance;


prompt
prompt 1.3、数据库运行时间
col run_time for a28
select instance_number,
    to_char(startup_time, 'yyyy-mm-dd hh24:mi:ss') startup_time,
    trunc(sysdate - (startup_time)) || 'day '
    || trunc(24 * ((sysdate - startup_time) - trunc(sysdate - startup_time))) || 'hour '
    || mod(trunc(1440 * ((sysdate - startup_time) - trunc(sysdate - startup_time))), 60) || 'min '
    || mod(trunc(86400 * ((sysdate - startup_time) - trunc(sysdate - startup_time))), 60) || 'min' run_time
  from gv$instance;

  
prompt
prompt 二、数据库的cpu、内存情况
prompt
prompt 2.1、cpu情况
col stat_name for a20
col percent for a10
select stat_name,
       to_char((value * 100 / (sum(value) over())), 90.99) || '%' percent
  from v$osstat
 where stat_name in
       ('IDLE_TIME', 'BUSY_TIME', 'USER_TIME', 'SYS_TIME', 'IOWAIT_TIME');

       
prompt
prompt 2.2、sga及其组件大小
prompt 参考值： Buffer_cache_size：70%sga，Shared_pool_size：15%sga左右
col name for a35 
col percent for a10
with tmp as
 (select decode(a.value, 0, b.value, null, b.value, a.value) sga_size
    from (select name, value from v$parameter where name = 'sga_target') a,
         (select name, value from v$parameter where name = 'sga_max_size') b)
select name, 
       round(bytes / 1024 / 1024) size_mb, round(sga_size / 1024 / 1024) sga_mb, 
       round(100 * bytes / sga_size, 2) || '%' percent
  from v$sgainfo, tmp
 where name in ('Buffer Cache Size', 'Shared Pool Size');

 
prompt
prompt 2.3、pga大小
prompt 参考值：pga大小为30%sga左右
col name for a30 
select name, round(value / 1024 / 1024) size_mb
  from v$parameter
 where name = 'pga_aggregate_target';

 
prompt
prompt 三、检查各文件状态
prompt
prompt 3.1、查看参数文件
col name for a20
col value for a40
select name, value from v$parameter where name = 'spfile';


prompt
prompt 3.2、查看控制文件
col name for a60
select name, status from v$controlfile;


prompt
prompt 3.3、查看在线日志
col member for a50
select a.group#,
       b.thread#,
       a.status,
       a.type,
       a.member,
       (b.bytes / 1024 / 1024) onl_size_mb
  from v$logfile a, v$log b
 where a.group# = b.group#
 order by 1, 2;

 
prompt
prompt 3.3.1、查看standby日志
col member for a50
select a.group#,
       b.thread#,
       a.status,
       a.type,
       a.member,
       (b.bytes / 1024 / 1024) std_size_mb
  from v$logfile a, v$standby_log b
 where a.group# = b.group#
 order by 1, 2;
 
 
prompt
prompt 3.4、检查最近一天日志切换频率
select thread#,
       sequence#,
       to_char(first_time, 'yyyy-mm-dd hh24:mi:ss') first_time,
       case
         when minutes < 0 then
          null
         else
          minutes
       end mitutes
  from (select thread#,
               sequence#,
               first_time,
               round((first_time - lag(first_time) over(order by thread#, first_time)) * 24 * 60, 2) minutes
          from v$log_history
         where first_time > sysdate - 2)
 where first_time > sysdate - 1
 order by thread#, first_time;

 
prompt
prompt 3.4.1、检查最近一周日志切换
select to_char(first_time, 'yyyy.mm.dd') day,
  to_char(sum(decode(to_char(first_time,'hh24'),'00',1,0)),'999') "00",
  to_char(sum(decode(to_char(first_time,'hh24'),'01',1,0)),'999') "01",
  to_char(sum(decode(to_char(first_time,'hh24'),'02',1,0)),'999') "02",
  to_char(sum(decode(to_char(first_time,'hh24'),'03',1,0)),'999') "03",
  to_char(sum(decode(to_char(first_time,'hh24'),'04',1,0)),'999') "04",
  to_char(sum(decode(to_char(first_time,'hh24'),'05',1,0)),'999') "05",
  to_char(sum(decode(to_char(first_time,'hh24'),'06',1,0)),'999') "06",
  to_char(sum(decode(to_char(first_time,'hh24'),'07',1,0)),'999') "07",
  to_char(sum(decode(to_char(first_time,'hh24'),'08',1,0)),'999') "08",
  to_char(sum(decode(to_char(first_time,'hh24'),'09',1,0)),'999') "09",
  to_char(sum(decode(to_char(first_time,'hh24'),'10',1,0)),'999') "10",
  to_char(sum(decode(to_char(first_time,'hh24'),'11',1,0)),'999') "11",     
  to_char(sum(decode(to_char(first_time,'hh24'),'12',1,0)),'999') "12",
  to_char(sum(decode(to_char(first_time,'hh24'),'13',1,0)),'999') "13",
  to_char(sum(decode(to_char(first_time,'hh24'),'14',1,0)),'999') "14",
  to_char(sum(decode(to_char(first_time,'hh24'),'15',1,0)),'999') "15",     
  to_char(sum(decode(to_char(first_time,'hh24'),'16',1,0)),'999') "16",
  to_char(sum(decode(to_char(first_time,'hh24'),'17',1,0)),'999') "17",
  to_char(sum(decode(to_char(first_time,'hh24'),'18',1,0)),'999') "18",
  to_char(sum(decode(to_char(first_time,'hh24'),'19',1,0)),'999') "19",
  to_char(sum(decode(to_char(first_time,'hh24'),'20',1,0)),'999') "20",
  to_char(sum(decode(to_char(first_time,'hh24'),'21',1,0)),'999') "21",
  to_char(sum(decode(to_char(first_time,'hh24'),'22',1,0)),'999') "22",
  to_char(sum(decode(to_char(first_time,'hh24'),'23',1,0)),'999') "23"      
from v$log_history where first_time > trunc(sysdate) - 7
group by to_char(first_time, 'yyyy.mm.dd') order by 1 desc; 


prompt
prompt 3.5、查看asm磁盘组空间
col name for a20
col used_percent for 9999
select group_number,
       name,
       type,
       total_mb,
       usable_file_mb,
       round(100 - usable_file_mb * decode(type, 'EXTERN', 1, 'NORMAL', 3, 'HIGH', 5) * 100 / (total_mb)) used_percent
  from v$asm_diskgroup;
 
 
prompt
prompt 3.6、查看表空间的使用情况
select tablespace_name,
       round(used / 1024 / 1024) used_mb,
       round(total / 1024 / 1024) total_mb,
       to_char(round(used / total * 100, 2), '9999990.99') used_percent
  from (select a.tablespace_name,
               (a.bytes_alloc - b.bytes_free) used,
               a.bytes_total total
          from (select tablespace_name,
                       sum(bytes) bytes_alloc,
                       sum(greatest(bytes, maxbytes)) bytes_total
                  from dba_data_files
                 group by tablespace_name) a,
               (select tablespace_name, sum(bytes) bytes_free
                  from dba_free_space
                 group by tablespace_name) b
         where a.tablespace_name = b.tablespace_name)
 order by 4;

 
prompt
prompt 3.7、查看临时表空间使用情况
select tablespace_name,
       used used_mb,
       allocate allocate_mb,
       total total_mb,
       to_char(round(used / total * 100, 2), '990.99') used_percent
  from (select tablespace_name,
               (select sum(blocks) / 128 from v$tempseg_usage) used,
               round(sum(bytes) / 1024 / 1024) allocate,
               round(sum(greatest(bytes, maxbytes)) / 1024 / 1024) total
          from dba_temp_files
         group by tablespace_name);

         
prompt
prompt 3.8、查看临时段使用的情况
col username for a20
col segtype for a10
select username,
       segtype,
       extents  extents_allocated,
       blocks   blocks_allocated
  from v$tempseg_usage
 order by 1, 2;

 
prompt
prompt 3.9、查看数据文件状态
col name for a30
select b.name tablespace_name, a.status, count(*)
  from v$datafile a, v$tablespace b
 where a.ts# = b.ts#
 group by b.name, a.status
 order by 1;

 
prompt
prompt 3.10、归档日志检查
col dest_name for a20
col error for a40 
col gap_status for a10 
select dest_id, dest_name, status, type, error, gap_status
  from v$archive_dest_status
 where status <> 'INACTIVE';


prompt
prompt 3.11、最近一周备份情况
select input_type, output_device_type, start_time, status
  from v$rman_backup_job_details
 where start_time > sysdate - 7
 order by start_time desc;

 
prompt
prompt 四、检查数据库对象状态
prompt 
prompt 4.1、查看回滚段状态
select status, count(*) from dba_rollback_segs group by status;
  
  
prompt
prompt 4.2、检查是否有禁用约束
col owner for a20
select owner, constraint_name, table_name, constraint_type, status
  from dba_constraints
 where status = 'DISABLED'
   and owner not in ('SYS',
                     'SYSTEM',
                     'WMSYS',
                     'DBSNMP',
                     'XDB',
                     'EXFSYS',
                     'CTXSYS',
                     'MDSYS',
                     'OLAPSYS',
                     'SYSMAN',
                     'APEX_030200',
                     'OUTLN',
                     'ORDDATA',
                     'ORDSYS',
                     'RMAN')
 order by 1, 3;
 
 
prompt
prompt 4.3、检查是否有禁用触发器
col owner for a20
col taigger_name for a10
col table_name for a30
col table_name for a30
select owner, trigger_name, table_name, status
  from dba_triggers
 where status = 'DISABLED'
   and owner not in ('SYS',
                     'SYSTEM',
                     'WMSYS',
                     'DBSNMP',
                     'XDB',
                     'EXFSYS',
                     'CTXSYS',
                     'MDSYS',
                     'OLAPSYS',
                     'SYSMAN',
                     'APEX_030200',
                     'OUTLN',
                     'ORDDATA',
                     'ORDSYS',
                     'RMAN')
 order by 1, 3;
 
 
prompt
prompt 4.4、oracle job是否有失败
col what for a50
select job, what, last_date, next_date, failures, broken
  from dba_jobs
 where failures > 0
    or broken = 'Y';
 
 
prompt
prompt 4.5、查看无效的对象
col object_name for a40
select owner, object_name, object_type, last_ddl_time
  from dba_objects
 where status != 'VALID'
   and owner not in ('SYS',
                     'SYSTEM',
                     'WMSYS',
                     'DBSNMP',
                     'XDB',
                     'EXFSYS',
                     'CTXSYS',
                     'MDSYS',
                     'OLAPSYS',
                     'SYSMAN',
                     'APEX_030200',
                     'OUTLN',
                     'ORDDATA',
                     'ORDSYS',
                     'RMAN',
                     'PUBLIC')
 order by 1, 3;
 
 
prompt
prompt 4.6、检查失效的索引
select owner, index_name, table_name, tablespace_name, status
  from dba_indexes
 where status not in ('VALID', 'N/A')
 order by 1, 3;


prompt
prompt 4.7、并行度大于1的索引
col owner for a25
col table_name for a30
col index_name for a30
col degree for a10
select owner, table_name, index_name, degree
  from dba_indexes
 where degree > '1'
 order by 1, 2;

 
prompt
prompt 4.8、索引冗余
col owner for a25
col table_name for a30
col redundant_index for a30
col sufficient_index for a30
select o1.name      owner,
       x.table_name,
       n1.name      redundant_index,
       n2.name      sufficient_index
  from sys.icol$   ic1,
       sys.icol$   ic2,
       sys.ind$    i1,
       sys.obj$    n1,
       sys.obj$    n2,
       sys.user$   o1,
       sys.user$   o2,
       dba_indexes x
 where ic1.pos# = 1
   and ic2.bo# = ic1.bo#
   and ic2.obj# != ic1.obj#
   and ic2.pos# = 1
   and ic2.intcol# = ic1.intcol#
   and i1.obj# = ic1.obj#
   and bitand(i1.property, 1) = 0
   and (select max(pos#) * (max(pos#) + 1) / 2
          from sys.icol$
         where obj# = ic1.obj#) =
       (select sum(xc1.pos#)
          from sys.icol$ xc1, sys.icol$ xc2
         where xc1.obj# = ic1.obj#
           and xc2.obj# = ic2.obj#
           and xc1.pos# = xc2.pos#
           and xc1.intcol# = xc2.intcol#)
   and n1.obj# = ic1.obj#
   and n2.obj# = ic2.obj#
   and o1.user# = n1.owner#
   and o2.user# = n2.owner#
   and x.index_name = n1.name
   and n1.name not like 'BIN$%'
   and o1.name not in ('SYS',
                       'SYSTEM',
                       'WMSYS',
                       'DBSNMP',
                       'XDB',
                       'EXFSYS',
                       'CTXSYS',
                       'MDSYS',
                       'OLAPSYS',
                       'SYSMAN',
                       'APEX_030200',
                       'OUTLN',
                       'ORDDATA',
                       'ORDSYS',
                       'RMAN')
 order by 1, 2;

 
prompt
prompt 4.9、检查碎片程度高的表
prompt 找出总大小超过1G，且使用率不足70%的表
col used_percent for a15
select owner,
       table_name,
       used used_mb,
       total total_mb,
       round(used * 100 / total) || '%' used_percent,
       num_rows,
       last_analyzed
  from (select owner,
               table_name,
               round(blocks * 8192 / 1024 / 1024) total,
               round(num_rows * avg_row_len / 1024 / 1024) used,
               num_rows,
               last_analyzed
          from dba_tables)
 where total > 1000
   and round(used * 100 / total) < 70
 order by 1, 2;
  
  
prompt
prompt 4.10、检查一些扩展异常的对象
prompt 对象的extent数量超过临界值的80%，需要move
select segment_name,
       segment_type,
       tablespace_name,
       (extents / max_extents) * 100 percent
  from sys.dba_segments
 where max_extents != 0
   and (extents / max_extents) >= 0.8
 order by percent;

 
prompt
prompt 4.11、检查对象的下一扩展与表空间的最大扩展值 
prompt 表空间的剩余空间已经无法满足对象的下次扩展，需要扩表空间
select a.table_name, a.next_extent, a.tablespace_name
  from all_tables a,
       (select tablespace_name, max(bytes) as big_chunk
          from dba_free_space
         group by tablespace_name) f
 where f.tablespace_name = a.tablespace_name
   and a.next_extent > f.big_chunk
union
select a.index_name, a.next_extent, a.tablespace_name
  from all_indexes a,
       (select tablespace_name, max(bytes) as big_chunk
          from dba_free_space
         group by tablespace_name) f
 where f.tablespace_name = a.tablespace_name
   and a.next_extent > f.big_chunk;

   
prompt
prompt 4.12、查看行迁移或行链接
col percentage for a15
select 'chained rows' ratio,
       round((select value
                from v$sysstat
               where name = 'table fetch continued row') /
             (select value
                from v$sysstat
               where name = 'table scan rows gotten') * 100,
             2) || '%' percentage
  from dual;

  
prompt
prompt 4.13、检查system表空间内的内容
select owner, table_name object_name, type
  from (select owner, table_name, 'table' as type
          from dba_tables
         where tablespace_name = 'SYSTEM'
           and owner != 'SYS'
           and owner not in ('SYS',
                             'SYSTEM',
                             'WMSYS',
                             'DBSNMP',
                             'XDB',
                             'EXFSYS',
                             'CTXSYS',
                             'MDSYS',
                             'OLAPSYS',
                             'SYSMAN',
                             'APEX_030200',
                             'OUTLN',
                             'ORDDATA',
                             'ORDSYS')
        union
        select owner, index_name, 'index' as type
          from dba_indexes
         where tablespace_name = 'SYSTEM'
           and owner != 'SYS'
           and owner not in ('SYS',
                             'SYSTEM',
                             'WMSYS',
                             'DBSNMP',
                             'XDB',
                             'EXFSYS',
                             'CTXSYS',
                             'MDSYS',
                             'OLAPSYS',
                             'SYSMAN',
                             'APEX_030200',
                             'OUTLN',
                             'ORDDATA',
                             'ORDSYS'))
 order by 1, 3;


prompt
prompt 五、dbtime和连接情况
prompt
prompt 5.1、查看当前实例最近一天的db_time
select c.snap_id,
       to_char(b.begin_interval_time, 'yyyy-mm-dd hh24:mi') begin_snapshot_time,
       c.db_time
  from (select a.snap_id,
               trunc((db_time_1 - lag(db_time_1, 1, db_time_1)
                      over(partition by stat_name,
                           instance_number order by snap_id)) / 1000000 / 60) db_time
          from (select a.snap_id,
                       a.dbid,
                       a.instance_number,
                       a.stat_name,
                       sum(a.value) db_time_1
                  from dba_hist_sys_time_model a
                 where a.stat_name = 'DB time'
                   and a.instance_number =
                       (select instance_number from v$instance)
                 group by a.snap_id, a.dbid, a.instance_number, a.stat_name) a) c,
       dba_hist_snapshot b
 where b.instance_number = (select instance_number from v$instance)
   and c.snap_id = b.snap_id
   and b.begin_interval_time > sysdate - 1
 order by 1;
 

prompt
prompt 5.2、检查数据库连接情况
col machine for a30
select username, program, machine, count(*)
  from v$session
 where username is not null
 group by username, program, machine
 order by 1, 4 desc;


prompt    
prompt 5.3、检查oracle初始化文件中相关参数值
prompt initial_allocation：软限制，limit_value：硬限制
prompt 若limit_value - max_utilization <= 5，则表明与resource_name相关的oracle初始化参数需要调整。可以通过参数文件调整。
select resource_name, max_utilization, initial_allocation, limit_value
  from v$resource_limit
 order by 4, 3;

 
prompt
prompt 六、检查数据库event和sql
prompt
prompt 6.1、当前数据库的等待事件
col wait_class for a15
col event for a30
select inst_id, wait_class, event, count(*)
  from gv$session
 where wait_class <> 'Idle'
 group by inst_id, wait_class, event
 order by inst_id, wait_class, event;

 
prompt
prompt 6.2、top5 event
prompt total_waits：总等待的次数，average_wait：每次等待的时间(ms)
col event for a30
select *
  from (select event, total_waits, 10 * average_wait average_wait, wait_class#
          from v$system_event
         where event not like 'SQL%'
           and wait_class# <> 6
         order by total_waits desc)
 where rownum <= 5;


prompt
prompt 6.3、top10 物理读sql
col sql_text for a65
select *
  from (select sql_id,
               replace(substr(sql_text, 1, 300), chr(13), '') sql_text,
               disk_reads,
               executions,
               round(disk_reads / executions) "DISKREADS/EXEC"
          from v$sqlarea
         where disk_reads > 0
           and executions > 0
         order by disk_reads desc)
 where rownum <= 10;

 
prompt
prompt 6.4、top10 逻辑读sql
select *
  from (select sql_id,
               replace(substr(sql_text, 1, 300), chr(13), '') sql_text,
               buffer_gets,
               executions,
               round(buffer_gets / executions) "GETS/EXEC"
          from v$sqlarea
         where buffer_gets > 0
           and executions > 0
         order by buffer_gets desc)
 where rownum <= 10;

 
prompt
prompt 6.5、top10 物理读object
col value for 999999999999
col object_name for a30
select *
  from (select owner, object_name, value
          from v$segment_statistics
         where statistic_name = 'physical reads'
         order by value desc)
 where rownum <= 10;

 
prompt
prompt 6.6、top10 热segment
col object_name for a30
col owner for a20
select *
  from (select ob.owner, ob.object_name, ob.object_type, sum(b.tch) touchs
          from x$bh b, dba_objects ob
         where b.obj = ob.data_object_id
           and b.ts# > 0
         group by ob.owner, ob.object_name, ob.object_type
         order by sum(tch) desc)
 where rownum <= 10;


prompt
prompt 6.7、查看热点数据文件(从单块读取时间判断)
prompt cs：单块读的时间(ms)，readtim：总的读时间(ms)，writetim：总的写时间(ms)
col file_name for a60
select *
  from (select t.file_name,
               t.tablespace_name,
               round(s.singleblkrdtim / s.singleblkrds / 10, 3) as cs,
               round(s.readtim / 10) readtim,
               round(s.writetim / 10) writetim
          from v$filestat s, dba_data_files t
         where s.file# = t.file_id
         order by cs desc)
 where rownum <= 10;

 
prompt
prompt 6.8、检查运行很久的sql
col username for a12
col opname for a16
col progress for a8
select b.username,
       a.sql_text,
       b.sid,
       b.serial#,
       b.sofar,
       b.totalwork,
       round(b.sofar / b.totalwork * 100, 2) "COMPLETE%"
  from gv$sql a, gv$session_longops b
 where a.sql_id = b.sql_id
   and a.inst_id = b.inst_id
   and b.totalwork <> 0
   and b.sofar <> b.totalwork;


Rem 执行次数大于100次，且在一周之内发生执行计划突变的sql
prompt
prompt 6.9、检查执行计划最近一周发生突变的sql
with a as
 (select sql.sql_id,
         sql.plan_hash_value,
         min(to_char(s.begin_interval_time, 'yyyymmdd_hh24mi')) date_time,
         sum(sql.executions_delta) executions_delta,
         round(avg(sql.buffer_gets_delta /
                   decode(nvl(sql.executions_delta, 0),
                          0,
                          1,
                          sql.executions_delta))) avg_lio,
         round(avg((sql.cpu_time_delta / 1000000) /
                   decode(nvl(sql.executions_delta, 0),
                          0,
                          1,
                          sql.executions_delta)),
               2) avg_cputime_s,
         round(avg((sql.elapsed_time_delta / 1000000) /
                   decode(nvl(sql.executions_delta, 0),
                          0,
                          1,
                          sql.executions_delta)),
               2) avg_etime_s,
         'HIS' as status
    from dba_hist_sqlstat sql, dba_hist_sql_plan spl, dba_hist_snapshot s
   where sql.dbid = (select dbid from v$database)
     and sql.sql_id = spl.sql_id
     and spl.object_owner not in ('SYS', 'SYSTEM', 'SYSMAN')
     and s.snap_id = sql.snap_id
     and s.begin_interval_time between trunc(sysdate - 7) and trunc(sysdate)
     and sql.executions_delta > 100
     and sql.plan_hash_value <> 0
   group by sql.sql_id, sql.plan_hash_value
  union all
  select b.sql_id,
         b.plan_hash_value,
         to_char(b.last_active_time, 'yyyymmdd_hh24mi'),
         b.executions,
         b.buffer_gets / b.executions,
         b.cpu_time / 1000000 / b.executions,
         b.elapsed_time / 1000000 / b.executions,
         'NOW'
    from v$sqlstats b
   where b.executions > 100)
select sql_id, plan_hash_value, date_time, executions_delta, round(avg_lio) avg_lio, trunc(avg_cputime_s, 3) avg_cputime_s, trunc(avg_etime_s, 3) avg_etime_s, status
  from a
 where sql_id in (
select sql_id
  from(
select sql_id, count(distinct plan_hash_value)
  from a
 group by sql_id
having count(distinct plan_hash_value) > 1))
 order by sql_id, date_time;


spool off
