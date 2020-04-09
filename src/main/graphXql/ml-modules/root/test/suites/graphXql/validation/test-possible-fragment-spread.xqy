xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare variable $RULE := 'POSSIBLE-FRAGMENT-SPREAD';

(: OF THE SAME OBJECT :)
let $query := 
'
fragment objectWithinObject on Person { ...personFragment }
fragment personFragment on Person { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: OF THE SAME OBJECT WITH INLINE FRAGMENT:)
let $query := 
'
fragment objectWithinObjectAnon on Person { ... on Person { name } }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: OBJECT INTO AN IMPLEMENTED INTERFACE :)
let $query := 
'
fragment objectWithinInterface on Human { ...personFragment }
fragment personFragment on Person { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: OBJECT INTO CONTAINING UNION :)
let $query := 
'
fragment objectWithinUnion on HeroOrFoe { ...heroFragment }
fragment heroFragment on Hero { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: UNION INTO CONTAINING OBJECT :)
let $query := 
'
fragment unionWithinObject on Hero { ...heroOrFoeFragment }
fragment heroOrFoeFragment on HeroOrFoe { __typename }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: UNION INTO OVERLAPPING INTERFACES :)
let $query := 
'
fragment unionWithinInterface on Human { ...heroOrFoeFragment }
fragment heroOrFoeFragment on HeroOrFoe { __typename }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: UNION INTO OVERLAPPING UNION :)
let $query := 
'
fragment unionWithinUnion on DogOrHuman { ...heroOrFoeFragment }
fragment heroOrFoeFragment on HeroOrFoe { __typename }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INTERFACE INTO IMPLEMENTED OBJECT :)
let $query := 
'
fragment interfaceWithinObject on Human { ...foeFragment }
fragment foeFragment on Foe { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INTERFACE INTO OVERLAPPING INTERFACE :)
let $query := 
'
fragment interfaceWithinInterface on Person { ...humanFragment }
fragment humanFragment on Human { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INTERFACE INTO OVERLAPPING INTERFACE IN INLINE FRAGMENT:)
let $query := 
'
fragment interfaceWithinInterface on Person { ... on Human {name} }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: INTERFACE INTO OVERLAPPING UNION :)
let $query := 
'
fragment interfaceWithinUnion on HeroOrFoe { ...humanFragment }
fragment humanFragment on Human { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,
(: IGNORES INCORRECT TYPE (CAUGHT BY FRAGMENTS-ON-COMPOSITE-TYPES) 
let $query := 
'
fragment humanFragment on Human { ...badInADfferentWay }
fragment badInADfferentWay on String { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
return
    test:assert-equal(0, fn:count($actual/errors[./rule= $RULE]))
,:)
(: DIFFERENT OBJECT INTO OBJECT :)
let $query := 
'
fragment invalidObjectWithinObject on Person { ...personFragment }
fragment personFragment on Event { title }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [personFragment] cannot be spread here as objects of type [Person] can never be of type [Event].", "locations":[{"line":2, "column":51}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, 'personFragment')])
)
,
(: DIFFERENT OBJECT INTO OBJECT In INLINE FRAGMENT:)
let $query := 
'
fragment invalidObjectWithinObjectAnon on Person { 
    ... on Event { title } 
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment cannot be spread here as objects of type [Person] can never be of type [Event].", "locations":[{"line":null, "column":null}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[Person]')])
)
,
(: OBJECT INTO NOT IMPLEMENTING INTERFACE :)
let $query := 
'
fragment invalidObjectWithinInterface on Dog { ...humanFragment }
fragment humanFragment on Human { friends { name } }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [humanFragment] cannot be spread here as objects of type [Dog] can never be of type [Human].", "locations":[{"line":2, "column":51}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[humanFragment]')])
)
,
(: OBJECT INTO NOT CONTAINING UNION :)
let $query := 
'
fragment invalidObjectWithinUnion on CatOrDog { ...humanFragment }
fragment humanFragment on Human { friends { name } }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [humanFragment] cannot be spread here as objects of type [CatOrDog] can never be of type [Human].", "locations":[{"line":2, "column":52}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[humanFragment]')])
)
,
(: UNION INTO NOT CONTAINED OBJECT :)
let $query := 
'
fragment invalidUnionWithinObject on Dog { ...heroOrFoeFragment }
fragment heroOrFoeFragment on HeroOrFoe { __typename }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [heroOrFoeFragment] cannot be spread here as objects of type [Dog] can never be of type [HeroOrFoe].", "locations":[{"line":2, "column":47}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[heroOrFoeFragment]')])
)
,
(: UNION INTO NON OVERLAPPING INTERFACE :)
let $query := 
'
fragment invalidUnionWithinInterface on Pet { ...heroOrFoeFragment }
fragment heroOrFoeFragment on HeroOrFoe { __typename }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [heroOrFoeFragment] cannot be spread here as objects of type [Pet] can never be of type [HeroOrFoe].", "locations":[{"line":2, "column":50}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[heroOrFoeFragment]')])
)
,
(: UNION INTO NON OVERLAPPING UNION :)
let $query := 
'
fragment invalidUnionWithinUnion on HorseOrDog { ...heroOrFoeFragment }
fragment heroOrFoeFragment on HeroOrFoe { __typename }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [heroOrFoeFragment] cannot be spread here as objects of type [HorseOrDog] can never be of type [HeroOrFoe].", "locations":[{"line":2, "column":53}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[heroOrFoeFragment]')])
)
,
(: INTERFACE INTO NON IMPLEMENTING OBJECT :)
let $query := 
'
fragment invalidInterfaceWithinObject on Dog { ...personFragment }
fragment personFragment on Person { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [personFragment] cannot be spread here as objects of type [Dog] can never be of type [Person].", "locations":[{"line":2, "column":51}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[personFragment]')])
)
,
(: INTERFACE INTO NON OVERLAPPING INTERFACE :)
let $query := 
'
fragment invalidInterfaceWithinInterface on Pet {
    ...personFragment
}
fragment personFragment on Person { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [personFragment] cannot be spread here as objects of type [Pet] can never be of type [Person].", "locations":[{"line":3, "column":8}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[personFragment]')])
)
,
(: INTERFACE INTO NON OVERLAPPING INTERFACE IN INLINE FRAGMENT :)
let $query := 
'
fragment invalidInterfaceWithinInterfaceAnon on Pet {
    ...on Person { name }
}
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment cannot be spread here as objects of type [Pet] can never be of type [Person].", "locations":[{"line":null, "column":null}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[Person]')])
)
,
(: INTERFACE INTO NON OVERLAPPING UNION :)
let $query := 
'
fragment invalidInterfaceWithinUnion on HeroOrFoe { ...petFragment }
fragment petFragment on Pet { name }
'
let $parsed-query := parser:parse($query, xs:boolean('true')) 
let $actual := validator:validate($parsed-query)
let $expected := 
(
    xdmp:to-json(xdmp:from-json-string('{"rule":"POSSIBLE-FRAGMENT-SPREAD", "message":"Fragment [petFragment] cannot be spread here as objects of type [HeroOrFoe] can never be of type [Pet].", "locations":[{"line":2, "column":56}]}'))
)
return
(
    test:assert-equal(1, fn:count($actual/errors[./rule= $RULE]))
    ,test:assert-equal($expected[1]/node(), $actual/errors[./rule= $RULE][fn:contains(./message, '[petFragment]')])
)
