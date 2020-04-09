xquery version "1.0-ml";

import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";
import module namespace visit = "http://graph.x.ql/visitor" at "/graphXql/visitor.xqy";
import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";

(: Allows querying the schema for types :)
let $query := 
'
{
    __schema {
        types {
            name
        }
    }
}  
'

let $variables := map:map()
(: 
    Include all types used by StarWars schema, introspection types and
    standard directives. For example, `Boolean` is used in `@skip`,
    `@include` and also inside introspection types.
 :)
let $expected := xdmp:to-json(xdmp:from-json-string('
{
  "data": {
    "__schema": {
      "types": [
        {
          "name": "Query"
        },
        {
          "name": "Boolean"
        },
        {
          "name": "Episode"
        },
        {
          "name": "Droid"
        },
        {
          "name": "Character"
        },
        {
          "name": "String"
        },
        {
          "name": "ID"
        },
        {
          "name": "Human"
        },
        {
          "name": "__Schema"
        },
        {
          "name": "__Type"
        },
        {
          "name": "__TypeKind"
        },
        {
          "name": "__EnumValue"
        },
        {
          "name": "__Field"
        },
        {
          "name": "__Directive"
        },
        {
          "name": "__DirectiveLocation"
        },
        {
          "name": "__InputValue"
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
(: Allows querying the schema for query type :)
let $query := 
'
{
    __schema {
        queryType {
            name
        }
    }
}
'

let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
  "data": {
    "__schema": {
      "queryType": {
        "name": "Query"
      }
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
(: Allows querying the schema for a specific type :)
let $query := 
'
{
    __type(name: "Droid") {
        name
    }
}
'

let $variables := map:map()
let $expected := xdmp:to-json(xdmp:from-json-string('
{
  "data": {
    "__type": {
      "name": "Droid"
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
(: Allows querying the schema for an object kind :)
let $query := 
'
{
    __type(name: "Droid") {
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
      "name": "Droid",
      "kind": "OBJECT"
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
(: Allows querying the schema for an interface kind :)
let $query := 
'
{
    __type(name: "Character") {
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
      "name": "Character",
      "kind": "INTERFACE"
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
(: Allows querying the schema for object fields :)
let $query := 
'
{
    __type(name: "Droid") {
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
            "fields": [
                {
                    "name": "id",
                    "type": {
                        "kind": "NON_NULL",
                        "name": null
                    }
                },
                {
                    "name": "name",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                {
                    "name": "friends",
                    "type": {
                        "kind": "LIST",
                        "name": null
                    }
                },
                {
                    "name": "appearsIn",
                    "type": {
                        "kind": "LIST",
                        "name": null
                    }
                },
                {
                    "name": "secretBackstory",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                },
                {
                    "name": "primaryFunction",
                    "type": {
                        "kind": "SCALAR",
                        "name": "String"
                    }
                }
            ],
            "name": "Droid"
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
(: Allows querying the schema for nested object field :)
let $query := 
'
{
    __type(name: "Droid") {
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
      "name": "Droid",
      "fields": [
        {
          "name": "id",
          "type": {
            "name": null,
            "kind": "NON_NULL",
            "ofType": {
                "name": "ID",
                "kind": "SCALAR"
            }
          }
        },
        {
          "name": "name",
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
              "name": "Character",
              "kind": "INTERFACE"
            }
          }
        },
        {
          "name": "appearsIn",
          "type": {
            "name": null,
            "kind": "LIST",
            "ofType": {
              "name": "Episode",
              "kind": "ENUM"
            }
          }
        },
        {
          "name": "secretBackstory",
          "type": {
            "name": "String",
            "kind": "SCALAR",
            "ofType": null
          }
        },
        {
          "name": "primaryFunction",
          "type": {
            "name": "String",
            "kind": "SCALAR",
            "ofType": null
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
(: Allows querying the schema for field args :)
let $query := 
'
{
    __schema {
        queryType {
            fields {
                name
                args {
                    name
                    description
                    type {
                        name
                        kind
                        ofType {
                            name
                            kind
                        }
                    }
                    defaultValue
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
    "__schema": {
      "queryType": {
        "fields": [
          {
            "name": "hero",
            "args": [
              {
                "name": "episode",
                "description": "If omitted, returns the hero of the whole saga. If provided, returns the hero of that particular episode.",
                "type": {
                  "name": "Episode",
                  "kind": "ENUM",
                  "ofType": null
                },
                "defaultValue": null
              }
            ]
          },
          {
            "name": "human",
            "args": [
              {
                "name": "id",
                "description": "id of the human.",
                "type": {
                  "name": null,
                  "kind": "NON_NULL",
                  "ofType": {
                    "name": "ID",
                    "kind": "SCALAR"
                  }
                },
                "defaultValue": null
              }
            ]
          },
          {
            "name": "droid",
            "args": [
              {
                "name": "id",
                "description": "id of the droid.",
                "type": {
                  "name": null,
                  "kind": "NON_NULL",
                  "ofType": {
                    "name": "ID",
                    "kind": "SCALAR"
                  }
                },
                "defaultValue": null
              }
            ]
          }
        ]
      }
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
(: Allows querying the schema for documentation :)
let $query := 
'
{
    __type(name: "Droid") {
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
      "name": "Droid",
      "description": "A mechanical creature in the Star Wars universe."
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
