xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'NO-UNUSED-VARIABLES';

(: ALL VARIABLES ARE USED :)
let $query := 
'
query ($a: String, $b: String, $c: String) {
    field(a: $a, b: $b, c: $c)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ALL VARIABLES ARE USED DEEPLY :)
let $query := 
'
query Foo($a: String, $b: String, $c: String) {
    field(a: $a) {
        field(b: $b) {
            field(c: $c)
        }
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ALL VARIABLES ARE USED DEEPLY IN INLINE FRAGMENTS:)
let $query := 
'
query Foo($a: String, $b: String, $c: String) {
    ... on Type {
        field(a: $a) {
            field(b: $b) {
                ... on Type {
                    field(c: $c)
                }
            }
        }
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ALL VARIABLES ARE USED IN FRAGMENTS:)
let $query := 
'
query Foo($a: String, $b: String, $c: String) {
    ...FragA
}
fragment FragA on Type {
    field(a: $a) {
        ...FragB
    }
}
fragment FragB on Type {
    field(b: $b) {
        ...FragC
    }
}
fragment FragC on Type {
    field(c: $c)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: VARIABLES USED BY FRAGMENT IN MULTIPLE OPERATIONS:)
let $query := 
'
query Foo($a: String) {
    ...FragA
}
query Bar($b: String) {
    ...FragB
}
fragment FragA on Type {
    field(a: $a)
}
fragment FragB on Type {
    field(b: $b)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: VARIABLES USED BY RECURSIVE FRAGMENTS :)
let $query := 
'
query Foo($a: String) {
    ...FragA
}
fragment FragA on Type {
    field(a: $a) {
        ...FragA
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: VARIABLE NOT USED :)
let $query := 
'
query ($a: String, $b: String, $c: String) {
    field(a: $a, b: $b)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [c] is never used.", "locations":[{"line":2, "column":33}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[c]')])
)
,
(: MULTIPLE VARIABLES NOT USED :)
let $query := 
'
query Foo($a: String, $b: String, $c: String) {
    field(b: $b)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [a] is never used by operation [Foo].", "locations":[{"line":2, "column":12}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [c] is never used by operation [Foo].", "locations":[{"line":2, "column":36}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[a]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[c]')])
)
,
(: VARIABLE NOT USED IN FRAGMENT :)
let $query := 
'
query Foo($a: String, $b: String, $c: String) {
    ...FragA
}
fragment FragA on Type {
    field(a: $a) {
        ...FragB
    }
}
fragment FragB on Type {
    field(b: $b) {
        ...FragC
    }
}
fragment FragC on Type {
    field
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [c] is never used by operation [Foo].", "locations":[{"line":2, "column":36}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[c]')])
)
,
(: MULTIPLE VARIABLES NOT USED :)
let $query := 
'
query Foo($a: String, $b: String, $c: String) {
    ...FragA
}
fragment FragA on Type {
    field {
        ...FragB
    }
}
fragment FragB on Type {
    field(b: $b) {
        ...FragC
    }
}
fragment FragC on Type {
    field
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [a] is never used by operation [Foo].", "locations":[{"line":2, "column":12}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [c] is never used by operation [Foo].", "locations":[{"line":2, "column":36}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[a]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[c]')])
)
,
(: VARIABLE NOT USED BY UNREFERENCED FRAGMENT :)
let $query := 
'
query Foo($b: String) {
    ...FragA
}
fragment FragA on Type {
    field(a: $a)
}
fragment FragB on Type {
    field(b: $b)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [b] is never used by operation [Foo].", "locations":[{"line":2, "column":12}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[b]')])
)
,
(: VARIABLE NOT USED BY FRAGMENT USED BY OTHER OPERATION :)
let $query := 
'
query Foo($b: String) {
    ...FragA
}
query Bar($a: String) {
    ...FragB
}
fragment FragA on Type {
    field(a: $a)
}
fragment FragB on Type {
    field(b: $b)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [b] is never used by operation [Foo].", "locations":[{"line":2, "column":12}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNUSED-VARIABLES", "message":"Variable [a] is never used by operation [Bar].", "locations":[{"line":5, "column":12}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[b]') and fn:contains(./message, '[Foo]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[a]') and fn:contains(./message, '[Bar]')])
)
