xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

declare namespace http="xdmp:http";

declare variable $graphXql-endpoint-uri := "http://localhost:8152/LATEST/resources/graphXql";

(: --------------------------
  Simple Query
--------------------------  :)
let $query := 
'
query {
  hero:person(id: 1) {
    name
  }
  foe:person(id: 2) {
    name
  }
}
'

let $payload := object-node {
  "query": $query
}

let $expected := xdmp:to-json(xdmp:from-json-string('{"data":{"hero":{"name":"Luke"}, "foe":{"name":"Joe"}}}'))

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
let $actual := $result[2]
return 
(
    test:assert-equal('200', $response/http:code/string()),
    test:assert-equal($expected, $actual)
)
,
(: --------------------------
  Query with variables
--------------------------  :)
let $query := 
'query Person($id: Int!) {
  person(id: $id) {
    name
  }
}
'

let $payload := object-node {
  "query": $query,
  "variables": object-node{"id": 2}
}

let $expected := xdmp:to-json(xdmp:from-json-string('{"data":{"person":{"name":"Joe"}}}'))
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
let $actual := $result[2]   
return
(
    test:assert-equal('200', $response/http:code/string()),
    test:assert-equal($expected, $actual)
)
,
(: --------------------------
  Query with default value
--------------------------  :)
let $query := 
'query Person($id: Int = 1) {
  person(id: $id) {
    name
  }
}'

let $payload := object-node {
  "query": $query
}

let $expected := xdmp:to-json(xdmp:from-json-string('{"data":{"person":{"name":"Luke"}}}'))
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
let $actual := $result[2]   
return
(
    test:assert-equal('200', $response/http:code/string()),
    test:assert-equal($expected, $actual)
)
,
(: --------------------------
  variable override default value
--------------------------  :)
let $query := 
'query Person($id: Int = 1) {
  person(id: $id) {
    name
  }
}'

let $payload := object-node {
  "query": $query,
  "variables": object-node{"id": 2}
}

let $expected := xdmp:to-json(xdmp:from-json-string('{"data":{"person":{"name":"Joe"}}}'))
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
let $actual := $result[2]   
return
(
    test:assert-equal('200', $response/http:code/string()),
    test:assert-equal($expected, $actual)
)
(: TODO: FIX mutation unit test  :)
(: ,
(: --------------------------
  Mutation
--------------------------  :)
let $query := 
'
mutation CreateParticipant($id: Int!, $participant: String!) {
  createParticipant(id: $id, participant:$participant){
    event(id: $id) {
      title
      participants { name }
    }
  }
}
'

let $payload := object-node {
  "query": $query,
  "variables": object-node{"id": 1, "participant": "7"}
}

let $expected := xdmp:to-json(xdmp:from-json-string('{"data":{"event":{"title":"Big conference", "participants":[{"name":"Joe"}, {"name":"Jack"}, {"name":"William"}, {"name":"Avrel"}, {"name":"Jesse"}]}}}'))
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
let $_ := xdmp:log('$$$$$$$$$$$$$$$$$$$$$$$$$', 'debug')
let $_ := xdmp:log($result, 'debug')
let $_ := xdmp:log('$$$$$$$$$$$$$$$$$$$$$$$$$', 'debug')
let $response := $result[1]
let $actual := $result[2]   
return
(
    test:assert-equal('200', $response/http:code/string()),
    test:assert-equal($expected, $actual)
) :)
