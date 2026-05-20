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

if ($_SERVER["REQUEST_METHOD"] == "POST") {
    $title = mysqli_real_escape_string($conn, $_POST["title"]);
    $coins = intval($_POST["coins"]);
    $price = floatval($_POST["price"]);

    if ($title != "" && $coins > 0 && $price > 0) {
        mysqli_query($conn, "
            INSERT INTO coin_packages (title, coins, price, status)
            VALUES ('$title', $coins, $price, 'active')
        ");
    }

    header("Location: coin_packages.php");
    exit;
}

if (isset($_GET["delete"])) {
    $id = intval($_GET["delete"]);
    mysqli_query($conn, "DELETE FROM coin_packages WHERE id=$id");
    header("Location: coin_packages.php");
    exit;
}

if (isset($_GET["toggle"])) {
    $id = intval($_GET["toggle"]);
    $pkg = mysqli_fetch_assoc(mysqli_query($conn, "SELECT status FROM coin_packages WHERE id=$id"));
    $newStatus = ($pkg["status"] == "active") ? "inactive" : "active";

    mysqli_query($conn, "UPDATE coin_packages SET status='$newStatus' WHERE id=$id");
    header("Location: coin_packages.php");
    exit;
}

$packages = mysqli_query($conn, "SELECT * FROM coin_packages ORDER BY id DESC");
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Coin Packages</title>

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
.grid{display:grid;grid-template-columns:400px 1fr;gap:24px}
.box{background:white;border-radius:24px;box-shadow:0 12px 30px rgba(15,23,42,.08);padding:25px}
.box h2{font-weight:normal;margin-bottom:20px;color:#0f172a}
label{display:block;margin-bottom:8px;color:#475569}
input{width:100%;padding:14px;border:1px solid #cbd5e1;border-radius:14px;margin-bottom:18px;font-size:15px}
button{background:#2563eb;color:white;border:none;padding:14px 24px;border-radius:14px;cursor:pointer;font-size:15px}
table{width:100%;border-collapse:collapse}
th{background:#f8fafc;color:#475569;padding:15px;text-align:left;font-size:14px}
td{padding:15px;border-top:1px solid #e2e8f0;font-size:14px;color:#334155}
.badge{padding:7px 13px;border-radius:30px;font-size:13px}
.active{background:#dcfce7;color:#166534}
.inactive{background:#fee2e2;color:#991b1b}
.btn{padding:8px 13px;border-radius:10px;text-decoration:none;color:white;font-size:13px;margin-right:5px;display:inline-block}
.btn-toggle{background:#f97316}
.btn-delete{background:#ef4444}
@media(max-width:900px){
    .sidebar{width:100%;height:auto;position:relative}
    .main{margin-left:0;width:100%;padding:20px}
    .grid{grid-template-columns:1fr}
    .box{overflow-x:auto}
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
        <h1>Coin Packages</h1>
        <div>Welcome, <strong><?php echo $_SESSION["admin_username"]; ?></strong></div>
    </div>

    <div class="grid">

        <div class="box">
            <h2>Add Package</h2>

            <form method="POST">
                <label>Package Title</label>
                <input type="text" name="title" placeholder="Example: Starter Pack" required>

                <label>Coins</label>
                <input type="number" name="coins" placeholder="Example: 100" required>

                <label>Price</label>
                <input type="number" step="0.01" name="price" placeholder="Example: 100" required>

                <button type="submit">Add Package</button>
            </form>
        </div>

        <div class="box">
            <h2>Package List</h2>

            <table>
                <tr>
                    <th>ID</th>
                    <th>Title</th>
                    <th>Coins</th>
                    <th>Price</th>
                    <th>Status</th>
                    <th>Action</th>
                </tr>

                <?php while($p = mysqli_fetch_assoc($packages)): ?>
                <tr>
                    <td>#<?php echo $p["id"]; ?></td>
                    <td><?php echo htmlspecialchars($p["title"]); ?></td>
                    <td><?php echo $p["coins"]; ?></td>
                    <td>৳<?php echo $p["price"]; ?></td>
                    <td>
                        <span class="badge <?php echo $p["status"]; ?>">
                            <?php echo ucfirst($p["status"]); ?>
                        </span>
                    </td>
                    <td>
                        <a class="btn btn-toggle" href="coin_packages.php?toggle=<?php echo $p["id"]; ?>">
                            Toggle
                        </a>

                        <a 
                            class="btn btn-delete" 
                            href="coin_packages.php?delete=<?php echo $p["id"]; ?>"
                            onclick="return confirm('Delete this package?')"
                        >
                            Delete
                        </a>
                    </td>
                </tr>
                <?php endwhile; ?>
            </table>
        </div>

    </div>

</div>

</body>
</html>