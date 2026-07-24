<?php

header("Content-Type: application/json");
require_once "db.php";
require_once "auth.php";

$userId = requireAuthenticatedUser($conn);

$defaults = [
    ["Food & Drink", "expense"],
    ["Shopping", "expense"],
    ["Transport", "expense"],
    ["Coffee", "expense"],
    ["Housing", "expense"],
    ["Entertainment", "expense"],
    ["Salary", "income"],
    ["Other", "both"],
];

foreach ($defaults as $item) {
    $stmt = $conn->prepare(
        "INSERT IGNORE INTO categories (user_id, name, type) VALUES (?, ?, ?)"
    );
    $stmt->bind_param("iss", $userId, $item[0], $item[1]);
    $stmt->execute();
}

$stmt = $conn->prepare(
    "SELECT id, name, icon, color, type
     FROM categories
     WHERE user_id = ?
     ORDER BY name ASC"
);
$stmt->bind_param("i", $userId);
$stmt->execute();
$result = $stmt->get_result();

$categories = [];
while ($row = $result->fetch_assoc()) {
    $categories[] = $row;
}

echo json_encode(["status" => "success", "data" => $categories]);
