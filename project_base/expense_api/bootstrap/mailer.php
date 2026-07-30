<?php

declare(strict_types=1);

function sendPasswordResetEmail(
    string $recipient,
    string $token
): bool {
    $autoload = dirname(__DIR__) . "/vendor/autoload.php";
    if (!is_file($autoload)) {
        error_log("Composer dependencies are missing; cannot send reset email");
        return false;
    }
    require_once $autoload;

    $host = getenv("SMTP_HOST") ?: "";
    $port = intval(getenv("SMTP_PORT") ?: "587");
    $username = getenv("SMTP_USERNAME") ?: "";
    $password = getenv("SMTP_PASSWORD") ?: "";
    $from = getenv("PASSWORD_RESET_FROM") ?: "";
    if ($host === "" || $username === "" || $password === "" || $from === "") {
        error_log("SMTP configuration is incomplete");
        return false;
    }

    try {
        $mailer = new PHPMailer\PHPMailer\PHPMailer(true);
        $mailer->isSMTP();
        $mailer->Host = $host;
        $mailer->Port = $port;
        $mailer->SMTPAuth = true;
        $mailer->Username = $username;
        $mailer->Password = $password;
        $mailer->SMTPSecure = $port === 465
            ? PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_SMTPS
            : PHPMailer\PHPMailer\PHPMailer::ENCRYPTION_STARTTLS;
        $mailer->CharSet = "UTF-8";
        $mailer->setFrom($from, "AI Expense Manager");
        $mailer->addAddress($recipient);
        $mailer->Subject = "AI Expense Manager password reset";
        $mailer->Body = "Your password reset token is:\n\n{$token}\n\n"
            . "This token expires in 15 minutes. "
            . "If you did not request it, ignore this email.";
        $mailer->send();
        return true;
    } catch (Throwable $error) {
        error_log("Password reset email failed: " . $error->getMessage());
        return false;
    }
}
