xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'EXECUTABLE-DEFINITION';

(: ONLY OPERATION :)
let $query := 
'
query Foo {
        person {
          name
        }
      }  
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: OPERATION AND FRAGMENT :)
let $query := 
'
query Foo {
        person {
          name
          ...Frag
        }
      }
      fragment Frag on Hero {
        name
      }  
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: WITH TYPE DEFINITION :)
let $query := 
'
query Foo {
        dog {
          name
        }
      }
type Cow {
    name: String
}
extend type Dog {
    color: String
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"EXECUTABLE-DEFINITION", "message":"The object Cow definition is not executable", "locations":[{"line":7, "column":1}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"EXECUTABLE-DEFINITION", "message":"The object Dog definition is not executable", "locations":[{"line":10, "column":1}]}'))
)
return
(
  test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Cow')])
  ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Dog')])
)
,
(: WITH SCHEMA DEFINITION :)
let $query := 
'
schema {
        query: Query
      }
type Query {
    test: String
}
extend schema @directive
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)

let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"EXECUTABLE-DEFINITION", "message":"The schema definition is not executable", "locations":[{"line":2, "column":1}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"EXECUTABLE-DEFINITION", "message":"The object Query definition is not executable", "locations":[{"line":5, "column":1}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"EXECUTABLE-DEFINITION", "message":"The schema definition is not executable", "locations":[{"line":8, "column":1}]}'))
)
return
(
  test:assert-equal(3, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Query')])
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'schema')][1])
  ,test:assert-equal($expected[3]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'schema')][2])
)
