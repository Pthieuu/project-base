<?php

header("Content-Type: application/json");

$conn = new mysqli("localhost","root","","ai_expense_manager");

if ($conn->connect_error) {
    die(json_encode(["status"=>"db_error"]));
}

$data = json_decode(file_get_contents("php://input"), true);

if(!$data){
    echo json_encode(["status"=>"no_data"]);
    exit();
}

// 🔥 bắt buộc có user_id
if(!isset($data['user_id'])){
    echo json_encode(["status"=>"no_user_id"]);
    exit();
}

$user_id = $data['user_id'] ?? null;

$sql = "INSERT INTO transactions(user_id,description,category,account,amount,is_expense,notes,date)
VALUES(?,?,?,?,?,?,?,?)";

$stmt = $conn->prepare($sql);

$stmt->bind_param(
    "isssdiss",
    $user_id,
    $data['description'],
    $data['category'],
    $data['account'],
    $data['amount'],
    $data['is_expense'],
    $data['notes'],
    $data['date']
);

if($stmt->execute()){
    echo json_encode(["status"=>"success"]);
}else{
    echo json_encode([
        "status"=>"error",
        "message"=>$stmt->error
    ]);
}