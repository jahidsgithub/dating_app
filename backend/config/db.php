<?php
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With");
header("Access-Control-Allow-Methods: GET, POST, OPTIONS");
header("Content-Type: application/json; charset=UTF-8");

if ($_SERVER['REQUEST_METHOD'] == 'OPTIONS') {
    http_response_code(200);
    exit;
}

$conn = mysqli_connect("localhost", "root", "", "dating_app");

if (!$conn) {
    echo json_encode([
        "status" => false,
        "message" => "Database connection failed"
    ]);
    exit;
}

mysqli_set_charset($conn, "utf8mb4");

function input($key, $default = '') {
    $json = json_decode(file_get_contents("php://input"), true);

    if (isset($_POST[$key])) {
        return trim($_POST[$key]);
    }

    if (isset($_GET[$key])) {
        return trim($_GET[$key]);
    }

    if (isset($json[$key])) {
        return trim($json[$key]);
    }

    return $default;
}
?>