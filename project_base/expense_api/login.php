<?php

header("Content-Type: application/json; charset=utf-8");
require_once "db.php";
require_once "auth.php";

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
        try {
            $session = issueAccessToken($conn, intval($user['id']));
        } catch (Throwable $error) {
            http_response_code(500);
            echo json_encode([
                "status" => "error",
                "message" => $error->getMessage()
            ]);
            exit();
        }
        echo json_encode([
            "status"=>"success",
            "user_id"=>$user['id'],
            "name"=>$user['name'],
            "email"=>$user['email'],
            ...$session
        ]);
    }else{
        echo json_encode(["status"=>"wrong_password"]);
    }

}else{
    echo json_encode(["status"=>"user_not_found"]);
}
