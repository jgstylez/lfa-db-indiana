// Ensure you have Deno configured to support TypeScript and external fetch requests.
// You might need to specify permissions for network access when running your Deno script.

export default async (req: Request, res: Response) => {
  // Assuming the body structure is already validated
  const { newRecord } = await req.json();

  // Define your Resend API details
  const resendAPIUrl = "https://api.resend.io/send";
  const apiKey = "re_GLHPcwXE_5ei3Ph8Lk5a9nrbRxTWhnh7G"; // Ensure this is securely stored and not hardcoded in production
  const emailContent = {
    to: newRecord.recipientEmail, // Adjust based on actual field names
    from: "indiana@localfoodaccess.com",
    subject: "Bill of Lading Received",
    text:
      `Dear ${newRecord.recipientName},\n\nYour Bill of Lading has been marked as received. Here are the details:\n- Sender: ${newRecord.senderName}\n- Bill ID: ${newRecord.id}\n\nThis is an automated message. Please do not reply.`,
  };

  try {
    const response = await fetch(resendAPIUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "Authorization": `Bearer ${apiKey}`,
      },
      body: JSON.stringify(emailContent),
    });

    if (response.ok) {
      // If email sent successfully
      return new Response(
        JSON.stringify({ status: "Email sent successfully" }),
        {
          headers: { "Content-Type": "application/json" },
        },
      );
    } else {
      // If there was an error sending the email
      const errorResponse = await response.json();
      console.error("Failed to send email:", errorResponse);
      return new Response(
        JSON.stringify({
          status: "Failed to send email",
          error: errorResponse,
        }),
        {
          status: 500,
          headers: { "Content-Type": "application/json" },
        },
      );
    }
  } catch (error) {
    // Handle any errors that occurred during the fetch operation
    console.error("Error sending email:", error);
    return new Response(
      JSON.stringify({
        status: "Error sending email",
        error: error.toString(),
      }),
      {
        status: 500,
        headers: { "Content-Type": "application/json" },
      },
    );
  }
};
