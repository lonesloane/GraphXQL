xquery version "1.0-ml";
module namespace errh = "http://one.oecd.org/one/lib/errors.xqy";

declare function errh:forbidden() {
  fn:error((), "RESTAPI-SRVEXERR", ("403", "Forbidden", "Access denied"))
};

declare function errh:not-found() {
  fn:error((), "RESTAPI-SRVEXERR", ("404", "Not found", "No result found"))
};

declare function errh:bad-request($msg as xs:string) {
  fn:error((), "RESTAPI-SRVEXERR", ("400", "Bad request", $msg))
};

declare function errh:internal-server-error($msg as xs:string) {
  fn:error((), "RESTAPI-SRVEXERR", ("500", "Internal server error", $msg))
};

declare function errh:throw-exception($ex, $module-name) {
  xdmp:log(fn:concat(fn:upper-case($module-name), " EXCEPTION"), "error"),
  xdmp:log(xdmp:describe($ex, (),()), "error"),
  fn:error((),$ex//error:code/string(),$ex//error:data/error:datum/string())
};