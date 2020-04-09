xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace validator = "http://graph.x.ql/validator" at "/graphXql/validator.xqy";

declare namespace http="xdmp:http";

declare variable $graphXql-endpoint-uri := "http://localhost:8152/LATEST/resources/graphXql";

let $query := 
'
query {
  hero:person(id:"1") {
    name
    friends { name }
    accomplices { name }
  }
}
extend type Dog {
  color: String
}
'

let $payload := object-node {
  "query": $query
}

let $result :=
    xdmp:http-post(
        $graphXql-endpoint-uri,
        <options xmlns="xdmp:http">
          <headers>
            <content-type>application/json</content-type>
          </headers>
            <authentication method="digest">
                <username>admin</username>
                <password>admin</password>
            </authentication>
        </options>,
        $payload)

let $response := $result[1]
return
(
    test:assert-equal('400', $response/http:code/string()),
    test:assert-equal('VALIDATION-ERROR', $response/http:message/string())
)
