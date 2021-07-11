# vim:set ft= ts=4 sw=4 et fdm=marker:

use strict;
use lib '.';
use t::TestWasm;

skip_valgrind();

plan tests => repeat_each() * (blocks() * 5);

run_tests();

__DATA__

=== TEST 1: proxy_wasm - set_request_header() sets a new non-builtin header
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Hello:wasm';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- response_body
Host: localhost
Connection: close
Hello: wasm
--- grep_error_log eval: qr/\[wasm\].*? #\d+ on_request_headers.*/
--- grep_error_log_out eval
qr/\[wasm\] #\d+ on_request_headers, 2 headers
\[wasm\] #\d+ on_request_headers, 3 headers/
--- no_error_log
[error]
[crit]



=== TEST 2: proxy_wasm - set_request_header() sets a new non-builtin header (case-sensitive)
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=hello:wasm';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- response_body
Host: localhost
Connection: close
hello: wasm
--- grep_error_log eval: qr/\[wasm\].*? #\d+ on_request_headers.*/
--- grep_error_log_out eval
qr/\[wasm\] #\d+ on_request_headers, 2 headers
\[wasm\] #\d+ on_request_headers, 3 headers/
--- no_error_log
[error]
[crit]



=== TEST 3: proxy_wasm - set_request_header() sets a non-builtin headers when many headers exist
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Header20:updated';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- more_headers eval
(CORE::join "\n", map { "Header$_: value-$_" } 1..20)
--- response_body eval
qq{Host: localhost
Connection: close
}.(CORE::join "\n", map { "Header$_: value-$_" } 1..19)
. "\nHeader20: updated\n"
--- no_error_log
[error]
[crit]
[alert]



=== TEST 4: proxy_wasm - set_request_header() removes an existing non-builtin header when no value
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Wasm:';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- more_headers
Wasm: incoming
--- response_body
Host: localhost
Connection: close
--- no_error_log
[error]
[crit]
[alert]



=== TEST 5: proxy_wasm - set_request_header() sets the same non-builtin header multiple times
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Hello:wasm';
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Hello:wasm';
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Hello:wasm';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- more_headers
Hello: invalid
--- response_body
Host: localhost
Connection: close
Hello: wasm
--- grep_error_log eval: qr/\[wasm\].*? #\d+ on_request_headers.*/
--- grep_error_log_out eval
qr/\[wasm\] #\d+ on_request_headers, 3 headers
\[wasm\] #\d+ on_request_headers, 3 headers
\[wasm\] #\d+ on_request_headers, 3 headers
\[wasm\] #\d+ on_request_headers, 3 headers/
--- no_error_log
[error]
[crit]



=== TEST 6: proxy_wasm - set_request_header() sets Connection header (close) when many headers exist
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Connection:close';
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Connection:close';
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Connection:close';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- more_headers eval
(CORE::join "\n", map { "Header$_: value-$_" } 1..20)
. "\nConnection: keep-alive\n"
--- response_body eval
qq{Host: localhost
}.(CORE::join "\n", map { "Header$_: value-$_" } 1..20)
. "\nConnection: close\n"
--- grep_error_log eval: qr/\[wasm\].*? #\d+ on_request_headers.*/
--- grep_error_log_out eval
qr/\[wasm\] #\d+ on_request_headers, 22 headers
\[wasm\] #\d+ on_request_headers, 22 headers
\[wasm\] #\d+ on_request_headers, 22 headers/
--- no_error_log
[error]
[crit]



=== TEST 7: proxy_wasm - set_request_header() sets Connection header (keep-alive)
--- abort
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Connection:keep-alive';
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Connection:keep-alive';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- more_headers
Connection: close
--- response_body
Host: localhost
Connection: keep-alive
--- grep_error_log eval: qr/\[wasm\].*? #\d+ on_request_headers.*/
--- grep_error_log_out eval
qr/\[wasm\] #\d+ on_request_headers, 2 headers
\[wasm\] #\d+ on_request_headers, 2 headers
\[wasm\] #\d+ on_request_headers, 2 headers/
--- no_error_log
[error]
[crit]



=== TEST 8: proxy_wasm - set_request_header() sets Connection header (closed)
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Connection:closed';
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Connection:closed';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- response_body
Host: localhost
Connection: closed
--- grep_error_log eval: qr/\[wasm\].*? #\d+ on_request_headers.*/
--- grep_error_log_out eval
qr/\[wasm\] #\d+ on_request_headers, 2 headers
\[wasm\] #\d+ on_request_headers, 2 headers
\[wasm\] #\d+ on_request_headers, 2 headers/
--- no_error_log
[error]
[crit]



=== TEST 9: proxy_wasm - set_request_header() sets Content-Length header
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Content-Length:0';
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Content-Length:0';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- more_headers
Content-Length: 10
--- response_body
Host: localhost
Connection: close
Content-Length: 0
--- grep_error_log eval: qr/\[wasm\].*? #\d+ on_request_headers.*/
--- grep_error_log_out eval
qr/\[wasm\] #\d+ on_request_headers, 3 headers
\[wasm\] #\d+ on_request_headers, 3 headers
\[wasm\] #\d+ on_request_headers, 3 headers/
--- no_error_log
[error]
[crit]



=== TEST 10: proxy_wasm - set_request_header() removes Content-Length header when no value
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Content-Length:';
        proxy_wasm hostcalls 'test_case=/t/set_request_header \
                              value=Content-Length:';
        proxy_wasm hostcalls 'test_case=/t/echo/headers';
    }
--- more_headers
Content-Length: 10
--- response_body
Host: localhost
Connection: close
--- grep_error_log eval: qr/\[wasm\].*? #\d+ on_request_headers.*/
--- grep_error_log_out eval
qr/\[wasm\] #\d+ on_request_headers, 3 headers
\[wasm\] #\d+ on_request_headers, 2 headers
\[wasm\] #\d+ on_request_headers, 2 headers/
--- no_error_log
[error]
[crit]



=== TEST 11: proxy_wasm - set_request_header() x on_phases
should log an error (but no trap) when response is produced
--- wasm_modules: hostcalls
--- config
    location /t {
        proxy_wasm hostcalls 'on_phase=request_headers \
                              test_case=/t/set_request_header \
                              value=From:request_headers';
        proxy_wasm hostcalls 'on_phase=request_headers \
                              test_case=/t/echo/headers';
        proxy_wasm hostcalls 'on_phase=response_headers \
                              test_case=/t/set_request_header \
                              value=From:response_headers';
        proxy_wasm hostcalls 'on_phase=log \
                              test_case=/t/set_request_header \
                              value=From:log';
    }
--- more_headers
From: client
--- response_body_like
From: request_headers
--- grep_error_log eval: qr/\[(info|error|crit)\] .*?(?=(\s+<|,|\n))/
--- grep_error_log_out eval
qr/.*?
\[info\] .*? \[wasm\] #\d+ entering "RequestHeaders"
\[info\] .*? \[wasm\] #\d+ entering "RequestHeaders"
\[info\] .*? \[wasm\] #\d+ entering "ResponseHeaders"
\[error\] .*? \[wasm\] cannot set request header: response produced
\[info\] .*? \[wasm\] #\d+ entering "Log"
\[error\] .*? \[wasm\] cannot set request header: response produced/
--- no_error_log
[warn]
[crit]
