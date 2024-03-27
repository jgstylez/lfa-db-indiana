// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

console.log("Bill of Lading Paid!");

Deno.serve(async (req) => {
  const { name } = await req.json();
  const data = {
    message: `Hello ${name}!`,
  };

  return new Response(
    JSON.stringify(data),
    { headers: { "Content-Type": "application/json" } },
  );
});

export default async (req: any, res: any) => {
  const { newRecord } = req.body;

  // Define your Resend API details
  const resendAPIUrl = "https://api.resend.io/send"; // This might be different; use your actual Resend API endpoint
  const apiKey = "re_GLHPcwXE_5ei3Ph8Lk5a9nrbRxTWhnh7G";
  const emailContent = {
    to: newRecord.recipient, // Assuming newRecord contains 'recipient' email
    from: "indiana@localfoodaccess.com", // Specify the sender's email address
    subject: "Bill of Lading Paid", // Customize your subject
    text:
      `Dear ${newRecord.recipientName},\n\nA Bill of Lading has been marked paid. Details:\nSender: ${newRecord.senderName}\n\nThis is an automated message.`, // Customize your message
    // Optionally, add 'html' field if you want to send HTML email
  };

  try {
    const response = await fetch(resendAPIUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`, // Ensure your API expects Authorization header
      },
      body: JSON.stringify(emailContent),
    });

    if (response.ok) {
      // If email sent successfully
      res.send({ status: "Email sent successfully" });
    } else {
      // If there was an error sending the email
      const errorResponse = await response.json();
      console.error("Failed to send email:", errorResponse);
      res.status(500).send({
        status: "Failed to send email",
        error: errorResponse,
      });
    }
  } catch (error) {
    // Handle any errors that occurred during the fetch operation
    console.error("Error sending email:", error);
    res.status(500).send({
      status: "Error sending email",
      error: error.toString(),
    });
  }
};
