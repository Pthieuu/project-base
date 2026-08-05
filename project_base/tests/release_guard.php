<?php

declare(strict_types=1);

$root = dirname(__DIR__);
$failures = [];

function assertReleaseGuard(bool $condition, string $message): void
{
    global $failures;
    if (!$condition) {
        $failures[] = $message;
    }
}

$productionCompose = file_get_contents($root . "/compose.prod.yaml");
$migrationRunner = file_get_contents($root . "/expense_api/bin/migrate.php");
$chatEndpoint = file_get_contents($root . "/expense_api/endpoints/ai/chat.php");
$ocrEndpoint = file_get_contents($root . "/expense_api/endpoints/ai/receipt_ocr.php");
$dockerIgnore = file_get_contents($root . "/.dockerignore");

assertReleaseGuard(
    !str_contains($productionCompose, "database-migrations:"),
    "Production Compose must not depend on an ephemeral migration service."
);
foreach (["session_migration.sql", "api_rate_limits.sql"] as $migration) {
    assertReleaseGuard(
        str_contains($migrationRunner, $migration),
        "Migration runner is missing {$migration}."
    );
}
assertReleaseGuard(
    !str_contains($chatEndpoint, "Access-Control-Allow-Origin: *"),
    "AI chat must use the shared production CORS policy."
);
foreach ([$chatEndpoint, $ocrEndpoint] as $endpoint) {
    assertReleaseGuard(
        str_contains($endpoint, "enforceRateLimit"),
        "Every expensive AI endpoint must be rate limited."
    );
}
assertReleaseGuard(
    str_contains($dockerIgnore, "expense_api/legacy"),
    "Legacy PHP must be excluded from production images."
);

if ($failures !== []) {
    foreach ($failures as $failure) {
        fwrite(STDERR, "FAIL: {$failure}\n");
    }
    exit(1);
}

fwrite(STDOUT, "Release guards passed.\n");
