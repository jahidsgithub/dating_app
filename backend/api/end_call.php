<?php
include "../config/db.php";

$call_id = input("call_id");

if ($call_id == "") {
    echo json_encode([
        "status" => false,
        "message" => "Call ID required"
    ]);
    exit;
}

$call_id = intval($call_id);

$call = mysqli_fetch_assoc(mysqli_query($conn, "
    SELECT * FROM calls 
    WHERE id=$call_id 
    LIMIT 1
"));

if (!$call) {
    echo json_encode([
        "status" => false,
        "message" => "Call not found"
    ]);
    exit;
}

$channel = mysqli_real_escape_string($conn, $call["agora_channel"]);

mysqli_query($conn, "
    UPDATE calls 
    SET end_time=NOW(), status='ended' 
    WHERE id=$call_id
");

mysqli_query($conn, "
    UPDATE call_requests 
    SET status='ended' 
    WHERE agora_channel='$channel'
");

echo json_encode([
    "status" => true,
    "message" => "Call ended"
]);
?>