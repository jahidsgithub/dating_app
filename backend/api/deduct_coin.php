<?php
include "../config/db.php";

$user_id = input("user_id");
$coins = input("coins", 1);
$call_id = input("call_id");

if ($user_id == "") {
    echo json_encode(["status"=>false,"message"=>"User ID required"]);
    exit;
}

$user = mysqli_fetch_assoc(mysqli_query($conn, "SELECT coins FROM users WHERE id='$user_id'"));

if (!$user) {
    echo json_encode(["status"=>false,"message"=>"User not found"]);
    exit;
}

if ($user["coins"] < $coins) {
    echo json_encode(["status"=>false,"message"=>"Insufficient coins"]);
    exit;
}

mysqli_query($conn, "UPDATE users SET coins = coins - $coins WHERE id='$user_id'");

mysqli_query($conn, "
INSERT INTO coin_transactions 
(user_id, type, coins, note)
VALUES 
('$user_id', 'debit', '$coins', 'Video call charge')
");

if ($call_id != "") {
    mysqli_query($conn, "
        UPDATE calls 
        SET coins_deducted = coins_deducted + $coins 
        WHERE id='$call_id'
    ");
}

$balance = mysqli_fetch_assoc(mysqli_query($conn, "SELECT coins FROM users WHERE id='$user_id'"));

echo json_encode([
    "status"=>true,
    "message"=>"Coin deducted",
    "balance"=>$balance["coins"]
]);
?>