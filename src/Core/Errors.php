<?php
//
// src/Core/Errors.php
//
namespace Praticom\Core;
//
error_reporting(0);
register_shutdown_function(['Errors','systemErrors']);
//
class Errors {
	//
	public function __construct($code,$details = null,$msg = null){
		//
		$msg = !$msg ? $this->translateErrorResponse($code) : $msg;
		//
		echo json_encode([
			'success'       => false,
	        'code'          => $code,
	        'msg'           => $msg,
	        'error_details' => str_replace("@","<br/>",$details),
	        'parameters'    => []
		]);
		//
		exit;
	}
	//
	public static function systemErrors(){
		//
		if($e = error_get_last()){
			$code 	= $e['type'];
			$details = ' Arquivo: '.$e['file'].' @ Linha: '.$e['line'];
			$msg 	= $e['message'];
			$error 	= new Errors($code,$details,$msg);
		}
	}
	//
	private function translateErrorResponse($code){
		//
		switch((string)$code){
			//
			case "2002": return "Conn Error: Host não reconhecido."; break;
			case "1049": return "Conn Error: Base de dados não encontrada."; break;
			case "1045": return "Conn Error: Usuário ou senha da base de dados inválidos."; break;
			case "1000": return "Authentication Error: Erro ao autenticar."; break;
			case "1001": return "Authentication Error: Erro ao receber dados de autenticação"; break;
			case "2000": return "FileConfig Error: Erro no arquivo de Configuração do Modulo."; break;
			case "404C": return "Config Error: Erro ao receber dados de configurações"; break;
			case "000C": return "Config Error: Erro indeterminado no sistema de configuração"; break;

			default: return "Erro '".$code."': Erro desconhecido.";
		}
	}
}
?>