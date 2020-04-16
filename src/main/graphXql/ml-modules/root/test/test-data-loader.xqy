xquery version "1.0-ml";

(:declare namespace tdl = "/graphXql/one/test-data-loader";:)
module namespace tdl = "/graphXql/one/test-data-loader";
import module namespace cvt = "http://marklogic.com/cpf/convert" at "/MarkLogic/conversion/convert.xqy";

declare namespace s="http://www.w3.org/2005/xpath-functions";

declare variable $tdl:UNSUPPORTED_FILE_NAME_TEMPLATE as xs:string := 'unsupported file name template';
declare variable $tdl:URI-ROOT as xs:string := '/graphXql/';
declare variable $tdl:__CALLER_FILE__ := tdl:get-caller();

(:-----------------------------------
    SUPPORTED TEST DATA FILE TYPES
-------------------------------------:)
declare variable $tdl:TYPE_EVENT := 'event';
declare variable $tdl:TYPE_EVENT-PARTICIPATION := 'event-participation';
declare variable $tdl:TYPE_SESSION-PARTICIPATION := 'session-participation';
declare variable $tdl:TYPE_SESSION := 'session';
declare variable $tdl:TYPE_PERSON := 'person';
declare variable $tdl:TYPE_PERSON-VERSION := 'person-version';
declare variable $tdl:TYPE_OFFDOC := 'offdoc';
declare variable $tdl:TYPE_LV := 'lv';
declare variable $tdl:TYPE_REP := 'rep';
declare variable $tdl:TYPE_ROOM-DOC := 'roomdoc';
declare variable $tdl:TYPE_PUB-LV := 'pub-lv';
declare variable $tdl:TYPE_PUB-REP := 'pub-rep';
declare variable $tdl:TYPE_DELEGATION-MEMBERSHIP := 'delegation-membership';
declare variable $tdl:TYPE_DELEGATION := 'delegation';
declare variable $tdl:TYPE_FUNCTIONAL-ROLE := 'functional-role';
declare variable $tdl:TYPE_ALERT := 'alert';
declare variable $tdl:TYPE_DOWNLOAD := 'download';
declare variable $tdl:TYPE_COUNTRY := 'country';
declare variable $tdl:TYPE_CITY := 'city';
declare variable $tdl:TYPE_ROLES := 'roles';
declare variable $tdl:TYPE_LANGUAGE := 'language';
declare variable $tdl:TYPE_SEARCH-RESPONSE := 'search-response';
declare variable $tdl:TYPE_REGISTRATION-STATUS := 'registration-status';
declare variable $tdl:TYPE_COMPANY := 'company';
declare variable $tdl:TYPE_TYPES := 'types';
declare variable $tdl:TYPE_CHANGE_LOG := 'change-log';
declare variable $tdl:TYPE_PROFILE := 'profile';
declare variable $tdl:TYPE_TILE := 'tile';
declare variable $tdl:TYPE_ROOT_COTE := 'root-cote';
declare variable $tdl:TYPE_COUNTRY_RESTRICTION := 'country-restriction';
declare variable $tdl:TYPE_ACCESS_REQUEST := 'access-request';
declare variable $tdl:TYPE_DOC_ACCESS_RULE := 'doc-access-rule';
declare variable $tdl:TYPE_MEDIA_FILE := 'media-file';
declare variable $tdl:TYPE_BO_ACCESS_RIGHTS := 'bo-access-rights';
declare variable $tdl:TYPE_BO_FUNCTIONALITY := 'bo-functionality';
(:-----------------------------------------------
    REGULAR EXPRESSIONS MATCHING FILE TEMPLATES
-------------------------------------------------:)
declare variable $tdl:FILENAME_TEMPLATES as map:map := map:map()
    => map:with($tdl:TYPE_EVENT,'^event-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_EVENT-PARTICIPATION,'^event-participation-([0-9]*(_merged)?)-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_SESSION-PARTICIPATION,'^session-participation-([0-9]*(_merged)?)-([0-9]*)-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_SESSION,'^session-([0-9]*)-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_PERSON,'^person-([0-9]*(_merged)?)\.xml$')
    => map:with($tdl:TYPE_PERSON-VERSION,'^person-([0-9]*(_merged)?)-(([0-9]{4})-([0-9]{2})-([0-9]{2})T([0-9]{2})-([0-9]{2})-([0-9]{2})-([0-9]{0,4}))\.xml$')
    => map:with($tdl:TYPE_OFFDOC,'^offdoc-([0-9\-\(\)a-zA-Z]*)\.xml$')
    => map:with($tdl:TYPE_LV,'^lv-([0-9\-\(\)a-zA-Z]*)-([a-zA-Z]{2})\.xml$')
    => map:with($tdl:TYPE_REP,'^rep-([0-9\-\(\)a-zA-Z]*)-([a-zA-Z]{2})-(doc|docx|html|pdf)\.xml$')
    => map:with($tdl:TYPE_ROOM-DOC,'^room-doc-([0-9\(\)a-zA-Z]*)-([0-9\(\)a-zA-Z]*)\.xml$')
    => map:with($tdl:TYPE_PUB-LV,'^pub-([0-9]*)-([a-zA-Z]{2})\.xml$')
    => map:with($tdl:TYPE_PUB-REP,'^pub-rep-([0-9]*)-([a-zA-Z]{2})-(doc|docx|html|pdf)\.xml$')
    => map:with($tdl:TYPE_DELEGATION-MEMBERSHIP,'^delegation-([a-zA-Z]{2})-membership-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_DELEGATION,'^delegation-([a-zA-Z]{2})\.xml$')
    => map:with($tdl:TYPE_FUNCTIONAL-ROLE,'^functional-role-([a-zA-Z]*)\.xml$')
    => map:with($tdl:TYPE_ALERT,'^alert-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_DOWNLOAD,'^download-([a-z0-9]*)\.xml$')
    => map:with($tdl:TYPE_COUNTRY,'^country-([a-zA-Z]{2})\.xml$')
    => map:with($tdl:TYPE_CITY,'^city-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_ROLES,'^roles\.xml$')
    => map:with($tdl:TYPE_LANGUAGE,'^lang-([a-zA-Z]*)\.xml$')
    => map:with($tdl:TYPE_SEARCH-RESPONSE,'^search-response-([0-9\-\(\)a-zA-Z]*)\.xml$')
    => map:with($tdl:TYPE_REGISTRATION-STATUS,'^registration-status\.xml$')
    => map:with($tdl:TYPE_COMPANY,'^company-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_TYPES,'^types\.xml$')
    => map:with($tdl:TYPE_CHANGE_LOG,'^change-log-([0-9a-zA-Z-]*)\.xml$')
    => map:with($tdl:TYPE_PROFILE,'^profile-([0-9a-zA-Z-]*)\.xml$')
    => map:with($tdl:TYPE_TILE,'^tile-([0-9a-zA-Z-]*)\.xml$')
    => map:with($tdl:TYPE_ROOT_COTE,'^root-cote-([A-Z?-]*)\.xml$')
    => map:with($tdl:TYPE_COUNTRY_RESTRICTION,'^country-restriction-([A-Z]{2})\.xml$')
    => map:with($tdl:TYPE_ACCESS_REQUEST,'^access-request-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_DOC_ACCESS_RULE, '^doc-access-rule-([a-z]{2})\.xml$')
    => map:with($tdl:TYPE_MEDIA_FILE, '^mediafile-([a-zA-Z]*)-([a-zA-Z]*)-([a-zA-Z]*)-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_BO_ACCESS_RIGHTS, '^bo-access-rights-([0-9]*)\.xml$')
    => map:with($tdl:TYPE_BO_FUNCTIONALITY, '^bof-([a-z\-]*)\.xml$');

(:------------------------------
    COLLECTIONS PER FILE TYPES
--------------------------------:)
declare variable $tdl:COLLECTIONS as map:map :=map:map()
    => map:with($tdl:TYPE_EVENT, ('/graphXql/one-content', '/graphXql/events'))
    => map:with($tdl:TYPE_EVENT-PARTICIPATION, ('/graphXql/event-participations'))
    => map:with($tdl:TYPE_SESSION-PARTICIPATION, ('/graphXql/session-participations'))
    => map:with($tdl:TYPE_SESSION, ('/graphXql/events/sessions'))
    => map:with($tdl:TYPE_PERSON, ('/graphXql/one-content', '/graphXql/persons'))
    => map:with($tdl:TYPE_PERSON-VERSION, ('/graphXql/persons/versions'))
    => map:with($tdl:TYPE_OFFDOC, ('/graphXql/official-documents'))
    => map:with($tdl:TYPE_LV, ('/graphXql/one-content', '/graphXql/language-version'))
    => map:with($tdl:TYPE_REP, ('/graphXql/representation'))
    => map:with($tdl:TYPE_ROOM-DOC, ('/graphXql/room-documents'))
    => map:with($tdl:TYPE_PUB-LV, ('/graphXql/pub-language-version', '/graphXql/one-content'))
    => map:with($tdl:TYPE_PUB-REP, ('/graphXql/pub-representation'))
    => map:with($tdl:TYPE_DELEGATION-MEMBERSHIP, ('/graphXql/delegation-memberships'))
    => map:with($tdl:TYPE_DELEGATION, ('/graphXql/delegations'))
    => map:with($tdl:TYPE_FUNCTIONAL-ROLE, ('http://ems.oecd.org/delegation-functionnal-roles'))
    => map:with($tdl:TYPE_ALERT, ('/graphXql/alerts'))
    => map:with($tdl:TYPE_DOWNLOAD, ('/graphXql/downloads'))
    => map:with($tdl:TYPE_COUNTRY, ('/graphXql/Taxonomy/Countries#Countries','/graphXql/reference-data'))
    => map:with($tdl:TYPE_CITY, ('/graphXql/Taxonomy/Cities#Cities'))
    => map:with($tdl:TYPE_ROLES, ('/graphXql/Taxonomy/Roles#Roles'))
    => map:with($tdl:TYPE_LANGUAGE, ('http://kim.oecd.org/Taxonomy/Languages#Languages'))
    => map:with($tdl:TYPE_REGISTRATION-STATUS, ('/graphXql/RegistrationStatus#Participants'))
    => map:with($tdl:TYPE_COMPANY, ('/graphXql/company'))
    => map:with($tdl:TYPE_TYPES, ('/graphXql/reference-data', '/graphXql/Taxonomy/Types#Types'))
    => map:with($tdl:TYPE_CHANGE_LOG, ('/graphXql/change-logs'))
    => map:with($tdl:TYPE_PROFILE, ('/graphXql/document-access/profiles'))
    => map:with($tdl:TYPE_TILE, ('/graphXql/tiles'))
    => map:with($tdl:TYPE_ROOT_COTE, ('/graphXql/root-cotes'))
    => map:with($tdl:TYPE_COUNTRY_RESTRICTION, ('/graphXql/document-access/country-restrictions'))
    => map:with($tdl:TYPE_ACCESS_REQUEST, ('/graphXql/document-access/access-requests', '/graphXql/top-level-cotes-access-requests'))
    => map:with($tdl:TYPE_DOC_ACCESS_RULE, ('/graphXql/doc-access-rules'))
    => map:with($tdl:TYPE_MEDIA_FILE, ('/graphXql/media-files'))
    => map:with($tdl:TYPE_BO_ACCESS_RIGHTS, ('/graphXql/back-office/access-rights'))
    => map:with($tdl:TYPE_BO_FUNCTIONALITY, ('/graphXql/back-office/functionalities'));

declare function tdl:apply-template-matcher($filename as xs:string, $file_type as xs:string) {
    let $regex := map:get($tdl:FILENAME_TEMPLATES, $file_type)
    return fn:analyze-string($filename, $regex, '')
};

declare function tdl:compute-bo-access-rights-uri($matches as node()*){
  let $key := $matches//s:match/s:group[@nr eq 1]/string()
  return fn:concat($tdl:URI-ROOT, 'back-office/access-right/', $key)
};

declare function tdl:compute-bo-functionality-uri($matches as node()*){
  let $key := $matches//s:match/s:group[@nr eq 1]/string()
  return fn:concat($tdl:URI-ROOT, 'back-office/functionality/', $key)
};

declare function tdl:compute-offdoc-uri($matches as node()*){
    let $doc-uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $doc-uri := fn:replace($doc-uri, "-", "/")
    return fn:concat($tdl:URI-ROOT, 'document/', $doc-uri)
};

declare function tdl:compute-search-response-uri($matches as node()*){
    let $doc-uri := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat('/search-response-', $doc-uri)
};

declare function tdl:compute-lv-uri($matches as node()*)as xs:string{
    let $doc-uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $lang := $matches//s:match/s:group[@nr eq 2]/string()
    let $doc-uri := fn:replace($doc-uri, "-", "/")
    return fn:concat($tdl:URI-ROOT, 'document/', $doc-uri, '/', $lang)
};

declare function tdl:compute-rep-uri($matches as node()*)as xs:string{
    let $doc-uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $lang := $matches//s:match/s:group[@nr eq 2]/string()
    let $format := $matches//s:match/s:group[@nr eq 3]/string()
    let $doc-uri := fn:replace($doc-uri, "-", "/")
    return fn:concat($tdl:URI-ROOT, 'document/', $doc-uri, '/', $lang, '/', $format)
};

declare function tdl:compute-roomdoc-uri($matches as node()*){
    let $event-uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $doc-uri := $matches//s:match/s:group[@nr eq 2]/string()
    return fn:concat($tdl:URI-ROOT, 'event/', $event-uri, '/documents/', $doc-uri)
};

declare function tdl:compute-pub-lv-uri($matches as node()*){
    let $doc-uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $lang := $matches//s:match/s:group[@nr eq 2]/string()
    return fn:concat($tdl:URI-ROOT, 'publication/', $doc-uri, '/', $lang)
};

declare function tdl:compute-pub-rep-uri($matches as node()*)as xs:string{
    let $doc-uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $lang := $matches//s:match/s:group[@nr eq 2]/string()
    let $format := $matches//s:match/s:group[@nr eq 3]/string()
    return fn:concat($tdl:URI-ROOT, 'publication/', $doc-uri, '/', $lang, '/', $format)
};

declare function tdl:compute-event-uri($matches as node()*)as xs:string{
    let $event-uri := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat($tdl:URI-ROOT, 'event/', $event-uri)
};

declare function tdl:compute-company-uri($matches as node()*)as xs:string{
    let $company-key := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat($tdl:URI-ROOT, 'Taxonomy/Companies#', $company-key)
};

declare function tdl:compute-alert-uri($matches as node()*)as xs:string{
    let $alert-uri := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat($tdl:URI-ROOT, 'alert/', $alert-uri)
};

declare function tdl:compute-download-uri($matches as node()*)as xs:string{
    let $uri := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat($tdl:URI-ROOT, 'download/', $uri)
};

declare function tdl:compute-country-uri($matches as node()*)as xs:string{
    let $country-uri := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat('http://kim.oecd.org/Taxonomy/ISO31661/A2#', fn:upper-case($country-uri))
};

declare function tdl:compute-city-uri($filename as xs:string)as xs:string{
    let $matches := tdl:apply-template-matcher($filename, $tdl:TYPE_CITY)
    let $city-uri := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat('http://ems.oecd.org/Taxonomy/City#', $city-uri)
};

declare function tdl:compute-session-uri($matches as node()*)as xs:string{
    let $event-uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $session-uri := $matches//s:match/s:group[@nr eq 2]/string()
    return fn:concat($tdl:URI-ROOT, 'event/session/', $event-uri, '#', $session-uri)
};

declare function tdl:compute-person-uri($matches as node()*)as xs:string{
    let $person-uri := $matches//s:match/s:group[@nr eq 1]/string()||$matches//s:match/s:group[@nr eq 2]/string()
    return fn:concat($tdl:URI-ROOT, 'person/', $person-uri)
};

declare function tdl:compute-media-file-uri($matches as node()*) as xs:string {
    let $media-type := $matches//s:match/s:group[@nr eq 1]/string()
    let $photo-type := $matches//s:match/s:group[@nr eq 2]/string()
    let $photo-size := $matches//s:match/s:group[@nr eq 3]/string()
    let $contact-key := $matches//s:match/s:group[@nr eq 4]/string()
    return fn:concat($tdl:URI-ROOT, 'media-file/', $media-type, '/', $photo-type, '/' ,$photo-size, '/', $contact-key)
};

declare function tdl:compute-person-version-uri($matches as node()*)as xs:string{
    let $person-uri := $matches//s:match//s:group[@nr eq 1]/string()||$matches//s:match//s:group[@nr eq 2]/string()
    let $year := $matches//s:match//s:group[@nr eq 4]/string()
    let $month := $matches//s:match//s:group[@nr eq 5]/string()
    let $day := $matches//s:match//s:group[@nr eq 6]/string()
    let $hour := $matches//s:match//s:group[@nr eq 7]/string()
    let $min := $matches//s:match//s:group[@nr eq 8]/string()
    let $sec := $matches//s:match//s:group[@nr eq 9]/string()
    let $mill := $matches//s:match//s:group[@nr eq 10]/string()
    let $date := fn:concat($year,'-', $month,'-',$day,'T',$hour,':',$min,':',$sec,'.',$mill) 
    return fn:concat($tdl:URI-ROOT, 'person/', $person-uri, '/', $date)
};

declare function tdl:compute-session-participation-uri($matches as node()*)as xs:string{
    let $person-uri := $matches//s:match/s:group[@nr eq 1]/string()||$matches//s:match/s:group[@nr eq 2]/string()
    let $event-uri := $matches//s:match/s:group[@nr eq 3]/string()
    let $session-uri := $matches//s:match/s:group[@nr eq 4]/string()
    return fn:concat($tdl:URI-ROOT, 'person/', $person-uri, '/event/', $event-uri, '/session/', $session-uri)
};

declare function tdl:compute-event-participation-uri($matches as node()*)as xs:string{
    let $person-uri := $matches//s:match/s:group[@nr eq 1]/string()||$matches//s:match/s:group[@nr eq 2]/string()
    let $event-uri := $matches//s:match/s:group[@nr eq 3]/string()
    return fn:concat($tdl:URI-ROOT, 'person/', $person-uri, '/event/', $event-uri)
};

declare function tdl:compute-delegation-membership-uri($matches as node()*) as xs:string{
    let $country-iso := $matches//s:match/s:group[@nr eq 1]/string()
    let $uri := $matches//s:match/s:group[@nr eq 2]/string()
    return fn:concat($tdl:URI-ROOT, 'delegation/',$country-iso, '/person/', $uri)
};

declare function tdl:compute-delegation-uri($matches as node()*) as xs:string{
    let $country-iso := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat($tdl:URI-ROOT, 'delegation/', fn:lower-case($country-iso))
};

declare function tdl:compute-functional-role-uri($matches as node()*) as xs:string{
    let $uri := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat('http://ems.oecd.org/delegation-functionnal-role/', $uri)
};

declare function tdl:compute-language-uri($matches as node()*) as xs:string{
    let $uri := $matches//s:match/s:group[@nr eq 1]/string()
    return fn:concat('http://kim.oecd.org/Taxonomy/Languages#', $uri)
};

declare function tdl:compute-change-log-uri($matches as node()*) as xs:string{
    let $uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $uri := fn:concat('/graphXql/change-log/', $uri)
    let $_ := xdmp:log(fn:concat('tdl:compute-change-log-uri: ', $uri), 'debug')
    return $uri
};

declare function tdl:compute-access-request-uri($matches as node()*) as xs:string {
    let $uri := $matches//s:match/s:group[@nr eq 1]/string()
    let $uri := fn:concat('/graphXql/document-access/access-request/', $uri)
    let $_ := xdmp:log(fn:concat('tdl:compute-access-request-uri: ', $uri), 'debug')
    return $uri
};

declare function tdl:compute-profile-uri($matches as node()*) as xs:string{
    let $key := $matches//s:match/s:group[@nr eq 1]/string()
    let $uri := fn:concat('/graphXql/document-access/profile/', $key)
    return $uri
};

declare function tdl:compute-root-cote-uri($matches as node()*) as xs:string{
    let $key := $matches//s:match/s:group[@nr eq 1]/string()
    let $key := fn:replace($key, "-", "/")
    let $uri := fn:concat('/graphXql/root-cote/', $key)
    return $uri
};

declare function tdl:compute-country-restriction-uri($matches as node()*) as xs:string{
    let $key := $matches//s:match/s:group[@nr eq 1]/string()
    let $uri := fn:concat('/graphXql/document-access/country-restriction/', $key)
    return $uri
};

declare function tdl:compute-tile-uri($matches as node()*) as xs:string{
    let $key := $matches//s:match/s:group[@nr eq 1]/string()
    let $uri := fn:concat('/graphXql/tile/', $key)
    return $uri
};

declare function tdl:compute-doc-access-rule-uri($matches as node()*) as xs:string{
    let $key := $matches//s:match/s:group[@nr eq 1]/string()
    let $uri := fn:concat('/graphXql/doc-access-rule/', $key)
    return $uri
};

declare function tdl:compute-entity-uri($file_type as xs:string, $filename as xs:string)as xs:string{
    let $matches := tdl:apply-template-matcher($filename, $file_type)
    return
    if      ($file_type eq $tdl:TYPE_EVENT) then tdl:compute-event-uri($matches)
    else if ($file_type eq $tdl:TYPE_EVENT-PARTICIPATION) then tdl:compute-event-participation-uri($matches)
    else if ($file_type eq $tdl:TYPE_SESSION-PARTICIPATION) then tdl:compute-session-participation-uri($matches)
    else if ($file_type eq $tdl:TYPE_SESSION) then tdl:compute-session-uri($matches)
    else if ($file_type eq $tdl:TYPE_PERSON) then tdl:compute-person-uri($matches)
    else if ($file_type eq $tdl:TYPE_PERSON-VERSION) then tdl:compute-person-version-uri($matches)
    else if ($file_type eq $tdl:TYPE_OFFDOC) then tdl:compute-offdoc-uri($matches)
    else if ($file_type eq $tdl:TYPE_LV) then tdl:compute-lv-uri($matches)
    else if ($file_type eq $tdl:TYPE_REP) then tdl:compute-rep-uri($matches)
    else if ($file_type eq $tdl:TYPE_ROOM-DOC) then tdl:compute-roomdoc-uri($matches)
    else if ($file_type eq $tdl:TYPE_PUB-LV) then tdl:compute-pub-lv-uri($matches)
    else if ($file_type eq $tdl:TYPE_PUB-REP) then tdl:compute-pub-rep-uri($matches)
    else if ($file_type eq $tdl:TYPE_DELEGATION-MEMBERSHIP) then tdl:compute-delegation-membership-uri($matches)
    else if ($file_type eq $tdl:TYPE_DELEGATION) then tdl:compute-delegation-uri($matches)
    else if ($file_type eq $tdl:TYPE_FUNCTIONAL-ROLE) then tdl:compute-functional-role-uri($matches)
    else if ($file_type eq $tdl:TYPE_ALERT) then tdl:compute-alert-uri($matches)
    else if ($file_type eq $tdl:TYPE_DOWNLOAD) then tdl:compute-download-uri($matches)
    else if ($file_type eq $tdl:TYPE_COUNTRY) then tdl:compute-country-uri($matches)
    else if ($file_type eq $tdl:TYPE_CITY) then tdl:compute-city-uri($matches)
    else if ($file_type eq $tdl:TYPE_LANGUAGE) then tdl:compute-language-uri($matches)
    else if ($file_type eq $tdl:TYPE_ROLES) then '/graphXql/Taxonomy/Roles'
    else if ($file_type eq $tdl:TYPE_SEARCH-RESPONSE) then tdl:compute-search-response-uri($matches) (: '/search-response.xml' :)
    else if ($file_type eq $tdl:TYPE_REGISTRATION-STATUS) then '/graphXql/RegistrationStatus'
    else if ($file_type eq $tdl:TYPE_COMPANY) then tdl:compute-company-uri($matches)
    else if ($file_type eq $tdl:TYPE_TYPES) then '/graphXql/Taxonomy/Types'
    else if ($file_type eq $tdl:TYPE_CHANGE_LOG) then tdl:compute-change-log-uri($matches)
    else if ($file_type eq $tdl:TYPE_ACCESS_REQUEST) then tdl:compute-access-request-uri($matches)
    else if ($file_type eq $tdl:TYPE_PROFILE) then tdl:compute-profile-uri($matches)
    else if ($file_type eq $tdl:TYPE_TILE) then tdl:compute-tile-uri($matches)
    else if ($file_type eq $tdl:TYPE_ROOT_COTE) then tdl:compute-root-cote-uri($matches)
    else if ($file_type eq $tdl:TYPE_COUNTRY_RESTRICTION) then tdl:compute-country-restriction-uri($matches)
    else if ($file_type eq $tdl:TYPE_DOC_ACCESS_RULE) then tdl:compute-doc-access-rule-uri($matches)
    else if ($file_type eq $tdl:TYPE_MEDIA_FILE) then tdl:compute-media-file-uri($matches)
    else if ($file_type eq $tdl:TYPE_BO_ACCESS_RIGHTS) then tdl:compute-bo-access-rights-uri($matches)
    else if ($file_type eq $tdl:TYPE_BO_FUNCTIONALITY) then tdl:compute-bo-functionality-uri($matches)
    else (
        let $_ := xdmp:log('[UNSUPPORTED FILE NAME TEMPLATE]: ','debug')
        let $_ := xdmp:log($file_type,'debug')
        return $tdl:UNSUPPORTED_FILE_NAME_TEMPLATE
    )
};

declare function tdl:compute-entity-parameters($filename as xs:string) as map:map{
    let $file_type_label := tdl:get-file-type($filename)
    let $collections := map:get($tdl:COLLECTIONS, $file_type_label)
    let $uri := tdl:compute-entity-uri($file_type_label, $filename)

    return map:map()
        => map:with('uri', $uri)
        => map:with('collections', $collections)
};

declare function tdl:list-data-files($test-name as xs:string) as xs:string*{
    (:
        Retrieve test data files from the suite folder path based on '$test-name'
    :)
    let $query := "declare variable $test-name as xs:string external;
    cts:uri-match(fn:concat('/test/suites/',$test-name, '/test-data/*'))"
    let $options := <options xmlns="xdmp:eval">
		    <database>{xdmp:modules-database()}</database>
		  </options>
    let $uris := xdmp:eval($query, (xs:QName('test-name'), $test-name), $options)
    let $filenames := (
        for $uri in $uris
        let $filename := fn:tokenize($uri, '/')[fn:last()]
        where (fn:string-length($filename) gt 0)
            return $filename
            )
            
    let $templates := $tdl:FILENAME_TEMPLATES!(map:get(., map:keys(.)))
    for $filename in $filenames
    (:
        Return only files complying with naming conventions
    :)
    where (count(fn:analyze-string($filename, $templates, '')//s:match)>0)
    return $filename
};

declare function tdl:get-file-type($filename as xs:string) as xs:string {
    let $score := 0
    let $type_key := ''
    let $_ :=
        for $key in map:keys($tdl:FILENAME_TEMPLATES)
        let $template := map:get($tdl:FILENAME_TEMPLATES, $key)
        let $result := count(fn:analyze-string($filename, $template, '')//s:match)
        return 
        if ($result > $score) then 
        (
            xdmp:set($score, $result),
            xdmp:set($type_key, $key)
        )
        else ()
    
    return $type_key
};

declare function tdl:load-test-file($filename as xs:string, $database-id as xs:unsignedLong, $uri as xs:string)
{
  tdl:load-test-file($filename, $database-id, $uri, xdmp:default-permissions())
};

declare function tdl:load-test-file($filename as xs:string, $database-id as xs:unsignedLong, $uri as xs:string, $permissions as element(sec:permission)*)
{
  tdl:load-test-file($filename, $database-id, $uri, $permissions, xdmp:default-collections())
};

declare function tdl:load-test-file($filename as xs:string, $database-id as xs:unsignedLong, $uri as xs:string, $permissions as element(sec:permission)*, $collections as xs:string*)
{
  xdmp:log('[tdl:suite-setup][$filename]: '||$filename, 'debug'),
  xdmp:log('[tdl:suite-setup][$database-id]: '||$database-id, 'debug'),
  xdmp:log('[tdl:suite-setup][$uri]: '||$uri, 'debug'),
  xdmp:log('[tdl:suite-setup][$permissions]: '||$permissions, 'debug'),
  xdmp:log('[tdl:suite-setup][$collections]: '||$collections, 'debug'),

  if ($database-id eq 0) then
    let $uri := fn:replace($uri, "//", "/")
    let $_ :=
      try {
        xdmp:filesystem-directory(cvt:basepath($uri))
      }
      catch ($ex) {
        xdmp:filesystem-directory-create(cvt:basepath($uri),
          <options xmlns="xdmp:filesystem-directory-create">
            <create-parents>true</create-parents>
          </options>)
      }
    return
      xdmp:save($uri, tdl:get-test-file($filename))
  else
    let $doc := tdl:get-test-file($filename)
    return
      xdmp:invoke-function(
        function() {
          xdmp:document-insert($uri, $doc, $permissions, $collections)
        },
        <options xmlns="xdmp:eval">
          <transaction-mode>update-auto-commit</transaction-mode>
          <database>{$database-id}</database>
        </options>
      )
};

declare function tdl:get-caller()
  as xs:string
{
  try { fn:error((), "ROXY-BOOM") }
  catch ($ex) {
    if ($ex/error:code ne 'ROXY-BOOM') then xdmp:rethrow()
    else (
      let $uri-list := $ex/error:stack/error:frame/error:uri/fn:string()
      let $_ := xdmp:log('[helper:get-caller][$uri-list]: ', 'debug')
      let $_ := xdmp:log($uri-list, 'debug')
      return $uri-list[fn:contains(., 'suites')]
      )
  }
};

declare function tdl:get-test-file($filename as xs:string)
as document-node()
{
  tdl:get-test-file($filename, "text", "force-unquote")
};

declare function tdl:get-test-file($filename as xs:string, $format as xs:string?)
as document-node()
{
  tdl:get-test-file($filename, $format, ())
};

declare function tdl:get-test-file($filename as xs:string, $format as xs:string?, $unquote as xs:string?)
as document-node()
{
  xdmp:log('[tdl:suite-setup][$tdl:__CALLER_FILE__]: '||$tdl:__CALLER_FILE__, 'debug'),

  tdl:get-modules-file(
    fn:replace(
      fn:concat(
        cvt:basepath($tdl:__CALLER_FILE__), "/test-data/", $filename),
      "//", "/"), $format, $unquote)
};

declare function tdl:get-modules-file($file as xs:string) {
  tdl:get-modules-file($file, "text", "force-unquote")
};

declare function tdl:get-modules-file($file as xs:string, $format as xs:string?) {
  tdl:get-modules-file($file, $format, ())
};

declare function tdl:get-modules-file($file as xs:string, $format as xs:string?, $unquote as xs:string?) {
  let $doc :=
    if (xdmp:modules-database() eq 0) then
      xdmp:document-get(
        tdl:build-uri(xdmp:modules-root(), $file),
        if (fn:exists($format)) then
          <options xmlns="xdmp:document-get">
            <format>{$format}</format>
          </options>
        else
          ())
    else
      xdmp:invoke-function(
        function() {
          fn:doc($file)
        },
        <options xmlns="xdmp:eval">
          <database>{xdmp:modules-database()}</database>
        </options>
      )

  return
    if (fn:empty($unquote) or $doc/*) then
      $doc
    else
      if ($unquote eq "force-unquote") then
        try {
          xdmp:unquote($doc)
        }
        catch ($ex) {
          $doc
        }
      else
        xdmp:unquote($doc)
};

declare function tdl:build-uri(
  $base as xs:string,
  $suffix as xs:string) as xs:string
{
  fn:string-join(
    (fn:replace($base, "(.*)/$", "$1"),
    fn:replace($suffix, "^/(.*)", "$1")),
    "/")
};

(:-----------------------------------
        MODULE "MAIN FUNCTION"
-------------------------------------:)
declare function tdl:suite-setup($test-name as xs:string){
    xdmp:log("******** "||$test-name||":suite-setup - START ***********"),
    (
        let $filenames := tdl:list-data-files($test-name)
        for $filename in $filenames
            let $entity-parameters := tdl:compute-entity-parameters($filename)
            let $entity-uri := map:get($entity-parameters, 'uri')
            let $collections := map:get($entity-parameters, 'collections')
            return
            (
                tdl:load-test-file($filename, xdmp:database(), $entity-uri),
                xdmp:document-set-collections($entity-uri, ('/test/data', $collections))
            )
    ),
    xdmp:log("******** "||$test-name||":suite-setup - END ***********")
};

