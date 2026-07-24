<?php

header("Content-Type: application/json; charset=utf-8");
require_once "db.php";
require_once "auth.php";

requireAuthenticatedUser($conn);
revokeCurrentAccessToken($conn);

echo json_encode(["status" => "success"]);
