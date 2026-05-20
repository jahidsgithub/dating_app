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

$coins = mysqli_query($conn, "
    SELECT ct.*, u.name, u.email
    FROM coin_transactions ct
    LEFT JOIN users u ON ct.user_id = u.id
    ORDER BY ct.id DESC
");
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Coin History</title>
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
.credit{color:#059669;font-weight:bold}
.debit{color:#dc2626;font-weight:bold}
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
    <h1>Coin History</h1>

    <div class="box">
        <table>
            <tr>
                <th>ID</th>
                <th>User</th>
                <th>Email</th>
                <th>Type</th>
                <th>Coins</th>
                <th>Note</th>
                <th>Date</th>
            </tr>

            <?php while($c = mysqli_fetch_assoc($coins)): ?>
            <tr>
                <td><?php echo $c["id"]; ?></td>
                <td><?php echo htmlspecialchars($c["name"] ?? "Unknown"); ?></td>
                <td><?php echo htmlspecialchars($c["email"] ?? ""); ?></td>
                <td class="<?php echo $c["type"]; ?>"><?php echo ucfirst($c["type"]); ?></td>
                <td><?php echo $c["coins"]; ?></td>
                <td><?php echo htmlspecialchars($c["note"]); ?></td>
                <td><?php echo $c["created_at"]; ?></td>
            </tr>
            <?php endwhile; ?>
        </table>
    </div>
</div>

</body>
</html>