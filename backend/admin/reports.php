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

if (isset($_GET["review"])) {
    $id = intval($_GET["review"]);

    mysqli_query($conn, "UPDATE reports SET status='reviewed' WHERE id=$id");

    header("Location: reports.php");
    exit;
}

if (isset($_GET["block_user"])) {
    $user_id = intval($_GET["block_user"]);

    mysqli_query($conn, "UPDATE users SET status='blocked' WHERE id=$user_id");

    header("Location: reports.php");
    exit;
}

$reports = mysqli_query($conn, "
    SELECT r.*,
    u1.name AS reporter_name,
    u1.email AS reporter_email,
    u2.name AS reported_name,
    u2.email AS reported_email,
    u2.status AS reported_status
    FROM reports r
    LEFT JOIN users u1 ON r.reporter_id = u1.id
    LEFT JOIN users u2 ON r.reported_user_id = u2.id
    ORDER BY r.id DESC
");
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Reports</title>

<style>
*{margin:0;padding:0;box-sizing:border-box;font-family:Arial,sans-serif}
body{background:#eef2f7}
.sidebar{width:280px;height:100vh;background:#0f172a;position:fixed;left:0;top:0;padding:25px}
.sidebar h2{color:white;font-weight:normal;margin-bottom:30px}
.sidebar a{display:block;text-decoration:none;color:#e5e7eb;padding:14px 16px;border-radius:14px;margin-bottom:12px;background:#1e293b}
.sidebar a:hover{background:#2563eb}
.logout{background:#ef4444!important;margin-top:40px}
.main{margin-left:280px;padding:30px;width:calc(100% - 280px)}
.header{display:flex;justify-content:space-between;align-items:center;margin-bottom:25px}
.header h1{font-weight:normal;color:#0f172a}
.table-box{background:white;border-radius:24px;overflow:hidden;box-shadow:0 12px 30px rgba(15,23,42,.08)}
table{width:100%;border-collapse:collapse}
th{background:#f8fafc;color:#475569;padding:15px;text-align:left;font-size:14px}
td{padding:15px;border-top:1px solid #e2e8f0;color:#334155;font-size:14px;vertical-align:top}
.badge{padding:7px 13px;border-radius:30px;font-size:13px;display:inline-block}
.pending{background:#fef3c7;color:#92400e}
.reviewed{background:#dcfce7;color:#166534}
.active{background:#dcfce7;color:#166534}
.blocked{background:#fee2e2;color:#991b1b}
.btn{padding:8px 13px;border-radius:10px;text-decoration:none;color:white;font-size:13px;margin-bottom:5px;display:inline-block}
.btn-review{background:#2563eb}
.btn-block{background:#ef4444}
.reason{max-width:280px;line-height:1.5}
.small{color:#64748b;font-size:13px;margin-top:4px}
@media(max-width:768px){
    .sidebar{width:100%;height:auto;position:relative}
    .main{margin-left:0;width:100%;padding:20px}
    .table-box{overflow-x:auto}
}
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

    <div class="header">
        <h1>User Reports</h1>
        <div>Welcome, <strong><?php echo $_SESSION["admin_username"]; ?></strong></div>
    </div>

    <div class="table-box">
        <table>
            <tr>
                <th>ID</th>
                <th>Reporter</th>
                <th>Reported User</th>
                <th>Reason</th>
                <th>Report Status</th>
                <th>User Status</th>
                <th>Date</th>
                <th>Action</th>
            </tr>

            <?php while($r = mysqli_fetch_assoc($reports)): ?>
            <tr>
                <td>#<?php echo $r["id"]; ?></td>

                <td>
                    <?php echo htmlspecialchars($r["reporter_name"] ?? "Unknown"); ?>
                    <div class="small"><?php echo htmlspecialchars($r["reporter_email"] ?? ""); ?></div>
                </td>

                <td>
                    <?php echo htmlspecialchars($r["reported_name"] ?? "Unknown"); ?>
                    <div class="small"><?php echo htmlspecialchars($r["reported_email"] ?? ""); ?></div>
                </td>

                <td class="reason">
                    <?php echo htmlspecialchars($r["reason"]); ?>
                </td>

                <td>
                    <span class="badge <?php echo $r["status"]; ?>">
                        <?php echo ucfirst($r["status"]); ?>
                    </span>
                </td>

                <td>
                    <span class="badge <?php echo $r["reported_status"]; ?>">
                        <?php echo ucfirst($r["reported_status"] ?? "Unknown"); ?>
                    </span>
                </td>

                <td><?php echo $r["created_at"]; ?></td>

                <td>
                    <?php if($r["status"] == "pending"): ?>
                        <a class="btn btn-review" href="reports.php?review=<?php echo $r["id"]; ?>">
                            Mark Reviewed
                        </a>
                    <?php endif; ?>

                    <?php if($r["reported_status"] == "active"): ?>
                        <a 
                            class="btn btn-block" 
                            href="reports.php?block_user=<?php echo $r["reported_user_id"]; ?>"
                            onclick="return confirm('Block this reported user?')"
                        >
                            Block User
                        </a>
                    <?php endif; ?>
                </td>
            </tr>
            <?php endwhile; ?>

        </table>
    </div>

</div>

</body>
</html>