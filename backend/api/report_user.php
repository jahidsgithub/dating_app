<?php
include "../config/db.php";

$reporter_id = input("reporter_id");
$reported_user_id = input("reported_user_id");
$reason = input("reason");

if ($reporter_id == "" || $reported_user_id == "") {
    echo json_encode(["status"=>false,"message"=>"Reporter and reported user required"]);
    exit;
}

$stmt = mysqli_prepare($conn, "
INSERT INTO reports 
(reporter_id, reported_user_id, reason)
VALUES 
(?, ?, ?)
");

mysqli_stmt_bind_param($stmt, "iis", $reporter_id, $reported_user_id, $reason);

if (mysqli_stmt_execute($stmt)) {
    echo json_encode(["status"=>true,"message"=>"Report submitted"]);
} else {
    echo json_encode(["status"=>false,"message"=>"Report failed"]);
}
?>