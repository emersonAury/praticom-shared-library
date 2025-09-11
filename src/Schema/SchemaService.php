<?php
//
// src/Schema/SchemaService.php
//
namespace Praticom\Shared\Schema;
//
use InvalidArgumentException;
use RuntimeException;
//
class SchemaService {
    //
    private string $schemaDirectory;
    //
    public function __construct(string $schemaDirectory) {
        if (!is_dir($schemaDirectory)) {
            throw new InvalidArgumentException("O diretório de schemas não existe: {$schemaDirectory}");
        }
        $this->schemaDirectory = $schemaDirectory;
    }
    //
    public function getSchema(string $schemaName): array{
        //
        if (!preg_match('/^[a-zA-Z0-9_]+$/', $schemaName)) {
            throw new InvalidArgumentException("Nome de schema inválido: '{$schemaName}'.");
        }
        //
        $filePath = $this->schemaDirectory . DIRECTORY_SEPARATOR . $schemaName . '.json';
        //
        if (!file_exists($filePath) || !is_readable($filePath)) {
            throw new RuntimeException("Schema '{$schemaName}' não encontrado ou não pode ser lido.");
        }
        //
        $content = file_get_contents($filePath);
        $data = json_decode($content, true);
        //
        if (json_last_error() !== JSON_ERROR_NONE) {
            throw new RuntimeException("Erro ao decodificar o JSON do schema '{$schemaName}': " . json_last_error_msg());
        }
        //
        return $data;
    }
}