xquery version "1.0-ml";

module namespace parser = "http://graph.x.ql/parser";

import module namespace lex = "http://graph.x.ql/lexer" 
    at "/graphXql/lexer.xqy";

declare namespace s = "http://www.w3.org/2005/xpath-functions";

declare variable $parser:LOCATION as xs:boolean := xs:boolean('false');

declare variable $parser:DIRECTIVE_LOCATION_NAMES := 
(
    (:Request Definitions:)
    'QUERY',
    'MUTATION',
    'SUBSCRIPTION',
    'FIELD',
    'FRAGMENT_DEFINITION',
    'FRAGMENT_SPREAD',
    'INLINE_FRAGMENT',
    'VARIABLE_DEFINITION',
    (:Type System Definitions:)
    'SCHEMA',
    'SCALAR',
    'OBJECT',
    'FIELD_DEFINITION',
    'ARGUMENT_DEFINITION',
    'INTERFACE',
    'UNION',
    'ENUM',
    'ENUM_VALUE',
    'INPUT_OBJECT',
    'INPUT_FIELD_DEFINITION'
);

declare variable $TOKENS := ();
declare variable $POS := 1;

(: 
    Determines if the next token is of a given kind
:)
declare function parser:peek($token-kind as xs:string) as xs:boolean (:TODO: strongly type token-kind:)
{
    $TOKENS[$POS]/@type/string() eq $token-kind 
};

declare function parser:peek-description() as xs:boolean
{
    (parser:peek($lex:STRING-LABEL) or parser:peek($lex:BLOCK_STRING-LABEL)) 
};

(: 
    If the next token is of the given kind, return that token after advancing
    the lexer. Otherwise, do not change the parser state and throw an error.
:)
declare function parser:expect-token($token-kind as xs:string)
{
    let $token := $TOKENS[$POS]
    return
    if ($token/@type/string() eq $token-kind ) then 
    (
        let $_ := xdmp:set($POS, $POS+1)
        return $token[1]
    ) else
        fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "expected "||$token-kind, ", found ",$TOKENS[$POS]/@type/string()))
};

(: 
    If the next token is of the given kind, return that token after advancing
    the lexer. Otherwise, do not change the parser state and return undefined.
:)
declare function parser:expect-optional-token($token-kind as xs:string)
{
    let $token := $TOKENS[$POS]
    return
    if ($token/@type/string() eq $token-kind ) then 
    (
        let $_ := xdmp:set($POS, $POS+1)
        return $token[1]
    ) 
    else ()
};

(: 
    If the next token is a given keyword, advance the lexer.
    Otherwise, do not change the parser state and throw an error.
:)
declare function parser:expect-keyword($value as xs:string)
{
    if ($TOKENS[$POS]/@type/string() eq $lex:NAME-LABEL and $TOKENS[$POS]/@value/string() eq $value)
    then 
        xdmp:set($POS, $POS+1)
    else 
        fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "expected "||$value, ", found ",$TOKENS[$POS]))
};

(: 
    If the next token is a given keyword, return "true" after advancing
    the lexer. Otherwise, do not change the parser state and return "false".
:)
declare function parser:expect-optional-keyword($value as xs:string) as xs:boolean
{
    if ($TOKENS[$POS]/@type/string() eq $lex:NAME-LABEL and $TOKENS[$POS]/@value/string() eq $value)
    then 
    (
        let $_ := xdmp:set($POS, $POS+1)
        return xs:boolean('true')
    )
    else xs:boolean('false')
};

declare function parser:many($start-token as xs:string, $func, $stop-token as xs:string) as node()*
{   
    let $tokens := ()
    let $_ := parser:expect-token($start-token)
    return
        parser:parse-many($tokens, $func, $stop-token)
};

declare function parser:parse-many($tokens as node()*, $func, $stop-token as xs:string) as node()*
{
    if (parser:peek($stop-token))
    then 
    (
        let $_ := parser:expect-token($stop-token)
        return $tokens
    )
    else 
    (
        let $tokens := ($tokens, $func())
        return parser:parse-many($tokens, $func, $stop-token)
    )
};

declare function parser:many-optional($start-token as xs:string, $func, $stop-token as xs:string) as node()*
{
    let $tokens := ()
    return
    if (parser:expect-optional-token($start-token)) 
    then parser:parse-many($tokens, $func, $stop-token)
    else ()
};

declare function parser:parse($source as xs:string, $location as xs:boolean) as node()
{
    let $_ := xdmp:set($parser:LOCATION, $location)
    return parser:parse($source)
};

(: 
    Given a GraphQL source, parses it into a Document.
    Throws GraphQLError if a syntax error is encountered.
:)
declare function parser:parse($source as xs:string) as node()
{
    
    let $_ := xdmp:log('parser:parse: '||$source, 'debug')
    let $_ := xdmp:set($TOKENS, lex:get-tokens(lex:tokenize($source)))
    let $_ := xdmp:set($POS, 1)

    (: return ($TOKENS) :)
    return parser:parse-document()
};

