xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'UNIQUE-ARGUMENT-NAME';

(: NO FIELD ARGUMENTS :)
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
(: NO ARGUMENTS ON DIRECTIVE :)
let $query := 
'
{
    field @directive
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ARGUMENT ON FIELD :)
let $query := 
'
{
    field(arg: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ARGUMENT ON DIRECTIVE :)
let $query := 
'
{
    field @directive(arg: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SAME ARGUMENT ON 2 FIELDS :)
let $query := 
'
{
    one: field(arg: "value")
    two: field(arg: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SAME ARGUMENT ON 2 DIRECTIVES :)
let $query := 
'
{
    field @directive1(arg: "value") @directive2(arg: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SAME ARGUMENT ON FIELD AND DIRECTIVE :)
let $query := 
'
{
    field(arg: "value") @directive(arg: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE FIELD ARGUMENTS :)
let $query := 
'
{
    field(arg1: "value", arg2: "value", arg3: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE DIRECTIVE ARGUMENTS :)
let $query := 
'
{
    field @directive(arg1: "value", arg2: "value", arg3: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: DUPLICATE FIELD ARGUMENTS :)
let $query := 
'
{
    field(arg1: "value", arg1: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-ARGUMENT-NAME", "message":"There can be only one argument named arg1.", "locations":[{"line":3, "column":11}, {"line":3, "column":26}]}'))
)
return
(
  test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: MANY DUPLICATE FIELD ARGUMENTS :)
let $query := 
'
{
    field(arg1: "value", arg1: "value", arg1: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-ARGUMENT-NAME", "message":"There can be only one argument named arg1.", "locations":[{"line":3, "column":11}, {"line":3, "column":26}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-ARGUMENT-NAME", "message":"There can be only one argument named arg1.", "locations":[{"line":3, "column":11}, {"line":3, "column":41}]}'))
)
return
(
  test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][./locations/column = 26])
  ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][./locations/column = 41])
)
,
(: DUPLICATE DIRECTIVE ARGUMENTS :)
let $query := 
'
{
    field @directive(arg1: "value", arg1: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-ARGUMENT-NAME", "message":"There can be only one argument named arg1.", "locations":[{"line":3, "column":22}, {"line":3, "column":37}]}'))
)
return
(
  test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: MANY DIRECTIVE FIELD ARGUMENTS :)
let $query := 
'
{
    field @directive(arg1: "value", arg1: "value", arg1: "value")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-ARGUMENT-NAME", "message":"There can be only one argument named arg1.", "locations":[{"line":3, "column":22}, {"line":3, "column":37}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-ARGUMENT-NAME", "message":"There can be only one argument named arg1.", "locations":[{"line":3, "column":22}, {"line":3, "column":52}]}'))
)
return
(
  test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][./locations/column = 37])
  ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][./locations/column = 52])
)
