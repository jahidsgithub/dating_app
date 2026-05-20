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

if (isset($_GET["block"])) {
    $id = intval($_GET["block"]);
    mysqli_query($conn, "UPDATE users SET status='blocked' WHERE id=$id");
    header("Location: users.php");
    exit;
}

if (isset($_GET["active"])) {
    $id = intval($_GET["active"]);
    mysqli_query($conn, "UPDATE users SET status='active' WHERE id=$id");
    header("Location: users.php");
    exit;
}

if (isset($_GET["delete"])) {
    $id = intval($_GET["delete"]);
    mysqli_query($conn, "DELETE FROM users WHERE id=$id");
    header("Location: users.php");
    exit;
}

$search = $_GET["search"] ?? "";

if ($search != "") {
    $safeSearch = mysqli_real_escape_string($conn, $search);

    $users = mysqli_query($conn, "
        SELECT * FROM users
        WHERE name LIKE '%$safeSearch%'
        OR email LIKE '%$safeSearch%'
        OR country LIKE '%$safeSearch%'
        ORDER BY id DESC
    ");
} else {
    $users = mysqli_query($conn, "SELECT * FROM users ORDER BY id DESC");
}

$totalUsers = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM users"))["total"];
$activeUsers = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM users WHERE status='active'"))["total"];
$blockedUsers = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM users WHERE status='blocked'"))["total"];
$onlineUsers = mysqli_fetch_assoc(mysqli_query($conn, "SELECT COUNT(*) AS total FROM users WHERE is_online=1"))["total"];
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Users Management</title>

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
}

.card span{
    color:#64748b;
    font-size:14px;
}

.card h2{
    margin-top:8px;
    font-size:32px;
    color:#0f172a;
}

.search-box{
    background:white;
    padding:20px;
    border-radius:22px;
    box-shadow:0 12px 30px rgba(15,23,42,.08);
    margin-bottom:25px;
}

.search-box form{
    display:flex;
    gap:12px;
}

.search-box input{
    flex:1;
    padding:15px;
    border:1px solid #cbd5e1;
    border-radius:14px;
    font-size:15px;
}

.search-box button{
    border:none;
    background:#2563eb;
    color:white;
    padding:0 28px;
    border-radius:14px;
    cursor:pointer;
    font-size:15px;
}

.table-box{
    background:white;
    border-radius:24px;
    box-shadow:0 12px 30px rgba(15,23,42,.08);
    overflow:hidden;
}

table{
    width:100%;
    border-collapse:collapse;
}

th{
    background:#f8fafc;
    color:#475569;
    padding:16px;
    text-align:left;
    font-size:14px;
}

td{
    padding:16px;
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

.online{
    color:#16a34a;
    font-weight:bold;
}

.offline{
    color:#ef4444;
    font-weight:bold;
}

.btn{
    padding:8px 13px;
    border-radius:10px;
    text-decoration:none;
    color:white;
    font-size:13px;
    margin-right:5px;
    display:inline-block;
}

.btn-block{
    background:#f97316;
}

.btn-active{
    background:#16a34a;
}

.btn-delete{
    background:#ef4444;
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

    .search-box form{
        flex-direction:column;
    }

    .search-box button{
        padding:14px;
    }

    .table-box{
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
        <h1>Users Management</h1>
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
            <span>Blocked Users</span>
            <h2><?php echo $blockedUsers; ?></h2>
        </div>

        <div class="card">
            <span>Online Users</span>
            <h2><?php echo $onlineUsers; ?></h2>
        </div>
    </div>

    <div class="search-box">
        <form method="GET">
            <input 
                type="text" 
                name="search" 
                placeholder="Search by name, email or country..."
                value="<?php echo htmlspecialchars($search); ?>"
            >
            <button type="submit">Search</button>
        </form>
    </div>

    <div class="table-box">
        <table>
            <tr>
                <th>ID</th>
                <th>User</th>
                <th>Email</th>
                <th>Gender</th>
                <th>Age</th>
                <th>Country</th>
                <th>Coins</th>
                <th>Status</th>
                <th>Online</th>
                <th>Action</th>
            </tr>

            <?php while($user = mysqli_fetch_assoc($users)): ?>
            <tr>
                <td>#<?php echo $user["id"]; ?></td>
                <td class="user-name"><?php echo htmlspecialchars($user["name"]); ?></td>
                <td><?php echo htmlspecialchars($user["email"]); ?></td>
                <td><?php echo ucfirst($user["gender"]); ?></td>
                <td><?php echo $user["age"]; ?></td>
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

                <td>
                    <?php if($user["status"] == "active"): ?>
                        <a class="btn btn-block" href="users.php?block=<?php echo $user["id"]; ?>">Block</a>
                    <?php else: ?>
                        <a class="btn btn-active" href="users.php?active=<?php echo $user["id"]; ?>">Activate</a>
                    <?php endif; ?>

                    <a 
                        class="btn btn-delete" 
                        href="users.php?delete=<?php echo $user["id"]; ?>" 
                        onclick="return confirm('Delete this user?')"
                    >
                        Delete
                    </a>
                </td>
            </tr>
            <?php endwhile; ?>

        </table>
    </div>

</div>

</body>
</html>