(: 
    Implements the parsing rules in the Document section.

    Document : Definition+
:)
declare function parser:parse-document()
{
    (
        xdmp:log('[parser:parse-document]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start := $TOKENS[$POS]
    return
    <document>
        {parser:parse-definitions()}
        {parser:loc($start)}
    </document>
};

declare function parser:parse-definitions()
{
    (
        xdmp:log('[parser:parse-definitions]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    <definitions>
    {
        parser:many($lex:SOF, parser:parse-definition#0, $lex:EOF)
    }
    </definitions>
};

(: 
    Definition :
    - ExecutableDefinition
    - TypeSystemDefinition
    - TypeSystemExtension

    ExecutableDefinition :
    - OperationDefinition
    - FragmentDefinition
:)
declare function parser:parse-definition()
{
    (
        xdmp:log('[parser:parse-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    if (parser:peek($lex:NAME-LABEL)) then
    (
        switch($TOKENS[$POS]/@value/string())
            case 'query'
            case 'mutation' 
            case 'subscription' 
                return parser:parse-operation-definition()
            case 'fragment' 
                return parser:parse-fragment_definition()
            case 'schema'
            case 'scalar'
            case 'type'
            case 'interface'
            case 'union'
            case 'enum'
            case 'input'
            case 'directive'
                return parser:parse-type-system-definition()
            case 'extend'
                return parser:parse-type-system-extension()
            default
                return fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ",$TOKENS[$POS]))
    ) 
    else if (parser:peek($lex:BRACE_L-LABEL)) then 
    (
        parser:parse-operation-definition()
    )
    else if (parser:peek($lex:STRING-LABEL) or parser:peek($lex:BLOCK_STRING-LABEL)) then (
        parser:parse-type-system-definition()
    )
    else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ",$TOKENS[$POS]))
};

(: 
    Implements the parsing rules in the Operations section.

    OperationDefinition :
    - SelectionSet
    - OperationType Name? VariableDefinitions? Directives? SelectionSet
:)
declare function parser:parse-operation-definition()
{
    (
        xdmp:log('[parser:parse-operation-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start := $TOKENS[$POS]
    return
    if (parser:peek($lex:BRACE_L-LABEL)) then
    (
        <operation-definition operation="query" name="undefined">
            {parser:parse-selection-set()}
            {parser:loc($start)}
        </operation-definition>
    )
    else 
    (
        let $operation := parser:parse-operation-type()
        let $name := if (parser:peek($lex:NAME-LABEL)) then parser:parse-name() else ()
        return 
        <operation-definition operation="{$operation}">
            {$name}
            {parser:parse-variable-definitions()}
            {parser:parse-directives((), xs:boolean('false'))}
            {parser:parse-selection-set()}
            {parser:loc($start)}
        </operation-definition>

    )
};

(: 
    FragmentDefinition :
    - fragment FragmentName on TypeCondition Directives? SelectionSet

    TypeCondition : NamedType
:)
declare function parser:parse-fragment_definition()
{
    (
        xdmp:log('[parser:parse-fragment_definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $_ := parser:expect-keyword('fragment')
    return
        <fragment_definition>
            {parser:parse-fragment-name()}
            <type-condition>
            {
                let $_ := parser:expect-keyword('on') 
                return parser:parse-named-type()
            }
            </type-condition>
            {parser:parse-directives((), xs:boolean('false'))}
            {parser:parse-selection-set()}
        </fragment_definition>
};

(: 
    Implements the parsing rules in the Type Definition section.

    TypeSystemDefinition :
        - SchemaDefinition
        - TypeDefinition
        - DirectiveDefinition

    TypeDefinition :
        - ScalarTypeDefinition
        - ObjectTypeDefinition
        - InterfaceTypeDefinition
        - UnionTypeDefinition
        - EnumTypeDefinition
        - InputObjectTypeDefinition
:)
declare function parser:parse-type-system-definition()
{
    (
        xdmp:log('[parser:parse-type-system-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    if (parser:peek-description()) then xdmp:set($POS, $POS+1) else ()
    ,
    if ($TOKENS[$POS]/@type/string() eq $lex:NAME-LABEL)
    then
        switch ($TOKENS[$POS]/@value/string())
        case 'schema'
            return parser:parse-schema-definition()
        case 'scalar'
            return parser:parse-scalar-type-definition()
        case 'type'
            return parser:parse-object-type-definition()
        case 'interface'
            return parser:parse-interface-type-definition()
        case 'union'
            return parser:parse-union-type-definition()
        case 'enum'
            return parser:parse-enum-type-definition()
        case 'input'
            return parser:parse-input-object-type-definition()
        case 'directive'
            return parser:parse-directive-definition()
        default
            return fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ",$TOKENS[$POS]))
    else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unexpected token: ",$TOKENS[$POS]))
};

(: 
    SchemaDefinition : schema Directives[Const]? { OperationTypeDefinition+ }
:)
declare function parser:parse-schema-definition(){
    (
        xdmp:log('[parser:parse-schema-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return
        <schema-definition>
            {if (parser:expect-keyword('schema')) then () else ()}
            {parser:parse-directives((), xs:boolean('true'))}
            {parser:many($lex:BRACE_L-LABEL, parser:parse-operation-type-definition#0, $lex:BRACE_R-LABEL)}
            {parser:loc($start)}
        </schema-definition>
};

(: 
    OperationTypeDefinition : OperationType : NamedType
:)
declare function parser:parse-operation-type-definition(){
    (
        xdmp:log('[parser:parse-operation-type-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return
        <operation-type-definition>
            {parser:parse-operation-type()}
            {if (parser:expect-token($lex:COLON-LABEL)) then () else ()}
            {parser:parse-named-type()}
            {parser:loc($start)}
        </operation-type-definition>
};

(: 
    ScalarTypeDefinition : Description? scalar Name Directives[Const]?
:)
declare function parser:parse-scalar-type-definition(){
    (
        xdmp:log('[parser:parse-scalar-type-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return
        <scalar-type-definition>
            {parser:parse-description()}
            {if (parser:expect-keyword('scalar')) then () else ()}
            {parser:parse-name()}
            {parser:parse-directives((), xs:boolean('true'))}
            {parser:loc($start)}
        </scalar-type-definition>
};

(: 
    ObjectTypeDefinition :
        Description?
        type Name ImplementsInterfaces? Directives[Const]? FieldsDefinition?
:)
declare function parser:parse-object-type-definition(){
    (
        xdmp:log('[parser:parse-object-type-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return
        <object-type-definition>
            {parser:parse-description()}
            {if (parser:expect-keyword('type')) then () else ()}
            {parser:parse-name()}
            {parser:parse-implements-interfaces()}
            {parser:parse-directives((), xs:boolean('true'))}
            {parser:parse-fields-definition()}
            {parser:loc($start)}
        </object-type-definition>
};

(: 
    ImplementsInterfaces :
        - implements `&`? NamedType
        - ImplementsInterfaces & NamedType
:)
declare function parser:parse-implements-interfaces(){
    (
        xdmp:log('[parser:parse-implements-interfaces]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $types := ()
    let $types :=
        if (parser:expect-optional-keyword('implements'))
        then 
            parser:parse-implement-interface($types)
        else ()
    return $types
};

declare function parser:parse-implement-interface($types){
    (
        xdmp:log('[parser:parse-implement-interface]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    if (parser:expect-optional-token($lex:AMP-LABEL) or parser:peek($lex:NAME-LABEL))
    then 
    (
        let $types := ($types, parser:parse-named-type())
        return parser:parse-implement-interface($types)
    )
    else $types
};

(: 
    FieldsDefinition : { FieldDefinition+ }
:)
declare function parser:parse-fields-definition(){
    (
        xdmp:log('[parser:parse-fields-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    parser:many-optional($lex:BRACE_L-LABEL, parser:parse-field_definition#0, $lex:BRACE_R-LABEL)
};

(: 
    FieldDefinition :
    - Description? Name ArgumentsDefinition? : Type Directives[Const]?
:)
declare function parser:parse-field_definition(){
    (
        xdmp:log('[parser:parse-field_definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return 
    <field_definition>
        {parser:parse-description()}
        {parser:parse-name()}
        {parser:parse-arguments-definition()}
        {if (parser:expect-token($lex:COLON-LABEL)) then () else ()}
        {parser:parse-type-reference()}
        {parser:parse-directives((), xs:boolean('true'))}
        {parser:loc($start)}
    </field_definition>
};

(: 
    ArgumentsDefinition : ( InputValueDefinition+ )
:)
declare function parser:parse-arguments-definition(){
    (
        xdmp:log('[parser:parse-arguments-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    parser:many-optional($lex:PAREN_L-LABEL, parser:parse-input-value-definition#0, $lex:PAREN_R-LABEL)
};

(: 
    InputValueDefinition :
    - Description? Name : Type DefaultValue? Directives[Const]?
:)
declare function parser:parse-input-value-definition(){
    (
        xdmp:log('[parser:parse-input-value-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return 
    <input-value-definition>
        {parser:parse-description()}
        {parser:parse-name()}
        {if (parser:expect-token($lex:COLON-LABEL)) then () else ()}
        {parser:parse-type-reference()}
        {if (parser:expect-optional-token($lex:EQUALS-LABEL)) then parser:parse-value-literal(xs:boolean('true')) else ()}
        {parser:parse-directives((), xs:boolean('true'))}
        {parser:loc($start)}
    </input-value-definition>
};

(: 
    InterfaceTypeDefinition :
    - Description? interface Name Directives[Const]? FieldsDefinition?
:)
declare function parser:parse-interface-type-definition(){
    (
        xdmp:log('[parser:parse-interface-type-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return 
    <interface-type-definition>
        {parser:parse-description()}
        {if (parser:expect-keyword('interface')) then () else ()}
        {parser:parse-name()}
        {parser:parse-implements-interfaces()}
        {parser:parse-directives((), xs:boolean('true'))}
        {parser:parse-fields-definition()}
        {parser:loc($start)}
    </interface-type-definition>
};

(: 
    UnionTypeDefinition :
    - Description? union Name Directives[Const]? UnionMemberTypes?
:)
declare function parser:parse-union-type-definition(){
    (
        xdmp:log('[parser:parse-union-type-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return 
    <union-type-definition>
        {parser:parse-description()}
        {if (parser:expect-keyword('union')) then () else ()}
        {parser:parse-name()}
        {parser:parse-directives((), xs:boolean('true'))}
        {parser:parse-union-member-types()}
        {parser:loc($start)}
    </union-type-definition>
};

(: 
    UnionMemberTypes :
    - = `|`? NamedType
    - UnionMemberTypes | NamedType
:)
declare function parser:parse-union-member-types(){
    (
        xdmp:log('[parser:parse-union-member-types]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $types := ()
    let $types :=
        if (parser:expect-optional-token($lex:EQUALS-LABEL))
        then 
            parser:parse-union-member-type($types)
        else ()
    return $types
};

declare function parser:parse-union-member-type($types){
    (
        xdmp:log('[parser:parse-union-member-type]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    if (parser:expect-optional-token($lex:PIPE-LABEL))
    then 
    (
        let $types := ($types, parser:parse-named-type())
        return parser:parse-union-member-type($types)
    )
    else $types
};

(: 
    EnumTypeDefinition :
    - Description? enum Name Directives[Const]? EnumValuesDefinition?
:)
declare function parser:parse-enum-type-definition(){
    (
        xdmp:log('[parser:parse-enum-type-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return 
    <enum-type-definition>
        {parser:parse-description()}
        {if (parser:expect-keyword('enum')) then () else ()}
        {parser:parse-name()}
        {parser:parse-directives((), xs:boolean('true'))}
        {parser:parse-enum-values-definition()}
        {parser:loc($start)}
    </enum-type-definition>
};

(: 
    EnumValuesDefinition : { EnumValueDefinition+ }
:)
declare function parser:parse-enum-values-definition(){
    (
        xdmp:log('[parser:parse-enum-values-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    parser:many-optional($lex:BRACE_L-LABEL, parser:parse-enum-value-definition#0, $lex:BRACE_R-LABEL)
};

(: 
    EnumValueDefinition : Description? EnumValue Directives[Const]?

    EnumValue : Name
:)
declare function parser:parse-enum-value-definition(){
    (
        xdmp:log('[parser:parse-enum-value-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return 
    <enum-value-definition>
        {parser:parse-description()}
        {parser:parse-name()}
        {parser:parse-directives((), xs:boolean('true'))}
        {parser:loc($start)}
    </enum-value-definition>
};

(: 
    InputObjectTypeDefinition :
    - Description? input Name Directives[Const]? InputFieldsDefinition?
:)
declare function parser:parse-input-object-type-definition(){
    (
        xdmp:log('[parser:parse-input-object-type-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return 
    <input-object-type-definition>
        {parser:parse-description()}
        {if (parser:expect-keyword('input')) then () else ()}
        {parser:parse-name()}
        {parser:parse-directives((), xs:boolean('true'))}
        {parser:parse-input-fields-definition()}
        {parser:loc($start)}
    </input-object-type-definition>
};

(: 
    InputFieldsDefinition : { InputValueDefinition+ }
:)
declare function parser:parse-input-fields-definition(){
    (
        xdmp:log('[parser:parse-input-fields-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    parser:many-optional($lex:BRACE_L-LABEL, parser:parse-input-value-definition#0, $lex:BRACE_R-LABEL)
};

(: 
    DirectiveDefinition :
    - Description? directive @ Name ArgumentsDefinition? `repeatable`? on DirectiveLocations
:)
declare function parser:parse-directive-definition(){
    (
        xdmp:log('[parser:parse-directive-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $start:= $TOKENS[$POS]
    return 
    <directive-definition>
        {parser:parse-description()}
        {if (parser:expect-keyword('directive')) then () else ()}
        {if (parser:expect-token($lex:AT-LABEL)) then () else ()}
        {parser:parse-name()}
        {parser:parse-arguments-definition()}
        {parser:expect-optional-keyword('repeatable')}
        {if (parser:expect-keyword('on')) then () else ()}
        {parser:parse-directive-locations()}
        {parser:loc($start)}
    </directive-definition>
};

(: 
    DirectiveLocations :
    - `|`? DirectiveLocation
    - DirectiveLocations | DirectiveLocation
:)
declare function parser:parse-directive-locations(){
    (
        xdmp:log('[parser:parse-directive-locations]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    let $_ := parser:expect-optional-token($lex:PIPE-LABEL)
    let $locations := ()
    let $locations := parser:parse-directive-location($locations)
    return $locations
};

declare function parser:parse-directive-location($locations){
    (
        xdmp:log('[parser:parse-directive-location]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),
    
    if (parser:expect-optional-token($lex:PIPE-LABEL))
    then 
    (
        let $locations := ($locations, parser:parse-directive-location-name())
        return parser:parse-union-member-type($locations)
    )
    else $locations
};

(: 
    DirectiveLocation :
        - ExecutableDirectiveLocation
        - TypeSystemDirectiveLocation

    ExecutableDirectiveLocation : one of
        `QUERY`
        `MUTATION`
        `SUBSCRIPTION`
        `FIELD`
        `FRAGMENT_DEFINITION`
        `FRAGMENT_SPREAD`
        `INLINE_FRAGMENT`

    TypeSystemDirectiveLocation : one of
        `SCHEMA`
        `SCALAR`
        `OBJECT`
        `FIELD_DEFINITION`
        `ARGUMENT_DEFINITION`
        `INTERFACE`
        `UNION`
        `ENUM`
        `ENUM_VALUE`
        `INPUT_OBJECT`
        `INPUT_FIELD_DEFINITION`
:)
declare function parser:parse-directive-location-name(){
    (
        xdmp:log('[parser:parse-directive-location-name]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $name := parser:parse-named-type()
    return 
    if ($name = $parser:DIRECTIVE_LOCATION_NAMES)
    then $name
    else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ",$TOKENS[$POS]))
};

(: 
    TypeSystemExtension :
        - SchemaExtension
        - TypeExtension

    TypeExtension :
        - ScalarTypeExtension
        - ObjectTypeExtension
        - InterfaceTypeExtension
        - UnionTypeExtension
        - EnumTypeExtension
        - InputObjectTypeDefinition
:)
declare function parser:parse-type-system-extension()
{
    (
        xdmp:log('[parser:parse-type-system-extension]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $token := $TOKENS[$POS+1]
    return
    if ($token/@type/string() eq $lex:NAME-LABEL)
    then
    (
        switch($token/@value/string())
            case 'schema'
                return parser:parse-schema-extension()
            case 'scalar'
                return parser:parse-scalar-type-extension()
            case 'type'
                return parser:parse-object-type-extension()
            case 'interface'
                return parser:parse-interface-type-extension()
            case 'union'
                return parser:parse-union-type-extension()
            case 'enum'
                return parser:parse-enum-type-extension()
            case 'input'
                return parser:parse-input-object-type-extension()
            default
                return fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ",$TOKENS[$POS]))
    ) 
    else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ",$TOKENS[$POS]))
};

(: 
    SchemaExtension :
    - extend schema Directives[Const]? { OperationTypeDefinition+ }
    - extend schema Directives[Const]
:)
declare function parser:parse-schema-extension(){
    (
        xdmp:log('[parser:parse-schema-extension]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start:= $TOKENS[$POS]
    let $_ := parser:expect-keyword('extend')
    let $_ := parser:expect-keyword('schema')
    let $directives := parser:parse-directives((), xs:boolean('true'))
    let $operation-types := parser:many-optional($lex:BRACE_L-LABEL, parser:parse-operation-type-definition#0, $lex:BRACE_R-LABEL)
    return
        if (fn:count($directives) gt 0 or fn:count($operation-types) gt 0)
        then 
        <schema-extension>
            {$directives}
            {$operation-types}
            {parser:loc($start)}
        </schema-extension>
        else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unexpected token: ",$start))
};

(: 
    ScalarTypeExtension :
    - extend scalar Name Directives[Const]
:)
declare function parser:parse-scalar-type-extension(){
    (
        xdmp:log('[parser:parse-scalar-type-extension]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start:= $TOKENS[$POS]
    let $_ := parser:expect-keyword('extend')
    let $_ := parser:expect-keyword('scalar')
    let $name := parser:parse-name()
    let $directives := parser:parse-directives((), xs:boolean('true'))
    return
        if (fn:count($directives) gt 0)
        then 
        <scalar-type-extension>
            {$name}
            {$directives}
            {parser:loc($start)}
        </scalar-type-extension>
        else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unexpected token: ",$start))
};

(: 
    ObjectTypeExtension :
    - extend type Name ImplementsInterfaces? Directives[Const]? FieldsDefinition
    - extend type Name ImplementsInterfaces? Directives[Const]
    - extend type Name ImplementsInterfaces
:)
declare function parser:parse-object-type-extension(){
    (
        xdmp:log('[parser:parse-object-type-extension]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start:= $TOKENS[$POS]
    let $_ := parser:expect-keyword('extend')
    let $_ := parser:expect-keyword('type')
    let $name := parser:parse-name()
    let $interfaces := parser:parse-implements-interfaces()
    let $directives := parser:parse-directives((), xs:boolean('true'))
    let $fields := parser:parse-fields-definition()
    return
        if (fn:count($interfaces) gt 0 or fn:count($directives) gt 0 or fn:count($fields) gt 0)
        then 
        <object-type-extension>
            {$name}
            {$interfaces}
            {$directives}
            {$fields}
            {parser:loc($start)}
        </object-type-extension>
        else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unexpected token: ",$start))
};

(: 
    InterfaceTypeExtension :
    - extend interface Name ImplementsInterfaces? Directives[Const]? FieldsDefinition
    - extend interface Name ImplementsInterfaces? Directives[Const]
    - extend interface Name ImplementsInterfaces
:)
declare function parser:parse-interface-type-extension(){
    (
        xdmp:log('[parser:parse-interface-type-extension]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start:= $TOKENS[$POS]
    let $_ := parser:expect-keyword('extend')
    let $_ := parser:expect-keyword('interface')
    let $name := parser:parse-name()
    let $interfaces := parser:parse-implements-interfaces()
    let $directives := parser:parse-directives((), xs:boolean('true'))
    let $fields := parser:parse-fields-definition()
    return
        if (fn:count($interfaces) gt 0 or fn:count($directives) gt 0 or fn:count($fields) gt 0)
        then 
        <interface-type-extension>
            {$name}
            {$interfaces}
            {$directives}
            {$fields}
            {parser:loc($start)}
        </interface-type-extension>
        else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unexpected token: ",$start))
};

(: 
    UnionTypeExtension :
    - extend union Name Directives[Const]? UnionMemberTypes
    - extend union Name Directives[Const]
:)
declare function parser:parse-union-type-extension(){
    (
        xdmp:log('[parser:parse-union-type-extension]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start:= $TOKENS[$POS]
    let $_ := parser:expect-keyword('extend')
    let $_ := parser:expect-keyword('union')
    let $name := parser:parse-name()
    let $directives := parser:parse-directives((), xs:boolean('true'))
    let $types := parser:parse-union-member-types()
    return
        if (fn:count($directives) gt 0 or fn:count($types) gt 0)
        then 
        <union-type-extension>
            {$name}
            {$directives}
            {$types}
            {parser:loc($start)}
        </union-type-extension>
        else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unexpected token: ",$start))
};

(: 
    EnumTypeExtension :
    - extend enum Name Directives[Const]? EnumValuesDefinition
    - extend enum Name Directives[Const]
:)
declare function parser:parse-enum-type-extension(){
    (
        xdmp:log('[parser:parse-enum-type-extension]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start:= $TOKENS[$POS]
    let $_ := parser:expect-keyword('extend')
    let $_ := parser:expect-keyword('enum')
    let $name := parser:parse-name()
    let $directives := parser:parse-directives((), xs:boolean('true'))
    let $values := parser:parse-enum-values-definition()
    return
        if (fn:count($directives) gt 0 or fn:count($values) gt 0)
        then 
        <enum-type-extension>
            {$name}
            {$directives}
            {$values}
            {parser:loc($start)}
        </enum-type-extension>
        else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unexpected token: ",$start))
};

(: 
    InputObjectTypeExtension :
    - extend input Name Directives[Const]? InputFieldsDefinition
    - extend input Name Directives[Const]
:)
declare function parser:parse-input-object-type-extension(){
    (
        xdmp:log('[parser:parse-input-object-type-extension]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $start:= $TOKENS[$POS]
    let $_ := parser:expect-keyword('extend')
    let $_ := parser:expect-keyword('input')
    let $name := parser:parse-name()
    let $directives := parser:parse-directives((), xs:boolean('true'))
    let $fields := parser:parse-input-fields-definition()
    return
        if (fn:count($directives) gt 0 or fn:count($fields) gt 0)
        then 
        <input-object-type-extension>
            {$name}
            {$directives}
            {$fields}
            {parser:loc($start)}
        </input-object-type-extension>
        else fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unexpected token: ",$start))
};

(: 
    Description : StringValue
:)
declare function parser:parse-description(){
    (
        xdmp:log('[parser:parse-description]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    if (parser:peek-description()) 
    then parser:parse-literal()
    else ()
};

(: 
    SelectionSet : { Selection+ }
:)
declare function parser:parse-selection-set()
{
    (
        xdmp:log('[parser:parse-selection-set]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    <selection-set>
    {parser:many($lex:BRACE_L-LABEL, parser:parse-selection#0, $lex:BRACE_R-LABEL)}
    </selection-set>
};

(: 
    Selection :
    - Field
    - FragmentSpread
    - InlineFragment
:)
declare function parser:parse-selection()
{
    (
        xdmp:log('[parser:parse-selection]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    if (parser:peek($lex:SPREAD-LABEL)) 
    then 
        parser:parse-fragment() 
    else 
        parser:parse-field()
};

(: 
    Implements the parsing rules in the Fragments section.

    Corresponds to both FragmentSpread and InlineFragment in the spec.

    FragmentSpread : ... FragmentName Directives?

    InlineFragment : ... TypeCondition? Directives? SelectionSet
:)
declare function parser:parse-fragment()
{
    (
        xdmp:log('[parser:parse-fragment]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $_ := parser:expect-token($lex:SPREAD-LABEL)
    let $has-type-condition := parser:expect-optional-keyword('on')
    return
    if (not($has-type-condition) and parser:peek($lex:NAME-LABEL)) 
    then
    (
        <fragment_spread>
            {parser:parse-fragment-name()}
            {parser:parse-directives((), xs:boolean('false'))}
        </fragment_spread>
    )
    else
    (
        <inline_fragment>
            <type-condition>{if ($has-type-condition) then parser:parse-named-type() else 'undefined'}</type-condition>
            {parser:parse-directives((), xs:boolean('false'))}
            {parser:parse-selection-set()}
        </inline_fragment>
    )
};

declare function parser:parse-named-type()
{
    (
        xdmp:log('[parser:parse-named-type]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    <named-type>
        {parser:parse-name()}
    </named-type>
};

(: 
    FragmentName : Name but not `on`
:)
declare function parser:parse-fragment-name()
{
    (
        xdmp:log('[parser:parse-fragment-name]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    if ($TOKENS[$POS]/@value/string() eq 'on') 
    then fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ",$TOKENS[$POS]))
    else parser:parse-name()
};

(: 
    Field : Alias? Name Arguments? Directives? SelectionSet?

    Alias : Name :
:)
declare function parser:parse-field()
{
    (
        xdmp:log('[parser:parse-field]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $name-or-alias := parser:parse-name()
    let $name := ''
    let $alias := ''

    let $_ :=
        if (parser:expect-optional-token($lex:COLON-LABEL)) then 
        (
            let $_ := xdmp:set($alias, $name-or-alias/@value/string())
            let $_ := xdmp:set($name, parser:parse-name())
            return ()
        )
        else
        (
            let $_ := xdmp:set($name, $name-or-alias)
            return ()
        )

    return 
        element field {
            (
                if (fn:string-length($alias)>0) 
                then attribute alias { $alias } 
                else ()
            )
            ,$name
            ,parser:parse-arguments(xs:boolean('false'))
            ,parser:parse-directives((), xs:boolean('false'))
            ,(
                if (parser:peek($lex:BRACE_L-LABEL)) 
                then parser:parse-selection-set()
                else ()
            )
        }
};

(: 
    Arguments[Const] : ( Argument[?Const]+ )
:)
declare function parser:parse-arguments($is-constant as xs:boolean)
{
    (
        xdmp:log('[parser:parse-arguments]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $func := if ($is-constant) 
                then parser:parse-const-argument#0                  
                else parser:parse-argument#0
    let $arguments := parser:many-optional($lex:PAREN_L-LABEL, $func, $lex:PAREN_R-LABEL)
    return
        if (fn:count($arguments)>0) then <arguments>{$arguments}</arguments> else ()
};

declare function parser:parse-const-argument()
{ 
    (
        xdmp:log('[parser:parse-const-argument]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    <const-arg/>
};

(: 
    Argument[Const] : Name : Value[?Const]
:)
declare function parser:parse-argument()
{   
    (
        xdmp:log('[parser:parse-argument]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $name := parser:parse-name()
    let $_ := parser:expect-token($lex:COLON-LABEL)
    let $value := parser:parse-value-literal(xs:boolean('false'))
    return
        <argument>
            {$name}
            <value>{$value}</value>
        </argument>
};

(: 
    Implements the parsing rules in the Directives section.

    Directives[Const] : Directive[?Const]+
:)
declare function parser:parse-directives($tokens as node()*,$is-constant as xs:boolean)
{
    (
        xdmp:log('[parser:parse-directives]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    if (parser:peek($lex:AT-LABEL))
    then 
    (
        let $tokens := ($tokens, parser:parse-directive($is-constant))
        return parser:parse-directives($tokens, $is-constant)
    )
    else
        if (fn:count($tokens)>0) then <directives>{$tokens}</directives> else ()
};

(: 
    Directive[Const] : @ Name Arguments[?Const]?
:)
declare function parser:parse-directive($is-constant as xs:boolean)
{
    (
        xdmp:log('[parser:parse-directive]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $_ := parser:expect-token($lex:AT-LABEL)
    return 
    <directive>
        {parser:parse-name()}
        {parser:parse-arguments($is-constant)}
    </directive>
};

(: 
    VariableDefinitions : ( VariableDefinition+ )
:)
declare function parser:parse-variable-definitions()
{
    (
        xdmp:log('[parser:parse-variable-definitions]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    parser:many-optional($lex:PAREN_L-LABEL, parser:parse-variable-definition#0, $lex:PAREN_R-LABEL)
};

(: 
    VariableDefinition : Variable : Type DefaultValue? Directives[Const]?
:)
declare function parser:parse-variable-definition()
{
    (
        xdmp:log('[parser:parse-variable-definition]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    <variable-definition>
        {parser:parse-variable()}
        <type>
        {
            let $_ := parser:expect-token($lex:COLON-LABEL) 
            return parser:parse-type-reference()
        }
        </type>
        {
            if (parser:expect-optional-token($lex:EQUALS-LABEL))
            then <default-value>{parser:parse-value-literal(xs:boolean('true'))}</default-value>
            else ()
        }
        {parser:parse-directives((), xs:boolean('true'))}
    </variable-definition>
};

(: 
    Implements the parsing rules in the Types section.

    Type :
    - NamedType
    - ListType
    - NonNullType
:)
declare function parser:parse-type-reference()
{
    (
        xdmp:log('[parser:parse-type-reference]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $type := 
        if (parser:expect-optional-token($lex:BRACKET_L-LABEL)) 
        then
        (
            let $type := parser:parse-type-reference()
            let $_ := parser:expect-token($lex:BRACKET_R-LABEL)
            return
            <list-type>
            {$type}
            </list-type>
        )
        else
        (
            parser:parse-named-type() 
        )

    return
        if (parser:expect-optional-token($lex:BANG-LABEL))
        then 
            <non-null-type>
            {$type}
            </non-null-type>
        else
            $type
};

(: 
    OperationType : one of query mutation subscription
:)
declare function parser:parse-operation-type()
{
    (
        xdmp:log('[parser:parse-operation-type]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $operation-token := parser:expect-token($lex:NAME-LABEL)
    return 
    switch($operation-token/@value/string())
        case 'query' 
            return 'query'
        case 'mutation' 
            return 'mutation'
        case 'subscription' 
            return 'subscription'
        default
            return fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ", $TOKENS[$POS]))
};

(: 
    Converts a name lex token into a name parse node.
:)
declare function parser:parse-name()
{
    (
        xdmp:log('[parser:parse-name]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $token := parser:expect-token($lex:NAME-LABEL)    
    return
        <name value="{$token/@value/string()}">
        {parser:loc($token)}
        </name>
};

declare function parser:parse-value-literal()
{
    parser:parse-value-literal(xs:boolean('false'))
};

(: 
    Value[Const] :
    - [~Const] Variable
    - IntValue
    - FloatValue
    - StringValue
    - BooleanValue
    - NullValue
    - EnumValue
    - ListValue[?Const]
    - ObjectValue[?Const]

    BooleanValue : one of `true` `false`

    NullValue : `null`

    EnumValue : Name but not `true`, `false` or `null`
:)
declare function parser:parse-value-literal($is-constant as xs:boolean)
{
    (
        xdmp:log('[parser:parse-value-literal]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $token := $TOKENS[$POS]

    return

        switch($token/@type/string())
        case 'BRACKET_L' 
        return 
            parser:parse-list($is-constant)
        case 'BRACE_L' 
        return 
            parser:parse-object($is-constant)
        case 'BRACE_R' 
        return 
            ()
        case 'NUMBER'
        return
        (
            let $_ := xdmp:set($POS, $POS+1)
            let $number := $token[1]/@value/string()
            return
                if (fn:contains($number, '.'))
                then <float value="{$token[1]/@value/string()}"/>
                else <int value="{$token[1]/@value/string()}"/>
        )
        (: case 'INT' 
        return
        (
            let $_ := xdmp:set($POS, $POS+1)
            return <int value="{$token[1]/@value/string()}"/>
        )
        case 'FLOAT' 
        return
        (
            let $_ := xdmp:set($POS, $POS+1)
            return <float value="{$token[1]/@value/string()}"/>
        ) :)
        case 'STRING' 
        case 'BLOCK_STRING' 
        return 
            parser:parse-literal()
        case 'DOLLAR'
        return
            if (not($is-constant)) then parser:parse-variable() else ()
        case 'NAME'
        case 'BooleanLiteral'
        return
            if ($token/@value/string() eq 'true' or $token/@value/string() eq 'false') then 
            (
                let $_ := xdmp:set($POS, $POS+1)
                return <boolean value="{$token[1]/@value/string()}"/>
            ) 
            else if ($token/@value/string() eq 'null') then
            (
                let $_ := xdmp:set($POS, $POS+1)
                return <null/>
            )
            else 
            (
                let $_ := xdmp:set($POS, $POS+1)
                return <enum value="{$token[1]/@value/string()}"/>
            )
        default 
        return 
            fn:error((), 'PARSER EXCEPTION', ("500", "Internal server error", "unable to parse input: ",$TOKENS[$POS]))

};

declare function parser:parse-literal()
{
    (
        xdmp:log('[parser:parse-literal]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $token := $TOKENS[$POS]
    let $value := fn:replace($token[1]/@value/string(), '"', '') (: needed to remove extra "" around the string element :)
    let $_ := xdmp:set($POS, $POS+1)
    return 
        <string value="{$value}" block="{$token[1]/@type/string() eq 'BLOCK_STRING'}"/>
};

declare function parser:parse-list($is-constant as xs:boolean)
{
    (
        xdmp:log('[parser:parse-list]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    <list>
        {parser:many-optional($lex:BRACKET_L-LABEL, parser:parse-value-literal#0, $lex:BRACKET_R-LABEL)}
    </list>
};

(: 
    ObjectValue[Const] :
    - { }
    - { ObjectField[?Const]+ }
:)
declare function parser:parse-object($is-constant as xs:boolean)
{
    (
        xdmp:log('[parser:parse-object]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    <object>
        {parser:many-optional($lex:BRACE_L-LABEL, parser:parse-object-field#0, $lex:BRACE_R-LABEL)}
    </object>
};

(: 
    ObjectField[Const] : Name : Value[?Const]
:)
declare function parser:parse-object-field()
{
    (
        xdmp:log('[parser:parse-object-field]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    if (parser:peek('NAME'))
    then
    (
        let $name := parser:parse-name()
        let $_ := parser:expect-token($lex:COLON-LABEL)
        let $value := parser:parse-value-literal()
        return
            <object-field>
                {$name}
                <value>{$value}</value>
            </object-field>
    )
    else ()
};

(: 
    Variable : $ Name
:)
declare function parser:parse-variable()
{
    (
        xdmp:log('[parser:parse-variable]: '||xdmp:describe($TOKENS[$POS], (),()))
    ),

    let $_ := parser:expect-token($lex:DOLLAR-LABEL)
    return
    <variable>
        {parser:parse-name()}
    </variable>
};

(: 
    Returns a location object, used to identify the place in
    the source that created a given parsed object.
:)
declare function parser:loc($start-token)
{
    if ($parser:LOCATION)
    then
        <location>
            {$start-token}
            <last-token/>
            <source/>
        </location>
    else 
        ()
};