replace backend incoming call api codes<?php
include "../config/db.php";

$caller_id = input("caller_id");
$receiver_id = input("receiver_id");

if ($caller_id == "" || $receiver_id == "") {
    echo json_encode([
        "status" => false,
        "message" => "Caller and receiver required"
    ]);
    exit;
}

$caller_id = intval($caller_id);
$receiver_id = intval($receiver_id);

$channel = "call_" . $caller_id . "_" . $receiver_id . "_" . time();

mysqli_query($conn, "
    INSERT INTO call_requests 
    (caller_id, receiver_id, agora_channel, status)
    VALUES 
    ($caller_id, $receiver_id, '$channel', 'ringing')
");

$request_id = mysqli_insert_id($conn);

echo json_encode([
    "status" => true,
    "message" => "Call request sent",
    "request_id" => $request_id,
    "agora_channel" => $channel
]);
?>