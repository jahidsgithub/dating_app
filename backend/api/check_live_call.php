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

$query = mysqli_query($conn, "
    SELECT status 
    FROM calls 
    WHERE id=$call_id 
    LIMIT 1
");

if (mysqli_num_rows($query) == 0) {
    echo json_encode([
        "status" => false,
        "message" => "Call not found"
    ]);
    exit;
}

$call = mysqli_fetch_assoc($query);

echo json_encode([
    "status" => true,
    "call_status" => $call["status"]
]);
?>