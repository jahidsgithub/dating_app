<?php
include "../config/db.php";

$user_id = $_POST["user_id"] ?? "";

if ($user_id == "") {
    echo json_encode([
        "status" => false,
        "message" => "User ID required"
    ]);
    exit;
}

if (!isset($_FILES["photo"])) {
    echo json_encode([
        "status" => false,
        "message" => "Photo file required"
    ]);
    exit;
}

$uploadDir = "../uploads/";

if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0777, true);
}

$fileName = time() . "_" . basename($_FILES["photo"]["name"]);
$targetPath = $uploadDir . $fileName;

$fileType = strtolower(pathinfo($targetPath, PATHINFO_EXTENSION));

$allowed = ["jpg", "jpeg", "png", "webp"];

if (!in_array($fileType, $allowed)) {
    echo json_encode([
        "status" => false,
        "message" => "Only JPG, PNG and WEBP allowed"
    ]);
    exit;
}

if (move_uploaded_file($_FILES["photo"]["tmp_name"], $targetPath)) {

    $photoPath = "backend/uploads/" . $fileName;

    mysqli_query($conn, "UPDATE users SET profile_photo='$photoPath' WHERE id='$user_id'");

    echo json_encode([
        "status" => true,
        "message" => "Profile photo uploaded",
        "profile_photo" => $photoPath
    ]);

} else {
    echo json_encode([
        "status" => false,
        "message" => "Upload failed"
    ]);
}
?>