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

/* APPROVE REQUEST */
if (isset($_GET["approve"])) {

    $request_id = intval($_GET["approve"]);

    $request = mysqli_fetch_assoc(mysqli_query($conn, "
        SELECT pr.*, cp.coins
        FROM coin_purchase_requests pr
        LEFT JOIN coin_packages cp ON pr.package_id = cp.id
        WHERE pr.id = $request_id
    "));

    if ($request && $request["status"] == "pending") {

        $coins = intval($request["coins"]);
        $user_id = intval($request["user_id"]);

        mysqli_query($conn, "
            UPDATE users
            SET coins = coins + $coins
            WHERE id = $user_id
        ");

        mysqli_query($conn, "
            INSERT INTO coin_transactions
            (user_id, type, coins, note)
            VALUES
            ($user_id, 'credit', $coins, 'Coin purchase approved')
        ");

        mysqli_query($conn, "
            UPDATE coin_purchase_requests
            SET status='approved'
            WHERE id=$request_id
        ");
    }

    header("Location: purchase_requests.php");
    exit;
}

/* REJECT REQUEST */
if (isset($_GET["reject"])) {

    $request_id = intval($_GET["reject"]);

    mysqli_query($conn, "
        UPDATE coin_purchase_requests
        SET status='rejected'
        WHERE id=$request_id
    ");

    header("Location: purchase_requests.php");
    exit;
}

$requests = mysqli_query($conn, "
    SELECT pr.*,
    u.name,
    u.email,
    cp.title,
    cp.coins
    FROM coin_purchase_requests pr
    LEFT JOIN users u ON pr.user_id = u.id
    LEFT JOIN coin_packages cp ON pr.package_id = cp.id
    ORDER BY pr.id DESC
");
?>

<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>Purchase Requests</title>

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

.table-box{
    background:white;
    border-radius:24px;
    overflow:hidden;
    box-shadow:0 12px 30px rgba(15,23,42,.08);
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
    font-size:14px;
}

.badge{
    padding:7px 13px;
    border-radius:30px;
    font-size:13px;
}

.pending{
    background:#fef3c7;
    color:#92400e;
}

.approved{
    background:#dcfce7;
    color:#166534;
}

.rejected{
    background:#fee2e2;
    color:#991b1b;
}

.btn{
    text-decoration:none;
    padding:8px 14px;
    border-radius:10px;
    color:white;
    font-size:13px;
    margin-right:5px;
}

.btn-approve{
    background:#16a34a;
}

.btn-reject{
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

        <h1>Coin Purchase Requests</h1>

        <div>
            Welcome,
            <strong><?php echo $_SESSION["admin_username"]; ?></strong>
        </div>

    </div>

    <div class="table-box">

        <table>

            <tr>
                <th>ID</th>
                <th>User</th>
                <th>Email</th>
                <th>Package</th>
                <th>Coins</th>
                <th>Amount</th>
                <th>Payment</th>
                <th>Transaction ID</th>
                <th>Status</th>
                <th>Action</th>
            </tr>

            <?php while($r = mysqli_fetch_assoc($requests)): ?>

            <tr>

                <td>#<?php echo $r["id"]; ?></td>

                <td><?php echo htmlspecialchars($r["name"]); ?></td>

                <td><?php echo htmlspecialchars($r["email"]); ?></td>

                <td><?php echo htmlspecialchars($r["title"]); ?></td>

                <td><?php echo $r["coins"]; ?></td>

                <td>৳<?php echo $r["amount"]; ?></td>

                <td><?php echo htmlspecialchars($r["payment_method"]); ?></td>

                <td><?php echo htmlspecialchars($r["transaction_id"]); ?></td>

                <td>

                    <span class="badge <?php echo $r["status"]; ?>">

                        <?php echo ucfirst($r["status"]); ?>

                    </span>

                </td>

                <td>

                    <?php if($r["status"] == "pending"): ?>

                        <a
                            class="btn btn-approve"
                            href="purchase_requests.php?approve=<?php echo $r["id"]; ?>"
                        >
                            Approve
                        </a>

                        <a
                            class="btn btn-reject"
                            href="purchase_requests.php?reject=<?php echo $r["id"]; ?>"
                        >
                            Reject
                        </a>

                    <?php else: ?>

                        -

                    <?php endif; ?>

                </td>

            </tr>

            <?php endwhile; ?>

        </table>

    </div>

</div>

</body>
</html>