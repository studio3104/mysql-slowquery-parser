require 'spec_helper'
require 'mysql-slowquery-parser'

describe MySQLSlowQueryParser do
  let(:parser) { MySQLSlowQueryParser }
  let(:mysql_raw_slow_logs) {
    <<-EOF
/usr/local/Cellar/mysql/5.6.12/bin/mysqld, Version: 5.6.12 (Source distribution). started with:
Tcp port: 3306  Unix socket: /tmp/mysql.sock
Time                 Id Command    Argument
# Time: 140128 13:39:11
# User@Host: [user] @ localhost []  Id:     8
# Query_time: 2.001227  Lock_time: 0.000000 Rows_sent: 1  Rows_examined: 0
SET timestamp=1390883951;
select sleep(2);
/usr/local/Cellar/mysql/5.6.12/bin/mysqld, Version: 5.6.12 (Source distribution). started with:
Tcp port: 3306  Unix socket: /tmp/mysql.sock
Time                 Id Command    Argument
# Time: 140326  0:36:56
# User@Host: root[root] @ localhost []  Id:    51
# Query_time: 10.001140  Lock_time: 0.000000 Rows_sent: 1  Rows_examined: 0
SET timestamp=1395761816;
select sleep(10);
# Time: 140326  0:37:11
# User@Host: root[root] @ localhost []  Id:    51
# Query_time: 10.001114  Lock_time: 0.000000 Rows_sent: 1  Rows_examined: 0
use mysql;
SET timestamp=1395761831;
select sleep(10);
    EOF
  }
  let(:percona_raw_slow_logs) {
    <<-EOF
# Time: 120913 12:58:21
# User@Host: root[root] @ localhost []
# Thread_id: 45  Schema: sbtest  Last_errno: 0  Killed: 0
# Query_time: 34.452360  Lock_time: 0.000134  Rows_sent: 50  Rows_examined: 8800050  Rows_affected: 0  Rows_read: 50
# Bytes_sent: 3499  Tmp_tables: 1  Tmp_disk_tables: 1  Tmp_table_sizes: 2450800000
# InnoDB_trx_id: B08
# QC_Hit: No  Full_scan: Yes  Full_join: No  Tmp_table: Yes  Tmp_table_on_disk: Yes
# Filesort: Yes  Filesort_on_disk: Yes  Merge_passes: 202
#   InnoDB_IO_r_ops: 58994  InnoDB_IO_r_bytes: 966557696  InnoDB_IO_r_wait: 8.327283
#   InnoDB_rec_lock_wait: 0.000000  InnoDB_queue_wait: 0.000000
#   InnoDB_pages_distinct: 60281
SET timestamp=1347508701;
SELECT * FROM sbtest ORDER BY RAND() LIMIT 50;
/usr/sbin/mysqld, Version: 5.5.34-32.0-log (Percona Server (GPL), Release rel32.0, Revision 591). started with:
Tcp port: 3306  Unix socket: /var/lib/mysql/mysql.sock
Time                 Id Command    Argument
# Time: 131226 19:07:02
# User@Host: user[user] @  [192.168.10.11]
# Thread_id: 9510259  Schema: sbtest  Last_errno: 0  Killed: 0
# Query_time: 4.901885  Lock_time: 0.000065  Rows_sent: 8309  Rows_examined: 69763781  Rows_affected: 0  Rows_read: 69763781
# Bytes_sent: 802732
SET timestamp=1388052422;
SELECT
        *
FROM
        sbtest;
    EOF
  }

  let(:percona_raw_slow_logs_without_Schema) {
    <<-EOF
# Time: 120913 12:58:21
# User@Host: root[root] @ localhost []
# Thread_id: 45  Schema:   Last_errno: 0  Killed: 0
# Query_time: 34.452360  Lock_time: 0.000134  Rows_sent: 50  Rows_examined: 8800050  Rows_affected: 0  Rows_read: 50
# Bytes_sent: 3499  Tmp_tables: 1  Tmp_disk_tables: 1  Tmp_table_sizes: 2450800000
# InnoDB_trx_id: B08
# QC_Hit: No  Full_scan: Yes  Full_join: No  Tmp_table: Yes  Tmp_table_on_disk: Yes
# Filesort: Yes  Filesort_on_disk: Yes  Merge_passes: 202
#   InnoDB_IO_r_ops: 58994  InnoDB_IO_r_bytes: 966557696  InnoDB_IO_r_wait: 8.327283
#   InnoDB_rec_lock_wait: 0.000000  InnoDB_queue_wait: 0.000000
#   InnoDB_pages_distinct: 60281
SET timestamp=1347508701;
SELECT * FROM sbtest ORDER BY RAND() LIMIT 50;
    EOF
  }

  describe '#split_raw_slow_logs' do
    context 'MySQL' do
      let(:split_log) { parser.split_raw_slow_logs(mysql_raw_slow_logs) }
      it { expect(split_log.size).to eq(3) }
    end
    context 'Percona' do
      let(:split_log) { parser.split_raw_slow_logs(percona_raw_slow_logs) }
      it { expect(split_log.size).to eq(2) }
    end
    context 'Percona without Schema' do
      let(:split_log_without_Schema) { parser.split_raw_slow_logs(percona_raw_slow_logs_without_Schema) }
      it { expect(split_log_without_Schema.size).to eq(1) }
    end
  end

  describe '#parse_slow_log' do
    context 'MySQL' do
      let(:split_log) { parser.split_raw_slow_logs(mysql_raw_slow_logs) }
      let(:parsed_logs) { split_log.map { |l| parser.parse_slow_log(l) } }

      it { expect(parsed_logs.size).to eq(3) }
      it do
        expect(parsed_logs).to eq([
          {
            datetime: 1390883951, user: 'user', host: 'localhost',
            query_time: 2.001227, lock_time: 0.0, rows_sent: 1, rows_examined:0,
            sql: 'select sleep(2)'
          },
          {
            datetime: 1395761816, user: 'root', host: 'localhost',
            query_time: 10.00114, lock_time: 0.0, rows_sent: 1, rows_examined: 0,
            sql: 'select sleep(10)'
          },
          {
            datetime: 1395761831, user: 'root', host: 'localhost',
            query_time: 10.001114, lock_time: 0.0, rows_sent: 1, rows_examined: 0, 
            db: 'mysql', sql: 'select sleep(10)'
          }
        ])
      end
    end

    context 'Percona' do
      let(:split_log) { parser.split_raw_slow_logs(percona_raw_slow_logs) }
      let(:parsed_logs) { split_log.map { |l| parser.parse_slow_log(l) } }

      it { expect(parsed_logs.size).to eq(2) }
      it do
        expect(parsed_logs).to eq([
          {
            datetime: 1347508701, user: 'root', host: 'localhost',
            thread_id: 45, schema: 'sbtest', last_errno: 0, killed: 0,
            query_time: 34.45236, lock_time: 0.000134, rows_sent: 50, rows_examined: 8800050, rows_affected: 0, rows_read: 50,
            bytes_sent: 3499, tmp_tables: 1, tmp_disk_tables: 1, tmp_table_sizes: 2450800000,
            innodb_trx_id: 'B08',
            qc_hit: 'No',
            full_scan: 'Yes', full_join: 'No', tmp_table: 'Yes', tmp_table_on_disk: 'Yes',
            filesort: 'Yes', filesort_on_disk: 'Yes', merge_passes: 202,
            innodb_io_r_ops: 58994, innodb_io_r_bytes: 966557696, innodb_io_r_wait: 8.327283,
            innodb_rec_lock_wait: 0.0, innodb_queue_wait: 0.0, 
            innodb_pages_distinct: 60281,
            sql: 'SELECT * FROM sbtest ORDER BY RAND() LIMIT 50'
          },
          {
            datetime: 1388052422, user: 'user', host: '192.168.10.11',
            thread_id: 9510259, schema: 'sbtest', last_errno: 0, killed: 0,
            query_time: 4.901885, lock_time: 6.5e-05, rows_sent: 8309, rows_examined: 69763781, rows_affected: 0, rows_read: 69763781,
            bytes_sent: 802732,
            sql: "SELECT\n        *\nFROM\n        sbtest"
          }
        ])
      end
    end

    context 'Percona without Schema' do
      let(:split_log_without_Schema) { parser.split_raw_slow_logs(percona_raw_slow_logs_without_Schema) }
      let(:parsed_logs_without_Schema) { split_log_without_Schema.map { |l| parser.parse_slow_log(l) } }

      it { expect(parsed_logs_without_Schema.size).to eq(1) }
      it do
        expect(parsed_logs_without_Schema).to eq([
          {
            datetime: 1347508701, user: 'root', host: 'localhost',
            thread_id: 45, schema: nil, last_errno: 0, killed: 0,
            query_time: 34.45236, lock_time: 0.000134, rows_sent: 50, rows_examined: 8800050, rows_affected: 0, rows_read: 50,
            bytes_sent: 3499, tmp_tables: 1, tmp_disk_tables: 1, tmp_table_sizes: 2450800000,
            innodb_trx_id: 'B08',
            qc_hit: 'No',
            full_scan: 'Yes', full_join: 'No', tmp_table: 'Yes', tmp_table_on_disk: 'Yes',
            filesort: 'Yes', filesort_on_disk: 'Yes', merge_passes: 202,
            innodb_io_r_ops: 58994, innodb_io_r_bytes: 966557696, innodb_io_r_wait: 8.327283,
            innodb_rec_lock_wait: 0.0, innodb_queue_wait: 0.0, 
            innodb_pages_distinct: 60281,
            sql: 'SELECT * FROM sbtest ORDER BY RAND() LIMIT 50'
          },
        ])
      end
    end
  end
end
