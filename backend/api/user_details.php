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

$stmt = mysqli_prepare($conn, "SELECT id, name, email, phone, gender, age, country, profile_photo, coins, status, is_online, created_at FROM users WHERE id=? LIMIT 1");
mysqli_stmt_bind_param($stmt, "i", $user_id);
mysqli_stmt_execute($stmt);

$result = mysqli_stmt_get_result($stmt);

if (mysqli_num_rows($result) == 0) {
    echo json_encode([
        "status" => false,
        "message" => "User not found"
    ]);
    exit;
}

$user = mysqli_fetch_assoc($result);

echo json_encode([
    "status" => true,
    "user" => $user
]);
?>