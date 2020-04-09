xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";

let $query := 
'
{
    __type(name: "Person") {
        name
    }
}
'
let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
    "data": {
        "__type": {
            "name": "Person"
        }
    }
}
'))
let $actual := parser:parse($query)
                => visit:visit($variables)
return 
(
    test:assert-equal($expected, $actual)
)
,
let $query := 
'
{
    __type(name: "Person") {
        name
        kind
    }
}
'
let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
    "data": {
        "__type": {
            "name": "Person",
            "kind": "INTERFACE"
        }
    }
}
'))
let $actual := parser:parse($query)
                => visit:visit($variables)
return 
(
    test:assert-equal($expected, $actual)
)
,
let $query := 
'
{
    __type(name: "Hero") {
        name
        kind
    }
}
'
let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
    "data": {
        "__type": {
            "name": "Hero",
            "kind": "OBJECT"
        }
    }
}
'))
let $actual := parser:parse($query)
                => visit:visit($variables)
return 
(
    test:assert-equal($expected, $actual)
)
,
let $query := 
'
{
    __type(name: "Hero") {
        name
        fields {
            name
            type {
                name
                kind
            }
        }
    }
}
'
let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
  "data": {
    "__type": {
      "name": "Hero",
      "fields": [
        {
          "name": "name",
          "type": {
            "name": "String",
            "kind": "SCALAR"
          }
        },
        {
          "name": "height",
          "type": {
            "name": "String",
            "kind": "SCALAR"
          }
        },
        {
          "name": "appearsIn",
          "type": {
            "name": "String",
            "kind": "SCALAR"
          }
        },
        {
          "name": "friends",
          "type": {
            "name": null,
            "kind": "LIST"
          }
        },
        {
          "name": "foes",
          "type": {
            "name": null,
            "kind": "LIST"
          }
        }
      ]
    }
  }
}'))
let $actual := parser:parse($query)
                => visit:visit($variables)
return 
(
    test:assert-equal($expected, $actual)
)
,
let $query := 
'
{
    __type(name: "Hero") {
        name
        fields {
            name
            type {
                name
                kind
                ofType {
                    name
                    kind
                }
            }
        }
    }
}
'
let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
  "data": {
    "__type": {
      "name": "Hero",
      "fields": [
        {
          "name": "name",
          "type": {
            "name": "String",
            "kind": "SCALAR",
            "ofType": null
          }
        },
        {
          "name": "height",
          "type": {
            "name": "String",
            "kind": "SCALAR",
            "ofType": null
          }
        },
        {
          "name": "appearsIn",
          "type": {
            "name": "String",
            "kind": "SCALAR",
            "ofType": null
          }
        },
        {
          "name": "friends",
          "type": {
            "name": null,
            "kind": "LIST",
            "ofType": {
              "name": "Person",
              "kind": "INTERFACE"
            }
          }
        },
        {
          "name": "foes",
          "type": {
            "name": null,
            "kind": "LIST",
            "ofType": {
              "name": "Person",
              "kind": "INTERFACE"
            }
          }
        }
      ]
    }
  }
}'))
let $actual := parser:parse($query)
                => visit:visit($variables)
return 
(
    test:assert-equal($expected, $actual)
)
,
let $query := 
'
{
  __type(name: "Hero") {
    name
    description
  }
}
'
let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
  "data": {
    "__type": {
      "name": "Hero",
      "description": "The good guy."
    }
  }
}
'))
let $actual := parser:parse($query)
                => visit:visit($variables)
return 
(
    test:assert-equal($expected, $actual)
)
