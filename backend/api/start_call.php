<?php
include "../config/db.php";

$caller_id = input("caller_id");
$receiver_id = input("receiver_id");

if ($caller_id == "" || $receiver_id == "") {
    echo json_encode(["status"=>false,"message"=>"Caller and receiver required"]);
    exit;
}

$channel = "call_" . $caller_id . "_" . $receiver_id . "_" . time();

$sql = "
INSERT INTO calls 
(caller_id, receiver_id, agora_channel, start_time, status)
VALUES 
('$caller_id', '$receiver_id', '$channel', NOW(), 'running')
";

if (mysqli_query($conn, $sql)) {
    echo json_encode([
        "status"=>true,
        "message"=>"Call started",
        "call_id"=>mysqli_insert_id($conn),
        "agora_channel"=>$channel
    ]);
} else {
    echo json_encode(["status"=>false,"message"=>"Call start failed"]);
}
?>