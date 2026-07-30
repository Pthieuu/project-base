<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";

$email = strtolower(trim($_POST['email'] ?? ''));
$password = $_POST['password'] ?? '';

// 🔥 CHECK RỖNG
if(empty($email) || empty($password)){
    echo json_encode(["status"=>"empty_fields"]);
    exit();
}

$emailHash = hash("sha256", $email);
$ipHash = hash("sha256", $_SERVER["REMOTE_ADDR"] ?? "unknown");
$cleanup = $conn->prepare(
    "DELETE FROM login_attempts
     WHERE attempted_at < DATE_SUB(NOW(), INTERVAL 15 MINUTE)"
);
$cleanup->execute();

$attemptCount = $conn->prepare(
    "SELECT COUNT(*) AS attempts FROM login_attempts
     WHERE email_hash = ? AND ip_hash = ?"
);
$attemptCount->bind_param("ss", $emailHash, $ipHash);
$attemptCount->execute();
$attempts = intval($attemptCount->get_result()->fetch_assoc()["attempts"] ?? 0);
if ($attempts >= 5) {
    http_response_code(429);
    header("Retry-After: 900");
    echo json_encode([
        "status" => "rate_limited",
        "message" => "Too many login attempts. Try again later."
    ]);
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
        $clearAttempts = $conn->prepare(
            "DELETE FROM login_attempts WHERE email_hash = ? AND ip_hash = ?"
        );
        $clearAttempts->bind_param("ss", $emailHash, $ipHash);
        $clearAttempts->execute();
        try {
            $session = issueAccessToken($conn, intval($user['id']));
        } catch (Throwable $error) {
            http_response_code(500);
            error_log("Login session creation failed: " . $error->getMessage());
            echo json_encode(["status" => "error", "message" => "Login failed"]);
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
        recordFailedLogin($conn, $emailHash, $ipHash);
        echo json_encode(["status"=>"invalid_credentials"]);
    }

}else{
    // Verify a fixed hash to reduce account-enumeration timing differences.
    password_verify(
        $password,
        '$2y$10$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2uheWG/igi.'
    );
    recordFailedLogin($conn, $emailHash, $ipHash);
    echo json_encode(["status"=>"invalid_credentials"]);
}

function recordFailedLogin(
    mysqli $conn,
    string $emailHash,
    string $ipHash
): void {
    $attempt = $conn->prepare(
        "INSERT INTO login_attempts (email_hash, ip_hash) VALUES (?, ?)"
    );
    $attempt->bind_param("ss", $emailHash, $ipHash);
    $attempt->execute();
}
