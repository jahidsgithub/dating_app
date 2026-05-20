<?php
include "../config/db.php";

$blocker_id = input("blocker_id");
$blocked_user_id = input("blocked_user_id");

if ($blocker_id == "" || $blocked_user_id == "") {
    echo json_encode([
        "status" => false,
        "message" => "Blocker and blocked user required"
    ]);
    exit;
}

$blocker_id = intval($blocker_id);
$blocked_user_id = intval($blocked_user_id);

if ($blocker_id == $blocked_user_id) {
    echo json_encode([
        "status" => false,
        "message" => "You cannot block yourself"
    ]);
    exit;
}

mysqli_query($conn, "
    INSERT IGNORE INTO user_blocks
    (blocker_id, blocked_user_id)
    VALUES
    ($blocker_id, $blocked_user_id)
");

echo json_encode([
    "status" => true,
    "message" => "User blocked successfully"
]);
?>