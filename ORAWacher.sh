#!/usr/bin/ksh
echo ""
echo "ORAWatcher Version：1.0.1"
echo ""
#Create Time：2016-04-08  
#Update Time：2016-04-08 15:44                                            
######################################################################
#数据库连接设置
######################################################################
sqlstr=$1
test $1
if [ $? = 1 ]; then
    echo
    echo "Info...You did not enter a value for sqlstr."
    echo "Info...Using default value = system/system"
    sqlstr="system/system"   
fi 

######################################################################
# Create log subdirectories if they don't exist
######################################################################
if [ ! -d archive ]; then
        mkdir archive
fi        

echo "$sqlstr"
echo "Starting Data Collection..."
echo ""
######################################################################
hostn=`hostname`
hour=`date +'%m.%d.%y.%H00.dat'`
echo "`date` collect...">archive/${hostn}_oracle_$hour
######################################################################
echo "########################  1.数据库版本"
echo "select '                    ' as \"--1.Database Version\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "Select version FROM Product_component_version 
Where SUBSTR(PRODUCT,1,6)='Oracle';" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  2.控制文件"
echo "select '                    ' as \"--2.Control files\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "select name from v\$controlfile;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  3.pfile、spfile"
echo "select '                    ' as \"--3.Parameter files\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "show parameter pfile;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  4.字符集"
echo "select '                    ' as \"--4.DB Character\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "col PARAMETER for a20
col value for a20
select * from v\$nls_parameters where parameter='NLS_CHARACTERSET';" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  5.归档状态"
echo "select '                    ' as \"--5.DB Archive Mode\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 333
show parameter log_archive" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  6.参数设置"
echo "select '                    ' as \"--6.Parameter Config\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 500
set pages 2000
show parameter;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  7.回滚段存储位置"
echo "select '                    ' as \"--7.Undo Info\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 500
set pages 2000
SELECT SEGMENT_NAME, TABLESPACE_NAME, STATUS FROM DBA_ROLLBACK_SEGS;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  8.redolog"
echo "select '                    ' as \"--8.Redolog Files\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 200
set pages 2000
col MEMBER for a50
select a.member,a.group#,b.thread#,b.bytes,b.members,b.status
from v\$logfile a,v\$log b
where a.group#=b.group#;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  9.查看表空间大小及利用率"
echo "select '                    ' as \"--9.Tablespace Usage\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 200
set pages 2000
col TABLESPACENAME for a30
select substr(a.TABLESPACE_NAME,1,30) TablespaceName,
sum(a.bytes/1024/1024) as \"Totle_size(M)\",
sum(nvl(b.free_space1/1024/1024,0)) as \"Free_space(M)\",
sum(a.bytes/1024/1024)-sum(nvl(b.free_space1/1024/1024,0)) as \"Used_space(M)\",
round((sum(a.bytes/1024/1024)-sum(nvl(b.free_space1/1024/1024,0)))
*100/sum(a.bytes/1024/1024),2) as \"Used_percent%\" from dba_data_files a,
(select sum(nvl(bytes,0)) free_space1,file_id from dba_free_space
group by file_id) b where a.file_id = b.file_id(+) group by a.TABLESPACE_NAME
order by \"Used_percent%\";" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  10.数据文件"
echo "select '                    ' as \"--10.DB Files Info\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 300
set pagesize 500
col file_name format a80
col TABLESPACE_NAME for a30
select tablespace_name,file_id,status,bytes/1024/1024 FileSizeM,file_name from dba_data_files order by tablespace_name;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  11.查看数据文件的扩展方式"
echo "select '                    ' as \"--11.DB Files Extend\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 300
set pagesize 500
col FILE_NAME for a60
col TABLESPACE_NAME for a30
select file_id,file_name,tablespace_name,autoextensible 
from dba_data_files order by file_id;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  12.查看表空间的扩展方式"
echo "select '                    ' as \"--12.TBS Extend\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 120
select TABLESPACE_NAME, BLOCK_SIZE, EXTENT_MANAGEMENT, SEGMENT_SPACE_MANAGEMENT 
from dba_tablespaces;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  13.临时表空间"
echo "select '                    ' as \"--13.DB Temp TBS\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "select FILE_NAME, FILE_ID, TABLESPACE_NAME, BYTES/1024/1024 \"BYTES(M)\", USER_BYTES/1024/1024 \"USER_BYTES(M)\", status from dba_temp_files;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  14.用户默认表空间"
echo "select '                     ' as \"--14.User Default TBS\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set lines 200
set pages 2000
col username for a20
col default_tablespace for a30
col temporary_tablespace for a30
select username, default_tablespace, temporary_tablespace from dba_users;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  15.数据库缓冲区高速缓存命中率"
echo "select '                    ' as \"--15.DB Cache Hit\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "select 1-(phy.value/(cur.value+con.value))
from v\$sysstat cur, v\$sysstat con, v\$sysstat phy
where cur.name = 'db block gets' 
and con.name = 'consistent gets' 
and phy.name = 'physical reads';" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  16.重写不等待比率"
echo "select '                    ' as \"--16.Redo nowaits\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "select (req.value*5000)/entries.value
from v\$sysstat req,v\$sysstat entries
where req.name = 'redo log space requests'
and entries.name = 'redo entires';" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  17.库高速缓存命中率"
echo "select '                    ' as \"--17.Library Cache Hit\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "select namespace,gethitratio from v\$librarycache;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  18.数据字典高速缓存Getmisses对gets的目标比例"
echo "select '                    ' as \"--18.DB Dic cache\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "select sum(getmisses)/sum(gets) from v\$rowcache;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  19.用户对像（表、索引、大小）"
echo "select '                    ' as \"--19.User objects\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "col OWNER for a30
col SEGMENT_NAME for a33
col PARTITION_NAME for a22
col SEGMENT_TYPE for a11
col TABLESPACE_NAME for a30
set lines 333
set pages 5000
select OWNER ,SEGMENT_NAME,PARTITION_NAME,SEGMENT_TYPE,TABLESPACE_NAME,bytes/1024/1024 as table_size_M 
from  Dba_Segments where SEGMENT_TYPE='TABLE' order by OWNER;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
  
