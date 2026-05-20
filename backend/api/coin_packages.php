<?php
include "../config/db.php";

$query = mysqli_query($conn, "SELECT * FROM coin_packages WHERE status='active' ORDER BY price ASC");

$packages = [];

while ($row = mysqli_fetch_assoc($query)) {
    $packages[] = $row;
}

echo json_encode([
    "status" => true,
    "packages" => $packages
]);
?>