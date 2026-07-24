<?php
header("Content-Type: application/json; charset=utf-8");
require_once "db.php";
require_once "auth.php";

$user_id = requireAuthenticatedUser($conn);

$stmt = $conn->prepare("SELECT * FROM transactions WHERE user_id = ?");
$stmt->bind_param("i", $user_id);
$stmt->execute();

$result = $stmt->get_result();

$data = [];

while($row = $result->fetch_assoc()){
    $data[] = $row;
}

echo json_encode([
    "status" => "success",
    "data" => $data
]);
