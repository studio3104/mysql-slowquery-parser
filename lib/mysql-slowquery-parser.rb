require 'time'

class MySQLSlowQueryParser
  def self.parse(raw_slow_logs)
    split_raw_slow_logs(raw_slow_logs).map { |raw_slow_log|
      parse_slow_log(raw_slow_log)
    }
  end

  # 生スローログを意味のある単位に分割
  def self.split_raw_slow_logs(raw_slow_logs)
    result = []
    part = []

    raw_slow_logs.each_line do |line|
      part << line
      if line.end_with?(';', ";\n") && !line.start_with?('use ', 'SET timestamp=')
        result << part
        part = []
      end
    end

    result
  end

  def self.parse_slow_log(raw_slow_log)
    result = {}
    line = raw_slow_log.shift

    while !line.start_with?('#')
      # こういうのを suppress する
      #### /usr/local/Cellar/mysql/5.6.12/bin/mysqld, Version: 5.6.12 (Source distribution). started with:
      #### Tcp port: 3306  Unix socket: /tmp/mysql.sock
      line = raw_slow_log.shift
    end

    if record = line.match(/^# Time:\s+(.+)/)
      result[:datetime] = Time.parse(record[1]).to_i
      line = raw_slow_log.shift
    end

    if record = line.match(/^# User@Host: ([^\[]+)?\[([^\]]*)\] @ ([^\[]+)\[([^\]]*)\]/)
      result[:user] = record[1].nil? || record[1].empty? ? record[2] : record[1]
      result[:host] = record[3].nil? || record[3].strip.empty? ? record[4] : record[3].strip
      line = raw_slow_log.shift
    end

    # こういうのをハッシュにする
    #### # Query_time: 4.267253  Lock_time: 0.000017  Rows_sent: 0  Rows_examined: 734266  Rows_affected: 734266  Rows_read: 734266
    while line.start_with?('#')
      line = line.sub(/^#\s+/, '')

      # '  ' で split したかったけど、' ' で区切られてる場合(MacのMySQLで確認)もあったからこうした
      record = line.split(/\s+/).map { |val|
        case val
        when /\:$/
          val.sub(/\:$/, '').downcase.to_sym
        when /^\d+$/
          val.to_i
        when /^\d+\.\d+$/
          val.to_f
        else
          val
        end
      }

      # # Thread_id: 45  Schema:   Last_errno: 0  Killed: 0
      # ↑ の Schema みたいに、値がない場合に nil を埋めて対応する
      begin
        result = result.merge(Hash[*record])
      rescue ArgumentError # odd number of arguments for Hash
        _record = []
        record.each_with_index do |val, i|
          _record << val
          if val.is_a?(Symbol) && record[i+1].is_a?(Symbol)
            _record << nil
          end
        end
        _record << nil if _record.last.is_a?(Symbol)
        result = result.merge(Hash[*_record])
      end

      line = raw_slow_log.shift
    end

    if record = line.match(/^use (\w+);$/)
      result[:db] = record[1]
      line = raw_slow_log.shift
    end

    if record = line.match(/^SET timestamp=(\d+);$/)
      result[:datetime] = record[1].to_i
      line = raw_slow_log.shift
    end

    result[:sql] = line
    raw_slow_log.each do |l|
      result[:sql] = result[:sql] + l
    end
    result[:sql] = result[:sql].sub(/;$/, '')
    result[:sql] = result[:sql].strip

    result
  end
end
