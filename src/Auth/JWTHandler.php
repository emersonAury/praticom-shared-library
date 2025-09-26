<?php
//
// src/Auth/JWTHandler.php
namespace Praticom\Auth;
//
use Firebase\JWT\JWT;
use Firebase\JWT\Key;
//
class JWTHandler {
    private $secret;
    private $algorithm = 'HS256';
    //
    public function __construct(string $secret) {
        $this->secret = $secret;
    }
    //
    public function generateToken(array $payload): string {
        return JWT::encode($payload, $this->secret, $this->algorithm);
    }
    //
    public function validateToken(string $token) {
        try {
            return JWT::decode($token, new Key($this->secret, $this->algorithm));
        } catch (\Exception $e) {
            throw new \Exception('Token inválido: ' . $e->getMessage());
        }
    }
}
?>