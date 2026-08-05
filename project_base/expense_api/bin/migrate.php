<?php

declare(strict_types=1);

require_once dirname(__DIR__) . "/bootstrap/config.php";

$port = envValue("DB_PORT");
if (!ctype_digit($port)) {
    fwrite(STDERR, "DB_PORT must be numeric.\n");
    exit(1);
}

$connection = new mysqli(
    envValue("DB_HOST"),
    envValue("DB_USER"),
    envValue("DB_PASSWORD", true),
    envValue("DB_NAME"),
    intval($port)
);

if ($connection->connect_error) {
    fwrite(STDERR, "Database migration connection failed.\n");
    exit(1);
}
$connection->set_charset("utf8mb4");

$migrationFiles = [
    "00_core_schema.sql",
    "schema_extensions.sql",
    "social_streaks.sql",
    "session_migration.sql",
    "password_reset_tokens.sql",
    "login_attempts.sql",
    "api_rate_limits.sql",
];

foreach ($migrationFiles as $migrationFile) {
    $path = dirname(__DIR__) . "/database/{$migrationFile}";
    $sql = file_get_contents($path);
    if ($sql === false || !$connection->multi_query($sql)) {
        fwrite(STDERR, "Migration {$migrationFile} failed.\n");
        exit(1);
    }

    while (true) {
        $result = $connection->store_result();
        if ($result instanceof mysqli_result) {
            $result->free();
        }
        if (!$connection->more_results()) {
            break;
        }
        if (!$connection->next_result()) {
            fwrite(STDERR, "Migration {$migrationFile} failed.\n");
            exit(1);
        }
    }

    fwrite(STDOUT, "Applied {$migrationFile}\n");
}

$connection->close();
