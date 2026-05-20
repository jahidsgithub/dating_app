<?php
include "../config/db.php";

$request_id = input("request_id");
$response = input("response");

if ($request_id == "" || $response == "") {
    echo json_encode([
        "status" => false,
        "message" => "Request ID and response required"
    ]);
    exit;
}

$request_id = intval($request_id);

if (!in_array($response, ["accepted", "rejected", "ended"])) {
    echo json_encode([
        "status" => false,
        "message" => "Invalid response"
    ]);
    exit;
}

$callRequest = mysqli_fetch_assoc(mysqli_query($conn, "
    SELECT * FROM call_requests 
    WHERE id = $request_id 
    LIMIT 1
"));

if (!$callRequest) {
    echo json_encode([
        "status" => false,
        "message" => "Call request not found"
    ]);
    exit;
}

mysqli_query($conn, "
    UPDATE call_requests 
    SET status = '$response'
    WHERE id = $request_id
");

$call_id = "";

if ($response == "accepted") {

    $caller_id = intval($callRequest["caller_id"]);
    $receiver_id = intval($callRequest["receiver_id"]);
    $channel = mysqli_real_escape_string($conn, $callRequest["agora_channel"]);

    mysqli_query($conn, "
        INSERT INTO calls 
        (caller_id, receiver_id, agora_channel, start_time, status)
        VALUES 
        ($caller_id, $receiver_id, '$channel', NOW(), 'running')
    ");

    $call_id = mysqli_insert_id($conn);
}

echo json_encode([
    "status" => true,
    "message" => "Call $response",
    "response" => $response,
    "call_id" => $call_id,
    "agora_channel" => $callRequest["agora_channel"],
    "caller_id" => $callRequest["caller_id"],
    "receiver_id" => $callRequest["receiver_id"]
]);
?>