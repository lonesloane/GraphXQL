xquery version "1.0-ml";

import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

declare namespace s = "http://www.w3.org/2005/xpath-functions";

let $query := '
query HeroNameAndFriends{
  hero:person(id: "1") {
      name
      friends {
          name
      }
  }
}
'
let $expected :=xdmp:to-json(xdmp:from-json-string('{"data":{"hero":{"name":"Luke", "friends":{"name":"Daisy"}}}}'))
let $actual := parser:parse($query) => visit:visit()
return (
    test:assert-equal($expected, $actual)
)
