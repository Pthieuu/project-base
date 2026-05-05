<?php
$conn = new mysqli("localhost","root","","ai_expense_manager");

$data_input = json_decode(file_get_contents("php://input"), true);

if(!isset($data_input['user_id'])){
    echo json_encode(["status"=>"no_user_id"]);
    exit();
}

$user_id = $data_input['user_id'];

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
?>