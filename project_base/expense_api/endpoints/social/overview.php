<?php

header("Content-Type: application/json; charset=utf-8");
require_once dirname(__DIR__, 2) . "/bootstrap/db.php";
require_once dirname(__DIR__, 2) . "/bootstrap/auth.php";
require_once dirname(__DIR__, 2) . "/bootstrap/social_streaks.php";

$userId = requireAuthenticatedUser($conn);
$today = date("Y-m-d");

$pendingStmt = $conn->prepare(
    "SELECT f.id, u.id AS user_id, u.name, u.email
     FROM friendships f
     JOIN users u ON u.id = f.requester_id
     WHERE f.receiver_id = ? AND f.status = 'pending'
     ORDER BY f.created_at DESC"
);
$pendingStmt->bind_param("i", $userId);
$pendingStmt->execute();
$pendingResult = $pendingStmt->get_result();
$pending = [];
while ($row = $pendingResult->fetch_assoc()) {
    $pending[] = $row;
}

$streakStmt = $conn->prepare(
    "SELECT s.id, s.friendship_id, s.current_streak, s.longest_streak,
            f.requester_id, f.receiver_id,
            u.id AS friend_id, u.name AS friend_name, u.email AS friend_email
     FROM social_streaks s
     JOIN friendships f ON f.id = s.friendship_id
     JOIN users u ON u.id = IF(f.requester_id = ?, f.receiver_id, f.requester_id)
     WHERE f.status = 'accepted'
       AND (f.requester_id = ? OR f.receiver_id = ?)
     ORDER BY s.current_streak DESC, f.updated_at DESC"
);
$streakStmt->bind_param("iii", $userId, $userId, $userId);
$streakStmt->execute();
$streakResult = $streakStmt->get_result();
$streaks = [];

while ($row = $streakResult->fetch_assoc()) {
    $streakId = intval($row["id"]);
    $progress = refreshStreak($conn, $streakId);

    $checkins = $conn->prepare(
        "SELECT user_id FROM streak_checkins
         WHERE streak_id = ? AND checkin_date = ?"
    );
    $checkins->bind_param("is", $streakId, $today);
    $checkins->execute();
    $checkinResult = $checkins->get_result();
    $checkedUsers = [];
    while ($checkin = $checkinResult->fetch_assoc()) {
        $checkedUsers[intval($checkin["user_id"])] = true;
    }

    $nudge = $conn->prepare(
        "SELECT COUNT(*) AS total FROM streak_nudges
         WHERE streak_id = ? AND receiver_id = ? AND nudge_date = ?"
    );
    $nudge->bind_param("iis", $streakId, $userId, $today);
    $nudge->execute();
    $nudgeCount = intval($nudge->get_result()->fetch_assoc()["total"] ?? 0);

    $streaks[] = [
        "id" => $streakId,
        "friendship_id" => intval($row["friendship_id"]),
        "friend_id" => intval($row["friend_id"]),
        "friend_name" => $row["friend_name"],
        "friend_email" => $row["friend_email"],
        "current_streak" => $progress["current_streak"],
        "longest_streak" => max(
            intval($row["longest_streak"]),
            intval($progress["longest_streak"])
        ),
        "me_checked_in" => isset($checkedUsers[$userId]),
        "friend_checked_in" => isset($checkedUsers[intval($row["friend_id"])]),
        "nudged_me_today" => $nudgeCount > 0
    ];
}

echo json_encode([
    "status" => "success",
    "data" => [
        "pending_invitations" => $pending,
        "streaks" => $streaks
    ]
], JSON_UNESCAPED_UNICODE);
