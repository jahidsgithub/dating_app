<?php
include "../config/db.php";

mysqli_query($conn, "
    UPDATE users 
    SET is_online = 0
    WHERE last_seen < (NOW() - INTERVAL 30 SECOND)
");

echo json_encode([
    "status" => true,
    "message" => "Inactive users updated"
]);
?>