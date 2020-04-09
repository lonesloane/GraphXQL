xquery version "1.0-ml";

import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

(: --------------------------
  directive: include false
    on Properties
--------------------------  :)
let $query := 
'query Person($id: String!, $withFriends: Boolean!) {
  person(id: $id) {
    name
    friends @include(if: $withFriends) {
      name
    }
  }
}'
let $variables := map:map()
  => map:with('id', '2')
  => map:with('withFriends', xs:boolean('false'))

let $expected := xdmp:to-json(xdmp:from-json-string('{"data":{"person":{"name":"Joe"}}}'))
let $actual := parser:parse($query) => visit:visit($variables)
return (
    test:assert-equal($expected, $actual)
)
,
(: --------------------------
  directive: include true
    on Properties
--------------------------  :)
let $query := 
'query Person($id: String!, $withFriends: Boolean!) {
  person(id: $id) {
    name
    friends @include(if: $withFriends) {
      name
    }
  }
}'
let $variables := map:map()
  => map:with('id', '2')
  => map:with('withFriends', xs:boolean('true'))

let $expected := xdmp:to-json(xdmp:from-json-string('{"data":{"person":{"name":"Joe","friends":{"name":"Jesse"}}}}'))
let $actual := parser:parse($query) => visit:visit($variables)
return (
    test:assert-equal($expected, $actual)
)
,
(: --------------------------
  directive: include true
    on named fragment
--------------------------  :)
let $query := '
query Person($withFriends: Boolean!){
  hero:person(id: "1") {
    name
  ...comparisonFields @include(if: $withFriends)
  }
  foe:person(id: "2") {
    name
    ...comparisonFields @include(if: $withFriends)
  }
}
fragment comparisonFields on Person {
  appearsIn
  friends {
      name
  }
}
'
let $variables := map:map()
  => map:with('withFriends', xs:boolean('true'))

let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"hero":{"name":"Luke", "appearsIn":"Return of the Jedi", "friends":{"name":"Daisy"}}, "foe":{"name":"Joe", "appearsIn":"Return of the Jedi", "friends":{"name":"Jesse"}}}}'))
let $actual := parser:parse($query) => visit:visit($variables)
return (
    test:assert-equal($expected, $actual)
)
,
(: --------------------------
  directive: include false
    on named fragment
--------------------------  :)
let $query := '
query Person($withFriends: Boolean!){
  hero:person(id: "1") {
    name
  ...comparisonFields @include(if: $withFriends)
  }
  foe:person(id: "2") {
    name
    ...comparisonFields @include(if: $withFriends)
  }
}
fragment comparisonFields on Person {
  appearsIn
  friends {
      name
  }
}
'
let $variables := map:map()
  => map:with('withFriends', xs:boolean('false'))

let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"hero":{"name":"Luke"}, "foe":{"name":"Joe"}}}'))
let $actual := parser:parse($query) => visit:visit($variables)
return (
    test:assert-equal($expected, $actual)
)
,
(: --------------------------
  directive: include true
    on inline fragment
--------------------------  :)
let $query := '
query Person($withFriends: Boolean!){
  hero:person(id: "1") {
    name
    ... on Hero @include(if: $withFriends) {
        foes {
            name
        }
    }
  }
  foe:person(id: "2") {
    name
    ... on Foe @include(if: $withFriends) {
        accomplices {
            name
        }
    }
  }
}
'
let $variables := map:map()
  => map:with('withFriends', xs:boolean('true'))

let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"hero":{"name":"Luke", "foes":[{"name":"Joe"}, {"name":"Jack"}, {"name":"William"}, {"name":"Avrel"}]}, "foe":{"name":"Joe", "accomplices":[{"name":"Jack"}, {"name":"William"}, {"name":"Avrel"}]}}}'))
let $actual := parser:parse($query) => visit:visit($variables)
return (
    test:assert-equal($expected, $actual)
)
,
(: --------------------------
  directive: include false
    on inline fragment
--------------------------  :)
let $query := '
query Person($withFriends: Boolean!){
  hero:person(id: "1") {
    name
    ... on Hero @include(if: $withFriends) {
        foes {
            name
        }
    }
  }
  foe:person(id: "2") {
    name
    ... on Foe @include(if: $withFriends) {
        accomplices {
            name
        }
    }
  }
}
'
let $variables := map:map()
  => map:with('withFriends', xs:boolean('false'))

let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"hero":{"name":"Luke"}, "foe":{"name":"Joe"}}}'))
let $actual := parser:parse($query) => visit:visit($variables)
return (
    test:assert-equal($expected, $actual)
)
