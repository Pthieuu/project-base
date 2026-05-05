<?php

header("Content-Type: application/json");

$conn = new mysqli("localhost","root","","ai_expense_manager");

$email = $_POST['email'] ?? '';
$password = $_POST['password'] ?? '';

// 🔥 CHECK RỖNG
if(empty($email) || empty($password)){
    echo json_encode(["status"=>"empty_fields"]);
    exit();
}

// prepared statement (an toàn hơn)
$stmt = $conn->prepare("SELECT * FROM users WHERE email = ?");
$stmt->bind_param("s", $email);
$stmt->execute();

$result = $stmt->get_result();

if($result->num_rows > 0){

    $user = $result->fetch_assoc();

    if(password_verify($password, $user['password'])){
        echo json_encode([
            "status"=>"success",
            "user_id"=>$user['id'],
            "name"=>$user['name']
        ]);
    }else{
        echo json_encode(["status"=>"wrong_password"]);
    }

}else{
    echo json_encode(["status"=>"user_not_found"]);
}

?>