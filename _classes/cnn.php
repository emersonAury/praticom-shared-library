<?php
//
use Firebase\JWT\JWT;
//
class Conn {
	//
	public $db;
	//
	public function __construct(){
		//
		try {
 			$this->db = new PDO('mysql:host='.DB_HOST.';dbname='.DB_NAME, DB_USER, DB_PSWD);
    		$this->db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
		} 
		catch(PDOException $e) {
			//
			$resume = 'Arquivo: '.$e->getfile().' @ Linha: '.$e->getLine();
			new Errors($e->errorInfo[1],$resume,$e->errorInfo[2]);
		}
	}
	//
	public function doQuery($sql,$bindParam = null){
		//
		$stmt = $this->db->prepare($sql);
		//
		if($stmt === false){
			return ['success'=>false, 'cod'=>400, 'sql'=>$sql, 'msg'=>'Falha na preparação da Instrução SQL.'];
		}
		//
		if(is_array($bindParam)){
			//
			$i = 1;
			//
			foreach($bindParam as $attr=>&$var){
				//
				switch(substr($attr,0,3)){
					case 'var': $stmt->bindParam($i,$var,PDO::PARAM_STR); break;
					case 'str': $stmt->bindParam($i,$var,PDO::PARAM_STR); break;
					case 'int': $stmt->bindParam($i,$var,PDO::PARAM_INT); break;
					default: 	$stmt->bindParam($i,$var,PDO::PARAM_LOB);
				}
				//
				$i++;
			}
		}
		//
	    try{
   			$stmt->execute();
   			//
   			$res 	= $stmt->fetchAll();
   			$count 	= count($res);
   			//
   			if($count == 0) return ['success'=>true, 'cod'=>404, 'sql' => $this->sql($sql), 'msg'=>'Não foi encontrado nenhum registo', 'count'=>$count];	
   			if($count == 1) return ['success'=>true, 'cod'=>200, 'sql' => $this->sql($sql), 'msg'=>'Foi Encontrado '.$count.' registo', 'count'=>$count, 'fetch'=>$res];
   			//
   			return ['success'=>true, 'cod'=>200, 'sql' => $this->sql($sql), 'msg'=>'Foram Encontrados '.$count.' registos', 'count'=>$count, 'fetch'=>$res];
   		}
   		catch(PDOException $e){
   			return ['success'=>false, 'cod'=>$e->errorInfo[1], 'sql'=>$this->sql($sql), 'msg'=>$e->errorInfo[2]];
   		}
	}
	//
	public function add($table,$obj){
		//
		$fields = [];
		//
		foreach($obj as $attr){
			//
			switch($attr['type']){
				case 'number': 	
				case 'check': 	$field = $attr['name']. " = ".$attr['value']; break;
				default: 	 	$field = $attr['name']. " = '".$attr['value']."'"; break;
			}
			//
			array_push($fields, $field);
		}
		//
		$res = $this->doQuery("INSERT INTO ".$this->san($table)." SET ".implode(',',$fields));
		//
		if($res['cod'] == 1062){ // Registo duplicado
			//
			if (preg_match("/'(.*?)'/", $res['msg'], $matches)) {
    			$res['msg'] = "O valor '" . $matches[1] . "' já existe.";
			}
			else{
				$res['msg'] = "Valor duplicado.";
			}
			//
			return $res;
		}
		//
		if(!$res['success']) return $res;
		//
		return ['success'=>true, 'cod'=>100, 'sql'=>$this->sql($res['sql']), 'msg'=>'Registo adicionado com sucesso.'];
	}
	//
	public function login($table,$obj){
		//
		$fields = [];
		//
		foreach($obj as $attr){
			//
			if($attr['type'] == 'text' || $attr['type'] == 'email'){
				array_push($fields, $attr['name']. " = '".$attr['value']."'");
			}
			elseif($attr['type'] == 'password'){
				$password = $attr['value'];
			}
		}
		//
		$res = $this->doQuery("SELECT id,user,password,permission FROM ".$this->san($table)." WHERE ".implode(' AND ',$fields)." AND cd_status = 1 LIMIT 1");
		//
		if($res['success']){
			//
			if($res['count'] > 0){
				if(password_verify($password, $res['fetch'][0]['password'])){
					//
					$payload = [
                		'iss'  => HOST,
                		'aud'  => HOST,
                		'iat'  => time(),
                		'exp'  => time() + (60 * 60), // Expira em 1 hora
                		'data' => [
		                    'userId' => $res['fetch'][0]['id'],
		                    'userName' => $res['fetch'][0]['user'],
		                    'userPermission' => $res['fetch'][0]['permission']
                		]
            		];
            		//
            		$jwt = JWT::encode($payload, JWT_SECRET_KEY, 'HS256');
            		//
            		$res['parameters']['token'] = $jwt;
					$res['msg'] = "Login bem sucedido.";	
				}
				else{
					$res['success'] = false;
					$res['msg'] = "Senha incorreta.";
				}
			}	
			else{
				$res['success'] = false;
				$res['msg'] = "Usuário incorreto.";
			}	
		}
		//
		return $res;
	}
	//
	///////////////////////////////////////////////////
	// CUSTOM FUNCTION
	///////////////////////////////////////////////////
	//
	public function san($text){
		return htmlspecialchars($text, REPLACE_FLAGS, CHARSET);
	}
	//
	private function sql($sql){
		return !PRODUCTION ? $sql : 'Restrito a fase de testes';
	}
}
?>