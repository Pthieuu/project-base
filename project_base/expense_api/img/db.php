<?php

$host = "localhost";
$user = "root";
$password = "";
$db = "ai_expense_manager";

$conn = new mysqli($host,$user,$password,$db);

if($conn->connect_error){
    die("Connection failed");
}

?>