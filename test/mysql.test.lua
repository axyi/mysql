#!/usr/bin/env tarantool

package.path = "../?/init.lua;./?/init.lua"
package.cpath = "../?.so;../?.dylib;./?.so;./?.dylib"

local mysql = require('mysql')
local json = require('json')

require('tap').test('mysql', function(t)
    t:plan(16)
    local host, port, user, password, db = string.match(os.getenv('MYSQL') or '',
        "([^:]*):([^:]*):([^:]*):([^:]*):([^:]*)")

    local c, err = mysql.connect({ host = host, port = port, user = user,
        password = password, db = db, raise = false })
    t:ok(c ~= nil, "connection")
    -- Add an extension to 'tap' module
    getmetatable(t).__index.q = function(test, stmt, result, ...)
        test:is_deeply(c:execute(stmt, ...), result,
            ... ~= nil and stmt..' % '..json.encode({...}) or stmt)
    end
    t:ok(c:ping(), "ping")
    if c == nil then
        return
    end
    t:q("SELECT '123' AS bla, 345", {{ bla = '123', ['345'] = 345 }})
    t:q('SELECT -1 AS neg, NULL AS abc', {{ neg = -1 }})
    t:q('SELECT -1.1 AS neg, 1.2 AS pos', {{ neg = "-1.1", pos = "1.2" }})
    t:q('SELECT ? AS val', {{ val = 'abc' }}, 'abc')
    t:q('SELECT ? AS val', {{ val = '1' }}, '1')
    t:q('SELECT ? AS val', {{ val = 123 }},123)
    t:q('SELECT ? AS val', {{ val = 1 }}, true)
    t:q('SELECT ? AS val', {{ val = 0 }}, false)
    t:q('SELECT ? AS val, ? AS num, ? AS str',
        {{ val = 0, num = 123, str = 'abc'}}, false, 123, 'abc')
    t:q('SELECT ? AS bool1, ? AS bool2, ? AS nil, ? AS num, ? AS str',
        {{ bool1 = 1, bool2 = 0, num = 123, str = 'abc' }}, true, false, nil,
        123, 'abc')
    t:q('SELECT 1 AS one UNION ALL SELECT 2', {{ one = 1}, { one = 2}})

    t:test("tx", function(t)
        t:plan(8)
        if not c:execute("CREATE TEMPORARY TABLE _tx_test (a int)") then
            return
        end

        t:ok(c:begin(), "begin")
        local tuples, nrows = c:execute("INSERT INTO _tx_test VALUES(10)");
        t:is(nrows, 1, "nrows")
        t:q('SELECT * FROM _tx_test', {{ a  = 10 }})
        t:ok(c:rollback(), "roolback")
        t:q('SELECT * FROM _tx_test', {})

        t:ok(c:begin(), "begin")
        c:execute("INSERT INTO _tx_test VALUES(10)");
        t:ok(c:commit(), "commit")
        t:q('SELECT * FROM _tx_test', {{ a  = 10 }})

        c:execute("DROP TABLE _tx_test")
    end)

    t:q('DROP TABLE IF EXISTS unknown_table', {})
    local tuples, reason = c:execute('DROP TABLE unknown_table')
    t:like(reason, 'unknown_table', 'error')
    t:ok(c:close(), "close")
end)
