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

$message = "";

if ($_SERVER["REQUEST_METHOD"] == "POST") {

    $user_id = intval($_POST["user_id"]);
    $coins = intval($_POST["coins"]);

    if ($user_id > 0 && $coins > 0) {

        mysqli_query(
            $conn,
            "UPDATE users SET coins = coins + $coins WHERE id=$user_id"
        );

        mysqli_query(
            $conn,
            "
            INSERT INTO coin_transactions
            (user_id, type, coins, note)
            VALUES
            ($user_id, 'credit', $coins, 'Coins added by admin')
            "
        );

        $message = "Coins added successfully";

    } else {

        $message = "Please enter valid data";
    }
}

$users = mysqli_query(
    $conn,
    "SELECT id, name, email, coins FROM users ORDER BY name ASC"
);
?>

<!DOCTYPE html>
<html>
<head>

    <meta charset="UTF-8">

    <title>Add Coins</title>

    <style>

        *{
            margin:0;
            padding:0;
            box-sizing:border-box;
            font-family:Arial,sans-serif;
        }

        body{
            background:#f3f4f6;
        }

        .sidebar{
            width:280px;
            height:100vh;
            background:#111827;
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
            color:white;
            background:#1f2937;
            padding:13px 15px;
            border-radius:12px;
            margin-bottom:12px;
            transition:.2s;
        }

        .sidebar a:hover{
            background:#2563eb;
        }

        .logout{
            background:#dc2626 !important;
            margin-top:40px;
        }

        .main{

            margin-left:280px;
            width:calc(100% - 280px);
            min-height:100vh;

            display:flex;
            justify-content:center;
            align-items:center;

            padding:40px;
        }

        .box{

            background:white;
            padding:35px;
            border-radius:24px;
            box-shadow:0 15px 35px rgba(0,0,0,.08);

            width:100%;
            max-width:700px;
        }

        h1{
            margin-bottom:25px;
            font-weight:normal;
            color:#111827;
        }

        label{
            display:block;
            margin-bottom:8px;
            color:#374151;
        }

        select,
        input{

            width:100%;
            padding:15px;

            border:1px solid #d1d5db;
            border-radius:12px;

            margin-bottom:20px;

            font-size:15px;
        }

        button{

            background:#2563eb;
            color:white;

            border:none;

            padding:14px 30px;

            border-radius:12px;

            cursor:pointer;

            font-size:15px;
        }

        button:hover{
            background:#1d4ed8;
        }

        .msg{

            background:#dcfce7;
            color:#166534;

            padding:14px;

            border-radius:12px;

            margin-bottom:20px;
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

    <div class="box">

        <h1>Add Coins</h1>

        <?php if($message != ""): ?>

            <div class="msg">

                <?php echo $message; ?>

            </div>

        <?php endif; ?>

        <form method="POST">

            <label>Select User</label>

            <select name="user_id" required>

                <option value="">Select User</option>

                <?php while($u = mysqli_fetch_assoc($users)): ?>

                    <option value="<?php echo $u["id"]; ?>">

                        <?php echo htmlspecialchars($u["name"]); ?>

                        -

                        <?php echo htmlspecialchars($u["email"]); ?>

                        -

                        Balance:
                        <?php echo $u["coins"]; ?>

                    </option>

                <?php endwhile; ?>

            </select>

            <label>Coins</label>

            <input
                type="number"
                name="coins"
                min="1"
                placeholder="Enter coins amount"
                required
            >

            <button type="submit">
                Add Coins
            </button>

        </form>

    </div>

</div>

</body>
</html>