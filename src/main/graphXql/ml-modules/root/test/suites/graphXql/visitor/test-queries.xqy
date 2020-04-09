xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";

(: --------------------------
  BIG query
--------------------------  :)
let $query := 
'query {
  hero:person(id: "1") {
    name
    friends { name }
    foes { name }
  }
  foe:person(id: "2") {
    name
    friends { name }
    accomplices { name }
 }
   event(id: "1"){
     title
     location
     startDate
     endDate
     participants {
       name
     }
   }
   agenda:document(id: "1"){
     title
     author
     publicationDate
     cote
   }
   delegation(id: "1"){
     name
     location
     membershipDate
     members {
       name
     }
   }
}'
let $variables := map:map()
let $result := parser:parse($query)
                => visit:visit($variables)
return (
    test:assert-true(fn:not(fn:empty($result)))
)
