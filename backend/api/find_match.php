<?php
include "../config/db.php";

$user_id = input("user_id");
$looking_for = input("looking_for", "any");

if ($user_id == "") {
    echo json_encode([
        "status" => false,
        "message" => "User ID required"
    ]);
    exit;
}

$user_id = intval($user_id);

/* Auto offline inactive users */
mysqli_query($conn, "
    UPDATE users
    SET is_online = 0
    WHERE last_seen < (NOW() - INTERVAL 30 SECOND)
");

/* Current user check */
$userCheck = mysqli_query($conn, "
    SELECT * FROM users
    WHERE id = $user_id
    AND status = 'active'
    LIMIT 1
");

if (mysqli_num_rows($userCheck) == 0) {
    echo json_encode([
        "status" => false,
        "message" => "User not found or blocked"
    ]);
    exit;
}

/* Make current user online */
mysqli_query($conn, "
    UPDATE users
    SET is_online = 1, last_seen = NOW()
    WHERE id = $user_id
");

/* Remove old queue */
mysqli_query($conn, "
    DELETE FROM match_queue
    WHERE user_id = $user_id
");

$genderSql = "";

if ($looking_for != "any") {
    $safeGender = mysqli_real_escape_string($conn, $looking_for);
    $genderSql = " AND u.gender = '$safeGender' ";
}

/* Match only online + active + unblocked users */
$matchQuery = mysqli_query($conn, "
    SELECT
        mq.id AS queue_id,
        u.id,
        u.name,
        u.email,
        u.phone,
        u.gender,
        u.age,
        u.country,
        u.profile_photo,
        u.coins,
        u.is_online,
        u.last_seen
    FROM match_queue mq
    JOIN users u ON mq.user_id = u.id

    WHERE mq.status = 'waiting'
    AND mq.user_id != $user_id
    AND u.status = 'active'
    AND u.is_online = 1
    AND u.last_seen >= (NOW() - INTERVAL 30 SECOND)

    AND mq.user_id NOT IN (
        SELECT blocked_user_id
        FROM user_blocks
        WHERE blocker_id = $user_id
    )

    AND mq.user_id NOT IN (
        SELECT blocker_id
        FROM user_blocks
        WHERE blocked_user_id = $user_id
    )

    $genderSql

    ORDER BY mq.created_at ASC
    LIMIT 1
");

if (mysqli_num_rows($matchQuery) > 0) {

    $match = mysqli_fetch_assoc($matchQuery);

    mysqli_query($conn, "
        UPDATE match_queue
        SET status = 'matched'
        WHERE id = " . intval($match["queue_id"])
    );

    echo json_encode([
        "status" => true,
        "message" => "Match found",
        "matched_user" => $match
    ]);

} else {

    $safeLooking = mysqli_real_escape_string($conn, $looking_for);

    mysqli_query($conn, "
        INSERT INTO match_queue
        (user_id, looking_for, status)
        VALUES
        ($user_id, '$safeLooking', 'waiting')
    ");

    echo json_encode([
        "status" => false,
        "message" => "Waiting for online match"
    ]);
}
?>