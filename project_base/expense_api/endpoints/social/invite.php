<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";

$userId = requireAuthenticatedUser($conn);
$data = json_decode(file_get_contents("php://input"), true) ?: [];
$email = strtolower(trim((string)($data["email"] ?? "")));
if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
    echo json_encode(["status" => "error", "message" => "Enter a valid email"]);
    exit();
}

$stmt = $conn->prepare("SELECT id FROM users WHERE LOWER(email) = ? LIMIT 1");
$stmt->bind_param("s", $email);
$stmt->execute();
$friend = $stmt->get_result()->fetch_assoc();
if (!$friend) {
    echo json_encode(["status" => "error", "message" => "User not found"]);
    exit();
}
$friendId = intval($friend["id"]);
if ($friendId === $userId) {
    echo json_encode(["status" => "error", "message" => "You cannot invite yourself"]);
    exit();
}

$check = $conn->prepare(
    "SELECT id, status FROM friendships
     WHERE (requester_id = ? AND receiver_id = ?)
        OR (requester_id = ? AND receiver_id = ?)
     LIMIT 1"
);
$check->bind_param("iiii", $userId, $friendId, $friendId, $userId);
$check->execute();
$existing = $check->get_result()->fetch_assoc();
if ($existing && $existing["status"] !== "rejected") {
    echo json_encode(["status" => "error", "message" => "An invitation or friendship already exists"]);
    exit();
}

if ($existing) {
    $id = intval($existing["id"]);
    $update = $conn->prepare(
        "UPDATE friendships
         SET requester_id = ?, receiver_id = ?, status = 'pending'
         WHERE id = ?"
    );
    $update->bind_param("iii", $userId, $friendId, $id);
    $update->execute();
} else {
    $insert = $conn->prepare(
        "INSERT INTO friendships (requester_id, receiver_id) VALUES (?, ?)"
    );
    $insert->bind_param("ii", $userId, $friendId);
    $insert->execute();
}

echo json_encode(["status" => "success"]);
