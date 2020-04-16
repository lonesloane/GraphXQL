xquery version "1.0-ml";

module namespace visit = "http://graph.x.ql/visitor";

import module namespace parser = "http://graph.x.ql/parser" 
    at "/graphXql/parser.xqy";
import module namespace disp = "http://graph.x.ql/dispatcher" 
    at "/graphXql/dispatcher.xqy";

declare variable $visit:CONTEXT := map:map();
declare variable $visit:VARIABLES := map:map();

declare function visit:set-variable-default-values($node as node())
{
    for $variable-definition in $node//variable-definition[./default-value]
    return
        (: variable values override default values :) 
        if (map:contains($visit:VARIABLES, $variable-definition/variable/name/@value/string())) then ()
        else map:put($visit:VARIABLES, $variable-definition/variable/name/@value/string(), $variable-definition/default-value/child::*/@value/string())
        (: TODO: keep $variable-definition/default-value/child::* to track both value and type :)
};

declare function visit:visit($node as node())
{
    visit:match($node, ())
};

declare function visit:visit($node as node(), $variables as map:map)
{
    let $_ := xdmp:set($visit:VARIABLES, $variables)
    let $_ := visit:set-variable-default-values($node)
    return visit:match($node, ())
};

(: declare function visit:match($node as node(), $entity as element()?) as node() :)
declare function visit:match($node as node(), $entity) as node()
{
    xdmp:log('[visit:match]: '||$node/name(), 'debug'),

    switch($node/name())
    
    case 'document' 
    return 
        document {visit:match($node/definitions, ())}
    
    case 'definitions'  
    return 
        visit:match($node/operation-definition, ())
    
    case 'operation-definition' 
    return
        if ($node/@operation/string() eq 'query') 
        then 
            object-node {'data': visit:match($node/selection-set, ())}
        
        else if ($node/@operation/string() eq 'mutation')
        then 
        (
            (: TODO: Fix bug when mutation values are not global variables :)
            (: TODO Fix mutation logic, should not require additional "pseudo-query" field to access expected result :)
            disp:mutate($node/selection-set/field, $visit:VARIABLES)
            ,object-node {'data': visit:match($node/selection-set/field/selection-set, ())}
        )
        
        else 
            fn:error((), 'VISITOR EXCEPTION', ("500", "Internal server error", "unsupported operation: "||$node/@operation/string()))
    
    case 'selection-set'
    return 
    (
        if (not($entity)) then (: entity :)
            let $json := json:object()
            let $_ :=
                for $field in $node/field
                    let $entity-name := $field/name/@value/string()
                    let $alias := $field/@alias/string()
                    let $field-name := fn:head(($alias, $entity-name))
                    let $entity-resolver := disp:get-entity-resolver($entity-name)
                    let $variables := visit:get-variables($field)
                    return map:put($json, $field-name, (xdmp:apply($entity-resolver, $variables)!visit:match($field/selection-set, .))) 
            return xdmp:to-json($json)
        else (: fields :)
            let $json := json:object()
            let $_ := 
                for $field in visit:list-fields($node, $entity)
                    let $field-name := $field/name/@value/string()
                    let $field-resolver := disp:get-field-resolver($entity, $field-name)
                    let $variables := visit:get-variables($field)
                    let $field-value := xdmp:apply($field-resolver, $entity, $variables)
                    let $field-value := 
                        typeswitch($field-value)
                            case json:array
                            return 
                                if ($field//selection-set) 
                                then 
                                (
                                    let $array := json:array()
                                    let $_ :=
                                        for $value in json:array-values($field-value)
                                            return json:array-push($array, visit:match($field/selection-set, $value))
                                    return $array
                                )
                                else $field-value 
                            default 
                            return
                                if ($field//selection-set) 
                                then $field-value!visit:match($field/selection-set, .)
                                else $field-value 
                        return map:put($json, $field-name, $field-value)
            return xdmp:to-json($json)
    )

    case 'fragment-definition' (: should be resolved when visiting selection-sets :)
    return 
        fn:error((), 'VISITOR EXCEPTION', ("500", "Internal server error", "fragment-definition should be resolved when visiting selection-sets"))
    default 
    return 
        fn:error((), 'VISITOR EXCEPTION', ("500", "Internal server error", "unexpected token kind: "||$node/name()))
};

declare function visit:get-argument-value($argument as node())
{
    (
        xdmp:log('[visit:get-argument-value] $argument: '||xdmp:describe($argument, (), ()), 'debug')
    ),

    if ($argument/variable) then 
        if (map:contains($visit:VARIABLES, $argument/variable/name/@value/string())) 
        then map:get($visit:VARIABLES, $argument/variable/name/@value/string())
        else fn:error((), 'visit:get-argument-value EXCEPTION', ("500", "Internal server error", "No variables found matching: "||$argument/variable/name/@value/string(), $visit:VARIABLES))
    else $argument//@value/string()
};

declare function visit:include-skip-fields($node as node(), $entity) as node()* 
{
    (
        xdmp:log('[visit:include-skip-fields] $node: '||xdmp:describe($node,(),()), 'debug')
    ),

    (: 
        TODO: improve support for other directives 
        currently limited to 'include' and 'skip' directives
    :)
    (
        for $field in $node/field
        return
            if ($field/directives) then 
                if ($field/directives/directive/name/@value/string() eq 'include') then 
                    if (xs:boolean(visit:get-argument-value($field/directives/directive/arguments/argument[./name/@value/string()='if']/value))) 
                    then $field 
                    else ()
                else if ($field/directives/directive/name/@value/string() eq 'skip') then 
                    if (xs:boolean(visit:get-argument-value($field/directives/directive/arguments/argument[./name/@value/string()='if']/value))) 
                    then () 
                    else $field
                else fn:error((), 'VISITOR EXCEPTION', ("500", "Internal server error", "unsupported directive: "||$field/directives/directive/name/@value/string()))
            else 
                $field
    ),
    (
        for $fragment-spread in $node/fragment-spread
        let $_ := xdmp:log('[visit:list-fields] $fragment-spread: '||xdmp:describe($fragment-spread, (), ()), 'debug')
        return
            if (visit:include-fragment($fragment-spread)) 
            then visit:include-skip-fields(fn:root($node)//fragment-definition[./name/@value=$fragment-spread/name/@value]/selection-set, $entity)
            else ()
    )
};

declare function visit:include-fragment($node as node()) as xs:boolean 
{
    (
        xdmp:log('[visit:include-fragment] $node: '||xdmp:describe($node,(),()), 'debug')
    ),

    if ($node/directives) then 
        if ($node/directives/directive/name/@value/string() eq 'include') then 
            xs:boolean(visit:get-argument-value($node/directives/directive/arguments/argument[./name/@value/string()='if']/value))
        else if ($node/directives/directive/name/@value/string() eq 'skip') then 
            fn:not(xs:boolean(visit:get-argument-value($node/directives/directive/arguments/argument[./name/@value/string()='if']/value)))
        else fn:error((), 'VISITOR EXCEPTION', ("500", "Internal server error", "unexpected directive: "||$node/directives/directive/name/@value/string()))
    else 
        xs:boolean('true')
};

declare function visit:list-fields($node as node(), $entity) as node()*
{
    (
        xdmp:log('[visit:list-fields] $node: '||xdmp:describe($node,(),()), 'debug')
        ,xdmp:log('[visit:list-fields] $entity: '||xdmp:describe($entity,(),()), 'debug')
    ),

    let $fields := visit:include-skip-fields($node, $entity)
    let $named-fragment-fields := 
        for $fragment-spread in $node/fragment-spread
        let $_ := xdmp:log('[visit:list-fields] $fragment-spread: '||xdmp:describe($fragment-spread, (), ()), 'debug')
        return
            if (visit:include-fragment($fragment-spread)) 
            then visit:include-skip-fields(fn:root($node)//fragment-definition[./name/@value=$fragment-spread/name/@value]/selection-set, $entity)
            else ()
    let $inline-fragment-fields :=
        for $inline-fragment in $node/inline-fragment
        let $_ := xdmp:log('[visit:list-fields] $inline-fragment: '||xdmp:describe($inline-fragment, (), ()), 'debug')
        return
            if ((disp:get-entity-type($entity) eq $inline-fragment/type-condition/named-type/name/@value/string()) 
                and visit:include-fragment($inline-fragment))
            then visit:include-skip-fields($inline-fragment/selection-set, $entity)
            else ()
    return 
        ($fields, $named-fragment-fields, $inline-fragment-fields)
};

declare function visit:get-variables($field as node()) as map:map
{
    (
        xdmp:log('[visit:get-variables] $field: '||xdmp:describe($field,(),()), 'debug')
    ),

    let $variables := map:map()
    let $_ := 
        if ($field/arguments/argument) 
        then
            $field/arguments/argument!map:put($variables, ./name/@value/string(), visit:get-argument-value(./value))
        else ()            
    return $variables
};
