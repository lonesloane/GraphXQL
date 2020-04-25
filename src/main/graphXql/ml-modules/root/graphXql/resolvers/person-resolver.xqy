xquery version "1.0-ml";

module namespace gxqlr = "http://graph.x.ql/resolvers";

import schema namespace gxql ="http://graph.x.ql" 
    at "/graphxql/entities/graphXql-types.xsd";

declare default element namespace "http://graph.x.ql";

declare function gxqlr:person-entity-resolver($var-map as map:map) as element(*, gxql:Person)?
{
    if (map:contains($var-map, 'id'))
    then 
    (
        let $person-uri := fn:concat('/graphXql/person/', map:get($var-map, 'id'))
        return fn:doc($person-uri)/node()
    )
    else fn:error((), 'ENTITY RESOLVER EXCEPTION', ("500", "Internal server error", "No identifier received in variables: ", $var-map))
};

declare function gxqlr:person-field-resolver($field-name as xs:string) as xdmp:function
{
    if ($field-name eq 'name') then xdmp:function(xs:QName('gxqlr:person-name-resolver'))
    else if ($field-name eq 'height') then xdmp:function(xs:QName('gxqlr:person-height-resolver'))
    else if ($field-name eq 'appearsIn') then xdmp:function(xs:QName('gxqlr:person-appearsIn-resolver'))
    else if ($field-name eq 'friends') then xdmp:function(xs:QName('gxqlr:person-friends-resolver'))
    else if ($field-name eq 'foes') then xdmp:function(xs:QName('gxqlr:person-foes-resolver'))
    else if ($field-name eq 'accomplices') then xdmp:function(xs:QName('gxqlr:person-accomplices-resolver'))
    else fn:error((), 'FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unsupported field: "||$field-name))
};

declare function gxqlr:person-name-resolver($person as element(*, gxql:Person), $var-map as map:map)
{
    $person/name/string()
};

declare function gxqlr:person-height-resolver($person as element(*, gxql:Person), $var-map as map:map)
{
    if (map:contains($var-map, 'unit'))
    then gxqlr:person-convert-to-unit($person/height/string(), map:get($var-map, 'unit'))
    else $person/height/string()
};

declare function gxqlr:person-appearsIn-resolver($person as element(*, gxql:Person), $var-map as map:map)
{
    $person/appearsIn/string()
};

declare function gxqlr:person-friends-resolver($person as element(*, gxql:Person), $var-map as map:map) as element(*, gxql:Person)*
{
    let $friend-ids := $person/friends/id/string()
    let $person-uris := $friend-ids!fn:concat('/graphXql/person/', .)
    return $person-uris!fn:doc(.)/node()
};

declare function gxqlr:person-foes-resolver($person as element(*, gxql:Person), $var-map as map:map) as element(*, gxql:Person)*
{
    let $foe-ids := $person/foes/id/string()
    let $person-uris := $foe-ids!fn:concat('/graphXql/person/', .)
    return $person-uris!fn:doc(.)/node()
};

declare function gxqlr:person-accomplices-resolver($person as element(*, gxql:Person), $var-map as map:map) as element(*, gxql:Person)*
{
    let $accomplice-ids := $person/accomplices/id/string()
    let $person-uris := $accomplice-ids!fn:concat('/graphXql/person/', .)
    return $person-uris!fn:doc(.)/node()
};

declare function gxqlr:person-convert-to-unit($height as xs:string, $unit as xs:string)
{
    if ($unit eq 'FOOT') then '5.86'
    else '180'
};
