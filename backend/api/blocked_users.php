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
    SELECT ub.*, 
    u.name, u.email, u.gender, u.country, u.profile_photo
    FROM user_blocks ub
    LEFT JOIN users u ON ub.blocked_user_id = u.id
    WHERE ub.blocker_id = $user_id
    ORDER BY ub.id DESC
");

$users = [];

while ($row = mysqli_fetch_assoc($query)) {
    $users[] = $row;
}

echo json_encode([
    "status" => true,
    "users" => $users
]);
?>