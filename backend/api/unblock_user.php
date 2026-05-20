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

mysqli_query($conn, "
    DELETE FROM user_blocks
    WHERE blocker_id = $blocker_id
    AND blocked_user_id = $blocked_user_id
");

echo json_encode([
    "status" => true,
    "message" => "User unblocked successfully"
]);
?>