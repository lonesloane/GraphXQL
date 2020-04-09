xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'UNIQUE-FRAGMENT-NAME';

(: NO OPERATION :)
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
(: ONE FRAGMENT :)
let $query := 
'
{
    ...fragA
}

fragment fragA on Type {
    field
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MANY FRAGMENTS :)
let $query := 
'
{
    ...fragA
    ...fragB
    ...fragC
}
fragment fragA on Type {
    fieldA
}
fragment fragB on Type {
    fieldB
}
fragment fragC on Type {
    fieldC
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INLINE FRAGMENTS CONSIDERED UNIQUE :)
let $query := 
'
{
    ...on Type {
        fieldA
    }
    ...on Type {
        fieldB
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: FRAGMENT AND OPERATION NAMED THE SAME :)
let $query := 
'
query Foo {
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
(: FRAGMENTS NAMED THE SAME :)
let $query := 
'
{
    ...fragA
}
fragment fragA on Type {
    fieldA
}
fragment fragA on Type {
    fieldB
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-FRAGMENT-NAME", "message":"There can be only one fragment named fragA.", "locations":[{"line":5, "column":10}, {"line":8, "column":10}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: UNREFERENCED FRAGMENTS NAMED THE SAME :)
let $query := 
'
fragment fragA on Type {
    fieldA
}
fragment fragA on Type {
    fieldB
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-FRAGMENT-NAME", "message":"There can be only one fragment named fragA.", "locations":[{"line":2, "column":10}, {"line":5, "column":10}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
