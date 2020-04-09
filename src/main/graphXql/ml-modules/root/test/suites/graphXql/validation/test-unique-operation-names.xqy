xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'UNIQUE-OPERATION-NAME';

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
(: ONE NAMED OPERATION :)
let $query := 
'
      query Foo {
        field
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE OPERATIONS :)
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
(: MULTIPLE OPERATIONS OF DIFFERENT TYPES:)
let $query := 
'
      query Foo {
        field
      }
      mutation Bar {
        field
      }
      subscription Baz {
        field
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: FRAGMENT AND OPERATION WITH SAE NAME :)
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
(: MULTIPLE OPERATIONS WITH SAME NAME :)
let $query := 
'
      query Foo {
        fieldA
      }
      query Foo {
        fieldB
      }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-OPERATION-NAME", "message":"There can be only one operation named Foo.", "locations":[{"line":2, "column":13}, {"line":5, "column":13}]}'))
)
return
(
  test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: MULTIPLE OPERATIONS WITH SAME NAME DIFFERENT TYPES (MUTATION) :)
let $query := 
'
      query Foo {
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
    xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-OPERATION-NAME", "message":"There can be only one operation named Foo.", "locations":[{"line":2, "column":13}, {"line":5, "column":16}]}'))
)
return
(
  test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: MULTIPLE OPERATIONS WITH SAME NAME DIFFERENT TYPES (SUBSCRIPTION) :)
let $query := 
'
      query Foo {
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
  xdmp:to-json(xdmp:from-json-string('{"rule":"UNIQUE-OPERATION-NAME", "message":"There can be only one operation named Foo.", "locations":[{"line":2, "column":13}, {"line":5, "column":20}]}'))
)
return
(
  test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
