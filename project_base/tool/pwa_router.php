<?php

declare(strict_types=1);

$projectRoot = dirname(__DIR__);
$webRoot = $projectRoot . "/build/web";
$apiRoot = $projectRoot . "/expense_api";
$requestPath = rawurldecode(
    parse_url($_SERVER["REQUEST_URI"] ?? "/", PHP_URL_PATH) ?: "/"
);

// Expose only PHP files below endpoints/ through /api. Files such as .env,
// database migrations, bootstrap code, and legacy assets are unreachable.
if (str_starts_with($requestPath, "/api/")) {
    $endpoint = substr($requestPath, strlen("/api/"));
    $endpointPath = realpath($apiRoot . "/" . $endpoint);
    $publicApiRoot = realpath($apiRoot . "/endpoints");
    if (
        !preg_match(
            '/^endpoints(?:\/[A-Za-z0-9_-]+)+\.php$/',
            $endpoint
        ) ||
        $endpointPath === false ||
        $publicApiRoot === false ||
        !str_starts_with(
            $endpointPath,
            $publicApiRoot . DIRECTORY_SEPARATOR
        ) ||
        !is_file($endpointPath)
    ) {
        http_response_code(404);
        header("Content-Type: application/json; charset=utf-8");
        echo json_encode(["status" => "error", "message" => "API not found"]);
        return;
    }

    chdir(dirname($endpointPath));
    require $endpointPath;
    return;
}

// Let PHP's development server serve existing Flutter build assets.
$assetPath = realpath($webRoot . $requestPath);
if (
    $requestPath !== "/" &&
    $assetPath !== false &&
    str_starts_with($assetPath, realpath($webRoot) . DIRECTORY_SEPARATOR) &&
    is_file($assetPath)
) {
    return false;
}

// Flutter uses client-side routing, so unknown non-API paths load index.html.
$indexPath = $webRoot . "/index.html";
if (!is_file($indexPath)) {
    http_response_code(503);
    header("Content-Type: text/plain; charset=utf-8");
    echo "PWA build not found. Run flutter build web first.";
    return;
}

header("Content-Type: text/html; charset=utf-8");
readfile($indexPath);
