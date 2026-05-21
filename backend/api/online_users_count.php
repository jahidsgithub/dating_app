<?php
include "../config/db.php";

/* Auto offline inactive users */
mysqli_query($conn, "
    UPDATE users
    SET is_online = 0
    WHERE last_seen < (NOW() - INTERVAL 30 SECOND)
");

$query = mysqli_query($conn, "
    SELECT COUNT(*) AS total
    FROM users
    WHERE status='active'
    AND is_online=1
    AND last_seen >= (NOW() - INTERVAL 30 SECOND)
");

$data = mysqli_fetch_assoc($query);

echo json_encode([
    "status" => true,
    "online_users" => intval($data["total"])
]);
?>