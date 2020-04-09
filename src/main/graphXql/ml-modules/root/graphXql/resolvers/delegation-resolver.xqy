xquery version "1.0-ml";

module namespace gxqlr = "http://graph.x.ql/resolvers";

import schema namespace gxql ="http://graph.x.ql" 
    at "/graphxql/entity-types.xsd";

declare default element namespace "http://graph.x.ql";

declare function gxqlr:delegation-field-resolver($field-name as xs:string) as xdmp:function
{
         if ($field-name eq 'name') then xdmp:function(xs:QName('gxqlr:delegation-name-resolver'))
    else if ($field-name eq 'location') then xdmp:function(xs:QName('gxqlr:delegation-location-resolver'))
    else if ($field-name eq 'membershipDate') then xdmp:function(xs:QName('gxqlr:delegation-membership-date-resolver'))
    else if ($field-name eq 'members') then xdmp:function(xs:QName('gxqlr:delegation-members-resolver'))
    else fn:error((), 'DELEGATION FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unexpected token kind: "||$field-name))
};

declare function gxqlr:delegation-entity-resolver($var-map as map:map) as element(*, gxql:Delegation)
{
    if (map:contains($var-map, 'id'))
    then 
    (
        let $delegation-uri := fn:concat('http://one.oecd.org/delegation/', map:get($var-map, 'id'))
        return fn:doc($delegation-uri)/node()
    )
    else fn:error((), 'entity-resolver EXCEPTION', ("500", "Internal server error", "No identifier received in variables: ", $var-map))
};

declare function gxqlr:delegation-name-resolver($delegation as element(), $var-map as map:map)
{
    $delegation/name/string()
};

declare function gxqlr:delegation-location-resolver($delegation as element(), $var-map as map:map)
{
    $delegation/location/string()
};

declare function gxqlr:delegation-membership-date-resolver($delegation as element(), $var-map as map:map)
{
    $delegation/membership-date/string()
};

declare function gxqlr:delegation-members-resolver($delegation as element(), $var-map as map:map) as element(*, gxql:Person)*
{
    let $member-ids := $delegation/members/person/id/string()
    let $person-uris := $member-ids!fn:concat('http://one.oecd.org/person/', .)
    return $person-uris!fn:doc(.)/node()
};
