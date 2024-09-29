# Budget Management App

## Introduction

The **Budget Management App** is a mobile application designed to help users effectively manage their daily, weekly, and monthly expenses. It enables users to track their spending across various categories, set budgets, and visualize their expenses over time. The app is built using Flutter for the frontend and Java Spring Boot for the backend, providing a smooth, responsive, and user-friendly interface.

This project is ideal for those who want to gain control over their finances and monitor their spending habits. Users can input expenses, categorize them, and get insightful reports on how they are managing their money.

## App Features

- **Expense Input & Tracking:**  
  Users can add expenses, specifying the amount, category (e.g., food, travel, shopping), and date.
  
- **Expense Categories:**  
  Pre-defined categories for easier tracking (e.g., groceries, rent, utilities, entertainment), with options for users to create custom categories.
  
- **Budget Limit Setting:**  
  Users can set monthly, weekly, or daily budget limits to ensure they don’t overspend in specific categories or overall.

- **Real-time Expense Summary:**  
  A quick overview of the total spent in a day, week, or month with real-time updates.

- **Expense Breakdown:**  
  Visual breakdown of expenses through pie charts and bar graphs, showing how much has been spent in each category.

- **Push Notifications:**  
  Receive alerts when approaching budget limits or after exceeding them.

- **Secure User Authentication:**  
  Users can log in and securely store their data with mobile number and OTP authentication.

- **Data Sync:**  
  Sync data across multiple devices with cloud integration, ensuring access to expense records anywhere.

- **Dark Mode:**  
  The app supports dark mode for better user experience during nighttime use.

## Technologies Used

### Frontend:
- **Flutter:**  
  Used for building the user interface of the app, ensuring a smooth and responsive experience on both Android and iOS platforms.
  
- **Dart:**  
  The programming language used to develop Flutter apps. Dart's fast performance and compilation enhance the app's speed and efficiency.

### Backend:
- **Java Spring Boot:**  
  Provides RESTful APIs for handling user data, budgets, and expenses. It also manages user authentication and handles communication with the database.

- **MySQL:**  
  A robust relational database used for storing user data, expense records, categories, and budget limits.

### Other Tools:
- **Postman:**  
  Used for testing the API endpoints created in the backend.
  
- **Git & GitHub:**  
  Version control system for managing the project’s source code and facilitating collaboration.
  
- **VS Code & IntelliJ IDEA:**  
  IDEs used for Flutter and Java Spring Boot development respectively.

## How to Run the Project

1. **Clone the Repository :**
   ```bash
   git clone https://github.com/shivammm1/budget-app.git
   cd budget-app
2. **Install Dependencies :**
   ```bash
   flutter pub get
   
3. **Run the App :**
   ```bash
   flutter run
      
4. **Backend Setup :**
   - **Ensure you have Java and MySQL installed.**  
   - **Set up the backend by running the Spring Boot application on your local machine**  
   - **Configure the database connection in the application.properties file for MySQL.**  

5. **API Testing :**<br>
     Use Postman to test the API endpoints and ensure the backend is working properly.



