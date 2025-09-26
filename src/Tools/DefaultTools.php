<?php
//
// src/Tools/DefaultTools.php
//
namespace Praticom\Tools;
//
class DefaultTools {
	//
	public function __construction(){
		
	}
	//
	public function getJson($file){
		//
		if($json = json_decode(file_get_contents($file))){
		    return $json;
		}
		else{
			new Errors(400,'Arquivo JSON mal formatado.',ERROR_MSG);
		}
	}
}
?>
