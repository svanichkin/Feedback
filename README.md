# Feedback
This class makes it easy to send feedback from users of the application. Sending takes place either to the e-mail address or in iMessage.

Easy to use:

Setup with your email or/and imessage
```
[Feedback
 setupWithIMessage:@"my_imessage@me.com"
 email:@"my_email.me.com"];
```

Then do action on user button "Send feedback"
```
[Feedback
 sendFeedbackWithController:self
 text:@"User send feedback from App"];
```
