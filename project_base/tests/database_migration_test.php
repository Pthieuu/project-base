<?php

declare(strict_types=1);

require dirname(__DIR__) . "/expense_api/bin/migrate.php";
require_once dirname(__DIR__) . "/expense_api/bootstrap/db.php";

$requiredTables = [
    "users",
    "transactions",
    "user_sessions",
    "password_reset_tokens",
    "login_attempts",
    "api_rate_limits",
];

foreach ($requiredTables as $table) {
    $safeTable = $conn->real_escape_string($table);
    $result = $conn->query("SHOW TABLES LIKE '{$safeTable}'");
    if ($result === false || $result->num_rows !== 1) {
        fwrite(STDERR, "Missing table after migration: {$table}\n");
        exit(1);
    }
}

fwrite(STDOUT, "Database migration integration test passed.\n");
