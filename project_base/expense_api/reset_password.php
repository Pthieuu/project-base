<?php

header("Content-Type: application/json; charset=utf-8");

include "db.php";

$email = trim($_POST["email"] ?? "");
$password = (string)($_POST["password"] ?? "");

if ($email === "" || $password === "") {
    echo json_encode(["status" => "empty_fields"]);
    exit();
}

if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "invalid_email"]);
    exit();
}

if (strlen($password) < 6) {
    echo json_encode(["status" => "weak_password"]);
    exit();
}

$check = $conn->prepare("SELECT id FROM users WHERE email = ?");
$check->bind_param("s", $email);
$check->execute();
$result = $check->get_result();

if ($result->num_rows === 0) {
    echo json_encode(["status" => "user_not_found"]);
    exit();
}

$hashedPassword = password_hash($password, PASSWORD_DEFAULT);
$stmt = $conn->prepare("UPDATE users SET password = ? WHERE email = ?");
$stmt->bind_param("ss", $hashedPassword, $email);

if ($stmt->execute()) {
    echo json_encode(["status" => "success"]);
} else {
    echo json_encode(["status" => "error", "message" => $stmt->error]);
}

?>
