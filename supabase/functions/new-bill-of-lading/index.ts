// Follow this setup guide to integrate the Deno language server with your editor:
// https://deno.land/manual/getting_started/setup_your_environment
// This enables autocomplete, go to definition, etc.

console.log("New Bill of Lading!");

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
    subject: "Bill of Lading Notification", // Customize your subject
    text:
      `Dear ${newRecord.recipientName},\n\nA Bill of Lading has been processed. Details:\nSender: ${newRecord.senderName}\n\nThis is an automated message.`, // Customize your message
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

/* To invoke locally:

  1. Run `supabase start` (see: https://supabase.com/docs/reference/cli/supabase-start)
  2. Make an HTTP request:

  curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/new-bill-of-lading' \
    --header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0' \
    --header 'Content-Type: application/json' \
    --data '{"name":"Functions"}'

*/
