xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'UNIQUE-INPUT-FIELD-NAME';

(: INPUT OBJECT WITH FIELD :)
let $query := 
'
{
    field(arg: { f: "true" })
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SAME INPUT OBJECT WITHIN TWO ARGS  :)
let $query := 
'
{
    field(arg1: { f: true }, arg2: { f: true })
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE INPUT OBJECT FIELDS  :)
let $query := 
'
{
    field(arg: { f1: "value", f2: "value", f3: "value" })
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NESTED INPUT OBJECTS WITH SIMILAR FIELDS  :)
let $query := 
'
{
    field(arg: {
        deep: {
            deep: {
                id: "1"
            }
            id: "1"
        }
        id: "1"
    })
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: DUPLICATE INPUT OBJECT FIELDS  :)
let $query := 
'
{
    field(arg: { f1: "value", f1: "value" })
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-INPUT-FIELD-NAME", "message":"There can be only one field named f1.", "locations":[{"line":3, "column":18}, {"line":3, "column":31}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: MANY DUPLICATE INPUT OBJECT FIELDS  :)
let $query := 
'
{
    field(arg: { f1: "value", f1: "value", f1: "value" })
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-INPUT-FIELD-NAME", "message":"There can be only one field named f1.", "locations":[{"line":3, "column":18}, {"line":3, "column":31}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-INPUT-FIELD-NAME", "message":"There can be only one field named f1.", "locations":[{"line":3, "column":18}, {"line":3, "column":44}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][./locations/column = 31])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][./locations/column = 44])
)
,
(: NESTED DUPLICATE INPUT OBJECT FIELDS  :)
let $query := 
'
{
    field(arg: { f1: {f2: "value", f2: "value" }})
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-INPUT-FIELD-NAME", "message":"There can be only one field named f2.", "locations":[{"line":3, "column":23}, {"line":3, "column":36}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
