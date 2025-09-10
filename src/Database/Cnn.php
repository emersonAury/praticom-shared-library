<?php
//
namespace Praticom\Shared\Database;
//
use PDO;
use PDOException;
use Firebase\JWT\JWT;
use Shared\Lib\Errors;
//
class Cnn {
	//
    private $conn;
	private $lastSql;
    private $isProduction;
	//
	public function __construct($host,$dbname,$user,$password, $isProduction = false){
		//
		$this->isProduction = $isProduction;
		//
		try {
 			$dsn = "mysql:host={$host};dbname={$dbname};charset=utf8mb4";
            $this->conn = new PDO($dsn, $user, $password);
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
            $this->conn->setAttribute(PDO::ATTR_DEFAULT_FETCH_MODE, PDO::FETCH_ASSOC);
		} 
		catch(PDOException $e) {
            throw new PDOException("Falha na conexão com o banco de dados: " . $e->getMessage(), (int)$e->getCode());
        }
	}
	//
	public function doQuery($sql, $params = []) {
		//
        $this->lastSql = $this->interpolateQuery($sql, $params); // Para depuração
		//
        try {
			//
            $stmt = $this->conn->prepare($sql);
            $stmt->execute($params);
			//
            // Para SELECT
            if (stripos(trim($sql), 'SELECT') === 0) {
                $result = $stmt->fetchAll();
                $count = count($result);

                if ($count === 0) {
                    return ['success' => true, 'cod' => 404, 'msg' => 'Nenhum registro encontrado.', 'count' => 0, 'data' => []];
                }
                return ['success' => true, 'cod' => 200, 'msg' => "Encontrado(s) {$count} registro(s).", 'count' => $count, 'data' => $result];
            }
            // Para INSERT, UPDATE, DELETE
            else {
                $sql_command = strtoupper(strtok(trim($sql), ' '));
                $affectedRows = $stmt->rowCount();

                switch ($sql_command) {
                    case 'INSERT':
                        $lastId = $this->conn->lastInsertId();
                        return ['success' => true, 'cod' => 201, 'msg' => 'Registro criado com sucesso.', 'lastInsertId' => $lastId];
                    
                    case 'UPDATE':
                        $msg = $affectedRows > 0 ? 'Registro(s) atualizado(s) com sucesso.' : 'Nenhum registro precisou ser atualizado.';
                        return ['success' => true, 'cod' => 200, 'msg' => $msg, 'affectedRows' => $affectedRows];

                    case 'DELETE':
                        if ($affectedRows > 0) {
                            return ['success' => true, 'cod' => 200, 'msg' => 'Registro(s) excluído(s) com sucesso.', 'affectedRows' => $affectedRows];
                        } else {
                            return ['success' => true, 'cod' => 404, 'msg' => 'Nenhum registro encontrado para exclusão.', 'affectedRows' => 0];
                        }

                    default:
                        // Um retorno genérico para outras operações como TRUNCATE, DROP, etc.
                        return ['success' => true, 'cod' => 200, 'msg' => 'Operação realizada com sucesso.', 'affectedRows' => $affectedRows];
                }
            }
        } catch (PDOException $e) {
            return ['success' => false, 'cod' => $e->getCode(), 'msg' => $e->getMessage(), 'sql' => $this->getLastSql()];
        }
    }
    //
    public function getConnection() {
        return $this->conn;
    }
    //
    public function getLastSql() {
        return !$this->isProduction ? $this->lastSql : 'Restrito a fase de testes';
    }
    //
    private function interpolateQuery($query, $params) {
        $keys = array();
        $values = $params;

        # build a regular expression for each parameter
        foreach ($params as $key => $value) {
            if (is_string($key)) {
                $keys[] = '/:'.$key.'/';
            } else {
                $keys[] = '/[?]/';
            }
            if(is_string($value))
                $values[$key] = "'" . $value . "'";

            if(is_array($value))
                $values[$key] = implode(',', $value);

            if (is_null($value))
                $values[$key] = 'NULL';
        }
        return preg_replace($keys, $values, $query, 1, $count);
    }
}