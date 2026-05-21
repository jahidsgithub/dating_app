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

mysqli_query($conn, "
    UPDATE users 
    SET is_online = 1, last_seen = NOW()
    WHERE id = $user_id
");

echo json_encode([
    "status" => true,
    "message" => "Activity updated"
]);
?>