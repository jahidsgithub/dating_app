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

$totalUsers = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM users"))["total"];
$activeUsers = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM users WHERE status='active'"))["total"];
$onlineUsers = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM users WHERE is_online=1"))["total"];
$blockedUsers = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM users WHERE status='blocked'"))["total"];
$totalCalls = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM calls"))["total"];
$runningCalls = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM calls WHERE status='running'"))["total"];
$totalReports = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM reports"))["total"];

$recentUsers = mysqli_query($conn, "SELECT * FROM users ORDER BY id DESC LIMIT 8");

$recentCalls = mysqli_query($conn, "
    SELECT c.*, u1.name AS caller_name, u2.name AS receiver_name
    FROM calls c
    LEFT JOIN users u1 ON c.caller_id = u1.id
    LEFT JOIN users u2 ON c.receiver_id = u2.id
    ORDER BY c.id DESC
    LIMIT 6
");
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Admin Dashboard</title>

<style>
*{
    margin:0;
    padding:0;
    box-sizing:border-box;
    font-family:Arial,sans-serif;
}

body{
    background:#eef2f7;
}

.sidebar{
    width:280px;
    height:100vh;
    background:#0f172a;
    position:fixed;
    left:0;
    top:0;
    padding:25px;
}

.sidebar h2{
    color:white;
    font-weight:normal;
    margin-bottom:30px;
}

.sidebar a{
    display:block;
    text-decoration:none;
    color:#e5e7eb;
    padding:14px 16px;
    border-radius:14px;
    margin-bottom:12px;
    background:#1e293b;
}

.sidebar a:hover{
    background:#2563eb;
    color:white;
}

.logout{
    background:#ef4444!important;
    margin-top:40px;
}

.main{
    margin-left:280px;
    padding:30px;
    width:calc(100% - 280px);
}

.header{
    display:flex;
    justify-content:space-between;
    align-items:center;
    margin-bottom:25px;
}

.header h1{
    font-weight:normal;
    color:#0f172a;
}

.cards{
    display:grid;
    grid-template-columns:repeat(auto-fit,minmax(190px,1fr));
    gap:18px;
    margin-bottom:25px;
}

.card{
    background:white;
    padding:22px;
    border-radius:22px;
    box-shadow:0 12px 30px rgba(15,23,42,.08);
    border-left:5px solid #2563eb;
}

.card span{
    color:#64748b;
    font-size:14px;
}

.card h2{
    margin-top:8px;
    font-size:34px;
    color:#0f172a;
}

.grid{
    display:grid;
    grid-template-columns:1.2fr .8fr;
    gap:22px;
}

.panel{
    background:white;
    border-radius:24px;
    box-shadow:0 12px 30px rgba(15,23,42,.08);
    overflow:hidden;
}

.panel-header{
    padding:20px 22px;
    border-bottom:1px solid #e2e8f0;
    display:flex;
    justify-content:space-between;
    align-items:center;
}

.panel-header h2{
    font-weight:normal;
    color:#0f172a;
    font-size:22px;
}

.panel-header a{
    text-decoration:none;
    background:#2563eb;
    color:white;
    padding:9px 14px;
    border-radius:10px;
    font-size:13px;
}

table{
    width:100%;
    border-collapse:collapse;
}

th{
    background:#f8fafc;
    color:#475569;
    padding:15px;
    text-align:left;
    font-size:14px;
}

td{
    padding:15px;
    border-top:1px solid #e2e8f0;
    color:#334155;
    font-size:14px;
}

.user-name{
    font-weight:bold;
    color:#0f172a;
}

.badge{
    padding:7px 13px;
    border-radius:30px;
    font-size:13px;
}

.badge-active{
    background:#dcfce7;
    color:#166534;
}

.badge-blocked{
    background:#fee2e2;
    color:#991b1b;
}

.badge-running{
    background:#dbeafe;
    color:#1d4ed8;
}

.badge-ended{
    background:#f1f5f9;
    color:#475569;
}

.online{
    color:#16a34a;
    font-weight:bold;
}

.offline{
    color:#ef4444;
    font-weight:bold;
}

@media(max-width:1000px){
    .grid{
        grid-template-columns:1fr;
    }
}

@media(max-width:768px){
    .sidebar{
        width:100%;
        height:auto;
        position:relative;
    }

    .main{
        margin-left:0;
        width:100%;
        padding:20px;
    }

    .header{
        flex-direction:column;
        align-items:flex-start;
        gap:10px;
    }

    .panel{
        overflow-x:auto;
    }
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
        <h1>Dashboard Overview</h1>
        <div>Welcome, <strong><?php echo $_SESSION["admin_username"]; ?></strong></div>
    </div>

    <div class="cards">
        <div class="card">
            <span>Total Users</span>
            <h2><?php echo $totalUsers; ?></h2>
        </div>

        <div class="card">
            <span>Active Users</span>
            <h2><?php echo $activeUsers; ?></h2>
        </div>

        <div class="card">
            <span>Online Users</span>
            <h2><?php echo $onlineUsers; ?></h2>
        </div>

        <div class="card">
            <span>Blocked Users</span>
            <h2><?php echo $blockedUsers; ?></h2>
        </div>

        <div class="card">
            <span>Total Calls</span>
            <h2><?php echo $totalCalls; ?></h2>
        </div>

        <div class="card">
            <span>Running Calls</span>
            <h2><?php echo $runningCalls; ?></h2>
        </div>

        <div class="card">
            <span>Total Reports</span>
            <h2><?php echo $totalReports; ?></h2>
        </div>
    </div>

    <div class="grid">

        <div class="panel">
            <div class="panel-header">
                <h2>Recent Users</h2>
                <a href="users.php">View All</a>
            </div>

            <table>
                <tr>
                    <th>ID</th>
                    <th>User</th>
                    <th>Gender</th>
                    <th>Country</th>
                    <th>Coins</th>
                    <th>Status</th>
                    <th>Online</th>
                </tr>

                <?php while($user = mysqli_fetch_assoc($recentUsers)): ?>
                <tr>
                    <td>#<?php echo $user["id"]; ?></td>
                    <td class="user-name"><?php echo htmlspecialchars($user["name"]); ?></td>
                    <td><?php echo ucfirst($user["gender"]); ?></td>
                    <td><?php echo htmlspecialchars($user["country"]); ?></td>
                    <td><?php echo $user["coins"]; ?></td>
                    <td>
                        <?php if($user["status"] == "active"): ?>
                            <span class="badge badge-active">Active</span>
                        <?php else: ?>
                            <span class="badge badge-blocked">Blocked</span>
                        <?php endif; ?>
                    </td>
                    <td>
                        <?php if($user["is_online"] == 1): ?>
                            <span class="online">Online</span>
                        <?php else: ?>
                            <span class="offline">Offline</span>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endwhile; ?>
            </table>
        </div>

        <div class="panel">
            <div class="panel-header">
                <h2>Recent Calls</h2>
                <a href="calls.php">View All</a>
            </div>

            <table>
                <tr>
                    <th>ID</th>
                    <th>Caller</th>
                    <th>Receiver</th>
                    <th>Status</th>
                </tr>

                <?php while($call = mysqli_fetch_assoc($recentCalls)): ?>
                <tr>
                    <td>#<?php echo $call["id"]; ?></td>
                    <td><?php echo htmlspecialchars($call["caller_name"] ?? "Unknown"); ?></td>
                    <td><?php echo htmlspecialchars($call["receiver_name"] ?? "Unknown"); ?></td>
                    <td>
                        <?php if($call["status"] == "running"): ?>
                            <span class="badge badge-running">Running</span>
                        <?php else: ?>
                            <span class="badge badge-ended">Ended</span>
                        <?php endif; ?>
                    </td>
                </tr>
                <?php endwhile; ?>
            </table>
        </div>

    </div>

</div>

</body>
</html>