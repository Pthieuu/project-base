<?php

// Kept as a safe compatibility endpoint. Password resets must use the
// request/confirm token flow; knowing an email address is never sufficient.
header("Content-Type: application/json; charset=utf-8");
http_response_code(410);
echo json_encode([
    "status" => "deprecated",
    "message" => "Use the password reset token flow."
]);
