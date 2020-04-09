xquery version "1.0-ml";

import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

declare namespace s = "http://www.w3.org/2005/xpath-functions";

let $query := '
query {
  person (id: "1") {
    name
  }
}
'
let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"person":{"name":"Luke"}}}'))
let $actual := visit:visit(parser:parse($query))
return (
    test:assert-equal($expected, $actual)
)
,
let $query := '
query {
  person (id: "1") {
    name
    height
  }
}
'
let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"person":{"name":"Luke", "height":"180"}}}'))
let $actual := visit:visit(parser:parse($query))
return (
    test:assert-equal($expected, $actual)
)
,
let $query := '
query {
  person (id: "1"){
    name
    foes {
      name
    }
  }
}
'
let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"person":{"name":"Luke", "foes":[{"name":"Joe"}, {"name":"Jack"}, {"name":"William"}, {"name":"Avrel"}]}}}'))
let $actual := visit:visit(parser:parse($query))
return (
    test:assert-equal($expected, $actual)
)