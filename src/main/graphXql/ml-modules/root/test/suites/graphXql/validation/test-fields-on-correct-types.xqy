xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'FIELD-ON-CORRECT-TYPE';

(: OBJECT FIELD SELECTION :)
let $query := 
'
fragment objectFieldSelection on Person {
    __typename
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,    
(: ALIASED OBJECT FIELD SELECTION :)
let $query := 
'
fragment aliasedObjectFieldSelection on Person {
    tn: __typename
    otherName: name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,    
(: INTERFACE FIELD SELECTION :)
let $query := 
'
fragment interfaceFieldSelection on Human {
    __typename
    name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,    
(: ALIASED INTERFACE FIELD SELECTION :)
let $query := 
'
fragment interfaceFieldSelection on Human {
    otherName: name
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,    
(: LYING ALIAS SELECTION 
let $query := 
'
fragment lyingAliasSelection on Dog {
    name: nickName
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := xdmp:to-json(xdmp:from-json-string('{"errors":[]}'))

return
    test:assert-equal($expected, $actual)
,   :) 
(: IGNORES FIELDS ON UNKNOWN TYPES :)
let $query := 
'
fragment unknownSelection on UnknownType {
    unknownField
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: REPORT ERROR WHEN TYPE IS KNOWN :)
let $query := 
'
fragment typeKnownAgain on Human {
    unknown_human_field {
        ... on Person {
            unknown_person_field
        }
    }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"FIELD-ON-CORRECT-TYPE", "message":"Cannot query field unknown_human_field on type Human. Available fields are name.", "locations":[{"line":3, "column":5}]}'))
  ,xdmp:to-json(xdmp:from-json-string('{"rule":"FIELD-ON-CORRECT-TYPE", "message":"Cannot query field unknown_person_field on type Person. Available fields are name, height, appearsIn, friends, dog, hasFriend.", "locations":[{"line":5, "column":13}]}'))
)
return
(
  test:assert-equal(2, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Human')])
  ,test:assert-equal($expected[2]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Person')][1])
)
,
(: FIELD NOT DEFINED ON FRAGMENT :)
let $query := 
'
fragment fieldNotDefined on Hero {
    accomplices
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
  xdmp:to-json(xdmp:from-json-string('{"rule":"FIELD-ON-CORRECT-TYPE", "message":"Cannot query field accomplices on type Hero. Available fields are name, height, appearsIn, friends, foes.", "locations":[{"line":3, "column":5}]}'))
)
return
(
  test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
  ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'Hero')])
)
,
(: OBJECT FIELD SELECTION :)
let $query := 
'
query {
  hero:person(id: "1") {
    name
  }
  foe:person(id: "2") {
    name
  }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
  test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))

