<?php
include "../config/db.php";

$user_id = input("user_id");

if ($user_id == "") {
    echo json_encode(["status"=>false,"message"=>"User ID required"]);
    exit;
}

mysqli_query($conn, "UPDATE users SET is_online=0 WHERE id='$user_id'");

echo json_encode([
    "status"=>true,
    "message"=>"User offline"
]);
?>