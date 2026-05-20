<?php
include "../config/db.php";

$user_id = input("user_id");

if ($user_id == "") {
    echo json_encode([
        "status" => false,
        "message" => "User ID required"
    ]);
    exit;
}

$user_id = intval($user_id);

/* Auto end old ringing calls */
mysqli_query($conn, "
    UPDATE call_requests
    SET status='ended'
    WHERE status='ringing'
    AND created_at < (NOW() - INTERVAL 35 SECOND)
");

$query = mysqli_query($conn, "
    SELECT cr.*, 
    u.name AS caller_name,
    u.email AS caller_email,
    u.gender AS caller_gender,
    u.country AS caller_country,
    u.profile_photo AS caller_photo
    FROM call_requests cr
    LEFT JOIN users u ON cr.caller_id = u.id
    WHERE cr.receiver_id = $user_id
    AND cr.status = 'ringing'
    ORDER BY cr.id DESC
    LIMIT 1
");

if (mysqli_num_rows($query) == 0) {
    echo json_encode([
        "status" => false,
        "message" => "No incoming call"
    ]);
    exit;
}

$call = mysqli_fetch_assoc($query);

echo json_encode([
    "status" => true,
    "message" => "Incoming call",
    "call" => $call
]);
?>