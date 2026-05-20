<?php
include "../config/db.php";

$email = input("email");
$password = input("password");

if ($email == "" || $password == "") {
    echo json_encode([
        "status" => false,
        "message" => "Email and password are required"
    ]);
    exit;
}

$stmt = mysqli_prepare($conn, "SELECT * FROM users WHERE email=? LIMIT 1");
mysqli_stmt_bind_param($stmt, "s", $email);
mysqli_stmt_execute($stmt);
$result = mysqli_stmt_get_result($stmt);

if (mysqli_num_rows($result) == 0) {
    echo json_encode([
        "status" => false,
        "message" => "Invalid email or password"
    ]);
    exit;
}

$user = mysqli_fetch_assoc($result);

if (!password_verify($password, $user['password'])) {
    echo json_encode([
        "status" => false,
        "message" => "Invalid email or password"
    ]);
    exit;
}

mysqli_query($conn, "UPDATE users SET is_online=1 WHERE id=" . intval($user['id']));

unset($user['password']);

echo json_encode([
    "status" => true,
    "message" => "Login successful",
    "user" => $user
]);
?>