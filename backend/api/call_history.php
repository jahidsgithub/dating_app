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

$query = mysqli_query($conn, "
    SELECT c.*,
    u1.name AS caller_name,
    u2.name AS receiver_name
    FROM calls c
    LEFT JOIN users u1 ON c.caller_id = u1.id
    LEFT JOIN users u2 ON c.receiver_id = u2.id
    WHERE c.caller_id = $user_id
    OR c.receiver_id = $user_id
    ORDER BY c.id DESC
");

$history = [];

while ($row = mysqli_fetch_assoc($query)) {
    $history[] = $row;
}

echo json_encode([
    "status" => true,
    "history" => $history
]);
?>