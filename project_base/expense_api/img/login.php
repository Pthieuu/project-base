<?php

include "db.php";

$email = $_POST['email'];
$password = $_POST['password'];

$sql = "SELECT * FROM users WHERE email='$email'";
$result = $conn->query($sql);

if($result->num_rows > 0){

    $user = $result->fetch_assoc();

    if(password_verify($password,$user['password'])){
        echo json_encode([
            "status"=>"success",
            "user"=>$user
        ]);
    }else{
        echo json_encode(["status"=>"wrong_password"]);
    }

}else{
    echo json_encode(["status"=>"user_not_found"]);
}

?>