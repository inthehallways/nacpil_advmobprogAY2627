# Celesse Aisle Nacpil
## INF231
## CTADMOBGL: Advanced Mobile Programming

A Flutter project that focuses on advanced topics. Covering the Mobile to Web Transactions.

## Lab Activity Instance
### Lab Activity 1:
I learned while doing this activity that setState is used for managing local or ephemeral state inside one widget. Particularly, the counter in this lab activity uses setState because only MyHomePage needs to update the counter value. When the button is pressed, setState tells Flutter to rebuild that widget so the new counter number appears on the screen.

On the other hand, Provider is used for managing app-wide or shared state. This activity in particular uses Provider for the theme because the light or dark mode affects the whole app, not just a specific widget. The ThemeModel stores the current theme mode, and the notifyListeners() tells the widgets listening to it that they need to rebuild. In simpler terms, setState is good for small state inside one screen, while Provider is better on shared state that is used by multiple parts of the app.

### Lab Activity 2:
I learned while doing this activity that the model, service, and screen have different roles when rendering data from an API endpoint. The model is used to define the structure of the data. In this activity in particular, the Product model contains the fields from the API such as the title, price, description, rating, stock, and image. It also uses fromJson to convert the JSON response into a Dart object that can be used by the app.

On the other hand, the service is responsible for getting the data from the API. The ProductService sends a request to the products endpoint so it can return a list of Product objects. The screen then displays this data using FutureBuilder. While waiting, it shows a loading indicator, and once the data is loaded, it displays the products.

Lastly, the design pattern used in this activity separates the responsibilities of the app. The model handles the data structure, the service handles the API request, and the screen handles the user interface. This makes the code easier to understand because each file has its own purpose. I believe it also makes the app easier to maintain since changes in the API, data model, or UI can be handled in separate parts of the project.

### Lab Activity 3:
I learned while doing this activity that the cart model, service, and screen have different roles when rendering cart data from the API. The Cart and CartProduct models define the structure of the cart response, including the user id, product title, price, quantity, discount, total, and thumbnail. The models also use fromJson to convert the JSON response into Dart objects that can be used by the app.

On the other hand, the CartService handles the API requests. In this activity, getCartByUserId is used to render only one user’s cart instead of displaying all carts. The cart screen then uses FutureBuilder to wait for the API response and display the cart items. When a cart item is clicked, the product id is used to get the full product details, then the app navigates to the same ProductDetailScreen.

Lastly, the updated design pattern separates the responsibilities of the app. The model handles the data structure, the service handles the API calls, and the screen handles the user interface. This makes the app easier to understand and maintain because each file has its own purpose. The get by id process is also useful because it allows the app to retrieve specific cart or product data instead of loading everything from the API.

### Lab Activity 4:
I learned while doing this activity that the user model, service, and screens also have different roles when rendering authenticated user data from the API. The User model defines the structure of the user response, including the id, username, email, first name, last name, gender, image, access token, and refresh token. It also uses fromJson to convert the JSON response from the login API into a Dart object that can be saved and used by the app.

On the other hand, the UserService handles the authentication logic and saved user data. In this activity, loginUser sends the username and password to the API endpoint, then saveUserData stores the returned user information and token using SharedPreferences. The splash screen uses the saved token to check if the user is already logged in, while the sign in screen uses UserService to authenticate the user. The profile screen then gets the saved user data and displays it in the UI, such as the name, username, email, gender, image, and user id.

Lastly, the updated design pattern still separates the responsibilities of the app. The model handles the data structure, the service handles the API request and local saved data, and the screen handles the user interface and navigation. This makes the app easier to maintain because the authentication logic is not mixed directly with the UI. The saved user id is also used in rendering the cart screen by calling getCartByUserId, so the app displays the cart that belongs to the logged in user instead of using a hardcoded user id.

### Lab Activity 5:
I learned while doing this activity that integrating Firebase Authentication into a Flutter application allows the user model, service, and screens to handle real-time identity management alongside REST API data sources like DummyJSON. In this activity, the User model was expanded to include fields such as age, contact number, and login type, while the UserService was updated to manage both DummyJSON REST login and Firebase Auth SDK methods including signIn, createAccount, signOut, updateUsername, resetPasswordFromCurrentPassword, and deleteAccount.

On the other hand, the sign in and sign up screens provide a dual authentication workflow that allows users to register or log in using Firebase Auth or DummyJSON API. The sign up screen captures registration details and creates the user directly in the Firebase backend, while the sign in screen allows users to toggle between Firebase email login and DummyJSON username login. The profile screen then dynamically displays the authenticated user details along with a login type badge, account action options, and user cart information loaded from the service layer.

Lastly, the design pattern cleanly separates identity services from the presentation layer. The UserService handles all authentication logic, session clearing, and credential re-authentication, while the screens focus strictly on rendering responsive user interfaces for dark and light themes. Integrating Firebase Authentication provides real-time state management, secure token handling, and production-ready identity operations for the Flutter application.
