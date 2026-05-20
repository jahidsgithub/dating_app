<?php
include "../config/db.php";

$request_id = input("request_id");

if ($request_id == "") {
    echo json_encode([
        "status" => false,
        "message" => "Request ID required"
    ]);
    exit;
}

$request_id = intval($request_id);

$query = mysqli_query($conn, "
    SELECT cr.*, c.id AS call_id
    FROM call_requests cr
    LEFT JOIN calls c 
    ON c.agora_channel = cr.agora_channel
    WHERE cr.id = $request_id
    LIMIT 1
");

if (mysqli_num_rows($query) == 0) {
    echo json_encode([
        "status" => false,
        "message" => "Call request not found"
    ]);
    exit;
}

$data = mysqli_fetch_assoc($query);

echo json_encode([
    "status" => true,
    "call_status" => $data["status"],
    "call_id" => $data["call_id"],
    "agora_channel" => $data["agora_channel"],
    "caller_id" => $data["caller_id"],
    "receiver_id" => $data["receiver_id"]
]);
?>