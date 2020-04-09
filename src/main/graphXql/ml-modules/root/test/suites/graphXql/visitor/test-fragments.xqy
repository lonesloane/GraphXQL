xquery version "1.0-ml";

import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

declare namespace s = "http://www.w3.org/2005/xpath-functions";

(: Named fragment :)
let $query := '
query {
  hero:person(id: "1") {
    ...comparisonFields
  }
  foe:person(id: "2") {
    ...comparisonFields
  }
}
fragment comparisonFields on Person {
  name
  appearsIn
  friends {
      name
  }
}
'
let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"hero":{"name":"Luke", "appearsIn":"Return of the Jedi", "friends":{"name":"Daisy"}}, "foe":{"name":"Joe", "appearsIn":"Return of the Jedi", "friends":{"name":"Jesse"}}}}'))
let $actual := visit:visit(parser:parse($query))
return (
    test:assert-equal($expected, $actual)
)
,
(: Inline fragment :)
let $query := '
query {
  hero:person(id: "1") {
    name
    ... on Hero {
        foes {
            name
        }
    }
  }
  foe:person(id: "2") {
    name
    ... on Foe {
        accomplices {
            name
        }
    }
  }
}
'
let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"hero":{"name":"Luke", "foes":[{"name":"Joe"}, {"name":"Jack"}, {"name":"William"}, {"name":"Avrel"}]}, "foe":{"name":"Joe", "accomplices":[{"name":"Jack"}, {"name":"William"}, {"name":"Avrel"}]}}}'))
let $actual := visit:visit(parser:parse($query))
return (
    test:assert-equal($expected, $actual)
)
