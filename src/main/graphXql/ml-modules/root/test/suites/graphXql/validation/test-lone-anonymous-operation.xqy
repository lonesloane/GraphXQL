xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'LONE-ANONYMOUS-OPERATION';

(: NO OPERATION :)
let $query := 
'
fragment fragA on Type {
    field
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ONE ANONYMOUS OPERATION :)
let $query := 
'
{
    field
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE NAMED OPERATIONS :)
let $query := 
'
query Foo {
    field
}

query Bar {
    field
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ANONYMOUS OPERATION WITH FRAGMENT :)
let $query := 
'
{
    ...Foo
}
fragment Foo on Type {
    field
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE ANONYMOUS OPERATIONS :)
let $query := 
'
{
    fieldA
}
{
    fieldB
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"LONE-ANONYMOUS-OPERATION", "message":"This anonymous operation must be the only defined operation.", "locations":[{"line":2, "column":1}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"LONE-ANONYMOUS-OPERATION", "message":"This anonymous operation must be the only defined operation.", "locations":[{"line":5, "column":1}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][./locations/line = 2])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][./locations/line = 5])
)
,
(: ANONYMOUS OPERATION WITH MUTATION :)
let $query := 
'
{
    fieldA
}
mutation Foo {
    fieldB
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"LONE-ANONYMOUS-OPERATION", "message":"This anonymous operation must be the only defined operation.", "locations":[{"line":2, "column":1}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: ANONYMOUS OPERATION WITH SUBSCRIPTION :)
let $query := 
'
{
    fieldA
}
subscription Foo {
    fieldB
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"LONE-ANONYMOUS-OPERATION", "message":"This anonymous operation must be the only defined operation.", "locations":[{"line":2, "column":1}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
