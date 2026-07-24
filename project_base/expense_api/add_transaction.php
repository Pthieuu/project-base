<?php

header("Content-Type: application/json");

include "db.php";
require_once "auth.php";

if ($conn->connect_error) {
    die(json_encode(["status"=>"db_error"]));
}

$data = json_decode(file_get_contents("php://input"), true);

if(!$data){
    echo json_encode(["status"=>"no_data"]);
    exit();
}

$required = ["description", "category", "account", "amount", "is_expense", "date"];
foreach ($required as $key) {
    if (!array_key_exists($key, $data)) {
        echo json_encode(["status" => "missing_field", "message" => "Missing {$key}"]);
        exit();
    }
}

$user_id = requireAuthenticatedUser($conn);
$description = trim((string)$data['description']);
$category = trim((string)$data['category']);
$account = trim((string)$data['account']);
$amount = floatval($data['amount']);
$is_expense = intval($data['is_expense']);
$notes = trim((string)($data['notes'] ?? ""));
$date = trim((string)$data['date']);

if ($description === "" || $category === "" || $amount <= 0 || $date === "") {
    echo json_encode(["status" => "invalid_data", "message" => "Invalid transaction data"]);
    exit();
}

$timestamp = strtotime($date);
if ($timestamp === false) {
    echo json_encode(["status" => "invalid_date", "message" => "Invalid transaction date"]);
    exit();
}
if (preg_match('/^\d{4}-\d{2}-\d{2}$/', $date)) {
    $date = $date . " " . date("H:i:s");
    $timestamp = strtotime($date);
}
$date = date("Y-m-d H:i:s", $timestamp);

$sql = "INSERT INTO transactions(user_id,description,category,account,amount,is_expense,notes,date)
VALUES(?,?,?,?,?,?,?,?)";

$stmt = $conn->prepare($sql);

$stmt->bind_param(
    "isssdiss",
    $user_id,
    $description,
    $category,
    $account,
    $amount,
    $is_expense,
    $notes,
    $date
);

if($stmt->execute()){
    echo json_encode(["status"=>"success"]);
}else{
    echo json_encode([
        "status"=>"error",
        "message"=>$stmt->error
    ]);
}
