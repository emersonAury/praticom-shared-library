<?php
define('CHARSET', 'ISO-8859-1');
define('REPLACE_FLAGS', ENT_COMPAT | ENT_XHTML);
//
define("ENGINE","Praticom AI");
define("HOST","http://localhost/praticomai");
define("PRODUCTION",false);
//
define("DB_HOST","localhost");
define("DB_NAME","praticom_api_users");
define("DB_USER","root");
define("DB_PSWD","");	
//
define("ERROR_MSG","A requisição falhou");
//
define("JWT_SECRET_KEY", "gT8@kPz$5vF!wR9b");
//
if(!PRODUCTION){
	$__css = "adminlte.css";
}
else{
	$__css = "adminlte.min.css";
}
//
?>