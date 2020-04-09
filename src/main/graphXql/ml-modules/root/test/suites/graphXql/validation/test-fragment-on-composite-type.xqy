xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'FRAGMENT-ON-COMPOSITE-TYPE';

(: OBJECT IS VALID FRAGMENT TYPE :)
let $query := 
'
      fragment validFragment on Hero {
        friends
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INTERFACE IS VALID FRAGMENT TYPE :)
let $query := 
'
      fragment validFragment on Person {
        name
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: OBJECT IS VALID INLINE FRAGMENT TYPE :)
let $query := 
'
      fragment validFragment on Person {
        ... on Hero {
          friends
        }
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INTERFACE IS VALID INLINE FRAGMENT TYPE :)
let $query := 
'
      fragment validFragment on Human {
        ... on Person {
          name
        }
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INLINE FRAGMENT WITHOUT TYPE IS VALID :)
let $query := 
'
      fragment validFragment on Person {
        ... {
          name
        }
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: UNION IS VALID FRAGMENT TYPE 
let $query := 
'
      fragment validFragment on HeroOrFoe {
        __typename
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := xdmp:to-json(xdmp:from-json-string('{"errors":[]}'))

return
    test:assert-equal($expected, $actual)
,
:)
(: SCALAR IS INVALID FRAGMENT TYPE :)
let $query := 
'
      fragment scalarFragment on Boolean {
        bad
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"FRAGMENT-ON-COMPOSITE-TYPE", "message":"Fragment scalarFragment cannot condition on non composite type Boolean.", "locations":[{"line":2, "column":16}]}'))
)
return
(
  test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: SCALAR IS INVALID INLINE FRAGMENT TYPE :)
let $query := 
'
      fragment invalidFragment on Person {
        ... on String {
          name
        }
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"FRAGMENT-ON-COMPOSITE-TYPE", "message":"Fragment cannot condition on non composite type String.", "locations":[{"line":3, "column":16}]}'))
)
return
(
  test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)

(: ENUM IS INVALID FRAGMENT TYPE 
let $query := 
'
      fragment invalidFragment on Person {
        ... on String {
          name
        }
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := xdmp:to-json(xdmp:from-json-string('{
    "errors": [
        {
            "locations": [
                {
                    "column": 16,
                    "line": 3
                }
            ],
            "message": "Fragment cannot condition on non composite type String."
        }
    ]
}'))

return
    test:assert-equal($expected, $actual)
,
:)
(: INPUT OBJECT IS INVALID FRAGMENT TYPE 
let $query := 
'
      fragment invalidFragment on Person {
        ... on String {
          name
        }
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := xdmp:to-json(xdmp:from-json-string('{
    "errors": [
        {
            "locations": [
                {
                    "column": 16,
                    "line": 3
                }
            ],
            "message": "Fragment cannot condition on non composite type String."
        }
    ]
}'))

return
    test:assert-equal($expected, $actual)
:)