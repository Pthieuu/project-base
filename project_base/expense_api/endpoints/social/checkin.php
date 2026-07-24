<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";
require_once dirname(__DIR__, 2) . "/bootstrap/social_streaks.php";

$userId = requireAuthenticatedUser($conn);
$data = json_decode(file_get_contents("php://input"), true) ?: [];
$streakId = intval($data["streak_id"] ?? 0);
$privateStatus = (string)($data["private_status"] ?? "");
$allowed = ["mindful", "paused_purchase", "unplanned_purchase", "observed"];
if (!in_array($privateStatus, $allowed, true)) {
    echo json_encode(["status" => "error", "message" => "Invalid check-in"]);
    exit();
}
requireStreakMember($conn, $streakId, $userId);
$today = date("Y-m-d");
$stmt = $conn->prepare(
    "INSERT INTO streak_checkins (streak_id, user_id, checkin_date, private_status)
     VALUES (?, ?, ?, ?)
     ON DUPLICATE KEY UPDATE private_status = VALUES(private_status)"
);
$stmt->bind_param("iiss", $streakId, $userId, $today, $privateStatus);
$stmt->execute();
$progress = refreshStreak($conn, $streakId);
echo json_encode(["status" => "success", "data" => $progress]);
