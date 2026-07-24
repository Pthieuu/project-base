<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";

requireAuthenticatedUser($conn);
revokeCurrentAccessToken($conn);

echo json_encode(["status" => "success"]);
