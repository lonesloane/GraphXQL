xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'UNIQUE-VARIABLE-NAME';

(: UNIQUE VARIABLE NAMES :)
let $query := 
'
query A($x: Int, $y: String) { __typename }
query B($x: String, $y: Int) { __typename }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: DUPLICATE VARIABLE NAMES :)
let $query := 
'
query A($x: Int, $x: Int, $x: String) { __typename }
query B($x: String, $x: Int) { __typename }
query C($x: Int, $x: Int) { __typename }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-VARIABLE-NAME", "message":"There can be only one variable named x.", "locations":[{"line":2, "column":10}, {"line":2, "column":19}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-VARIABLE-NAME", "message":"There can be only one variable named x.", "locations":[{"line":2, "column":10}, {"line":2, "column":28}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-VARIABLE-NAME", "message":"There can be only one variable named x.", "locations":[{"line":3, "column":10}, {"line":3, "column":22}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-VARIABLE-NAME", "message":"There can be only one variable named x.", "locations":[{"line":4, "column":10}, {"line":4, "column":19}]}'))
)
return
(
  test:assert-equal(4, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][./locations/column = 19][./locations/line = 2])
  ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][./locations/column = 28])
  ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][./locations/column = 22])
  ,test:assert-equal($expected[4]/node(), $actual/errors[./rule= $RULE][./locations/column = 19][./locations/line = 4])
)
