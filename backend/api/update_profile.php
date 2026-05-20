<?php
include "../config/db.php";

$user_id = input("user_id");
$name = input("name");
$phone = input("phone");
$gender = input("gender");
$age = input("age");
$country = input("country");

if ($user_id == "") {
    echo json_encode(["status"=>false,"message"=>"User ID required"]);
    exit;
}

$stmt = mysqli_prepare($conn, "
    UPDATE users 
    SET name=?, phone=?, gender=?, age=?, country=? 
    WHERE id=?
");

mysqli_stmt_bind_param($stmt, "sssisi", $name, $phone, $gender, $age, $country, $user_id);

if (mysqli_stmt_execute($stmt)) {
    echo json_encode(["status"=>true,"message"=>"Profile updated"]);
} else {
    echo json_encode(["status"=>false,"message"=>"Profile update failed"]);
}
?>