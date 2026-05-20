<?php
include "../config/db.php";

$name = input("name");
$email = input("email");
$phone = input("phone");
$password = input("password");
$gender = input("gender", "male");
$age = input("age", 18);
$country = input("country");

if ($name == "" || $email == "" || $password == "") {
    echo json_encode([
        "status" => false,
        "message" => "Name, email and password are required"
    ]);
    exit;
}

$check = mysqli_prepare($conn, "SELECT id FROM users WHERE email=? LIMIT 1");
mysqli_stmt_bind_param($check, "s", $email);
mysqli_stmt_execute($check);
$result = mysqli_stmt_get_result($check);

if (mysqli_num_rows($result) > 0) {
    echo json_encode([
        "status" => false,
        "message" => "Email already registered"
    ]);
    exit;
}

$hash = password_hash($password, PASSWORD_DEFAULT);

$stmt = mysqli_prepare($conn, "INSERT INTO users 
(name, email, phone, password, gender, age, country, coins) 
VALUES (?, ?, ?, ?, ?, ?, ?, 20)");

mysqli_stmt_bind_param($stmt, "sssssis", $name, $email, $phone, $hash, $gender, $age, $country);

if (mysqli_stmt_execute($stmt)) {
    echo json_encode([
        "status" => true,
        "message" => "Registration successful",
        "user_id" => mysqli_insert_id($conn)
    ]);
} else {
    echo json_encode([
        "status" => false,
        "message" => "Registration failed"
    ]);
}
?>