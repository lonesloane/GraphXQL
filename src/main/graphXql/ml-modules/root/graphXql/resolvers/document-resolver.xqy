xquery version "1.0-ml";

module namespace gxqlr = "http://graph.x.ql/resolvers";

import schema namespace gxql ="http://graph.x.ql" 
    at "/graphxql/entities/graphXql-types.xsd";

declare default element namespace "http://graph.x.ql";

declare function gxqlr:document-field-resolver($field-name as xs:string) as xdmp:function
{
         if ($field-name eq 'title') then xdmp:function(xs:QName('gxqlr:document-title-resolver'))
    else if ($field-name eq 'author') then xdmp:function(xs:QName('gxqlr:document-author-resolver'))
    else if ($field-name eq 'publicationDate') then xdmp:function(xs:QName('gxqlr:document-publication-date-resolver'))
    else if ($field-name eq 'cote') then xdmp:function(xs:QName('gxqlr:document-cote-resolver'))
    else fn:error((), 'DOCUMENT FIELD RESOLVER EXCEPTION', ("500", "Internal server error", "unexpected token kind: "||$field-name))
};

declare function gxqlr:document-entity-resolver($var-map as map:map) as element(*, gxql:Document)
{
    if (map:contains($var-map, 'id'))
    then 
    (
        let $document-uri := fn:concat('/graphXql/document/', map:get($var-map, 'id'))
        return fn:doc($document-uri)/node()
    )
    else fn:error((), 'entity-resolver EXCEPTION', ("500", "Internal server error", "No identifier received in variables: ", $var-map))
};

declare function gxqlr:document-title-resolver($document as element(), $var-map as map:map)
{
    $document/title/string()
};

declare function gxqlr:document-author-resolver($document as element(), $var-map as map:map)
{
    $document/author/string()
};

declare function gxqlr:document-publication-date-resolver($document as element(), $var-map as map:map)
{
    $document/publication-date/string()
};

declare function gxqlr:document-cote-resolver($document as element(), $var-map as map:map)
{
    $document/cote/string()
};