echo "########################  20.检查是否有失效的索引"
echo "select '                      ' as \"--20.Check invalid Ind\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set lines 333
set pages 50
select index_name, owner, status, tablespace_name 
 from dba_indexes
 where owner not in('SYS','SYSTEM')
 and status != 'VALID'
 and tablespace_name is not null 
union all 
select index_name, index_owner owner, status, tablespace_name
 from dba_ind_partitions
 where index_owner not in ('SYS','SYSTEM')
 and status <> 'USABLE'
 and tablespace_name is not null;
select '' as a from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  21.检查数据库会话连接占用率"
echo "select '                    ' as \"--21.Check DB Sessions\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "col TOT_SESSIONS for a15
select cur_sessions, tot_sessions, a.cur_sessions/b.tot_sessions*100 \"sessions used%\"
from (select count(*) cur_sessions from v\$session) a,
(select value tot_sessions from v\$parameter where name = 'sessions') b;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  22.检查数据库会话连接历史最高值"
echo "select '                         ' as \"--22.Highwater of Session\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "select HIGHWATER
 from dba_high_water_mark_statistics
 where name = 'SESSIONS';" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour

echo "########################  23.检查数据库Job状态"
echo "select '                      ' as \"--23.Check Status of Job\" from dual;" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
echo "set linesize 333
col what for a30
col NEXT_DATE for a30 
col INTERVAL for a30
select job, what, next_date, INTERVAL, BROKEN
 from dba_jobs
 where BROKEN != 'N';" >my_sql.sql
sqlplus $sqlstr <my_sql.sql>>archive/${hostn}_oracle_$hour
######################################################################

echo "Collection completed."
echo "The Collected result saved in ./archive/${hostn}_oracle_$hour."
echo ""
