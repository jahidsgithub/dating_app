<?php
session_start();
if (!isset($_SESSION["admin_id"])) {
    header("Location: login.php");
    exit;
}

$conn = mysqli_connect("localhost", "root", "", "dating_app");
if (!$conn) {
    die("Database connection failed");
}

$calls = mysqli_query($conn, "
    SELECT c.*, 
    u1.name AS caller_name, 
    u2.name AS receiver_name
    FROM calls c
    LEFT JOIN users u1 ON c.caller_id = u1.id
    LEFT JOIN users u2 ON c.receiver_id = u2.id
    ORDER BY c.id DESC
");
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Video Calls</title>
<style>
body{margin:0;font-family:Arial,sans-serif;background:#f3f4f6}
.sidebar{width:250px;height:100vh;background:#111827;position:fixed;padding:25px}
.sidebar h2{color:white;font-weight:normal;margin-bottom:30px}
.sidebar a{display:block;color:white;text-decoration:none;background:#1f2937;padding:13px 15px;border-radius:10px;margin-bottom:12px}
.sidebar a:hover{background:#2563eb}
.logout{background:#dc2626!important;margin-top:40px}
.main{margin-left:250px;padding:30px}
.box{background:white;padding:25px;border-radius:20px;box-shadow:0 10px 25px rgba(0,0,0,.05);overflow-x:auto}
h1{font-weight:normal;margin-bottom:25px}
table{width:100%;border-collapse:collapse}
th{background:#111827;color:white;padding:14px;text-align:left}
td{padding:14px;border-bottom:1px solid #e5e7eb}
.badge{padding:6px 12px;border-radius:20px;color:white;font-size:13px}
.running{background:#059669}
.ended{background:#dc2626}
</style>
</head>
<body>

<div class="sidebar">
    <h2>Dating Admin</h2>
    <a href="dashboard.php">Dashboard</a>
    <a href="users.php">Users</a>
    <a href="calls.php">Video Calls</a>
    <a href="coins.php">Coin History</a>
    <a href="coin_packages.php">Coin Packages</a>
    <a href="purchase_requests.php">Purchase Requests</a>
    <a href="reports.php">Reports</a>
    <a href="add_coins.php">Add Coins</a>
    <a href="logout.php" class="logout">Logout</a>
</div>

<div class="main">
    <h1>Video Calls</h1>

    <div class="box">
        <table>
            <tr>
                <th>ID</th>
                <th>Caller</th>
                <th>Receiver</th>
                <th>Channel</th>
                <th>Start</th>
                <th>End</th>
                <th>Coins</th>
                <th>Status</th>
            </tr>

            <?php while($c = mysqli_fetch_assoc($calls)): ?>
            <tr>
                <td><?php echo $c["id"]; ?></td>
                <td><?php echo htmlspecialchars($c["caller_name"] ?? "Unknown"); ?></td>
                <td><?php echo htmlspecialchars($c["receiver_name"] ?? "Unknown"); ?></td>
                <td><?php echo htmlspecialchars($c["agora_channel"]); ?></td>
                <td><?php echo $c["start_time"]; ?></td>
                <td><?php echo $c["end_time"] ?: "-"; ?></td>
                <td><?php echo $c["coins_deducted"]; ?></td>
                <td>
                    <span class="badge <?php echo $c["status"]; ?>">
                        <?php echo ucfirst($c["status"]); ?>
                    </span>
                </td>
            </tr>
            <?php endwhile; ?>
        </table>
    </div>
</div>

</body>
</html>