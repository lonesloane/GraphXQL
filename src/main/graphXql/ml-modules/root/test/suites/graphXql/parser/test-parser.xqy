xquery version "1.0-ml";

import module namespace parser = "http://graph.x.ql/parser" at "/graphXql/parser.xqy";
import module namespace test = "http://marklogic.com/test" at "/test/test-helper.xqy";

declare namespace s = "http://www.w3.org/2005/xpath-functions";


let $string := '
query Hero($episode: Episode = JEDI, $withFriends: Boolean!) 
{
  myHero: hero(episode: $episode) {
    name
    ... on Droid {
      primaryFunction
    }
    ... on Human {
      height
    }
    height(unit: FOOT)
    friends @include(if: $withFriends)
    # Queries can have comments!
    ...comparisonFields
  }

  empireHero: hero(episode: EMPIRE) {
    name
    height(unit: FOOT)
    friends @include(if: $withFriends)
    # Queries can have comments!
    ...comparisonFields
  }

  regularHero: hero(id: "123") {
    name
    height(unit: FOOT)
    friends @include(if: $withFriends)
    # Queries can have comments!
    ...comparisonFields
  }
}

fragment comparisonFields on Character {
  name
  appearsIn
  friends {
    name
  }
  friendsConnection(first: $first) {
    totalCount
    edges {
      node {
        name
      }
    }
  }
}'

return (
    parser:parse($string)
)
,
let $query := '
query {
  person {
    name
    friends {
      name
    }
  }
}
'
return (
    parser:parse($query)
)
,
let $query := '
query Foo {
    human(id: "4") {
        ...bar
    }
}
fragment foo on Human {
    name
}
'
return (
    parser:parse($query)
)
