# Firebase-hosted web app links: 
- https://readright-f4e36.web.app/
- https://readright-f4e36.firebaseapp.com/

How to deploy: https://firebase.google.com/docs/hosting/

# Code to deploy Firebase Hosting from root directory:
# Set the public directory to be: build/web
# Configure as a single-page app: yes
# Overwrite index.html: no
``` bash
firebase login
flutter build web
firebase init hosting
firebase deploy --only hosting
```
# Note:
Make sure you have Firebase CLI installed. You can install it using npm:
``` bash
npm install -g firebase-tools
```