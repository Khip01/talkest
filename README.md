# gh-pages

### 🕵️‍♂️WHERE did these files come from?
These files come from the build results of the flutter web application project into several files that can be executed by the website. 
<br>

## 📋Steps 
Here is how to generate the following files
- Go to the flutter_web_app project directory ```cd flutter_web_app```
- Execute the following commands _(more details in the [Flutter Docs - Web Build](https://docs.flutter.dev/platform-integration/web/renderers#command-line-options))_
```bash
flutter build web --release --dart-define=GOOGLE_WEB_CLIENT_ID=YOUR_CLIENT_ID.apps.googleusercontent.com
``` 
- This will create a new folder ```build/web/``` and it's content
- Then finally all the contents of the ```build/web``` folder will be placed in this ```gh-pages``` branch
