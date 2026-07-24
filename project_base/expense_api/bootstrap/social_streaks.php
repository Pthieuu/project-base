<?php

function requireStreakMember(mysqli $conn, int $streakId, int $userId): array
{
    $stmt = $conn->prepare(
        "SELECT s.id, s.friendship_id, f.requester_id, f.receiver_id
         FROM social_streaks s
         JOIN friendships f ON f.id = s.friendship_id
         WHERE s.id = ? AND f.status = 'accepted'
           AND (f.requester_id = ? OR f.receiver_id = ?)
         LIMIT 1"
    );
    $stmt->bind_param("iii", $streakId, $userId, $userId);
    $stmt->execute();
    $row = $stmt->get_result()->fetch_assoc();
    if (!$row) {
        http_response_code(404);
        echo json_encode(["status" => "error", "message" => "Streak not found"]);
        exit();
    }
    return $row;
}

function refreshStreak(mysqli $conn, int $streakId): array
{
    $stmt = $conn->prepare(
        "SELECT checkin_date
         FROM streak_checkins
         WHERE streak_id = ?
         GROUP BY checkin_date
         HAVING COUNT(DISTINCT user_id) >= 2
         ORDER BY checkin_date ASC"
    );
    $stmt->bind_param("i", $streakId);
    $stmt->execute();
    $result = $stmt->get_result();

    $dates = [];
    while ($row = $result->fetch_assoc()) {
        $dates[] = $row["checkin_date"];
    }

    $longest = 0;
    $run = 0;
    $previous = null;
    foreach ($dates as $date) {
        $current = new DateTimeImmutable($date);
        $run = $previous !== null &&
            $previous->modify("+1 day")->format("Y-m-d") === $date
            ? $run + 1
            : 1;
        $longest = max($longest, $run);
        $previous = $current;
    }

    $completed = array_fill_keys($dates, true);
    $cursor = new DateTimeImmutable("today");
    if (!isset($completed[$cursor->format("Y-m-d")])) {
        $cursor = $cursor->modify("-1 day");
    }
    $currentStreak = 0;
    while (isset($completed[$cursor->format("Y-m-d")])) {
        $currentStreak++;
        $cursor = $cursor->modify("-1 day");
    }
    $lastCompleted = empty($dates) ? null : end($dates);

    $update = $conn->prepare(
        "UPDATE social_streaks
         SET current_streak = ?, longest_streak = GREATEST(longest_streak, ?),
             last_completed_date = ?
         WHERE id = ?"
    );
    $update->bind_param("iisi", $currentStreak, $longest, $lastCompleted, $streakId);
    $update->execute();

    return [
        "current_streak" => $currentStreak,
        "longest_streak" => $longest,
        "last_completed_date" => $lastCompleted
    ];
}
