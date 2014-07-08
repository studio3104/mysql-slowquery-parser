# MySQLSlowQueryParser [![Build Status](https://travis-ci.org/studio3104/mysql-slowquery-parser.svg)](https://travis-ci.org/studio3104/mysql-slowquery-parser)

Slow query log parser for MySQL

## Installation

Add this line to your application's Gemfile:

    gem 'mysql-slowquery-parser'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install mysql-slowquery-parser

## Usage

```ruby
slowquery = <<SLOW
/usr/local/Cellar/mysql/5.6.12/bin/mysqld, Version: 5.6.12 (Source distribution). started with:
Tcp port: 3306  Unix socket: /tmp/mysql.sock
Time                 Id Command    Argument
# Time: 140128 13:39:11
# User@Host: [user] @ localhost []  Id:     8
# Query_time: 2.001227  Lock_time: 0.000000 Rows_sent: 1  Rows_examined: 0
SET timestamp=1390883951;
SELECT
  *
FROM
  mysql.user;
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
SLOW
```

```ruby
MySQLSlowQueryParser.parse(slowquery)
```

```ruby
[
  {
    datetime: 1390883951,
    user: 'user',
    host: 'localhost',
    query_time: 2.001227,
    lock_time: 0.0,
    rows_sent: 1,
    rows_examined: 0,
    sql: 'SELECT\n  *\nFROM\n  mysql.user'
  },
  {
    datetime: 1395761816,
    user: 'root',
    host: 'localhost',
    query_time: 10.00114,
    lock_time: 0.0,
    rows_sent: 1,
    rows_examined: 0,
    sql: 'select sleep(10)'
  },
  {
    datetime: 1395761831,
    user: 'root',
    host: 'localhost',
    query_time: 10.001114,
    lock_time: 0.0,
    rows_sent: 1,
    rows_examined: 0,
    db: 'mysql',
    sql: 'select sleep(10)'
  }
]
```

## Contributing

1. Fork it ( https://github.com/studio3104/mysql-slowquery-parser/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request
