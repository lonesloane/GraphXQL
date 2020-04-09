xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'KNOWN-ARGUMENT-NAME';

(: KNOWN ARG NAME:)
let $query := 
'
fragment argOnRequiredArg on Person {
    hasFriend(id: "1")
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE ARGS ARE KNOWN :)
let $query := 
'
fragment multipleArgs on Event {
    participants(offset: "10", length: "10")
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: IGNORES ARGS OF UNKNOWN FIELDS:)
let $query := 
'
fragment argOnUnknownField on Person {
    unknownField(unknownArg: "1")
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: MULTIPLE ARGS IN REVERSE ORDER ARE KNOWN :)
let $query := 
'
fragment multipleArgs on Event {
    participants(length: "10", offset: "10")
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: NO ARGS ON OPTIONAL ARGS :)
let $query := 
'
fragment noArgOnOptionalArg on Delegation {
    members
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ARGS ARE KNOWN DEEPLY :)
let $query := 
'
{
    event {
        participants(offset:"10", length:"10") {
            ... on Person {
                hasFriend(id:"1")
            }
        }
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: DIRECTIVE ARGS ARE KNOWN :)
let $query := 
'
{
    person @skip(if:true)
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: FIELD ARGS ARE INVALID :)
let $query := 
'
{
    person @skip(unless:true)
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-ARGUMENT-NAME", "message":"Unknown argument [unless] on directive [skip]. Available arguments: [if]", "locations":[{"line":3, "column":18}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'skip')])
)
,
(: DIRECTIVE WITHOUT ARGS IS VALID :)
let $query := 
'
{
    person @onField
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: ARG PASSED TO DIRECTIVE WITHOUT ARG IS INVALID :)
let $query := 
'
{
    person @onField(if: true)
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-ARGUMENT-NAME", "message":"Unknown argument [if] on directive [onField].", "locations":[{"line":3, "column":21}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'onField')])
)
,
(: MISSPELLED DIRECTIVE ARG IS INVALID :)
let $query := 
'
{
    person @skip(iff: true)
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-ARGUMENT-NAME", "message":"Unknown argument [iff] on directive [skip]. Available arguments: [if]", "locations":[{"line":3, "column":18}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'skip')])
)
,
(: INVALID ARG NAME:)
let $query := 
'
fragment argOnRequiredArg on Person {
    hasFriend(unknown: "1")
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-ARGUMENT-NAME", "message":"Unknown argument [unknown] on field [Person.hasFriend]. Available arguments: [id]", "locations":[{"line":3, "column":15}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Person')])
)
,
(: MISSPELLED ARG NAME IS INVALID :)
let $query := 
'
fragment invalidArgName on Person {
    hasFriend(idd: "1")
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-ARGUMENT-NAME", "message":"Unknown argument [idd] on field [Person.hasFriend]. Available arguments: [id]", "locations":[{"line":3, "column":15}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Person')])
)
,
(: UNKNOWN ARGS AMONGST KNOWN ARG ARE INVALID :)
let $query := 
'
fragment oneGoodArgOneInvalidArg on Person {
    hasFriend(unknown1: "1", id: "1", unknown2:"2")
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-ARGUMENT-NAME", "message":"Unknown argument [unknown1] on field [Person.hasFriend]. Available arguments: [id]", "locations":[{"line":3, "column":15}]}'))
    ,xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-ARGUMENT-NAME", "message":"Unknown argument [unknown2] on field [Person.hasFriend]. Available arguments: [id]", "locations":[{"line":3, "column":39}]}'))
)
return
(
    test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'unknown1')])
    ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'unknown2')])
)
,
(: UNKNOWN ARGS DEEPLY ARE INVALID :)
let $query := 
'
{
    event {
        participants(offset:"10", length:"10") {
            ... on Person {
                hasFriend(idz:"1")
            }
        }
    }
}'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"KNOWN-ARGUMENT-NAME", "message":"Unknown argument [idz] on field [Person.hasFriend]. Available arguments: [id]", "locations":[{"line":6, "column":27}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'idz')])
)


