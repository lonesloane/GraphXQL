xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'NO-UNDEFINED-VARIABLES';

(: ALL VARIABLES DEFINED :)
let $query := 
'
query Foo($a: String, $b: String, $c: String) {
    field(a: $a, b: $b, c: $c)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ALL VARIABLES DEEPLY DEFINED :)
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
(: ALL VARIABLES DEEPLY IN INLINE FRAGMENTS DEFINED :)
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
(: ALL VARIABLES IN FRAGMENTS DEEPLY DEFINED :)
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
(: VARIABLE WITHIN SINGLE FRAGMENT DEFINED IN MULTIPLE OPERATIONS :)
let $query := 
'
query Foo($a: String) {
    ...FragA
}
query Bar($a: String) {
    ...FragA
}
fragment FragA on Type {
    field(a: $a)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: VARIABLE WITHIN FRAGMENTS DEFINED IN OPERATIONS :)
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
(: VARIABLE WITHIN RECURSIVE FRAGMENT DEFINED :)
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
(: VARIABLE NOT DEFINED :)
let $query := 
'
query Foo($a: String, $b: String, $c: String) {
    field(a: $a, b: $b, c: $c, d: $d)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$d] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":3, "column":36}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$d')])
)
,
(: VARIABLE NOT DEFINED BY UN-NAMED QUERY:)
let $query := 
'
{
    field(a: $a)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$a] is not defined.", "locations":[{"line":3, "column":15}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$a')])
)
,
(: MULTIPLE VARIABLES NOT DEFINED :)
let $query := 
'
query Foo($b: String) {
    field(a: $a, b: $b, c: $c)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$a] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":3, "column":15}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$c] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":3, "column":29}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$a')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$c')])
)
,
(: VARIABLE IN FRAGMENT NOT DEFINED BY UN-NAMED QUERY :)
let $query := 
'
{
    ...FragA
}
fragment FragA on Type {
    field(a: $a)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$a] is not defined.", "locations":[{"line":6, "column":15}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$a')])
)
,
(: VARIABLE IN FRAGMENT NOT DEFINED BY OPERATION :)
let $query := 
'
query Foo($a: String, $b: String) {
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
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$c] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":16, "column":15}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$c')])
)
,
(: MULTIPLE VARIABLES IN FRAGMENTS NOT DEFINED :)
let $query := 
'
query Foo($b: String) {
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
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$a] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":6, "column":15}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$c] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":16, "column":15}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$a')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$c')])
)
,
(: SINGLE VARIABLE IN FRAGMENT NOT DEFINED BY MULTIPLE OPERATIONS :)
let $query := 
'
query Foo($a: String) {
    ...FragAB
}
query Bar($a: String) {
    ...FragAB
}
fragment FragAB on Type {
    field(a: $a, b: $b)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$b] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":9, "column":22}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$b] is not defined by operation [Bar].", "locations":[{"line":5, "column":7}, {"line":9, "column":22}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Foo')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Bar')])
)
,
(: VARIABLES IN FRAGMENT NOT DEFINED BY MULTIPLE OPERATIONS :)
let $query := 
'
query Foo($b: String) {
    ...FragAB
}
query Bar($a: String) {
    ...FragAB
}
fragment FragAB on Type {
    field(a: $a, b: $b)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$a] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":9, "column":15}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$b] is not defined by operation [Bar].", "locations":[{"line":5, "column":7}, {"line":9, "column":22}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$a') and fn:contains(./message, 'Foo')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$b') and fn:contains(./message, 'Bar')])
)
,
(: VARIABLE IN FRAGMENT USED BY OTHER OPERATION :)
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
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$a] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":9, "column":15}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$b] is not defined by operation [Bar].", "locations":[{"line":5, "column":7}, {"line":12, "column":15}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$a') and fn:contains(./message, 'Foo')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '$b') and fn:contains(./message, 'Bar')])
)
,
(: MULTIPLEUNDEFINED VARIABLES PRODUCE MULTIPLE ERRORS :)
let $query := 
'
query Foo($b: String) {
    ...FragAB
}
query Bar($a: String) {
    ...FragAB
}
fragment FragAB on Type {
    field1(a: $a, b: $b)
    ...FragC
    field3(a: $a, b: $b)
}
fragment FragC on Type {
    field2(c: $c)
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$a] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":9, "column":16}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$a] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":11, "column":16}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$c] is not defined by operation [Foo].", "locations":[{"line":2, "column":7}, {"line":14, "column":16}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$b] is not defined by operation [Bar].", "locations":[{"line":5, "column":7}, {"line":9, "column":23}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$b] is not defined by operation [Bar].", "locations":[{"line":5, "column":7}, {"line":11, "column":23}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-UNDEFINED-VARIABLES", "message":"Variable [$c] is not defined by operation [Bar].", "locations":[{"line":5, "column":7}, {"line":14, "column":16}]}'))
)
return
(
    test:assert-equal(6, fn:count($actual/errors[./rule= $RULE]))
)
