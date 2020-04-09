xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'NO-FRAGMENT-CYCLES';

(: SINGLE REFERENCE IS VALID :)
let $query := 
'
fragment fragA on Person { ...fragB }
fragment fragB on Person { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SPREADING TWICE IS NOT CIRCULAR :)
let $query := 
'
fragment fragA on Dog { ...fragB, ...fragB }
fragment fragB on Dog { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SPREADING TWICE INDIRECTLY IS NOT CIRCULAR :)
let $query := 
'
fragment fragA on Dog { ...fragB, ...fragC }
fragment fragB on Dog { ...fragC }
fragment fragC on Dog { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: DOUBLE SPREAD WITHIN ABSTRACT TYPES :)
let $query := 
'
fragment nameFragment on Pet {
    ... on Dog { name }
    ... on Cat { name }
}

fragment spreadsInAnon on Pet {
    ... on Dog { ...nameFragment }
    ... on Cat { ...nameFragment }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: DOES NOT FALSE POSITIVE ON UNKNOWN FRAGMENT :)
let $query := 
'
fragment nameFragment on Pet {
    ...UnknownFragment
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SPREADING RECURSIVELY WITHIN FIELD FAILS :)
let $query := 
'
fragment fragA on Person {  friends {...fragA } }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragA].", "locations":[{"line":2, "column":10}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'fragA')])
)
,
(: NO SPREADING ITSELF DIRECTLY :)
let $query := 
'
fragment fragA on Dog { ...fragA }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragA].", "locations":[{"line":2, "column":10}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'fragA')])
)
,
(: NO SPREADING ITSELF DIRECTLY WITHIN INLINE FRAGMENT :)
let $query := 
'
fragment fragA on Pet {
    ... on Dog {
        ...fragA
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragA].", "locations":[{"line":2, "column":10}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'fragA')])
)
,
(: NO SPREADING ITSELF INDIRECTLY :)
let $query := 
'
fragment fragA on Dog { ...fragB }
fragment fragB on Dog { ...fragA }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragB].", "locations":[{"line":3, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragB] within itself via [fragA].", "locations":[{"line":2, "column":10}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA] within')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragB] within')])
)
,
(: NO SPREADING ITSELF INDIRECTLY REPORTS OPPOSITE ORDERS :)
let $query := 
'
fragment fragB on Dog { ...fragA }
fragment fragA on Dog { ...fragB }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragB] within itself via [fragA].", "locations":[{"line":3, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragB].", "locations":[{"line":2, "column":10}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragB] within')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA] within')])
)
,
(: NO SPREADING ITSELF INDIRECTLY WITH INLINE FRAGMENT :)
let $query := 
'
fragment fragA on Pet {
    ... on Dog {
        ...fragB
    }
}
fragment fragB on Pet {
    ... on Dog {
        ...fragA
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragB].", "locations":[{"line":7, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragB] within itself via [fragA].", "locations":[{"line":2, "column":10}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA] within')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragB] within')])
)
,
(: NO SPREADING ITSELF DEEPLY :)
let $query := 
'
fragment fragA on Dog { ...fragB }
fragment fragB on Dog { ...fragC }
fragment fragC on Dog { ...fragO }
fragment fragX on Dog { ...fragY }
fragment fragY on Dog { ...fragZ }
fragment fragZ on Dog { ...fragO }
fragment fragO on Dog { ...fragP }
fragment fragP on Dog { ...fragA, ...fragX }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragB ,fragC ,fragO ,fragP].", "locations":[{"line":3, "column":10}, {"line":4, "column":10}, {"line":8, "column":10}, {"line":9, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragB] within itself via [fragC ,fragO ,fragP ,fragA].", "locations":[{"line":4, "column":10}, {"line":8, "column":10}, {"line":9, "column":10}, {"line":2, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragC] within itself via [fragO ,fragP ,fragA ,fragB].", "locations":[{"line":8, "column":10}, {"line":9, "column":10}, {"line":2, "column":10}, {"line":3, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragX] within itself via [fragY ,fragZ ,fragO ,fragP].", "locations":[{"line":6, "column":10}, {"line":7, "column":10}, {"line":8, "column":10}, {"line":9, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragY] within itself via [fragZ ,fragO ,fragP ,fragX].", "locations":[{"line":7, "column":10}, {"line":8, "column":10}, {"line":9, "column":10}, {"line":5, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragZ] within itself via [fragO ,fragP ,fragX ,fragY].", "locations":[{"line":8, "column":10}, {"line":9, "column":10}, {"line":5, "column":10}, {"line":6, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragO] within itself via [fragP ,fragX ,fragY ,fragZ].", "locations":[{"line":9, "column":10}, {"line":5, "column":10}, {"line":6, "column":10}, {"line":7, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragO] within itself via [fragP ,fragA ,fragB ,fragC].", "locations":[{"line":9, "column":10}, {"line":2, "column":10}, {"line":3, "column":10}, {"line":4, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragP] within itself via [fragX ,fragY ,fragZ ,fragO].", "locations":[{"line":5, "column":10}, {"line":6, "column":10}, {"line":7, "column":10}, {"line":8, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragP] within itself via [fragA ,fragB ,fragC ,fragO].", "locations":[{"line":2, "column":10}, {"line":3, "column":10}, {"line":4, "column":10}, {"line":8, "column":10}]}'))
)
return
(
    test:assert-equal(10, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragB ,fragC ,fragO ,fragP]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragC ,fragO ,fragP ,fragA]')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragO ,fragP ,fragA ,fragB]')])
    ,test:assert-equal($expected[4]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragY ,fragZ ,fragO ,fragP]')])
    ,test:assert-equal($expected[5]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragZ ,fragO ,fragP ,fragX]')])
    ,test:assert-equal($expected[6]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragO ,fragP ,fragX ,fragY]')])
    ,test:assert-equal($expected[7]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragP ,fragX ,fragY ,fragZ]')])
    ,test:assert-equal($expected[8]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragP ,fragA ,fragB ,fragC]')])
    ,test:assert-equal($expected[9]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragX ,fragY ,fragZ ,fragO]')])
    ,test:assert-equal($expected[10]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA ,fragB ,fragC ,fragO]')])
)
,
(: NO SPREADING ITSELF DEEPLY TWO PATHS:)
let $query := 
'
fragment fragA on Dog { ...fragB, ...fragC }
fragment fragB on Dog { ...fragA }
fragment fragC on Dog { ...fragA }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragB].", "locations":[{"line":3, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragC].", "locations":[{"line":4, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragB] within itself via [fragA].", "locations":[{"line":2, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragC] within itself via [fragA].", "locations":[{"line":2, "column":10}]}'))
)
return
(
    test:assert-equal(4, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA] within itself via [fragB]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA] within itself via [fragC]')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragB] within itself via [fragA]')])
    ,test:assert-equal($expected[4]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragC] within itself via [fragA]')])
)
,
(: NO SPREADING ITSELF DEEPLY TWO PATHS -- ALT TRAVERSE ORDER :)
let $query := 
'
fragment fragA on Dog { ...fragC }
fragment fragB on Dog { ...fragC }
fragment fragC on Dog { ...fragA, ...fragB }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragC].", "locations":[{"line":4, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragB] within itself via [fragC].", "locations":[{"line":4, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragC] within itself via [fragB].", "locations":[{"line":3, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragC] within itself via [fragA].", "locations":[{"line":2, "column":10}]}'))
)
return
(
    test:assert-equal(4, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA] within itself via [fragC]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragB] within itself via [fragC]')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragC] within itself via [fragB]')])
    ,test:assert-equal($expected[4]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragC] within itself via [fragA]')])
)
,
(: NO SPREADING ITSELF DEEPLY AND IMMEDIATELY :)
let $query := 
'
fragment fragA on Dog { ...fragB }
fragment fragB on Dog { ...fragB, ...fragC }
fragment fragC on Dog { ...fragA, ...fragB }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragB ,fragB ,fragC].", "locations":[{"line":3, "column":10}, {"line":3, "column":10}, {"line":4, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragA] within itself via [fragB ,fragC].", "locations":[{"line":3, "column":10}, {"line":4, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragB] within itself via [fragB].", "locations":[{"line":3, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragB] within itself via [fragC].", "locations":[{"line":4, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragC] within itself via [fragB].", "locations":[{"line":3, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"NO-FRAGMENT-CYCLES", "message":"Cannot spread fragment [fragC] within itself via [fragA ,fragB].", "locations":[{"line":2, "column":10}, {"line":3, "column":10}]}'))
)
return
(
    test:assert-equal(6, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA] within itself via [fragB ,fragB ,fragC]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragA] within itself via [fragB ,fragC]')])
    ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragB] within itself via [fragB]')])
    ,test:assert-equal($expected[4]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragB] within itself via [fragC]')])
    ,test:assert-equal($expected[5]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragC] within itself via [fragB]')])
    ,test:assert-equal($expected[6]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[fragC] within itself via [fragA ,fragB]')])
)
