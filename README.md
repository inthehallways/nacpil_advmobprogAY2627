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