xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'PROVIDED-REQUIRED-ARGUMENTS';

(: IGNORES UNKNOWN ARGUMENTS :)
let $query := 
'
{
    pet (unknownArgument: true)
    {
        name
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ARG ON OPTIONAL ARG :)
let $query := 
'
{
    horse
    {
        canSpeak (inHisHead: true)
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NO ARG ON OPTIONAL ARG :)
let $query := 
'
{
    horse
    {
        canSpeak
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NO ARG ON REQUIRED ARG WITH DEFAULT :)
let $query := 
'
{
    dog
    {
        canSpeak
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE ARGS :)
let $query := 
'
{
    horse {
        multipleRequired(req1: "1", req2: "2")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE ARGS REVERSE ORDER :)
let $query := 
'
{
    horse {
        multipleRequired(req2: "2", req1: "1")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NO ARGS ON MULTIPLE OPTIONAL :)
let $query := 
'
{
    horse {
        multipleOptional
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ONE ARG ON MULTIPLE OPTIONAL :)
let $query := 
'
{
    horse {
        multipleOptional(opt1: "1")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: SECOND ARG ON MULTIPLE OPTIONAL :)
let $query := 
'
{
    horse {
        multipleOptional(opt2: "1")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE REQS ON MIXED LIST :)
let $query := 
'
{
    horse {
        multipleOptAndReq(req1: "1", req2: "1")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE REQS AND ONE OPT ON MIXED LIST :)
let $query := 
'
{
    horse {
        multipleOptAndReq(req1: "1", req2: "1", opt1: "1")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ALL REQS AND OPTS ON MIXED LIST :)
let $query := 
'
{
    horse {
        multipleOptAndReq(req1: "1", req2: "1", opt1: "1", opt2: "1")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MISSING ONE NON-NULLABLE ARGUMENT :)
let $query := 
'
{
    person
    {
        name
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"PROVIDED-REQUIRED-ARGUMENTS", "message":"Field [person] argument [id] of type [Int!] is required, but it was not provided.", "locations":[{"line":3, "column":5}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[id]')])
)
,
(: MISSING MULTIPLE NON-NULLABLE ARGUMENTS :)
let $query := 
'
{
    horse
    {
        multipleRequired
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"PROVIDED-REQUIRED-ARGUMENTS", "message":"Field [multipleRequired] argument [req1] of type [Int!] is required, but it was not provided.", "locations":[{"line":5, "column":9}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"PROVIDED-REQUIRED-ARGUMENTS", "message":"Field [multipleRequired] argument [req2] of type [Int!] is required, but it was not provided.", "locations":[{"line":5, "column":9}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[req1]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[req2]')])
)
,
(: INCORRECT VALUE AND MISSING ARGUMENT :)
let $query := 
'
{
    horse
    {
        multipleRequired(req1:"one")
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"PROVIDED-REQUIRED-ARGUMENTS", "message":"Field [multipleRequired] argument [req2] of type [Int!] is required, but it was not provided.", "locations":[{"line":5, "column":9}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[req2]')])
)
,
(: IGNORES UNKNOWN DIRECTIVE :)
let $query := 
'
{
    dog @unknown
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: WITH DIRECTIVES OF VALID TYPES :)
let $query := 
'
{
    dog @include(if: true) {
        name
    }
    human @skip(if: false) {
        name
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: WITH DIRECTIVES OF MISSING TYPES :)
let $query := 
'
{
    dog @include {
        name @skip
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"PROVIDED-REQUIRED-ARGUMENTS", "message":"Directive [@include] argument [if] of type [Boolean!] is required, but it was not provided.", "locations":[{"line":3, "column":10}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"PROVIDED-REQUIRED-ARGUMENTS", "message":"Directive [@skip] argument [if] of type [Boolean!] is required, but it was not provided.", "locations":[{"line":4, "column":15}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[@include]')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[@skip]')])
)
