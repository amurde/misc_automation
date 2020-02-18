select DF.TOTAL/1048576 "DataFile Size Mb", LOG.TOTAL/1048576 "Redo Log Size Mb",
CONTROL.TOTAL/1048576 "Control File Size Mb", 
(DF.TOTAL + LOG.TOTAL + CONTROL.TOTAL)/1048576 "Total Size Mb" from dual,
(select sum(a.bytes) TOTAL from dba_data_files a) DF,
(select sum(b.bytes) TOTAL from v$log b) LOG,
(select sum((cffsz+1)*cfbsz) TOTAL from x$kcccf c) CONTROL;
