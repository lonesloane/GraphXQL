xquery version "1.0-ml";

import module namespace lex = "http://graph.x.ql/lexer" at "/graphXql/lexer.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

declare namespace s = "http://www.w3.org/2005/xpath-functions";


(: 
    BANG: '!'
:)
let $string := '! with a bang'
let $result := fn:analyze-string($string, '^('||$lex:BANG-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    DOLLAR: '$'
:)
let $string := '$ with a dollar'
let $result := fn:analyze-string($string, '^('||$lex:DOLLAR-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    PAREN_L: '\('
:)
let $string := '( left paren'
let $result := fn:analyze-string($string, '^('||$lex:PAREN_L-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    PAREN_R: '\)'
:)
let $string := ') right paren'
let $result := fn:analyze-string($string, '^('||$lex:PAREN_R-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    SPREAD: '\.\.\.'
:)
let $string := '... spread all over'
let $result := fn:analyze-string($string, '^('||$lex:SPREAD-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    COLON: ':'
:)
let $string := ': colon'
let $result := fn:analyze-string($string, '^('||$lex:COLON-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    EQUALS: '='
:)
let $string := '= equals'
let $result := fn:analyze-string($string, '^('||$lex:EQUALS-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    AT: '@'
:)
let $string := '@ at'
let $result := fn:analyze-string($string, '^('||$lex:AT-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    BRACKET_L: '\['
:)
let $string := '[ left bracket'
let $result := fn:analyze-string($string, '^('||$lex:BRACKET_L-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    BRACKET_R: '\]'
:)
let $string := '] right bracket'
let $result := fn:analyze-string($string, '^('||$lex:BRACKET_R-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    BRACE_L: '{'
:)
let $string := '{ left brace'
let $result := fn:analyze-string($string, '^('||$lex:BRACE_L-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    PIPE: '\|'
:)
let $string := '| pipe'
let $result := fn:analyze-string($string, '^('||$lex:PIPE-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    BRACE_R: '}'
:)
let $string := '} right brace'
let $result := fn:analyze-string($string, '^('||$lex:BRACE_R-REGEXP||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    BooleanLiteral : "true|false" 
:)
let $regex := map:get($lex:lexer-regex-map, $lex:BooleanLiteral-ID)
return (
    test:assert-equal('true|false',$regex)
)
,
let $string := 'true'
let $regex := map:get($lex:lexer-regex-map, $lex:BooleanLiteral-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
let $string := 'false'
let $regex := map:get($lex:lexer-regex-map, $lex:BooleanLiteral-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    NAME : "[_A-Za-z][_0-9A-Za-z]*" 
:)
let $regex := map:get($lex:lexer-regex-map, $lex:NAME-ID)
return (
    test:assert-equal('[_A-Za-z][_0-9A-Za-z]*',$regex)
)
,
let $string := 'likeStory'
let $regex := map:get($lex:lexer-regex-map, $lex:NAME-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    String_ : STRING|BLOCK_STRING 

let $regex := map:get($lex:lexer-regex-map, $lex:String_-ID)
return (
    test:assert-equal('("""[\W]*?.*?[\W]*?"""|(\\(["\\/bfnrt]|u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])|"[^"\\]*"))',$regex)
)
,
let $string := '"This is a string"'
let $regex := map:get($lex:lexer-regex-map, $lex:String_-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,:)
(: 
    STRING : "(ESC|~["\\])*"; 
:)
let $regex := map:get($lex:lexer-regex-map, $lex:STRING-ID)
return (
    test:assert-equal('(\\(["\\/bfnrt]|u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])|"[^"\\]*")',$regex)
)
,
let $string := '"This is a string"'
let $regex := map:get($lex:lexer-regex-map, $lex:STRING-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    BLOCK_STRING : '""".*?"""'; 

let $regex := map:get($lex:lexer-regex-map, $lex:BLOCK_STRING-ID)
return (
    test:assert-equal('""".*?"""',$regex)
)
,
let $string := '"""block string"""'
let $regex := map:get($lex:lexer-regex-map, $lex:BLOCK_STRING-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,:)
(: 
    ID := STRING 

let $regex := map:get($lex:lexer-regex-map, $lex:ID-ID)
return (
    test:assert-equal('(\\(["\\/bfnrt]|u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])|"[^"\\]*")',$regex)
)
,
let $string := '"This is a string"'
let $regex := map:get($lex:lexer-regex-map, $lex:String_-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,:)
(: 
    ESC : \\(["\\/bfnrt]|UNICODE) 

let $regex := map:get($lex:lexer-regex-map, $lex:ESC-ID)
return (
    test:assert-equal('\\(["\\/bfnrt]|u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F])',$regex)
)
,
let $string := '\u0FF9'
let $regex := map:get($lex:lexer-regex-map, $lex:ESC-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,:)
(: 
    UNICODE : uHEXHEXHEXHEX 

let $regex := map:get($lex:lexer-regex-map, $lex:UNICODE-ID)
return (
    test:assert-equal('u[0-9a-fA-F][0-9a-fA-F][0-9a-fA-F][0-9a-fA-F]',$regex)
)
,
let $string := 'u0FF9'
let $regex := map:get($lex:lexer-regex-map, $lex:UNICODE-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,:)
(: 
    HEX : [0-9a-fA-F] 

let $regex := map:get($lex:lexer-regex-map, $lex:HEX-ID)
return (
    test:assert-equal('[0-9a-fA-F]',$regex)
)
,
let $string := '0'
let $regex := map:get($lex:lexer-regex-map, $lex:HEX-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,:)
(: 
    NUMBER : -?INT.[0-9]+EXP?|'-'?INTEXP|-?INT 
:)
let $regex := map:get($lex:lexer-regex-map, $lex:NUMBER-ID)
return (
    test:assert-equal('[+-]?(\d+([.]\d*)?(e[+-]?\d+)?|[.]\d+(e[+-]?\d+)?)',$regex)
)
,
let $string := '123.4e-02'
let $regex := map:get($lex:lexer-regex-map, $lex:NUMBER-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('123.4e-02',$result//s:match/string())
)
,
(: 
    INT : 0|[1-9][0-9]* 

let $regex := map:get($lex:lexer-regex-map, $lex:INT-ID)
return (
    test:assert-equal('0|[1-9][0-9]*',$regex)
)
,
let $string := '123098'
let $regex := map:get($lex:lexer-regex-map, $lex:INT-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,:)
(: 
    EXP : [Ee][+\-]?INT 

let $regex := map:get($lex:lexer-regex-map, $lex:EXP-ID)
return (
    test:assert-equal('[Ee][+\-]?0|[1-9][0-9]*',$regex)
)
,
let $string := 'e+02'
let $regex := map:get($lex:lexer-regex-map, $lex:EXP-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,:)
(:
    WS : [ \t\n\r]+ 
:)
let $regex := map:get($lex:lexer-regex-map, $lex:WS-ID)
return (
    test:assert-equal('[ \t\n\r]+',$regex)
)
,
let $string := '    '
let $regex := map:get($lex:lexer-regex-map, $lex:WS-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
,
(: 
    LineComment : #~[\r\n]* 
:)
let $regex := map:get($lex:lexer-regex-map, $lex:LineComment-ID)
return (
    test:assert-equal('#[^\r\n]*',$regex)
)
,
let $string := '# this is a comment'
let $regex := map:get($lex:lexer-regex-map, $lex:LineComment-ID)
let $result := fn:analyze-string($string, '^('||$regex||')', '')
return (
    test:assert-true(fn:exists($result//s:match)),
    test:assert-equal('1',$result//s:match/s:group/@nr/string())
)
