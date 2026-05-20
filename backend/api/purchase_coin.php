<?php
include "../config/db.php";

$user_id = input("user_id");
$package_id = input("package_id");
$payment_method = input("payment_method");
$transaction_id = input("transaction_id");

if ($user_id == "" || $package_id == "") {
    echo json_encode([
        "status" => false,
        "message" => "User ID and package ID required"
    ]);
    exit;
}

$package = mysqli_fetch_assoc(
    mysqli_query($conn, "SELECT * FROM coin_packages WHERE id='$package_id' AND status='active'")
);

if (!$package) {
    echo json_encode([
        "status" => false,
        "message" => "Invalid package"
    ]);
    exit;
}

$amount = $package["price"];

$stmt = mysqli_prepare($conn, "
    INSERT INTO coin_purchase_requests 
    (user_id, package_id, amount, payment_method, transaction_id, status)
    VALUES (?, ?, ?, ?, ?, 'pending')
");

mysqli_stmt_bind_param($stmt, "iidss", $user_id, $package_id, $amount, $payment_method, $transaction_id);

if (mysqli_stmt_execute($stmt)) {
    echo json_encode([
        "status" => true,
        "message" => "Purchase request submitted. Please wait for admin approval."
    ]);
} else {
    echo json_encode([
        "status" => false,
        "message" => "Request failed"
    ]);
}
?>