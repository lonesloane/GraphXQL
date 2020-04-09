xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'SINGLE-FIELD-SUBSCRIPTION';

(: VALID SUBSCRIPTION :)
let $query := 
'
subscription ImportantEmails {
   importantEmails
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
   test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: FAILS WITH MORE THAN ONE ROOT FIELD :)
let $query := 
'
subscription ImportantEmails {
   importantEmails
   notImportantEmails
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
   xdmp:to-json(xdmp:from-json-string('{"rule":"SINGLE-FIELD-SUBSCRIPTION", "message":"Subscription ImportantEmails must select only one top level field.", "locations":[{"line":2, "column":1}]}'))
)
return
(
   test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
   ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: FAILS WITH MORE THAN ONE ROOT FIELD INCLUDING INTROSPECTION :)
let $query := 
'
subscription ImportantEmails {
   importantEmails
   __typename
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
   xdmp:to-json(xdmp:from-json-string('{"rule":"SINGLE-FIELD-SUBSCRIPTION", "message":"Subscription ImportantEmails must select only one top level field.", "locations":[{"line":2, "column":1}]}'))
)
return
(
   test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
   ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: FAILS WITH MANY MORE THAN ONE ROOT FIELD :)
let $query := 
'
subscription ImportantEmails {
   importantEmails
   notImportantEmails
   spamEmails
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
   xdmp:to-json(xdmp:from-json-string('{"rule":"SINGLE-FIELD-SUBSCRIPTION", "message":"Subscription ImportantEmails must select only one top level field.", "locations":[{"line":2, "column":1}]}'))
)
return
(
   test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
   ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
,
(: FAILS WITH MORE THAN ONE ROOT FIELD IN ANONYMOUS SUBSCRIPTION :)
let $query := 
'
subscription {
   importantEmails
   notImportantEmails
}
'

let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
   xdmp:to-json(xdmp:from-json-string('{"rule":"SINGLE-FIELD-SUBSCRIPTION", "message":"Anonymous subscription must select only one top level field.", "locations":[{"line":2, "column":1}]}'))
)
return
(
   test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
   ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE])
)
